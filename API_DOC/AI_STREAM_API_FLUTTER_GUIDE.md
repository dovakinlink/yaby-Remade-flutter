# AI 流式接口 Flutter 对接指南

## 📖 文档概述

本文档详细说明如何在 Flutter 应用中调用 AI 流式接口（基于 Server-Sent Events, SSE）。

**⚠️ 重要提示**：所有 AI 流式接口都需要 JWT Token 认证，未携带或携带无效 Token 会导致请求失败（401 Unauthorized）。

---

## 🔐 认证要求

### JWT Token 认证说明

所有 AI API 接口（包括流式接口）都受 Spring Security 保护，必须在请求头中携带有效的 JWT Access Token：

```
Authorization: Bearer <your_access_token>
```

### 认证流程

1. **用户登录**：调用 `/api/v1/auth/login` 获取 JWT Token
2. **携带 Token**：在所有 AI 请求的 `Authorization` 头中携带 Token
3. **Token 刷新**：Token 过期时调用 `/api/v1/auth/refresh` 刷新 Token

### 安全配置

根据后端 `SecurityConfig.java` 配置：
- ✅ 所有 `/api/v1/ai/**` 接口都需要认证
- ✅ JWT 通过 `JwtAuthenticationFilter` 自动验证
- ✅ 认证失败会返回 401 状态码
- ✅ SSE 流式请求同样需要 JWT 认证

---

## 📡 流式接口概览

### 可用的流式 AI 接口

| 接口路径 | 功能说明 | 超时时间 | 需要认证 |
|---------|---------|---------|---------|
| `POST /api/v1/ai/query-stream` | 临床试验项目智能匹配（流式） | 60秒 | ✅ 是 |
| `POST /api/v1/ai/xiaobai/ask-stream` | 小白Agent知识库问答（流式） | 120秒 | ✅ 是 |

### SSE 响应格式

```
event: message
data: {"text": "这是AI返回的文本片段"}

event: message
data: {"text": "下一个文本片段"}

event: done
data: {}
```

---

## 🚀 Flutter 完整实现

### 1. 依赖配置

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0  # 用于HTTP请求
```

### 2. AI Service 封装类

创建 `ai_service.dart`：

```dart
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

/// AI流式服务类
/// 
/// 负责与后端AI流式接口通信
/// 所有请求都需要JWT Token认证
class AiStreamService {
  final String baseUrl;
  final String accessToken;
  
  AiStreamService({
    required this.baseUrl,
    required this.accessToken,
  });
  
  /// AI 项目查询（流式）
  /// 
  /// [question] 用户的问题
  /// [orgId] 组织ID
  /// [disciplineId] 学科ID（可选）
  /// [sessionId] 会话ID（可选，不传则自动生成）
  /// [onData] 接收到数据时的回调
  /// [onDone] 流结束时的回调
  /// [onError] 出错时的回调
  /// 
  /// 返回一个 StreamSubscription，可用于取消请求
  Future<StreamSubscription?> queryAiStream({
    required String question,
    required int orgId,
    int? disciplineId,
    String? sessionId,
    required Function(String text) onData,
    required Function() onDone,
    required Function(dynamic error) onError,
  }) async {
    // 构建输入文本
    String inputAsText = 'orgId:$orgId';
    if (disciplineId != null) {
      inputAsText += ',disciplineId:$disciplineId';
    }
    inputAsText += ',$question';
    
    // 生成会话ID（如果未提供）
    final effectiveSessionId = sessionId ?? 
        'session-${DateTime.now().millisecondsSinceEpoch}';
    
    try {
      return await _sendSseRequest(
        url: '$baseUrl/api/v1/ai/query-stream',
        body: {
          'inputAsText': inputAsText,
          'sessionId': effectiveSessionId,
        },
        onData: onData,
        onDone: onDone,
        onError: onError,
      );
    } catch (e) {
      onError(e);
      return null;
    }
  }
  
  /// 小白 Agent 流式问答
  /// 
  /// [question] 问题内容
  /// [projectId] 项目ID
  /// [patientName] 患者姓名（可选）
  /// [sessionId] 会话ID（可选，不传则自动生成）
  /// [onData] 接收到数据时的回调
  /// [onDone] 流结束时的回调
  /// [onError] 出错时的回调
  /// 
  /// 返回一个 StreamSubscription，可用于取消请求
  Future<StreamSubscription?> askXiaobaiStream({
    required String question,
    required int projectId,
    String? patientName,
    String? sessionId,
    required Function(String text) onData,
    required Function() onDone,
    required Function(dynamic error) onError,
  }) async {
    // 生成会话ID（如果未提供）
    final effectiveSessionId = sessionId ?? 
        'xiaobai-session-${DateTime.now().millisecondsSinceEpoch}';
    
    try {
      return await _sendSseRequest(
        url: '$baseUrl/api/v1/ai/xiaobai/ask-stream',
        body: {
          'question': question,
          'projectId': projectId,
          if (patientName != null) 'patientName': patientName,
          'sessionId': effectiveSessionId,
        },
        onData: onData,
        onDone: onDone,
        onError: onError,
      );
    } catch (e) {
      onError(e);
      return null;
    }
  }
  
  /// 发送SSE流式请求（内部方法）
  /// 
  /// 处理所有流式请求的通用逻辑：
  /// 1. 设置正确的请求头（包括JWT Token）
  /// 2. 发送POST请求
  /// 3. 解析SSE响应流
  /// 4. 处理不同的事件类型
  /// 
  /// ⚠️ 关键点：必须在请求头中携带 Authorization: Bearer <token>
  Future<StreamSubscription?> _sendSseRequest({
    required String url,
    required Map<String, dynamic> body,
    required Function(String text) onData,
    required Function() onDone,
    required Function(dynamic error) onError,
  }) async {
    final client = http.Client();
    
    try {
      // 创建POST请求
      final request = http.Request('POST', Uri.parse(url));
      
      // ⚠️ 重要：设置请求头，必须包含JWT Token
      request.headers.addAll({
        'Authorization': 'Bearer $accessToken',  // 🔑 JWT认证
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',  // 接受SSE格式
      });
      
      // 设置请求体
      request.body = jsonEncode(body);
      
      // 发送请求
      final response = await client.send(request);
      
      // 检查HTTP状态码
      if (response.statusCode == 401) {
        // JWT认证失败
        client.close();
        onError('认证失败：JWT Token无效或已过期，请重新登录');
        return null;
      } else if (response.statusCode == 403) {
        // 权限不足
        client.close();
        onError('权限不足：无权访问该资源');
        return null;
      } else if (response.statusCode != 200) {
        // 其他错误
        client.close();
        onError('请求失败：HTTP ${response.statusCode}');
        return null;
      }
      
      // 解析SSE流
      final subscription = response.stream
        .transform(utf8.decoder)  // 字节流 -> 字符串
        .transform(const LineSplitter())  // 字符串 -> 行
        .listen(
          (line) {
            try {
              // 解析SSE事件
              if (line.startsWith('data: ')) {
                // 提取data字段内容
                final data = line.substring(6);
                
                // 跳过空数据
                if (data.isEmpty || data == '{}') {
                  return;
                }
                
                // 解析JSON数据
                final jsonData = jsonDecode(data);
                
                // 提取文本内容并回调
                if (jsonData['text'] != null) {
                  onData(jsonData['text']);
                }
              } else if (line.startsWith('event: done')) {
                // 流结束事件
                onDone();
                client.close();
              }
            } catch (e) {
              // 解析单行数据出错，记录但不中断流
              print('解析SSE数据出错: $e, 原始行: $line');
            }
          },
          onError: (error) {
            // 流错误
            onError(error);
            client.close();
          },
          onDone: () {
            // 流正常结束
            onDone();
            client.close();
          },
          cancelOnError: true,  // 出错时取消订阅
        );
      
      return subscription;
    } catch (e) {
      // 请求发送失败
      client.close();
      onError(e);
      return null;
    }
  }
}
```

### 3. 在 UI 中使用

创建 `ai_chat_page.dart`：

```dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'ai_service.dart';

/// AI 聊天页面
/// 
/// 展示如何在UI中使用流式AI服务
class AiChatPage extends StatefulWidget {
  final String accessToken;
  final int orgId;
  final int? disciplineId;
  
  const AiChatPage({
    Key? key,
    required this.accessToken,
    required this.orgId,
    this.disciplineId,
  }) : super(key: key);
  
  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  late AiStreamService _aiService;
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String _aiResponse = '';
  bool _isLoading = false;
  StreamSubscription? _currentSubscription;
  
  @override
  void initState() {
    super.initState();
    _aiService = AiStreamService(
      baseUrl: 'http://your-server-url:8090',  // 替换为实际服务器地址
      accessToken: widget.accessToken,
    );
  }
  
  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    _currentSubscription?.cancel();
    super.dispose();
  }
  
  /// 提交问题
  Future<void> _askQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入问题')),
      );
      return;
    }
    
    // 防止重复提交
    if (_isLoading) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _aiResponse = '';
    });
    
    // 发送流式请求
    _currentSubscription = await _aiService.queryAiStream(
      question: question,
      orgId: widget.orgId,
      disciplineId: widget.disciplineId,
      onData: (text) {
        // 实时追加接收到的文本
        setState(() {
          _aiResponse += text;
        });
        
        // 自动滚动到底部
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      },
      onDone: () {
        setState(() {
          _isLoading = false;
        });
        print('AI 响应完成');
      },
      onError: (error) {
        setState(() {
          _isLoading = false;
        });
        
        // 处理认证错误
        if (error.toString().contains('认证失败') || 
            error.toString().contains('JWT Token')) {
          // Token过期，跳转到登录页面
          _showErrorDialog('登录已过期', '您的登录状态已过期，请重新登录');
          // TODO: 导航到登录页面
          // Navigator.pushReplacementNamed(context, '/login');
        } else {
          _showErrorDialog('出错了', error.toString());
        }
      },
    );
  }
  
  /// 取消当前请求
  void _cancelRequest() {
    _currentSubscription?.cancel();
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已取消请求')),
    );
  }
  
  /// 显示错误对话框
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 项目查询'),
        actions: [
          if (_isLoading)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _cancelRequest,
              tooltip: '取消请求',
            ),
        ],
      ),
      body: Column(
        children: [
          // AI 响应显示区域
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_aiResponse.isEmpty && !_isLoading)
                    const Center(
                      child: Text(
                        '请输入问题，开始查询...',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  if (_aiResponse.isNotEmpty)
                    SelectableText(
                      _aiResponse,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  if (_isLoading && _aiResponse.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // 加载指示器
          if (_isLoading)
            const LinearProgressIndicator(),
          
          // 输入框
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _questionController,
                      decoration: const InputDecoration(
                        hintText: '输入您的问题...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.send,
                      enabled: !_isLoading,
                      onSubmitted: (_) => _askQuestion(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(_isLoading ? Icons.stop : Icons.send),
                    onPressed: _isLoading ? _cancelRequest : _askQuestion,
                    color: Theme.of(context).primaryColor,
                    iconSize: 28,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### 4. Token 管理示例

创建 `auth_manager.dart`：

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 认证管理器
/// 
/// 负责JWT Token的存储、获取和刷新
class AuthManager {
  static const _storage = FlutterSecureStorage();
  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  
  /// 保存Token
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
  }
  
  /// 获取Access Token
  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }
  
  /// 获取Refresh Token
  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }
  
  /// 清除Token（登出）
  static Future<void> clearTokens() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
  }
  
  /// 检查Token是否存在
  static Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
```

---

## 🔧 常见问题和解决方案

### 1. 401 Unauthorized 错误

**问题**：请求返回 401 状态码

**原因**：
- JWT Token 未携带
- JWT Token 格式错误
- JWT Token 已过期
- JWT Token 无效

**解决方案**：

```dart
// 方案1：检查Token是否正确设置
final token = await AuthManager.getAccessToken();
if (token == null || token.isEmpty) {
  // 跳转到登录页面
  Navigator.pushReplacementNamed(context, '/login');
  return;
}

// 方案2：Token过期时自动刷新
Future<String?> getValidAccessToken() async {
  String? token = await AuthManager.getAccessToken();
  
  // 检查Token是否过期（可选：解析JWT payload检查exp字段）
  if (isTokenExpired(token)) {
    // 使用RefreshToken刷新
    final newToken = await refreshAccessToken();
    if (newToken != null) {
      await AuthManager.saveTokens(
        accessToken: newToken,
        refreshToken: await AuthManager.getRefreshToken() ?? '',
      );
      return newToken;
    } else {
      // 刷新失败，需要重新登录
      await AuthManager.clearTokens();
      return null;
    }
  }
  
  return token;
}
```

### 2. 流式连接中断

**问题**：SSE连接突然中断

**原因**：
- 网络不稳定
- 服务器超时
- Token在请求过程中过期

**解决方案**：

```dart
// 添加重试机制
Future<void> _askQuestionWithRetry({int maxRetries = 3}) async {
  int retryCount = 0;
  
  while (retryCount < maxRetries) {
    try {
      // 获取最新的有效Token
      final token = await getValidAccessToken();
      if (token == null) {
        _showErrorDialog('登录已过期', '请重新登录');
        return;
      }
      
      // 更新Service的Token
      _aiService = AiStreamService(
        baseUrl: _baseUrl,
        accessToken: token,
      );
      
      // 发送请求
      await _askQuestion();
      break;  // 成功，退出循环
    } catch (e) {
      retryCount++;
      if (retryCount >= maxRetries) {
        _showErrorDialog('请求失败', '已重试$maxRetries次，请稍后再试');
      } else {
        // 等待后重试
        await Future.delayed(Duration(seconds: 2));
      }
    }
  }
}
```

### 3. 响应数据格式错误

**问题**：解析SSE数据时出错

**原因**：
- 后端返回的数据格式不是标准JSON
- 网络传输过程中数据损坏

**解决方案**：

```dart
// 增强错误处理
if (line.startsWith('data: ')) {
  final data = line.substring(6);
  
  if (data.isEmpty || data == '{}') {
    return;
  }
  
  try {
    final jsonData = jsonDecode(data);
    if (jsonData is Map && jsonData['text'] != null) {
      onData(jsonData['text']);
    } else {
      print('数据格式不正确: $jsonData');
    }
  } catch (e) {
    // 记录错误但不中断流
    print('解析JSON出错: $e, 原始数据: $data');
  }
}
```

### 4. 内存泄漏

**问题**：频繁调用导致内存占用增长

**原因**：
- StreamSubscription 未正确取消
- http.Client 未关闭

**解决方案**：

```dart
class _AiChatPageState extends State<AiChatPage> {
  StreamSubscription? _currentSubscription;
  
  @override
  void dispose() {
    // 确保取消订阅
    _currentSubscription?.cancel();
    super.dispose();
  }
  
  Future<void> _askQuestion() async {
    // 取消之前的请求
    await _currentSubscription?.cancel();
    
    // 发送新请求
    _currentSubscription = await _aiService.queryAiStream(...);
  }
}
```

---

## 📱 完整的应用示例

### 主应用入口

```dart
import 'package:flutter/material.dart';
import 'auth_manager.dart';
import 'ai_chat_page.dart';
import 'login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI 项目查询',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AppHomePage(),
      routes: {
        '/login': (context) => const LoginPage(),
      },
    );
  }
}

class AppHomePage extends StatefulWidget {
  const AppHomePage({Key? key}) : super(key: key);

  @override
  State<AppHomePage> createState() => _AppHomePageState();
}

class _AppHomePageState extends State<AppHomePage> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final hasToken = await AuthManager.hasValidToken();
    setState(() {
      _isAuthenticated = hasToken;
      _isLoading = false;
    });

    if (!hasToken) {
      // 跳转到登录页面
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isAuthenticated) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<String?>(
      future: AuthManager.getAccessToken(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return AiChatPage(
          accessToken: snapshot.data!,
          orgId: 1,  // 从用户信息获取
          disciplineId: 2,  // 可选
        );
      },
    );
  }
}
```

---

## ⚡ 性能优化建议

### 1. Token 缓存

```dart
class TokenCache {
  static String? _cachedToken;
  static DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 5);
  
  static Future<String?> getToken() async {
    // 检查缓存是否有效
    if (_cachedToken != null && 
        _cacheTime != null && 
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cachedToken;
    }
    
    // 从存储获取
    _cachedToken = await AuthManager.getAccessToken();
    _cacheTime = DateTime.now();
    return _cachedToken;
  }
  
  static void clearCache() {
    _cachedToken = null;
    _cacheTime = null;
  }
}
```

### 2. 请求去重

```dart
class AiRequestManager {
  static final Map<String, StreamSubscription> _activeRequests = {};
  
  static Future<StreamSubscription?> sendRequest(
    String requestId,
    Future<StreamSubscription?> Function() requestBuilder,
  ) async {
    // 取消同ID的旧请求
    await _activeRequests[requestId]?.cancel();
    
    // 发送新请求
    final subscription = await requestBuilder();
    if (subscription != null) {
      _activeRequests[requestId] = subscription;
      
      // 请求完成后清理
      subscription.onDone(() {
        _activeRequests.remove(requestId);
      });
    }
    
    return subscription;
  }
}
```

### 3. 文本增量渲染优化

```dart
class StreamingTextWidget extends StatefulWidget {
  final Stream<String> textStream;
  
  const StreamingTextWidget({Key? key, required this.textStream}) 
      : super(key: key);
  
  @override
  State<StreamingTextWidget> createState() => _StreamingTextWidgetState();
}

class _StreamingTextWidgetState extends State<StreamingTextWidget> {
  final StringBuffer _buffer = StringBuffer();
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: widget.textStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _buffer.write(snapshot.data);
        }
        
        return SelectableText(
          _buffer.toString(),
          style: const TextStyle(fontSize: 16, height: 1.5),
        );
      },
    );
  }
}
```

---

## 🔒 安全最佳实践

### 1. Token 安全存储

```dart
// 使用 flutter_secure_storage
// pubspec.yaml:
// dependencies:
//   flutter_secure_storage: ^9.0.0

import 'package:flutter_secure_storage/flutter_secure_storage';

const storage = FlutterSecureStorage();

// 保存Token（加密存储）
await storage.write(key: 'access_token', value: token);

// 读取Token
final token = await storage.read(key: 'access_token');
```

### 2. HTTPS 通信

```dart
// 生产环境必须使用HTTPS
class ApiConfig {
  static const String baseUrl = 
      kDebugMode 
          ? 'http://localhost:8090'  // 开发环境
          : 'https://api.yourdomain.com';  // 生产环境
}
```

### 3. Token 自动刷新

```dart
class AuthInterceptor {
  static Future<String?> getValidToken() async {
    String? token = await AuthManager.getAccessToken();
    
    // 检查是否即将过期（提前5分钟刷新）
    if (token != null && willExpireSoon(token)) {
      // 刷新Token
      final newToken = await _refreshToken();
      if (newToken != null) {
        await AuthManager.saveTokens(
          accessToken: newToken,
          refreshToken: await AuthManager.getRefreshToken() ?? '',
        );
        return newToken;
      }
    }
    
    return token;
  }
  
  static bool willExpireSoon(String token) {
    // 解析JWT payload，检查exp字段
    // 实现略
    return false;
  }
}
```

---

## 📚 参考资源

### 相关文档

- [AI API 完整文档](./AI_API.md)
- [用户认证 API 文档](./API_DOCS.md)
- [Flutter HTTP 包文档](https://pub.dev/packages/http)

### 后端接口

- `POST /api/v1/auth/login` - 用户登录
- `POST /api/v1/auth/refresh` - 刷新Token
- `POST /api/v1/ai/query-stream` - AI项目查询（流式）
- `POST /api/v1/ai/xiaobai/ask-stream` - 小白Agent问答（流式）

### 技术栈

- **协议**: Server-Sent Events (SSE)
- **认证**: JWT (JSON Web Token)
- **传输**: HTTP/HTTPS
- **数据格式**: JSON

---

## 📝 版本历史

- **v1.0.0** (2025-01-02)
  - 初始版本
  - 详细说明JWT认证要求
  - 提供完整的Flutter实现示例
  - 包含常见问题解决方案

---

## 💡 技术支持

如有问题，请联系开发团队或查看相关文档。

**重要提醒**：
- ✅ 所有流式接口都需要JWT Token认证
- ✅ Token必须放在 `Authorization: Bearer <token>` 头中
- ✅ 401错误表示Token无效，需要重新登录或刷新Token
- ✅ 建议实现Token自动刷新机制，提升用户体验
