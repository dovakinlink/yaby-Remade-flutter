import 'package:flutter/foundation.dart';
import 'package:yabai_app/core/network/api_exception.dart';
import 'package:yabai_app/features/home/data/models/project_model.dart';
import 'package:yabai_app/features/home/data/repositories/project_repository.dart';

class ProjectSelectionProvider extends ChangeNotifier {
  ProjectSelectionProvider(this._repository);

  final ProjectRepository _repository;

  // 项目列表
  List<ProjectModel> _projects = [];
  List<ProjectModel> get projects => _projects;

  // 搜索关键词
  String _searchKeyword = '';
  String get searchKeyword => _searchKeyword;

  // 分页信息
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasNext = false;

  bool get hasNext => _hasNext;

  // 加载状态
  bool _isInitialLoading = false;
  bool _isLoadingMore = false;
  bool _isSearchMode = false;
  String? _errorMessage;
  String? _loadMoreError;

  bool get isInitialLoading => _isInitialLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSearchMode => _isSearchMode;
  String? get errorMessage => _errorMessage;
  String? get loadMoreError => _loadMoreError;

  /// 初始加载
  Future<void> loadInitial() async {
    _isInitialLoading = true;
    _errorMessage = null;
    _currentPage = 1;
    notifyListeners();

    try {
      final response = await _repository.searchProjects(
        keyword: _searchKeyword,
        page: _currentPage,
        size: 20,
      );

      _projects = response.data;
      _currentPage = response.page;
      _totalPages = response.pages;
      _hasNext = response.hasNext;
      _errorMessage = null;

      debugPrint('加载项目成功，共 ${_projects.length} 个项目');
    } on ApiException catch (e) {
      debugPrint('加载失败: ${e.message}');
      _errorMessage = e.message;
      _projects = [];
    } catch (e) {
      debugPrint('加载异常: $e');
      _errorMessage = '加载失败: ${e.toString()}';
      _projects = [];
    } finally {
      _isInitialLoading = false;
      notifyListeners();
    }
  }

  /// 加载更多
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasNext) {
      return;
    }

    _isLoadingMore = true;
    _loadMoreError = null;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;

      final response = await _repository.searchProjects(
        keyword: _searchKeyword,
        page: nextPage,
        size: 20,
      );

      _projects.addAll(response.data);
      _currentPage = response.page;
      _totalPages = response.pages;
      _hasNext = response.hasNext;
      _loadMoreError = null;

      debugPrint('加载更多成功，当前共 ${_projects.length} 个项目');
    } on ApiException catch (e) {
      debugPrint('加载更多失败: ${e.message}');
      _loadMoreError = e.message;
    } catch (e) {
      debugPrint('加载更多异常: $e');
      _loadMoreError = '加载失败: ${e.toString()}';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// 搜索项目
  Future<void> search(String keyword) async {
    final trimmedKeyword = keyword.trim();

    if (trimmedKeyword == _searchKeyword) {
      return;
    }

    _searchKeyword = trimmedKeyword;
    _isSearchMode = trimmedKeyword.isNotEmpty;
    _currentPage = 1;

    debugPrint('搜索项目: $_searchKeyword');
    await loadInitial();
  }

  /// 清空搜索
  Future<void> clearSearch() async {
    if (_searchKeyword.isEmpty) {
      return;
    }

    _searchKeyword = '';
    _isSearchMode = false;
    _currentPage = 1;

    await loadInitial();
  }

  /// 刷新
  Future<void> refresh() async {
    _currentPage = 1;
    await loadInitial();
  }
}

