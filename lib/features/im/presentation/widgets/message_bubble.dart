import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/core/network/api_client.dart';
import 'package:yabai_app/features/im/data/models/im_message_model.dart';
import 'package:yabai_app/features/im/data/models/message_content.dart';
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
        final avatarUrl = message.senderAvatar;
        
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
        
        return ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 200,
            maxHeight: 200,
          ),
          child: CachedNetworkImage(
            imageUrl: resolvedUrl,
            httpHeaders: apiClient.getAuthHeaders(), // 添加认证头
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
        );
      },
    );
  }

  Widget _buildFileContent(bool isDark) {
    final fileContent = message.body as FileContent;
    return Row(
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
    );
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

