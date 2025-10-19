import 'package:flutter/material.dart';
import 'package:yabai_app/features/screening/data/models/screening_model.dart';
import 'package:yabai_app/features/screening/data/repositories/screening_repository.dart';

/// 筛查列表状态管理
class ScreeningListProvider extends ChangeNotifier {
  ScreeningListProvider(this._repository);

  final ScreeningRepository _repository;

  List<ScreeningModel> _screenings = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasNext = false;
  int _total = 0;
  String? _currentStatusFilter;

  List<ScreeningModel> get screenings => _screenings;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  bool get hasNext => _hasNext;
  int get total => _total;
  bool get isEmpty => _screenings.isEmpty && !_isLoading;
  String? get currentStatusFilter => _currentStatusFilter;

  /// 设置状态筛选并重新加载
  Future<void> setStatusFilter(String? statusCode) async {
    if (_currentStatusFilter == statusCode) return;
    
    _currentStatusFilter = statusCode;
    await loadInitial();
  }

  /// 加载初始数据
  Future<void> loadInitial() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    _currentPage = 1;
    notifyListeners();

    try {
      final response = await _repository.fetchMyScreenings(
        statusCode: _currentStatusFilter,
        page: _currentPage,
        size: 20,
      );

      _screenings = response.data;
      _hasNext = response.hasNext;
      _total = response.total;
      _errorMessage = null;
    } catch (error) {
      _errorMessage = error.toString();
      _screenings = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 刷新数据
  Future<void> refresh() async {
    _currentPage = 1;
    _errorMessage = null;

    try {
      final response = await _repository.fetchMyScreenings(
        statusCode: _currentStatusFilter,
        page: _currentPage,
        size: 20,
      );

      _screenings = response.data;
      _hasNext = response.hasNext;
      _total = response.total;
      _errorMessage = null;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      notifyListeners();
    }
  }

  /// 加载更多
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasNext) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final response = await _repository.fetchMyScreenings(
        statusCode: _currentStatusFilter,
        page: nextPage,
        size: 20,
      );

      _screenings.addAll(response.data);
      _currentPage = nextPage;
      _hasNext = response.hasNext;
      _total = response.total;
      _errorMessage = null;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// 清除错误消息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

