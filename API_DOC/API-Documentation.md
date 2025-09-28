# 用户认证 API 文档

## 基础信息

- **服务器地址**: `http://localhost:8090`
- **API版本**: v1
- **内容类型**: `application/json`
- **编码格式**: `UTF-8`

## 统一响应格式

所有API接口都使用统一的响应格式：

```json
{
  "success": boolean,    // 请求是否成功
  "code": "string",      // 响应代码
  "message": "string",   // 响应消息
  "data": object         // 响应数据（成功时有值，失败时为null）
}
```

## 认证接口

### 1. 用户注册

**接口描述**: 注册新用户账户，注册成功后自动返回JWT令牌

- **URL**: `/api/v1/auth/sign-up`
- **方法**: `POST`
- **认证**: 无需认证

#### 请求参数

```json
{
  "username": "string",    // 用户名，必填，4-50字符
  "password": "string",    // 密码，必填，6-100字符
  "nickname": "string",    // 昵称，可选，最大50字符
  "orgId": number          // 组织ID，必填，长整型
}
```

#### 响应示例

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

**失败响应 (200)**:
```json
{
  "success": false,
  "code": "USER_EXISTS",
  "message": "用户名已被占用",
  "data": null
}
```

#### Flutter 调用示例

```dart
final response = await http.post(
  Uri.parse('http://localhost:8090/api/v1/auth/sign-up'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'username': 'test001',
    'password': '123456',
    'nickname': '测试用户',
    'orgId': 1
  }),
);

final data = jsonDecode(response.body);
if (data['success']) {
  final accessToken = data['data']['accessToken'];
  final refreshToken = data['data']['refreshToken'];
  // 保存token到本地存储
}
```

### 2. 用户登录

**接口描述**: 验证用户名和密码，登录成功后返回JWT令牌

- **URL**: `/api/v1/auth/sign-in`
- **方法**: `POST`
- **认证**: 无需认证

#### 请求参数

```json
{
  "username": "string",    // 用户名，必填
  "password": "string"     // 密码，必填
}
```

#### 响应示例

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

**失败响应 (200)**:
```json
{
  "success": false,
  "code": "BAD_CREDENTIALS",
  "message": "用户名或密码错误",
  "data": null
}
```

#### Flutter 调用示例

```dart
final response = await http.post(
  Uri.parse('http://localhost:8090/api/v1/auth/sign-in'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'username': 'test001',
    'password': '123456'
  }),
);

final data = jsonDecode(response.body);
if (data['success']) {
  final accessToken = data['data']['accessToken'];
  final refreshToken = data['data']['refreshToken'];
  // 保存token到本地存储
} else {
  // 处理登录失败
  print('登录失败: ${data['message']}');
}
```

### 3. Token 刷新

**接口描述**: 使用刷新令牌获取新的访问令牌，延长登录有效期

- **URL**: `/api/v1/auth/token-refresh`
- **方法**: `POST`
- **认证**: 无需认证

#### 请求参数

```json
{
  "refreshToken": "string"    // 刷新令牌，必填
}
```

#### 响应示例

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

**失败响应 (200)**:
```json
{
  "success": false,
  "code": "INVALID_TOKEN",
  "message": "刷新令牌无效",
  "data": null
}
```

#### Flutter 调用示例

```dart
final response = await http.post(
  Uri.parse('http://localhost:8090/api/v1/auth/token-refresh'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'refreshToken': savedRefreshToken
  }),
);

final data = jsonDecode(response.body);
if (data['success']) {
  final newAccessToken = data['data']['accessToken'];
  final newRefreshToken = data['data']['refreshToken'];
  // 更新本地存储的token
} else {
  // Token失效，需要重新登录
  navigateToLogin();
}
```

## JWT Token 说明

### Access Token (访问令牌)
- **用途**: 用于API请求认证
- **有效期**: 15分钟 (900000毫秒)
- **使用方式**: 在请求头中添加 `Authorization: Bearer <accessToken>`

### Refresh Token (刷新令牌)
- **用途**: 用于获取新的访问令牌
- **有效期**: 30天 (2592000000毫秒)
- **使用方式**: 调用token刷新接口时作为请求参数

### JWT Payload 内容
访问令牌包含以下信息：
```json
{
  "sub": "username",      // 用户名
  "userId": 123,          // 用户ID
  "orgId": 1,             // 组织ID
  "type": "access",       // 令牌类型
  "iat": 1640995200,      // 签发时间
  "exp": 1640996100       // 过期时间
}
```

## 错误码说明

| 错误码 | 说明 | 解决方案 |
|--------|------|----------|
| `USER_EXISTS` | 用户名已被占用 | 使用不同的用户名重新注册 |
| `USER_NOT_FOUND` | 用户不存在 | 检查用户名是否正确或先注册 |
| `USER_DISABLED` | 账户已禁用 | 联系管理员启用账户 |
| `BAD_CREDENTIALS` | 用户名或密码错误 | 检查登录凭证是否正确 |
| `INVALID_TOKEN` | 令牌无效 | 重新登录获取新令牌 |
| `ORG_NOT_BOUND` | 未绑定任何组织 | 联系管理员绑定组织 |
| `SERVER_ERROR` | 服务器内部错误 | 稍后重试或联系技术支持 |

## 请求头示例

### 无需认证的接口
```http
POST /api/v1/auth/sign-in HTTP/1.1
Host: localhost:8090
Content-Type: application/json
```

### 需要认证的接口
```http
GET /api/v1/user/profile HTTP/1.1
Host: localhost:8090
Content-Type: application/json
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## Flutter HTTP 客户端配置

```dart
class ApiClient {
  static const String baseUrl = 'http://localhost:8090';
  static String? _accessToken;
  static String? _refreshToken;

  // 设置token
  static void setTokens(String accessToken, String refreshToken) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  // 获取认证头
  static Map<String, String> getAuthHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    
    return headers;
  }

  // 登录
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/sign-in'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );
    
    final data = jsonDecode(response.body);
    
    if (data['success']) {
      setTokens(data['data']['accessToken'], data['data']['refreshToken']);
    }
    
    return data;
  }

  // Token刷新
  static Future<bool> refreshToken() async {
    if (_refreshToken == null) return false;
    
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/token-refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': _refreshToken}),
    );
    
    final data = jsonDecode(response.body);
    
    if (data['success']) {
      setTokens(data['data']['accessToken'], data['data']['refreshToken']);
      return true;
    }
    
    return false;
  }
}
```

## 安全建议

1. **Token存储**: 使用Flutter的`flutter_secure_storage`包安全存储JWT令牌
2. **自动刷新**: 在访问令牌即将过期时自动调用刷新接口
3. **错误处理**: 实现统一的错误处理机制，包括网络错误和业务错误
4. **HTTPS**: 生产环境务必使用HTTPS协议
5. **输入验证**: 前端也应进行基础的输入验证

## 测试用例

### 测试数据
```json
{
  "validUser": {
    "username": "test001",
    "password": "123456",
    "nickname": "测试用户",
    "orgId": 1
  },
  "invalidUser": {
    "username": "",
    "password": "123"
  }
}
```

### 测试场景
1. ✅ 用户注册成功
2. ✅ 用户名已存在注册失败
3. ✅ 参数验证失败
4. ✅ 用户登录成功
5. ✅ 登录凭证错误
6. ✅ Token刷新成功
7. ✅ 无效Token刷新失败

---

**更新时间**: 2025-09-28  
**API版本**: v1.0.0  
**文档版本**: 1.0.0  
