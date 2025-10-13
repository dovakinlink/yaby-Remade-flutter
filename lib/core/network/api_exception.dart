class ApiException implements Exception {
  ApiException({required this.message, this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'ApiException(code: $code, message: $message)';
}
