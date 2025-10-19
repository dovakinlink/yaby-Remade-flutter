import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yabai_app/core/theme/app_theme.dart';
import 'package:yabai_app/features/profile/presentation/pages/user_profile_detail_page.dart';

/// 可点击的用户头像组件
class ClickableUserAvatar extends StatelessWidget {
  const ClickableUserAvatar({
    super.key,
    required this.userId,
    this.avatarUrl,
    this.radius = 20,
  });

  final int userId;
  final String? avatarUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.pushNamed(
          UserProfileDetailPage.routeName,
          pathParameters: {'userId': userId.toString()},
        );
      },
      child: CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.brandGreen.withValues(alpha: 0.1),
        backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
            ? NetworkImage(avatarUrl!)
            : null,
        child: avatarUrl == null || avatarUrl!.isEmpty
            ? Icon(
                Icons.person,
                size: radius * 0.8,
                color: AppColors.brandGreen,
              )
            : null,
      ),
    );
  }
}

