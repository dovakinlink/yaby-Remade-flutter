class UserProfile {
  final int id;
  final String username;
  final String? nickname;
  final String? phone;
  final String? email;
  final String? avatar;
  final int? orgId;
  final int status;
  final DateTime createTime;
  final DateTime updateTime;

  UserProfile({
    required this.id,
    required this.username,
    this.nickname,
    this.phone,
    this.email,
    this.avatar,
    this.orgId,
    required this.status,
    required this.createTime,
    required this.updateTime,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      username: json['username'] as String,
      nickname: json['nickname'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      avatar: json['avatar'] as String?,
      orgId: json['orgId'] as int?,
      status: json['status'] as int,
      createTime: DateTime.parse(json['createTime'] as String),
      updateTime: DateTime.parse(json['updateTime'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'nickname': nickname,
      'phone': phone,
      'email': email,
      'avatar': avatar,
      'orgId': orgId,
      'status': status,
      'createTime': createTime.toIso8601String(),
      'updateTime': updateTime.toIso8601String(),
    };
  }

  /// 是否为正常状态
  bool get isActive => status == 1;

  /// 是否被禁用
  bool get isDisabled => status == 0;

  /// 显示名称（优先使用昵称，其次用户名）
  String get displayName => nickname ?? username;

  /// 是否有头像
  bool get hasAvatar => avatar != null && avatar!.isNotEmpty;
}

