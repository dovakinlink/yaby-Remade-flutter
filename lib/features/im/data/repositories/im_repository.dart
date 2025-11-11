import 'package:yabai_app/core/network/api_client.dart';
import 'package:yabai_app/features/im/data/models/conversation_model.dart';
import 'package:yabai_app/features/im/data/models/im_message_model.dart';
import 'package:yabai_app/features/im/data/models/group_model.dart';
import 'package:yabai_app/features/im/data/models/group_member_model.dart';

/// IM Repository - 封装 REST API 调用
class ImRepository {
  final ApiClient _apiClient;

  ImRepository(this._apiClient);

  // ==================== 会话管理 API ====================

  /// 获取会话列表
  Future<List<Conversation>> getConversations({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/im/conversations',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );

      final data = response.data;
      if (data != null && data['success'] == true) {
        final list = data['data'] as List<dynamic>;
        return list.map((item) => Conversation.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        throw Exception(data?['message'] ?? '获取会话列表失败');
      }
    } catch (e) {
      throw Exception('获取会话列表失败: $e');
    }
  }

  /// 获取会话详情
  Future<Conversation> getConversation(String convId) async {
    try {
      final response = await _apiClient.get('/api/v1/im/conversations/$convId');

      final data = response.data;
      if (data != null && data['success'] == true) {
        return Conversation.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        throw Exception(data?['message'] ?? '获取会话详情失败');
      }
    } catch (e) {
      throw Exception('获取会话详情失败: $e');
    }
  }

  /// 获取未读消息总数
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.get('/api/v1/im/conversations/unread-count');

      final data = response.data;
      if (data != null && data['success'] == true) {
        return (data['data']['totalUnread'] as int?) ?? 0;
      } else {
        return 0; // 接口失败时返回0
      }
    } catch (e) {
      // 出错时返回0，避免影响用户体验
      return 0;
    }
  }

  /// 创建单聊会话
  Future<Conversation> createSingleConversation(int targetUserId) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/im/conversations/single',
        data: {
          'targetUserId': targetUserId,
        },
      );

      final data = response.data;
      if (data != null && data['success'] == true) {
        final conversation = Conversation.fromJson(data['data'] as Map<String, dynamic>);
        // API返回的数据可能没有targetUserId，我们需要手动添加
        return conversation.copyWith(targetUserId: targetUserId);
      } else {
        throw Exception(data?['message'] ?? '创建单聊会话失败');
      }
    } catch (e) {
      throw Exception('创建单聊会话失败: $e');
    }
  }

  /// 创建群聊会话
  Future<void> createGroupConversation({
    required String name,
    required List<int> memberUserIds,
    String? avatar,
    String? notice,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/im/conversations/group',
        data: {
          'name': name,
          'memberUserIds': memberUserIds,
          if (avatar != null) 'avatar': avatar,
          if (notice != null) 'notice': notice,
        },
      );

      final data = response.data;
      if (data == null || data['success'] != true) {
        throw Exception(data?['message'] ?? '创建群聊会话失败');
      }
    } catch (e) {
      throw Exception('创建群聊会话失败: $e');
    }
  }

  // ==================== 消息管理 API ====================

  /// 发送消息（备用 REST API，主要使用 WebSocket）
  Future<ImMessage> sendMessage({
    required String convId,
    required String msgType,
    required Map<String, dynamic> content,
    List<int>? mentions,
    bool? mentionAll,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/im/messages',
        data: {
          'convId': convId,
          'msgType': msgType,
          'content': content,
          if (mentions != null) 'mentions': mentions,
          if (mentionAll != null) 'mentionAll': mentionAll,
        },
      );

      final data = response.data;
      if (data != null && data['success'] == true) {
        return ImMessage.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        throw Exception(data?['message'] ?? '发送消息失败');
      }
    } catch (e) {
      throw Exception('发送消息失败: $e');
    }
  }

  /// 获取历史消息
  Future<List<ImMessage>> getHistoryMessages(
    String convId, {
    int? maxSeq,
    int limit = 50,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/im/messages/$convId/history',
        queryParameters: {
          if (maxSeq != null) 'maxSeq': maxSeq,
          'limit': limit,
        },
      );

      final data = response.data;
      if (data != null && data['success'] == true) {
        final list = data['data'] as List<dynamic>;
        return list.map((item) => ImMessage.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        throw Exception(data?['message'] ?? '获取历史消息失败');
      }
    } catch (e) {
      throw Exception('获取历史消息失败: $e');
    }
  }

  /// 撤回消息
  Future<void> revokeMessage(int messageId) async {
    try {
      final response = await _apiClient.delete('/api/v1/im/messages/$messageId');

      final data = response.data;
      if (data == null || data['success'] != true) {
        throw Exception(data?['message'] ?? '撤回消息失败');
      }
    } catch (e) {
      throw Exception('撤回消息失败: $e');
    }
  }

  /// 更新已读位置
  Future<void> updateReadPosition(String convId, int seq) async {
    try {
      final response = await _apiClient.put(
        '/api/v1/im/messages/$convId/read',
        data: {
          'convId': convId,
          'seq': seq,
        },
      );

      final data = response.data;
      if (data == null || data['success'] != true) {
        throw Exception(data?['message'] ?? '更新已读位置失败');
      }
    } catch (e) {
      throw Exception('更新已读位置失败: $e');
    }
  }

  // ==================== 群组管理 API ====================

  /// 获取群组详情
  Future<Group> getGroup(String convId) async {
    try {
      final response = await _apiClient.get('/api/v1/im/groups/$convId');

      final data = response.data;
      if (data != null && data['success'] == true) {
        return Group.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        throw Exception(data?['message'] ?? '获取群组详情失败');
      }
    } catch (e) {
      throw Exception('获取群组详情失败: $e');
    }
  }

  /// 更新群信息
  Future<void> updateGroup(
    String convId, {
    String? name,
    String? avatar,
    String? notice,
  }) async {
    try {
      final response = await _apiClient.put(
        '/api/v1/im/groups/$convId',
        data: {
          if (name != null) 'name': name,
          if (avatar != null) 'avatar': avatar,
          if (notice != null) 'notice': notice,
        },
      );

      final data = response.data;
      if (data == null || data['success'] != true) {
        throw Exception(data?['message'] ?? '更新群信息失败');
      }
    } catch (e) {
      throw Exception('更新群信息失败: $e');
    }
  }

  /// 添加群成员
  Future<void> addGroupMembers(String convId, List<int> userIds) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/im/groups/$convId/members',
        data: {
          'userIds': userIds,
        },
      );

      final data = response.data;
      if (data == null || data['success'] != true) {
        throw Exception(data?['message'] ?? '添加群成员失败');
      }
    } catch (e) {
      throw Exception('添加群成员失败: $e');
    }
  }

  /// 移除群成员
  Future<void> removeGroupMember(String convId, int userId) async {
    try {
      final response = await _apiClient.delete('/api/v1/im/groups/$convId/members/$userId');

      final data = response.data;
      if (data == null || data['success'] != true) {
        throw Exception(data?['message'] ?? '移除群成员失败');
      }
    } catch (e) {
      throw Exception('移除群成员失败: $e');
    }
  }

  /// 退出群聊
  Future<void> quitGroup(String convId) async {
    try {
      final response = await _apiClient.post('/api/v1/im/groups/$convId/quit');

      final data = response.data;
      if (data == null || data['success'] != true) {
        throw Exception(data?['message'] ?? '退出群聊失败');
      }
    } catch (e) {
      throw Exception('退出群聊失败: $e');
    }
  }

  /// 转让群主
  Future<void> transferGroup(String convId, int newOwnerId) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/im/groups/$convId/transfer',
        data: {
          'newOwnerId': newOwnerId,
        },
      );

      final data = response.data;
      if (data == null || data['success'] != true) {
        throw Exception(data?['message'] ?? '转让群主失败');
      }
    } catch (e) {
      throw Exception('转让群主失败: $e');
    }
  }

  /// 获取群成员列表
  Future<List<GroupMember>> getGroupMembers(String convId) async {
    try {
      final response = await _apiClient.get('/api/v1/im/groups/$convId/members');

      final data = response.data;
      if (data != null && data['success'] == true) {
        final list = data['data'] as List<dynamic>;
        return list.map((item) => GroupMember.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        throw Exception(data?['message'] ?? '获取群成员列表失败');
      }
    } catch (e) {
      throw Exception('获取群成员列表失败: $e');
    }
  }

  // ==================== 设备管理 API ====================

  /// 注册设备
  Future<void> registerDevice({
    required String platform,
    required String deviceId,
    String? pushToken,
    String? appBundle,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/im/devices',
        data: {
          'platform': platform,
          'deviceId': deviceId,
          if (pushToken != null) 'pushToken': pushToken,
          if (appBundle != null) 'appBundle': appBundle,
        },
      );

      final data = response.data;
      if (data == null || data['success'] != true) {
        throw Exception(data?['message'] ?? '注册设备失败');
      }
    } catch (e) {
      throw Exception('注册设备失败: $e');
    }
  }
}

