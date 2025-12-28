/// 小白Agent - 会话详情模型
class XiaobaiSessionDetailModel {
  const XiaobaiSessionDetailModel({
    required this.sessionId,
    required this.title,
    this.projectId,
    this.projectName,
    required this.messages,
  });

  final String sessionId;
  final String title;
  final int? projectId;
  final String? projectName;
  final List<XiaobaiChatLogModel> messages;

  factory XiaobaiSessionDetailModel.fromJson(Map<String, dynamic> json) {
    final messagesList = json['messages'] as List<dynamic>? ?? [];
    return XiaobaiSessionDetailModel(
      sessionId: json['sessionId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      projectId: json['projectId'] as int?,
      projectName: json['projectName'] as String?,
      messages: messagesList
          .map((e) => XiaobaiChatLogModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'title': title,
      'projectId': projectId,
      'projectName': projectName,
      'messages': messages.map((e) => e.toJson()).toList(),
    };
  }
}

/// 小白Agent - 聊天记录模型
class XiaobaiChatLogModel {
  const XiaobaiChatLogModel({
    required this.id,
    required this.sessionId,
    required this.userQuestion,
    required this.aiResponse,
    required this.responseTimeMs,
    required this.status,
    this.errorMessage,
    required this.createdAt,
  });

  final int id;
  final String sessionId;
  final String userQuestion;
  final String aiResponse;
  final int responseTimeMs;
  final String status;
  final String? errorMessage;
  final DateTime createdAt;

  factory XiaobaiChatLogModel.fromJson(Map<String, dynamic> json) {
    return XiaobaiChatLogModel(
      id: json['id'] as int? ?? 0,
      sessionId: json['sessionId'] as String? ?? '',
      userQuestion: json['userQuestion'] as String? ?? '',
      aiResponse: json['aiResponse'] as String? ?? '',
      responseTimeMs: json['responseTimeMs'] as int? ?? 0,
      status: json['status'] as String? ?? 'SUCCESS',
      errorMessage: json['errorMessage'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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

