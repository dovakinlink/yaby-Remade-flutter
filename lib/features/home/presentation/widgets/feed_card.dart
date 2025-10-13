import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yabai_app/core/network/api_client.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/home/data/models/announcement_model.dart';

class FeedCard extends StatelessWidget {
  const FeedCard({super.key, required this.announcement, this.onTap});

  final AnnouncementModel announcement;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkCardBackground : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _AnnouncementCardContent(announcement: announcement),
        ),
      ),
    );
  }
}

class _AnnouncementCardContent extends StatelessWidget {
  const _AnnouncementCardContent({required this.announcement});

  final AnnouncementModel announcement;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final description = _plainText(announcement.displayContent);

    final badges = <Widget>[
      if (announcement.isTop)
        const _BadgeChip(
          label: '置顶',
          backgroundColor: Color(0xFFFFF2ED),
          textColor: Color(0xFFB42318),
        ),
      // 用户帖子显示标签名称，官方公告显示类型
      if (announcement.isUserPost && announcement.tagName != null)
        _BadgeChip(
          label: announcement.tagName!,
          backgroundColor: const Color(0xFFFFE8E8), // 浅红色背景
          textColor: const Color(0xFFE53935), // 红色文字
          borderColor: const Color(0xFFE53935).withValues(alpha: 0.5),
        )
      else if (announcement.isOfficial)
        _BadgeChip(
          label: announcement.noticeTypeLabel,
          backgroundColor: AppColors.brandGreen.withValues(alpha: 0.12),
          textColor: AppColors.brandGreen,
          borderColor: AppColors.brandGreen.withValues(alpha: 0.65),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 用户帖子显示发帖人信息
        if (announcement.isUserPost && announcement.publisherName != null) ...[
          Row(
            children: [
              _UserAvatar(
                avatarUrl: announcement.publisherAvatarUrl,
                userName: announcement.publisherName!,
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      announcement.publisherName!,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkNeutralText : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      announcement.publishedLabel,
                      style: textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(spacing: 8, runSpacing: 4, children: badges),
            ],
          ),
          const SizedBox(height: 16),
        ],
        // 官方公告显示时间和标签
        if (!announcement.isUserPost) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  announcement.publishedLabel,
                  style: textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.darkSecondaryText : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
              Wrap(spacing: 8, runSpacing: 4, children: badges),
            ],
          ),
          const SizedBox(height: 16),
        ],
        Text(
          announcement.title,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            height: 1.3,
            color: isDark ? AppColors.darkNeutralText : null,
          ),
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            description,
            style: textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.darkSecondaryText : Colors.grey[700],
              height: 1.5,
              fontSize: 14,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1)
            : null,
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

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.avatarUrl,
    required this.userName,
    required this.isDark,
  });

  final String? avatarUrl;
  final String userName;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final displayInitial = userName.isNotEmpty ? userName[0].toUpperCase() : '用';
    final apiClient = context.read<ApiClient>();
    final resolvedUrl = avatarUrl != null && avatarUrl!.isNotEmpty
        ? apiClient.resolveUrlSync(avatarUrl!)
        : null;
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.brandGreen.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: resolvedUrl != null
          ? ClipOval(
              child: Image.network(
                resolvedUrl,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                headers: apiClient.getAuthHeaders(),
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text(
                      displayInitial,
                      style: const TextStyle(
                        color: AppColors.brandGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            )
          : Center(
              child: Text(
                displayInitial,
                style: const TextStyle(
                  color: AppColors.brandGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }
}

String _plainText(String value) {
  if (value.isEmpty) {
    return '';
  }
  final withoutTags = value.replaceAll(RegExp(r'<[^>]*>'), ' ');
  final normalized = withoutTags
      .replaceAll('&nbsp;', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return normalized;
}
