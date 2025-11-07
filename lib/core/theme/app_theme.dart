import 'package:flutter/material.dart';

class AppColors {
  // 品牌色（在浅色和深色主题中保持一致）
  static const brandGreen = Color(0xFF36CAC4);
  static const accentBlue = Color(0xFF36CAC4);
  static const usernameBlue = Color(0xFF1A73E8);

  // 浅色主题颜色
  static const lightNeutralText = Color(0xFF0F172A);
  static const lightFieldBackground = Color(0xFFF4F5F6);
  static const lightFieldBorder = Color(0xFFCBD5E1);
  static const lightScaffoldBackground = Colors.white;
  static const lightCardBackground = Colors.white;
  static const lightDividerColor = Color(0xFFE5E7EB);

  // 深色主题颜色
  static const darkNeutralText = Color(0xFFF8F9FA);
  static const darkFieldBackground = Color(0xFF3F3F46);
  static const darkFieldBorder = Color(0xFF4B5563);
  static const darkScaffoldBackground = Color(0xFF212121);
  static const darkCardBackground = Color(0xFF333333);
  static const darkDividerColor = Color(0xFF374151);
  static const darkSecondaryText = Color(0xFF9CA3AF);

  // 兼容性（保留原有的静态引用）
  static const lightPrimaryText = lightNeutralText;
  static const darkPrimaryText = darkNeutralText;
  static const neutralText = lightNeutralText;
  static const fieldBackground = lightFieldBackground;
  static const fieldBorder = lightFieldBorder;
}

class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: AppColors.brandGreen,
            brightness: Brightness.light,
          ).copyWith(
            primary: AppColors.brandGreen,
            secondary: AppColors.accentBlue,
          ),
      scaffoldBackgroundColor: AppColors.lightScaffoldBackground,
      fontFamily: 'SF Pro Display',
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.lightNeutralText,
        displayColor: AppColors.lightNeutralText,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightFieldBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.lightFieldBorder,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.lightFieldBorder,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brandGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.brandGreen
              : AppColors.lightFieldBackground,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightDividerColor,
        thickness: 1,
        indent: 0,
        endIndent: 0,
      ),
      // 设置浅色主题应用栏
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightScaffoldBackground,
        foregroundColor: AppColors.lightNeutralText,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: AppColors.brandGreen,
            brightness: Brightness.dark,
          ).copyWith(
            primary: AppColors.brandGreen,
            secondary: AppColors.accentBlue,
            surface: AppColors.darkCardBackground,
            onSurface: AppColors.darkNeutralText,
          ),
      scaffoldBackgroundColor: AppColors.darkScaffoldBackground,
      fontFamily: 'SF Pro Display',
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.darkNeutralText,
        displayColor: AppColors.darkNeutralText,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkFieldBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.darkFieldBorder,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.darkFieldBorder,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brandGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        hintStyle: const TextStyle(color: AppColors.darkSecondaryText),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.darkNeutralText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.brandGreen
              : AppColors.darkFieldBackground,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDividerColor,
        thickness: 1,
        indent: 0,
        endIndent: 0,
      ),
      // 设置图标主题
      iconTheme: const IconThemeData(color: AppColors.darkNeutralText),
      // 设置应用栏主题
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkScaffoldBackground,
        foregroundColor: AppColors.darkNeutralText,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
