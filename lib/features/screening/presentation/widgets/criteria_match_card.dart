import 'package:flutter/material.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/home/data/models/project_criteria_model.dart';

/// 单个入排条件的匹配界面卡片
class CriteriaMatchCard extends StatelessWidget {
  const CriteriaMatchCard({
    super.key,
    required this.criterion,
    required this.matchResult,
    required this.remark,
    required this.onMatchResultChanged,
    required this.onRemarkChanged,
  });

  final ProjectCriteriaModel criterion;
  final bool? matchResult; // true=匹配, false=不匹配, null=未选择
  final String remark;
  final ValueChanged<bool> onMatchResultChanged;
  final ValueChanged<String> onRemarkChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDark ? AppColors.darkCardBackground : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 条件序号和内容
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: criterion.isInclusion
                        ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
                        : const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${criterion.itemNo}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: criterion.isInclusion
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    criterion.content,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.darkNeutralText
                          : AppColors.lightNeutralText,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 是/否 Radio 单选
            Row(
              children: [
                Expanded(
                  child: _RadioOption(
                    label: '是',
                    value: true,
                    groupValue: matchResult,
                    onChanged: onMatchResultChanged,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _RadioOption(
                    label: '否',
                    value: false,
                    groupValue: matchResult,
                    onChanged: onMatchResultChanged,
                    isDark: isDark,
                  ),
                ),
              ],
            ),

            // 备注输入框
            if (matchResult != null) ...[
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  hintText: '备注（可选）',
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : const Color(0xFF94A3B8),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkFieldBackground
                      : AppColors.lightFieldBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.darkNeutralText
                      : AppColors.lightNeutralText,
                ),
                maxLines: 2,
                onChanged: onRemarkChanged,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Radio 选项组件
class _RadioOption extends StatelessWidget {
  const _RadioOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.isDark,
  });

  final String label;
  final bool value;
  final bool? groupValue;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isSelected = groupValue == value;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandGreen.withValues(alpha: 0.1)
              : (isDark
                  ? AppColors.darkFieldBackground
                  : AppColors.lightFieldBackground),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.brandGreen
                : (isDark
                    ? AppColors.darkFieldBorder
                    : AppColors.lightFieldBorder),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Radio<bool>(
              value: value,
              groupValue: groupValue,
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
              activeColor: AppColors.brandGreen,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(
                horizontal: -4,
                vertical: -4,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? AppColors.brandGreen
                    : (isDark
                        ? AppColors.darkNeutralText
                        : AppColors.lightNeutralText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

