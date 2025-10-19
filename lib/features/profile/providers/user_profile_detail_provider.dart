import 'package:flutter/foundation.dart';
import 'package:yabai_app/core/network/api_exception.dart';
import 'package:yabai_app/features/auth/data/repositories/user_profile_repository.dart';
import 'package:yabai_app/features/profile/data/models/user_profile_model.dart';

/// 用户详情页状态管理
class UserProfileDetailProvider extends ChangeNotifier {
  UserProfileDetailProvider({
    required UserProfileRepository repository,
    required this.userId,
  }) : _repository = repository;

  final UserProfileRepository _repository;
  final int userId;

  UserProfileModel? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  UserProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// 加载用户详情
  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _repository.fetchUserProfile(userId);
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = '加载失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 重新加载
  Future<void> reload() async {
    await loadProfile();
  }
}

