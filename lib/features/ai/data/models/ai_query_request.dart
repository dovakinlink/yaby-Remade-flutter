class AiQueryRequest {
  const AiQueryRequest({
    required this.inputAsText,
  });

  final String inputAsText;

  Map<String, dynamic> toJson() {
    return {
      'input_as_text': inputAsText,
    };
  }
}

