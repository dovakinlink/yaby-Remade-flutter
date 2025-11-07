import 'package:yabai_app/features/address_book/data/models/address_book_item_model.dart';

class AddressBookGroupModel {
  const AddressBookGroupModel({
    required this.initial,
    required this.items,
  });

  final String initial;
  final List<AddressBookItemModel> items;

  factory AddressBookGroupModel.fromJson(Map<String, dynamic> json) {
    return AddressBookGroupModel(
      initial: json['initial']?.toString() ?? '#',
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => AddressBookItemModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'initial': initial,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  /// 是否为特殊字符组（#）
  bool get isSpecialGroup => initial == '#';

  /// 该组的人员数量
  int get itemCount => items.length;
}

