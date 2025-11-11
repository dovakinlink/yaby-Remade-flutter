/// WebSocket 消息确认（服务端 -> 客户端）
class WsMessageAck {
  /// 原消息ID（与客户端发送的 msgId 对应）
  final String msgId;

  /// 是否成功
  final bool success;

  /// 响应数据
  final Map<String, dynamic>? data;

  /// 错误信息
  final String? error;

  WsMessageAck({
    required this.msgId,
    required this.success,
    this.data,
    this.error,
  });

  factory WsMessageAck.fromJson(Map<String, dynamic> json) {
    return WsMessageAck(
      msgId: json['msgId'] as String,
      success: json['success'] as bool,
      data: json['data'] as Map<String, dynamic>?,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'msgId': msgId,
      'success': success,
      'data': data,
      'error': error,
    };
  }

  /// 获取消息序号（从 data 中提取）
  int? get seq => data?['seq'] as int?;

  /// 获取消息ID（从 data 中提取）
  int? get messageId => data?['messageId'] as int?;
}

