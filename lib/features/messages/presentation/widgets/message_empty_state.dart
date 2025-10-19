import 'package:flutter/material.dart';
import 'package:yabai_app/core/theme/app_theme.dart';

/// 消息空状态组件
class MessageEmptyState extends StatelessWidget {
  const MessageEmptyState({
    super.key,
    this.title = '暂无消息',
    this.subtitle = '目前没有未读消息',
    this.onRefresh,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 空状态图标
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.brandGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 40,
                color: AppColors.brandGreen.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            
            // 标题
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark 
                    ? AppColors.darkNeutralText 
                    : AppColors.lightNeutralText,
              ),
            ),
            const SizedBox(height: 8),
            
            // 副标题
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: isDark 
                    ? AppColors.darkSecondaryText 
                    : const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            
            // 刷新按钮（可选）
            if (onRefresh != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('刷新'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandGreen,
                  side: BorderSide(color: AppColors.brandGreen),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
