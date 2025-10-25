import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yabai_app/core/network/api_client.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/learning/data/models/learning_resource_model.dart';
import 'package:yabai_app/features/learning/data/models/resource_file_model.dart';
import 'package:yabai_app/features/learning/providers/learning_resource_detail_provider.dart';

class LearningResourceDetailPage extends StatefulWidget {
  final int resourceId;
  final LearningResource? resource;

  const LearningResourceDetailPage({
    super.key,
    required this.resourceId,
    this.resource,
  });

  static const routePath = 'learning/:id';
  static const routeName = 'learning-detail';

  @override
  State<LearningResourceDetailPage> createState() =>
      _LearningResourceDetailPageState();
}

class _LearningResourceDetailPageState
    extends State<LearningResourceDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LearningResourceDetailProvider>().loadDetail(widget.resourceId);
    });
  }

  @override
  void dispose() {
    context.read<LearningResourceDetailProvider>().clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkScaffoldBackground
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(widget.resource?.name ?? '资源详情'),
        backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
        elevation: 0,
      ),
      body: Consumer<LearningResourceDetailProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            onRefresh: () => provider.refresh(widget.resourceId),
            backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
            color: AppColors.brandGreen,
            child: _buildBody(provider, isDark),
          );
        },
      ),
    );
  }

  Widget _buildBody(LearningResourceDetailProvider provider, bool isDark) {
    if (provider.isLoading && provider.detail == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppColors.brandGreen),
        ),
      );
    }

    if (provider.errorMessage != null && provider.detail == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage!,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.refresh(widget.resourceId),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    final detail = provider.detail;
    if (detail == null) {
      return const Center(child: Text('资源不存在'));
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 资源信息卡片
          _buildResourceInfoCard(detail, isDark),

          // 文件列表
          if (detail.hasFiles) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Icon(Icons.attach_file, color: isDark ? AppColors.darkNeutralText : Colors.grey[700]),
                  const SizedBox(width: 8),
                  Text(
                    '学习资料 (${detail.fileCount})',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkNeutralText : null,
                    ),
                  ),
                ],
              ),
            ),
            ...detail.files.map((file) => _buildFileCard(file, isDark)),
            const SizedBox(height: 16),
          ] else ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  '暂无文件',
                  style: TextStyle(color: isDark ? AppColors.darkSecondaryText : Colors.grey[600]),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResourceInfoCard(dynamic detail, bool isDark) {
    return Card(
      margin: const EdgeInsets.all(16),
      color: isDark ? AppColors.darkCardBackground : Colors.white,
      elevation: isDark ? 0 : 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.brandGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.school,
                    color: AppColors.brandGreen,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    detail.name as String,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkNeutralText : null,
                    ),
                  ),
                ),
              ],
            ),
            if (detail.remark != null && (detail.remark as String).isNotEmpty) ...[
              const SizedBox(height: 12),
              Divider(color: isDark ? Colors.grey[700] : null),
              const SizedBox(height: 12),
              Text(
                detail.remark as String,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.darkSecondaryText : Colors.grey[700],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Divider(color: isDark ? Colors.grey[700] : null),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: isDark ? AppColors.darkSecondaryText : Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '更新于 ${_formatDateTime(detail.updatedAt as DateTime)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileCard(ResourceFile file, bool isDark) {
    // 添加调试输出
    debugPrint('文件: ${file.displayName}, 扩展名: ${file.ext}, MIME: ${file.mimeType}, 是否图片: ${file.isImage}');
    
    if (file.isImage) {
      debugPrint('渲染图片卡片: ${file.displayName}');
      return _buildImageAttachment(file, isDark);
    }
    
    debugPrint('渲染文档卡片: ${file.displayName}');
    return _buildDocumentAttachment(file, isDark);
  }

  Widget _buildDocumentAttachment(ResourceFile file, bool isDark) {
    final iconData = _iconForFile(file);
    final tileBackground =
        isDark ? const Color(0xFF3F3F46) : const Color(0xFFF3F4F6);
    final metadata = [
      if (file.formattedSize.isNotEmpty) file.formattedSize,
      if (file.ext.isNotEmpty)
        file.ext.replaceFirst('.', '').toUpperCase(),
    ].where((value) => value.isNotEmpty).join(' • ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _handleFileTap(file),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: tileBackground,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.brandGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: AppColors.brandGreen),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.displayName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkNeutralText : null,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (metadata.isNotEmpty)
                      Text(
                        metadata,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? AppColors.darkSecondaryText
                                      : const Color(0xFF6B7280),
                                ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isDark
                    ? AppColors.darkSecondaryText
                    : const Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  IconData _iconForFile(ResourceFile file) {
    final ext = file.ext.toLowerCase();
    if (file.isPdf) {
      return Icons.picture_as_pdf_outlined;
    }
    if (file.isImage) {
      return Icons.image_outlined;
    }
    if (_isVideo(file)) {
      return Icons.videocam_outlined;
    }
    if (ext.endsWith('xls') || ext.endsWith('xlsx')) {
      return Icons.table_chart_outlined;
    }
    if (ext.endsWith('ppt') || ext.endsWith('pptx')) {
      return Icons.slideshow_outlined;
    }
    if (file.isOfficeDoc) {
      return Icons.description_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  Future<void> _handleFileTap(ResourceFile file) async {
    if (file.url.isEmpty) {
      _showSnack('文件链接不可用');
      return;
    }

    late final String resolvedUrl;

    try {
      resolvedUrl = await _resolveAttachmentUrl(file);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnack('文件链接解析失败');
      return;
    }

    if (!mounted) {
      return;
    }

    final apiClient = context.read<ApiClient>();
    final headers = apiClient.getAuthHeaders();

    if (file.isImage) {
      await showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.72),
        builder: (_) => _FileImagePreviewDialog(
          imageUrl: resolvedUrl,
          title: file.displayName,
          headers: headers,
        ),
      );
      return;
    }

    final uri = Uri.tryParse(resolvedUrl);
    if (uri == null) {
      _showSnack('无法识别的文件链接');
      return;
    }

    final launchMode = (file.isPdf || _isVideo(file))
        ? LaunchMode.externalApplication
        : LaunchMode.platformDefault;

    final success = await launchUrl(uri, mode: launchMode);
    if (!success && mounted) {
      _showSnack('无法打开该文件，请稍后重试');
    }
  }

  bool _isVideo(ResourceFile file) {
    final mime = file.mimeType.toLowerCase();
    if (mime.startsWith('video/')) {
      return true;
    }

    final videoExts = ['.mp4', '.mov', '.avi', '.mkv', '.webm'];
    return videoExts.contains(file.ext.toLowerCase());
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _normalizeFileUrl(String rawUrl) {
    if (rawUrl.isEmpty) {
      return rawUrl;
    }

    final uri = Uri.tryParse(rawUrl);
    if (uri != null && uri.hasScheme) {
      return rawUrl;
    }

    var path = rawUrl.trim();
    if (!path.startsWith('/')) {
      path = '/$path';
    }

    if (path.startsWith('/files/')) {
      path = path.replaceFirst('/files/', '/uploads/');
    } else if (!path.startsWith('/uploads/')) {
      final dateFormatPattern = RegExp(r'^/\d{4}/\d{2}/\d{2}/');
      if (dateFormatPattern.hasMatch(path)) {
        path = '/uploads$path';
      }
    }

    return path;
  }

  Future<String> _resolveAttachmentUrl(ResourceFile file) {
    final apiClient = context.read<ApiClient>();
    final normalizedUrl = _normalizeFileUrl(file.url);
    return apiClient.resolveUrl(normalizedUrl);
  }

  Widget _buildImageAttachment(ResourceFile file, bool isDark) {
    debugPrint('构建图片附件: ${file.displayName}, URL: ${file.url}');
    
    return FutureBuilder<String>(
      future: _resolveAttachmentUrl(file),
      builder: (context, snapshot) {
        debugPrint('图片URL解析状态: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, hasError: ${snapshot.hasError}');
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildImageLoadingPlaceholder(isDark);
        }

        if (snapshot.hasError) {
          debugPrint('图片URL解析错误: ${snapshot.error}');
          return _buildDocumentAttachment(file, isDark);
        }

        if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
          debugPrint('图片URL为空或无效');
          return _buildDocumentAttachment(file, isDark);
        }

        final imageUrl = snapshot.data!;
        debugPrint('解析后的图片URL: $imageUrl');
        
        final headers = context.read<ApiClient>().getAuthHeaders();
        final borderRadius = BorderRadius.circular(16);
        final metadata = [
          if (file.formattedSize.isNotEmpty) file.formattedSize,
          if (file.ext.isNotEmpty)
            file.ext.replaceFirst('.', '').toUpperCase(),
        ].where((value) => value.isNotEmpty).join(' • ');

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Card(
            margin: EdgeInsets.zero,
            elevation: isDark ? 0 : 2,
            color: isDark ? AppColors.darkCardBackground : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
            child: InkWell(
              onTap: () => _handleFileTap(file),
              borderRadius: borderRadius,
              child: ClipRRect(
                borderRadius: borderRadius,
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        imageUrl,
                        headers: headers,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) {
                            return child;
                          }
                          return _buildImageNetworkLoading(isDark);
                        },
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('图片加载错误: $error');
                          return _buildImageNetworkError(isDark);
                        },
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              file.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (metadata.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                metadata,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageLoadingPlaceholder(bool isDark) {
    final borderRadius = BorderRadius.circular(16);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: _buildImageNetworkLoading(isDark),
        ),
      ),
    );
  }

  Widget _buildImageNetworkLoading(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFE5E7EB),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppColors.brandGreen),
        ),
      ),
    );
  }

  Widget _buildImageNetworkError(bool isDark) {
    final textColor = isDark ? Colors.white70 : const Color(0xFF6B7280);
    return Container(
      color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFE5E7EB),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_outlined, color: textColor, size: 36),
          const SizedBox(height: 8),
          Text(
            '图片加载失败',
            style: TextStyle(color: textColor),
          ),
        ],
      ),
    );
  }
}

class _FileImagePreviewDialog extends StatelessWidget {
  const _FileImagePreviewDialog({
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
