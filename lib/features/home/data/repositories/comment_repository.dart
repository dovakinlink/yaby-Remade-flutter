import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:yabai_app/core/network/api_client.dart';
import 'package:yabai_app/core/network/api_exception.dart';
import 'package:yabai_app/core/network/models/api_response.dart';
import 'package:yabai_app/features/profile/data/models/page_response.dart';
import 'package:yabai_app/features/home/data/models/comment_model.dart';

class CommentRepository {
  final ApiClient _apiClient;

  CommentRepository(this._apiClient);

  /// 获取评论列表
  Future<PageResponse<Comment>> getCommentList({
    required int noticeId,
    int page = 1,
    int size = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/notices/$noticeId/comments',
        queryParameters: {
          'page': page,
          'size': size,
        },
      );

      final body = response.data;
      if (body == null) {
        throw ApiException(message: '服务器未返回数据');
      }

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        body,
        dataParser: (rawData) {
          if (rawData is Map<String, dynamic>) {
            return rawData;
          }
          return <String, dynamic>{};
        },
      );

      if (!apiResponse.success) {
        throw ApiException(
          message: apiResponse.message,
          code: apiResponse.code,
        );
      }

      final data = apiResponse.data;
      if (data == null || data.isEmpty) {
        return PageResponse<Comment>.empty();
      }

      return PageResponse.fromJson(
        data,
        (json) => Comment.fromJson(json),
      );
    } on DioException catch (error) {
      final dynamic responseBody = error.response?.data;
      String? code;
      String message = '网络请求失败';
      if (responseBody is Map<String, dynamic>) {
        code = responseBody['code'] as String?;
        message = responseBody['message'] as String? ?? message;
      } else if (error.message != null) {
        message = error.message!;
      }
      throw ApiException(message: message, code: code);
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(message: '评论数据解析失败: $error');
    }
  }

  /// 创建评论或回复评论
  Future<Comment> createComment({
    required int noticeId,
    required String content,
    int? replyToCommentId,
  }) async {
    try {
      final requestData = <String, dynamic>{
        'content': content,
      };
      
      if (replyToCommentId != null) {
        requestData['replyToCommentId'] = replyToCommentId;
      }

      debugPrint('创建评论请求: noticeId=$noticeId, replyToCommentId=$replyToCommentId');

      final response = await _apiClient.post(
        '/api/v1/notices/$noticeId/comments',
        data: requestData,
      );

      final body = response.data;
      if (body == null) {
        debugPrint('创建评论失败: 服务器未返回数据');
        throw ApiException(message: '服务器未返回数据');
      }

      debugPrint('创建评论响应: ${body.toString().substring(0, body.toString().length > 200 ? 200 : body.toString().length)}');

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        body,
        dataParser: (rawData) {
          if (rawData is Map<String, dynamic>) {
            return rawData;
          }
          return <String, dynamic>{};
        },
      );

      if (!apiResponse.success) {
        debugPrint('创建评论失败: ${apiResponse.message}');
        throw ApiException(
          message: apiResponse.message,
          code: apiResponse.code,
        );
      }

      final data = apiResponse.data;
      if (data == null) {
        debugPrint('创建评论失败: 评论数据为null');
        throw ApiException(message: '服务器未返回评论数据');
      }

      debugPrint('创建评论成功，解析数据: ${data.toString()}');
      
      // 尝试解析评论数据
      try {
        return Comment.fromJson(data);
      } catch (parseError) {
        debugPrint('警告：评论创建成功但数据解析失败: $parseError');
        // 虽然解析失败，但评论已经创建成功，抛出特殊异常说明情况
        throw ApiException(
          message: '评论已成功发表',
          code: 'PARSE_ERROR_BUT_SUCCESS',
        );
      }
    } on DioException catch (error) {
      debugPrint('创建评论网络错误: ${error.message}');
      final dynamic responseBody = error.response?.data;
      String? code;
      String message = '网络请求失败';
      if (responseBody is Map<String, dynamic>) {
        code = responseBody['code'] as String?;
        message = responseBody['message'] as String? ?? message;
      } else if (error.message != null) {
        message = error.message!;
      }
      throw ApiException(message: message, code: code);
    } on ApiException {
      rethrow;
    } catch (error) {
      debugPrint('创建评论未知错误: $error');
      throw ApiException(message: '创建评论失败: $error');
    }
  }

  /// 删除评论
  Future<void> deleteComment(int commentId) async {
    try {
      final response = await _apiClient.delete(
        '/api/v1/comments/$commentId',
      );

      final body = response.data;
      if (body == null) {
        throw ApiException(message: '服务器未返回数据');
      }

      final apiResponse = ApiResponse<dynamic>.fromJson(
        body,
        dataParser: (rawData) => rawData,
      );

      if (!apiResponse.success) {
        throw ApiException(
          message: apiResponse.message,
          code: apiResponse.code,
        );
      }
    } on DioException catch (error) {
      final dynamic responseBody = error.response?.data;
      String? code;
      String message = '网络请求失败';
      if (responseBody is Map<String, dynamic>) {
        code = responseBody['code'] as String?;
        message = responseBody['message'] as String? ?? message;
      } else if (error.message != null) {
        message = error.message!;
      }
      throw ApiException(message: message, code: code);
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(message: '删除评论失败: $error');
    }
  }
}

