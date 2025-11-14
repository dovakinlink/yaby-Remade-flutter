import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:yabai_app/features/im/data/models/conversation_model.dart';
import 'package:yabai_app/features/im/data/models/im_message_model.dart';
import 'package:yabai_app/features/im/data/models/message_content.dart';

/// IM 本地数据库管理
class ImDatabase {
  static Database? _database;
  static const String _dbName = 'im_database.db';
  static const int _dbVersion = 3; // 版本3：添加 last_message_content 和 last_message_type 字段

  /// 获取数据库实例
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 创建表
  static Future<void> _onCreate(Database db, int version) async {
    // 会话表
    await db.execute('''
      CREATE TABLE conversations (
        conv_id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        title TEXT,
        avatar TEXT,
        last_message_seq INTEGER NOT NULL DEFAULT 0,
        last_message_at TEXT,
        last_message_preview TEXT,
        last_message_content TEXT,
        last_message_type TEXT,
        unread_count INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        target_user_id INTEGER
      )
    ''');

    // 消息表
    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY,
        conv_id TEXT NOT NULL,
        seq INTEGER NOT NULL,
        sender_user_id INTEGER NOT NULL,
        sender_name TEXT,
        sender_avatar TEXT,
        msg_type TEXT NOT NULL,
        body TEXT NOT NULL,
        mentions TEXT,
        is_revoked INTEGER NOT NULL DEFAULT 0,
        revoke_at TEXT,
        created_at TEXT NOT NULL,
        client_msg_id TEXT,
        local_status TEXT,
        UNIQUE(conv_id, seq)
      )
    ''');

    // 已读位置表
    await db.execute('''
      CREATE TABLE read_positions (
        conv_id TEXT PRIMARY KEY,
        seq INTEGER NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 创建索引
    await db.execute('CREATE INDEX idx_messages_conv_id ON messages(conv_id)');
    await db.execute('CREATE INDEX idx_messages_seq ON messages(seq)');
    await db.execute('CREATE INDEX idx_messages_created_at ON messages(created_at)');
    await db.execute('CREATE INDEX idx_conversations_last_message_at ON conversations(last_message_at)');
  }

  /// 升级数据库
  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 版本1到版本2：添加 target_user_id 字段
      await db.execute('ALTER TABLE conversations ADD COLUMN target_user_id INTEGER');
    }
    if (oldVersion < 3) {
      // 版本2到版本3：添加 last_message_content 和 last_message_type 字段
      await db.execute('ALTER TABLE conversations ADD COLUMN last_message_content TEXT');
      await db.execute('ALTER TABLE conversations ADD COLUMN last_message_type TEXT');
    }
  }

  /// 关闭数据库
  static Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  // ==================== 会话相关操作 ====================

  /// 保存或更新会话
  static Future<void> saveConversation(Conversation conversation) async {
    final db = await database;
    await db.insert(
      'conversations',
      {
        'conv_id': conversation.convId,
        'type': conversation.type.value,
        'title': conversation.title,
        'avatar': conversation.avatar,
        'last_message_seq': conversation.lastMessageSeq,
        'last_message_at': conversation.lastMessageAt?.toIso8601String(),
        'last_message_preview': conversation.lastMessagePreview,
        'last_message_content': conversation.lastMessageContent,
        'last_message_type': conversation.lastMessageType,
        'unread_count': conversation.unreadCount,
        'created_at': conversation.createdAt.toIso8601String(),
        'target_user_id': conversation.targetUserId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 获取所有会话
  static Future<List<Conversation>> getConversations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'conversations',
      orderBy: 'last_message_at DESC',
    );

    return maps.map((map) {
      return Conversation(
        convId: map['conv_id'] as String,
        type: ConversationType.fromString(map['type'] as String),
        title: map['title'] as String?,
        avatar: map['avatar'] as String?,
        lastMessageSeq: map['last_message_seq'] as int,
        lastMessageAt: map['last_message_at'] != null
            ? DateTime.parse(map['last_message_at'] as String)
            : null,
        lastMessagePreview: map['last_message_preview'] as String?,
        lastMessageContent: map['last_message_content'] as String?,
        lastMessageType: map['last_message_type'] as String?,
        unreadCount: map['unread_count'] as int,
        createdAt: DateTime.parse(map['created_at'] as String),
        targetUserId: map['target_user_id'] as int?,
      );
    }).toList();
  }

  /// 获取单个会话
  static Future<Conversation?> getConversation(String convId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'conversations',
      where: 'conv_id = ?',
      whereArgs: [convId],
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    return Conversation(
      convId: map['conv_id'] as String,
      type: ConversationType.fromString(map['type'] as String),
      title: map['title'] as String?,
      avatar: map['avatar'] as String?,
      lastMessageSeq: map['last_message_seq'] as int,
      lastMessageAt: map['last_message_at'] != null
          ? DateTime.parse(map['last_message_at'] as String)
          : null,
      lastMessagePreview: map['last_message_preview'] as String?,
      unreadCount: map['unread_count'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      targetUserId: map['target_user_id'] as int?,
    );
  }

  /// 根据对方用户ID查找单聊会话
  static Future<Conversation?> findSingleConversation(int targetUserId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'conversations',
      where: 'type = ? AND target_user_id = ?',
      whereArgs: ['SINGLE', targetUserId],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    return Conversation(
      convId: map['conv_id'] as String,
      type: ConversationType.fromString(map['type'] as String),
      title: map['title'] as String?,
      avatar: map['avatar'] as String?,
      lastMessageSeq: map['last_message_seq'] as int,
      lastMessageAt: map['last_message_at'] != null
          ? DateTime.parse(map['last_message_at'] as String)
          : null,
      lastMessagePreview: map['last_message_preview'] as String?,
      unreadCount: map['unread_count'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      targetUserId: map['target_user_id'] as int?,
    );
  }

  /// 更新会话的最后消息
  static Future<void> updateConversationLastMessage({
    required String convId,
    required int seq,
    required DateTime messageAt,
    required String preview,
    String? messageType,
    String? messageContent,
  }) async {
    final db = await database;
    final updateData = <String, dynamic>{
      'last_message_seq': seq,
      'last_message_at': messageAt.toIso8601String(),
      'last_message_preview': preview,
    };
    
    if (messageType != null) {
      updateData['last_message_type'] = messageType;
    }
    
    if (messageContent != null) {
      updateData['last_message_content'] = messageContent;
    }
    
    await db.update(
      'conversations',
      updateData,
      where: 'conv_id = ?',
      whereArgs: [convId],
    );
  }

  /// 增加会话未读数
  static Future<void> incrementUnreadCount(String convId) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE conversations SET unread_count = unread_count + 1 WHERE conv_id = ?',
      [convId],
    );
  }

  /// 清除会话未读数
  static Future<void> clearUnreadCount(String convId) async {
    final db = await database;
    await db.update(
      'conversations',
      {'unread_count': 0},
      where: 'conv_id = ?',
      whereArgs: [convId],
    );
  }

  /// 删除会话
  static Future<void> deleteConversation(String convId) async {
    final db = await database;
    await db.delete(
      'conversations',
      where: 'conv_id = ?',
      whereArgs: [convId],
    );
  }

  // ==================== 消息相关操作 ====================

  /// 保存消息
  static Future<void> saveMessage(ImMessage message) async {
    final db = await database;
    await db.insert(
      'messages',
      {
        'id': message.id,
        'conv_id': message.convId,
        'seq': message.seq,
        'sender_user_id': message.senderUserId,
        'sender_name': message.senderName,
        'sender_avatar': message.senderAvatar,
        'msg_type': message.msgType,
        'body': jsonEncode(message.body.toJson()),
        'mentions': message.mentions != null ? jsonEncode(message.mentions) : null,
        'is_revoked': message.isRevoked ? 1 : 0,
        'revoke_at': message.revokeAt?.toIso8601String(),
        'created_at': message.createdAt.toIso8601String(),
        'client_msg_id': message.clientMsgId,
        'local_status': message.localStatus?.value,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 批量保存消息
  static Future<void> saveMessages(List<ImMessage> messages) async {
    final db = await database;
    final batch = db.batch();
    
    for (final message in messages) {
      batch.insert(
        'messages',
        {
          'id': message.id,
          'conv_id': message.convId,
          'seq': message.seq,
          'sender_user_id': message.senderUserId,
          'sender_name': message.senderName,
          'sender_avatar': message.senderAvatar,
          'msg_type': message.msgType,
          'body': jsonEncode(message.body.toJson()),
          'mentions': message.mentions != null ? jsonEncode(message.mentions) : null,
          'is_revoked': message.isRevoked ? 1 : 0,
          'revoke_at': message.revokeAt?.toIso8601String(),
          'created_at': message.createdAt.toIso8601String(),
          'client_msg_id': message.clientMsgId,
          'local_status': message.localStatus?.value,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  /// 获取会话的消息列表
  static Future<List<ImMessage>> getMessages(
    String convId, {
    int? maxSeq,
    int limit = 50,
  }) async {
    final db = await database;
    
    String where = 'conv_id = ?';
    List<dynamic> whereArgs = [convId];
    
    if (maxSeq != null) {
      where += ' AND seq < ?';
      whereArgs.add(maxSeq);
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'seq DESC',
      limit: limit,
    );

    return maps.map((map) => _messageFromMap(map)).toList();
  }

  /// 获取会话的最大 seq
  static Future<int> getMaxSeq(String convId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT MAX(seq) as max_seq FROM messages WHERE conv_id = ?',
      [convId],
    );
    
    if (result.isEmpty || result.first['max_seq'] == null) {
      return 0;
    }
    
    return result.first['max_seq'] as int;
  }

  /// 根据客户端消息 ID 查找消息
  static Future<ImMessage?> getMessageByClientId(String clientMsgId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'client_msg_id = ?',
      whereArgs: [clientMsgId],
    );

    if (maps.isEmpty) return null;
    return _messageFromMap(maps.first);
  }

  /// 更新消息状态
  static Future<void> updateMessageStatus(
    String clientMsgId,
    MessageStatus status, {
    int? messageId,
    int? seq,
  }) async {
    final db = await database;
    final Map<String, dynamic> updates = {
      'local_status': status.value,
    };
    
    if (messageId != null) updates['id'] = messageId;
    if (seq != null) updates['seq'] = seq;
    
    await db.update(
      'messages',
      updates,
      where: 'client_msg_id = ?',
      whereArgs: [clientMsgId],
    );
  }

  /// 从 Map 转换为 ImMessage
  static ImMessage _messageFromMap(Map<String, dynamic> map) {
    final bodyJson = jsonDecode(map['body'] as String) as Map<String, dynamic>;
    final msgType = map['msg_type'] as String;
    
    return ImMessage(
      id: map['id'] as int,
      convId: map['conv_id'] as String,
      seq: map['seq'] as int,
      senderUserId: map['sender_user_id'] as int,
      senderName: map['sender_name'] as String?,
      senderAvatar: map['sender_avatar'] as String?,
      msgType: msgType,
      body: _parseMessageContent(msgType, bodyJson),
      mentions: map['mentions'] != null
          ? (jsonDecode(map['mentions'] as String) as List<dynamic>)
              .map((e) => e as int)
              .toList()
          : null,
      isRevoked: (map['is_revoked'] as int) == 1,
      revokeAt: map['revoke_at'] != null
          ? DateTime.parse(map['revoke_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      clientMsgId: map['client_msg_id'] as String?,
      localStatus: map['local_status'] != null
          ? MessageStatus.fromString(map['local_status'] as String)
          : null,
    );
  }

  /// 解析消息内容
  static MessageContent _parseMessageContent(String msgType, Map<String, dynamic> json) {
    return MessageContent.fromJson(msgType, json);
  }

  // ==================== 已读位置相关操作 ====================

  /// 保存已读位置
  static Future<void> saveReadPosition(String convId, int seq) async {
    final db = await database;
    await db.insert(
      'read_positions',
      {
        'conv_id': convId,
        'seq': seq,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 获取已读位置
  static Future<int> getReadPosition(String convId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'read_positions',
      where: 'conv_id = ?',
      whereArgs: [convId],
    );

    if (maps.isEmpty) return 0;
    return maps.first['seq'] as int;
  }

  // ==================== 数据清理操作 ====================

  /// 清空所有 IM 数据（用户登出时调用）
  static Future<void> clearAllData() async {
    debugPrint('清空所有 IM 本地数据');
    final db = await database;
    
    // 清空所有表
    await db.delete('conversations');
    await db.delete('messages');
    await db.delete('read_positions');
    
    debugPrint('IM 本地数据已清空');
  }
}

