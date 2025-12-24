import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:yabai_app/features/im/data/models/ws_message.dart';
import 'package:yabai_app/features/im/data/models/ws_message_ack.dart';
import 'package:yabai_app/features/im/data/models/im_message_model.dart';

/// WebSocket 连接状态
enum WebSocketState {
  disconnected, // 未连接
  connecting, // 连接中
  connected, // 已连接
  reconnecting, // 重连中
}

/// WebSocket 服务类
/// 负责管理 WebSocket 连接、心跳、重连、消息收发等
class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  /// 当前连接状态
  WebSocketState _state = WebSocketState.disconnected;
  WebSocketState get state => _state;

  /// 连接状态流
  final _stateController = StreamController<WebSocketState>.broadcast();
  Stream<WebSocketState> get stateStream => _stateController.stream;

  /// 接收到的消息流
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  /// 消息确认流
  final _ackController = StreamController<WsMessageAck>.broadcast();
  Stream<WsMessageAck> get ackStream => _ackController.stream;

  /// 新消息通知流
  final _newMessageController = StreamController<ImMessage>.broadcast();
  Stream<ImMessage> get newMessageStream => _newMessageController.stream;

  /// WebSocket 服务器地址（不包含 token）
  String? _baseWsUrl;
  
  /// 服务器主机地址
  String? _host;
  
  /// 服务器端口
  int? _port;

  /// Token 获取回调（用于重连时获取最新 token）
  Future<String> Function()? _tokenGetter;

  /// 重连次数
  int _reconnectAttempts = 0;

  /// 最大重连次数
  static const int _maxReconnectAttempts = 10;

  /// 心跳间隔（秒）
  static const int _heartbeatInterval = 30;

  /// 是否主动断开（如果是，则不自动重连）
  bool _manualDisconnect = false;
  
  /// 获取是否主动断开
  bool get isManualDisconnect => _manualDisconnect;

  WebSocketService();

  /// 连接 WebSocket
  Future<void> connect(String host, int port, String token, {Future<String> Function()? tokenGetter}) async {
    if (_state == WebSocketState.connected ||
        _state == WebSocketState.connecting) {
      return;
    }

    _host = host;
    _port = port;
    _baseWsUrl = 'ws://$host:$port/im/ws';
    _tokenGetter = tokenGetter;
    _manualDisconnect = false;

    await _connectWithToken(token);
  }

  /// 使用指定 token 连接
  Future<void> _connectWithToken(String token) async {
    if (_baseWsUrl == null || _host == null || _port == null) {
      return;
    }

    final wsUrl = '$_baseWsUrl?token=$token';
    
    try {
      _updateState(WebSocketState.connecting);

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // 监听消息
      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      _updateState(WebSocketState.connected);

      // 重置重连次数
      _reconnectAttempts = 0;

      // 启动心跳
      _startHeartbeat();
    } catch (e) {
      _updateState(WebSocketState.disconnected);
      _scheduleReconnect();
    }
  }

  /// 断开连接
  void disconnect() {
    _manualDisconnect = true;
    _cleanup();
    _updateState(WebSocketState.disconnected);
  }

  /// 清理资源
  void _cleanup() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  /// 启动心跳
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: _heartbeatInterval),
      (_) {
        if (_state == WebSocketState.connected) {
          try {
            _channel?.sink.add('PING');
          } catch (e) {
          }
        }
      },
    );
  }

  /// 处理收到的消息
  void _onMessage(dynamic data) {
    try {
      // PONG 响应，忽略
      if (data == 'PONG') {
        return;
      }

      final json = jsonDecode(data as String) as Map<String, dynamic>;
      _messageController.add(json);

      // 判断消息类型
      if (json.containsKey('msgId') && json.containsKey('success')) {
        // 这是消息确认（ACK）
        final ack = WsMessageAck.fromJson(json);
        _ackController.add(ack);
      } else if (json.containsKey('type')) {
        // 这是服务端推送
        final type = json['type'] as String;

        switch (type) {
          case WsMessageType.msgReceived:
            // 新消息通知
            final payload = json['payload'] as Map<String, dynamic>;
            final message = ImMessage.fromJson(payload);
            _newMessageController.add(message);
            break;
          case WsMessageType.syncResp:
            // 同步消息响应，交由外部处理
            break;
          case WsMessageType.systemNotify:
            // 系统通知，交由外部处理
            break;
        }
      }
    } catch (e) {
    }
  }

  /// 处理错误
  void _onError(dynamic error) {
    _updateState(WebSocketState.disconnected);
    _cleanup();
    _scheduleReconnect();
  }

  /// 处理连接关闭
  void _onDone() {
    _updateState(WebSocketState.disconnected);
    _cleanup();
    _scheduleReconnect();
  }

  /// 安排重连
  void _scheduleReconnect() {
    // 如果是主动断开，不重连
    if (_manualDisconnect) {
      return;
    }

    // 超过最大重连次数
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      return;
    }

    _reconnectAttempts++;
    _updateState(WebSocketState.reconnecting);

    // 指数退避策略：2^n 秒（最多 60 秒）
    final delay = (2 << (_reconnectAttempts - 1)).clamp(1, 60);

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delay), () async {
      
      // 尝试获取最新的 token
      String? token;
      if (_tokenGetter != null) {
        try {
          token = await _tokenGetter!();
        } catch (e) {
          // 如果获取 token 失败，继续使用旧的连接方式（可能失败）
          // 这种情况下，重连可能会失败，但至少会尝试
        }
      }
      
      // 如果没有 token 获取器或获取失败，无法重连
      if (token == null) {
        _updateState(WebSocketState.disconnected);
        return;
      }
      
      await _connectWithToken(token);
    });
  }

  /// 发送消息
  Future<void> sendMessage(WsMessage message) async {
    if (_state != WebSocketState.connected) {
      throw Exception('WebSocket 未连接');
    }

    try {
      final json = jsonEncode(message.toJson());
      _channel?.sink.add(json);
    } catch (e) {
      rethrow;
    }
  }

  /// 更新连接状态
  void _updateState(WebSocketState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);
    }
  }

  /// 释放资源
  void dispose() {
    disconnect();
    _stateController.close();
    _messageController.close();
    _ackController.close();
    _newMessageController.close();
  }
}

