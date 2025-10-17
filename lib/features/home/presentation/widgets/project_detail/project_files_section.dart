import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yabai_app/core/network/api_client.dart';
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
      onTap: () => _handleFileTap(context, file),
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

  Future<void> _handleFileTap(
    BuildContext context,
    ProjectFileModel file,
  ) async {
    if (file.fileUrl.isEmpty) {
      _showSnack(context, '附件链接不可用');
      return;
    }

    final apiClient = context.read<ApiClient>();
    final resolvedUrl = await apiClient.resolveUrl(file.fileUrl);
    final authHeaders = apiClient.getAuthHeaders();
    final messenger = ScaffoldMessenger.of(context);

    if (file.isImage) {
      await showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.72),
        builder: (_) => _ProjectImagePreviewDialog(
          imageUrl: resolvedUrl,
          title: file.name,
          headers: authHeaders,
        ),
      );
      return;
    }

    final launchMode = file.isPdf || file.isDocument
        ? LaunchMode.externalApplication
        : LaunchMode.platformDefault;

    final uri = Uri.tryParse(resolvedUrl);
    if (uri == null) {
      _showSnack(context, '无法识别的附件链接');
      return;
    }

    final success = await launchUrl(uri, mode: launchMode);
    if (!success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('无法打开附件，请稍后重试 (${file.name})'),
        ),
      );
    }
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _ProjectImagePreviewDialog extends StatelessWidget {
  const _ProjectImagePreviewDialog({
    required this.imageUrl,
    required this.title,
    required this.headers,
  });

  final String imageUrl;
  final String title;
  final Map<String, String> headers;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.86),
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    headers: headers,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) {
                        return child;
                      }
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(
                            AppColors.brandGreen,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Text(
                          '图片加载失败',
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: Colors.black.withValues(alpha: 0.32),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
