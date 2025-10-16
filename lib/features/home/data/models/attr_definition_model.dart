import 'package:yabai_app/features/home/data/models/attr_option_model.dart';

class AttrDefinitionModel {
  const AttrDefinitionModel({
    required this.id,
    required this.code,
    required this.label,
    required this.dataType,
    required this.control,
    required this.required,
    required this.searchable,
    this.unit,
    this.placeholder,
    this.helpText,
    required this.sort,
    required this.options,
  });

  final int id;
  final String code;
  final String label;
  final String dataType; // bool, int, decimal, date, text, option, multi_option
  final String control; // switch, input, select, multi_select, date_picker, etc.
  final bool required;
  final bool searchable;
  final String? unit;
  final String? placeholder;
  final String? helpText;
  final int sort;
  final List<AttrOptionModel> options;

  factory AttrDefinitionModel.fromJson(Map<String, dynamic> json) {
    return AttrDefinitionModel(
      id: json['id'] as int,
      code: json['code'] as String,
      label: json['label'] as String,
      dataType: json['dataType'] as String,
      control: json['control'] as String,
      required: json['required'] as bool,
      searchable: json['searchable'] as bool,
      unit: json['unit'] as String?,
      placeholder: json['placeholder'] as String?,
      helpText: json['helpText'] as String?,
      sort: json['sort'] as int,
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => AttrOptionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// 是否为选项类型（单选或多选）
  bool get isOptionType =>
      dataType == 'option' || dataType == 'multi_option';

  /// 获取启用的选项
  List<AttrOptionModel> get enabledOptions =>
      options.where((opt) => opt.enabled).toList();
}

