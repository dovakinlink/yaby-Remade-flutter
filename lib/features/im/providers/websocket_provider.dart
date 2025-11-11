import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:yabai_app/features/im/data/services/websocket_service.dart';
import 'package:yabai_app/features/im/data/models/ws_message.dart';
import 'package:yabai_app/features/im/data/models/ws_message_ack.dart';
import 'package:yabai_app/features/im/data/models/im_message_model.dart';

/// WebSocket 连接状态管理
class WebSocketProvider extends ChangeNotifier {
  final WebSocketService _websocketService;

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

  /// 新消息回调
  Function(ImMessage)? onNewMessage;

  WebSocketProvider(this._websocketService) {
    _init();
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
      onNewMessage?.call(message);
    });
  }

  /// 连接 WebSocket
  Future<void> connect(String host, int port, String token) async {
    await _websocketService.connect(host, port, token);
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

