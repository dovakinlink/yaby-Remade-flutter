/// 新版 AI 查询请求模型（通过 Spring Boot 代理）
class AiQueryRequestV2 {
  const AiQueryRequestV2({
    required this.inputAsText,
    this.sessionId,
  });

  final String inputAsText;
  final String? sessionId;

  Map<String, dynamic> toJson() {
    return {
      'inputAsText': inputAsText,
      if (sessionId != null) 'sessionId': sessionId,
    };
  }
}

