import 'package:yabai_app/features/messages/data/models/message_model.dart';

/// 消息列表响应模型，对应API文档中的分页响应格式
class MessageListResponse {
  final List<Message> data;
  final int page;
  final int size;
  final int total;
  final int pages;
  final bool hasNext;
  final bool hasPrev;

  const MessageListResponse({
    required this.data,
    required this.page,
    required this.size,
    required this.total,
    required this.pages,
    required this.hasNext,
    required this.hasPrev,
  });

  /// 是否为空列表
  bool get isEmpty => data.isEmpty;

  /// 是否还有更多数据
  bool get hasMore => hasNext;

  factory MessageListResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>? ?? [];
    final messages = dataList
        .map((item) => Message.fromJson(item as Map<String, dynamic>))
        .toList();

    return MessageListResponse(
      data: messages,
      page: json['page'] as int? ?? 1,
      size: json['size'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
      pages: json['pages'] as int? ?? 0,
      hasNext: json['hasNext'] as bool? ?? false,
      hasPrev: json['hasPrev'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((message) => message.toJson()).toList(),
      'page': page,
      'size': size,
      'total': total,
      'pages': pages,
      'hasNext': hasNext,
      'hasPrev': hasPrev,
    };
  }

  @override
  String toString() => 'MessageListResponse(total: $total, page: $page, hasNext: $hasNext)';
}
