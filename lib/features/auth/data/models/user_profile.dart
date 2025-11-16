class UserProfile {
  const UserProfile({
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
    this.roleCode,
    this.roleName,
    this.systemRoleId,
    this.systemRoleName,
    this.affiliationType,
    this.hospitalId,
    this.hospitalName,
    this.departmentId,
    this.departmentName,
    this.companyId,
    this.companyName,
    this.personId,
  });

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

  final String? roleCode;
  final String? roleName;
  final int? systemRoleId;
  final String? systemRoleName;
  final String? affiliationType;
  final int? hospitalId;
  final String? hospitalName;
  final int? departmentId;
  final String? departmentName;
  final int? companyId;
  final String? companyName;
  final String? personId; // 人员ID（t_person.c_id），用于查询参与的项目

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: _parseRequiredInt(json['id']),
      username: json['username']?.toString() ?? '',
      nickname: json['nickname'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      avatar: json['avatar'] as String?,
      orgId: _parseNullableInt(json['orgId']),
      status: _parseRequiredInt(json['status']),
      createTime: _parseDate(json['createTime']),
      updateTime: _parseDate(json['updateTime']),
      roleCode: json['roleCode'] as String?,
      roleName: json['roleName'] as String?,
      systemRoleId: _parseNullableInt(json['systemRoleId']),
      systemRoleName: json['systemRoleName'] as String?,
      affiliationType: json['affiliationType'] as String?,
      hospitalId: _parseNullableInt(json['hospitalId']),
      hospitalName: json['hospitalName'] as String?,
      departmentId: _parseNullableInt(json['departmentId']),
      departmentName: json['departmentName'] as String?,
      companyId: _parseNullableInt(json['companyId']),
      companyName: json['companyName'] as String?,
      personId: json['personId'] as String?,
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
      'roleCode': roleCode,
      'roleName': roleName,
      'systemRoleId': systemRoleId,
      'systemRoleName': systemRoleName,
      'affiliationType': affiliationType,
      'hospitalId': hospitalId,
      'hospitalName': hospitalName,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'companyId': companyId,
      'companyName': companyName,
      'personId': personId,
    };
  }

  bool get isActive => status == 1;

  bool get isDisabled => status == 0;

  String get displayName => nickname ?? username;

  bool get hasAvatar => avatar != null && avatar!.isNotEmpty;

  String? get primaryRoleName =>
      roleName?.isNotEmpty == true ? roleName : systemRoleName;

  static int _parseRequiredInt(dynamic value, {int fallback = 0}) {
    return _parseNullableInt(value) ?? fallback;
  }

  static int? _parseNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String && value.isNotEmpty) {
      return int.tryParse(value);
    }
    return null;
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
