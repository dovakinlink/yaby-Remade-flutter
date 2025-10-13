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
  String? _authToken;

  Future<Response<Map<String, dynamic>>> post(
    String path, {
    Map<String, dynamic>? data,
    Options? options,
  }) async {
    await _ensureBaseUrl();
    return dio.post<Map<String, dynamic>>(path, data: data, options: options);
  }

  Future<Response<Map<String, dynamic>>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    await _ensureBaseUrl();
    return dio.get<Map<String, dynamic>>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  void updateAuthToken(String? token) {
    _authToken = token;
    final headers = <String, dynamic>{...dio.options.headers};
    if (_authToken == null || _authToken!.isEmpty) {
      headers.remove('Authorization');
    } else {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    dio.options.headers = headers;
  }

  Map<String, String> getAuthHeaders() {
    if (_authToken != null && _authToken!.isNotEmpty) {
      return {'Authorization': 'Bearer $_authToken'};
    }
    return {};
  }

  Future<void> _ensureBaseUrl() async {
    final baseUrl = await EnvConfig.resolveApiBaseUrl();
    if (dio.options.baseUrl != baseUrl) {
      dio.options.baseUrl = baseUrl;
    }
  }

  Future<String> resolveUrl(String rawUrl) async {
    if (rawUrl.isEmpty) {
      return rawUrl;
    }
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      return rawUrl;
    }
    if (uri.hasScheme) {
      return rawUrl;
    }
    await _ensureBaseUrl();
    
    final base = dio.options.baseUrl.isNotEmpty
        ? dio.options.baseUrl
        : EnvConfig.initialBaseUrl;
    
    // 对于静态资源，使用不带端口的baseUrl
    final baseUrl = _isStaticResource(rawUrl) 
        ? _getStaticResourceBaseUrl(base)
        : base;
    
    final baseUri = Uri.tryParse(baseUrl);
    final target = Uri.tryParse(rawUrl);
    if (baseUri == null || target == null) {
      return rawUrl;
    }
    return baseUri.resolveUri(target).toString();
  }

  String resolveUrlSync(String rawUrl) {
    if (rawUrl.isEmpty) {
      return rawUrl;
    }
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || uri.hasScheme) {
      return rawUrl;
    }
    return _resolveWithBase(rawUrl);
  }

  String _resolveWithBase(String rawUrl) {
    final base = dio.options.baseUrl.isNotEmpty
        ? dio.options.baseUrl
        : EnvConfig.initialBaseUrl;
    
    // 对于静态资源（如图片、文件），使用不带端口的baseUrl
    // 因为静态资源服务器可能运行在不同的端口（通常是80）
    final baseUrl = _isStaticResource(rawUrl) 
        ? _getStaticResourceBaseUrl(base)
        : base;
    
    final baseUri = Uri.tryParse(baseUrl);
    final target = Uri.tryParse(rawUrl);
    if (baseUri == null || target == null) {
      return rawUrl;
    }
    return baseUri.resolveUri(target).toString();
  }
  
  bool _isStaticResource(String url) {
    // 识别各种静态资源路径模式
    if (url.startsWith('/uploads/') || 
        url.startsWith('/files/') ||
        url.startsWith('/static/') ||
        url.startsWith('/api/v1/files/') ||
        url.contains('/uploads/') ||
        url.contains('/files/')) {
      return true;
    }
    
    // 识别日期格式的文件路径 (如: 2025/10/11/xxx.jpg)
    final datePathPattern = RegExp(r'^\d{4}/\d{2}/\d{2}/');
    if (datePathPattern.hasMatch(url)) {
      return true;
    }
    
    // 识别常见的文件扩展名
    final fileExtensions = [
      '.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.svg',  // 图片
      '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', // 文档
      '.txt', '.md', '.csv',                                       // 文本
      '.mp4', '.avi', '.mov', '.mkv', '.webm',                    // 视频
      '.mp3', '.wav', '.ogg',                                      // 音频
      '.zip', '.rar', '.7z', '.tar', '.gz',                       // 压缩包
    ];
    
    final lowerUrl = url.toLowerCase();
    for (final ext in fileExtensions) {
      if (lowerUrl.endsWith(ext)) {
        return true;
      }
    }
    
    return false;
  }
  
  String _getStaticResourceBaseUrl(String apiBaseUrl) {
    // 从API baseUrl中提取主机地址，去掉端口号
    // 例如: http://127.0.0.1:8090 -> http://127.0.0.1
    final uri = Uri.tryParse(apiBaseUrl);
    if (uri == null) {
      return apiBaseUrl;
    }
    
    // 构建不带端口的URL（使用默认端口80）
    return Uri(
      scheme: uri.scheme,
      host: uri.host,
    ).toString();
  }
}
