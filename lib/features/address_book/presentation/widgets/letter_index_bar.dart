import 'package:flutter/material.dart';
import 'package:yabai_app/core/theme/app_theme.dart';

class LetterIndexBar extends StatefulWidget {
  const LetterIndexBar({
    super.key,
    required this.availableLetters,
    required this.onLetterTap,
  });

  final List<String> availableLetters;
  final ValueChanged<String> onLetterTap;

  @override
  State<LetterIndexBar> createState() => _LetterIndexBarState();
}

class _LetterIndexBarState extends State<LetterIndexBar> {
  String? _activeLetter;

  static const _allLetters = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '#',
  ];

  void _handleLetterTap(String letter) {
    if (widget.availableLetters.contains(letter)) {
      setState(() {
        _activeLetter = letter;
      });
      widget.onLetterTap(letter);
      
      // 重置高亮状态
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _activeLetter = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 24,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _allLetters.map((letter) {
          final isAvailable = widget.availableLetters.contains(letter);
          final isActive = _activeLetter == letter;

          return GestureDetector(
            onTap: () => _handleLetterTap(letter),
            child: Container(
              width: 20,
              height: 14,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.brandGreen.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isAvailable ? FontWeight.w600 : FontWeight.normal,
                  color: isAvailable
                      ? (isActive
                          ? AppColors.brandGreen
                          : (isDark
                              ? AppColors.darkNeutralText
                              : Colors.black87))
                      : (isDark
                          ? AppColors.darkSecondaryText.withValues(alpha: 0.3)
                          : Colors.grey.withValues(alpha: 0.3)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

