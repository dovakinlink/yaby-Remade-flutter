class FilterValueModel {
  const FilterValueModel({
    required this.attrCode,
    required this.attrLabel,
    required this.dataType,
    this.value,
  });

  final String attrCode;
  final String attrLabel;
  final String dataType;
  final dynamic value; // 可以是 int, String, List<int>, bool, DateTime等

  /// 转换为API需要的格式（字符串）
  String? toApiValue() {
    if (value == null) return null;

    switch (dataType) {
      case 'option':
        // 单选返回选项ID
        return value.toString();
      case 'multi_option':
        // 多选返回逗号分隔的选项ID列表
        if (value is List) {
          final list = value as List;
          if (list.isEmpty) return null;
          return list.join(',');
        }
        return null;
      case 'bool':
        return (value as bool).toString();
      case 'int':
      case 'decimal':
        return value.toString();
      case 'text':
        final text = value.toString().trim();
        return text.isEmpty ? null : text;
      case 'date':
        if (value is DateTime) {
          return (value as DateTime).toIso8601String().split('T')[0];
        }
        return null;
      default:
        return value.toString();
    }
  }

  /// 获取用于显示的标签文本
  String getDisplayLabel(Map<int, String>? optionLabels) {
    if (value == null) return '';

    switch (dataType) {
      case 'option':
        // 单选显示选项标签
        if (optionLabels != null && value is int) {
          return optionLabels[value] ?? value.toString();
        }
        return value.toString();
      case 'multi_option':
        // 多选显示选项标签列表
        if (value is List && optionLabels != null) {
          final list = value as List<int>;
          final labels = list
              .map((id) => optionLabels[id] ?? id.toString())
              .join(', ');
          return labels;
        }
        return value.toString();
      case 'bool':
        return (value as bool) ? '是' : '否';
      case 'date':
        if (value is DateTime) {
          return (value as DateTime).toIso8601String().split('T')[0];
        }
        return value.toString();
      default:
        return value.toString();
    }
  }

  /// 复制并更新值
  FilterValueModel copyWith({dynamic value}) {
    return FilterValueModel(
      attrCode: attrCode,
      attrLabel: attrLabel,
      dataType: dataType,
      value: value,
    );
  }

  /// 判断是否有有效值
  bool get hasValue {
    if (value == null) return false;
    if (value is String && (value as String).trim().isEmpty) return false;
    if (value is List && (value as List).isEmpty) return false;
    return true;
  }
}

