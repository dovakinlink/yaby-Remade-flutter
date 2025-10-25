import 'package:flutter/material.dart';
import 'package:yabai_app/core/network/api_exception.dart';
import 'package:yabai_app/features/home/data/models/announcement_model.dart';
import 'package:yabai_app/features/home/data/models/notice_tag_model.dart';
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

  final List<NoticeTagModel> _tags = <NoticeTagModel>[];
  List<NoticeTagModel> get tags => List.unmodifiable(_tags);

  bool _isTagLoading = false;

  int? _selectedTagId;
  int? get selectedTagId => _selectedTagId;

  int _currentPage = 0;
  int _pageSize = 10;
  int? _noticeType;
  int _requestId = 0;

  Future<void> loadInitial({int? noticeType, bool force = false}) async {
    if (_isInitialLoading && !force) {
      return;
    }

    final currentRequestId = ++_requestId;
    _noticeType = noticeType ?? _noticeType;
    _isInitialLoading = true;
    _isLoadingMore = false;
    _hasNext = true;
    _currentPage = 1;
    _errorMessage = null;
    _loadMoreError = null;
    notifyListeners();

    debugPrint('═══ HomeAnnouncementsProvider: loadInitial ═══');
    debugPrint('当前选中的标签ID: $_selectedTagId');
    debugPrint('noticeType: $_noticeType');
    debugPrint('page: $_currentPage, size: $_pageSize');

    try {
      final page = await _repository.fetchHomeAnnouncements(
        page: _currentPage,
        size: _pageSize,
        noticeType: _noticeType,
        tagId: _selectedTagId,
      );
      if (currentRequestId != _requestId) {
        return;
      }
      _announcements
        ..clear()
        ..addAll(page.data);
      _currentPage = page.page;
      _hasNext = page.hasNext;
      _errorMessage = null;
    } on ApiException catch (error) {
      if (currentRequestId != _requestId) {
        return;
      }
      _errorMessage = error.message;
      _announcements.clear();
      _hasNext = false;
    } catch (error) {
      if (currentRequestId != _requestId) {
        return;
      }
      _errorMessage = '加载失败: $error';
      _announcements.clear();
      _hasNext = false;
    } finally {
      if (currentRequestId == _requestId) {
        _isInitialLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> refresh({bool refreshTags = true}) async {
    if (refreshTags) {
      await loadAnnouncementTags(force: true);
    }
    await loadInitial(force: true);
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasNext) {
      return;
    }

    _isLoadingMore = true;
    _loadMoreError = null;
    notifyListeners();

    final nextPage = _currentPage + 1;
    
    debugPrint('═══ HomeAnnouncementsProvider: loadMore ═══');
    debugPrint('当前选中的标签ID: $_selectedTagId');
    debugPrint('noticeType: $_noticeType');
    debugPrint('page: $nextPage, size: $_pageSize');
    
    try {
      final page = await _repository.fetchHomeAnnouncements(
        page: nextPage,
        size: _pageSize,
        noticeType: _noticeType,
        tagId: _selectedTagId,
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

  bool get isLoadingTags => _isTagLoading;

  Future<void> loadAnnouncementTags({bool force = false}) async {
    if (_isTagLoading) {
      debugPrint('HomeAnnouncementsProvider: 标签正在加载中，跳过');
      return;
    }
    if (_tags.isNotEmpty && !force) {
      debugPrint('HomeAnnouncementsProvider: 标签已缓存，跳过加载');
      return;
    }

    _isTagLoading = true;
    notifyListeners();
    
    try {
      debugPrint('HomeAnnouncementsProvider: 开始加载标签列表');
      final fetchedTags = await _repository.fetchAnnouncementTags();
      _tags
        ..clear()
        ..addAll(fetchedTags);
      debugPrint('HomeAnnouncementsProvider: 成功加载 ${_tags.length} 个标签');
      notifyListeners();
    } on ApiException catch (e) {
      debugPrint('HomeAnnouncementsProvider: 加载标签失败 (ApiException): ${e.message}');
      // Hide errors per requirement: silently skip when tags unavailable.
    } catch (e) {
      debugPrint('HomeAnnouncementsProvider: 加载标签失败 (Exception): $e');
      // Ignore other errors to keep feed usable.
    } finally {
      _isTagLoading = false;
      notifyListeners();
    }
  }

  Future<void> applyTagFilter(int? tagId) async {
    debugPrint('═══ HomeAnnouncementsProvider: applyTagFilter ═══');
    debugPrint('新标签ID: $tagId');
    debugPrint('旧标签ID: $_selectedTagId');
    
    if (_selectedTagId == tagId && _announcements.isNotEmpty) {
      debugPrint('标签未变化，跳过刷新');
      return;
    }
    
    _selectedTagId = tagId;
    debugPrint('更新标签ID为: $_selectedTagId');
    debugPrint('开始重新加载公告列表...');
    
    await loadInitial(force: true);
  }
}
