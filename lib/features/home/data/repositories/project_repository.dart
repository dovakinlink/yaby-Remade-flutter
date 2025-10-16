import 'package:dio/dio.dart';
import 'package:yabai_app/core/network/api_client.dart';
import 'package:yabai_app/core/network/api_exception.dart';
import 'package:yabai_app/core/network/models/api_response.dart';
import 'package:yabai_app/core/network/models/page_response.dart';
import 'package:yabai_app/features/home/data/models/attr_definition_model.dart';
import 'package:yabai_app/features/home/data/models/project_detail_model.dart';
import 'package:yabai_app/features/home/data/models/project_model.dart';

class ProjectRepository {
  const ProjectRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PageResponse<ProjectModel>> fetchProjects({
    int page = 1,
    int size = 10,
    Map<String, String>? attrFilters,
  }) async {
    try {
      final queryParameters = <String, dynamic>{'page': page, 'size': size};

      // 添加自定义属性筛选条件
      if (attrFilters != null && attrFilters.isNotEmpty) {
        attrFilters.forEach((key, value) {
          queryParameters['attrFilters.$key'] = value;
        });
        print('[ProjectRepository] 筛选参数: $attrFilters');
        print('[ProjectRepository] 最终查询参数: $queryParameters');
      }

      final response = await _apiClient.get(
        '/api/v1/projects',
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
        return PageResponse<ProjectModel>.empty();
      }

      return PageResponse<ProjectModel>.fromJson(
        data,
        ProjectModel.fromJson,
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
      throw ApiException(message: '项目数据解析失败: $error');
    }
  }

  Future<List<AttrDefinitionModel>> fetchAttrDefinitions({
    int? templateId,
    int? disciplineId,
  }) async {
    try {
      final queryParameters = <String, dynamic>{};

      if (templateId != null) {
        queryParameters['templateId'] = templateId;
      }
      if (disciplineId != null) {
        queryParameters['disciplineId'] = disciplineId;
      }

      final response = await _apiClient.get(
        '/api/v1/projects/attr-definitions',
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
      );

      final body = response.data;
      
      if (body == null) {
        throw ApiException(message: '服务器未返回数据');
      }

      final apiResponse = ApiResponse<List<dynamic>>.fromJson(
        body,
        dataParser: (rawData) {
          if (rawData is List) {
            return rawData;
          }
          return <dynamic>[];
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
        return [];
      }

      return data
          .map((item) =>
              AttrDefinitionModel.fromJson(item as Map<String, dynamic>))
          .toList();
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
      throw ApiException(message: '属性定义解析失败: $error');
    }
  }

  Future<ProjectDetailModel> fetchProjectDetail(int id) async {
    try {
      final response = await _apiClient.get('/api/v1/projects/$id');

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
        throw ApiException(message: '项目不存在或无权访问');
      }

      return ProjectDetailModel.fromJson(data);
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
      throw ApiException(message: '项目详情解析失败: $error');
    }
  }

  Future<PageResponse<ProjectModel>> searchProjects({
    required String keyword,
    int page = 1,
    int size = 10,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'keyword': keyword,
        'page': page,
        'size': size,
      };

      final response = await _apiClient.get(
        '/api/v1/projects/search',
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
        return PageResponse<ProjectModel>.empty();
      }

      return PageResponse<ProjectModel>.fromJson(
        data,
        ProjectModel.fromJson,
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
      throw ApiException(message: '搜索项目失败: $error');
    }
  }
}

