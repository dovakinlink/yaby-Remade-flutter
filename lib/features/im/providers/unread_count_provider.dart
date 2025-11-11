import 'package:flutter/foundation.dart';
import 'package:yabai_app/features/im/data/repositories/im_repository.dart';

/// IM未读消息总数Provider
class UnreadCountProvider extends ChangeNotifier {
  final ImRepository _repository;

  UnreadCountProvider(this._repository);

  /// 未读消息总数
  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  /// 是否正在加载
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// 最后更新时间
  DateTime? _lastUpdateTime;
  DateTime? get lastUpdateTime => _lastUpdateTime;

  /// 加载未读消息总数
  Future<void> loadUnreadCount() async {
    if (_isLoading) return; // 防止重复请求

    _isLoading = true;
    notifyListeners();

    try {
      final count = await _repository.getUnreadCount();
      _unreadCount = count;
      _lastUpdateTime = DateTime.now();
      debugPrint('IM未读消息总数: $count');
    } catch (e) {
      debugPrint('获取未读消息总数失败: $e');
      // 出错时保持原有数值，不影响用户体验
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 清除未读数（当用户进入聊天页面后可以调用）
  void clearUnreadCount() {
    _unreadCount = 0;
    notifyListeners();
  }

  /// 手动设置未读数（用于接收到新消息时）
  void setUnreadCount(int count) {
    _unreadCount = count;
    notifyListeners();
  }

  /// 增加未读数
  void incrementUnreadCount([int count = 1]) {
    _unreadCount += count;
    notifyListeners();
  }
}

