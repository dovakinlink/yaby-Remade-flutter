/// 小白Agent - 会话模型（用于会话列表）
class XiaobaiSessionModel {
  const XiaobaiSessionModel({
    required this.sessionId,
    required this.title,
    required this.messageCount,
    required this.lastMessageAt,
    required this.createdAt,
  });

  final String sessionId;
  final String title;
  final int messageCount;
  final DateTime lastMessageAt;
  final DateTime createdAt;

  factory XiaobaiSessionModel.fromJson(Map<String, dynamic> json) {
    return XiaobaiSessionModel(
      sessionId: json['sessionId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      messageCount: json['messageCount'] as int? ?? 0,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'] as String)
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'title': title,
      'messageCount': messageCount,
      'lastMessageAt': lastMessageAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
