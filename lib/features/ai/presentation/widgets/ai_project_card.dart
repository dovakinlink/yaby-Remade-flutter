import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/ai/data/models/ai_project_model.dart';
import 'package:yabai_app/features/home/presentation/pages/project_detail_page.dart';

class AiProjectCard extends StatelessWidget {
  const AiProjectCard({
    super.key,
    required this.project,
  });

  final AiProjectModel project;

  void _handleTap(BuildContext context) {
    final projectId = project.projectId;
    if (projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('项目ID无效，无法查看详情'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    context.pushNamed(
      ProjectDetailPage.routeName,
      pathParameters: {'id': projectId.toString()},
    );
  }

  /// 构建笔记文本，将"结论："部分以绿色显示
  Widget _buildNoteText(String note, bool isDark) {
    // 查找"结论："的位置，支持多种格式
    int conclusionIndex = -1;
    final patterns = ['结论：', '结论:', '结论： ', '结论: '];
    
    for (final pattern in patterns) {
      final index = note.indexOf(pattern);
      if (index != -1) {
        conclusionIndex = index;
        break;
      }
    }
    
    if (conclusionIndex == -1) {
      // 如果没有找到"结论："，直接显示原文本
      return Text(
        note,
        style: TextStyle(
          fontSize: 14,
          color: isDark
              ? AppColors.darkSecondaryText
              : Colors.grey[700],
          height: 1.5,
        ),
      );
    }

    // 分割文本：结论之前的部分和结论部分
    final beforeConclusion = note.substring(0, conclusionIndex);
    final conclusion = note.substring(conclusionIndex);

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 14,
          color: isDark
              ? AppColors.darkSecondaryText
              : Colors.grey[700],
          height: 1.5,
        ),
        children: [
          // 结论之前的部分
          TextSpan(text: beforeConclusion),
          // 结论部分（绿色）
          TextSpan(
            text: conclusion,
            style: TextStyle(
              color: AppColors.brandGreen,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleTap(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.projectName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkNeutralText : Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : Colors.grey[400],
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkScaffoldBackground
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _buildNoteText(project.note, isDark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

