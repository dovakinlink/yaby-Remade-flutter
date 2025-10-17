import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:yabai_app/core/network/api_client.dart';
import 'package:yabai_app/features/auth/data/models/auth_exception.dart';
import 'package:yabai_app/features/auth/data/repositories/auth_repository.dart';
import 'package:yabai_app/features/auth/providers/auth_session_provider.dart';

/// 自动刷新令牌的拦截器
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.apiClient,
    required this.authRepository,
    required this.authSessionProvider,
    required this.onSessionExpired,
  });

  final ApiClient apiClient;
  final AuthRepository authRepository;
  final AuthSessionProvider authSessionProvider;
  final VoidCallback onSessionExpired;

  bool _isRefreshing = false;
  final List<_RequestRetryInfo> _pendingRequests = [];
  static const _retryFlag = '_retriedAfterRefresh';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_isAuthPath(options.uri.path)) {
      options.headers.remove('Authorization');
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    debugPrint('🔴 AuthInterceptor.onError: statusCode=${err.response?.statusCode}, path=${err.requestOptions.path}');
    
    // 只处理 401 未授权错误
    if (err.response?.statusCode != 401) {
      debugPrint('🔴 不是401错误，跳过处理');
      return handler.next(err);
    }

    final requestOptions = err.requestOptions;

    // 跳过刷新接口或已经重试过的请求，避免死循环
    if (_shouldSkipRetry(requestOptions)) {
      debugPrint('🔴 跳过重试（已重试过或是刷新接口）');
      return handler.next(err);
    }

    // 检查是否有 refresh token
    final currentTokens = authSessionProvider.tokens;
    debugPrint(
      '🔴 当前tokens: accessToken=${_maskToken(currentTokens?.accessToken)}, refreshToken=${_maskToken(currentTokens?.refreshToken)}',
    );
    
    if (currentTokens == null || currentTokens.refreshToken.isEmpty) {
      debugPrint('🔴 没有可用的 refresh token，跳转登录');
      _handleSessionExpired();
      return handler.next(err);
    }

    // 如果正在刷新，将请求加入队列
    if (_isRefreshing) {
      debugPrint('正在刷新令牌，将请求加入队列');
      _pendingRequests.add(_RequestRetryInfo(
        requestOptions: err.requestOptions,
        handler: handler,
      ));
      return;
    }

    // 开始刷新令牌
    _isRefreshing = true;
    debugPrint('开始刷新令牌...');

    try {
      // 调用刷新令牌接口
      final newTokens = await authRepository.refreshTokens(
        refreshToken: currentTokens.refreshToken,
      );

      debugPrint('令牌刷新成功');

      // 更新客户端凭证
      apiClient.updateAuthToken(newTokens.accessToken);

      // 重试原请求
      final response = await _retryRequest(
        requestOptions,
        newTokens.accessToken,
      );

      // 重试所有等待的请求
      await _retryPendingRequests(newTokens.accessToken);

      // 持久化新令牌
      await authSessionProvider.save(newTokens);

      // 返回成功响应
      return handler.resolve(response);
    } on AuthException catch (e) {
      debugPrint('令牌刷新失败: ${e.message}');
      
      // 清除等待的请求
      _clearPendingRequests(err);
      
      // 会话过期，清除登录状态
      _handleSessionExpired();
      
      return handler.next(err);
    } catch (e) {
      debugPrint('令牌刷新出错: $e');
      
      // 清除等待的请求
      _clearPendingRequests(err);
      
      return handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }

  /// 重试请求
  Future<Response<dynamic>> _retryRequest(
    RequestOptions requestOptions,
    String newAccessToken,
  ) async {
    final updatedHeaders = Map<String, dynamic>.from(requestOptions.headers)
      ..['Authorization'] = 'Bearer $newAccessToken';

    final options = requestOptions.copyWith(
      headers: updatedHeaders,
      extra: {
        ...requestOptions.extra,
        _retryFlag: true,
      },
    );

    return apiClient.dio.fetch<dynamic>(options);
  }

  /// 重试所有等待的请求
  Future<void> _retryPendingRequests(String newAccessToken) async {
    final requests = List<_RequestRetryInfo>.from(_pendingRequests);
    _pendingRequests.clear();

    for (final retryInfo in requests) {
      try {
        final response = await _retryRequest(
          retryInfo.requestOptions,
          newAccessToken,
        );
        retryInfo.handler.resolve(response);
      } catch (e) {
        retryInfo.handler.next(
          DioException(
            requestOptions: retryInfo.requestOptions,
            error: e,
          ),
        );
      }
    }
  }

  /// 清除所有等待的请求
  void _clearPendingRequests(DioException error) {
    final requests = List<_RequestRetryInfo>.from(_pendingRequests);
    _pendingRequests.clear();

    for (final retryInfo in requests) {
      retryInfo.handler.next(
        DioException(
          requestOptions: retryInfo.requestOptions,
          error: error.error,
          response: error.response,
        ),
      );
    }
  }

  /// 处理会话过期
  void _handleSessionExpired() {
    authSessionProvider.clear();
    onSessionExpired();
  }

  bool _shouldSkipRetry(RequestOptions requestOptions) {
    if (requestOptions.extra[_retryFlag] == true) {
      return true;
    }
    final path = requestOptions.uri.path;
    if (_isAuthPath(path)) {
      return true;
    }
    return false;
  }

  bool _isAuthPath(String path) {
    return path.contains('/auth/token-refresh') || path.contains('/auth/sign-in');
  }

  String _maskToken(String? token) {
    if (token == null || token.isEmpty) {
      return '<empty>';
    }
    const previewLength = 12;
    if (token.length <= previewLength) {
      return token;
    }
    return '${token.substring(0, previewLength)}...';
  }
}

/// 请求重试信息
class _RequestRetryInfo {
  _RequestRetryInfo({
    required this.requestOptions,
    required this.handler,
  });

  final RequestOptions requestOptions;
  final ErrorInterceptorHandler handler;
}
