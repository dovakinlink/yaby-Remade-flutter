# 用户注册 API 文档

本文档描述用户注册相关的API接口，用于移动端（iOS/Android）应用实现用户注册功能。

## 目录

- [接口概览](#接口概览)
- [1. 用户注册](#1-用户注册)
- [数据模型](#数据模型)
- [使用场景](#使用场景)
- [注意事项](#注意事项)
- [错误码说明](#错误码说明)

---

## 接口概览

| 接口 | 方法 | 路径 | 说明 |
|------|------|------|------|
| 用户注册 | POST | `/api/v1/auth/sign-up` | 创建新用户账户，注册成功后自动返回JWT令牌 |

---

## 1. 用户注册

**接口描述**: 创建新用户账户，注册成功后自动返回JWT令牌，用户可直接使用令牌进行后续操作。

**注意**: 
- 此注册功能主要用于苹果 App Connect 审核
- 注册的新用户默认归属 `orgId=3` 的组织
- 人员姓名默认为注册时填写的用户名
- 注册成功后会自动创建人员记录（t_person）并关联到用户

- **URL**: `/api/v1/auth/sign-up`
- **方法**: `POST`
- **认证**: 不需要认证（公开接口）

### 请求参数

**请求体 (JSON)**:

| 参数名 | 类型 | 必填 | 说明 | 示例 |
|--------|------|------|------|------|
| username | String | 是 | 登录用户名，4-50字符，唯一 | "testuser123" |
| password | String | 是 | 登录密码，6-100字符 | "password123" |
| nickname | String | 否 | 用户昵称，最大50字符，不填则使用用户名 | "测试用户" |

### 请求示例

```http
POST /api/v1/auth/sign-up
Content-Type: application/json

{
  "username": "testuser123",
  "password": "password123",
  "nickname": "测试用户"
}
```

### 响应示例

**成功响应 (200)**:

```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**错误响应 - 用户名已存在 (200)**:

```json
{
  "success": false,
  "code": "USER_EXISTS",
  "message": "用户名已被占用",
  "data": null
}
```

**错误响应 - 参数校验失败 (200)**:

```json
{
  "success": false,
  "code": "INVALID_PARAM",
  "message": "username is required; password length must be between 6 and 100",
  "data": null
}
```

### Flutter 调用示例

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthApiService {
  final String baseUrl = 'http://your-server.com/api/v1';
  
  /// 用户注册
  /// 
  /// [username] 登录用户名，4-50字符
  /// [password] 登录密码，6-100字符
  /// [nickname] 用户昵称，可选
  /// 
  /// 返回 [AuthResponse] 包含 accessToken 和 refreshToken
  Future<ApiResponse<AuthResponse>> register({
    required String username,
    required String password,
    String? nickname,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/sign-up'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
          if (nickname != null) 'nickname': nickname,
        }),
      );
      
      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      final apiResponse = ApiResponse<AuthResponse>.fromJson(jsonResponse);
      
      if (apiResponse.success) {
        // 注册成功，保存令牌到本地存储
        await _saveTokens(apiResponse.data!);
        return apiResponse;
      } else {
        // 注册失败，返回错误信息
        return apiResponse;
      }
    } catch (e) {
      return ApiResponse<AuthResponse>(
        success: false,
        code: 'NETWORK_ERROR',
        message: '网络请求失败: ${e.toString()}',
      );
    }
  }
  
  /// 保存令牌到本地存储
  Future<void> _saveTokens(AuthResponse authResponse) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', authResponse.accessToken);
    await prefs.setString('refresh_token', authResponse.refreshToken);
  }
}

/// 认证响应数据模型
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  
  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
  });
  
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }
}

/// API响应包装类
class ApiResponse<T> {
  final bool success;
  final String code;
  final String message;
  final T? data;
  
  ApiResponse({
    required this.success,
    required this.code,
    required this.message,
    this.data,
  });
  
  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse<T>(
      success: json['success'] as bool,
      code: json['code'] as String,
      message: json['message'] as String,
      data: json['data'] != null ? AuthResponse.fromJson(json['data']) as T : null,
    );
  }
}
```

### iOS (Swift) 调用示例

```swift
import Foundation

struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
}

struct ApiResponse<T: Codable>: Codable {
    let success: Bool
    let code: String
    let message: String
    let data: T?
}

class AuthApiService {
    let baseURL = "http://your-server.com/api/v1"
    
    /// 用户注册
    func register(username: String, password: String, nickname: String? = nil) async throws -> ApiResponse<AuthResponse> {
        let url = URL(string: "\(baseURL)/auth/sign-up")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [
            "username": username,
            "password": password
        ]
        if let nickname = nickname {
            body["nickname"] = nickname
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ApiResponse<AuthResponse>.self, from: data)
        
        if response.success, let authData = response.data {
            // 保存令牌到本地存储
            UserDefaults.standard.set(authData.accessToken, forKey: "access_token")
            UserDefaults.standard.set(authData.refreshToken, forKey: "refresh_token")
        }
        
        return response
    }
}
```

### Android (Kotlin) 调用示例

```kotlin
import com.google.gson.Gson
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import java.io.IOException

data class AuthResponse(
    val accessToken: String,
    val refreshToken: String
)

data class ApiResponse<T>(
    val success: Boolean,
    val code: String,
    val message: String,
    val data: T?
)

class AuthApiService(private val baseUrl: String = "http://your-server.com/api/v1") {
    private val client = OkHttpClient()
    private val gson = Gson()
    
    /**
     * 用户注册
     */
    fun register(
        username: String,
        password: String,
        nickname: String? = null,
        callback: (ApiResponse<AuthResponse>) -> Unit
    ) {
        val url = "$baseUrl/auth/sign-up"
        val requestBody = mapOf(
            "username" to username,
            "password" to password,
            *if (nickname != null) arrayOf("nickname" to nickname) else emptyArray()
        )
        
        val json = gson.toJson(requestBody)
        val mediaType = "application/json".toMediaType()
        val body = json.toRequestBody(mediaType)
        
        val request = Request.Builder()
            .url(url)
            .post(body)
            .addHeader("Content-Type", "application/json")
            .build()
        
        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                callback(ApiResponse(
                    success = false,
                    code = "NETWORK_ERROR",
                    message = "网络请求失败: ${e.message}",
                    data = null
                ))
            }
            
            override fun onResponse(call: Call, response: Response) {
                val responseBody = response.body?.string()
                val apiResponse = gson.fromJson(responseBody, ApiResponse::class.java)
                
                if (apiResponse.success && apiResponse.data != null) {
                    // 保存令牌到本地存储
                    val authData = gson.fromJson(
                        gson.toJson(apiResponse.data),
                        AuthResponse::class.java
                    )
                    val prefs = context.getSharedPreferences("auth", Context.MODE_PRIVATE)
                    prefs.edit()
                        .putString("access_token", authData.accessToken)
                        .putString("refresh_token", authData.refreshToken)
                        .apply()
                }
                
                callback(apiResponse)
            }
        })
    }
}
```

---

## 数据模型

### UserRegisterRequest

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| username | String | 是 | 登录用户名，4-50字符，唯一 |
| password | String | 是 | 登录密码，6-100字符 |
| nickname | String | 否 | 用户昵称，最大50字符，不填则使用用户名 |

### AuthResponse

| 字段 | 类型 | 说明 |
|------|------|------|
| accessToken | String | 访问令牌，用于后续API请求的认证 |
| refreshToken | String | 刷新令牌，用于刷新访问令牌 |

---

## 使用场景

### 1. 新用户注册

用户在移动端应用填写注册信息（用户名、密码、昵称），提交后调用注册接口。注册成功后：
- 自动创建用户账户（t_user）
- 自动创建人员记录（t_person），姓名为用户名
- 自动绑定到组织（orgId=3）
- 返回JWT令牌，用户可直接使用令牌进行后续操作

### 2. 苹果 App Connect 审核

此注册功能主要用于苹果 App Connect 审核，审核人员可以通过注册接口创建测试账户。

---

## 注意事项

1. **用户名唯一性**: 用户名在系统中必须唯一，如果用户名已存在，注册会失败并返回 `USER_EXISTS` 错误。

2. **密码安全**: 
   - 密码长度必须在 6-100 字符之间
   - 密码在服务端使用 MD5 加密存储
   - 建议客户端对密码进行适当的安全处理

3. **默认组织**: 所有通过注册接口创建的用户都会自动归属到 `orgId=3` 的组织，无需在注册时指定。

4. **人员记录**: 注册时会自动创建人员记录（t_person），人员姓名为注册时填写的用户名。

5. **令牌存储**: 注册成功后返回的 `accessToken` 和 `refreshToken` 需要客户端妥善保存，用于后续API请求的认证。

6. **令牌使用**: 
   - `accessToken` 用于后续API请求的认证，需要在请求头中携带：`Authorization: Bearer {accessToken}`
   - `refreshToken` 用于刷新访问令牌，当 `accessToken` 过期时可以使用刷新令牌获取新的访问令牌

7. **错误处理**: 客户端应该妥善处理各种错误情况，包括网络错误、参数校验错误、用户名已存在等。

---

## 错误码说明

| 错误码 | HTTP状态码 | 说明 | 解决方案 |
|--------|-----------|------|----------|
| SUCCESS | 200 | 注册成功 | - |
| USER_EXISTS | 200 | 用户名已被占用 | 提示用户更换用户名 |
| INVALID_PARAM | 200 | 参数校验失败 | 检查请求参数是否符合要求 |
| NETWORK_ERROR | - | 网络请求失败 | 检查网络连接，重试请求 |

---

## 相关接口

- [用户登录 API](./USER_PROFILE_API.md#用户登录) - 已注册用户登录
- [用户信息 API](./USER_PROFILE_API.md) - 查询和更新用户信息
- [令牌刷新 API](./USER_PROFILE_API.md#令牌刷新) - 刷新访问令牌

---

## 更新日志

- **2026-01-28**: 初始版本，实现用户注册功能，支持苹果 App Connect 审核
