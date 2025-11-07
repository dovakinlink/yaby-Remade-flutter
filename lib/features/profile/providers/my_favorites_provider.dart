import 'package:flutter/material.dart';
import 'package:yabai_app/features/home/data/models/favorite_project_model.dart';
import 'package:yabai_app/features/home/data/repositories/favorite_repository.dart';

class MyFavoritesProvider extends ChangeNotifier {
  final FavoriteRepository _repository;

  MyFavoritesProvider(this._repository);

  List<FavoriteProjectModel> _favorites = [];
  bool _isInitialLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String? _loadMoreError;

  int _currentPage = 0;
  bool _hasNext = false;

  List<FavoriteProjectModel> get favorites => _favorites;
  bool get isInitialLoading => _isInitialLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  String? get loadMoreError => _loadMoreError;
  bool get hasNext => _hasNext;
  bool get isEmpty => _favorites.isEmpty;

  /// 初始加载
  Future<void> loadInitial() async {
    _isInitialLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.fetchMyFavorites(page: 1, size: 20);
      _favorites = response.data;
      _currentPage = response.page;
      _hasNext = response.hasNext;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('加载我的收藏失败: $e');
    } finally {
      _isInitialLoading = false;
      notifyListeners();
    }
  }

  /// 加载更多
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasNext) return;

    _isLoadingMore = true;
    _loadMoreError = null;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final response = await _repository.fetchMyFavorites(page: nextPage, size: 20);
      _favorites.addAll(response.data);
      _currentPage = response.page;
      _hasNext = response.hasNext;
      _loadMoreError = null;
    } catch (e) {
      _loadMoreError = e.toString();
      debugPrint('加载更多收藏失败: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// 刷新
  Future<void> refresh() async {
    _currentPage = 0;
    _hasNext = false;
    _loadMoreError = null;
    await loadInitial();
  }

  /// 清除缓存数据
  void clear() {
    _favorites = [];
    _currentPage = 0;
    _hasNext = false;
    _errorMessage = null;
    _loadMoreError = null;
    notifyListeners();
  }

  /// 根据项目ID查找收藏
  FavoriteProjectModel? findByProjectId(int projectId) {
    try {
      return _favorites.firstWhere((fav) => fav.projectId == projectId);
    } catch (_) {
      return null;
    }
  }
}

