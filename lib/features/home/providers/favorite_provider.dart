import 'package:flutter/material.dart';
import 'package:yabai_app/features/home/data/repositories/favorite_repository.dart';

class FavoriteProvider extends ChangeNotifier {
  final FavoriteRepository _repository;

  FavoriteProvider(this._repository);

  bool _isFavorited = false;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isFavorited => _isFavorited;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// 检查收藏状态
  Future<void> checkFavoriteStatus(int projectId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _isFavorited = await _repository.checkFavoriteStatus(projectId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _isFavorited = false;
      debugPrint('检查收藏状态失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 切换收藏状态
  Future<bool> toggleFavorite(int projectId, {String? note}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_isFavorited) {
        // 取消收藏
        await _repository.removeFavorite(projectId);
        _isFavorited = false;
      } else {
        // 收藏
        await _repository.addFavorite(projectId, note: note);
        _isFavorited = true;
      }
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('切换收藏状态失败: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 重置状态
  void reset() {
    _isFavorited = false;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}

