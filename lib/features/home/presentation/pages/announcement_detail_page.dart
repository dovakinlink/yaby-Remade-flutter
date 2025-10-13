import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yabai_app/core/network/api_client.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/home/data/models/announcement_model.dart';

class AnnouncementDetailPage extends StatelessWidget {
  const AnnouncementDetailPage({super.key, required this.announcement});

  static const routePath = '/home/announcement/:id';
  static const routeName = 'announcement-detail';

  final AnnouncementModel announcement;

  static AnnouncementDetailPage fromState(GoRouterState state) {
    final extra = state.extra;
    if (extra is AnnouncementModel) {
      return AnnouncementDetailPage(announcement: extra);
    }
    throw StateError('Announcement data not provided for detail route');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final organizationName = announcement.organizationDisplayName ?? '通知公告';
    final contentHtml =
        announcement.contentHtml ??
        (announcement.displayContent.isNotEmpty
            ? '<p>${announcement.displayContent}</p>'
            : '<p>暂无内容</p>');

    // 底色
    final backgroundColor = isDark
        ? AppColors.darkScaffoldBackground
        : const Color(0xFFF8F9FA);
    
    // 卡片颜色
    final cardColor = isDark 
        ? AppColors.darkCardBackground 
        : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _HeaderBar(title: '通知公告'),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: cardColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 标题区域
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 用户帖子显示发帖人信息
                            if (announcement.isUserPost && 
                                announcement.publisherName != null) ...[
                              Row(
                                children: [
                                  _UserAvatar(
                                    avatarUrl: announcement.publisherAvatarUrl,
                                    userName: announcement.publisherName!,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          announcement.publisherName!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: isDark 
                                                    ? AppColors.darkNeutralText 
                                                    : null,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          announcement.publishedLabel,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: isDark
                                                    ? AppColors.darkSecondaryText
                                                    : const Color(0xFF6B7280),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                            Text(
                              announcement.title,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    height: 1.35,
                                    color: isDark ? AppColors.darkNeutralText : null,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                if (announcement.isTop)
                                  const _TagChip(
                                    label: '置顶',
                                    backgroundColor: Color(0xFFFFF2ED),
                                    textColor: Color(0xFFB42318),
                                  ),
                                // 用户帖子显示标签名称，官方公告显示类型
                                if (announcement.isUserPost && announcement.tagName != null)
                                  _TagChip(
                                    label: announcement.tagName!,
                                    backgroundColor: const Color(0xFFFFE8E8), // 浅红色背景
                                    textColor: const Color(0xFFE53935), // 红色文字
                                  )
                                else if (announcement.isOfficial)
                                  _TagChip(
                                    label: announcement.noticeTypeLabel,
                                    backgroundColor: AppColors.brandGreen
                                        .withValues(alpha: 0.14),
                                    textColor: AppColors.brandGreen,
                                  ),
                              ],
                            ),
                            // 官方公告显示发布时间
                            if (!announcement.isUserPost) ...[
                              const SizedBox(height: 12),
                              Text(
                                announcement.publishedLabel,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isDark 
                                      ? AppColors.darkSecondaryText 
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      // 分割条
                      Container(
                        height: 4,
                        color: backgroundColor,
                      ),
                      
                      // 内容区域
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Html(
                          data: contentHtml,
                          style: {
                            'body': Style(
                              fontSize: FontSize(16),
                              color: isDark 
                                  ? AppColors.darkNeutralText 
                                  : const Color(0xFF1F2937),
                              lineHeight: const LineHeight(1.6),
                              margin: Margins.zero,
                              padding: HtmlPaddings.zero,
                            ),
                            'h1': Style(
                              fontSize: FontSize(24),
                              fontWeight: FontWeight.w700,
                              color: isDark 
                                  ? AppColors.darkNeutralText 
                                  : const Color(0xFF1F2937),
                              margin: Margins.only(bottom: 16),
                            ),
                            'h2': Style(
                              fontSize: FontSize(20),
                              fontWeight: FontWeight.w700,
                              color: isDark 
                                  ? AppColors.darkNeutralText 
                                  : const Color(0xFF1F2937),
                              margin: Margins.only(bottom: 12),
                              textAlign: TextAlign.center,
                            ),
                            'h3': Style(
                              fontSize: FontSize(18),
                              fontWeight: FontWeight.w600,
                              color: isDark 
                                  ? AppColors.darkNeutralText 
                                  : const Color(0xFF1F2937),
                              margin: Margins.only(bottom: 10),
                            ),
                            'p': Style(
                              margin: Margins.symmetric(vertical: 8),
                              fontSize: FontSize(16),
                              color: isDark 
                                  ? AppColors.darkNeutralText 
                                  : const Color(0xFF1F2937),
                              lineHeight: const LineHeight(1.6),
                            ),
                            'ol': Style(
                              margin: Margins.only(left: 20, top: 8, bottom: 8),
                              padding: HtmlPaddings.zero,
                            ),
                            'ul': Style(
                              margin: Margins.only(left: 20, top: 8, bottom: 8),
                              padding: HtmlPaddings.zero,
                            ),
                            'li': Style(
                              margin: Margins.only(bottom: 4),
                              fontSize: FontSize(16),
                              color: isDark 
                                  ? AppColors.darkNeutralText 
                                  : const Color(0xFF1F2937),
                              lineHeight: const LineHeight(1.6),
                            ),
                            'strong': Style(
                              fontWeight: FontWeight.w700,
                              color: isDark 
                                  ? AppColors.darkNeutralText 
                                  : const Color(0xFF1F2937),
                            ),
                            'b': Style(
                              fontWeight: FontWeight.w700,
                              color: isDark 
                                  ? AppColors.darkNeutralText 
                                  : const Color(0xFF1F2937),
                            ),
                            'a': Style(
                              color: AppColors.brandGreen,
                              textDecoration: TextDecoration.underline,
                            ),
                            'img': Style(
                              width: Width(100),
                              margin: Margins.symmetric(vertical: 8),
                            ),
                          },
                          onLinkTap: (url, attributes, element) {
                            if (url == null) {
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('即将打开: $url')),
                            );
                          },
                        ),
                      ),
                      
                      // 附件区域
                      if (announcement.attachments.isNotEmpty) ...[
                        // 分割条
                        Container(
                          height: 4,
                          color: backgroundColor,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 24,
                          ),
                          child: _AttachmentsContent(
                            attachments: announcement.attachments,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: AppColors.brandGreen,
            ),
            padding: EdgeInsets.zero,
            splashRadius: 20,
          ),
          const SizedBox(width: 4),
          Text(
            '返回',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.brandGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: isDark ? AppColors.darkNeutralText : null,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('消息中心即将上线')));
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.sms_outlined,
                  color: isDark 
                      ? AppColors.darkNeutralText 
                      : const Color(0xFF1F2937),
                ),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.brandGreen,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '2',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AttachmentsContent extends StatelessWidget {
  const _AttachmentsContent({required this.attachments});

  final List<AnnouncementAttachment> attachments;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F7F6),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: const [
                  Icon(
                    Icons.insert_drive_file_outlined,
                    size: 16,
                    color: AppColors.brandGreen,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '文件',
                    style: TextStyle(
                      color: AppColors.brandGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '附件（${attachments.length}）',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkNeutralText : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ...attachments.map(
          (attachment) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _AttachmentTile(attachment: attachment),
          ),
        ),
      ],
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.attachment});

  final AnnouncementAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconData = _iconForAttachment(attachment);
    return InkWell(
      onTap: () => _handleTap(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark 
              ? const Color(0xFF3F3F46) 
              : const Color(0xFFF3F4F6),
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
                    attachment.displayLabel,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkNeutralText : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_sizeOrReadable.isNotEmpty)
                    Text(
                      _sizeOrReadable,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark 
                            ? AppColors.darkSecondaryText 
                            : const Color(0xFF6B7280),
                      ),
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
    );
  }

  String get _sizeOrReadable {
    if (attachment.readableSize != null &&
        attachment.readableSize!.trim().isNotEmpty) {
      return attachment.readableSize!;
    }
    if (attachment.size != null) {
      return _formatSize(attachment.size!);
    }
    return '';
  }

  IconData _iconForAttachment(AnnouncementAttachment attachment) {
    if (attachment.isPdf) {
      return Icons.picture_as_pdf_outlined;
    }
    if (attachment.isImage) {
      return Icons.image_outlined;
    }
    if (attachment.isVideo) {
      return Icons.videocam_outlined;
    }
    final mime = attachment.mimeType?.toLowerCase() ?? '';
    if (mime.contains('word')) {
      return Icons.description_outlined;
    }
    if (mime.contains('excel')) {
      return Icons.table_chart_outlined;
    }
    if (mime.contains('powerpoint')) {
      return Icons.slideshow_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  Future<void> _handleTap(BuildContext context) async {
    if (attachment.url.isEmpty) {
      _showSnack(context, '附件链接不可用');
      return;
    }

    final apiClient = context.read<ApiClient>();
    final resolvedUrl = await apiClient.resolveUrl(attachment.url);
    final authHeaders = apiClient.getAuthHeaders();
    final messenger = ScaffoldMessenger.of(context);

    // 调试日志
    print('📎 附件原始URL: ${attachment.url}');
    print('📎 解析后URL: $resolvedUrl');
    print('📎 认证头: $authHeaders');
    print('📎 是否为图片: ${attachment.isImage}');
    print('📎 MIME类型: ${attachment.mimeType}');

    if (attachment.isImage) {
      await showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.72),
        builder: (_) => _ImagePreviewDialog(
          imageUrl: resolvedUrl,
          title: attachment.displayLabel,
          headers: authHeaders,
        ),
      );
      return;
    }

    final launchMode = (attachment.isVideo || attachment.isPdf)
        ? LaunchMode.externalApplication
        : LaunchMode.platformDefault;

    final uri = Uri.tryParse(resolvedUrl);
    if (uri == null) {
      _showSnack(context, '无法识别的附件链接');
      return;
    }

    final success = await launchUrl(uri, mode: launchMode);
    if (!success) {
      messenger.showSnackBar(const SnackBar(content: Text('无法打开附件，请稍后重试')));
    }
  }

  String _formatSize(int size) {
    const kb = 1024;
    const mb = kb * 1024;
    if (size >= mb) {
      return '${(size / mb).toStringAsFixed(1)} MB';
    }
    if (size >= kb) {
      return '${(size / kb).toStringAsFixed(1)} KB';
    }
    return '$size B';
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.avatarUrl,
    required this.userName,
  });

  final String? avatarUrl;
  final String userName;

  @override
  Widget build(BuildContext context) {
    final displayInitial = userName.isNotEmpty ? userName[0].toUpperCase() : '用';
    final apiClient = context.read<ApiClient>();
    final resolvedUrl = avatarUrl != null && avatarUrl!.isNotEmpty
        ? apiClient.resolveUrlSync(avatarUrl!)
        : null;
    
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.brandGreen.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: resolvedUrl != null
          ? ClipOval(
              child: Image.network(
                resolvedUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                headers: apiClient.getAuthHeaders(),
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text(
                      displayInitial,
                      style: const TextStyle(
                        color: AppColors.brandGreen,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            )
          : Center(
              child: Text(
                displayInitial,
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

class _ImagePreviewDialog extends StatelessWidget {
  const _ImagePreviewDialog({
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
                    loadingBuilder: (context, child, event) {
                      if (event == null) {
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
