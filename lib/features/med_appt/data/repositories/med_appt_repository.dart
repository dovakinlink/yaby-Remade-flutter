import 'package:flutter/foundation.dart';
import 'package:yabai_app/core/network/api_client.dart';
import 'package:yabai_app/core/network/api_exception.dart';
import 'package:yabai_app/core/network/models/api_response.dart';
import 'package:yabai_app/core/network/models/page_response.dart';
import 'package:yabai_app/features/med_appt/data/models/med_appt_model.dart';
import 'package:yabai_app/features/med_appt/data/models/med_appt_create_request.dart';

class MedApptRepository {
  const MedApptRepository(this._apiClient);

  final ApiClient _apiClient;

  /// 创建用药预约
  /// 返回新建记录的ID
  Future<int> createMedAppt(MedApptCreateRequest request) async {
    try {
      debugPrint('═══ MedApptRepository: createMedAppt ═══');
      debugPrint('请求参数: ${request.toJson()}');

      final response = await _apiClient.post(
        '/api/v1/med-appt',
        data: request.toJson(),
      );

      debugPrint('响应状态: ${response.statusCode}');

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
          if (rawData is String) {
            return int.tryParse(rawData) ?? 0;
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

      final id = apiResponse.data;
      if (id == null || id == 0) {
        throw ApiException(message: '创建预约失败：未返回有效的ID');
      }

      debugPrint('创建成功，ID: $id');
      return id;
    } catch (e) {
      debugPrint('创建预约失败: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: '创建预约失败: ${e.toString()}');
    }
  }

  /// 查询周预约列表
  /// 根据指定日期查询该日期所在周（周一到周日）的所有用药预约
  Future<PageResponse<MedApptModel>> getWeekAppointments({
    required String date, // yyyy-MM-dd
    int page = 1,
    int size = 20,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'date': date,
        'page': page,
        'size': size,
      };

      debugPrint('═══ MedApptRepository: getWeekAppointments ═══');
      debugPrint('请求参数: $queryParameters');

      final response = await _apiClient.get(
        '/api/v1/med-appt/week',
        queryParameters: queryParameters,
      );

      debugPrint('响应状态: ${response.statusCode}');

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
        debugPrint('data为空，返回空页面');
        return PageResponse<MedApptModel>.empty();
      }

      final pageResponse = PageResponse<MedApptModel>.fromJson(
        data,
        MedApptModel.fromJson,
      );

      debugPrint('查询成功，共 ${pageResponse.total} 条记录');
      return pageResponse;
    } catch (e) {
      debugPrint('查询周预约列表失败: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: '查询预约列表失败: ${e.toString()}');
    }
  }

  /// 确认用药预约
  /// 将预约状态从PENDING（待确认）更新为CONFIRMED（已确认）
  Future<void> confirmMedAppt(int apptId) async {
    try {
      debugPrint('═══ MedApptRepository: confirmMedAppt ═══');
      debugPrint('预约ID: $apptId');

      final response = await _apiClient.put(
        '/api/v1/med-appt/$apptId/confirm',
      );

      debugPrint('响应状态: ${response.statusCode}');

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

      debugPrint('确认预约成功');
    } catch (e) {
      debugPrint('确认预约失败: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: '确认预约失败: ${e.toString()}');
    }
  }
}

