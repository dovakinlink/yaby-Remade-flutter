import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/home/data/models/attr_definition_model.dart';

class FilterItemWidget extends StatelessWidget {
  const FilterItemWidget({
    super.key,
    required this.attr,
    this.value,
    required this.onChanged,
  });

  final AttrDefinitionModel attr;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标签
        Text(
          attr.label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkNeutralText : AppColors.lightNeutralText,
          ),
        ),
        if (attr.helpText != null && attr.helpText!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            attr.helpText!,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
            ),
          ),
        ],
        const SizedBox(height: 12),
        // 输入控件
        _buildInputWidget(context, isDark),
      ],
    );
  }

  Widget _buildInputWidget(BuildContext context, bool isDark) {
    switch (attr.dataType) {
      case 'bool':
        return _buildBoolInput(isDark);
      case 'option':
        return _buildOptionInput(isDark);
      case 'multi_option':
        return _buildMultiOptionInput(isDark);
      case 'text':
        return _buildTextInput(isDark);
      case 'int':
        return _buildIntInput(isDark);
      case 'decimal':
        return _buildDecimalInput(isDark);
      case 'date':
        return _buildDateInput(context, isDark);
      default:
        return Text('不支持的类型: ${attr.dataType}');
    }
  }

  // 布尔值输入（标签样式）
  Widget _buildBoolInput(bool isDark) {
    final boolValue = value as bool?;
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip(
          label: '是',
          isSelected: boolValue == true,
          isDark: isDark,
          onTap: () => onChanged(true),
        ),
        _buildFilterChip(
          label: '否',
          isSelected: boolValue == false,
          isDark: isDark,
          onTap: () => onChanged(false),
        ),
      ],
    );
  }

  // 单选输入（标签样式）
  Widget _buildOptionInput(bool isDark) {
    final enabledOptions = attr.enabledOptions;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: enabledOptions.map((option) {
        final isSelected = value == option.id;
        return _buildFilterChip(
          label: option.label,
          isSelected: isSelected,
          isDark: isDark,
          onTap: () => onChanged(option.id),
        );
      }).toList(),
    );
  }

  // 多选输入（标签样式）
  Widget _buildMultiOptionInput(bool isDark) {
    final enabledOptions = attr.enabledOptions;
    final selectedIds = (value as List<int>?) ?? [];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: enabledOptions.map((option) {
        final isSelected = selectedIds.contains(option.id);
        return _buildFilterChip(
          label: option.label,
          isSelected: isSelected,
          isDark: isDark,
          onTap: () {
            final newSelection = List<int>.from(selectedIds);
            if (isSelected) {
              newSelection.remove(option.id);
            } else {
              newSelection.add(option.id);
            }
            onChanged(newSelection);
          },
        );
      }).toList(),
    );
  }

  // 文本输入
  Widget _buildTextInput(bool isDark) {
    return TextField(
      controller: TextEditingController(text: value?.toString() ?? ''),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: attr.placeholder ?? '请输入${attr.label}',
        suffixText: attr.unit,
      ),
    );
  }

  // 整数输入
  Widget _buildIntInput(bool isDark) {
    return TextField(
      controller: TextEditingController(text: value?.toString() ?? ''),
      onChanged: (text) {
        final intValue = int.tryParse(text);
        onChanged(intValue);
      },
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        hintText: attr.placeholder ?? '请输入${attr.label}',
        suffixText: attr.unit,
      ),
    );
  }

  // 小数输入
  Widget _buildDecimalInput(bool isDark) {
    return TextField(
      controller: TextEditingController(text: value?.toString() ?? ''),
      onChanged: (text) {
        final doubleValue = double.tryParse(text);
        onChanged(doubleValue);
      },
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        hintText: attr.placeholder ?? '请输入${attr.label}',
        suffixText: attr.unit,
      ),
    );
  }

  // 日期输入
  Widget _buildDateInput(BuildContext context, bool isDark) {
    final dateValue = value as DateTime?;
    final dateText = dateValue != null
        ? '${dateValue.year}-${dateValue.month.toString().padLeft(2, '0')}-${dateValue.day.toString().padLeft(2, '0')}'
        : '';

    return InkWell(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: dateValue ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: AppColors.brandGreen,
                ),
              ),
              child: child!,
            );
          },
        );
        if (pickedDate != null) {
          onChanged(pickedDate);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          hintText: attr.placeholder ?? '请选择${attr.label}',
          suffixIcon: const Icon(Icons.calendar_today, size: 20),
        ),
        child: Text(
          dateText.isEmpty ? '' : dateText,
          style: TextStyle(
            color: dateText.isEmpty
                ? (isDark ? AppColors.darkSecondaryText : Colors.grey[600])
                : (isDark ? AppColors.darkNeutralText : null),
          ),
        ),
      ),
    );
  }

  // 构建筛选标签
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.brandGreen
                : (isDark
                    ? AppColors.darkFieldBackground
                    : AppColors.lightFieldBackground),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.brandGreen
                  : (isDark
                      ? AppColors.darkFieldBorder
                      : AppColors.lightFieldBorder),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                const Icon(
                  Icons.check,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark
                          ? AppColors.darkNeutralText
                          : AppColors.lightNeutralText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

