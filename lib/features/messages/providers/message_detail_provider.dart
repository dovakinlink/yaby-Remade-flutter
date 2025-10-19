import 'package:flutter/foundation.dart';
import 'package:yabai_app/features/messages/data/models/message_model.dart';
import 'package:yabai_app/features/messages/data/repositories/message_repository.dart';

/// 消息详情状态管理
class MessageDetailProvider extends ChangeNotifier {
  final MessageRepository _repository;

  MessageDetailProvider(this._repository);

  Message? _message;
  bool _isLoading = false;
  String? _errorMessage;

  /// 消息详情
  Message? get message => _message;

  /// 是否正在加载
  bool get isLoading => _isLoading;

  /// 错误信息
  String? get errorMessage => _errorMessage;

  /// 加载消息详情
  Future<void> loadMessageDetail(int messageId) async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _message = await _repository.getMessageDetail(messageId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _message = null;
      debugPrint('加载消息详情失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 设置消息（从列表页面传入）
  void setMessage(Message message) {
    _message = message;
    _errorMessage = null;
    notifyListeners();
  }

  /// 清除状态
  void clear() {
    _message = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  /// 清除错误信息
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// 重新加载
  Future<void> reload() async {
    if (_message != null) {
      await loadMessageDetail(_message!.id);
    }
  }
}
