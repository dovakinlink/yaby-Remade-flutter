/// WebSocket 消息包装（客户端 -> 服务端）
class WsMessage {
  /// 消息类型
  final String type;

  /// 消息负载
  final Map<String, dynamic> payload;

  /// 客户端消息ID（用于追踪）
  final String msgId;

  /// 时间戳
  final int timestamp;

  WsMessage({
    required this.type,
    required this.payload,
    required this.msgId,
    required this.timestamp,
  });

  factory WsMessage.fromJson(Map<String, dynamic> json) {
    return WsMessage(
      type: json['type'] as String,
      payload: json['payload'] as Map<String, dynamic>? ?? {},
      msgId: json['msgId'] as String,
      timestamp: json['timestamp'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'payload': payload,
      'msgId': msgId,
      'timestamp': timestamp,
    };
  }

  /// 创建发送消息的 WebSocket 消息
  static WsMessage createSendMessage({
    required String msgId,
    required String convId,
    required String msgType,
    required Map<String, dynamic> content,
    List<int>? mentions,
    bool? mentionAll,
  }) {
    return WsMessage(
      type: 'SEND_MSG',
      msgId: msgId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      payload: {
        'convId': convId,
        'msgType': msgType,
        'content': content,
        if (mentions != null) 'mentions': mentions,
        if (mentionAll != null) 'mentionAll': mentionAll,
      },
    );
  }

  /// 创建同步消息请求的 WebSocket 消息
  static WsMessage createSyncRequest({
    required String msgId,
    required String convId,
    required int fromSeq,
    int? limit,
  }) {
    return WsMessage(
      type: 'SYNC_REQ',
      msgId: msgId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      payload: {
        'convId': convId,
        'fromSeq': fromSeq,
        if (limit != null) 'limit': limit,
      },
    );
  }

  /// 创建已读确认的 WebSocket 消息
  static WsMessage createReadAck({
    required String msgId,
    required String convId,
    required int seq,
  }) {
    return WsMessage(
      type: 'READ_ACK',
      msgId: msgId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      payload: {
        'convId': convId,
        'seq': seq,
      },
    );
  }
}

/// WebSocket 消息类型（服务端推送）
class WsMessageType {
  /// 新消息通知
  static const msgReceived = 'MSG_RECEIVED';

  /// 同步消息响应
  static const syncResp = 'SYNC_RESP';

  /// 系统通知
  static const systemNotify = 'SYSTEM_NOTIFY';
}

