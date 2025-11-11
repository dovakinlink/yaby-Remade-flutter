import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:yabai_app/features/im/data/repositories/im_repository.dart';
import 'package:yabai_app/features/im/data/local/im_database.dart';
import 'package:yabai_app/features/im/data/models/im_message_model.dart';
import 'package:yabai_app/features/im/data/models/conversation_model.dart';
import 'package:yabai_app/features/im/data/models/ws_message.dart';
import 'package:yabai_app/features/im/data/models/message_content.dart';
import 'package:yabai_app/features/im/providers/websocket_provider.dart';

/// 聊天页面状态管理
class ChatProvider extends ChangeNotifier {
  final ImRepository _repository;
  final WebSocketProvider _websocketProvider;
  final String convId;
  final int currentUserId;

  List<ImMessage> _messages = [];
  List<ImMessage> get messages => _messages;

  Conversation? _conversation;
  Conversation? get conversation => _conversation;

  bool _isInitialLoading = false;
  bool get isInitialLoading => _isInitialLoading;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  final _uuid = const Uuid();

  ChatProvider({
    required ImRepository repository,
    required WebSocketProvider websocketProvider,
    required this.convId,
    required this.currentUserId,
  })  : _repository = repository,
        _websocketProvider = websocketProvider;

  /// 初次加载
  Future<void> loadInitial() async {
    if (_isInitialLoading) return;

    _isInitialLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 加载会话信息
      _conversation = await ImDatabase.getConversation(convId);
      if (_conversation == null) {
        _conversation = await _repository.getConversation(convId);
        await ImDatabase.saveConversation(_conversation!);
      }

      // 加载本地消息
      _messages = await ImDatabase.getMessages(convId, limit: 50);
      _messages = _messages.reversed.toList(); // 反转为正序（旧 -> 新）
      notifyListeners();

      // 如果本地消息较少，从服务器加载更多
      if (_messages.length < 20) {
        await _loadHistoryFromServer();
      }

      // 标记为已读
      await _markAsRead();
    } catch (e) {
      debugPrint('聊天页面加载失败: $e');
      _errorMessage = e.toString();
    } finally {
      _isInitialLoading = false;
      notifyListeners();
    }
  }

  /// 加载更多历史消息
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _messages.isEmpty) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final oldestSeq = _messages.first.seq;
      await _loadHistoryFromServer(maxSeq: oldestSeq);
    } catch (e) {
      debugPrint('加载更多消息失败: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// 从服务器加载历史消息
  Future<void> _loadHistoryFromServer({int? maxSeq}) async {
    final historyMessages = await _repository.getHistoryMessages(
      convId,
      maxSeq: maxSeq,
      limit: 50,
    );

    if (historyMessages.isEmpty) {
      _hasMore = false;
      return;
    }

    // 保存到本地数据库
    await ImDatabase.saveMessages(historyMessages);

    // 重新从数据库加载
    _messages = await ImDatabase.getMessages(convId, limit: _messages.length + historyMessages.length);
    _messages = _messages.reversed.toList();
    notifyListeners();
  }

  /// 发送文本消息
  Future<void> sendTextMessage(String text) async {
    final clientMsgId = _uuid.v4();
    
    // 创建本地消息
    final localMessage = ImMessage(
      id: 0, // 临时 ID
      convId: convId,
      seq: 0, // 临时 seq
      senderUserId: currentUserId,
      msgType: 'TEXT',
      body: TextContent(text: text),
      isRevoked: false,
      createdAt: DateTime.now(),
      clientMsgId: clientMsgId,
      localStatus: MessageStatus.sending,
    );

    // 添加到消息列表
    _messages.add(localMessage);
    notifyListeners();

    // 保存到本地数据库
    await ImDatabase.saveMessage(localMessage);

    try {
      // 通过 WebSocket 发送
      final wsMessage = WsMessage.createSendMessage(
        msgId: clientMsgId,
        convId: convId,
        msgType: 'TEXT',
        content: {'text': text},
      );

      final ack = await _websocketProvider.sendMessageAndWaitAck(wsMessage);

      if (ack.success) {
        // 发送成功，更新消息状态
        await ImDatabase.updateMessageStatus(
          clientMsgId,
          MessageStatus.sent,
          messageId: ack.messageId,
          seq: ack.seq,
        );

        // 重新加载消息列表
        await _reloadMessages();
      } else {
        // 发送失败
        await ImDatabase.updateMessageStatus(clientMsgId, MessageStatus.failed);
        await _reloadMessages();
      }
    } catch (e) {
      debugPrint('发送消息失败: $e');
      // 标记为失败
      await ImDatabase.updateMessageStatus(clientMsgId, MessageStatus.failed);
      await _reloadMessages();
    }
  }

  /// 发送图片消息
  Future<void> sendImageMessage({
    required int fileId,
    required String url,
    int? width,
    int? height,
    int? size,
  }) async {
    final clientMsgId = _uuid.v4();

    // 创建本地消息
    final localMessage = ImMessage(
      id: 0,
      convId: convId,
      seq: 0,
      senderUserId: currentUserId,
      msgType: 'IMAGE',
      body: ImageContent(
        fileId: fileId,
        url: url,
        width: width,
        height: height,
        size: size,
      ),
      isRevoked: false,
      createdAt: DateTime.now(),
      clientMsgId: clientMsgId,
      localStatus: MessageStatus.sending,
    );

    _messages.add(localMessage);
    notifyListeners();
    await ImDatabase.saveMessage(localMessage);

    try {
      final wsMessage = WsMessage.createSendMessage(
        msgId: clientMsgId,
        convId: convId,
        msgType: 'IMAGE',
        content: {
          'fileId': fileId,
          'url': url,
          if (width != null) 'width': width,
          if (height != null) 'height': height,
          if (size != null) 'size': size,
        },
      );

      final ack = await _websocketProvider.sendMessageAndWaitAck(wsMessage);

      if (ack.success) {
        await ImDatabase.updateMessageStatus(
          clientMsgId,
          MessageStatus.sent,
          messageId: ack.messageId,
          seq: ack.seq,
        );
        await _reloadMessages();
      } else {
        await ImDatabase.updateMessageStatus(clientMsgId, MessageStatus.failed);
        await _reloadMessages();
      }
    } catch (e) {
      debugPrint('发送图片消息失败: $e');
      await ImDatabase.updateMessageStatus(clientMsgId, MessageStatus.failed);
      await _reloadMessages();
    }
  }

  /// 发送文件消息
  Future<void> sendFileMessage({
    required int fileId,
    required String url,
    required String filename,
    int? size,
  }) async {
    final clientMsgId = _uuid.v4();

    final localMessage = ImMessage(
      id: 0,
      convId: convId,
      seq: 0,
      senderUserId: currentUserId,
      msgType: 'FILE',
      body: FileContent(
        fileId: fileId,
        url: url,
        filename: filename,
        size: size,
      ),
      isRevoked: false,
      createdAt: DateTime.now(),
      clientMsgId: clientMsgId,
      localStatus: MessageStatus.sending,
    );

    _messages.add(localMessage);
    notifyListeners();
    await ImDatabase.saveMessage(localMessage);

    try {
      final wsMessage = WsMessage.createSendMessage(
        msgId: clientMsgId,
        convId: convId,
        msgType: 'FILE',
        content: {
          'fileId': fileId,
          'url': url,
          'filename': filename,
          if (size != null) 'size': size,
        },
      );

      final ack = await _websocketProvider.sendMessageAndWaitAck(wsMessage);

      if (ack.success) {
        await ImDatabase.updateMessageStatus(
          clientMsgId,
          MessageStatus.sent,
          messageId: ack.messageId,
          seq: ack.seq,
        );
        await _reloadMessages();
      } else {
        await ImDatabase.updateMessageStatus(clientMsgId, MessageStatus.failed);
        await _reloadMessages();
      }
    } catch (e) {
      debugPrint('发送文件消息失败: $e');
      await ImDatabase.updateMessageStatus(clientMsgId, MessageStatus.failed);
      await _reloadMessages();
    }
  }

  /// 重新加载消息列表
  Future<void> _reloadMessages() async {
    _messages = await ImDatabase.getMessages(convId, limit: _messages.length);
    _messages = _messages.reversed.toList();
    notifyListeners();
  }

  /// 标记为已读
  Future<void> _markAsRead() async {
    if (_messages.isEmpty) return;

    final lastSeq = _messages.last.seq;
    if (lastSeq == 0) return;

    try {
      // 更新本地已读位置
      await ImDatabase.saveReadPosition(convId, lastSeq);

      // 清除未读数
      await ImDatabase.clearUnreadCount(convId);

      // 通过 WebSocket 发送已读确认
      final readAck = WsMessage.createReadAck(
        msgId: _uuid.v4(),
        convId: convId,
        seq: lastSeq,
      );
      await _websocketProvider.sendMessage(readAck);
    } catch (e) {
      debugPrint('标记已读失败: $e');
    }
  }

  /// 处理接收到的新消息
  void handleNewMessage(ImMessage message) {
    if (message.convId != convId) return;

    _messages.add(message);
    notifyListeners();

    // 自动标记为已读
    _markAsRead();
  }
}

