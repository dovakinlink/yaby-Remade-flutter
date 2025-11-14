import 'package:flutter/foundation.dart';
import 'package:yabai_app/features/im/data/repositories/im_repository.dart';
import 'package:yabai_app/features/im/data/local/im_database.dart';
import 'package:yabai_app/features/im/data/models/conversation_model.dart';
import 'package:yabai_app/features/im/data/models/im_message_model.dart';
import 'package:yabai_app/features/im/data/models/message_content.dart';
import 'package:yabai_app/features/im/providers/websocket_provider.dart';

/// 会话列表状态管理
class ConversationListProvider extends ChangeNotifier {
  final ImRepository _repository;
  final WebSocketProvider? _websocketProvider;

  List<Conversation> _conversations = [];
  List<Conversation> get conversations => _conversations;

  bool _isInitialLoading = false;
  bool get isInitialLoading => _isInitialLoading;

  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  ConversationListProvider(
    this._repository, {
    WebSocketProvider? websocketProvider,
  }) : _websocketProvider = websocketProvider {
    // 注册 WebSocket 新消息监听器，用于实时更新会话列表
    if (_websocketProvider != null) {
      _websocketProvider!.addNewMessageListener(handleNewMessage);
    }
  }

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
      debugPrint('服务器会话 ${conv.title}: type=${conv.type.value}, targetUserId=${conv.targetUserId}, convId=${conv.convId}');
    }

    // 保存到本地数据库
    for (final conv in conversations) {
      await ImDatabase.saveConversation(conv);
    }

    // 重新从数据库加载（保证数据一致性）
    _conversations = await ImDatabase.getConversations();
    
    // 调试：打印从数据库读取的会话信息
    for (final conv in _conversations) {
      debugPrint('数据库会话 ${conv.title}: type=${conv.type.value}, targetUserId=${conv.targetUserId}, convId=${conv.convId}');
    }
    
    notifyListeners();
  }
  
  /// 从服务器加载并返回原始会话列表（用于查找匹配）
  /// 获取更多会话以确保能找到匹配的会话
  Future<List<Conversation>> _loadFromServerAndReturn() async {
    // 获取更多会话（前3页，共60条），确保能找到匹配的会话
    final allConversations = <Conversation>[];
    for (int page = 1; page <= 3; page++) {
      final conversations = await _repository.getConversations(page: page, pageSize: 20);
      if (conversations.isEmpty) break; // 没有更多数据了
      allConversations.addAll(conversations);
      if (conversations.length < 20) break; // 最后一页
    }

    // 调试：打印从API获取的会话信息
    debugPrint('从服务器获取了 ${allConversations.length} 个会话');
    for (final conv in allConversations) {
      debugPrint('服务器会话 ${conv.title}: type=${conv.type.value}, targetUserId=${conv.targetUserId}, convId=${conv.convId}');
    }

    // 保存到本地数据库
    for (final conv in allConversations) {
      await ImDatabase.saveConversation(conv);
    }

    // 重新从数据库加载（保证数据一致性）
    _conversations = await ImDatabase.getConversations();
    
    // 调试：打印从数据库读取的会话信息
    for (final conv in _conversations) {
      debugPrint('数据库会话 ${conv.title}: type=${conv.type.value}, targetUserId=${conv.targetUserId}, convId=${conv.convId}');
    }
    
    notifyListeners();
    
    // 返回服务器原始数据（包含最新的targetUserId）
    return allConversations;
  }

  /// 处理新消息（更新会话列表）
  Future<void> handleNewMessage(ImMessage message) async {
    try {
      debugPrint('ConversationListProvider: 收到新消息 - convId: ${message.convId}, seq: ${message.seq}, type: ${message.msgType}');
      
      // 获取消息预览文本
      final preview = message.getPreviewText();
      
      // 获取消息内容（仅TEXT类型需要）
      String? messageContent;
      if (message.msgType == 'TEXT' && message.body is TextContent) {
        messageContent = (message.body as TextContent).text;
      }
      
      // 更新会话的最后消息
      await ImDatabase.updateConversationLastMessage(
        convId: message.convId,
        seq: message.seq,
        messageAt: message.createdAt,
        preview: preview,
        messageType: message.msgType,
        messageContent: messageContent,
      );

      // 增加未读数（如果消息不是自己发送的）
      // 注意：这里需要知道当前用户ID，但ConversationListProvider没有这个信息
      // 暂时先增加未读数，在聊天页面打开时会清除
      await ImDatabase.incrementUnreadCount(message.convId);

      // 重新加载会话列表（按最后消息时间排序）
      _conversations = await ImDatabase.getConversations();
      
      // 将收到新消息的会话移到最前面
      final index = _conversations.indexWhere((c) => c.convId == message.convId);
      if (index > 0) {
        final conv = _conversations.removeAt(index);
        _conversations.insert(0, conv);
      }
      
      notifyListeners();
      debugPrint('ConversationListProvider: 会话列表已更新');
    } catch (e) {
      debugPrint('ConversationListProvider: 处理新消息失败 - $e');
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
      debugPrint('=== 开始创建单聊会话: targetUserId=$targetUserId ===');
      
      // 1. 先检查本地数据库是否已有该用户的会话
      Conversation? existingConversation = await ImDatabase.findSingleConversation(targetUserId);
      
      if (existingConversation != null) {
        debugPrint('✓ 步骤1: 在本地数据库找到已存在的单聊会话: convId=${existingConversation.convId}, targetUserId=${existingConversation.targetUserId}');
        return existingConversation;
      }
      debugPrint('✗ 步骤1: 本地数据库未找到会话');
      
      // 2. 本地没有，从服务器获取最新的会话列表（返回服务器原始数据）
      debugPrint('步骤2: 从服务器获取最新的会话列表...');
      final serverConversations = await _loadFromServerAndReturn();
      
      // 3. 检查服务器返回的会话列表（优先使用服务器原始数据，包含最新的targetUserId）
      debugPrint('步骤3: 检查服务器返回的会话列表（共${serverConversations.length}个）...');
      for (final conv in serverConversations) {
        if (conv.type == ConversationType.single && conv.targetUserId == targetUserId) {
          debugPrint('✓ 步骤3: 在服务器会话列表中找到匹配的会话: convId=${conv.convId}, targetUserId=${conv.targetUserId}');
          // 确保保存到数据库（使用服务器返回的数据）
          await ImDatabase.saveConversation(conv);
          return conv;
        }
      }
      debugPrint('✗ 步骤3: 服务器会话列表中未找到匹配的会话');
      
      // 4. 再次检查本地数据库（可能服务器上有但本地还没同步）
      existingConversation = await ImDatabase.findSingleConversation(targetUserId);
      if (existingConversation != null) {
        debugPrint('✓ 步骤4: 刷新后在本地数据库找到会话: convId=${existingConversation.convId}');
        return existingConversation;
      }
      debugPrint('✗ 步骤4: 刷新后本地数据库仍未找到会话');
      
      // 5. 检查本地数据库中的会话列表（从数据库加载的）
      debugPrint('步骤5: 检查本地数据库会话列表（共${_conversations.length}个）...');
      for (final conv in _conversations) {
        if (conv.type == ConversationType.single && conv.targetUserId == targetUserId) {
          debugPrint('✓ 步骤5: 在本地数据库会话列表中找到匹配的会话: convId=${conv.convId}, targetUserId=${conv.targetUserId}');
          return conv;
        }
      }
      debugPrint('✗ 步骤5: 本地数据库会话列表中未找到匹配的会话');
      
      // 6. 调用API创建/获取会话（API端保证幂等性，如果已存在则返回现有会话）
      debugPrint('步骤6: 调用API创建/获取单聊会话: targetUserId=$targetUserId');
      final conversation = await _repository.createSingleConversation(targetUserId);
      debugPrint('API返回会话: convId=${conversation.convId}, targetUserId=${conversation.targetUserId}');
      
      // 7. 检查返回的会话是否已存在于本地数据库（通过 convId）
      final existingByConvId = await ImDatabase.getConversation(conversation.convId);
      if (existingByConvId != null) {
        debugPrint('✓ 步骤7: API返回的会话已存在于本地数据库: convId=${conversation.convId}');
        // 更新 targetUserId（如果之前没有或不同）
        if (existingByConvId.targetUserId != targetUserId) {
          final updatedConv = existingByConvId.copyWith(targetUserId: targetUserId);
          await ImDatabase.saveConversation(updatedConv);
          debugPrint('已更新会话的 targetUserId: ${existingByConvId.targetUserId} -> $targetUserId');
          return updatedConv;
        }
        return existingByConvId;
      }
      debugPrint('✗ 步骤7: API返回的会话不存在于本地数据库');
      
      // 8. 确保 targetUserId 被设置（API可能不返回）
      final conversationWithTargetId = conversation.targetUserId == null
          ? conversation.copyWith(targetUserId: targetUserId)
          : conversation;
      
      // 9. 保存到本地数据库
      debugPrint('步骤9: 保存新会话到本地数据库: convId=${conversationWithTargetId.convId}, targetUserId=${conversationWithTargetId.targetUserId}');
      await ImDatabase.saveConversation(conversationWithTargetId);
      
      // 10. 重新加载会话列表
      _conversations = await ImDatabase.getConversations();
      notifyListeners();
      
      debugPrint('=== 创建单聊会话完成: convId=${conversationWithTargetId.convId} ===');
      return conversationWithTargetId;
    } catch (e) {
      debugPrint('创建单聊会话失败: $e');
      rethrow;
    }
  }
  
  @override
  void dispose() {
    // 移除监听器，避免内存泄漏
    if (_websocketProvider != null) {
      _websocketProvider!.removeNewMessageListener(handleNewMessage);
    }
    super.dispose();
  }
}

