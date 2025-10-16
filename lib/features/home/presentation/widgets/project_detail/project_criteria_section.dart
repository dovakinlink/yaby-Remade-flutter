import 'package:flutter/material.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/home/data/models/project_criteria_model.dart';
import 'package:yabai_app/features/home/presentation/widgets/project_detail/project_detail_section_container.dart';

class ProjectCriteriaSection extends StatelessWidget {
  const ProjectCriteriaSection({
    super.key,
    required this.criteria,
    this.showTopDivider = true,
  });

  final List<ProjectCriteriaModel> criteria;
  final bool showTopDivider;

  @override
  Widget build(BuildContext context) {
    if (criteria.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inclusionCriteria =
        criteria.where((c) => c.isInclusion).toList();
    final exclusionCriteria =
        criteria.where((c) => c.isExclusion).toList();

    return ProjectDetailSectionContainer(
      showTopDivider: showTopDivider,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '入排标准',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkNeutralText : null,
            ),
          ),
          const SizedBox(height: 20),
          // 入组标准
          if (inclusionCriteria.isNotEmpty) ...[
            _buildCriteriaGroup(
              context,
              title: '入组标准',
              criteria: inclusionCriteria,
              color: AppColors.brandGreen,
              isDark: isDark,
            ),
            if (exclusionCriteria.isNotEmpty) const SizedBox(height: 24),
          ],
          // 排除标准
          if (exclusionCriteria.isNotEmpty)
            _buildCriteriaGroup(
              context,
              title: '排除标准',
              criteria: exclusionCriteria,
              color: const Color(0xFFEF4444),
              isDark: isDark,
            ),
        ],
      ),
    );
  }

  Widget _buildCriteriaGroup(
    BuildContext context, {
    required String title,
    required List<ProjectCriteriaModel> criteria,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkNeutralText : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...criteria.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${item.itemNo}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.content,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: isDark
                            ? AppColors.darkNeutralText
                            : const Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
