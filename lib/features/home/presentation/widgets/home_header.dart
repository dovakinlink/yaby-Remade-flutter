import 'package:flutter/material.dart';
import 'package:yabai_app/core/theme/app_theme.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, this.onOpenDrawer, this.onOpenMessages});

  final VoidCallback? onOpenDrawer;
  final VoidCallback? onOpenMessages;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
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
          // 中间标题
          Expanded(
            child: Text(
              '首页',
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          // 右侧消息按钮
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: onOpenMessages,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Colors.white,
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
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(1),
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
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
    );
  }
}
