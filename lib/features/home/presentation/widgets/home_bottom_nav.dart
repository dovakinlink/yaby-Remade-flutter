import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yabai_app/core/theme/app_theme.dart';

class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = <_NavItemData>[
    _NavItemData('assets/icons/tab_home.svg', '首页'),
    _NavItemData('assets/icons/tab_search.svg', '探索'),
    _NavItemData('assets/icons/tab_grid.svg', '工作台'),
    _NavItemData('assets/icons/tab_bell.svg', '消息'),
    _NavItemData('assets/icons/tab_user.svg', '我的'),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: AppColors.brandGreen,
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        showUnselectedLabels: true,
        items: _items
            .map(
              (item) => BottomNavigationBarItem(
                label: item.label,
                icon: _NavIcon(
                  asset: item.asset,
                  color: const Color(0xFF94A3B8),
                ),
                activeIcon: _NavIcon(
                  asset: item.asset,
                  color: AppColors.brandGreen,
                ),
              ),
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
