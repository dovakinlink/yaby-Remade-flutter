import 'package:dio/dio.dart';
import 'package:yabai_app/core/config/env_config.dart';
import 'package:yabai_app/core/network/api_exception.dart';
import 'package:yabai_app/features/ai/data/models/ai_project_model.dart';
import 'package:yabai_app/features/ai/data/models/ai_query_request.dart';
import 'package:yabai_app/features/ai/data/models/ai_query_response.dart';

class AiRepository {
  AiRepository() {
    _dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.aiServiceHost,
        connectTimeout: const Duration(seconds: 150),
        sendTimeout: const Duration(seconds: 150),
        receiveTimeout: const Duration(seconds: 150), // AI 处理需要较长时间，设置为 2.5 分钟
        responseType: ResponseType.json,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  late final Dio _dio;

  /// 查询匹配的项目
  /// 
  /// [userInput] 用户输入的查询文本
  /// 返回匹配的项目列表（仅包含 is_match 为 true 的项目）
  Future<List<AiProjectModel>> queryProjects(String userInput) async {
    try {
      // 拼接固定前缀
      final fullInput = 'orgId:1,disciplineId:2,$userInput';
      
      final request = AiQueryRequest(inputAsText: fullInput);
      
      final response = await _dio.post<Map<String, dynamic>>(
        '/run',
        data: request.toJson(),
      );

      final body = response.data;
      
      if (body == null) {
        throw ApiException(message: 'AI 服务未返回数据');
      }

      // 解析响应
      final aiResponse = AiQueryResponse.fromJson(body);
      
      // 过滤出 is_match 为 true 的项目
      final matchedProjects = aiResponse.searchTrials.projects
          .where((project) => project.isMatch)
          .toList();

      return matchedProjects;
    } on DioException catch (error) {
      final dynamic responseBody = error.response?.data;
      String message = 'AI 服务请求失败';
      
      if (responseBody is Map<String, dynamic>) {
        message = responseBody['message'] as String? ?? message;
      } else if (error.message != null) {
        message = error.message!;
      }
      
      throw ApiException(message: message);
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(message: 'AI 查询结果解析失败: $error');
    }
  }
}

