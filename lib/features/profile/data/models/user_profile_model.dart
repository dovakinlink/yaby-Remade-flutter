/// 用户详情模型
class UserProfileModel {
  const UserProfileModel({
    required this.id,
    required this.username,
    required this.nickname,
    required this.phone,
    this.email,
    this.avatar,
    required this.orgId,
    required this.status,
    required this.createTime,
    required this.updateTime,
    required this.roleCode,
    required this.roleName,
    required this.systemRoleId,
    required this.systemRoleName,
    required this.affiliationType,
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
  final String nickname;
  final String phone;
  final String? email;
  final String? avatar;
  final int orgId;
  final int status;
  final DateTime createTime;
  final DateTime updateTime;
  final String roleCode;
  final String roleName;
  final int systemRoleId;
  final String systemRoleName;
  final String affiliationType; // HOSPITAL/CRO/SPONSOR
  final int? hospitalId;
  final String? hospitalName;
  final int? departmentId;
  final String? departmentName;
  final int? companyId;
  final String? companyName;
  final String? personId; // 人员ID（t_person.c_id），用于查询参与的项目

  /// 获取归属单位名称
  String get affiliationName {
    switch (affiliationType) {
      case 'HOSPITAL':
        return hospitalName ?? '未知医院';
      case 'CRO':
      case 'SPONSOR':
        return companyName ?? '未知公司';
      default:
        return '未知单位';
    }
  }

  /// 获取归属单位类型显示文本
  String get affiliationTypeText {
    switch (affiliationType) {
      case 'HOSPITAL':
        return '医院';
      case 'CRO':
        return 'CRO公司';
      case 'SPONSOR':
        return '申办方';
      default:
        return '未知';
    }
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      avatar: json['avatar'] as String?,
      orgId: json['orgId'] as int? ?? 0,
      status: json['status'] as int? ?? 0,
      createTime: DateTime.parse(json['createTime'] as String),
      updateTime: DateTime.parse(json['updateTime'] as String),
      roleCode: json['roleCode'] as String? ?? '',
      roleName: json['roleName'] as String? ?? '',
      systemRoleId: json['systemRoleId'] as int? ?? 0,
      systemRoleName: json['systemRoleName'] as String? ?? '',
      affiliationType: json['affiliationType'] as String? ?? '',
      hospitalId: json['hospitalId'] != null ? json['hospitalId'] as int : null,
      hospitalName: json['hospitalName'] as String?,
      departmentId: json['departmentId'] != null ? json['departmentId'] as int : null,
      departmentName: json['departmentName'] as String?,
      companyId: json['companyId'] != null ? json['companyId'] as int : null,
      companyName: json['companyName'] as String?,
      personId: json['personId'] as String?,
    );
  }
}

