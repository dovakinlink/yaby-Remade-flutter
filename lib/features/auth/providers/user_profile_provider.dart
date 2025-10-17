import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yabai_app/features/auth/data/models/user_profile.dart';
import 'package:yabai_app/features/auth/data/repositories/user_profile_repository.dart';

class UserProfileProvider extends ChangeNotifier {
  static const String _profileKey = 'user_profile';

  final UserProfileRepository _repository;

  UserProfile? _profile;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  UserProfileProvider(this._repository);

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;
  bool get hasProfile => _profile != null;

  /// 初始化：从本地存储恢复缓存
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_profileKey);

      if (profileJson != null && profileJson.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(profileJson);
        _profile = UserProfile.fromJson(data);
      }
    } catch (e) {
      debugPrint('恢复用户信息缓存失败: $e');
      _profile = null;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// 从API加载用户信息并缓存
  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final profile = await _repository.getUserProfile();
      _profile = profile;
      _errorMessage = null;

      // 缓存到本地存储
      await _cacheProfile(profile);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('加载用户信息失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 缓存用户信息到本地
  Future<void> _cacheProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = jsonEncode(profile.toJson());
      await prefs.setString(_profileKey, profileJson);
    } catch (e) {
      debugPrint('缓存用户信息失败: $e');
    }
  }

  /// 清除用户信息和缓存
  Future<void> clear() async {
    _profile = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileKey);
    } catch (e) {
      debugPrint('清除用户信息缓存失败: $e');
    }
  }

  /// 刷新用户信息
  Future<void> refresh() async {
    await loadProfile();
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) {
    return _repository.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }
}
