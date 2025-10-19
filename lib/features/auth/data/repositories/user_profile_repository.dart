import 'package:dio/dio.dart';
import 'package:yabai_app/core/network/api_client.dart';
import 'package:yabai_app/core/network/api_exception.dart';
import 'package:yabai_app/core/network/models/api_response.dart';
import 'package:yabai_app/features/auth/data/models/user_profile.dart';
import 'package:yabai_app/features/profile/data/models/user_profile_model.dart';

class UserProfileRepository {
  final ApiClient _apiClient;

  UserProfileRepository(this._apiClient);

  /// 获取当前用户个人信息
  Future<UserProfile> getUserProfile() async {
    try {
      final response = await _apiClient.get('/api/v1/user-profile/me');
      
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
        throw ApiException(message: '用户信息数据为空');
      }

      return UserProfile.fromJson(data);
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
      throw ApiException(message: '用户信息数据解析失败: $error');
    }
  }

  /// 修改密码
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiClient.put(
        '/api/v1/user-profile/change-password',
        data: {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
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
      throw ApiException(message: '修改密码失败: $error');
    }
  }

  /// 查询指定用户信息
  Future<UserProfileModel> fetchUserProfile(int userId) async {
    try {
      final response = await _apiClient.get('/api/v1/user-profile/$userId');
      
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
        throw ApiException(message: '用户信息为空');
      }

      return UserProfileModel.fromJson(data);
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
      throw ApiException(message: '查询用户信息失败: $error');
    }
  }
}
