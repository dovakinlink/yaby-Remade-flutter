import 'package:dio/dio.dart';

class ApiClient {
  ApiClient()
      : dio = Dio(
          BaseOptions(
            baseUrl: 'https://api.example.com',
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );

  final Dio dio;

  Future<Response<dynamic>> postLogin(Map<String, dynamic> data) async {
    // Demo endpoint to showcase dio usage; replace with real implementation.
    return dio.post('/login', data: data);
  }
}
