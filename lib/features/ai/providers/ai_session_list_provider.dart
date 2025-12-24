import 'package:flutter/foundation.dart';
import 'package:yabai_app/core/network/api_exception.dart';
import 'package:yabai_app/features/ai/data/models/ai_session_model.dart';
import 'package:yabai_app/features/ai/data/repositories/ai_repository.dart';

class AiSessionListProvider extends ChangeNotifier {
  AiSessionListProvider(this._repository);

  final AiRepository _repository;

  List<AiSessionModel> _sessions = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = true;

  List<AiSessionModel> get sessions => _sessions;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;
  bool get hasSessions => _sessions.isNotEmpty;

  /// 加载初始数据
  Future<void> loadInitial() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();

    try {
      final pageResponse = await _repository.getAiHistory(page: 1, size: 20);
      // 创建新的可增长列表，避免固定长度列表问题
      _sessions = List<AiSessionModel>.from(pageResponse.data);
      _hasMore = pageResponse.data.length >= 20;
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _sessions = [];
    } catch (e) {
      _errorMessage = '加载会话列表失败: $e';
      _sessions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 加载更多数据
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;

    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final pageResponse = await _repository.getAiHistory(
        page: nextPage,
        size: 20,
      );
      
      if (pageResponse.data.isEmpty) {
        _hasMore = false;
      } else {
        _sessions.addAll(pageResponse.data);
        _currentPage = nextPage;
        _hasMore = pageResponse.data.length >= 20;
      }
      
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = '加载更多失败: $e';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// 刷新列表
  Future<void> refresh() async {
    await loadInitial();
  }
}

