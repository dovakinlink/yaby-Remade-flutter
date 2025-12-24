import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/ai/data/models/ai_session_model.dart';

class AiSessionCard extends StatelessWidget {
  const AiSessionCard({
    super.key,
    required this.session,
    required this.onTap,
  });

  final AiSessionModel session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? AppColors.darkCardBackground : Colors.white,
      elevation: isDark ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 问题内容
              Text(
                session.lastQuestion,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkNeutralText : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              
              // 底部信息
              Row(
                children: [
                  // 匹配数
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brandGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${session.matchCount} 个匹配项目',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.brandGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  
                  // 时间
                  Text(
                    _formatTime(session.lastUpdated),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return DateFormat('MM-dd HH:mm').format(time);
    }
  }
}

