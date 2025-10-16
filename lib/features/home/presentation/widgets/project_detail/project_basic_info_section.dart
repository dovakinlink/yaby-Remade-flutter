import 'package:flutter/material.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/home/data/models/project_detail_model.dart';
import 'package:yabai_app/features/home/presentation/widgets/project_detail/project_detail_section_container.dart';

class ProjectBasicInfoSection extends StatelessWidget {
  const ProjectBasicInfoSection({
    super.key,
    required this.project,
    this.showTopDivider = false,
  });

  final ProjectDetailModel project;
  final bool showTopDivider;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return ProjectDetailSectionContainer(
      showTopDivider: showTopDivider,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 项目名称
          Text(
            project.projName,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: isDark ? AppColors.darkNeutralText : null,
            ),
          ),
          if (project.shortTitle != null) ...[
            const SizedBox(height: 8),
            Text(
              project.shortTitle!,
              style: textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          // 申办方
          if (project.sponsorName != null)
            _buildInfoRow(
              context,
              icon: Icons.business_outlined,
              label: '申办方',
              value: project.sponsorName!,
              isDark: isDark,
            ),
          // 进度状态
          _buildInfoRow(
            context,
            icon: Icons.track_changes_outlined,
            label: '项目进度',
            value: project.progressName,
            isDark: isDark,
            valueWidget: _buildProgressBadge(project.progressName),
          ),
          // 签约进度
          const SizedBox(height: 16),
          _buildSignProgress(context, isDark),
          // 备注
          if (project.hasRemark) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              icon: Icons.notes_outlined,
              label: '备注',
              value: project.remark!,
              isDark: isDark,
              isMultiline: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    Widget? valueWidget,
    bool isMultiline = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment:
            isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        isDark ? AppColors.darkSecondaryText : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                valueWidget ??
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkNeutralText : null,
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBadge(String progressName) {
    Color backgroundColor;
    Color textColor;

    switch (progressName) {
      case '进行中':
      case '入组中':
        backgroundColor = AppColors.brandGreen.withValues(alpha: 0.12);
        textColor = AppColors.brandGreen;
        break;
      case '待开始':
        backgroundColor = const Color(0xFFFFF2ED);
        textColor = const Color(0xFFB42318);
        break;
      case '停止':
      case '已完成':
        backgroundColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF6B7280);
        break;
      default:
        backgroundColor = const Color(0xFFEEF2FF);
        textColor = const Color(0xFF4F46E5);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: textColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        progressName,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildSignProgress(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.people_outline,
              size: 20,
              color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Text(
              '签约进度',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
              ),
            ),
            const Spacer(),
            Text(
              project.progressText,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.brandGreen,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${project.progressPercentage.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: project.progressPercentage / 100,
            backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation(AppColors.brandGreen),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
