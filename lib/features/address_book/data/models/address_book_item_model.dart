class AddressBookItemModel {
  const AddressBookItemModel({
    required this.pk,
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
}

