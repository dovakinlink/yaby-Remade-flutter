class PageResponse<T> {
  final List<T> data;
  final int page;
  final int size;
  final int total;
  final int pages;
  final bool hasNext;
  final bool hasPrev;

  PageResponse({
    required this.data,
    required this.page,
    required this.size,
    required this.total,
    required this.pages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory PageResponse.empty() {
    return PageResponse(
      data: [],
      page: 1,
      size: 0,
      total: 0,
      pages: 0,
      hasNext: false,
      hasPrev: false,
    );
  }

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PageResponse(
      data: (json['data'] as List)
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      page: json['page'] as int,
      size: json['size'] as int,
      total: json['total'] as int,
      pages: json['pages'] as int,
      hasNext: json['hasNext'] as bool,
      hasPrev: json['hasPrev'] as bool,
    );
  }
}

