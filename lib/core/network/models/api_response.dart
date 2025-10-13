class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.code,
    required this.message,
    this.data,
  });

  final bool success;
  final String code;
  final String message;
  final T? data;

  bool get hasData => data != null;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(Object? rawData)? dataParser,
  }) {
    final rawData = json['data'];
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      code: json['code'] as String? ?? '',
      message: json['message'] as String? ?? '',
      data: dataParser != null
          ? dataParser(rawData)
          : rawData is T
          ? rawData
          : null,
    );
  }
}
