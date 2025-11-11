/// 群成员模型（对应 API 文档的 GroupMemberVO）
class GroupMember {
  /// 用户ID
  final int userId;

  /// 用户姓名
  final String userName;

  /// 用户头像URL
  final String? userAvatar;

  /// 角色：0=普通成员，1=管理员，2=群主
  final int role;

  /// 角色名称
  final String roleName;

  /// 加入时间
  final DateTime joinAt;

  /// 是否被禁言
  final bool isMuted;

  GroupMember({
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.role,
    required this.roleName,
    required this.joinAt,
    required this.isMuted,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: json['userId'] as int,
      userName: json['userName'] as String,
      userAvatar: json['userAvatar'] as String?,
      role: json['role'] as int? ?? 0,
      roleName: json['roleName'] as String? ?? '成员',
      joinAt: DateTime.parse(json['joinAt'] as String),
      isMuted: json['isMuted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'role': role,
      'roleName': roleName,
      'joinAt': joinAt.toIso8601String(),
      'isMuted': isMuted,
    };
  }

  /// 是否是群主
  bool get isOwner => role == 2;

  /// 是否是管理员
  bool get isAdmin => role == 1;

  /// 是否是普通成员
  bool get isMember => role == 0;

  GroupMember copyWith({
    int? userId,
    String? userName,
    String? userAvatar,
    int? role,
    String? roleName,
    DateTime? joinAt,
    bool? isMuted,
  }) {
    return GroupMember(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      role: role ?? this.role,
      roleName: roleName ?? this.roleName,
      joinAt: joinAt ?? this.joinAt,
      isMuted: isMuted ?? this.isMuted,
    );
  }
}

