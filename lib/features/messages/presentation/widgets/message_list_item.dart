import 'package:flutter/material.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/messages/data/models/message_model.dart';

/// 消息列表项组件
class MessageListItem extends StatelessWidget {
  const MessageListItem({
    super.key,
    required this.message,
    required this.onTap,
  });

  final Message message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: isDark ? AppColors.darkCardBackground : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
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
              // 消息图标
              _buildMessageIcon(isDark),
              const SizedBox(width: 12),
              
              // 消息内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题行
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            message.fromUserName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark 
                                  ? AppColors.darkNeutralText 
                                  : AppColors.lightNeutralText,
                            ),
                          ),
                        ),
                        Text(
                          message.formattedTime,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark 
                                ? AppColors.darkSecondaryText 
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    
                    // 操作类型
                    Text(
                      message.categoryDisplayText,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.brandGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // 消息内容摘录
                    Text(
                      message.contentExcerpt,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark 
                            ? AppColors.darkSecondaryText 
                            : const Color(0xFF4B5563),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // 未读指示器
              if (message.isUnread) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageIcon(bool isDark) {
    IconData iconData;
    Color backgroundColor;
    
    switch (message.category) {
      case 'NOTICE_COMMENT':
        iconData = Icons.comment_outlined;
        backgroundColor = AppColors.brandGreen.withValues(alpha: 0.1);
        break;
      case 'COMMENT_REPLY':
        iconData = Icons.reply_outlined;
        backgroundColor = Colors.blue.withValues(alpha: 0.1);
        break;
      default:
        iconData = Icons.notifications_outlined;
        backgroundColor = Colors.grey.withValues(alpha: 0.1);
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        iconData,
        size: 20,
        color: message.category == 'NOTICE_COMMENT' 
            ? AppColors.brandGreen 
            : message.category == 'COMMENT_REPLY'
                ? Colors.blue
                : Colors.grey[600],
      ),
    );
  }
}
