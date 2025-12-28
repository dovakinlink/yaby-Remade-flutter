/// 小白Agent - 查询请求模型
class XiaobaiQueryRequest {
  const XiaobaiQueryRequest({
    required this.question,
    required this.projectId,
    this.patientName,
    this.sessionId,
  });

  final String question;
  final int projectId;
  final String? patientName;
  final String? sessionId;

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'projectId': projectId,
      if (patientName != null) 'patientName': patientName,
      if (sessionId != null) 'sessionId': sessionId,
    };
  }
}

