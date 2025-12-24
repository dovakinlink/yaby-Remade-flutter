/// AI 聊天记录模型（对应后端 t_ai_chat_log 表）
class AiChatLogModel {
  const AiChatLogModel({
    required this.id,
    required this.userId,
    required this.orgId,
    required this.sessionId,
    required this.userQuestion,
    required this.aiResponse,
    required this.responseTimeMs,
    required this.status,
    this.errorMessage,
    required this.createdAt,
  });

  final int id;
  final int userId;
  final int orgId;
  final String sessionId;
  final String userQuestion;
  final String aiResponse;
  final int responseTimeMs;
  final String status; // SUCCESS, ERROR, PENDING
  final String? errorMessage;
  final DateTime createdAt;

  factory AiChatLogModel.fromJson(Map<String, dynamic> json) {
    return AiChatLogModel(
      id: json['id'] as int? ?? 0,
      userId: json['userId'] as int? ?? 0,
      orgId: json['orgId'] as int? ?? 0,
      sessionId: json['sessionId'] as String? ?? '',
      userQuestion: json['userQuestion'] as String? ?? '',
      aiResponse: json['aiResponse'] as String? ?? '',
      responseTimeMs: json['responseTimeMs'] as int? ?? 0,
      status: json['status'] as String? ?? 'PENDING',
      errorMessage: json['errorMessage'] as String?,
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'orgId': orgId,
      'sessionId': sessionId,
      'userQuestion': userQuestion,
      'aiResponse': aiResponse,
      'responseTimeMs': responseTimeMs,
      'status': status,
      'errorMessage': errorMessage,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

