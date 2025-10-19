import 'package:flutter/material.dart';
import 'package:yabai_app/core/theme/app_theme.dart';

/// 筛查状态筛选组件
class ScreeningStatusFilter extends StatelessWidget {
  const ScreeningStatusFilter({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  final String? currentFilter;
  final ValueChanged<String?> onFilterChanged;

  static const _filters = <_FilterOption>[
    _FilterOption(null, '全部'),
    _FilterOption('PENDING', '待审核'),
    _FilterOption('CRC_REVIEW', '审核中'),
    _FilterOption('MATCH_FAILED', '筛查失败'),
    _FilterOption('ICF_SIGNED', '已知情'),
    _FilterOption('ICF_FAILED', '知情失败'),
    _FilterOption('ENROLLED', '已入组'),
    _FilterOption('EXITED', '已出组'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = currentFilter == filter.code;

          return _FilterChipButton(
            label: filter.label,
            isSelected: isSelected,
            isDark: isDark,
            onTap: () => onFilterChanged(filter.code),
          );
        },
      ),
    );
  }
}

/// 筛选选项数据类
class _FilterOption {
  const _FilterOption(this.code, this.label);

  final String? code;
  final String label;
}

/// 筛选按钮组件
class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
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
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
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
          ),
        ),
      ),
    );
  }
}

