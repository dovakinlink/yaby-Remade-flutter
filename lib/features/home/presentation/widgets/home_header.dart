import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/core/providers/theme_provider.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, this.onOpenDrawer, this.onOpenMessages});

  final VoidCallback? onOpenDrawer;
  final VoidCallback? onOpenMessages;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左侧菜单按钮
          GestureDetector(
            onTap: onOpenDrawer,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.brandGreen,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.grid_view_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
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
              Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: onOpenMessages,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkNeutralText : Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: isDark ? AppColors.darkScaffoldBackground : Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                  // 消息数字标记
                  Positioned(
                    top: -8,
                    right: -8,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkScaffoldBackground : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(1),
                        decoration: const BoxDecoration(
                          color: AppColors.brandGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            '2',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
