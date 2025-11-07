import 'package:dio/dio.dart';
import 'package:yabai_app/core/network/api_client.dart';
import 'package:yabai_app/core/network/api_exception.dart';
import 'package:yabai_app/core/network/models/api_response.dart';
import 'package:yabai_app/core/network/models/page_response.dart';
import 'package:yabai_app/features/home/data/models/favorite_project_model.dart';

class FavoriteRepository {
  const FavoriteRepository(this._apiClient);

  final ApiClient _apiClient;

  /// 收藏项目
  Future<void> addFavorite(int projectId, {String? note}) async {
    try {
      final data = <String, dynamic>{
        'projectId': projectId,
      };
      
      if (note != null && note.isNotEmpty) {
        data['note'] = note;
      }

      final response = await _apiClient.post(
        '/api/v1/favorites',
        data: data,
      );

      final body = response.data;

      if (body == null) {
        throw ApiException(message: '服务器未返回数据');
      }

      final apiResponse = ApiResponse<void>.fromJson(
        body,
        dataParser: (_) => null,
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
      throw ApiException(message: '收藏项目失败: $error');
    }
  }

  /// 取消收藏项目
  Future<void> removeFavorite(int projectId) async {
    try {
      final response = await _apiClient.delete(
        '/api/v1/favorites/$projectId',
      );

      final body = response.data;

      if (body == null) {
        throw ApiException(message: '服务器未返回数据');
      }

      final apiResponse = ApiResponse<void>.fromJson(
        body,
        dataParser: (_) => null,
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
      throw ApiException(message: '取消收藏失败: $error');
    }
  }

  /// 获取我的收藏项目列表
  Future<PageResponse<FavoriteProjectModel>> fetchMyFavorites({
    int page = 1,
    int size = 20,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'size': size,
      };

      final response = await _apiClient.get(
        '/api/v1/favorites',
        queryParameters: queryParameters,
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
        return PageResponse<FavoriteProjectModel>.empty();
      }

      return PageResponse<FavoriteProjectModel>.fromJson(
        data,
        FavoriteProjectModel.fromJson,
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
      throw ApiException(message: '获取收藏列表失败: $error');
    }
  }

  /// 检查项目收藏状态
  Future<bool> checkFavoriteStatus(int projectId) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/favorites/check/$projectId',
      );

      final body = response.data;

      if (body == null) {
        throw ApiException(message: '服务器未返回数据');
      }

      final apiResponse = ApiResponse<bool>.fromJson(
        body,
        dataParser: (rawData) {
          if (rawData is bool) {
            return rawData;
          }
          return false;
        },
      );

      if (!apiResponse.success) {
        throw ApiException(
          message: apiResponse.message,
          code: apiResponse.code,
        );
      }

      return apiResponse.data ?? false;
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
      throw ApiException(message: '检查收藏状态失败: $error');
    }
  }
}

