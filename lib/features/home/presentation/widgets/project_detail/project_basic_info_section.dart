import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/network/api_client.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/home/data/models/project_detail_model.dart';
import 'package:yabai_app/features/home/data/models/project_staff_model.dart';
import 'package:yabai_app/features/home/presentation/widgets/project_detail/project_detail_section_container.dart';

class ProjectBasicInfoSection extends StatelessWidget {
  const ProjectBasicInfoSection({
    super.key,
    required this.project,
    this.showTopDivider = false,
    this.piStaff,
  });

  final ProjectDetailModel project;
  final bool showTopDivider;
  final ProjectStaffModel? piStaff;

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
          _buildProjectNumber(context, isDark),
          if (_hasPiInfo) ...[
            const SizedBox(height: 16),
            _buildPiInfo(context, isDark),
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

  bool get _hasPiInfo {
    if (piStaff != null) return true;
    return project.piName != null && project.piName!.isNotEmpty;
  }

  Widget _buildProjectNumber(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '项目编号',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                project.displayProjectNo,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkNeutralText : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            _buildProgressBadge(project.progressName),
          ],
        ),
      ],
    );
  }

  Widget _buildPiInfo(BuildContext context, bool isDark) {
    final ProjectStaffModel? staff = piStaff;
    final String? piName = staff?.personName ?? project.piName;
    if (piName == null || piName.isEmpty) {
      return const SizedBox.shrink();
    }

    final roleLabel = staff?.roleName ?? 'PI';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '项目PI',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildPiAvatar(context, staff, piName),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    piName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkNeutralText : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.brandGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.brandGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      roleLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.brandGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPiAvatar(
    BuildContext context,
    ProjectStaffModel? staff,
    String fallbackName,
  ) {
    const double size = 48;

    if (staff != null && staff.hasAvatar) {
      final apiClient = context.read<ApiClient>();
      final resolved = apiClient.resolveUrlSync(staff.avatar!);
      return ClipOval(
        child: Image.network(
          resolved,
          width: size,
          height: size,
          fit: BoxFit.cover,
          headers: apiClient.getAuthHeaders(),
          errorBuilder: (context, error, stackTrace) {
            return _buildInitialAvatar(staff.initial, size: size);
          },
        ),
      );
    }

    if (staff != null) {
      return _buildInitialAvatar(staff.initial, size: size);
    }
    return _buildInitialAvatar(_initialFromName(fallbackName), size: size);
  }

  Widget _buildInitialAvatar(String initial, {double size = 48}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.brandGreen.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: AppColors.brandGreen,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _initialFromName(String name) {
    if (name.trim().isEmpty) return '?';
    return name.trim().characters.first.toUpperCase();
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
