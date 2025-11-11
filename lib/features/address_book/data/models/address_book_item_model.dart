class AddressBookItemModel {
  const AddressBookItemModel({
    required this.pk,
    this.userId,
    required this.name,
    required this.nameInitial,
    required this.phone,
    this.email,
    this.roleCode,
    this.roleName,
    this.affiliationType,
    this.avatar,
    required this.srcType,
  });

  final String pk;
  final int? userId; // 用户ID，用于IM单聊（联系人类型为null）
  final String name;
  final String nameInitial;
  final String phone;
  final String? email;
  final String? roleCode;
  final String? roleName;
  final String? affiliationType;
  final String? avatar;
  final String srcType;

  factory AddressBookItemModel.fromJson(Map<String, dynamic> json) {
    return AddressBookItemModel(
      pk: json['pk']?.toString() ?? '',
      userId: json['userId'] as int?, // 直接解析为 int，可为 null
      name: json['name']?.toString() ?? '',
      nameInitial: json['nameInitial']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      roleCode: json['roleCode']?.toString(),
      roleName: json['roleName']?.toString(),
      affiliationType: json['affiliationType']?.toString(),
      avatar: json['avatar']?.toString(),
      srcType: json['srcType']?.toString() ?? 'PERSON',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pk': pk,
      'userId': userId,
      'name': name,
      'nameInitial': nameInitial,
      'phone': phone,
      'email': email,
      'roleCode': roleCode,
      'roleName': roleName,
      'affiliationType': affiliationType,
      'avatar': avatar,
      'srcType': srcType,
    };
  }

  /// 是否来自人员表
  bool get isFromPerson => srcType == 'PERSON';

  /// 是否来自联系人表
  bool get isFromContact => srcType == 'CONTACT';

  /// 是否可以发起IM单聊（有userId）
  bool get canStartImChat => userId != null;

  /// 获取简化的角色名称
  /// 将"主要研究者"显示为"PI"，"临床研究协调员"显示为"CRC"
  String? get displayRoleName {
    if (roleName == null || roleName!.isEmpty) {
      return null;
    }
    
    // 根据roleCode或roleName进行转换
    if (roleCode == 'PI' || roleName == '主要研究者') {
      return 'PI';
    } else if (roleCode == 'CRC' || roleName == '临床研究协调员') {
      return 'CRC';
    }
    
    // 其他角色保持原样
    return roleName;
  }
}

