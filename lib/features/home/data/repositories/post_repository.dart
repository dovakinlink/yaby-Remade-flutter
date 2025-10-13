import 'package:dio/dio.dart';
import 'package:yabai_app/core/network/api_client.dart';
import 'package:yabai_app/core/network/api_exception.dart';
import 'package:yabai_app/features/home/data/models/announcement_model.dart';
import 'package:yabai_app/features/home/data/models/post_tag_model.dart';

class PostRepository {
  final ApiClient _apiClient;

  PostRepository(this._apiClient);

  /// 获取可用的帖子标签列表
  Future<List<PostTagModel>> getAvailableTags({int? hospitalId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (hospitalId != null) {
        queryParams['hospital-id'] = hospitalId.toString();
      }

      final response = await _apiClient.get(
        '/api/v1/posts/tags',
        queryParameters: queryParams,
      );

      final responseData = response.data as Map<String, dynamic>;
      
      if (responseData['success'] == true && responseData['data'] != null) {
        final List<dynamic> dataList = responseData['data'] as List<dynamic>;
        return dataList
            .map((json) => PostTagModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw ApiException(
        message: responseData['message'] as String? ?? '获取标签列表失败',
        code: responseData['code'] as String?,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw ApiException(
          message: '网络连接超时，请检查网络设置',
          code: 'TIMEOUT',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw ApiException(
          message: '无法连接到服务器，请确保后端服务已启动',
          code: 'CONNECTION_ERROR',
        );
      } else if (e.response?.statusCode == 401) {
        throw ApiException(
          message: '请先登录',
          code: 'UNAUTHORIZED',
        );
      } else if (e.response?.statusCode == 403) {
        throw ApiException(
          message: '没有权限访问',
          code: 'FORBIDDEN',
        );
      }
      throw ApiException(
        message: '获取标签列表失败: ${e.message ?? "未知错误"}',
        code: 'NETWORK_ERROR',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: '获取标签列表失败: ${e.toString()}',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// 创建用户帖子
  Future<AnnouncementModel> createPost(CreatePostRequest request) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/posts',
        data: request.toJson(),
      );

      final responseData = response.data as Map<String, dynamic>;
      
      if (responseData['success'] == true && responseData['data'] != null) {
        return AnnouncementModel.fromJson(
          responseData['data'] as Map<String, dynamic>,
        );
      }

      throw ApiException(
        message: responseData['message'] as String? ?? '发布帖子失败',
        code: responseData['code'] as String?,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw ApiException(
          message: '网络连接超时，请检查网络设置',
          code: 'TIMEOUT',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw ApiException(
          message: '无法连接到服务器，请确保后端服务已启动',
          code: 'CONNECTION_ERROR',
        );
      } else if (e.response?.statusCode == 401) {
        throw ApiException(
          message: '请先登录',
          code: 'UNAUTHORIZED',
        );
      } else if (e.response?.statusCode == 403) {
        throw ApiException(
          message: '没有权限发布帖子',
          code: 'FORBIDDEN',
        );
      } else if (e.response?.data != null) {
        final errorData = e.response!.data as Map<String, dynamic>;
        throw ApiException(
          message: errorData['message'] as String? ?? '发布帖子失败',
          code: errorData['code'] as String?,
        );
      }
      throw ApiException(
        message: '发布帖子失败: ${e.message ?? "未知错误"}',
        code: 'NETWORK_ERROR',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: '发布帖子失败: ${e.toString()}',
        code: 'UNKNOWN_ERROR',
      );
    }
  }
}

