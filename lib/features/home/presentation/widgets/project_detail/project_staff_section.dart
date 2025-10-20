import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/network/api_client.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/home/data/models/project_staff_model.dart';
import 'package:yabai_app/features/home/presentation/widgets/project_detail/project_detail_section_container.dart';
import 'package:yabai_app/features/profile/presentation/pages/user_profile_detail_page.dart';

class ProjectStaffSection extends StatelessWidget {
  const ProjectStaffSection({
    super.key,
    required this.staff,
    this.showTopDivider = true,
  });

  final List<ProjectStaffModel> staff;
  final bool showTopDivider;

  @override
  Widget build(BuildContext context) {
    if (staff.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ProjectDetailSectionContainer(
      showTopDivider: showTopDivider,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '项目人员',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkNeutralText : null,
            ),
          ),
          const SizedBox(height: 16),
          ...staff.asMap().entries.map((entry) {
            final index = entry.key;
            final person = entry.value;
            return Column(
              children: [
                if (index > 0) const Divider(height: 24),
                _buildStaffItem(context, person, isDark),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStaffItem(
    BuildContext context,
    ProjectStaffModel person,
    bool isDark,
  ) {
    final apiClient = context.read<ApiClient>();
    final hasClickableProfile = person.hasUserId;

    // 构建头像内容
    Widget avatarContent;
    if (person.hasAvatar) {
      final resolvedUrl = apiClient.resolveUrlSync(person.avatar!);
      avatarContent = ClipOval(
        child: Image.network(
          resolvedUrl,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          headers: apiClient.getAuthHeaders(),
          errorBuilder: (context, error, stackTrace) {
            // 加载失败显示首字母
            return _buildInitialAvatar(person.initial);
          },
        ),
      );
    } else {
      avatarContent = _buildInitialAvatar(person.initial);
    }

    // 包装InkWell（仅当有userId时）
    Widget avatar = avatarContent;
    if (hasClickableProfile) {
      avatar = InkWell(
        onTap: () {
          debugPrint('点击项目成员头像: ${person.personName}, userId: ${person.userId}');
          context.pushNamed(
            UserProfileDetailPage.routeName,
            pathParameters: {'userId': person.userId.toString()},
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: avatarContent,
      );
    }

    return Row(
      children: [
        // 头像
        avatar,
        const SizedBox(width: 16),
        // 人员信息
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    person.personName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkNeutralText : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (person.isPrimary)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.brandGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Text(
                        '主要负责人',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.brandGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey[800]
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      person.roleName,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (person.hasNote) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        person.note!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInitialAvatar(String initial) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.brandGreen.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: AppColors.brandGreen,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
