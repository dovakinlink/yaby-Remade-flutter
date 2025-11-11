/// 会话模型（对应 API 文档的 ConversationVO）
class Conversation {
  /// 会话ID（32字符）
  final String convId;

  /// 会话类型：SINGLE（单聊）/GROUP（群聊）/SYSTEM（系统）
  final ConversationType type;

  /// 会话标题（单聊为对方昵称，群聊为群名）
  final String? title;

  /// 会话头像URL
  final String? avatar;

  /// 最新消息seq
  final int lastMessageSeq;

  /// 最新消息时间
  final DateTime? lastMessageAt;

  /// 未读数量
  final int unreadCount;

  /// 创建时间
  final DateTime createdAt;

  /// 最后消息内容预览（用于列表显示）
  final String? lastMessagePreview;

  /// 新增：最后一条消息的原始内容（仅当 lastMessageType=TEXT 时为文本）
  final String? lastMessageContent;

  /// 新增：最后一条消息类型（TEXT/IMAGE/FILE/AUDIO/VIDEO/CARD/SYSTEM）
  final String? lastMessageType;

  /// 对方用户ID（仅单聊有效，用于防止重复创建会话）
  final int? targetUserId;

  Conversation({
    required this.convId,
    required this.type,
    this.title,
    this.avatar,
    required this.lastMessageSeq,
    this.lastMessageAt,
    required this.unreadCount,
    required this.createdAt,
    this.lastMessagePreview,
    this.lastMessageContent,
    this.lastMessageType,
    this.targetUserId,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      convId: json['convId'] as String,
      type: ConversationType.fromString(json['type'] as String),
      title: json['title'] as String?,
      avatar: json['avatar'] as String?,
      lastMessageSeq: json['lastMessageSeq'] as int? ?? 0,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'] as String)
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastMessagePreview: json['lastMessagePreview'] as String?,
      lastMessageContent: json['lastMessageContent'] as String?,
      lastMessageType: json['lastMessageType'] as String?,
      targetUserId: json['targetUserId'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'convId': convId,
      'type': type.value,
      'title': title,
      'avatar': avatar,
      'lastMessageSeq': lastMessageSeq,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'unreadCount': unreadCount,
      'createdAt': createdAt.toIso8601String(),
      'lastMessagePreview': lastMessagePreview,
      'lastMessageContent': lastMessageContent,
      'lastMessageType': lastMessageType,
      'targetUserId': targetUserId,
    };
  }

  Conversation copyWith({
    String? convId,
    ConversationType? type,
    String? title,
    String? avatar,
    int? lastMessageSeq,
    DateTime? lastMessageAt,
    int? unreadCount,
    DateTime? createdAt,
    String? lastMessagePreview,
    String? lastMessageContent,
    String? lastMessageType,
    int? targetUserId,
  }) {
    return Conversation(
      convId: convId ?? this.convId,
      type: type ?? this.type,
      title: title ?? this.title,
      avatar: avatar ?? this.avatar,
      lastMessageSeq: lastMessageSeq ?? this.lastMessageSeq,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      targetUserId: targetUserId ?? this.targetUserId,
    );
  }
}

/// 会话类型枚举
enum ConversationType {
  single('SINGLE'),
  group('GROUP'),
  system('SYSTEM');

  final String value;
  const ConversationType(this.value);

  static ConversationType fromString(String value) {
    return ConversationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ConversationType.single,
    );
  }
}

