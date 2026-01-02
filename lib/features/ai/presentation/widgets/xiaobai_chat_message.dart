import 'package:flutter/material.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/ai/providers/xiaobai_chat_provider.dart';
import 'package:yabai_app/features/ai/presentation/widgets/thinking_cursor.dart';

class XiaobaiChatMessage extends StatelessWidget {
  const XiaobaiChatMessage({
    super.key,
    required this.message,
  });

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: message.isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.smart_toy,
                size: 20,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppColors.brandGreen
                    : (isDark 
                        ? AppColors.darkCardBackground 
                        : Colors.white),
                borderRadius: BorderRadius.circular(12),
                boxShadow: message.isUser
                    ? []
                    : (isDark
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ]),
              ),
              child: message.isThinking
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ThinkingCursor(
                          color: isDark ? AppColors.darkNeutralText : Colors.black87,
                          width: 2,
                          height: 16,
                        ),
                      ],
                    )
                  : Text(
                      message.content,
                      style: TextStyle(
                        fontSize: 15,
                        color: message.isUser
                            ? Colors.white
                            : (isDark ? AppColors.darkNeutralText : Colors.black87),
                        height: 1.5,
                      ),
                    ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.brandGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.person,
                size: 20,
                color: AppColors.brandGreen,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
