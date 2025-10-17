import 'package:dio/dio.dart';
import 'package:yabai_app/core/network/api_client.dart';
import 'package:yabai_app/core/network/api_exception.dart';
import 'package:yabai_app/core/network/models/api_response.dart';
import 'package:yabai_app/features/home/data/models/announcement_model.dart';
import 'package:yabai_app/features/profile/data/models/page_response.dart';

class MyPostsRepository {
  final ApiClient _apiClient;

  MyPostsRepository(this._apiClient);

  /// 获取我的发表公告列表
  Future<PageResponse<AnnouncementModel>> getMyPosts({
    int page = 1,
    int size = 10,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/announcements/my-posts',
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
        return PageResponse<AnnouncementModel>.empty();
      }

      return PageResponse.fromJson(
        data,
        (json) => AnnouncementModel.fromJson(json),
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
      throw ApiException(message: '我的帖子数据解析失败: $error');
    }
  }
}

