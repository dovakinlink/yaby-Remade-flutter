import 'package:flutter/material.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/home/data/models/project_file_model.dart';
import 'package:yabai_app/features/home/presentation/widgets/project_detail/project_detail_section_container.dart';

class ProjectFilesSection extends StatelessWidget {
  const ProjectFilesSection({
    super.key,
    required this.files,
    this.showTopDivider = true,
  });

  final List<ProjectFileModel> files;
  final bool showTopDivider;

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ProjectDetailSectionContainer(
      showTopDivider: showTopDivider,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '项目附件',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkNeutralText : null,
            ),
          ),
          const SizedBox(height: 16),
          ...files.asMap().entries.map((entry) {
            final index = entry.key;
            final file = entry.value;
            return Column(
              children: [
                if (index > 0) const Divider(height: 24),
                _buildFileItem(context, file, isDark),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFileItem(
    BuildContext context,
    ProjectFileModel file,
    bool isDark,
  ) {
    return InkWell(
      onTap: () {
        // TODO: 打开文件查看/下载
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('文件查看功能即将上线: ${file.name}'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 文件图标
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getFileIconColor(file).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  _getFileIcon(file),
                  size: 24,
                  color: _getFileIconColor(file),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // 文件信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkNeutralText : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (file.extension.isNotEmpty) ...[
                        Text(
                          file.extension,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        file.formattedSize,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : Colors.grey[600],
                        ),
                      ),
                      if (file.category != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brandGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            file.categoryLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.brandGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.download_outlined,
              size: 20,
              color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(ProjectFileModel file) {
    if (file.isPdf) {
      return Icons.picture_as_pdf;
    } else if (file.isImage) {
      return Icons.image_outlined;
    } else if (file.isDocument) {
      return Icons.description_outlined;
    } else {
      return Icons.insert_drive_file_outlined;
    }
  }

  Color _getFileIconColor(ProjectFileModel file) {
    if (file.isPdf) {
      return const Color(0xFFEF4444);
    } else if (file.isImage) {
      return const Color(0xFF3B82F6);
    } else if (file.isDocument) {
      return const Color(0xFF8B5CF6);
    } else {
      return Colors.grey;
    }
  }
}
