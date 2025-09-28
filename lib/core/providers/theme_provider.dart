import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.light;
  bool _isDarkMode = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemeMode();
  }

  /// 切换主题模式
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    _themeMode = _isDarkMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    await _saveThemeMode();
  }

  /// 设置特定主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    _isDarkMode = mode == ThemeMode.dark;
    notifyListeners();
    await _saveThemeMode();
  }

  /// 从SharedPreferences加载主题设置
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);
      
      if (savedTheme != null) {
        switch (savedTheme) {
          case 'dark':
            _themeMode = ThemeMode.dark;
            _isDarkMode = true;
            break;
          case 'light':
            _themeMode = ThemeMode.light;
            _isDarkMode = false;
            break;
          case 'system':
            _themeMode = ThemeMode.system;
            _isDarkMode = false;
            break;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('加载主题设置失败: $e');
    }
  }

  /// 保存主题设置到SharedPreferences
  Future<void> _saveThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String themeString;
      
      switch (_themeMode) {
        case ThemeMode.dark:
          themeString = 'dark';
          break;
        case ThemeMode.light:
          themeString = 'light';
          break;
        case ThemeMode.system:
          themeString = 'system';
          break;
      }
      
      await prefs.setString(_themeKey, themeString);
    } catch (e) {
      debugPrint('保存主题设置失败: $e');
    }
  }
}
