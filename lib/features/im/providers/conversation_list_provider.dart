import 'package:flutter/foundation.dart';
import 'package:yabai_app/features/im/data/repositories/im_repository.dart';
import 'package:yabai_app/features/im/data/local/im_database.dart';
import 'package:yabai_app/features/im/data/models/conversation_model.dart';
import 'package:yabai_app/features/im/data/models/im_message_model.dart';

/// 会话列表状态管理
class ConversationListProvider extends ChangeNotifier {
  final ImRepository _repository;

  List<Conversation> _conversations = [];
  List<Conversation> get conversations => _conversations;

  bool _isInitialLoading = false;
  bool get isInitialLoading => _isInitialLoading;

  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  ConversationListProvider(this._repository);

  /// 初次加载
  Future<void> loadInitial() async {
    if (_isInitialLoading) return;

    _isInitialLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 先从本地数据库加载
      _conversations = await ImDatabase.getConversations();
      notifyListeners();

      // 再从服务器刷新
      await _loadFromServer();
    } catch (e) {
      debugPrint('会话列表加载失败: $e');
      _errorMessage = e.toString();
    } finally {
      _isInitialLoading = false;
      notifyListeners();
    }
  }

  /// 刷新会话列表
  Future<void> refresh() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _loadFromServer();
    } catch (e) {
      debugPrint('会话列表刷新失败: $e');
      _errorMessage = e.toString();
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// 从服务器加载
  Future<void> _loadFromServer() async {
    final conversations = await _repository.getConversations();

    // 调试：打印从API获取的会话信息
    for (final conv in conversations) {
      debugPrint('会话 ${conv.title}: lastMessageType=${conv.lastMessageType}, lastMessageContent=${conv.lastMessageContent}');
    }

    // 保存到本地数据库
    for (final conv in conversations) {
      await ImDatabase.saveConversation(conv);
    }

    // 重新从数据库加载（保证数据一致性）
    _conversations = await ImDatabase.getConversations();
    
    // 调试：打印从数据库读取的会话信息
    for (final conv in _conversations) {
      debugPrint('数据库会话 ${conv.title}: lastMessageType=${conv.lastMessageType}, lastMessageContent=${conv.lastMessageContent}');
    }
    
    notifyListeners();
  }

  /// 处理新消息（更新会话列表）
  Future<void> handleNewMessage(ImMessage message) async {
    try {
      // 更新会话的最后消息
      await ImDatabase.updateConversationLastMessage(
        convId: message.convId,
        seq: message.seq,
        messageAt: message.createdAt,
        preview: message.getPreviewText(),
      );

      // 增加未读数
      await ImDatabase.incrementUnreadCount(message.convId);

      // 重新加载会话列表
      _conversations = await ImDatabase.getConversations();
      notifyListeners();
    } catch (e) {
      debugPrint('处理新消息失败: $e');
    }
  }

  /// 清除会话未读数
  Future<void> clearUnreadCount(String convId) async {
    try {
      await ImDatabase.clearUnreadCount(convId);

      // 更新本地列表
      final index = _conversations.indexWhere((c) => c.convId == convId);
      if (index != -1) {
        _conversations[index] = _conversations[index].copyWith(unreadCount: 0);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('清除未读数失败: $e');
    }
  }

  /// 删除会话
  Future<void> deleteConversation(String convId) async {
    try {
      await ImDatabase.deleteConversation(convId);
      _conversations.removeWhere((c) => c.convId == convId);
      notifyListeners();
    } catch (e) {
      debugPrint('删除会话失败: $e');
      rethrow;
    }
  }

  /// 创建单聊会话（如果已存在则复用）
  Future<Conversation> createSingleConversation(int targetUserId) async {
    try {
      // 1. 先检查本地数据库是否已有该用户的会话
      Conversation? existingConversation = await ImDatabase.findSingleConversation(targetUserId);
      
      if (existingConversation != null) {
        debugPrint('找到已存在的单聊会话: ${existingConversation.convId}');
        return existingConversation;
      }
      
      // 2. 本地没有，从服务器获取最新的会话列表
      await refresh();
      
      // 3. 再次检查（可能服务器上有但本地还没同步）
      existingConversation = await ImDatabase.findSingleConversation(targetUserId);
      if (existingConversation != null) {
        debugPrint('刷新后找到已存在的单聊会话: ${existingConversation.convId}');
        return existingConversation;
      }
      
      // 4. 确实不存在，调用API创建新会话（API端保证幂等性）
      debugPrint('创建新的单聊会话: targetUserId=$targetUserId');
      final conversation = await _repository.createSingleConversation(targetUserId);
      
      // 5. 保存到本地数据库
      await ImDatabase.saveConversation(conversation);
      
      // 6. 重新加载会话列表
      _conversations = await ImDatabase.getConversations();
      notifyListeners();
      
      return conversation;
    } catch (e) {
      debugPrint('创建单聊会话失败: $e');
      rethrow;
    }
  }
}

