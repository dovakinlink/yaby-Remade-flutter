/// 群组模型（对应 API 文档的 GroupVO）
class Group {
  /// 会话ID（同时也是群ID）
  final String convId;

  /// 群名称
  final String name;

  /// 群头像URL
  final String? avatar;

  /// 群公告
  final String? notice;

  /// 群主用户ID
  final int ownerUserId;

  /// 群成员数量
  final int memberCount;

  /// 加群是否需要审核
  final bool joinApprove;

  /// 创建时间
  final DateTime createdAt;

  Group({
    required this.convId,
    required this.name,
    this.avatar,
    this.notice,
    required this.ownerUserId,
    required this.memberCount,
    required this.joinApprove,
    required this.createdAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      convId: json['convId'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      notice: json['notice'] as String?,
      ownerUserId: json['ownerUserId'] as int,
      memberCount: json['memberCount'] as int? ?? 0,
      joinApprove: json['joinApprove'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'convId': convId,
      'name': name,
      'avatar': avatar,
      'notice': notice,
      'ownerUserId': ownerUserId,
      'memberCount': memberCount,
      'joinApprove': joinApprove,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Group copyWith({
    String? convId,
    String? name,
    String? avatar,
    String? notice,
    int? ownerUserId,
    int? memberCount,
    bool? joinApprove,
    DateTime? createdAt,
  }) {
    return Group(
      convId: convId ?? this.convId,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      notice: notice ?? this.notice,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      memberCount: memberCount ?? this.memberCount,
      joinApprove: joinApprove ?? this.joinApprove,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

