import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:yabai_app/core/services/message_sound_service.dart';
import 'package:yabai_app/features/im/data/services/websocket_service.dart';
import 'package:yabai_app/features/im/data/models/ws_message.dart';
import 'package:yabai_app/features/im/data/models/ws_message_ack.dart';
import 'package:yabai_app/features/im/data/models/im_message_model.dart';
import 'package:yabai_app/features/im/providers/unread_count_provider.dart';
import 'package:yabai_app/features/auth/providers/auth_session_provider.dart';
import 'package:yabai_app/features/auth/data/repositories/auth_repository.dart';
import 'package:yabai_app/features/auth/data/models/auth_exception.dart';

/// WebSocket 连接状态管理
class WebSocketProvider extends ChangeNotifier {
  final WebSocketService _websocketService;
  final AuthSessionProvider? _authSessionProvider;
  final AuthRepository? _authRepository;
  final MessageSoundService _soundService = MessageSoundService();
  final int? _currentUserId;
  
  /// 未读消息数Provider的引用（可选，用于实时更新角标）
  UnreadCountProvider? _unreadCountProvider;

  WebSocketState _state = WebSocketState.disconnected;
  WebSocketState get state => _state;

  bool get isConnected => _state == WebSocketState.connected;
  bool get isConnecting => _state == WebSocketState.connecting;
  bool get isDisconnected => _state == WebSocketState.disconnected;
  bool get isReconnecting => _state == WebSocketState.reconnecting;

  StreamSubscription? _stateSubscription;
  StreamSubscription? _ackSubscription;
  StreamSubscription? _newMessageSubscription;

  /// 消息确认回调映射（msgId -> callback）
  final Map<String, Completer<WsMessageAck>> _ackCompleters = {};

  /// 新消息回调列表（支持多个监听器）
  final List<Function(ImMessage)> _newMessageCallbacks = [];
  
  /// 添加新消息监听器
  void addNewMessageListener(Function(ImMessage) callback) {
    if (!_newMessageCallbacks.contains(callback)) {
      _newMessageCallbacks.add(callback);
    }
  }
  
  /// 移除新消息监听器
  void removeNewMessageListener(Function(ImMessage) callback) {
    _newMessageCallbacks.remove(callback);
  }
  
  /// 兼容旧代码：设置单个回调（已废弃，建议使用 addNewMessageListener）
  @Deprecated('使用 addNewMessageListener 代替')
  set onNewMessage(Function(ImMessage)? callback) {
    _newMessageCallbacks.clear();
    if (callback != null) {
      _newMessageCallbacks.add(callback);
    }
  }
  
  /// 兼容旧代码：获取回调（已废弃）
  @Deprecated('使用 addNewMessageListener 代替')
  Function(ImMessage)? get onNewMessage {
    return _newMessageCallbacks.isEmpty ? null : _newMessageCallbacks.first;
  }

  WebSocketProvider(
    this._websocketService, {
    AuthSessionProvider? authSessionProvider,
    AuthRepository? authRepository,
    int? currentUserId,
    UnreadCountProvider? unreadCountProvider,
  })  : _authSessionProvider = authSessionProvider,
        _authRepository = authRepository,
        _currentUserId = currentUserId,
        _unreadCountProvider = unreadCountProvider {
    _init();
  }
  
  /// 设置未读消息数Provider（用于实时更新角标）
  void setUnreadCountProvider(UnreadCountProvider? provider) {
    _unreadCountProvider = provider;
  }

  void _init() {
    // 监听连接状态
    _stateSubscription = _websocketService.stateStream.listen((newState) {
      _state = newState;
      notifyListeners();
    });

    // 监听消息确认
    _ackSubscription = _websocketService.ackStream.listen((ack) {
      final completer = _ackCompleters.remove(ack.msgId);
      completer?.complete(ack);
    });

    // 监听新消息
    _newMessageSubscription = _websocketService.newMessageStream.listen((message) {
      // 如果不是自己发送的消息
      if (_currentUserId != null && message.senderUserId != _currentUserId) {
        // 播放音效
        _soundService.playNewMessageSound();
        
        // 实时更新未读消息角标（自动加1）
        // 下次API通信后会以API返回结果为准
        _unreadCountProvider?.incrementUnreadCount();
      }
      
      // 通知所有注册的监听器
      for (final callback in _newMessageCallbacks) {
        try {
          callback(message);
        } catch (e) {
          debugPrint('WebSocketProvider: 新消息回调执行失败 - $e');
        }
      }
    });
  }

  /// 连接 WebSocket
  Future<void> connect(String host, int port, String token) async {
    // 创建 token 获取回调，用于重连时刷新 token
    Future<String> tokenGetter() async {
      return await _getValidToken();
    }
    
    await _websocketService.connect(host, port, token, tokenGetter: tokenGetter);
  }

  /// 获取有效的 token（如果过期则刷新）
  Future<String> _getValidToken() async {
    if (_authSessionProvider == null || _authRepository == null) {
      throw Exception('AuthSessionProvider 或 AuthRepository 未设置');
    }

    final tokens = _authSessionProvider!.tokens;
    if (tokens == null) {
      throw Exception('未找到 token');
    }

    // 检查 access token 是否过期
    if (!_authSessionProvider!.isAuthenticated) {
      debugPrint('WebSocket: Access token 已过期，尝试刷新...');
      
      // 检查是否有 refresh token
      if (tokens.refreshToken.isEmpty) {
        throw Exception('Refresh token 不可用');
      }

      try {
        // 刷新 token
        final newTokens = await _authRepository!.refreshTokens(
          refreshToken: tokens.refreshToken,
        );
        
        // 保存新 token
        await _authSessionProvider!.save(newTokens);
        
        debugPrint('WebSocket: Token 刷新成功');
        return newTokens.accessToken;
      } on AuthException catch (e) {
        debugPrint('WebSocket: Token 刷新失败 - ${e.message}');
        throw Exception('Token 刷新失败: ${e.message}');
      } catch (e) {
        debugPrint('WebSocket: Token 刷新出错 - $e');
        throw Exception('Token 刷新出错: $e');
      }
    }

    // Token 仍然有效，直接返回
    return tokens.accessToken;
  }

  /// 断开连接
  void disconnect() {
    _websocketService.disconnect();
  }

  /// 发送消息并等待确认
  Future<WsMessageAck> sendMessageAndWaitAck(WsMessage message, {Duration timeout = const Duration(seconds: 10)}) async {
    // 创建 Completer 等待确认
    final completer = Completer<WsMessageAck>();
    _ackCompleters[message.msgId] = completer;

    try {
      // 发送消息
      await _websocketService.sendMessage(message);

      // 等待确认或超时
      return await completer.future.timeout(
        timeout,
        onTimeout: () {
          _ackCompleters.remove(message.msgId);
          throw TimeoutException('消息发送超时');
        },
      );
    } catch (e) {
      _ackCompleters.remove(message.msgId);
      rethrow;
    }
  }

  /// 发送消息（不等待确认）
  Future<void> sendMessage(WsMessage message) async {
    await _websocketService.sendMessage(message);
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _ackSubscription?.cancel();
    _newMessageSubscription?.cancel();
    _websocketService.dispose();
    super.dispose();
  }
}

