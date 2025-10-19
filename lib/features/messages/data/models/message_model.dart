import 'dart:convert';

/// 消息模型，对应API文档中的消息数据结构
class Message {
  final int id;
  final String category;
  final String resourceType;
  final int resourceId;
  final String title;
  final String contentExcerpt;
  final String fromUserName;
  final String extraJson;
  final int isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.category,
    required this.resourceType,
    required this.resourceId,
    required this.title,
    required this.contentExcerpt,
    required this.fromUserName,
    required this.extraJson,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  /// 是否为未读消息
  bool get isUnread => isRead == 0;

  /// 解析 extraJson 字段
  Map<String, dynamic> get extraData {
    try {
      return jsonDecode(extraJson);
    } catch (e) {
      return {};
    }
  }

  /// 获取跳转所需的帖子ID
  int? get noticeId {
    final extra = extraData;
    return extra['noticeId'] as int?;
  }

  /// 获取跳转所需的评论ID
  int? get commentId {
    final extra = extraData;
    return extra['commentId'] as int?;
  }

  /// 获取回复评论ID（仅在回复评论时有值）
  int? get replyToCommentId {
    final extra = extraData;
    return extra['replyToCommentId'] as int?;
  }

  /// 获取帖子标题（如果有的话）
  String? get noticeTitle {
    final extra = extraData;
    return extra['noticeTitle'] as String?;
  }

  /// 获取消息类型的显示文本
  String get categoryDisplayText {
    switch (category) {
      case 'NOTICE_COMMENT':
        return '评论了你的帖子';
      case 'COMMENT_REPLY':
        return '回复了你的评论';
      default:
        return '发送了消息';
    }
  }

  /// 获取消息时间的友好显示
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${createdAt.month}月${createdAt.day}日';
    }
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as int,
      category: json['category'] as String,
      resourceType: json['resourceType'] as String,
      resourceId: json['resourceId'] as int,
      title: json['title'] as String,
      contentExcerpt: json['contentExcerpt'] as String,
      fromUserName: json['fromUserName'] as String,
      extraJson: json['extraJson'] as String,
      isRead: json['isRead'] as int,
      readAt: json['readAt'] != null 
          ? DateTime.parse(json['readAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'resourceType': resourceType,
      'resourceId': resourceId,
      'title': title,
      'contentExcerpt': contentExcerpt,
      'fromUserName': fromUserName,
      'extraJson': extraJson,
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Message(id: $id, title: $title, isRead: $isRead)';
}
