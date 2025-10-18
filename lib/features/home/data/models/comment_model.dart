import 'package:yabai_app/core/config/env_config.dart';

class Comment {
  final int id;
  final int noticeId;
  final int commenterId;
  final String commenterName;
  final String? commenterAvatar;
  final String content;
  final int? replyToCommentId;
  final int? replyToUserId;
  final String? replyToName;
  final DateTime createdAt;
  final bool canDelete;

  const Comment({
    required this.id,
    required this.noticeId,
    required this.commenterId,
    required this.commenterName,
    this.commenterAvatar,
    required this.content,
    this.replyToCommentId,
    this.replyToUserId,
    this.replyToName,
    required this.createdAt,
    required this.canDelete,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as int,
      noticeId: json['noticeId'] as int,
      commenterId: json['commenterId'] as int,
      commenterName: json['commenterName'] as String? ?? '',
      commenterAvatar: json['commenterAvatar'] as String?,
      content: json['content'] as String? ?? '',
      replyToCommentId: json['replyToCommentId'] as int?,
      replyToUserId: json['replyToUserId'] as int?,
      replyToName: json['replyToName'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      canDelete: json['canDelete'] as bool? ?? false,
    );
  }

  /// 是否为回复评论
  bool get isReply => replyToCommentId != null;

  /// 获取完整的头像URL（带默认值）
  String get avatarUrl {
    if (commenterAvatar != null && commenterAvatar!.isNotEmpty) {
      // 如果已经是完整URL，直接返回
      if (commenterAvatar!.startsWith('http')) {
        return commenterAvatar!;
      }
      // 拼接服务器地址
      return '${EnvConfig.initialBaseUrl}$commenterAvatar';
    }
    return ''; // 返回空字符串，使用默认头像
  }

  /// 格式化时间显示
  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inSeconds < 60) {
      return '刚刚';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      // 超过7天显示具体日期
      final year = createdAt.year;
      final month = createdAt.month.toString().padLeft(2, '0');
      final day = createdAt.day.toString().padLeft(2, '0');
      
      // 如果是今年，不显示年份
      if (year == now.year) {
        return '$month-$day';
      }
      return '$year-$month-$day';
    }
  }

  /// 获取评论人姓名首字母（用于默认头像）
  String get nameInitial {
    if (commenterName.isEmpty) return '?';
    return commenterName.substring(0, 1).toUpperCase();
  }
}

