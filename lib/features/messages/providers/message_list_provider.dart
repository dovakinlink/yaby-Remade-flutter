import 'package:flutter/foundation.dart';
import 'package:yabai_app/features/messages/data/models/message_model.dart';
import 'package:yabai_app/features/messages/data/models/message_list_response.dart';
import 'package:yabai_app/features/messages/data/repositories/message_repository.dart';

/// 消息列表状态管理
class MessageListProvider extends ChangeNotifier {
  final MessageRepository _repository;

  MessageListProvider(this._repository);

  final List<Message> _messages = [];
  bool _isInitialLoading = false;
  bool _isLoadingMore = false;
  bool _hasNext = false;
  int _currentPage = 1;
  String? _errorMessage;
  String? _loadMoreError;

  /// 消息列表
  List<Message> get messages => List.unmodifiable(_messages);

  /// 是否初次加载中
  bool get isInitialLoading => _isInitialLoading;

  /// 是否正在加载更多
  bool get isLoadingMore => _isLoadingMore;

  /// 是否还有更多数据
  bool get hasNext => _hasNext;

  /// 当前页码
  int get currentPage => _currentPage;

  /// 错误信息
  String? get errorMessage => _errorMessage;

  /// 加载更多时的错误信息
  String? get loadMoreError => _loadMoreError;

  /// 是否为空列表
  bool get isEmpty => _messages.isEmpty;

  /// 初始加载
  Future<void> loadInitial() async {
    if (_isInitialLoading) return;

    _isInitialLoading = true;
    _errorMessage = null;
    _currentPage = 1;
    notifyListeners();

    try {
      final response = await _repository.getUnreadMessages(page: 1, size: 20);
      _messages.clear();
      _messages.addAll(response.data);
      _hasNext = response.hasNext;
      _currentPage = 1;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('加载消息列表失败: $e');
    } finally {
      _isInitialLoading = false;
      notifyListeners();
    }
  }

  /// 刷新列表
  Future<void> refresh() async {
    _messages.clear();
    _currentPage = 1;
    _hasNext = false;
    _errorMessage = null;
    _loadMoreError = null;
    await loadInitial();
  }

  /// 加载更多
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasNext) return;

    _isLoadingMore = true;
    _loadMoreError = null;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final response = await _repository.getUnreadMessages(page: nextPage, size: 20);
      
      _messages.addAll(response.data);
      _hasNext = response.hasNext;
      _currentPage = nextPage;
      _loadMoreError = null;
    } catch (e) {
      _loadMoreError = e.toString();
      debugPrint('加载更多消息失败: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// 根据ID查找消息
  Message? findById(int messageId) {
    try {
      return _messages.firstWhere((message) => message.id == messageId);
    } catch (e) {
      return null;
    }
  }

  /// 移除消息（查看后可能需要从未读列表中移除）
  void removeMessage(int messageId) {
    _messages.removeWhere((message) => message.id == messageId);
    notifyListeners();
  }

  /// 更新消息状态（标记为已读）
  void updateMessageReadStatus(int messageId) {
    final index = _messages.indexWhere((message) => message.id == messageId);
    if (index != -1) {
      // 从未读列表中移除已读消息
      _messages.removeAt(index);
      notifyListeners();
    }
  }

  /// 清除错误信息
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// 清除加载更多错误信息
  void clearLoadMoreError() {
    if (_loadMoreError != null) {
      _loadMoreError = null;
      notifyListeners();
    }
  }
}
