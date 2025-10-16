import 'package:flutter/material.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/home/data/models/project_attr_model.dart';
import 'package:yabai_app/features/home/presentation/widgets/project_detail/project_detail_section_container.dart';

class ProjectAttrsSection extends StatelessWidget {
  const ProjectAttrsSection({
    super.key,
    required this.attrs,
    this.showTopDivider = true,
  });

  final List<ProjectAttrModel> attrs;
  final bool showTopDivider;

  @override
  Widget build(BuildContext context) {
    if (attrs.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ProjectDetailSectionContainer(
      showTopDivider: showTopDivider,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '自定义属性',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkNeutralText : null,
            ),
          ),
          const SizedBox(height: 16),
          ...attrs.asMap().entries.map((entry) {
            final index = entry.key;
            final attr = entry.value;
            return Column(
              children: [
                if (index > 0) const Divider(height: 24),
                _buildAttrItem(context, attr, isDark),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAttrItem(
    BuildContext context,
    ProjectAttrModel attr,
    bool isDark,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            attr.label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: _buildAttrValue(context, attr, isDark),
        ),
      ],
    );
  }

  Widget _buildAttrValue(
    BuildContext context,
    ProjectAttrModel attr,
    bool isDark,
  ) {
    // 多选显示为标签列表
    if (attr.dataType == 'multi_option' &&
        attr.multiOptionLabels != null &&
        attr.multiOptionLabels!.isNotEmpty) {
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: attr.multiOptionLabels!
            .map((label) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brandGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.brandGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.brandGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ))
            .toList(),
      );
    }

    // 单选显示为标签
    if (attr.dataType == 'option' && attr.optionLabel != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.brandGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.brandGreen.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            attr.optionLabel!,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.brandGreen,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    // 其他类型显示为文本
    return Text(
      attr.displayValue,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: isDark ? AppColors.darkNeutralText : null,
      ),
    );
  }
}
