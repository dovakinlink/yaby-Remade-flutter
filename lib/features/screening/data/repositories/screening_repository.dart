import 'package:dio/dio.dart';
import 'package:yabai_app/core/network/api_client.dart';
import 'package:yabai_app/core/network/api_exception.dart';
import 'package:yabai_app/core/network/models/api_response.dart';
import 'package:yabai_app/core/network/models/page_response.dart';
import 'package:yabai_app/features/screening/data/models/enrollment_request_model.dart';
import 'package:yabai_app/features/screening/data/models/icf_request_model.dart';
import 'package:yabai_app/features/screening/data/models/screening_detail_model.dart';
import 'package:yabai_app/features/screening/data/models/screening_model.dart';
import 'package:yabai_app/features/screening/data/models/screening_request_model.dart';
import 'package:yabai_app/features/screening/data/models/status_log_model.dart';

class ScreeningRepository {
  const ScreeningRepository(this._apiClient);

  final ApiClient _apiClient;

  /// 提交初筛
  Future<int> submitScreening(ScreeningRequestModel request) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/screenings',
        data: request.toJson(),
      );

      final body = response.data;

      if (body == null) {
        throw ApiException(message: '服务器未返回数据');
      }

      final apiResponse = ApiResponse<int>.fromJson(
        body,
        dataParser: (rawData) {
          if (rawData is int) {
            return rawData;
          }
          return 0;
        },
      );

      if (!apiResponse.success) {
        throw ApiException(
          message: apiResponse.message,
          code: apiResponse.code,
        );
      }

      final data = apiResponse.data;
      if (data == null || data == 0) {
        throw ApiException(message: '提交初筛失败');
      }

      return data;
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
      throw ApiException(message: '提交初筛失败: $error');
    }
  }

  /// 查询我的筛查列表
  Future<PageResponse<ScreeningModel>> fetchMyScreenings({
    String? statusCode,
    int page = 1,
    int size = 20,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'size': size,
      };
      
      // 如果有状态筛选，添加到参数中
      if (statusCode != null && statusCode.isNotEmpty) {
        queryParameters['statusCode'] = statusCode;
      }
      
      final response = await _apiClient.get(
        '/api/v1/screenings/my',
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
        return PageResponse<ScreeningModel>.empty();
      }

      return PageResponse<ScreeningModel>.fromJson(
        data,
        ScreeningModel.fromJson,
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
      throw ApiException(message: '查询筛查列表失败: $error');
    }
  }

  /// 查询筛查详情
  Future<ScreeningDetailModel> fetchScreeningDetail(int id) async {
    try {
      final response = await _apiClient.get('/api/v1/screenings/$id');

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
        throw ApiException(message: '筛查详情为空');
      }

      return ScreeningDetailModel.fromJson(data);
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
      throw ApiException(message: '查询筛查详情失败: $error');
    }
  }

  /// 查询状态流转历史
  Future<List<StatusLogModel>> fetchStatusHistory(int screeningId) async {
    try {
      final response = await _apiClient.get('/api/v1/screenings/$screeningId/status-log');

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
      if (data == null) {
        return [];
      }

      return data
          .map((json) => StatusLogModel.fromJson(json as Map<String, dynamic>))
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
      throw ApiException(message: '查询状态历史失败: $error');
    }
  }

  /// 更新筛查状态
  Future<void> updateScreeningStatus({
    required int id,
    required String status,
    int? failReasonDictId,
    String? failRemark,
  }) async {
    try {
      final response = await _apiClient.put(
        '/api/v1/screenings/$id/status',
        data: {
          'status': status,
          'failReasonDictId': failReasonDictId,
          'failRemark': failRemark,
        },
      );

      final body = response.data;

      if (body == null) {
        throw ApiException(message: '服务器未返回数据');
      }

      final apiResponse = ApiResponse<String>.fromJson(
        body,
        dataParser: (rawData) => rawData?.toString() ?? '',
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
      throw ApiException(message: '更新筛查状态失败: $error');
    }
  }

  /// 提交知情同意
  Future<void> submitIcf(int screeningId, IcfRequestModel request) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/screenings/$screeningId/icf',
        data: request.toJson(),
      );

      final body = response.data;

      if (body == null) {
        throw ApiException(message: '服务器未返回数据');
      }

      final apiResponse = ApiResponse<String>.fromJson(
        body,
        dataParser: (rawData) => rawData?.toString() ?? '',
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
      throw ApiException(message: '提交知情同意失败: $error');
    }
  }

  /// 提交入组信息
  Future<void> submitEnrollment(int screeningId, EnrollmentRequestModel request) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/screenings/$screeningId/enrollment',
        data: request.toJson(),
      );

      final body = response.data;

      if (body == null) {
        throw ApiException(message: '服务器未返回数据');
      }

      final apiResponse = ApiResponse<String>.fromJson(
        body,
        dataParser: (rawData) => rawData?.toString() ?? '',
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
      throw ApiException(message: '提交入组信息失败: $error');
    }
  }

  /// 标记出组
  Future<void> markAsExited(int screeningId) async {
    try {
      final response = await _apiClient.put('/api/v1/screenings/$screeningId/exit');

      final body = response.data;

      if (body == null) {
        throw ApiException(message: '服务器未返回数据');
      }

      final apiResponse = ApiResponse<String>.fromJson(
        body,
        dataParser: (rawData) => rawData?.toString() ?? '',
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
      throw ApiException(message: '标记出组失败: $error');
    }
  }
}

