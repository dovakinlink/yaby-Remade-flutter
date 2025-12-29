import 'package:flutter/material.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/home/data/models/project_model.dart';

class ProjectCard extends StatelessWidget {
  const ProjectCard({super.key, required this.project, this.onTap});

  final ProjectModel project;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkCardBackground : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _ProjectCardContent(project: project),
        ),
      ),
    );
  }
}

class _ProjectCardContent extends StatelessWidget {
  const _ProjectCardContent({required this.project});

  final ProjectModel project;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 项目名称和进度标签
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.projName,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      height: 1.3,
                      color: isDark ? AppColors.darkNeutralText : null,
                    ),
                  ),
                  if (project.shortTitle != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          project.shortTitle!,
                          style: textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildXiaobaiStatus(context, isDark),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            _ProgressBadge(label: project.progressName),
          ],
        ),
        const SizedBox(height: 12),
        // 申办方
        if (project.sponsorName != null) ...[
          Row(
            children: [
              Icon(
                Icons.business_outlined,
                size: 16,
                color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  project.sponsorName!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : Colors.grey[700],
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        // 签约进度
        Row(
          children: [
            Icon(
              Icons.people_outline,
              size: 16,
              color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              '已签约 ${project.progressText}',
              style: textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.darkSecondaryText : Colors.grey[700],
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: project.progressPercentage / 100,
                  backgroundColor:
                      isDark ? Colors.grey[700] : Colors.grey[200],
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.brandGreen),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${project.progressPercentage.toStringAsFixed(0)}%',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.brandGreen,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        // 自定义标签
        if (project.customTags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: project.customTags
                .take(5) // 最多显示5个标签
                .map((tag) => _TagChip(label: tag))
                .toList(),
          ),
        ],
      ],
    );
  }

  /// 构建 AI 知识库状态显示
  Widget _buildXiaobaiStatus(BuildContext context, bool isDark) {
    final isUploaded = project.xiaobaiStatus == 1;
    
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'AI知识库: ',
            style: TextStyle(
              fontSize: 13,
              color: const Color(0xFFF77924), // 橙色
            ),
          ),
          TextSpan(
            text: isUploaded ? '已上传' : '未上传',
            style: TextStyle(
              fontSize: 13,
              color: isUploaded 
                  ? const Color(0xFF10B981) // 绿色（已上传）
                  : const Color(0xFFEF4444), // 红色（未上传）
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBadge extends StatelessWidget {
  const _ProgressBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    // 根据进度名称设置不同的颜色
    Color backgroundColor;
    Color textColor;

    switch (label) {
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: textColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              fontSize: 11,
            ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey[800]
            : AppColors.brandGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? AppColors.darkSecondaryText : Colors.grey[700],
              fontSize: 12,
            ),
      ),
    );
  }
}

