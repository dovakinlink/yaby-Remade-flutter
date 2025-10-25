import 'package:flutter/material.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/home/data/models/post_tag_model.dart';

class AnnouncementTagFilter extends StatelessWidget {
  const AnnouncementTagFilter({
    super.key,
    required this.tags,
    required this.selectedTagId,
    required this.onTagSelected,
  });

  final List<PostTagModel> tags;
  final int? selectedTagId;
  final ValueChanged<int?> onTagSelected;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '通知公告标签',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkNeutralText
                  : AppColors.lightNeutralText,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _TagChip(
                  label: '全部',
                  isSelected: selectedTagId == null,
                  isDark: isDark,
                  onTap: () => onTagSelected(null),
                ),
                ...tags.expand(
                  (tag) => [
                    const SizedBox(width: 8),
                    _TagChip(
                      label: tag.tagName,
                      isSelected: selectedTagId == tag.id,
                      isDark: isDark,
                      onTap: () => onTagSelected(tag.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = isSelected
        ? AppColors.brandGreen
        : (isDark ? AppColors.darkFieldBorder : const Color(0xFFCBD5E1));
    final Color textColor = isSelected
        ? Colors.white
        : (isDark ? AppColors.darkNeutralText : AppColors.brandGreen);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
        ),
      ),
    );
  }
}
