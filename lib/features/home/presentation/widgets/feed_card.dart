import 'package:flutter/material.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/home/data/models/mock_feed.dart';

class FeedCard extends StatelessWidget {
  const FeedCard({super.key, required this.feed});

  final MockFeed feed;

  @override
  Widget build(BuildContext context) {
    switch (feed.type) {
      case MockFeedType.announcement:
        return _AnnouncementFeed(feed: feed);
      case MockFeedType.task:
        return _TaskFeed(feed: feed);
      case MockFeedType.alert:
        return _AlertFeed(feed: feed);
      case MockFeedType.survey:
        return _SurveyFeed(feed: feed);
    }
  }
}

class _AnnouncementFeed extends StatelessWidget {
  const _AnnouncementFeed({required this.feed});

  final MockFeed feed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部时间和通知公告按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                feed.publishedLabel,
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brandGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '通知公告',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 标题
          Text(
            feed.title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          // 描述内容
          if (feed.description != null)
            Text(
              feed.description!,
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
                height: 1.5,
                fontSize: 14,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

class _TaskFeed extends StatelessWidget {
  const _TaskFeed({required this.feed});

  final MockFeed feed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 用户信息行
          Row(
            children: [
              // 用户头像
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/avatar_1.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.person,
                        color: Colors.grey[600],
                        size: 24,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 用户名和时间
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '张紫宁',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    feed.publishedLabel,
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // 添加按钮
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.brandGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 项目标题
          Text(
            feed.title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          // 项目启动标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '项目启动',
              style: TextStyle(
                color: const Color(0xFF166534),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 项目描述
          if (feed.description != null)
            Text(
              feed.description!,
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
                height: 1.5,
                fontSize: 14,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 12),
          // 底部评论数量
          if (feed.participants != null)
            Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  '${feed.participants}',
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _AlertFeed extends StatelessWidget {
  const _AlertFeed({required this.feed});

  final MockFeed feed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2F0),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFD9D4)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Badge(
                label: feed.tag ?? '提醒',
                backgroundColor: const Color(0xFFFFE0DB),
                textColor: const Color(0xFFB42318),
              ),
              const Spacer(),
              Icon(Icons.error_outline, color: const Color(0xFFB42318)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            feed.title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFFB42318),
              height: 1.28,
            ),
          ),
          if (feed.description != null) ...[
            const SizedBox(height: 10),
            Text(
              feed.description!,
              style: textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFB54708),
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Text(
            feed.publishedLabel,
            style: textTheme.bodySmall?.copyWith(
              color: const Color(0xFFB54708),
            ),
          ),
        ],
      ),
    );
  }
}

class _SurveyFeed extends StatelessWidget {
  const _SurveyFeed({required this.feed});

  final MockFeed feed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4FFFE),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD9F4F2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (feed.badgeText != null)
                _Badge(
                  label: feed.badgeText!,
                  backgroundColor: const Color(0xFFE0F7F6),
                  textColor: AppColors.brandGreen,
                ),
              const Spacer(),
              Icon(Icons.file_present_outlined, color: AppColors.brandGreen),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            feed.title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.32,
            ),
          ),
          if (feed.description != null) ...[
            const SizedBox(height: 10),
            Text(
              feed.description!,
              style: textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF334155),
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (feed.participants != null)
            Text(
              '当前参与 ${feed.participants} 人',
              style: textTheme.bodySmall?.copyWith(
                color: const Color(0xFF0F172A),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            feed.publishedLabel,
            style: textTheme.bodySmall?.copyWith(
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
