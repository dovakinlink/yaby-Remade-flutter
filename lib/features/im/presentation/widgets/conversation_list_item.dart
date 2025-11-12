import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/core/network/api_client.dart';
import 'package:yabai_app/features/im/data/models/conversation_model.dart';

/// 会话列表项组件
class ConversationListItem extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const ConversationListItem({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: isDark
                  ? AppColors.darkDividerColor
                  : AppColors.lightDividerColor,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头像
            _buildAvatar(),
            const SizedBox(width: 12),
            // 内容区域
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // 标题
                      Expanded(
                        child: Text(
                          conversation.title ?? '未命名会话',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkNeutralText
                                : AppColors.lightNeutralText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 时间
                      Text(
                        _formatTime(conversation.lastMessageAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // 最后消息预览
                      Expanded(
                        child: Text(
                          _buildLastMessageText(conversation),
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 未读数量徽章
                      if (conversation.unreadCount > 0)
                        _buildUnreadBadge(conversation.unreadCount),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Builder(
      builder: (context) {
        final apiClient = context.read<ApiClient>();
        final avatarUrl = conversation.avatar;
        
        // 使用 ApiClient 解析 URL
        final resolvedUrl = avatarUrl != null && avatarUrl.isNotEmpty
            ? apiClient.resolveUrlSync(avatarUrl)
            : null;
        
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.brandGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: resolvedUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    resolvedUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    headers: apiClient.getAuthHeaders(), // 添加认证头
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultAvatar();
                    },
                  ),
                )
              : _buildDefaultAvatar(),
        );
      },
    );
  }

  Widget _buildDefaultAvatar() {
    IconData icon;
    switch (conversation.type) {
      case ConversationType.group:
        icon = Icons.group;
        break;
      case ConversationType.system:
        icon = Icons.notifications;
        break;
      default:
        icon = Icons.person;
    }

    return Icon(
      icon,
      size: 28,
      color: AppColors.brandGreen,
    );
  }

  Widget _buildUnreadBadge(int count) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';

    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays == 0) {
      // 今天，显示时间
      return DateFormat('HH:mm').format(time);
    } else if (diff.inDays == 1) {
      // 昨天
      return '昨天';
    } else if (diff.inDays < 7) {
      // 一周内，显示星期几
      const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      return weekdays[time.weekday - 1];
    } else {
      // 超过一周，显示日期
      return DateFormat('MM-dd').format(time);
    }
  }

  /// 根据 API 新增字段生成最后一条消息的文案
  String _buildLastMessageText(Conversation c) {
    debugPrint('会话列表项 ${c.title}: type=${c.lastMessageType}, content=${c.lastMessageContent}, preview=${c.lastMessagePreview}');
    
    // 优先规则：
    // 1) 如果 lastMessageType == 'TEXT' 且 lastMessageContent 有内容，显示其内容
    if ((c.lastMessageType == 'TEXT') &&
        (c.lastMessageContent != null && c.lastMessageContent!.trim().isNotEmpty)) {
      debugPrint('  -> 显示 lastMessageContent: ${c.lastMessageContent}');
      return c.lastMessageContent!;
    }
    // 2) 如果 lastMessageType == 'PROJECT_CARD'，显示项目卡片标识
    if (c.lastMessageType == 'PROJECT_CARD') {
      debugPrint('  -> 显示 PROJECT_CARD 摘要');
      return '[项目卡片]';
    }
    // 3) 若有历史兼容字段 lastMessagePreview，回退显示
    if (c.lastMessagePreview != null && c.lastMessagePreview!.trim().isNotEmpty) {
      debugPrint('  -> 显示 lastMessagePreview: ${c.lastMessagePreview}');
      return c.lastMessagePreview!;
    }
    // 4) 无内容则显示占位
    debugPrint('  -> 显示默认占位');
    return '暂无内容';
  }
}

