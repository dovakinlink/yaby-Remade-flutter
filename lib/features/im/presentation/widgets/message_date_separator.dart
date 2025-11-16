import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yabai_app/core/theme/app_theme.dart';

/// 消息日期分隔符组件
class MessageDateSeparator extends StatelessWidget {
  final DateTime date;

  const MessageDateSeparator({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark 
              ? Colors.grey[800]?.withValues(alpha: 0.5)
              : Colors.grey[300]?.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _formatDate(date),
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// 格式化日期显示
  /// - 今天：显示"今天"
  /// - 昨天：显示"昨天"
  /// - 今年：显示"MM月DD日"（如：11月15日）
  /// - 往年：显示"YYYY年MM月DD日"（如：2024年11月15日）
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return '今天';
    } else if (messageDate == yesterday) {
      return '昨天';
    } else if (date.year == now.year) {
      // 今年的消息：显示"MM月DD日"
      return '${date.month}月${date.day}日';
    } else {
      // 往年的消息：显示"YYYY年MM月DD日"
      return '${date.year}年${date.month}月${date.day}日';
    }
  }
}

