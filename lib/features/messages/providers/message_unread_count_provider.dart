import 'package:flutter/foundation.dart';
import 'package:yabai_app/features/messages/data/repositories/message_repository.dart';

/// 未读消息数量状态管理
class MessageUnreadCountProvider extends ChangeNotifier {
  final MessageRepository _repository;

  MessageUnreadCountProvider(this._repository);

  int _unreadCount = 0;
  bool _isLoading = false;
  String? _errorMessage;

  /// 未读消息数量
  int get unreadCount => _unreadCount;

  /// 是否正在加载
  bool get isLoading => _isLoading;

  /// 错误信息
  String? get errorMessage => _errorMessage;

  /// 是否有未读消息
  bool get hasUnreadMessages => _unreadCount > 0;

  /// 获取显示的角标文本
  String get badgeText {
    if (_unreadCount <= 0) return '';
    if (_unreadCount > 99) return '99+';
    return _unreadCount.toString();
  }

  /// 加载未读消息数量
  Future<void> loadUnreadCount() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _unreadCount = await _repository.getUnreadCount();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('加载未读消息数量失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 刷新未读消息数量
  Future<void> refresh() async {
    await loadUnreadCount();
  }

  /// 减少未读消息数量（查看消息后调用）
  void decrementUnreadCount() {
    if (_unreadCount > 0) {
      _unreadCount--;
      notifyListeners();
    }
  }

  /// 手动设置未读消息数量
  void setUnreadCount(int count) {
    if (_unreadCount != count) {
      _unreadCount = count;
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
}
