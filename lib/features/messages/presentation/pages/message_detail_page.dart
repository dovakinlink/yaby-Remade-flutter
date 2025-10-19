import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/messages/data/models/message_model.dart';
import 'package:yabai_app/features/messages/providers/message_detail_provider.dart';
import 'package:yabai_app/features/messages/providers/message_unread_count_provider.dart';

/// 消息详情页面
class MessageDetailPage extends StatefulWidget {
  const MessageDetailPage({
    super.key,
    required this.messageId,
    this.message,
  });

  final int messageId;
  final Message? message;

  static const routePath = ':id';
  static const routeName = 'message-detail';

  @override
  State<MessageDetailPage> createState() => _MessageDetailPageState();
}

class _MessageDetailPageState extends State<MessageDetailPage> {
  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MessageDetailProvider>();
      
      if (widget.message != null) {
        // 如果从列表页面传入了消息对象，直接设置
        provider.setMessage(widget.message!);
      }
      
      // 加载消息详情（这会自动标记为已读）
      provider.loadMessageDetail(widget.messageId).then((_) {
        // 加载完成后，减少未读消息数量
        if (mounted && widget.message?.isUnread == true) {
          context.read<MessageUnreadCountProvider>().decrementUnreadCount();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark 
          ? AppColors.darkScaffoldBackground 
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('消息详情'),
        backgroundColor: isDark 
            ? AppColors.darkScaffoldBackground 
            : const Color(0xFFF8F9FA),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Consumer<MessageDetailProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.brandGreen),
              ),
            );
          }

          if (provider.errorMessage != null) {
            return _buildErrorState(provider);
          }

          if (provider.message == null) {
            return const Center(
              child: Text('消息不存在'),
            );
          }

          return _buildMessageDetail(provider.message!, isDark);
        },
      ),
    );
  }

  Widget _buildErrorState(MessageDetailProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.reload(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageDetail(Message message, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        elevation: isDark ? 0 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 消息头部信息
              _buildMessageHeader(message, isDark),
              const SizedBox(height: 20),
              
              // 消息内容
              _buildMessageContent(message, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageHeader(Message message, bool isDark) {
    return Row(
      children: [
        // 消息图标
        _buildMessageIcon(message, isDark),
        const SizedBox(width: 12),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 发送人
              Text(
                message.fromUserName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark 
                      ? AppColors.darkNeutralText 
                      : AppColors.lightNeutralText,
                ),
              ),
              const SizedBox(height: 4),
              
              // 操作类型和时间
              Row(
                children: [
                  Text(
                    message.categoryDisplayText,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.brandGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '·',
                    style: TextStyle(
                      color: isDark 
                          ? AppColors.darkSecondaryText 
                          : const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    message.formattedTime,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark 
                          ? AppColors.darkSecondaryText 
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageIcon(Message message, bool isDark) {
    IconData iconData;
    Color backgroundColor;
    Color iconColor;
    
    switch (message.category) {
      case 'NOTICE_COMMENT':
        iconData = Icons.comment_outlined;
        backgroundColor = AppColors.brandGreen.withValues(alpha: 0.1);
        iconColor = AppColors.brandGreen;
        break;
      case 'COMMENT_REPLY':
        iconData = Icons.reply_outlined;
        backgroundColor = Colors.blue.withValues(alpha: 0.1);
        iconColor = Colors.blue;
        break;
      default:
        iconData = Icons.notifications_outlined;
        backgroundColor = Colors.grey.withValues(alpha: 0.1);
        iconColor = Colors.grey[600]!;
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Icon(
        iconData,
        size: 24,
        color: iconColor,
      ),
    );
  }

  Widget _buildMessageContent(Message message, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        if (message.title.isNotEmpty) ...[
          Text(
            message.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark 
                  ? AppColors.darkNeutralText 
                  : AppColors.lightNeutralText,
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // 内容摘录
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark 
                ? AppColors.darkFieldBackground.withValues(alpha: 0.3)
                : const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark 
                  ? AppColors.darkDividerColor 
                  : AppColors.lightDividerColor,
              width: 1,
            ),
          ),
          child: Text(
            message.contentExcerpt,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: isDark 
                  ? AppColors.darkNeutralText 
                  : AppColors.lightNeutralText,
            ),
          ),
        ),
      ],
    );
  }
}
