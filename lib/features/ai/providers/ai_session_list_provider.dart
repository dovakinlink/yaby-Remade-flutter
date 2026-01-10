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

  /// 按 session_id 聚合数据，每个 session_id 只保留最新的一条记录
  List<AiSessionModel> _aggregateBySessionId(List<AiSessionModel> rawData) {
    final Map<String, AiSessionModel> sessionMap = {};
    
    for (final session in rawData) {
      final existingSession = sessionMap[session.sessionId];
      
      // 如果该 session_id 还没有记录，或者当前记录更新，则保留当前记录
      if (existingSession == null || 
          session.lastUpdated.isAfter(existingSession.lastUpdated)) {
        sessionMap[session.sessionId] = session;
      }
    }
    
    // 按最后更新时间降序排序
    final aggregatedList = sessionMap.values.toList()
      ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
    
    return aggregatedList;
  }

  /// 加载初始数据
  Future<void> loadInitial() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();

    try {
      final pageResponse = await _repository.getAiHistory(
        page: 1,
        size: 20,
        agent: 'xiaoya', // 找项目的AI历史会话需要传入agent=xiaoya
      );
      // 按 session_id 聚合数据，避免重复
      _sessions = _aggregateBySessionId(pageResponse.data);
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
        agent: 'xiaoya', // 找项目的AI历史会话需要传入agent=xiaoya
      );
      
      if (pageResponse.data.isEmpty) {
        _hasMore = false;
      } else {
        // 合并现有数据和新数据，然后按 session_id 聚合
        final allData = [..._sessions, ...pageResponse.data];
        _sessions = _aggregateBySessionId(allData);
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

