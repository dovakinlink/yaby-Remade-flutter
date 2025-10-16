import 'package:flutter/material.dart';
import 'package:yabai_app/core/network/api_exception.dart';
import 'package:yabai_app/core/network/models/page_response.dart';
import 'package:yabai_app/features/home/data/models/attr_definition_model.dart';
import 'package:yabai_app/features/home/data/models/filter_value_model.dart';
import 'package:yabai_app/features/home/data/models/project_model.dart';
import 'package:yabai_app/features/home/data/repositories/project_repository.dart';

class ProjectListProvider extends ChangeNotifier {
  ProjectListProvider(this._repository);

  final ProjectRepository _repository;

  final List<ProjectModel> _projects = <ProjectModel>[];
  List<ProjectModel> get projects => List.unmodifiable(_projects);

  bool _isInitialLoading = false;
  bool get isInitialLoading => _isInitialLoading;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  bool _hasNext = true;
  bool get hasNext => _hasNext;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _loadMoreError;
  String? get loadMoreError => _loadMoreError;

  int _currentPage = 0;
  int _pageSize = 10;
  Map<String, String>? _attrFilters;

  // 搜索相关状态
  bool _isSearchMode = false;
  bool get isSearchMode => _isSearchMode;

  String _searchKeyword = '';
  String get searchKeyword => _searchKeyword;

  // 属性定义相关状态
  final List<AttrDefinitionModel> _attrDefinitions = [];
  List<AttrDefinitionModel> get attrDefinitions =>
      List.unmodifiable(_attrDefinitions);

  bool _isLoadingAttrDefinitions = false;
  bool get isLoadingAttrDefinitions => _isLoadingAttrDefinitions;

  String? _attrDefinitionsError;
  String? get attrDefinitionsError => _attrDefinitionsError;

  // 筛选相关状态
  final Map<String, FilterValueModel> _selectedFilters = {};
  Map<String, FilterValueModel> get selectedFilters =>
      Map.unmodifiable(_selectedFilters);

  /// 获取当前生效的筛选条件数量
  int get activeFiltersCount => _selectedFilters.values
      .where((filter) => filter.hasValue)
      .length;

  /// 获取可搜索的属性定义
  List<AttrDefinitionModel> get searchableAttrDefinitions =>
      _attrDefinitions.where((attr) => attr.searchable).toList();

  Future<void> loadInitial({
    Map<String, String>? attrFilters,
    bool force = false,
  }) async {
    if (_isInitialLoading && !force) {
      return;
    }

    _attrFilters = attrFilters ?? _attrFilters;
    _isInitialLoading = true;
    _isLoadingMore = false;
    _hasNext = true;
    _currentPage = 1;
    _errorMessage = null;
    _loadMoreError = null;
    notifyListeners();

    try {
      final PageResponse<ProjectModel> page;

      // 根据搜索模式调用不同的接口
      if (_isSearchMode && _searchKeyword.isNotEmpty) {
        page = await _repository.searchProjects(
          keyword: _searchKeyword,
          page: _currentPage,
          size: _pageSize,
        );
      } else {
        page = await _repository.fetchProjects(
          page: _currentPage,
          size: _pageSize,
          attrFilters: _attrFilters,
        );
      }

      _projects
        ..clear()
        ..addAll(page.data);
      _currentPage = page.page;
      _hasNext = page.hasNext;
      _errorMessage = null;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      _projects.clear();
      _hasNext = false;
    } catch (error) {
      _errorMessage = '加载失败: $error';
      _projects.clear();
      _hasNext = false;
    } finally {
      _isInitialLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() {
    return loadInitial(force: true);
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasNext) {
      return;
    }

    _isLoadingMore = true;
    _loadMoreError = null;
    notifyListeners();

    final nextPage = _currentPage + 1;
    try {
      final PageResponse<ProjectModel> page;

      // 根据搜索模式调用不同的接口
      if (_isSearchMode && _searchKeyword.isNotEmpty) {
        page = await _repository.searchProjects(
          keyword: _searchKeyword,
          page: nextPage,
          size: _pageSize,
        );
      } else {
        page = await _repository.fetchProjects(
          page: nextPage,
          size: _pageSize,
          attrFilters: _attrFilters,
        );
      }

      _projects.addAll(page.data);
      _currentPage = page.page;
      _hasNext = page.hasNext;
    } on ApiException catch (error) {
      _loadMoreError = error.message;
    } catch (error) {
      _loadMoreError = '加载更多失败: $error';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void updatePageSize(int size) {
    if (size == _pageSize) {
      return;
    }
    _pageSize = size;
    loadInitial(force: true);
  }

  ProjectModel? findById(int id) {
    try {
      return _projects.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 加载属性定义
  Future<void> loadAttrDefinitions({
    int? templateId,
    int? disciplineId,
  }) async {
    if (_isLoadingAttrDefinitions) {
      return;
    }

    _isLoadingAttrDefinitions = true;
    _attrDefinitionsError = null;
    notifyListeners();

    try {
      final definitions = await _repository.fetchAttrDefinitions(
        templateId: templateId,
        disciplineId: disciplineId,
      );
      _attrDefinitions
        ..clear()
        ..addAll(definitions);
      _attrDefinitionsError = null;
    } on ApiException catch (error) {
      _attrDefinitionsError = error.message;
      _attrDefinitions.clear();
    } catch (error) {
      _attrDefinitionsError = '加载属性定义失败: $error';
      _attrDefinitions.clear();
    } finally {
      _isLoadingAttrDefinitions = false;
      notifyListeners();
    }
  }

  /// 更新筛选条件并刷新列表
  Future<void> updateFilters(Map<String, FilterValueModel> filters) async {
    print('[ProjectListProvider] 收到筛选条件: ${filters.length} 个');
    _selectedFilters.clear();
    _selectedFilters.addAll(filters);

    // 构建 API 筛选参数
    final attrFilters = <String, String>{};
    for (final filter in filters.values) {
      print('[ProjectListProvider] 处理筛选项: ${filter.attrCode}, 值: ${filter.value}, 类型: ${filter.dataType}');
      if (filter.hasValue) {
        final apiValue = filter.toApiValue();
        print('[ProjectListProvider] API值: $apiValue');
        if (apiValue != null && apiValue.isNotEmpty) {
          attrFilters[filter.attrCode] = apiValue;
          print('[ProjectListProvider] 添加筛选参数: ${filter.attrCode} = $apiValue');
        }
      }
    }

    _attrFilters = attrFilters.isNotEmpty ? attrFilters : null;
    print('[ProjectListProvider] 最终筛选参数: $_attrFilters');

    // 刷新列表
    await loadInitial(force: true);
  }

  /// 清空筛选条件
  Future<void> clearFilters() async {
    _selectedFilters.clear();
    _attrFilters = null;
    await loadInitial(force: true);
  }

  /// 移除单个筛选条件
  Future<void> removeFilter(String attrCode) async {
    _selectedFilters.remove(attrCode);

    // 重新构建 API 筛选参数
    final attrFilters = <String, String>{};
    for (final filter in _selectedFilters.values) {
      if (filter.hasValue) {
        final apiValue = filter.toApiValue();
        if (apiValue != null && apiValue.isNotEmpty) {
          attrFilters[filter.attrCode] = apiValue;
        }
      }
    }

    _attrFilters = attrFilters.isNotEmpty ? attrFilters : null;
    await loadInitial(force: true);
  }

  /// 根据属性定义获取选项标签映射
  Map<int, String> getOptionLabels(String attrCode) {
    final attr = _attrDefinitions.firstWhere(
      (a) => a.code == attrCode,
      orElse: () => throw Exception('未找到属性定义: $attrCode'),
    );
    return Map.fromEntries(
      attr.options.map((opt) => MapEntry(opt.id, opt.label)),
    );
  }

  /// 搜索项目
  Future<void> search(String keyword) async {
    final trimmedKeyword = keyword.trim();

    // 验证关键词
    if (trimmedKeyword.isEmpty) {
      return;
    }

    if (trimmedKeyword.length < 2) {
      _errorMessage = '搜索关键词至少需要2个字符';
      notifyListeners();
      return;
    }

    _isSearchMode = true;
    _searchKeyword = trimmedKeyword;
    _attrFilters = null; // 搜索模式下清空筛选条件

    await loadInitial(force: true);
  }

  /// 清空搜索，返回列表模式
  Future<void> clearSearch() async {
    _isSearchMode = false;
    _searchKeyword = '';
    await loadInitial(force: true);
  }
}

