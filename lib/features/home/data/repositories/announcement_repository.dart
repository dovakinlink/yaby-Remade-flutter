import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:yabai_app/core/network/api_client.dart';
import 'package:yabai_app/core/network/api_exception.dart';
import 'package:yabai_app/core/network/models/api_response.dart';
import 'package:yabai_app/core/network/models/page_response.dart';
import 'package:yabai_app/features/home/data/models/announcement_model.dart';
import 'package:yabai_app/features/home/data/models/notice_tag_model.dart';
import 'package:yabai_app/features/home/data/models/post_tag_model.dart';

class AnnouncementRepository {
  const AnnouncementRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PageResponse<AnnouncementModel>> fetchHomeAnnouncements({
    int page = 1,
    int size = 10,
    int? noticeType,
    int? status,
    int? tagId,
  }) async {
    try {
      final queryParameters = <String, dynamic>{'page': page, 'size': size};

      if (noticeType != null) {
        queryParameters['notice-type'] = noticeType;
      }
      if (status != null) {
        queryParameters['status'] = status;
      }
      if (tagId != null) {
        queryParameters['tagId'] = tagId;
      }

      debugPrint('═══ AnnouncementRepository: fetchHomeAnnouncements ═══');
      debugPrint('请求参数: $queryParameters');
      debugPrint('tagId: $tagId');

      final response = await _apiClient.get(
        '/api/v1/announcements/home',
        queryParameters: queryParameters,
      );

      debugPrint('响应状态: ${response.statusCode}');
      debugPrint('请求URL: ${response.requestOptions.uri}');

      final body = response.data;
      debugPrint('响应数据类型: ${body.runtimeType}');
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
        debugPrint('data为空，返回空页面');
        return PageResponse<AnnouncementModel>.empty();
      }

      final pageResponse = PageResponse<AnnouncementModel>.fromJson(
        data,
        AnnouncementModel.fromJson,
      );

      debugPrint('解析成功: ${pageResponse.data.length} 条公告');
      debugPrint('分页信息: page=${pageResponse.page}, size=${pageResponse.size}, total=${pageResponse.total}, hasNext=${pageResponse.hasNext}');

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
      throw ApiException(message: '公告数据解析失败: $error');
    }
  }

  /// 获取通知公告标签列表
  Future<List<NoticeTagModel>> fetchAnnouncementTags() async {
    try {
      debugPrint('AnnouncementRepository: 请求标签列表 /api/v1/announcements/tags');
      
      final response = await _apiClient.get('/api/v1/announcements/tags');
      final body = response.data;
      
      debugPrint('AnnouncementRepository: 标签API响应 - statusCode: ${response.statusCode}');
      
      if (body == null) {
        debugPrint('AnnouncementRepository: 响应body为null');
        throw ApiException(message: '服务器未返回数据');
      }

      debugPrint('AnnouncementRepository: 响应body类型: ${body.runtimeType}');
      
      // 根据API文档，响应格式是 { code, message, data }
      if (body is! Map<String, dynamic>) {
        throw ApiException(message: '响应格式错误');
      }

      final code = body['code'] as String?;
      final message = body['message'] as String?;
      final data = body['data'];

      debugPrint('AnnouncementRepository: code=$code, message=$message');

      if (code != 'SUCCESS') {
        throw ApiException(message: message ?? '获取标签列表失败', code: code);
      }

      if (data == null) {
        debugPrint('AnnouncementRepository: data为null，返回空列表');
        return [];
      }

      if (data is! List) {
        debugPrint('AnnouncementRepository: data不是List类型: ${data.runtimeType}');
        return [];
      }

      final tags = (data as List)
          .map((json) => NoticeTagModel.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('AnnouncementRepository: 成功获取 ${tags.length} 个标签');
      for (var tag in tags) {
        debugPrint('  - 标签: ${tag.tagName} (ID: ${tag.id}, Code: ${tag.tagCode})');
      }

      return tags;
    } on DioException catch (error) {
      debugPrint('AnnouncementRepository: 标签请求失败 - ${error.type}: ${error.message}');
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
      debugPrint('AnnouncementRepository: 标签解析失败 - $error');
      throw ApiException(message: '标签数据解析失败: $error');
    }
  }
}
