class ProjectStaffModel {
  const ProjectStaffModel({
    required this.personId,
    this.userId,
    this.avatar,
    required this.personName,
    required this.roleName,
    required this.isPrimary,
    this.note,
  });

  final String personId;
  final int? userId; // 用户ID，用于跳转到用户详情页
  final String? avatar; // 头像URL，用于显示用户头像
  final String personName;
  final String roleName; // CRC, PI, CRA等
  final bool isPrimary;
  final String? note;

  factory ProjectStaffModel.fromJson(Map<String, dynamic> json) {
    return ProjectStaffModel(
      personId: json['personId'] as String,
      userId: json['userId'] as int?,
      avatar: json['avatar'] as String?,
      personName: json['personName'] as String,
      roleName: json['roleName'] as String,
      isPrimary: json['isPrimary'] as bool,
      note: json['note'] as String?,
    );
  }

  /// 获取人员首字母（用于头像显示）
  String get initial {
    if (personName.isEmpty) return '?';
    return personName[0].toUpperCase();
  }

  /// 是否有备注
  bool get hasNote => note != null && note!.isNotEmpty;

  /// 是否有头像
  bool get hasAvatar => avatar != null && avatar!.isNotEmpty;

  /// 是否有用户ID（可点击跳转）
  bool get hasUserId => userId != null;
}

