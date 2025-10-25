import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/core/providers/theme_provider.dart';
import 'package:yabai_app/features/messages/providers/message_unread_count_provider.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, this.onOpenMessages});

  final VoidCallback? onOpenMessages;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 右侧按钮组
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 主题切换按钮
              GestureDetector(
                onTap: () async {
                  await themeProvider.toggleTheme();
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardBackground : Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    color: isDark ? AppColors.darkNeutralText : Colors.grey[700],
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 消息按钮
              Consumer<MessageUnreadCountProvider>(
                builder: (context, provider, child) {
                  final unreadCount = provider.unreadCount;

                  return Badge(
                    isLabelVisible: unreadCount > 0,
                    label: Text(
                      provider.badgeText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    alignment: AlignmentDirectional.topEnd,
                    offset: const Offset(4, -4),
                    backgroundColor: const Color(0xFFEF4444),
                    child: GestureDetector(
                      onTap: onOpenMessages,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkNeutralText : Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: isDark ? AppColors.darkScaffoldBackground : Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
