import 'package:flutter/material.dart';
import 'package:yabai_app/core/theme/app_theme.dart';

class LetterHeader extends StatelessWidget {
  const LetterHeader({
    super.key,
    required this.letter,
  });

  final String letter;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark
          ? AppColors.darkBackground
          : Colors.grey[100],
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark
              ? AppColors.darkSecondaryText
              : Colors.grey[600],
        ),
      ),
    );
  }
}

