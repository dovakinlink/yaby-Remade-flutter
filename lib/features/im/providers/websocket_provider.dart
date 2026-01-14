import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:yabai_app/core/services/message_sound_service.dart';
import 'package:yabai_app/core/config/env_config.dart';
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
        }
      }
    });
  }

  /// 连接 WebSocket
  /// [useSecure] 是否使用安全连接（wss://），HTTPS 环境应设为 true
  Future<void> connect(String host, int port, String token, {bool useSecure = false}) async {
    // 创建 token 获取回调，用于重连时刷新 token
    Future<String> tokenGetter() async {
      return await _getValidToken();
    }
    
    await _websocketService.connect(host, port, token, tokenGetter: tokenGetter, useSecure: useSecure);
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
        
        return newTokens.accessToken;
      } on AuthException catch (e) {
        throw Exception('Token 刷新失败: ${e.message}');
      } catch (e) {
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

  /// 等待连接完成（如果正在连接或重连中）
  Future<void> _waitForConnection({Duration timeout = const Duration(seconds: 30)}) async {
    // 如果已连接，直接返回
    if (_state == WebSocketState.connected) {
      return;
    }

    // 如果正在连接或重连中，等待完成
    if (_state == WebSocketState.connecting || _state == WebSocketState.reconnecting) {
      await _waitForStateChange(timeout: timeout);
      if (_state == WebSocketState.connected) {
        return; // 连接成功
      }
    }

    // 如果已断开且不是主动断开，尝试重新连接
    if (_state == WebSocketState.disconnected && !_websocketService.isManualDisconnect) {
      try {
        await _reconnectIfNeeded();
        // 等待连接完成
        await _waitForStateChange(timeout: timeout);
      } catch (e) {
        rethrow;
      }
    }

    // 最终检查连接状态
    if (_state != WebSocketState.connected) {
      throw Exception('WebSocket 连接失败，当前状态: $_state');
    }
  }

  /// 等待状态变化为 connected
  Future<void> _waitForStateChange({Duration timeout = const Duration(seconds: 30)}) async {
    if (_state == WebSocketState.connected) {
      return;
    }

    final completer = Completer<void>();
    late StreamSubscription subscription;
    
    subscription = _websocketService.stateStream.listen((state) {
      if (state == WebSocketState.connected) {
        if (!completer.isCompleted) {
          completer.complete();
        }
        subscription.cancel();
      } else if (state == WebSocketState.disconnected && !_websocketService.isManualDisconnect) {
        // 如果连接失败且不是主动断开，尝试重连
        _reconnectIfNeeded().catchError((e) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
          subscription.cancel();
        });
      }
    });

    try {
      await completer.future.timeout(
        timeout,
        onTimeout: () {
          subscription.cancel();
          throw TimeoutException('等待连接超时，当前状态: $_state');
        },
      );
    } finally {
      await subscription.cancel();
    }
  }

  /// 如果需要，尝试重新连接
  Future<void> _reconnectIfNeeded() async {
    if (_authSessionProvider == null) {
      throw Exception('AuthSessionProvider 未设置，无法重连');
    }

    if (!_authSessionProvider!.isAuthenticated) {
      throw Exception('用户未登录，无法重连');
    }

    final tokens = _authSessionProvider!.tokens;
    if (tokens == null) {
      throw Exception('未找到 token，无法重连');
    }

    try {
      // 获取最新的 token
      final token = await _getValidToken();
      
      // 获取服务器地址
      final baseUrl = await EnvConfig.resolveApiBaseUrl();
      final uri = Uri.parse(baseUrl);
      final host = uri.host;
      final port = uri.port;
      // 根据 baseUrl 的 scheme 判断是否使用安全连接
      final useSecure = uri.scheme == 'https';

      await connect(host, port, token, useSecure: useSecure);
    } catch (e) {
      rethrow;
    }
  }

  /// 发送消息并等待确认
  Future<WsMessageAck> sendMessageAndWaitAck(WsMessage message, {Duration timeout = const Duration(seconds: 10)}) async {
    // 确保连接已建立
    await _waitForConnection();

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
    // 确保连接已建立
    await _waitForConnection();
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

