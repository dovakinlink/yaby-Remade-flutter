import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yabai_app/core/theme/app_theme.dart';

class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.unreadCount = 0, // IM未读消息数
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int unreadCount;

  static const _items = <_NavItemData>[
    _NavItemData('assets/icons/tab_home.svg', '首页'),
    _NavItemData('assets/icons/tab_bell.svg', '聊天'),
    _NavItemData('assets/icons/tab_ai.svg', 'AI'),
    _NavItemData('assets/icons/tab_search.svg', '筛查'),
    _NavItemData('assets/icons/tab_user.svg', '我的'),
  ];

  Widget _buildNavIcon({
    required _NavItemData item,
    required int index,
    required bool isActive,
    required bool isDark,
  }) {
    final iconWidget = _NavIcon(
      asset: item.asset,
      color: isActive 
          ? AppColors.brandGreen 
          : isDark 
              ? AppColors.darkSecondaryText 
              : const Color(0xFF94A3B8),
    );

    // 聊天tab（index=1）显示未读消息角标
    if (index == 1 && unreadCount > 0) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          iconWidget,
          Positioned(
            right: -8,
            top: -4,
            child: Container(
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: isDark ? AppColors.darkCardBackground : Colors.white,
                  width: 1.5,
                ),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }

    return iconWidget;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
        elevation: 0,
        selectedItemColor: AppColors.brandGreen,
        unselectedItemColor: isDark 
            ? AppColors.darkSecondaryText 
            : const Color(0xFF94A3B8),
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkNeutralText : null,
        ),
        unselectedLabelStyle: TextStyle(
          color: isDark ? AppColors.darkSecondaryText : null,
        ),
        showUnselectedLabels: true,
        items: _items
            .asMap()
            .entries
            .map(
              (entry) {
                final index = entry.key;
                final item = entry.value;
                
                return BottomNavigationBarItem(
                  label: item.label,
                  icon: _buildNavIcon(
                    item: item,
                    index: index,
                    isActive: false,
                    isDark: isDark,
                  ),
                  activeIcon: _buildNavIcon(
                    item: item,
                    index: index,
                    isActive: true,
                    isDark: isDark,
                  ),
                );
              },
            )
            .toList(growable: false),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData(this.asset, this.label);

  final String asset;
  final String label;
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.asset, required this.color});

  final String asset;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: 24,
      height: 24,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
