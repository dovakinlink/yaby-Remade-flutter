import 'package:flutter/material.dart';
import 'package:yabai_app/core/theme/app_theme.dart';

/// Shared layout wrapper for project detail sections to keep styling consistent.
class ProjectDetailSectionContainer extends StatelessWidget {
  const ProjectDetailSectionContainer({
    super.key,
    required this.child,
    this.showTopDivider = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
  });

  final Widget child;
  final bool showTopDivider;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor =
        isDark ? AppColors.darkDividerColor : AppColors.lightDividerColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTopDivider)
          Container(
            height: 1,
            color: dividerColor,
          ),
        Padding(
          padding: padding,
          child: child,
        ),
      ],
    );
  }
}
