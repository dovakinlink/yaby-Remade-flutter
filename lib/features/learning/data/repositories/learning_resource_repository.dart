import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:yabai_app/core/network/api_client.dart';
import 'package:yabai_app/core/network/api_exception.dart';
import 'package:yabai_app/core/network/models/api_response.dart';
import 'package:yabai_app/features/profile/data/models/page_response.dart';
import 'package:yabai_app/features/learning/data/models/learning_resource_model.dart';
import 'package:yabai_app/features/learning/data/models/learning_resource_detail_model.dart';

class LearningResourceRepository {
  final ApiClient _apiClient;

  LearningResourceRepository(this._apiClient);

  /// 获取学习资源列表
  Future<PageResponse<LearningResource>> getResourceList({
    int page = 1,
    int size = 10,
  }) async {
    try {
      debugPrint('请求学习资源列表: page=$page, size=$size');
      
      final response = await _apiClient.get(
        '/api/v1/learning-resources',
        queryParameters: {
          'page': page,
          'size': size,
        },
      );

      debugPrint('学习资源API响应状态: ${response.statusCode}');

      final body = response.data;
      if (body == null) {
        debugPrint('学习资源API返回数据为null');
        throw ApiException(message: '服务器未返回数据');
      }

      debugPrint('学习资源API返回数据类型: ${body.runtimeType}');

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        body,
        dataParser: (rawData) {
          if (rawData is Map<String, dynamic>) {
            return rawData;
          }
          return <String, dynamic>{};
        },
      );

      debugPrint('学习资源API success=${apiResponse.success}, code=${apiResponse.code}, message=${apiResponse.message}');

      if (!apiResponse.success) {
        debugPrint('学习资源API返回失败: ${apiResponse.message}');
        throw ApiException(
          message: apiResponse.message,
          code: apiResponse.code,
        );
      }

      final data = apiResponse.data;
      if (data == null) {
        debugPrint('学习资源data为null，返回空列表');
        return PageResponse<LearningResource>.empty();
      }

      debugPrint('学习资源data keys: ${data.keys.toList()}');
      
      final pageResponse = PageResponse.fromJson(
        data,
        (json) => LearningResource.fromJson(json),
      );
      
      debugPrint('解析学习资源成功: 共${pageResponse.data.length}条, 当前页${pageResponse.page}, hasNext=${pageResponse.hasNext}');
      
      return pageResponse;
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
      throw ApiException(message: '学习资源数据解析失败: $error');
    }
  }

  /// 获取学习资源详情
  Future<LearningResourceDetail> getResourceDetail(int resourceId) async {
    try {
      debugPrint('请求学习资源详情: id=$resourceId');
      
      final response = await _apiClient.get(
        '/api/v1/learning-resources/$resourceId',
      );

      final body = response.data;
      if (body == null) {
        throw ApiException(message: '服务器未返回数据');
      }

      debugPrint('学习资源详情API响应状态: ${response.statusCode}');

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
        throw ApiException(message: '学习资源详情数据为空');
      }

      debugPrint('学习资源详情data keys: ${data.keys.toList()}');
      if (data['files'] != null) {
        debugPrint('文件数量: ${(data['files'] as List).length}');
        for (var file in (data['files'] as List)) {
          debugPrint('文件信息: ${file['displayName']}, ext: ${file['ext']}, mimeType: ${file['mimeType']}, url: ${file['url']}');
        }
      }

      final detail = LearningResourceDetail.fromJson(data);
      debugPrint('解析学习资源详情成功: ${detail.name}, 文件数: ${detail.fileCount}');
      
      return detail;
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
      debugPrint('学习资源详情解析错误: $error');
      throw ApiException(message: '学习资源详情解析失败: $error');
    }
  }
}
