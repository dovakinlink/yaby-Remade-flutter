import 'package:yabai_app/core/network/api_client.dart';
import 'package:yabai_app/features/messages/data/models/message_model.dart';
import 'package:yabai_app/features/messages/data/models/message_list_response.dart';

/// 消息仓库，封装消息相关的API调用
class MessageRepository {
  final ApiClient _apiClient;

  MessageRepository(this._apiClient);

  /// 获取未读消息数量
  /// 对应API: GET /api/v1/messages/unread-count
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.get('/api/v1/messages/unread-count');
      
      final data = response.data;
      if (data != null && data['success'] == true) {
        return data['data'] as int? ?? 0;
      } else {
        throw Exception(data?['message'] ?? '获取未读消息数量失败');
      }
    } catch (e) {
      throw Exception('获取未读消息数量失败: $e');
    }
  }

  /// 获取未读消息列表（分页）
  /// 对应API: GET /api/v1/messages/unread
  Future<MessageListResponse> getUnreadMessages({
    int page = 1,
    int size = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/messages/unread',
        queryParameters: {
          'page': page,
          'size': size,
        },
      );
      
      final data = response.data;
      if (data != null && data['success'] == true) {
        return MessageListResponse.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        throw Exception(data?['message'] ?? '获取消息列表失败');
      }
    } catch (e) {
      throw Exception('获取消息列表失败: $e');
    }
  }

  /// 获取消息详情（自动标记为已读）
  /// 对应API: GET /api/v1/messages/{id}
  Future<Message> getMessageDetail(int messageId) async {
    try {
      final response = await _apiClient.get('/api/v1/messages/$messageId');
      
      final data = response.data;
      if (data != null && data['success'] == true) {
        return Message.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        final code = data?['code'] as String?;
        final message = data?['message'] as String?;
        
        // 处理特定的错误情况
        if (code == 'MESSAGE_NOT_FOUND') {
          throw MessageNotFoundException(message ?? '消息不存在');
        } else if (code == 'MESSAGE_ACCESS_DENIED') {
          throw MessageAccessDeniedException(message ?? '无权访问该消息');
        } else if (code == 'UNAUTHORIZED') {
          throw UnauthorizedException(message ?? '请先登录');
        } else {
          throw Exception(message ?? '获取消息详情失败');
        }
      }
    } catch (e) {
      if (e is MessageException) {
        rethrow;
      }
      throw Exception('获取消息详情失败: $e');
    }
  }
}

/// 消息相关异常基类
abstract class MessageException implements Exception {
  final String message;
  const MessageException(this.message);
  
  @override
  String toString() => message;
}

/// 消息不存在异常
class MessageNotFoundException extends MessageException {
  const MessageNotFoundException(super.message);
}

/// 消息访问被拒绝异常
class MessageAccessDeniedException extends MessageException {
  const MessageAccessDeniedException(super.message);
}

/// 未授权异常
class UnauthorizedException extends MessageException {
  const UnauthorizedException(super.message);
}
