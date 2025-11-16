import 'package:flutter/material.dart';
import 'package:yabai_app/core/network/api_exception.dart';
import 'package:yabai_app/core/network/models/page_response.dart';
import 'package:yabai_app/features/home/data/models/project_model.dart';
import 'package:yabai_app/features/home/data/repositories/project_repository.dart';

class ProjectListByPersonProvider extends ChangeNotifier {
  ProjectListByPersonProvider({
    required ProjectRepository repository,
    required this.personId,
  }) : _repository = repository;

  final ProjectRepository _repository;
  final String personId;

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

  Future<void> loadInitial({bool force = false}) async {
    if (_isInitialLoading && !force) {
      return;
    }

    _isInitialLoading = true;
    _isLoadingMore = false;
    _hasNext = true;
    _currentPage = 1;
    _errorMessage = null;
    _loadMoreError = null;
    notifyListeners();

    try {
      final page = await _repository.fetchProjectsByPersonId(
        personId: personId,
        page: _currentPage,
        size: _pageSize,
      );

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

    try {
      final nextPage = _currentPage + 1;
      final page = await _repository.fetchProjectsByPersonId(
        personId: personId,
        page: nextPage,
        size: _pageSize,
      );

      _projects.addAll(page.data);
      _currentPage = page.page;
      _hasNext = page.hasNext;
      _loadMoreError = null;
    } on ApiException catch (error) {
      _loadMoreError = error.message;
    } catch (error) {
      _loadMoreError = '加载失败: $error';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }
}

