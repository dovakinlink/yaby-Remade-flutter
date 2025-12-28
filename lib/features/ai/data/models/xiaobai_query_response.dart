/// 小白Agent - 查询响应模型
class XiaobaiQueryResponse {
  const XiaobaiQueryResponse({
    required this.answer,
    required this.question,
    required this.projectCode,
  });

  final String answer;
  final String question;
  final String projectCode;

  factory XiaobaiQueryResponse.fromJson(Map<String, dynamic> json) {
    // 处理嵌套的data结构
    final data = json['data'] as Map<String, dynamic>? ?? json;
    
    return XiaobaiQueryResponse(
      answer: data['answer'] as String? ?? '',
      question: data['question'] as String? ?? '',
      projectCode: data['project_code'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'answer': answer,
      'question': question,
      'project_code': projectCode,
    };
  }
}

