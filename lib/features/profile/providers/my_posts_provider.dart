import 'package:flutter/material.dart';
import 'package:yabai_app/features/home/data/models/announcement_model.dart';
import 'package:yabai_app/features/profile/data/repositories/my_posts_repository.dart';

class MyPostsProvider extends ChangeNotifier {
  final MyPostsRepository _repository;

  MyPostsProvider(this._repository);

  List<AnnouncementModel> _posts = [];
  bool _isInitialLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String? _loadMoreError;

  int _currentPage = 0;
  bool _hasNext = false;

  List<AnnouncementModel> get posts => _posts;
  bool get isInitialLoading => _isInitialLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  String? get loadMoreError => _loadMoreError;
  bool get hasNext => _hasNext;
  bool get isEmpty => _posts.isEmpty;

  /// 初始加载
  Future<void> loadInitial() async {
    _isInitialLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.getMyPosts(page: 1, size: 10);
      _posts = response.data;
      _currentPage = response.page;
      _hasNext = response.hasNext;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('加载我的帖子失败: $e');
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
      final response = await _repository.getMyPosts(page: nextPage, size: 10);
      _posts.addAll(response.data);
      _currentPage = response.page;
      _hasNext = response.hasNext;
      _loadMoreError = null;
    } catch (e) {
      _loadMoreError = e.toString();
      debugPrint('加载更多我的帖子失败: $e');
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

  /// 根据ID查找公告
  AnnouncementModel? findById(int id) {
    try {
      return _posts.firstWhere((post) => post.id == id);
    } catch (_) {
      return null;
    }
  }
}

