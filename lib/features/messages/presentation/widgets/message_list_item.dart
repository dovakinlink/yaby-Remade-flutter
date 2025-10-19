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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildMessageTitle(isDark),
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
    Color iconColor;
    
    switch (message.iconType) {
      case 'screening':
        iconData = Icons.assignment;
        iconColor = const Color(0xFF8B5CF6); // 紫色
        break;
      case 'comment':
        iconData = message.category == 'COMMENT_REPLY' 
            ? Icons.reply_outlined 
            : Icons.comment_outlined;
        iconColor = AppColors.brandGreen;
        break;
      default:
        iconData = Icons.notifications_outlined;
        iconColor = const Color(0xFF3B82F6);
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        iconData,
        size: 20,
        color: iconColor,
      ),
    );
  }

  /// 构建消息标题（根据类型显示不同内容）
  Widget _buildMessageTitle(bool isDark) {
    if (message.iconType == 'screening' && message.projectName != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.fromUserName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark 
                  ? AppColors.darkNeutralText 
                  : AppColors.lightNeutralText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            message.projectName!,
            style: TextStyle(
              fontSize: 13,
              color: isDark 
                  ? AppColors.darkSecondaryText 
                  : const Color(0xFF6B7280),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }
    
    return Text(
      message.fromUserName,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark 
            ? AppColors.darkNeutralText 
            : AppColors.lightNeutralText,
      ),
    );
  }
}
