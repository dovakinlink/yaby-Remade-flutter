class ProjectStaffModel {
  const ProjectStaffModel({
    required this.personId,
    required this.personName,
    required this.roleName,
    required this.isPrimary,
    this.note,
  });

  final String personId;
  final String personName;
  final String roleName; // CRC, PI, CRA等
  final bool isPrimary;
  final String? note;

  factory ProjectStaffModel.fromJson(Map<String, dynamic> json) {
    return ProjectStaffModel(
      personId: json['personId'] as String,
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
}

