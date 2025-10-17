import 'package:dio/dio.dart';
import 'package:yabai_app/core/network/api_client.dart';
import 'package:yabai_app/features/auth/data/models/auth_exception.dart';
import 'package:yabai_app/features/auth/data/models/auth_tokens.dart';

class AuthRepository {
  const AuthRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<AuthTokens> signIn({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/auth/sign-in',
        data: {'username': username, 'password': password},
      );

      final body = response.data;
      if (body == null) {
        throw const AuthException(message: '服务器未返回数据');
      }

      final bool success = body['success'] as bool? ?? false;
      final String message = body['message'] as String? ?? '登录失败';
      final String? code = body['code'] as String?;

      if (!success) {
        throw AuthException(message: message, code: code);
      }

      final Map<String, dynamic>? data = body['data'] is Map<String, dynamic>
          ? body['data'] as Map<String, dynamic>
          : null;

      if (data == null) {
        throw const AuthException(message: '登录响应缺少凭证');
      }

      final tokens = AuthTokens.fromJson(data);

      if (tokens.accessToken.isEmpty || tokens.refreshToken.isEmpty) {
        throw const AuthException(message: '登录凭证无效');
      }

      return tokens;
    } on DioException catch (error) {
      final dynamic responseBody = error.response?.data;
      final Map<String, dynamic>? responseMap =
          responseBody is Map<String, dynamic> ? responseBody : null;
      final message =
          responseMap?['message'] as String? ?? error.message ?? '网络请求失败';
      final code = responseMap?['code'] as String?;
      throw AuthException(message: message, code: code);
    } catch (error) {
      if (error is AuthException) {
        rethrow;
      }
      throw AuthException(message: error.toString());
    }
  }

  Future<AuthTokens> refreshTokens({required String refreshToken}) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/auth/token-refresh',
        data: {'refreshToken': refreshToken},
      );

      final body = response.data;
      if (body == null) {
        throw const AuthException(message: '服务器未返回数据');
      }

      final bool success = body['success'] as bool? ?? false;
      final String message = body['message'] as String? ?? '刷新令牌失败';
      final String? code = body['code'] as String?;

      if (!success) {
        throw AuthException(message: message, code: code);
      }

      final Map<String, dynamic>? data = body['data'] is Map<String, dynamic>
          ? body['data'] as Map<String, dynamic>
          : null;

      if (data == null) {
        throw const AuthException(message: '刷新响应缺少凭证');
      }

      final tokens = AuthTokens.fromJson(data);

      if (tokens.accessToken.isEmpty || tokens.refreshToken.isEmpty) {
        throw const AuthException(message: '刷新凭证无效');
      }

      return tokens;
    } on DioException catch (error) {
      final dynamic responseBody = error.response?.data;
      final Map<String, dynamic>? responseMap =
          responseBody is Map<String, dynamic> ? responseBody : null;
      final message =
          responseMap?['message'] as String? ?? error.message ?? '网络请求失败';
      final code = responseMap?['code'] as String?;
      throw AuthException(message: message, code: code);
    } catch (error) {
      if (error is AuthException) {
        rethrow;
      }
      throw AuthException(message: error.toString());
    }
  }
}
