class ProjectAttrModel {
  const ProjectAttrModel({
    required this.attrId,
    required this.code,
    required this.label,
    required this.dataType,
    this.boolValue,
    this.intValue,
    this.decimalValue,
    this.dateValue,
    this.textValue,
    this.optionId,
    this.optionLabel,
    this.multiOptionLabels,
  });

  final int attrId;
  final String code;
  final String label;
  final String dataType; // bool, int, decimal, date, text, option, multi_option
  final bool? boolValue;
  final int? intValue;
  final double? decimalValue;
  final String? dateValue; // ISO date string
  final String? textValue;
  final int? optionId;
  final String? optionLabel;
  final List<String>? multiOptionLabels;

  factory ProjectAttrModel.fromJson(Map<String, dynamic> json) {
    return ProjectAttrModel(
      attrId: json['attrId'] as int,
      code: json['code'] as String,
      label: json['label'] as String,
      dataType: json['dataType'] as String,
      boolValue: json['boolValue'] as bool?,
      intValue: json['intValue'] as int?,
      decimalValue: json['decimalValue'] != null
          ? (json['decimalValue'] as num).toDouble()
          : null,
      dateValue: json['dateValue'] as String?,
      textValue: json['textValue'] as String?,
      optionId: json['optionId'] as int?,
      optionLabel: json['optionLabel'] as String?,
      multiOptionLabels: (json['multiOptionLabels'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  /// 获取用于显示的值
  String get displayValue {
    switch (dataType) {
      case 'bool':
        if (boolValue == null) return '-';
        return boolValue! ? '是' : '否';
      case 'int':
        return intValue?.toString() ?? '-';
      case 'decimal':
        return decimalValue?.toString() ?? '-';
      case 'date':
        return dateValue ?? '-';
      case 'text':
        return textValue ?? '-';
      case 'option':
        return optionLabel ?? '-';
      case 'multi_option':
        if (multiOptionLabels == null || multiOptionLabels!.isEmpty) {
          return '-';
        }
        return multiOptionLabels!.join(', ');
      default:
        return '-';
    }
  }

  /// 是否有值
  bool get hasValue {
    switch (dataType) {
      case 'bool':
        return boolValue != null;
      case 'int':
        return intValue != null;
      case 'decimal':
        return decimalValue != null;
      case 'date':
        return dateValue != null && dateValue!.isNotEmpty;
      case 'text':
        return textValue != null && textValue!.isNotEmpty;
      case 'option':
        return optionId != null;
      case 'multi_option':
        return multiOptionLabels != null && multiOptionLabels!.isNotEmpty;
      default:
        return false;
    }
  }
}

