import 'package:dio/dio.dart';
import 'package:yabai_app/core/config/env_config.dart';

class ApiClient {
  ApiClient({Dio? dio})
    : dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: EnvConfig.initialBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              responseType: ResponseType.json,
              headers: const {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            ),
          );

  final Dio dio;

  Future<Response<Map<String, dynamic>>> post(
    String path, {
    Map<String, dynamic>? data,
    Options? options,
  }) async {
    final baseUrl = await EnvConfig.resolveApiBaseUrl();
    if (dio.options.baseUrl != baseUrl) {
      dio.options.baseUrl = baseUrl;
    }

    return dio.post<Map<String, dynamic>>(path, data: data, options: options);
  }
}
