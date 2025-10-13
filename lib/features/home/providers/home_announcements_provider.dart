import 'package:flutter/material.dart';
import 'package:yabai_app/core/network/api_exception.dart';
import 'package:yabai_app/features/home/data/models/announcement_model.dart';
import 'package:yabai_app/features/home/data/repositories/announcement_repository.dart';

class HomeAnnouncementsProvider extends ChangeNotifier {
  HomeAnnouncementsProvider(this._repository);

  final AnnouncementRepository _repository;

  final List<AnnouncementModel> _announcements = <AnnouncementModel>[];
  List<AnnouncementModel> get announcements =>
      List.unmodifiable(_announcements);

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
  int? _noticeType;

  Future<void> loadInitial({int? noticeType, bool force = false}) async {
    if (_isInitialLoading && !force) {
      return;
    }

    _noticeType = noticeType ?? _noticeType;
    _isInitialLoading = true;
    _isLoadingMore = false;
    _hasNext = true;
    _currentPage = 1;
    _errorMessage = null;
    _loadMoreError = null;
    notifyListeners();

    try {
      final page = await _repository.fetchHomeAnnouncements(
        page: _currentPage,
        size: _pageSize,
        noticeType: _noticeType,
      );
      _announcements
        ..clear()
        ..addAll(page.data);
      _currentPage = page.page;
      _hasNext = page.hasNext;
      _errorMessage = null;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      _announcements.clear();
      _hasNext = false;
    } catch (error) {
      _errorMessage = '加载失败: $error';
      _announcements.clear();
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
      final page = await _repository.fetchHomeAnnouncements(
        page: nextPage,
        size: _pageSize,
        noticeType: _noticeType,
      );
      _announcements.addAll(page.data);
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

  AnnouncementModel? findById(int id) {
    try {
      return _announcements.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }
}
