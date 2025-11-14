import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/core/network/api_client.dart';
import 'package:yabai_app/features/auth/providers/user_profile_provider.dart';
import 'package:yabai_app/features/im/data/models/im_message_model.dart';
import 'package:yabai_app/features/im/data/models/message_content.dart';
import 'package:yabai_app/features/im/presentation/widgets/project_card_message.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 消息气泡组件
class MessageBubble extends StatelessWidget {
  final ImMessage message;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            _buildAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe && message.senderName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 12),
                    child: Text(
                      message.senderName!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppColors.brandGreen
                        : (isDark ? AppColors.darkCardBackground : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: _buildMessageContent(isDark),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 12, right: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkSecondaryText : Colors.grey[500],
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        _buildStatusIndicator(isDark),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            _buildAvatar(),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Builder(
      builder: (context) {
        final apiClient = context.read<ApiClient>();
        var avatarUrl = message.senderAvatar;
        
        // 如果是当前用户发送的消息且没有头像，尝试从 UserProfileProvider 获取
        if (isMe && (avatarUrl == null || avatarUrl.isEmpty)) {
          try {
            final userProfile = context.read<UserProfileProvider>();
            avatarUrl = userProfile.profile?.avatar;
          } catch (e) {
            // UserProfileProvider 可能不可用，忽略错误
          }
        }
        
        // 使用 ApiClient 解析 URL
        final resolvedUrl = avatarUrl != null && avatarUrl.isNotEmpty
            ? apiClient.resolveUrlSync(avatarUrl)
            : null;
        
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.brandGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(18),
          ),
          child: resolvedUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    resolvedUrl,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    headers: apiClient.getAuthHeaders(), // 添加认证头
                    errorBuilder: (context, error, stackTrace) {
                      return _buildAvatarFallback();
                    },
                  ),
                )
              : _buildAvatarFallback(),
        );
      },
    );
  }
  
  Widget _buildAvatarFallback() {
    // 如果有发送者名称，显示首字母
    if (message.senderName != null && message.senderName!.isNotEmpty) {
      return Center(
        child: Text(
          message.senderName![0].toUpperCase(),
          style: const TextStyle(
            color: AppColors.brandGreen,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return const Icon(Icons.person, color: AppColors.brandGreen, size: 20);
  }

  Widget _buildMessageContent(bool isDark) {
    if (message.isRevoked) {
      return Text(
        '[消息已撤回]',
        style: TextStyle(
          fontSize: 14,
          color: isMe ? Colors.white70 : (isDark ? AppColors.darkSecondaryText : Colors.grey[600]),
          fontStyle: FontStyle.italic,
        ),
      );
    }

    switch (message.msgType) {
      case 'TEXT':
        return _buildTextContent(isDark);
      case 'IMAGE':
        return _buildImageContent();
      case 'FILE':
        return _buildFileContent(isDark);
      case 'PROJECT_CARD':
        return ProjectCardMessage(content: message.body as ProjectCardContent);
      default:
        return Text(
          '[不支持的消息类型]',
          style: TextStyle(
            fontSize: 14,
            color: isMe ? Colors.white70 : (isDark ? AppColors.darkSecondaryText : Colors.grey[600]),
          ),
        );
    }
  }

  Widget _buildTextContent(bool isDark) {
    final textContent = message.body as TextContent;
    return Text(
      textContent.text,
      style: TextStyle(
        fontSize: 15,
        color: isMe ? Colors.white : (isDark ? AppColors.darkNeutralText : Colors.black87),
      ),
    );
  }

  Widget _buildImageContent() {
    return Builder(
      builder: (context) {
        final apiClient = context.read<ApiClient>();
        final imageContent = message.body as ImageContent;
        
        // 使用 ApiClient 解析图片 URL
        final resolvedUrl = apiClient.resolveUrlSync(imageContent.url);
        final headers = apiClient.getAuthHeaders();
        
        return GestureDetector(
          onTap: () {
            _showImagePreview(context, resolvedUrl, headers);
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 200,
              maxHeight: 200,
            ),
            child: CachedNetworkImage(
              imageUrl: resolvedUrl,
              httpHeaders: headers,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 200,
                height: 200,
                color: Colors.grey[300],
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(AppColors.brandGreen),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: 200,
                height: 200,
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  /// 显示图片预览
  void _showImagePreview(BuildContext context, String imageUrl, Map<String, String> headers) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.86),
      builder: (dialogContext) => _ImagePreviewDialog(
        imageUrl: imageUrl,
        headers: headers,
      ),
    );
  }

  Widget _buildFileContent(bool isDark) {
    return Builder(
      builder: (context) {
        final apiClient = context.read<ApiClient>();
        final fileContent = message.body as FileContent;
        
        return GestureDetector(
          onTap: () {
            _handleFileTap(context, apiClient, fileContent);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.insert_drive_file,
                color: isMe ? Colors.white : AppColors.brandGreen,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileContent.filename,
                      style: TextStyle(
                        fontSize: 14,
                        color: isMe ? Colors.white : (isDark ? AppColors.darkNeutralText : Colors.black87),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (fileContent.size != null)
                      Text(
                        _formatFileSize(fileContent.size!),
                        style: TextStyle(
                          fontSize: 12,
                          color: isMe ? Colors.white70 : (isDark ? AppColors.darkSecondaryText : Colors.grey[600]),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  /// 处理文件点击
  Future<void> _handleFileTap(BuildContext context, ApiClient apiClient, FileContent fileContent) async {
    if (fileContent.url.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('文件链接不可用')),
        );
      }
      return;
    }

    try {
      // 解析文件 URL
      final resolvedUrl = await apiClient.resolveUrl(fileContent.url);
      
      if (!context.mounted) return;
      
      final uri = Uri.tryParse(resolvedUrl);
      if (uri == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法识别的文件链接')),
        );
        return;
      }

      // 判断文件类型，决定打开方式
      final fileExt = fileContent.filename.toLowerCase().split('.').last;
      final isPdf = fileExt == 'pdf';
      final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(fileExt);
      final isVideo = ['mp4', 'avi', 'mov', 'mkv', 'webm'].contains(fileExt);
      
      LaunchMode launchMode;
      if (isPdf || isVideo) {
        // PDF 和视频使用外部应用打开
        launchMode = LaunchMode.externalApplication;
      } else if (isImage) {
        // 图片显示预览对话框
        final headers = apiClient.getAuthHeaders();
        await showDialog(
          context: context,
          barrierColor: Colors.black.withValues(alpha: 0.86),
          builder: (dialogContext) => _ImagePreviewDialog(
            imageUrl: resolvedUrl,
            headers: headers,
            title: fileContent.filename,
          ),
        );
        return;
      } else {
        // 其他文件使用平台默认方式打开
        launchMode = LaunchMode.platformDefault;
      }

      final success = await launchUrl(uri, mode: launchMode);
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法打开该文件，请稍后重试')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('打开文件失败: $e')),
        );
      }
    }
  }

  Widget _buildStatusIndicator(bool isDark) {
    if (message.localStatus == null) return const SizedBox.shrink();

    IconData icon;
    Color color;

    switch (message.localStatus!) {
      case MessageStatus.sending:
        icon = Icons.access_time;
        color = isDark ? AppColors.darkSecondaryText : Colors.grey[500]!;
        break;
      case MessageStatus.sent:
        icon = Icons.done;
        color = AppColors.brandGreen;
        break;
      case MessageStatus.failed:
        icon = Icons.error_outline;
        color = Colors.red;
        break;
    }

    return Icon(icon, size: 14, color: color);
  }

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// 图片预览对话框
class _ImagePreviewDialog extends StatelessWidget {
  const _ImagePreviewDialog({
    required this.imageUrl,
    required this.headers,
    this.title,
  });

  final String imageUrl;
  final Map<String, String> headers;
  final String? title;

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
            // 顶部标题栏（如果有标题）
            if (title != null)
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
                          title!,
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
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // 右上角关闭按钮（如果没有标题栏，或者作为备用）
            Positioned(
              right: 8,
              top: title != null ? 56 : 8,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
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

