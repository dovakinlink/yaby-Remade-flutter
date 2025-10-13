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

## 项目统计接口

### 4. 项目统计查询

**接口描述**: 获取当前用户组织下的项目统计数据，用于首页展示

- **URL**: `/api/v1/projects/statistics`
- **方法**: `GET`
- **认证**: 需要JWT认证

#### 请求参数

无需请求参数。数据范围自动根据JWT Token中的组织ID进行隔离。

#### 请求头

```http
GET /api/v1/projects/statistics HTTP/1.1
Host: localhost:8090
Content-Type: application/json
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

#### 响应示例

**成功响应 (200)**:
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": {
    "enrolling": 124,    // 入组中（进行中）的项目数量
    "pending": 3,        // 待开始的项目数量
    "stopped": 87,       // 停止（已完成/终止）的项目数量
    "total": 214         // 项目总数
  }
}
```

**失败响应 (401)**:
```json
{
  "success": false,
  "code": "UNAUTHORIZED",
  "message": "用户未登录",
  "data": null
}
```

#### 字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| `enrolling` | number | 入组中的项目数量，对应项目状态为"进行中"、"入组中"等 |
| `pending` | number | 待开始的项目数量，对应项目状态为"待启动"、"计划中"等 |
| `stopped` | number | 已停止的项目数量，对应项目状态为"已完成"、"终止"、"关闭"等 |
| `total` | number | 所有有效项目的总数量（不包括已删除的项目） |

#### 项目状态映射

项目统计根据 `t_project` 表的 `progress_id` 字段关联到 `sys_dict` 表的字典项进行分类：

- **入组中（enrolling）**: `sys_dict.code` 为 `IN_PROGRESS`、`ENROLLING`、`ONGOING`
- **待开始（pending）**: `sys_dict.code` 为 `PENDING`、`NOT_STARTED`、`PLANNED`
- **停止（stopped）**: `sys_dict.code` 为 `STOPPED`、`COMPLETED`、`TERMINATED`、`CLOSED`

> 注意：实际的字典代码值需要根据 `sys_dict` 表中的实际数据配置调整

#### Flutter 调用示例

```dart
// 获取项目统计数据
Future<Map<String, dynamic>?> getProjectStatistics() async {
  try {
    final response = await http.get(
      Uri.parse('http://localhost:8090/api/v1/projects/statistics'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',  // 使用登录后获取的token
      },
    );

    final data = jsonDecode(response.body);
    
    if (data['success']) {
      final statistics = data['data'];
      print('入组中: ${statistics['enrolling']}');
      print('待开始: ${statistics['pending']}');
      print('停止: ${statistics['stopped']}');
      print('总数: ${statistics['total']}');
      return statistics;
    } else {
      print('获取统计失败: ${data['message']}');
      return null;
    }
  } catch (e) {
    print('网络请求失败: $e');
    return null;
  }
}
```

#### 完整的Flutter示例（包含UI展示）

```dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeStatisticsWidget extends StatefulWidget {
  final String accessToken;

  const HomeStatisticsWidget({Key? key, required this.accessToken}) : super(key: key);

  @override
  _HomeStatisticsWidgetState createState() => _HomeStatisticsWidgetState();
}

class _HomeStatisticsWidgetState extends State<HomeStatisticsWidget> {
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8090/api/v1/projects/statistics'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.accessToken}',
        },
      );

      final data = jsonDecode(response.body);
      
      if (data['success']) {
        setState(() {
          _statistics = data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('加载统计数据失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_statistics == null) {
      return const Center(child: Text('加载失败'));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('入组中', _statistics!['enrolling']),
          _buildStatItem('待开始', _statistics!['pending']),
          _buildStatItem('停止', _statistics!['stopped']),
          _buildStatItem('总数', _statistics!['total']),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, dynamic value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Text(
          '$value',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
```

#### 数据隔离说明

此接口基于多租户架构设计，具有以下特点：

1. **组织隔离**: 统计数据仅包含当前用户所属组织的项目
2. **自动识别**: 组织ID从JWT Token中自动提取，无需前端传递
3. **数据安全**: 用户无法访问其他组织的项目统计数据
4. **软删除**: 已逻辑删除的项目（`is_deleted = 1`）不计入统计

#### 使用场景

- 移动端首页展示项目概览
- 项目管理控制台的统计看板
- 数据报表的基础数据源

#### 注意事项

1. **认证必需**: 此接口必须携带有效的JWT Token，否则返回401错误
2. **实时统计**: 数据直接从数据库查询，不使用缓存，确保数据实时性
3. **字典配置**: 项目状态分类依赖 `sys_dict` 表的配置，如调整字典项需同步更新SQL查询逻辑
4. **性能考虑**: 如项目数量很大，建议后续考虑添加缓存机制

## 通知公告接口

### 1. 首页公告分页查询

**接口描述**: 获取首页通知公告分页列表，支持公告类型过滤和权限控制

- **URL**: `/api/v1/announcements/home`
- **方法**: `GET`
- **认证**: 需要JWT Token

#### 请求参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| page | number | 否 | 页码，默认1 |
| size | number | 否 | 每页大小，默认10 |
| notice-type | number | 否 | 公告类型：0-官方公告，1-用户帖子，不传-全部 |

#### 响应示例

**成功响应 (200)**:
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "操作成功",
  "data": {
    "items": [
      {
        "id": 1,
        "orgId": 1,
        "hospitalId": 1,
        "title": "重要通知",
        "noticeType": 0,
        "top": true,
        "status": 1,
        "orderNo": 100,
        "contentHtml": "<p>这是一条重要通知...</p>",
        "contentText": "这是一条重要通知...",
        "attachments": [
          {
            "id": 1,
            "fileId": 10,
            "filename": "通知文档.pdf",
            "displayName": "通知文档.pdf",
            "ext": ".pdf",
            "mimeType": "application/pdf",
            "sizeBytes": 2621440,
            "width": null,
            "height": null,
            "url": "/api/v1/files/10",
            "sortNo": 1,
            "image": false,
            "pdf": true,
            "video": false,
            "readableSize": "2.50 MB"
          }
        ],
        "createdBy": 1,
        "createdAt": "2025-10-11T10:00:00",
        "updatedAt": "2025-10-11T10:00:00"
      }
    ],
    "page": 1,
    "size": 10,
    "total": 25
  }
}
```

#### 字段说明

**公告字段**:

| 字段 | 类型 | 说明 |
|------|------|------|
| id | number | 公告ID |
| orgId | number | 组织ID |
| hospitalId | number | 医院ID |
| title | string | 公告标题 |
| noticeType | number | 公告类型：0-官方公告，1-用户帖子 |
| top | boolean | 是否置顶 |
| status | number | 状态：1-发布，0-草稿 |
| orderNo | number | 排序序号，数值越大越靠前 |
| contentHtml | string | HTML格式的内容 |
| contentText | string | 纯文本内容 |
| attachments | array | 附件列表 |
| createdBy | number | 创建人ID |
| creatorAvatar | string \| null | 创建者头像URL（仅用户帖子notice_type=1时有值） |
| creatorName | string \| null | 创建者姓名（仅用户帖子notice_type=1时有值） |
| tagId | number \| null | 标签ID（仅用户帖子notice_type=1时有值） |
| tagName | string \| null | 标签名称（仅用户帖子notice_type=1时有值） |
| createdAt | string | 创建时间 |
| updatedAt | string | 更新时间 |

**附件字段**:

| 字段 | 类型 | 说明 |
|------|------|------|
| id | number | 附件映射ID |
| fileId | number | 文件ID |
| filename | string | 原始文件名 |
| displayName | string | 展示名称 |
| ext | string | 文件扩展名（如 .pdf, .jpg） |
| mimeType | string | 文件MIME类型 |
| sizeBytes | number | 文件大小（字节） |
| width | number | 图片宽度（仅图片有值） |
| height | number | 图片高度（仅图片有值） |
| url | string | 文件访问URL（格式：uploads/ + t_file.rel_path） |
| sortNo | number | 排序序号 |
| image | boolean | 是否为图片 |
| pdf | boolean | 是否为PDF |
| video | boolean | 是否为视频 |
| readableSize | string | 可读的文件大小格式 |

#### 权限控制说明

- **官方公告（notice_type=0）**: 只能查看当前用户组织的公告
- **用户帖子（notice_type=1）**: 所有用户都可以查看
- **全部类型（不传notice_type）**: 用户帖子全部可见，官方公告只能看到自己组织的

### 2. 公告详情查询

**接口描述**: 根据公告ID获取公告的详细信息，包括附件列表

- **URL**: `/api/v1/announcements/{id}`
- **方法**: `GET`
- **认证**: 需要JWT Token

#### 路径参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| id | number | 是 | 公告ID |

#### 响应示例

**成功响应 (200)**:
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "操作成功",
  "data": {
    "id": 1,
    "orgId": 1,
    "hospitalId": 1,
    "title": "重要通知",
    "noticeType": 0,
    "top": true,
    "status": 1,
    "orderNo": 100,
    "contentHtml": "<p>这是一条重要通知...</p>",
    "contentText": "这是一条重要通知...",
    "attachments": [
      {
        "id": 1,
        "fileId": 10,
        "filename": "通知文档.pdf",
        "displayName": "通知文档.pdf",
        "ext": ".pdf",
        "mimeType": "application/pdf",
        "sizeBytes": 2621440,
        "width": null,
        "height": null,
        "url": "/api/v1/files/10",
        "sortNo": 1,
        "image": false,
        "pdf": true,
        "video": false,
        "readableSize": "2.50 MB"
      },
      {
        "id": 2,
        "fileId": 11,
        "filename": "附图.jpg",
        "displayName": "附图.jpg",
        "ext": ".jpg",
        "mimeType": "image/jpeg",
        "sizeBytes": 524288,
        "width": 1920,
        "height": 1080,
        "url": "/api/v1/files/11",
        "sortNo": 2,
        "image": true,
        "pdf": false,
        "video": false,
        "readableSize": "512.00 KB"
      }
    ],
    "createdBy": 1,
    "createdAt": "2025-10-11T10:00:00",
    "updatedAt": "2025-10-11T10:00:00"
  }
}
```

**失败响应 (404)**:
```json
{
  "success": false,
  "code": "NOTICE_NOT_FOUND",
  "message": "公告不存在",
  "data": null
}
```

#### Flutter 调用示例

```dart
// 获取公告详情
Future<Map<String, dynamic>?> getAnnouncementDetail(int id) async {
  try {
    final response = await http.get(
      Uri.parse('http://localhost:8090/api/v1/announcements/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    final data = jsonDecode(response.body);
    
    if (data['success']) {
      final announcement = data['data'];
      print('标题: ${announcement['title']}');
      print('附件数量: ${announcement['attachments'].length}');
      
      // 处理附件
      for (var attachment in announcement['attachments']) {
        print('附件: ${attachment['displayName']} (${attachment['readableSize']})');
        
        // 根据文件类型处理
        if (attachment['image']) {
          // 显示图片
        } else if (attachment['pdf']) {
          // 打开PDF查看器
        } else if (attachment['video']) {
          // 播放视频
        }
      }
      
      return announcement;
    } else {
      print('错误: ${data['message']}');
      return null;
    }
  } catch (e) {
    print('请求失败: $e');
    return null;
  }
}
```

### 3. 公告列表查询

**接口描述**: 根据过滤条件获取公告列表

- **URL**: `/api/v1/announcements`
- **方法**: `GET`
- **认证**: 需要JWT Token

#### 请求参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| org-id | number | 否 | 组织ID |
| hospital-id | number | 否 | 医院ID |
| status | number | 否 | 状态：1-发布，0-草稿 |

#### 响应示例

**成功响应 (200)**:
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "操作成功",
  "data": [
    {
      "id": 1,
      "orgId": 1,
      "hospitalId": 1,
      "title": "重要通知",
      "noticeType": 0,
      "top": true,
      "status": 1,
      "orderNo": 100,
      "contentHtml": "<p>这是一条重要通知...</p>",
      "contentText": "这是一条重要通知...",
      "attachments": [],
      "createdBy": 1,
      "createdAt": "2025-10-11T10:00:00",
      "updatedAt": "2025-10-11T10:00:00"
    }
  ]
}
```

#### 附件展示建议

根据文件的 MIME 类型，客户端可以选择不同的展示和处理方式：

**图片类型** (`image/*`):
- 使用图片查看器直接显示
- 支持缩放、旋转等操作
- 推荐库: `photo_view`

**PDF文档** (`application/pdf`):
- 使用PDF查看器打开
- 支持翻页、缩放等操作
- 推荐库: `flutter_pdfview`

**视频文件** (`video/*`):
- 使用视频播放器播放
- 支持播放、暂停、快进等操作
- 推荐库: `video_player`

**其他文件类型**:
- 提供下载功能
- 保存到本地后使用系统默认应用打开
- 推荐库: `dio`, `path_provider`, `open_file`

## 用户帖子接口

### 1. 获取可用的帖子标签列表

**接口描述**: 获取当前用户可用的帖子标签列表

- **URL**: `/api/v1/posts/tags`
- **方法**: `GET`
- **认证**: 需要JWT Token

#### 请求参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| hospital-id | number | 否 | 医院ID，传入则返回组织级和该医院的标签 |

#### 响应示例

**成功响应 (200)**:
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "操作成功",
  "data": [
    {
      "id": 1,
      "tagCode": "PROJECT_ANNOUNCEMENT",
      "tagName": "项目公告",
      "description": "项目相关的公告信息",
      "orderNo": 1
    },
    {
      "id": 2,
      "tagCode": "ACADEMIC_DISCUSSION",
      "tagName": "学术讨论",
      "description": "学术相关的讨论话题",
      "orderNo": 2
    },
    {
      "id": 3,
      "tagCode": "EXPERIENCE_SHARING",
      "tagName": "经验分享",
      "description": "工作经验分享",
      "orderNo": 3
    }
  ]
}
```

#### 字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| id | number | 标签ID |
| tagCode | string | 标签编码（唯一标识） |
| tagName | string | 标签名称 |
| description | string | 标签说明 |
| orderNo | number | 排序序号 |

### 2. 创建用户帖子

**接口描述**: 用户发布新帖子，支持图文内容和附件上传

- **URL**: `/api/v1/posts`
- **方法**: `POST`
- **认证**: 需要JWT Token

#### 请求参数

```json
{
  "hospitalId": 1,
  "tagId": 2,
  "title": "【学术讨论】肿瘤免疫治疗最新进展",
  "contentHtml": "<p>最近参加了一个学术会议，想跟大家分享一些关于肿瘤免疫治疗的最新进展...</p><img src='/api/v1/files/100' />",
  "contentText": "最近参加了一个学术会议，想跟大家分享一些关于肿瘤免疫治疗的最新进展...",
  "fileIds": [100, 101, 102]
}
```

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| hospitalId | number | 是 | 医院ID |
| tagId | number | 是 | 标签ID |
| title | string | 是 | 帖子标题，最多255字符 |
| contentHtml | string | 是 | HTML格式的内容 |
| contentText | string | 否 | 纯文本内容，用于搜索 |
| fileIds | array | 否 | 附件文件ID列表 |

#### 响应示例

**成功响应 (200)**:
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "操作成功",
  "data": {
    "id": 10,
    "orgId": 1,
    "hospitalId": 1,
    "title": "【学术讨论】肿瘤免疫治疗最新进展",
    "noticeType": 1,
    "top": false,
    "status": 1,
    "orderNo": 0,
    "contentHtml": "<p>最近参加了一个学术会议，想跟大家分享一些关于肿瘤免疫治疗的最新进展...</p><img src='/api/v1/files/100' />",
    "contentText": "最近参加了一个学术会议，想跟大家分享一些关于肿瘤免疫治疗的最新进展...",
    "attachments": [
      {
        "id": 10,
        "fileId": 100,
        "filename": "会议PPT.pdf",
        "displayName": "会议PPT.pdf",
        "ext": ".pdf",
        "mimeType": "application/pdf",
        "sizeBytes": 5242880,
        "width": null,
        "height": null,
        "url": "/api/v1/files/100",
        "sortNo": 1,
        "image": false,
        "pdf": true,
        "video": false,
        "readableSize": "5.00 MB"
      },
      {
        "id": 11,
        "fileId": 101,
        "filename": "现场照片1.jpg",
        "displayName": "现场照片1.jpg",
        "ext": ".jpg",
        "mimeType": "image/jpeg",
        "sizeBytes": 1048576,
        "width": 1920,
        "height": 1080,
        "url": "/api/v1/files/101",
        "sortNo": 2,
        "image": true,
        "pdf": false,
        "video": false,
        "readableSize": "1.00 MB"
      }
    ],
    "createdBy": 5,
    "createdAt": "2025-10-11T15:30:00",
    "updatedAt": "2025-10-11T15:30:00"
  }
}
```

**失败响应 - 标签不存在 (400)**:
```json
{
  "success": false,
  "code": "TAG_NOT_FOUND",
  "message": "标签不存在",
  "data": null
}
```

**失败响应 - 标签已停用 (400)**:
```json
{
  "success": false,
  "code": "TAG_DISABLED",
  "message": "标签已停用",
  "data": null
}
```

**失败响应 - 无权使用标签 (403)**:
```json
{
  "success": false,
  "code": "TAG_ACCESS_DENIED",
  "message": "无权使用该标签",
  "data": null
}
```

#### Flutter 调用示例

```dart
// 1. 获取可用标签
Future<List<NoticeTag>?> getAvailableTags({int? hospitalId}) async {
  try {
    final uri = hospitalId != null
        ? Uri.parse('http://localhost:8090/api/v1/posts/tags?hospital-id=$hospitalId')
        : Uri.parse('http://localhost:8090/api/v1/posts/tags');
        
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    final data = jsonDecode(response.body);
    
    if (data['success']) {
      List<NoticeTag> tags = (data['data'] as List)
          .map((json) => NoticeTag.fromJson(json))
          .toList();
      return tags;
    } else {
      print('错误: ${data['message']}');
      return null;
    }
  } catch (e) {
    print('请求失败: $e');
    return null;
  }
}

// 2. 创建帖子
Future<Map<String, dynamic>?> createPost({
  required int hospitalId,
  required int tagId,
  required String title,
  required String contentHtml,
  String? contentText,
  List<int>? fileIds,
}) async {
  try {
    final response = await http.post(
      Uri.parse('http://localhost:8090/api/v1/posts'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'hospitalId': hospitalId,
        'tagId': tagId,
        'title': title,
        'contentHtml': contentHtml,
        'contentText': contentText,
        'fileIds': fileIds,
      }),
    );

    final data = jsonDecode(response.body);
    
    if (data['success']) {
      print('发帖成功！帖子ID: ${data['data']['id']}');
      return data['data'];
    } else {
      print('发帖失败: ${data['message']}');
      return null;
    }
  } catch (e) {
    print('请求失败: $e');
    return null;
  }
}
```

#### 使用场景

**1. 用户发布项目公告**
- 选择"项目公告"标签
- 填写标题和内容
- 上传相关文档附件
- 发布后所有用户可见

**2. 学术讨论交流**
- 选择"学术讨论"标签
- 分享学术会议内容
- 上传PPT、照片等附件
- 促进学术交流

**3. 经验分享**
- 选择"经验分享"标签
- 分享工作经验和心得
- 附上相关图片或文档
- 帮助新人快速成长

#### 注意事项

1. **图文内容**: 
   - `contentHtml` 支持富文本格式，可以包含图片、链接等
   - 图片建议先上传到文件服务，获取URL后嵌入HTML中
   - `contentText` 用于搜索，建议同时提供

2. **附件上传**:
   - 附件需要先通过文件上传接口上传，获取文件ID
   - 多个附件按 `fileIds` 数组顺序排列
   - 支持图片、PDF、Office文档等多种格式

3. **标签选择**:
   - 必须选择一个标签才能发帖
   - 标签由后台管理员配置
   - 不同医院可能有不同的标签

4. **权限控制**:
   - 用户只能使用自己组织的标签
   - 发布的帖子归属于指定的医院
   - 所有用户都可以查看用户帖子（notice_type=1）

---

**更新时间**: 2025-10-11  
**API版本**: v1.0.0  
**文档版本**: 1.3.0  
