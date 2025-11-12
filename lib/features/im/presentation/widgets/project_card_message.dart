import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/im/data/models/message_content.dart';

/// 项目卡片消息组件
class ProjectCardMessage extends StatelessWidget {
  final ProjectCardContent content;

  const ProjectCardMessage({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => _navigateToProject(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark 
                ? AppColors.darkDividerColor 
                : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 项目标题
            Text(
              content.project.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkNeutralText
                    : AppColors.lightNeutralText,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // 项目信息行（分期、适应症、治疗线）
            _buildInfoRow(isDark),
            const SizedBox(height: 4),
            // 状态和中心数
            _buildStatusRow(isDark),
          ],
        ),
      ),
    );
  }

  /// 跳转到项目详情
  void _navigateToProject(BuildContext context) {
    context.pushNamed(
      'project-detail',
      pathParameters: {'id': '${content.project.id}'},
    );
  }

  /// 构建信息行（分期 | 适应症 | 治疗线）
  Widget _buildInfoRow(bool isDark) {
    final info = <String>[];

    if (content.project.phase != null && content.project.phase!.isNotEmpty) {
      info.add(content.project.phase!);
    }
    if (content.project.tumorType != null && content.project.tumorType!.isNotEmpty) {
      info.add(content.project.tumorType!);
    }
    if (content.project.lineOfTherapy != null && content.project.lineOfTherapy!.isNotEmpty) {
      info.add(content.project.lineOfTherapy!);
    }

    if (info.isEmpty) {
      return const SizedBox.shrink();
    }

    return Text(
      info.join(' | '),
      style: TextStyle(
        fontSize: 13,
        color: isDark 
            ? AppColors.darkSecondaryText 
            : Colors.grey[600],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// 构建状态行（状态 · 中心数）
  Widget _buildStatusRow(bool isDark) {
    final parts = <String>[];

    if (content.project.status != null && content.project.status!.isNotEmpty) {
      parts.add(content.project.status!);
    }

    if (content.project.siteCount != null && content.project.siteCount! > 0) {
      parts.add('${content.project.siteCount}家中心');
    }

    if (parts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.brandGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            parts.join(' · '),
            style: TextStyle(
              fontSize: 12,
              color: AppColors.brandGreen,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

