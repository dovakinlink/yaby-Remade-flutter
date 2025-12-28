import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:yabai_app/core/config/env_config.dart';
import 'package:yabai_app/core/network/api_client.dart';
import 'package:yabai_app/core/network/api_exception.dart';
import 'package:yabai_app/core/network/models/api_response.dart';
import 'package:yabai_app/core/network/models/page_response.dart';
import 'package:yabai_app/features/ai/data/models/ai_chat_log_model.dart';
import 'package:yabai_app/features/ai/data/models/ai_project_model.dart';
import 'package:yabai_app/features/ai/data/models/ai_query_request.dart';
import 'package:yabai_app/features/ai/data/models/ai_query_request_v2.dart';
import 'package:yabai_app/features/ai/data/models/ai_query_response.dart';
import 'package:yabai_app/features/ai/data/models/ai_session_model.dart';
import 'package:yabai_app/features/ai/data/models/xiaobai_patient_project_model.dart';
import 'package:yabai_app/features/ai/data/models/xiaobai_query_request.dart';
import 'package:yabai_app/features/ai/data/models/xiaobai_query_response.dart';
import 'package:yabai_app/features/ai/data/models/xiaobai_session_model.dart';
import 'package:yabai_app/features/ai/data/models/xiaobai_session_detail_model.dart';

class AiRepository {
  AiRepository({ApiClient? apiClient}) : _apiClient = apiClient {
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
    debugPrint('🤖 [AI] AiRepository 初始化完成');
  }

  late final Dio _dio;
  final ApiClient? _apiClient;

  /// 查询匹配的项目
  /// 
  /// [userInput] 用户输入的查询文本
  /// 返回匹配的项目列表（仅包含 is_match 为 true 的项目）
  Future<List<AiProjectModel>> queryProjects(String userInput) async {
    debugPrint('🤖 [AI] 开始查询项目（Python直连）');
    debugPrint('🤖 [AI] 输入: $userInput');
    
    try {
      // 拼接固定前缀
      final fullInput = 'orgId:1,disciplineId:2,$userInput';
      debugPrint('🤖 [AI] 完整输入: $fullInput');
      
      final request = AiQueryRequest(inputAsText: fullInput);
      
      final startTime = DateTime.now();
      final response = await _dio.post<Map<String, dynamic>>(
        '/run',
        data: request.toJson(),
      );
      final duration = DateTime.now().difference(startTime);
      
      debugPrint('🤖 [AI] 请求完成，耗时: ${duration.inMilliseconds}ms');

      final body = response.data;
      
      if (body == null) {
        debugPrint('🤖 [AI] ❌ 错误: AI 服务未返回数据');
        throw ApiException(message: 'AI 服务未返回数据');
      }

      // 输出完整的响应 JSON
      debugPrint('🤖 [AI] ========== 响应数据开始 ==========');
      try {
        final jsonStr = const JsonEncoder.withIndent('  ').convert(body);
        debugPrint('🤖 [AI] $jsonStr');
      } catch (e) {
        debugPrint('🤖 [AI] JSON格式化失败: $body');
      }
      debugPrint('🤖 [AI] ========== 响应数据结束 ==========');

      // 解析响应
      debugPrint('🤖 [AI] 开始解析响应数据...');
      final aiResponse = AiQueryResponse.fromJson(body);
      
      debugPrint('🤖 [AI] 解析完成，总项目数: ${aiResponse.searchTrials.projects.length}');
      
      // 输出所有项目的 is_match 状态
      for (var i = 0; i < aiResponse.searchTrials.projects.length; i++) {
        final project = aiResponse.searchTrials.projects[i];
        debugPrint('🤖 [AI]   项目${i + 1}: ${project.projectName} (isMatch: ${project.isMatch})');
      }
      
      // 过滤出 is_match 为 true 的项目
      final matchedProjects = aiResponse.searchTrials.projects
          .where((project) => project.isMatch)
          .toList();

      debugPrint('🤖 [AI] ✅ 查询成功，匹配项目数: ${matchedProjects.length}');
      for (var i = 0; i < matchedProjects.length && i < 3; i++) {
        debugPrint('🤖 [AI]   匹配项目${i + 1}: ${matchedProjects[i].projectName}');
      }
      return matchedProjects;
    } on DioException catch (error) {
      debugPrint('🤖 [AI] ❌ DioException: ${error.type} - ${error.message}');
      final dynamic responseBody = error.response?.data;
      String message = 'AI 服务请求失败';
      
      if (responseBody is Map<String, dynamic>) {
        message = responseBody['message'] as String? ?? message;
      } else if (error.message != null) {
        message = error.message!;
      }
      
      debugPrint('🤖 [AI] ❌ 错误信息: $message');
      throw ApiException(message: message);
    } on ApiException {
      rethrow;
    } catch (error) {
      debugPrint('🤖 [AI] ❌ 未知错误: $error');
      throw ApiException(message: 'AI 查询结果解析失败: $error');
    }
  }

  /// 通过 Spring Boot 代理查询匹配的项目（新接口）
  /// 
  /// [userInput] 用户输入的查询文本
  /// [sessionId] 会话 ID（可选）
  /// 返回匹配的项目列表（仅包含 is_match 为 true 的项目）
  Future<List<AiProjectModel>> queryProjectsViaSpringBoot(
    String userInput, {
    String? sessionId,
  }) async {
    if (_apiClient == null) {
      debugPrint('🤖 [AI] ❌ 错误: ApiClient 未初始化');
      throw ApiException(message: 'ApiClient 未初始化');
    }

    debugPrint('🤖 [AI] 开始查询项目（Spring Boot代理）');
    debugPrint('🤖 [AI] 输入: $userInput');
    debugPrint('🤖 [AI] SessionID: ${sessionId ?? "无"}');

    try {
      // 拼接固定前缀
      final fullInput = 'orgId:1,disciplineId:2,$userInput';
      debugPrint('🤖 [AI] 完整输入: $fullInput');
      
      final request = AiQueryRequestV2(
        inputAsText: fullInput,
        sessionId: sessionId,
      );
      
      debugPrint('🤖 [AI] 发送请求到: /api/v1/ai/query');
      debugPrint('🤖 [AI] 超时设置: 150秒');
      
      final startTime = DateTime.now();
      // AI 请求需要更长的超时时间
      final response = await _apiClient!.post(
        '/api/v1/ai/query',
        data: request.toJson(),
        options: Options(
          sendTimeout: const Duration(seconds: 150),
          receiveTimeout: const Duration(seconds: 150),
        ),
      );
      final duration = DateTime.now().difference(startTime);
      
      debugPrint('🤖 [AI] 请求完成，耗时: ${duration.inSeconds}秒 (${duration.inMilliseconds}ms)');

      final body = response.data;
      
      if (body == null) {
        debugPrint('🤖 [AI] ❌ 错误: AI 服务未返回数据');
        throw ApiException(message: 'AI 服务未返回数据');
      }

      // 输出完整的响应 JSON
      debugPrint('🤖 [AI] ========== 响应数据开始 ==========');
      try {
        final jsonStr = const JsonEncoder.withIndent('  ').convert(body);
        debugPrint('🤖 [AI] $jsonStr');
      } catch (e) {
        debugPrint('🤖 [AI] JSON格式化失败: $body');
      }
      debugPrint('🤖 [AI] ========== 响应数据结束 ==========');

      // 解析 ApiResponse 包装格式
      debugPrint('🤖 [AI] 开始解析响应数据...');
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        body,
        dataParser: (rawData) {
          if (rawData is Map<String, dynamic>) {
            return rawData;
          }
          return <String, dynamic>{};
        },
      );

      debugPrint('🤖 [AI] ApiResponse: success=${apiResponse.success}, code=${apiResponse.code}');

      if (!apiResponse.success) {
        debugPrint('🤖 [AI] ❌ API返回失败: ${apiResponse.message}');
        throw ApiException(
          message: apiResponse.message.isNotEmpty ? apiResponse.message : 'AI 查询失败',
          code: apiResponse.code,
        );
      }

      final aiData = apiResponse.data;
      if (aiData == null || aiData.isEmpty) {
        debugPrint('🤖 [AI] ❌ 错误: AI 服务返回数据为空');
        throw ApiException(message: 'AI 服务返回数据为空');
      }

      debugPrint('🤖 [AI] 成功解包 ApiResponse，实际数据字段: ${aiData.keys}');

      // 解析 AI 响应数据
      final aiResponse = AiQueryResponse.fromJson(aiData);
      
      final allProjects = aiResponse.searchTrials.projects;
      debugPrint('🤖 [AI] 解析完成，总项目数: ${allProjects.length}');
      
      // 输出所有项目的详细信息
      if (allProjects.isEmpty) {
        debugPrint('🤖 [AI] ⚠️ 警告：search_trials.projects 为空数组');
      } else {
        debugPrint('🤖 [AI] ========== 项目列表 ==========');
        for (var i = 0; i < allProjects.length; i++) {
          final project = allProjects[i];
          debugPrint('🤖 [AI] 项目${i + 1}:');
          debugPrint('🤖 [AI]   - project_code: ${project.projectCode}');
          debugPrint('🤖 [AI]   - project_name: ${project.projectName}');
          debugPrint('🤖 [AI]   - is_match: ${project.isMatch}');
          debugPrint('🤖 [AI]   - note: ${project.note.substring(0, project.note.length > 50 ? 50 : project.note.length)}...');
        }
        debugPrint('🤖 [AI] ========== 项目列表结束 ==========');
      }
      
      // 过滤出 is_match 为 true 的项目
      final matchedProjects = allProjects
          .where((project) => project.isMatch)
          .toList();

      debugPrint('🤖 [AI] 匹配项目筛选: ${allProjects.length} -> ${matchedProjects.length}');
      
      if (matchedProjects.isEmpty && allProjects.isNotEmpty) {
        debugPrint('🤖 [AI] ⚠️ 警告：所有项目的 is_match 都为 false，返回所有项目');
        // 如果没有匹配的项目，返回所有项目
        return allProjects;
      }

      debugPrint('🤖 [AI] ✅ 查询成功，返回 ${matchedProjects.length} 个匹配项目');
      
      return matchedProjects;
    } on DioException catch (error) {
      debugPrint('🤖 [AI] ❌ DioException: ${error.type}');
      debugPrint('🤖 [AI] ❌ 状态码: ${error.response?.statusCode}');
      debugPrint('🤖 [AI] ❌ 错误信息: ${error.message}');
      
      final dynamic responseBody = error.response?.data;
      String message = 'AI 服务请求失败';
      
      if (responseBody is Map<String, dynamic>) {
        message = responseBody['message'] as String? ?? message;
        debugPrint('🤖 [AI] ❌ 服务器返回: $message');
      } else if (error.message != null) {
        message = error.message!;
      }
      
      throw ApiException(message: message);
    } on ApiException {
      rethrow;
    } catch (error) {
      debugPrint('🤖 [AI] ❌ 未知错误: $error');
      throw ApiException(message: 'AI 查询结果解析失败: $error');
    }
  }

  /// 获取 AI 对话历史
  /// 
  /// [page] 页码（从 1 开始）
  /// [size] 每页数量
  /// [agent] 可选的 Agent 名称，用于筛选特定 Agent 的对话历史
  Future<PageResponse<AiSessionModel>> getAiHistory({
    int page = 1,
    int size = 20,
    String? agent,
  }) async {
    if (_apiClient == null) {
      throw ApiException(message: 'ApiClient 未初始化');
    }

    debugPrint('🤖 [AI] 开始获取对话历史: page=$page, size=$size, agent=$agent');

    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };
      
      // 如果指定了 agent，添加到查询参数中
      if (agent != null && agent.isNotEmpty) {
        queryParams['agent'] = agent;
      }

      final response = await _apiClient!.get(
        '/api/v1/ai/history',
        queryParameters: queryParams,
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final body = response.data;
      
      if (body == null) {
        throw ApiException(message: '获取对话历史失败');
      }

      debugPrint('🤖 [AI] 对话历史响应: ${body.keys}');

      // 解析 ApiResponse 包装格式
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        body,
        dataParser: (rawData) {
          if (rawData is Map<String, dynamic>) {
            return rawData;
          }
          return <String, dynamic>{};
        },
      );

      debugPrint('🤖 [AI] ApiResponse: success=${apiResponse.success}, code=${apiResponse.code}');

      if (!apiResponse.success) {
        throw ApiException(
          message: apiResponse.message.isNotEmpty ? apiResponse.message : '获取对话历史失败',
          code: apiResponse.code,
        );
      }

      final pageData = apiResponse.data;
      if (pageData == null) {
        debugPrint('🤖 [AI] 对话历史数据为空，返回空列表');
        return PageResponse.empty();
      }

      debugPrint('🤖 [AI] 分页数据字段: ${pageData.keys}');

      final result = PageResponse<AiSessionModel>.fromJson(
        pageData,
        (json) => AiSessionModel.fromJson(json as Map<String, dynamic>),
      );

      debugPrint('🤖 [AI] ✅ 获取对话历史成功，共 ${result.data.length} 条记录');

      return result;
    } on DioException catch (error) {
      debugPrint('🤖 [AI] ❌ 获取对话历史失败: ${error.type}');
      final dynamic responseBody = error.response?.data;
      String message = '获取对话历史失败';
      
      if (responseBody is Map<String, dynamic>) {
        message = responseBody['message'] as String? ?? message;
      } else if (error.message != null) {
        message = error.message!;
      }
      
      throw ApiException(message: message);
    } on ApiException {
      rethrow;
    } catch (error) {
      debugPrint('🤖 [AI] ❌ 解析对话历史失败: $error');
      throw ApiException(message: '获取对话历史失败: $error');
    }
  }

  /// 获取指定会话的记录
  /// 
  /// [sessionId] 会话 ID
  Future<List<AiChatLogModel>> getSessionHistory(String sessionId) async {
    if (_apiClient == null) {
      throw ApiException(message: 'ApiClient 未初始化');
    }

    debugPrint('🤖 [AI] 开始获取会话记录: sessionId=$sessionId');

    try {
      final response = await _apiClient!.get(
        '/api/v1/ai/session/$sessionId',
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final body = response.data;
      
      if (body == null) {
        throw ApiException(message: '获取会话记录失败');
      }

      debugPrint('🤖 [AI] 会话记录响应: ${body.keys}');

      // 解析 ApiResponse 包装格式
      final success = body['success'] as bool? ?? false;
      final code = body['code'] as String? ?? '';
      final message = body['message'] as String? ?? '';

      debugPrint('🤖 [AI] ApiResponse: success=$success, code=$code');

      if (!success) {
        throw ApiException(
          message: message.isNotEmpty ? message : '获取会话记录失败',
          code: code,
        );
      }

      // 从 data 字段获取聊天记录列表
      final dynamic rawData = body['data'];
      if (rawData == null) {
        debugPrint('🤖 [AI] 会话记录数据为空');
        return [];
      }

      final List<dynamic> dataList = rawData is List ? rawData : [];
      
      final result = dataList
          .whereType<Map<String, dynamic>>()
          .map((json) => AiChatLogModel.fromJson(json))
          .toList();

      debugPrint('🤖 [AI] ✅ 获取会话记录成功，共 ${result.length} 条记录');

      return result;
    } on DioException catch (error) {
      debugPrint('🤖 [AI] ❌ 获取会话记录失败: ${error.type}');
      final dynamic responseBody = error.response?.data;
      String message = '获取会话记录失败';
      
      if (responseBody is Map<String, dynamic>) {
        message = responseBody['message'] as String? ?? message;
      } else if (error.message != null) {
        message = error.message!;
      }
      
      throw ApiException(message: message);
    } on ApiException {
      rethrow;
    } catch (error) {
      debugPrint('🤖 [AI] ❌ 解析会话记录失败: $error');
      throw ApiException(message: '获取会话记录失败: $error');
    }
  }

  /// 查询患者关联项目
  /// 
  /// [patientIdentifier] 患者标识（住院号或姓名）
  /// 返回患者关联的项目列表
  Future<List<XiaobaiPatientProject>> queryPatientProjects(
    String patientIdentifier,
  ) async {
    if (_apiClient == null) {
      throw ApiException(message: 'ApiClient 未初始化');
    }

    debugPrint('🤖 [Xiaobai] 开始查询患者项目: $patientIdentifier');

    try {
      final response = await _apiClient!.post(
        '/api/v1/ai/patient-projects',
        data: {'patientIdentifier': patientIdentifier},
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final body = response.data;
      
      if (body == null) {
        throw ApiException(message: '查询患者项目失败');
      }

      debugPrint('🤖 [Xiaobai] 患者项目响应: ${body.keys}');

      // 解析 ApiResponse 包装格式
      final success = body['success'] as bool? ?? false;
      final code = body['code'] as String? ?? '';
      final message = body['message'] as String? ?? '';

      debugPrint('🤖 [Xiaobai] ApiResponse: success=$success, code=$code');

      if (!success) {
        throw ApiException(
          message: message.isNotEmpty ? message : '查询患者项目失败',
          code: code,
        );
      }

      // 从 data 字段获取项目列表
      final dynamic rawData = body['data'];
      if (rawData == null) {
        debugPrint('🤖 [Xiaobai] 患者项目数据为空');
        return [];
      }

      final List<dynamic> dataList = rawData is List ? rawData : [];
      
      final result = dataList
          .whereType<Map<String, dynamic>>()
          .map((json) => XiaobaiPatientProject.fromJson(json))
          .toList();

      debugPrint('🤖 [Xiaobai] ✅ 查询患者项目成功，共 ${result.length} 个项目');

      return result;
    } on DioException catch (error) {
      debugPrint('🤖 [Xiaobai] ❌ 查询患者项目失败: ${error.type}');
      final dynamic responseBody = error.response?.data;
      String message = '查询患者项目失败';
      
      if (responseBody is Map<String, dynamic>) {
        message = responseBody['message'] as String? ?? message;
      } else if (error.message != null) {
        message = error.message!;
      }
      
      throw ApiException(message: message);
    } on ApiException {
      rethrow;
    } catch (error) {
      debugPrint('🤖 [Xiaobai] ❌ 解析患者项目失败: $error');
      throw ApiException(message: '查询患者项目失败: $error');
    }
  }

  /// 小白Agent问答（非流式）
  /// 
  /// [question] 用户问题
  /// [projectId] 项目ID
  /// [patientName] 患者标识（可选）
  /// [sessionId] 会话ID（可选）
  /// 返回AI回答
  Future<XiaobaiQueryResponse> askXiaobai({
    required String question,
    required int projectId,
    String? patientName,
    String? sessionId,
  }) async {
    if (_apiClient == null) {
      throw ApiException(message: 'ApiClient 未初始化');
    }

    debugPrint('🤖 [Xiaobai] 开始问答');
    debugPrint('🤖 [Xiaobai] 问题: $question');
    debugPrint('🤖 [Xiaobai] 项目ID: $projectId');
    debugPrint('🤖 [Xiaobai] SessionID: ${sessionId ?? "无"}');

    try {
      final request = XiaobaiQueryRequest(
        question: question,
        projectId: projectId,
        patientName: patientName,
        sessionId: sessionId,
      );
      
      final startTime = DateTime.now();
      final response = await _apiClient!.post(
        '/api/v1/ai/xiaobai/ask',
        data: request.toJson(),
        options: Options(
          sendTimeout: const Duration(seconds: 120),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );
      final duration = DateTime.now().difference(startTime);
      
      debugPrint('🤖 [Xiaobai] 请求完成，耗时: ${duration.inSeconds}秒 (${duration.inMilliseconds}ms)');

      final body = response.data;
      
      if (body == null) {
        throw ApiException(message: '小白Agent未返回数据');
      }

      // 输出完整的响应 JSON
      debugPrint('🤖 [Xiaobai] ========== 响应数据开始 ==========');
      try {
        final jsonStr = const JsonEncoder.withIndent('  ').convert(body);
        debugPrint('🤖 [Xiaobai] $jsonStr');
      } catch (e) {
        debugPrint('🤖 [Xiaobai] JSON格式化失败: $body');
      }
      debugPrint('🤖 [Xiaobai] ========== 响应数据结束 ==========');

      // 解析 ApiResponse 包装格式
      final success = body['success'] as bool? ?? false;
      final code = body['code'] as String? ?? '';
      final message = body['message'] as String? ?? '';

      debugPrint('🤖 [Xiaobai] ApiResponse: success=$success, code=$code');

      if (!success) {
        throw ApiException(
          message: message.isNotEmpty ? message : '小白Agent问答失败',
          code: code,
        );
      }

      final data = body['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw ApiException(message: '小白Agent返回数据为空');
      }

      debugPrint('🤖 [Xiaobai] 成功解包 ApiResponse');

      // 解析小白Agent响应
      final result = XiaobaiQueryResponse.fromJson(data);

      debugPrint('🤖 [Xiaobai] ✅ 问答成功');

      return result;
    } on DioException catch (error) {
      debugPrint('🤖 [Xiaobai] ❌ DioException: ${error.type}');
      debugPrint('🤖 [Xiaobai] ❌ 状态码: ${error.response?.statusCode}');
      debugPrint('🤖 [Xiaobai] ❌ 错误信息: ${error.message}');
      
      final dynamic responseBody = error.response?.data;
      String message = '小白Agent请求失败';
      
      if (responseBody is Map<String, dynamic>) {
        message = responseBody['message'] as String? ?? message;
        debugPrint('🤖 [Xiaobai] ❌ 服务器返回: $message');
      } else if (error.message != null) {
        message = error.message!;
      }
      
      throw ApiException(message: message);
    } on ApiException {
      rethrow;
    } catch (error) {
      debugPrint('🤖 [Xiaobai] ❌ 未知错误: $error');
      throw ApiException(message: '小白Agent问答失败: $error');
    }
  }

  /// 获取小白Agent历史会话列表
  /// 
  /// [page] 页码（从 1 开始）
  /// [size] 每页数量
  Future<PageResponse<XiaobaiSessionModel>> getXiaobaiSessions({
    int page = 1,
    int size = 20,
  }) async {
    if (_apiClient == null) {
      throw ApiException(message: 'ApiClient 未初始化');
    }

    debugPrint('🤖 [Xiaobai] 开始获取会话列表: page=$page, size=$size');

    try {
      final response = await _apiClient!.get(
        '/api/v1/ai/xiaobai/sessions',
        queryParameters: {
          'page': page,
          'size': size,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final body = response.data;
      
      if (body == null) {
        throw ApiException(message: '获取会话列表失败');
      }

      debugPrint('🤖 [Xiaobai] 会话列表响应: ${body.keys}');

      // 解析 ApiResponse 包装格式
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        body,
        dataParser: (rawData) {
          if (rawData is Map<String, dynamic>) {
            return rawData;
          }
          return <String, dynamic>{};
        },
      );

      debugPrint('🤖 [Xiaobai] ApiResponse: success=${apiResponse.success}, code=${apiResponse.code}');

      if (!apiResponse.success) {
        throw ApiException(
          message: apiResponse.message.isNotEmpty ? apiResponse.message : '获取会话列表失败',
          code: apiResponse.code,
        );
      }

      final pageData = apiResponse.data;
      if (pageData == null) {
        debugPrint('🤖 [Xiaobai] 会话列表数据为空，返回空列表');
        return PageResponse.empty();
      }

      debugPrint('🤖 [Xiaobai] 分页数据字段: ${pageData.keys}');

      final result = PageResponse<XiaobaiSessionModel>.fromJson(
        pageData,
        (json) => XiaobaiSessionModel.fromJson(json as Map<String, dynamic>),
      );

      debugPrint('🤖 [Xiaobai] ✅ 获取会话列表成功，共 ${result.data.length} 条记录');

      return result;
    } on DioException catch (error) {
      debugPrint('🤖 [Xiaobai] ❌ 获取会话列表失败: ${error.type}');
      final dynamic responseBody = error.response?.data;
      String message = '获取会话列表失败';
      
      if (responseBody is Map<String, dynamic>) {
        message = responseBody['message'] as String? ?? message;
      } else if (error.message != null) {
        message = error.message!;
      }
      
      throw ApiException(message: message);
    } on ApiException {
      rethrow;
    } catch (error) {
      debugPrint('🤖 [Xiaobai] ❌ 解析会话列表失败: $error');
      throw ApiException(message: '获取会话列表失败: $error');
    }
  }

  /// 获取小白Agent会话详情
  /// 
  /// [sessionId] 会话ID
  Future<XiaobaiSessionDetailModel> getXiaobaiSessionDetail(String sessionId) async {
    if (_apiClient == null) {
      throw ApiException(message: 'ApiClient 未初始化');
    }

    debugPrint('🤖 [Xiaobai] 开始获取会话详情: sessionId=$sessionId');

    try {
      final response = await _apiClient!.get(
        '/api/v1/ai/xiaobai/sessions/$sessionId',
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final body = response.data;
      
      if (body == null) {
        throw ApiException(message: '获取会话详情失败');
      }

      debugPrint('🤖 [Xiaobai] 会话详情响应: ${body.keys}');

      // 解析 ApiResponse 包装格式
      final success = body['success'] as bool? ?? false;
      final code = body['code'] as String? ?? '';
      final message = body['message'] as String? ?? '';

      debugPrint('🤖 [Xiaobai] ApiResponse: success=$success, code=$code');

      if (!success) {
        throw ApiException(
          message: message.isNotEmpty ? message : '获取会话详情失败',
          code: code,
        );
      }

      // 从 data 字段获取会话详情
      final dynamic rawData = body['data'];
      if (rawData == null) {
        debugPrint('🤖 [Xiaobai] 会话详情数据为空');
        throw ApiException(message: '会话不存在');
      }

      final result = XiaobaiSessionDetailModel.fromJson(rawData as Map<String, dynamic>);

      debugPrint('🤖 [Xiaobai] ✅ 获取会话详情成功，共 ${result.messages.length} 条消息');

      return result;
    } on DioException catch (error) {
      debugPrint('🤖 [Xiaobai] ❌ 获取会话详情失败: ${error.type}');
      final dynamic responseBody = error.response?.data;
      String message = '获取会话详情失败';
      
      if (responseBody is Map<String, dynamic>) {
        message = responseBody['message'] as String? ?? message;
      } else if (error.message != null) {
        message = error.message!;
      }
      
      throw ApiException(message: message);
    } on ApiException {
      rethrow;
    } catch (error) {
      debugPrint('🤖 [Xiaobai] ❌ 解析会话详情失败: $error');
      throw ApiException(message: '获取会话详情失败: $error');
    }
  }
}

