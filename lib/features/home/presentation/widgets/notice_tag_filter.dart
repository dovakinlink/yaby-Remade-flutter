import 'package:flutter/material.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/home/data/models/notice_tag_model.dart';

/// 通知公告标签筛选器
/// 
/// 根据截图设计：
/// - 选中的标签：品牌绿背景 + 白色文字
/// - 未选中的标签：白色背景 + 灰色边框 + 深色文字
/// - 单选模式
class NoticeTagFilter extends StatelessWidget {
  const NoticeTagFilter({
    super.key,
    required this.tags,
    this.selectedTagId,
    required this.onTagSelected,
    this.isLoading = false,
  });

  final List<NoticeTagModel> tags;
  final int? selectedTagId;
  final ValueChanged<int?> onTagSelected;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 加载中显示加载指示器
    if (isLoading) {
      return Container(
        height: 48,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(AppColors.brandGreen),
          ),
        ),
      );
    }

    // 始终显示标签筛选器（至少有"全部"选项）
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tags.length + 1, // +1 for "全部" option
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            // "全部" 选项
            return _TagButton(
              label: '全部',
              isSelected: selectedTagId == null,
              onTap: () => onTagSelected(null),
              isDark: isDark,
            );
          }

          final tag = tags[index - 1];
          return _TagButton(
            label: tag.tagName,
            isSelected: selectedTagId == tag.id,
            onTap: () => onTagSelected(tag.id),
            isDark: isDark,
          );
        },
      ),
    );
  }
}

/// 标签按钮组件
/// 
/// 设计规范（根据截图）：
/// - 选中状态：品牌绿背景 + 白色文字 + 无边框
/// - 未选中状态：透明/白色背景 + 黑色边框 + 深色文字
/// - 圆角：18-20px
/// - 内边距：水平12-16px，垂直6-8px
class _TagButton extends StatelessWidget {
  const _TagButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            // 选中：品牌绿背景，未选中：透明背景
            color: isSelected
                ? AppColors.brandGreen
                : (isDark ? Colors.transparent : Colors.white),
            borderRadius: BorderRadius.circular(16),
            // 未选中时显示边框
            border: isSelected
                ? null
                : Border.all(
                    color: isDark
                        ? Colors.grey[700]!
                        : Colors.black.withOpacity(0.8),
                    width: 1,
                  ),
          ),
          child: Text(
            label,
            style: TextStyle(
              // 选中：白色文字，未选中：深色文字
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.darkNeutralText : Colors.black87),
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

