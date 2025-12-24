class PageResponse<T> {
  const PageResponse({
    required this.data,
    required this.page,
    required this.size,
    required this.total,
    required this.pages,
    required this.hasNext,
    required this.hasPrev,
  });

  final List<T> data;
  final int page;
  final int size;
  final int total;
  final int pages;
  final bool hasNext;
  final bool hasPrev;

  bool get isEmpty => data.isEmpty;
  bool get isNotEmpty => data.isNotEmpty;

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final rawList = json['data'];
    final items = rawList is List
        ? rawList
              .whereType<Map<String, dynamic>>()
              .map(fromJsonT)
              .toList()
        : <T>[];

    return PageResponse<T>(
      data: items,
      page: json['page'] as int? ?? 1,
      size: json['size'] as int? ?? items.length,
      total: json['total'] as int? ?? items.length,
      pages: json['pages'] as int? ?? 1,
      hasNext: json['hasNext'] as bool? ?? false,
      hasPrev: json['hasPrev'] as bool? ?? false,
    );
  }

  factory PageResponse.empty() {
    return PageResponse<T>(
      data: <T>[],
      page: 1,
      size: 0,
      total: 0,
      pages: 0,
      hasNext: false,
      hasPrev: false,
    );
  }
}
