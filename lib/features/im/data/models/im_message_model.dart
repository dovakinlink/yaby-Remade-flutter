import 'message_content.dart';

/// IM 消息模型（对应 API 文档的 ImMessageVO）
class ImMessage {
  /// 消息ID
  final int id;

  /// 会话ID
  final String convId;

  /// 消息序号（会话内递增）
  final int seq;

  /// 发送者用户ID
  final int senderUserId;

  /// 发送者姓名
  final String? senderName;

  /// 发送者头像
  final String? senderAvatar;

  /// 消息类型
  final String msgType;

  /// 消息内容
  final MessageContent body;

  /// @的用户ID列表
  final List<int>? mentions;

  /// 是否被撤回
  final bool isRevoked;

  /// 撤回时间
  final DateTime? revokeAt;

  /// 创建时间
  final DateTime createdAt;

  /// 客户端消息ID（用于消息追踪和去重）
  final String? clientMsgId;

  /// 本地状态（发送中、已送达、失败等）
  final MessageStatus? localStatus;

  ImMessage({
    required this.id,
    required this.convId,
    required this.seq,
    required this.senderUserId,
    this.senderName,
    this.senderAvatar,
    required this.msgType,
    required this.body,
    this.mentions,
    required this.isRevoked,
    this.revokeAt,
    required this.createdAt,
    this.clientMsgId,
    this.localStatus,
  });

  factory ImMessage.fromJson(Map<String, dynamic> json) {
    final bodyJson = json['body'] as Map<String, dynamic>? ?? {};
    final msgType = json['msgType'] as String? ?? 'TEXT';
    
    return ImMessage(
      id: json['id'] as int? ?? 0,
      convId: json['convId'] as String? ?? '',
      seq: json['seq'] as int? ?? 0,
      senderUserId: json['senderUserId'] as int? ?? 0,
      senderName: json['senderName'] as String?,
      senderAvatar: json['senderAvatar'] as String?,
      msgType: msgType,
      body: MessageContent.fromJson(msgType, bodyJson),
      mentions: (json['mentions'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
      isRevoked: json['isRevoked'] as bool? ?? false,
      revokeAt: json['revokeAt'] != null
          ? DateTime.parse(json['revokeAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      clientMsgId: json['clientMsgId'] as String?,
      localStatus: json['localStatus'] != null
          ? MessageStatus.fromString(json['localStatus'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'convId': convId,
      'seq': seq,
      'senderUserId': senderUserId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'msgType': msgType,
      'body': body.toJson(),
      'mentions': mentions,
      'isRevoked': isRevoked,
      'revokeAt': revokeAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'clientMsgId': clientMsgId,
      'localStatus': localStatus?.value,
    };
  }

  ImMessage copyWith({
    int? id,
    String? convId,
    int? seq,
    int? senderUserId,
    String? senderName,
    String? senderAvatar,
    String? msgType,
    MessageContent? body,
    List<int>? mentions,
    bool? isRevoked,
    DateTime? revokeAt,
    DateTime? createdAt,
    String? clientMsgId,
    MessageStatus? localStatus,
  }) {
    return ImMessage(
      id: id ?? this.id,
      convId: convId ?? this.convId,
      seq: seq ?? this.seq,
      senderUserId: senderUserId ?? this.senderUserId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      msgType: msgType ?? this.msgType,
      body: body ?? this.body,
      mentions: mentions ?? this.mentions,
      isRevoked: isRevoked ?? this.isRevoked,
      revokeAt: revokeAt ?? this.revokeAt,
      createdAt: createdAt ?? this.createdAt,
      clientMsgId: clientMsgId ?? this.clientMsgId,
      localStatus: localStatus ?? this.localStatus,
    );
  }

  /// 获取消息内容预览文本
  String getPreviewText() {
    if (isRevoked) {
      return '[消息已撤回]';
    }

    switch (msgType) {
      case 'TEXT':
        return (body as TextContent).text;
      case 'IMAGE':
        return '[图片]';
      case 'FILE':
        return '[文件]';
      case 'AUDIO':
        return '[语音]';
      case 'VIDEO':
        return '[视频]';
      case 'CARD':
        return '[卡片消息]';
      case 'SYSTEM':
        return '[系统消息]';
      default:
        return '[未知消息类型]';
    }
  }
}

/// 消息本地状态枚举
enum MessageStatus {
  sending('sending'), // 发送中
  sent('sent'), // 已送达
  failed('failed'); // 发送失败

  final String value;
  const MessageStatus(this.value);

  static MessageStatus fromString(String value) {
    return MessageStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => MessageStatus.sending,
    );
  }
}

