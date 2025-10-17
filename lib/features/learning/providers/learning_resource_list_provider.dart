import 'package:flutter/material.dart';
import 'package:yabai_app/features/learning/data/models/learning_resource_model.dart';
import 'package:yabai_app/features/learning/data/repositories/learning_resource_repository.dart';

class LearningResourceListProvider extends ChangeNotifier {
  final LearningResourceRepository _repository;

  LearningResourceListProvider(this._repository);

  List<LearningResource> _resources = [];
  bool _isInitialLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String? _loadMoreError;

  int _currentPage = 0;
  bool _hasNext = false;
  bool _hasLoadedInitial = false;

  List<LearningResource> get resources => _resources;
  bool get isInitialLoading => _isInitialLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  String? get loadMoreError => _loadMoreError;
  bool get hasNext => _hasNext;
  bool get isEmpty => _resources.isEmpty;
  bool get hasLoadedInitial => _hasLoadedInitial;

  /// 初始加载
  Future<void> loadInitial({bool force = false}) async {
    if (_isInitialLoading) return;
    if (_hasLoadedInitial && !force) return;
    _isInitialLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.getResourceList(page: 1, size: 10);
      _resources = response.data;
      _currentPage = response.page;
      _hasNext = response.hasNext;
      _errorMessage = null;
      _hasLoadedInitial = true;
    } catch (e) {
      _errorMessage = e.toString();
      _hasLoadedInitial = false;
      debugPrint('加载学习资源失败: $e');
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
      final response = await _repository.getResourceList(page: nextPage, size: 10);
      _resources.addAll(response.data);
      _currentPage = response.page;
      _hasNext = response.hasNext;
      _loadMoreError = null;
    } catch (e) {
      _loadMoreError = e.toString();
      debugPrint('加载更多学习资源失败: $e');
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
    _hasLoadedInitial = false;
    await loadInitial(force: true);
  }

  /// 根据ID查找资源
  LearningResource? findById(int id) {
    try {
      return _resources.firstWhere((resource) => resource.id == id);
    } catch (_) {
      return null;
    }
  }
}
