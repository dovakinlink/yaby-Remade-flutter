import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yabai_app/core/config/env_config.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/learning/data/models/learning_resource_model.dart';
import 'package:yabai_app/features/learning/data/models/resource_file_model.dart';
import 'package:yabai_app/features/learning/providers/learning_resource_detail_provider.dart';
import 'package:intl/intl.dart';

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
    IconData fileIcon;
    Color iconColor;

    if (file.isPdf) {
      fileIcon = Icons.picture_as_pdf;
      iconColor = Colors.red;
    } else if (file.isImage) {
      fileIcon = Icons.image;
      iconColor = Colors.blue;
    } else if (file.isOfficeDoc) {
      fileIcon = Icons.description;
      iconColor = Colors.orange;
    } else {
      fileIcon = Icons.insert_drive_file;
      iconColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: isDark ? AppColors.darkCardBackground : Colors.white,
      elevation: isDark ? 0 : 1,
      child: ListTile(
        leading: Icon(fileIcon, color: iconColor, size: 32),
        title: Text(
          file.displayName,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkNeutralText : null,
          ),
        ),
        subtitle: Text(
          '${file.formattedSize} • ${file.ext}',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (file.isPdf)
              IconButton(
                icon: const Icon(Icons.visibility, color: Colors.blue),
                onPressed: () => _previewFile(file),
                tooltip: '预览',
              ),
            IconButton(
              icon: Icon(Icons.download, color: AppColors.brandGreen),
              onPressed: () => _downloadFile(file),
              tooltip: '下载',
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  Future<void> _previewFile(ResourceFile file) async {
    final resolvedUrl = await _resolveFileUrl(file.url);
    final uri = Uri.parse(resolvedUrl);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法预览该文件')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('预览失败: $e')),
      );
    }
  }

  Future<void> _downloadFile(ResourceFile file) async {
    final resolvedUrl = await _resolveFileUrl(file.url);
    final uri = Uri.parse(resolvedUrl);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法下载该文件')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('下载失败: $e')),
      );
    }
  }

  Future<String> _resolveFileUrl(String rawUrl) async {
    if (rawUrl.isEmpty) {
      return rawUrl;
    }

    // 若已是绝对路径，直接返回
    final uri = Uri.tryParse(rawUrl);
    if (uri != null && uri.hasScheme) {
      return rawUrl;
    }

    // 规范化路径，确保带有 uploads 前缀
    final normalizedPath = rawUrl.startsWith('/uploads/')
        ? rawUrl
        : '/uploads/${rawUrl.replaceFirst(RegExp(r'^/+'), '')}';

    final baseUri = Uri.tryParse(EnvConfig.initialBaseUrl);
    if (baseUri == null) {
      return normalizedPath;
    }

    return Uri(
      scheme: baseUri.scheme,
      host: baseUri.host,
    ).resolve(normalizedPath).toString();
  }
}
