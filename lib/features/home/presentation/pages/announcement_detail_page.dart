import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yabai_app/core/network/api_client.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/home/data/models/announcement_model.dart';
import 'package:yabai_app/features/home/providers/comment_list_provider.dart';
import 'package:yabai_app/features/home/presentation/widgets/comment_card.dart';
import 'package:yabai_app/features/home/presentation/widgets/comment_input_bar.dart';

class AnnouncementDetailPage extends StatefulWidget {
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
  State<AnnouncementDetailPage> createState() => _AnnouncementDetailPageState();
}

class _AnnouncementDetailPageState extends State<AnnouncementDetailPage> {
  bool _showComments = false;
  late TextEditingController _commentController;
  late ScrollController _commentScrollController;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    _commentScrollController = ScrollController();
    _commentScrollController.addListener(_handleCommentScroll);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentScrollController
      ..removeListener(_handleCommentScroll)
      ..dispose();
    super.dispose();
  }

  void _handleCommentScroll() {
    if (!_commentScrollController.hasClients) return;

    final provider = context.read<CommentListProvider>();
    if (!provider.hasNext || provider.isLoadingMore) return;

    final position = _commentScrollController.position;
    if (position.pixels >= position.maxScrollExtent * 0.9) {
      unawaited(provider.loadMore());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contentHtml =
        widget.announcement.contentHtml ??
        (widget.announcement.displayContent.isNotEmpty
            ? '<p>${widget.announcement.displayContent}</p>'
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
            if (!_showComments)
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
                            if (widget.announcement.isUserPost && 
                                widget.announcement.publisherName != null) ...[
                              Row(
                                children: [
                                  _UserAvatar(
                                    avatarUrl: widget.announcement.publisherAvatarUrl,
                                    userName: widget.announcement.publisherName!,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.announcement.publisherName!,
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
                                          widget.announcement.publishedLabel,
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
                              widget.announcement.title,
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
                                if (widget.announcement.isTop)
                                  const _TagChip(
                                    label: '置顶',
                                    backgroundColor: Color(0xFFFFF2ED),
                                    textColor: Color(0xFFB42318),
                                  ),
                                // 用户帖子显示标签名称，官方公告显示类型
                                if (widget.announcement.isUserPost && widget.announcement.tagName != null)
                                  _TagChip(
                                    label: widget.announcement.tagName!,
                                    backgroundColor: const Color(0xFFFFE8E8), // 浅红色背景
                                    textColor: const Color(0xFFE53935), // 红色文字
                                  )
                                else if (widget.announcement.isOfficial)
                                  _TagChip(
                                    label: widget.announcement.noticeTypeLabel,
                                    backgroundColor: AppColors.brandGreen
                                        .withValues(alpha: 0.14),
                                    textColor: AppColors.brandGreen,
                                  ),
                              ],
                            ),
                            // 官方公告显示发布时间
                            if (!widget.announcement.isUserPost) ...[
                              const SizedBox(height: 12),
                              Text(
                                widget.announcement.publishedLabel,
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
                      _HtmlContentView(
                        htmlContent: contentHtml,
                        isDark: isDark,
                      ),
                      
                      // 附件区域
                      if (widget.announcement.attachments.isNotEmpty) ...[
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
                            attachments: widget.announcement.attachments,
                          ),
                        ),
                      ],
                      
                      // 评论入口（只有用户帖子才显示）
                      if (widget.announcement.isUserPost) ...[
                        Container(height: 4, color: backgroundColor),
                        _buildCommentBar(context, isDark),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            
            // 评论区域（展开后显示）
            if (_showComments && widget.announcement.isUserPost)
              Expanded(
                child: _buildCommentSection(context, isDark, cardColor),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCommentBar(BuildContext context, bool isDark) {
    final provider = context.watch<CommentListProvider>();
    
    return InkWell(
      onTap: () {
        setState(() {
          _showComments = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        child: Row(
          children: [
            Icon(Icons.comment_outlined, color: AppColors.brandGreen, size: 20),
            const SizedBox(width: 8),
            Text(
              '评论 (${provider.commentCount})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkNeutralText : Colors.black87,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: isDark ? AppColors.darkSecondaryText : Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCommentSection(BuildContext context, bool isDark, Color cardColor) {
    final provider = context.watch<CommentListProvider>();
    
    return Container(
      color: isDark ? AppColors.darkScaffoldBackground : const Color(0xFFF8F9FA),
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cardColor,
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
                Text(
                  '评论 (${provider.commentCount})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkNeutralText : Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showComments = false;
                      provider.cancelReply();
                    });
                  },
                  icon: const Icon(Icons.close),
                  color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          
          // 评论列表
          Expanded(
            child: _buildCommentList(provider, isDark),
          ),
          
          // 输入框
          CommentInputBar(
            controller: _commentController,
            replyingTo: provider.replyingTo,
            onCancelReply: () => provider.cancelReply(),
            onSubmit: () => _submitComment(provider),
            isSubmitting: provider.isSubmitting,
          ),
        ],
      ),
    );
  }
  
  Widget _buildCommentList(CommentListProvider provider, bool isDark) {
    if (provider.isLoading && provider.comments.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppColors.brandGreen),
        ),
      );
    }
    
    if (provider.errorMessage != null && provider.comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage!,
              style: TextStyle(color: isDark ? AppColors.darkSecondaryText : Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.refresh(),
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
    
    if (provider.comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.comment_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '暂无评论',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '快来发表第一条评论吧',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkSecondaryText : Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      controller: _commentScrollController,
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: provider.comments.length + (provider.hasNext ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.comments.length) {
          // 加载更多指示器
          if (provider.isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppColors.brandGreen),
                  ),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }
        
        final comment = provider.comments[index];
        return CommentCard(
          comment: comment,
          onReply: () => provider.setReplyingTo(comment),
          onDelete: comment.canDelete
              ? () => _deleteComment(context, provider, comment.id)
              : null,
        );
      },
    );
  }
  
  Future<void> _submitComment(CommentListProvider provider) async {
    final content = _commentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('评论内容不能为空')),
      );
      return;
    }
    
    final success = await provider.createComment(content);
    if (success) {
      _commentController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('评论成功')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('评论失败，请重试')),
        );
      }
    }
  }
  
  Future<void> _deleteComment(
    BuildContext context,
    CommentListProvider provider,
    int commentId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条评论吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final success = await provider.deleteComment(commentId);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('删除成功')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('删除失败，请重试')),
          );
        }
      }
    }
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

class _HtmlContentView extends StatefulWidget {
  const _HtmlContentView({
    required this.htmlContent,
    required this.isDark,
  });

  final String htmlContent;
  final bool isDark;

  @override
  State<_HtmlContentView> createState() => _HtmlContentViewState();
}

class _HtmlContentViewState extends State<_HtmlContentView> {
  WebViewController? _controller;
  double _webViewHeight = 400; // 默认高度
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (_isDisposed) return NavigationDecision.prevent;
            
            // 拦截外部链接
            if (request.url.startsWith('http')) {
              if (mounted && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('即将打开: ${request.url}')),
                );
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(_buildHtmlPage());

    // 获取内容高度
    _updateHeight();
  }

  Future<void> _updateHeight() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (_isDisposed || !mounted) return;

    try {
      if (_controller == null) return;
      
      final heightString = await _controller!.runJavaScriptReturningResult(
        'document.documentElement.scrollHeight',
      );
      final height = double.tryParse(heightString.toString()) ?? 400;
      
      if (!_isDisposed && mounted) {
        setState(() {
          _webViewHeight = height + 20; // 添加一些额外空间
        });
      }
    } catch (e) {
      debugPrint('获取WebView高度失败: $e');
    }
  }

  String _buildHtmlPage() {
    final textColor = widget.isDark ? '#F8F9FA' : '#1F2937';
    final backgroundColor = widget.isDark ? '#333333' : '#FFFFFF';
    final linkColor = '#36CAC4'; // AppColors.brandGreen

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
      font-size: 16px;
      line-height: 1.6;
      color: $textColor;
      background-color: $backgroundColor;
      padding: 20px;
      word-wrap: break-word;
      overflow-wrap: break-word;
    }
    
    h1 {
      font-size: 24px;
      font-weight: 700;
      margin-bottom: 16px;
      color: $textColor;
    }
    
    h2 {
      font-size: 20px;
      font-weight: 700;
      margin-bottom: 12px;
      text-align: center;
      color: $textColor;
    }
    
    h3 {
      font-size: 18px;
      font-weight: 600;
      margin-bottom: 10px;
      color: $textColor;
    }
    
    p {
      margin: 8px 0;
      font-size: 16px;
      line-height: 1.6;
      color: $textColor;
    }
    
    ol, ul {
      margin: 8px 0 8px 20px;
      padding: 0;
    }
    
    li {
      margin-bottom: 4px;
      font-size: 16px;
      line-height: 1.6;
      color: $textColor;
    }
    
    strong, b {
      font-weight: 700;
      color: $textColor;
    }
    
    a {
      color: $linkColor;
      text-decoration: underline;
    }
    
    img {
      max-width: 100%;
      height: auto;
      margin: 8px 0;
      display: block;
    }
  </style>
</head>
<body>
  ${widget.htmlContent}
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return SizedBox(
        height: 100,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.brandGreen),
          ),
        ),
      );
    }
    
    return SizedBox(
      height: _webViewHeight,
      child: WebViewWidget(controller: _controller!),
    );
  }
}
