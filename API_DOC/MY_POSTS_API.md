# 我的发表公告列表 API 文档

## 概述

本文档描述了"我的"页面相关的API接口，包括：

1. **我的发表公告列表**：查询当前登录用户发表过的所有通知公告
2. **用户个人信息**：获取当前登录用户的详细个人信息
3. **修改密码**：用户修改自己的登录密码
4. **退出登录**：用户退出登录（清除本地Token）

这些接口用于APP的"我的"页面展示用户的个人信息、发表内容以及账号安全管理功能。

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

---

## API 接口详情

### 获取我的发表公告列表（分页）

**接口描述**: 查询当前登录用户发表过的所有通知公告（已发布状态），用于APP的"我的"页面展示，支持分页。

- **URL**: `/api/v1/announcements/my-posts`
- **方法**: `GET`
- **认证**: 需要JWT Token

#### 查询条件说明

此接口自动根据当前登录用户的身份进行查询，具有以下特点：

- ✅ 只显示当前用户创建的公告（`created_by = 当前用户ID`）
- ✅ 只显示已发布的公告（`status = 1`）
- ✅ 包含所有类型（官方公告 + 用户帖子）
- ✅ 按创建时间倒序排列（最新的在前）
- ✅ 不包含已删除的公告

#### 请求参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| page | number | 否 | 1 | 页码，从1开始 |
| size | number | 否 | 10 | 每页大小，建议10-50 |

#### 请求示例

```http
GET /api/v1/announcements/my-posts?page=1&size=10 HTTP/1.1
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
    "data": [
      {
        "id": 123,
        "orgId": 1,
        "hospitalId": 1,
        "title": "【学术讨论】肿瘤免疫治疗最新进展",
        "noticeType": 1,
        "top": false,
        "status": 1,
        "orderNo": 0,
        "contentHtml": "<p>最近参加了一个学术会议，想跟大家分享一些关于肿瘤免疫治疗的最新进展...</p>",
        "contentText": "最近参加了一个学术会议，想跟大家分享一些关于肿瘤免疫治疗的最新进展...",
        "attachments": [
          {
            "id": 1,
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
          }
        ],
        "createdBy": 5,
        "creatorAvatar": "/avatar/user5.jpg",
        "creatorName": "张医生",
        "tagId": 2,
        "tagName": "学术讨论",
        "createdAt": "2025-10-15T10:30:00",
        "updatedAt": "2025-10-15T10:30:00"
      },
      {
        "id": 98,
        "orgId": 1,
        "hospitalId": 1,
        "title": "项目进展通报",
        "noticeType": 0,
        "top": false,
        "status": 1,
        "orderNo": 0,
        "contentHtml": "<p>本周项目进展顺利...</p>",
        "contentText": "本周项目进展顺利...",
        "attachments": [],
        "createdBy": 5,
        "creatorAvatar": null,
        "creatorName": null,
        "tagId": null,
        "tagName": null,
        "createdAt": "2025-10-12T14:20:00",
        "updatedAt": "2025-10-12T14:20:00"
      }
    ],
    "page": 1,
    "size": 10,
    "total": 25,
    "pages": 3,
    "hasNext": true,
    "hasPrev": false
  }
}
```

**失败响应 - 未登录 (401)**:

```json
{
  "success": false,
  "code": "UNAUTHORIZED",
  "message": "请先登录",
  "data": null
}
```

**失败响应 - Token过期 (401)**:

```json
{
  "success": false,
  "code": "TOKEN_EXPIRED",
  "message": "登录已过期，请重新登录",
  "data": null
}
```

#### 响应字段说明

**分页对象**:

| 字段 | 类型 | 说明 |
|------|------|------|
| data | array | 公告列表数据 |
| page | number | 当前页码 |
| size | number | 每页大小 |
| total | number | 总记录数 |
| pages | number | 总页数 |
| hasNext | boolean | 是否有下一页 |
| hasPrev | boolean | 是否有上一页 |

**公告对象字段**:

| 字段 | 类型 | 说明 |
|------|------|------|
| id | number | 公告ID |
| orgId | number | 组织ID |
| hospitalId | number | 医院ID |
| title | string | 公告标题 |
| noticeType | number | 公告类型：0-官方公告，1-用户帖子 |
| top | boolean | 是否置顶 |
| status | number | 状态：1-发布，0-草稿 |
| orderNo | number | 排序序号 |
| contentHtml | string | HTML格式的内容 |
| contentText | string | 纯文本内容 |
| attachments | array | 附件列表 |
| createdBy | number | 创建人ID（当前用户ID） |
| creatorAvatar | string \| null | 创建者头像URL（仅用户帖子时有值） |
| creatorName | string \| null | 创建者姓名（仅用户帖子时有值） |
| tagId | number \| null | 标签ID（仅用户帖子时有值） |
| tagName | string \| null | 标签名称（仅用户帖子时有值） |
| createdAt | string | 创建时间（ISO 8601格式） |
| updatedAt | string | 更新时间（ISO 8601格式） |

**附件对象字段**:

| 字段 | 类型 | 说明 |
|------|------|------|
| id | number | 附件映射ID |
| fileId | number | 文件ID |
| filename | string | 原始文件名 |
| displayName | string | 展示名称 |
| ext | string | 文件扩展名（如 .pdf, .jpg） |
| mimeType | string | 文件MIME类型 |
| sizeBytes | number | 文件大小（字节） |
| width | number \| null | 图片宽度（仅图片有值） |
| height | number \| null | 图片高度（仅图片有值） |
| url | string | 文件访问URL |
| sortNo | number | 排序序号 |
| image | boolean | 是否为图片 |
| pdf | boolean | 是否为PDF |
| video | boolean | 是否为视频 |
| readableSize | string | 可读的文件大小格式 |

---

### 获取当前用户个人信息

**接口描述**: 获取当前登录用户的详细个人信息，包括用户名、昵称、联系方式、所属组织等。

- **URL**: `/api/v1/user-profile/me`
- **方法**: `GET`
- **认证**: 需要JWT Token

#### 请求参数

无需请求参数。用户身份自动从JWT Token中获取。

#### 请求示例

```http
GET /api/v1/user-profile/me HTTP/1.1
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
    "id": 5,
    "username": "zhangsan",
    "nickname": "张医生",
    "phone": "13800138000",
    "email": "zhangsan@hospital.com",
    "avatar": "/uploads/avatars/zhangsan.jpg",
    "orgId": 1,
    "status": 1,
    "createTime": "2025-09-15T10:30:00",
    "updateTime": "2025-10-15T14:20:00"
  }
}
```

**失败响应 - 未登录 (401)**:

```json
{
  "success": false,
  "code": "UNAUTHORIZED",
  "message": "请先登录",
  "data": null
}
```

**失败响应 - Token过期 (401)**:

```json
{
  "success": false,
  "code": "TOKEN_EXPIRED",
  "message": "登录已过期，请重新登录",
  "data": null
}
```

**失败响应 - 用户不存在 (404)**:

```json
{
  "success": false,
  "code": "USER_NOT_FOUND",
  "message": "用户不存在",
  "data": null
}
```

#### 响应字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| id | number | 用户ID |
| username | string | 登录用户名 |
| nickname | string \| null | 用户昵称（可选） |
| phone | string \| null | 手机号码（可选） |
| email | string \| null | 邮箱地址（可选） |
| avatar | string \| null | 用户头像URL（可选，从t_person表关联获取） |
| orgId | number \| null | 所属组织ID |
| status | number | 用户状态：1-正常，0-禁用 |
| createTime | string | 注册时间（ISO 8601格式） |
| updateTime | string | 最后更新时间（ISO 8601格式） |

#### 使用场景

1. **个人中心页面**: 显示用户的基本信息和账号状态
2. **用户信息编辑**: 编辑前获取当前信息进行回显
3. **头像昵称展示**: 在APP各处显示用户昵称
4. **权限验证**: 验证用户状态和所属组织

---

### 修改密码

**接口描述**: 修改当前登录用户的密码。需要验证旧密码，修改成功后当前Token仍然有效，用户无需重新登录。

- **URL**: `/api/v1/user-profile/change-password`
- **方法**: `PUT`
- **认证**: 需要JWT Token

#### 请求参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| oldPassword | string | 是 | 旧密码（用于验证身份） |
| newPassword | string | 是 | 新密码（长度6-100字符） |

#### 请求示例

```http
PUT /api/v1/user-profile/change-password HTTP/1.1
Host: localhost:8090
Content-Type: application/json
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

{
  "oldPassword": "oldpassword123",
  "newPassword": "newpassword456"
}
```

#### cURL示例

```bash
curl -X PUT http://localhost:8090/api/v1/user-profile/change-password \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "oldPassword": "oldpassword123",
    "newPassword": "newpassword456"
  }'
```

#### 响应示例

**成功响应 (200)**:

```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": "密码修改成功"
}
```

**失败响应 - 未登录 (401)**:

```json
{
  "success": false,
  "code": "UNAUTHORIZED",
  "message": "请先登录",
  "data": null
}
```

**失败响应 - 旧密码错误 (400)**:

```json
{
  "success": false,
  "code": "OLD_PASSWORD_INCORRECT",
  "message": "旧密码错误",
  "data": null
}
```

**失败响应 - 新旧密码相同 (400)**:

```json
{
  "success": false,
  "code": "PASSWORD_NOT_CHANGED",
  "message": "新密码不能与旧密码相同",
  "data": null
}
```

**失败响应 - 参数校验失败 (400)**:

```json
{
  "success": false,
  "code": "INVALID_PARAMETER",
  "message": "新密码长度必须在6-100字符之间",
  "data": null
}
```

**失败响应 - 用户不存在 (404)**:

```json
{
  "success": false,
  "code": "USER_NOT_FOUND",
  "message": "用户不存在",
  "data": null
}
```

#### 业务规则

1. **旧密码验证**: 必须提供正确的旧密码才能修改
2. **新密码要求**: 
   - 长度：6-100字符
   - 不能与旧密码相同
3. **Token有效性**: 修改密码成功后，当前Token仍然有效，用户无需重新登录
4. **密码加密**: 密码使用MD5加密存储

#### 安全建议

1. **前端验证**: 建议在前端添加"确认新密码"输入框，确保用户两次输入一致
2. **密码强度**: 建议前端提示用户使用包含字母和数字的组合密码
3. **限流保护**: 避免频繁修改密码（建议1分钟内最多修改1次）
4. **忘记密码**: 如果用户忘记旧密码，需要通过其他方式（如手机验证码）重置密码

---

### 退出登录

**接口描述**: 用户退出登录。由于JWT是无状态的，退出登录主要在客户端实现（删除本地Token），服务端接口用于日志记录和未来扩展。

- **URL**: `/api/v1/auth/logout`
- **方法**: `POST`
- **认证**: 需要JWT Token

#### 请求参数

无需请求参数。

#### 请求示例

```http
POST /api/v1/auth/logout HTTP/1.1
Host: localhost:8090
Content-Type: application/json
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

#### cURL示例

```bash
curl -X POST http://localhost:8090/api/v1/auth/logout \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

#### 响应示例

**成功响应 (200)**:

```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": "退出登录成功"
}
```

#### 客户端处理说明

退出登录后，客户端必须执行以下操作：

1. **删除Token**: 
   ```dart
   // 删除Access Token
   await storage.delete(key: 'access_token');
   // 删除Refresh Token
   await storage.delete(key: 'refresh_token');
   ```

2. **清除缓存**: 
   ```dart
   // 清除用户信息缓存
   await storage.delete(key: 'user_profile');
   // 清除其他业务缓存
   ```

3. **跳转登录页**: 
   ```dart
   // 导航到登录页面
   Navigator.of(context).pushAndRemoveUntil(
     MaterialPageRoute(builder: (context) => LoginPage()),
     (route) => false,
   );
   ```

4. **重置状态**: 清除所有内存中的用户状态和业务数据

#### 技术说明

- **Token有效性**: 调用此接口后，Token在服务端仍然有效（直到过期），客户端需要确保删除所有Token
- **未来扩展**: 此接口为未来的Token黑名单机制预留，后续可以实现服务端主动失效Token
- **日志记录**: 服务端会记录用户的退出登录行为，用于安全审计

---

## Flutter 集成示例

### 1. 定义数据模型

```dart
// 公告模型
class Announcement {
  final int id;
  final int orgId;
  final int? hospitalId;
  final String title;
  final int noticeType;
  final bool top;
  final int status;
  final int orderNo;
  final String contentHtml;
  final String contentText;
  final List<Attachment> attachments;
  final int createdBy;
  final String? creatorAvatar;
  final String? creatorName;
  final int? tagId;
  final String? tagName;
  final DateTime createdAt;
  final DateTime updatedAt;

  Announcement({
    required this.id,
    required this.orgId,
    this.hospitalId,
    required this.title,
    required this.noticeType,
    required this.top,
    required this.status,
    required this.orderNo,
    required this.contentHtml,
    required this.contentText,
    required this.attachments,
    required this.createdBy,
    this.creatorAvatar,
    this.creatorName,
    this.tagId,
    this.tagName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      orgId: json['orgId'],
      hospitalId: json['hospitalId'],
      title: json['title'],
      noticeType: json['noticeType'],
      top: json['top'],
      status: json['status'],
      orderNo: json['orderNo'],
      contentHtml: json['contentHtml'],
      contentText: json['contentText'],
      attachments: (json['attachments'] as List)
          .map((e) => Attachment.fromJson(e))
          .toList(),
      createdBy: json['createdBy'],
      creatorAvatar: json['creatorAvatar'],
      creatorName: json['creatorName'],
      tagId: json['tagId'],
      tagName: json['tagName'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // 是否为官方公告
  bool get isOfficialNotice => noticeType == 0;
  
  // 是否为用户帖子
  bool get isUserPost => noticeType == 1;
}

// 附件模型
class Attachment {
  final int id;
  final int fileId;
  final String filename;
  final String displayName;
  final String ext;
  final String mimeType;
  final int sizeBytes;
  final int? width;
  final int? height;
  final String url;
  final int sortNo;
  final bool image;
  final bool pdf;
  final bool video;
  final String readableSize;

  Attachment({
    required this.id,
    required this.fileId,
    required this.filename,
    required this.displayName,
    required this.ext,
    required this.mimeType,
    required this.sizeBytes,
    this.width,
    this.height,
    required this.url,
    required this.sortNo,
    required this.image,
    required this.pdf,
    required this.video,
    required this.readableSize,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id'],
      fileId: json['fileId'],
      filename: json['filename'],
      displayName: json['displayName'],
      ext: json['ext'],
      mimeType: json['mimeType'],
      sizeBytes: json['sizeBytes'],
      width: json['width'],
      height: json['height'],
      url: json['url'],
      sortNo: json['sortNo'],
      image: json['image'],
      pdf: json['pdf'],
      video: json['video'],
      readableSize: json['readableSize'],
    );
  }
}

// 分页响应模型
class PageResponse<T> {
  final List<T> data;
  final int page;
  final int size;
  final int total;
  final int pages;
  final bool hasNext;
  final bool hasPrev;

  PageResponse({
    required this.data,
    required this.page,
    required this.size,
    required this.total,
    required this.pages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PageResponse(
      data: (json['data'] as List)
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      page: json['page'],
      size: json['size'],
      total: json['total'],
      pages: json['pages'],
      hasNext: json['hasNext'],
      hasPrev: json['hasPrev'],
    );
  }
}
```

### 2. API 服务类

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AnnouncementApiService {
  static const String baseUrl = 'http://localhost:8090';
  final String accessToken;

  AnnouncementApiService(this.accessToken);

  /// 获取我的发表公告列表
  Future<PageResponse<Announcement>?> getMyPosts({
    int page = 1,
    int size = 10,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/api/v1/announcements/my-posts?page=$page&size=$size',
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      final data = jsonDecode(response.body);

      if (data['success']) {
        return PageResponse.fromJson(
          data['data'],
          (json) => Announcement.fromJson(json),
        );
      } else {
        print('获取失败: ${data['message']}');
        return null;
      }
    } catch (e) {
      print('请求失败: $e');
      return null;
    }
  }
}
```

### 3. 用户个人信息数据模型

```dart
// 用户个人信息模型
class UserProfile {
  final int id;
  final String username;
  final String? nickname;
  final String? phone;
  final String? email;
  final String? avatar;
  final int? orgId;
  final int status;
  final DateTime createTime;
  final DateTime updateTime;

  UserProfile({
    required this.id,
    required this.username,
    this.nickname,
    this.phone,
    this.email,
    this.avatar,
    this.orgId,
    required this.status,
    required this.createTime,
    required this.updateTime,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      username: json['username'],
      nickname: json['nickname'],
      phone: json['phone'],
      email: json['email'],
      avatar: json['avatar'],
      orgId: json['orgId'],
      status: json['status'],
      createTime: DateTime.parse(json['createTime']),
      updateTime: DateTime.parse(json['updateTime']),
    );
  }

  // 是否为正常状态
  bool get isActive => status == 1;
  
  // 是否被禁用
  bool get isDisabled => status == 0;
  
  // 显示名称（优先使用昵称，其次用户名）
  String get displayName => nickname ?? username;
  
  // 是否有头像
  bool get hasAvatar => avatar != null && avatar!.isNotEmpty;
}
```

### 4. 用户信息API服务类

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class UserApiService {
  static const String baseUrl = 'http://localhost:8090';
  final String accessToken;

  UserApiService(this.accessToken);

  /// 获取当前用户个人信息
  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/user-profile/me');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      final data = jsonDecode(response.body);

      if (data['success']) {
        return UserProfile.fromJson(data['data']);
      } else {
        print('获取用户信息失败: ${data['message']}');
        return null;
      }
    } catch (e) {
      print('请求失败: $e');
      return null;
    }
  }

  /// 修改密码
  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/user-profile/change-password');

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      return {
        'success': data['success'],
        'code': data['code'],
        'message': data['message'],
      };
    } catch (e) {
      print('修改密码请求失败: $e');
      return {
        'success': false,
        'code': 'NETWORK_ERROR',
        'message': '网络请求失败',
      };
    }
  }
}
```

### 4-1. 退出登录API服务类

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthApiService {
  static const String baseUrl = 'http://localhost:8090';
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  /// 退出登录
  Future<bool> logout() async {
    try {
      // 1. 获取当前Token
      final accessToken = await storage.read(key: 'access_token');
      
      if (accessToken != null) {
        // 2. 调用服务端退出登录接口
        final uri = Uri.parse('$baseUrl/api/v1/auth/logout');
        await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        );
      }

      // 3. 删除本地Token（无论服务端调用是否成功）
      await storage.delete(key: 'access_token');
      await storage.delete(key: 'refresh_token');

      // 4. 清除用户信息缓存
      await storage.delete(key: 'user_profile');
      await storage.delete(key: 'user_id');
      await storage.delete(key: 'org_id');

      return true;
    } catch (e) {
      print('退出登录失败: $e');
      
      // 即使出错也要清除本地Token
      try {
        await storage.deleteAll();
      } catch (_) {}
      
      return false;
    }
  }
}
```

### 5. 个人中心页面实现

```dart
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  final String accessToken;

  const ProfilePage({Key? key, required this.accessToken}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late UserApiService _userApiService;
  UserProfile? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _userApiService = UserApiService(widget.accessToken);
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    final profile = await _userApiService.getCurrentUserProfile();

    setState(() {
      _userProfile = profile;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('个人中心'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _userProfile != null ? _editProfile : null,
            tooltip: '编辑资料',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserProfile,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_userProfile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserProfile,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 用户头像和基本信息卡片
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // 头像
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue[100],
                  backgroundImage: _userProfile!.hasAvatar
                      ? NetworkImage(_userProfile!.avatar!)
                      : null,
                  child: !_userProfile!.hasAvatar
                      ? Text(
                          _userProfile!.displayName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                // 昵称/用户名
                Text(
                  _userProfile!.displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // 用户名（如果有昵称）
                if (_userProfile!.nickname != null)
                  Text(
                    '@${_userProfile!.username}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                const SizedBox(height: 8),
                // 账号状态
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _userProfile!.isActive
                        ? Colors.green[100]
                        : Colors.red[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _userProfile!.isActive ? '账号正常' : '账号已禁用',
                    style: TextStyle(
                      fontSize: 12,
                      color: _userProfile!.isActive
                          ? Colors.green[900]
                          : Colors.red[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 详细信息卡片
        Card(
          child: Column(
            children: [
              _buildInfoTile(
                icon: Icons.person,
                label: '用户名',
                value: _userProfile!.username,
              ),
              if (_userProfile!.phone != null)
                _buildInfoTile(
                  icon: Icons.phone,
                  label: '手机号',
                  value: _userProfile!.phone!,
                ),
              if (_userProfile!.email != null)
                _buildInfoTile(
                  icon: Icons.email,
                  label: '邮箱',
                  value: _userProfile!.email!,
                ),
              if (_userProfile!.orgId != null)
                _buildInfoTile(
                  icon: Icons.business,
                  label: '组织ID',
                  value: _userProfile!.orgId.toString(),
                ),
              _buildInfoTile(
                icon: Icons.access_time,
                label: '注册时间',
                value: _formatDate(_userProfile!.createTime),
              ),
              _buildInfoTile(
                icon: Icons.update,
                label: '更新时间',
                value: _formatDate(_userProfile!.updateTime),
                isLast: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 功能按钮区域
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.lock, color: Colors.blue),
                title: const Text('修改密码'),
                subtitle: const Text('保护账号安全'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _changePassword,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('退出登录', style: TextStyle(color: Colors.red)),
                trailing: const Icon(Icons.chevron_right, color: Colors.red),
                onTap: _logout,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.blue),
          title: Text(label),
          subtitle: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _editProfile() {
    // TODO: 跳转到编辑资料页面
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(
          userProfile: _userProfile!,
          accessToken: widget.accessToken,
        ),
      ),
    );
  }

  /// 修改密码
  void _changePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangePasswordPage(
          accessToken: widget.accessToken,
        ),
      ),
    );
  }

  /// 退出登录
  void _logout() async {
    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('退出', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 显示加载提示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // 调用退出登录接口
      final authService = AuthApiService();
      final success = await authService.logout();

      // 关闭加载提示
      if (mounted) Navigator.of(context).pop();

      if (success) {
        // 退出成功，跳转到登录页
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginPage()),
            (route) => false,
          );
        }
      } else {
        // 退出失败，显示错误提示（但依然清除了本地数据）
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('退出登录失败，但本地数据已清除')),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginPage()),
            (route) => false,
          );
        }
      }
    }
  }
}
```

### 5-1. 修改密码页面实现

```dart
import 'package:flutter/material.dart';

class ChangePasswordPage extends StatefulWidget {
  final String accessToken;

  const ChangePasswordPage({Key? key, required this.accessToken}) : super(key: key);

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('修改密码'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 安全提示卡片
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '为了保护您的账号安全，请定期修改密码',
                        style: TextStyle(color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),

            // 旧密码输入框
            TextFormField(
              controller: _oldPasswordController,
              obscureText: !_isOldPasswordVisible,
              decoration: InputDecoration(
                labelText: '旧密码',
                hintText: '请输入当前密码',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isOldPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _isOldPasswordVisible = !_isOldPasswordVisible;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入旧密码';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // 新密码输入框
            TextFormField(
              controller: _newPasswordController,
              obscureText: !_isNewPasswordVisible,
              decoration: InputDecoration(
                labelText: '新密码',
                hintText: '请输入新密码（6-100字符）',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isNewPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _isNewPasswordVisible = !_isNewPasswordVisible;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入新密码';
                }
                if (value.length < 6 || value.length > 100) {
                  return '密码长度必须在6-100字符之间';
                }
                if (value == _oldPasswordController.text) {
                  return '新密码不能与旧密码相同';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // 确认新密码输入框
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: !_isConfirmPasswordVisible,
              decoration: InputDecoration(
                labelText: '确认新密码',
                hintText: '请再次输入新密码',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请确认新密码';
                }
                if (value != _newPasswordController.text) {
                  return '两次输入的密码不一致';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // 密码强度提示
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '密码安全建议：',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTip('长度在6-100字符之间'),
                    _buildTip('建议使用字母和数字组合'),
                    _buildTip('不要使用过于简单的密码'),
                    _buildTip('不要与旧密码相同'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 提交按钮
            ElevatedButton(
              onPressed: _isLoading ? null : _submitChangePassword,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('确认修改', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  /// 提交修改密码
  Future<void> _submitChangePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userService = UserApiService(widget.accessToken);
      final result = await userService.changePassword(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      setState(() => _isLoading = false);

      if (result['success']) {
        // 修改成功
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('密码修改成功'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        // 修改失败
        if (mounted) {
          String errorMessage = result['message'] ?? '修改密码失败';
          
          // 根据错误码显示不同的提示
          if (result['code'] == 'OLD_PASSWORD_INCORRECT') {
            errorMessage = '旧密码错误，请重新输入';
          } else if (result['code'] == 'PASSWORD_NOT_CHANGED') {
            errorMessage = '新密码不能与旧密码相同';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('修改密码失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
```

### 6. 我的发表页面实现

```dart
import 'package:flutter/material.dart';

class MyPostsPage extends StatefulWidget {
  final String accessToken;

  const MyPostsPage({Key? key, required this.accessToken}) : super(key: key);

  @override
  _MyPostsPageState createState() => _MyPostsPageState();
}

class _MyPostsPageState extends State<MyPostsPage> {
  late AnnouncementApiService _apiService;
  final ScrollController _scrollController = ScrollController();
  
  List<Announcement> _announcements = [];
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _apiService = AnnouncementApiService(widget.accessToken);
    _loadMyPosts();
    
    // 监听滚动，实现分页加载
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoading && _hasMore) {
        _loadMorePosts();
      }
    }
  }

  Future<void> _loadMyPosts() async {
    setState(() => _isLoading = true);

    final response = await _apiService.getMyPosts(page: 1, size: 10);

    if (response != null) {
      setState(() {
        _announcements = response.data;
        _currentPage = response.page;
        _totalPages = response.pages;
        _hasMore = response.hasNext;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMorePosts() async {
    if (_currentPage >= _totalPages) return;

    setState(() => _isLoading = true);

    final response = await _apiService.getMyPosts(
      page: _currentPage + 1,
      size: 10,
    );

    if (response != null) {
      setState(() {
        _announcements.addAll(response.data);
        _currentPage = response.page;
        _hasMore = response.hasNext;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的发表'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadMyPosts,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _announcements.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_announcements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.post_add, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '暂无发表内容',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _announcements.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _announcements.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final announcement = _announcements[index];
        return _buildAnnouncementCard(announcement);
      },
    );
  }

  Widget _buildAnnouncementCard(Announcement announcement) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          // 跳转到详情页
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnnouncementDetailPage(
                announcementId: announcement.id,
                accessToken: widget.accessToken,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行
              Row(
                children: [
                  // 公告类型标签
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: announcement.isOfficialNotice
                          ? Colors.blue[100]
                          : Colors.green[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      announcement.isOfficialNotice ? '官方公告' : '用户帖子',
                      style: TextStyle(
                        fontSize: 12,
                        color: announcement.isOfficialNotice
                            ? Colors.blue[900]
                            : Colors.green[900],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 置顶标识
                  if (announcement.top)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '置顶',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[900],
                        ),
                      ),
                    ),
                  // 标签名称（用户帖子）
                  if (announcement.tagName != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        announcement.tagName!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              // 标题
              Text(
                announcement.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // 内容预览
              Text(
                announcement.contentText,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // 附件提示
              if (announcement.attachments.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.attach_file, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${announcement.attachments.length} 个附件',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              // 底部信息
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 发布时间
                  Text(
                    _formatDate(announcement.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  // 操作按钮
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () {
                          // 编辑公告
                        },
                        tooltip: '编辑',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () {
                          // 删除公告（需要确认）
                          _confirmDelete(announcement);
                        },
                        tooltip: '删除',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return '刚刚';
        }
        return '${difference.inMinutes}分钟前';
      }
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  void _confirmDelete(Announcement announcement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除公告"${announcement.title}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 调用删除API
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
```

---

## 使用场景

### 1. 我的页面展示

在APP的"我的"页面中，用户可以查看自己发表过的所有公告和帖子：

- 官方公告：工作相关的通知
- 用户帖子：学术讨论、经验分享等

### 2. 内容管理

用户可以在此页面管理自己的发表内容：

- 查看发表历史
- 编辑或删除内容
- 查看浏览量和反馈（如有）

### 3. 数据统计

可以基于此接口统计用户的活跃度：

- 发表总数
- 最近发表时间
- 内容类型分布

---

## 常见问题 FAQ

### Q1: 为什么我看不到自己的草稿？

**A**: 此接口只返回已发布的公告（`status = 1`）。草稿内容（`status = 0`）不会显示。如需查看草稿，请使用专门的草稿管理接口。

### Q2: 分页加载如何实现？

**A**: 
1. 首次加载：`page=1, size=10`
2. 检查 `hasNext` 字段判断是否有下一页
3. 加载更多：`page=2, size=10`
4. 将新数据追加到列表

### Q3: 如何区分官方公告和用户帖子？

**A**: 通过 `noticeType` 字段判断：
- `noticeType = 0`：官方公告，通常没有 `creatorAvatar`、`creatorName`、`tagId`、`tagName`
- `noticeType = 1`：用户帖子，有完整的创建者信息和标签信息

### Q4: Token过期了怎么办？

**A**: 当收到 `401` 或 `TOKEN_EXPIRED` 错误时：
1. 使用 Refresh Token 调用刷新接口获取新的 Access Token
2. 如果刷新失败，引导用户重新登录
3. 建议在请求拦截器中统一处理

### Q5: 如何实现下拉刷新？

**A**: 使用 Flutter 的 `RefreshIndicator` 组件：
```dart
RefreshIndicator(
  onRefresh: () async {
    await _loadMyPosts(); // 重新加载第一页
  },
  child: ListView(...),
)
```

### Q6: 附件如何下载和预览？

**A**: 
- 图片：直接使用 `Image.network(attachment.url)` 显示
- PDF：使用 `flutter_pdfview` 包打开
- 其他文件：使用 `dio` 下载到本地，然后用 `open_file` 打开

### Q7: 如何显示用户头像？

**A**: API返回的 `avatar` 字段包含头像URL路径。显示建议：
1. 如果 `avatar` 有值，使用 `NetworkImage` 或 `CachedNetworkImage` 加载显示
2. 如果 `avatar` 为 null，使用用户昵称或用户名的首字母作为默认头像
3. 建议使用 `cached_network_image` 包缓存头像图片，提升加载速度

示例代码：
```dart
CircleAvatar(
  radius: 50,
  backgroundColor: Colors.blue[100],
  backgroundImage: userProfile.hasAvatar
      ? NetworkImage(userProfile.avatar!)
      : null,
  child: !userProfile.hasAvatar
      ? Text(
          userProfile.displayName.substring(0, 1).toUpperCase(),
          style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
        )
      : null,
)
```

### Q8: 用户信息会缓存吗？

**A**: API不会在服务端缓存用户信息，每次请求都从数据库实时查询。建议：
1. 在客户端使用 `shared_preferences` 或 `hive` 缓存用户信息
2. 设置合理的缓存过期时间（如30分钟）
3. 在用户修改信息后立即更新缓存
4. APP启动时检查缓存有效性

### Q9: 如何判断用户是否被禁用？

**A**: 通过 `status` 字段判断：
- `status = 1`：账号正常，用户可以正常使用
- `status = 0`：账号已禁用，应该提示用户联系管理员

示例代码：
```dart
if (userProfile.status == 0) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('账号已被禁用'),
      content: Text('您的账号已被管理员禁用，请联系管理员处理。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('确定'),
        ),
      ],
    ),
  );
}
```

### Q10: 如何在多个页面间共享用户信息？

**A**: 推荐使用状态管理方案：
1. **Provider**: 适合中小型应用
   ```dart
   class UserProvider extends ChangeNotifier {
     UserProfile? _profile;
     
     Future<void> loadProfile(String token) async {
       _profile = await UserApiService(token).getCurrentUserProfile();
       notifyListeners();
     }
   }
   ```

2. **Riverpod**: 更现代的状态管理方案
3. **GetX**: 简单易用的状态管理
4. **Bloc**: 适合大型应用的状态管理

### Q11: 修改密码后需要重新登录吗？

**A**: 不需要。修改密码成功后，当前的JWT Token仍然有效，用户可以继续使用。技术说明：
1. 修改密码只更新数据库中的密码哈希值
2. 不会使现有Token失效
3. 用户体验更好，无需重新登录
4. 新密码在下次登录时生效

注意：如果希望修改密码后强制重新登录，需要额外实现Token黑名单机制。

### Q12: 忘记密码怎么办？

**A**: 当前版本的修改密码接口需要提供旧密码验证身份。如果忘记旧密码：
1. 应该使用"忘记密码"功能（需要单独实现）
2. 通常通过手机验证码或邮箱验证重置密码
3. 联系管理员重置密码

建议在登录页面提供"忘记密码"入口。

### Q13: 退出登录后Token还有效吗？

**A**: 是的，从技术角度讲：
1. JWT Token是无状态的，服务端不存储Token状态
2. 调用退出登录接口后，Token在服务端仍然有效（直到过期）
3. 但客户端会删除本地存储的所有Token
4. 删除Token后，即使Token未过期也无法再使用

因此，客户端退出登录的关键是**彻底删除本地存储的Token和用户信息**。

### Q14: 如何实现强制退出（踢出用户）？

**A**: 当前JWT无状态架构下，无法直接强制某个Token失效。如需实现此功能，有以下方案：

**方案一：Token黑名单（推荐）**
1. 服务端维护一个黑名单（Redis）
2. 退出登录时将Token加入黑名单
3. 每次请求验证Token是否在黑名单中
4. Token过期后自动从黑名单删除

**方案二：Token版本号**
1. 用户表增加 `token_version` 字段
2. Token中包含版本号
3. 修改密码或强制退出时，版本号+1
4. 验证Token时检查版本号是否匹配

**方案三：缩短Token有效期**
1. 将Access Token有效期设置为较短时间（如15分钟）
2. 通过Refresh Token机制延长会话
3. 退出登录时删除Refresh Token

### Q15: 如何实现密码强度验证？

**A**: 当前后端只验证密码长度（6-100字符），如需更严格的密码强度验证：

**前端验证**（推荐）：
```dart
String? validatePasswordStrength(String password) {
  if (password.length < 6) {
    return '密码长度至少6个字符';
  }
  
  // 检查是否包含字母
  if (!RegExp(r'[a-zA-Z]').hasMatch(password)) {
    return '密码必须包含字母';
  }
  
  // 检查是否包含数字
  if (!RegExp(r'\d').hasMatch(password)) {
    return '密码必须包含数字';
  }
  
  // 可选：检查是否包含特殊字符
  // if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
  //   return '密码建议包含特殊字符';
  // }
  
  return null; // 验证通过
}
```

**后端验证**：
如需在后端实现，可以在 `ChangePasswordRequest` 中添加自定义验证注解。

### Q16: 修改密码时如何防止暴力破解？

**A**: 安全建议：
1. **限流保护**: 对修改密码接口进行限流（如1分钟最多3次）
2. **验证码**: 敏感操作前要求输入图形验证码或短信验证码
3. **账号锁定**: 连续输入错误密码N次后临时锁定账号
4. **二次验证**: 重要操作前要求输入手机验证码确认身份
5. **日志记录**: 记录所有修改密码的操作（成功和失败）用于审计

---

## 错误码说明

| 错误码 | HTTP状态码 | 说明 | 解决方案 |
|--------|-----------|------|----------|
| `SUCCESS` | 200 | 请求成功 | - |
| `UNAUTHORIZED` | 401 | 未登录或Token无效 | 重新登录或刷新Token |
| `TOKEN_EXPIRED` | 401 | Token已过期 | 使用Refresh Token刷新 |
| `FORBIDDEN` | 403 | 没有权限 | 检查用户权限 |
| `USER_NOT_FOUND` | 404 | 用户不存在 | 确认用户ID是否正确 |
| `OLD_PASSWORD_INCORRECT` | 400 | 旧密码错误 | 提示用户重新输入正确的旧密码 |
| `PASSWORD_NOT_CHANGED` | 400 | 新密码与旧密码相同 | 提示用户输入不同的新密码 |
| `INVALID_PARAMETER` | 400 | 请求参数无效 | 检查参数格式和长度 |
| `SERVER_ERROR` | 500 | 服务器内部错误 | 稍后重试或联系技术支持 |

---

## 性能优化建议

### 1. 分页大小选择

- 移动端建议：`size = 10`
- 平板端建议：`size = 20`
- 避免设置过大导致加载缓慢

### 2. 图片加载优化

- 使用缩略图显示列表
- 点击查看详情时加载原图
- 使用 `cached_network_image` 包缓存图片

### 3. 列表优化

- 使用 `ListView.builder` 实现懒加载
- 监听滚动位置，提前触发下一页加载
- 使用下拉刷新和上拉加载更多

### 4. 数据缓存

- 将第一页数据缓存到本地
- 离线时显示缓存数据
- 使用 `shared_preferences` 或 `hive` 存储

---

## 安全建议

1. **Token存储**: 使用 `flutter_secure_storage` 安全存储JWT令牌
2. **HTTPS**: 生产环境必须使用HTTPS协议
3. **错误处理**: 不要在错误提示中暴露敏感信息
4. **输入验证**: 前端也应进行基础的输入验证
5. **防重复请求**: 避免用户快速多次点击触发重复请求

---

## 测试用例

### 正常场景

1. ✅ 首次加载第一页数据
2. ✅ 下拉刷新更新数据
3. ✅ 上拉加载更多数据
4. ✅ 点击跳转到详情页
5. ✅ 空状态显示（无发表内容）

### 异常场景

1. ✅ Token过期自动刷新
2. ✅ 网络错误重试
3. ✅ 已经是最后一页不再加载
4. ✅ 并发请求去重

---

## 更新日志

| 版本 | 日期 | 说明 |
|------|------|------|
| 1.3.0 | 2025-10-17 | 新增修改密码和退出登录API及完整文档（含Flutter示例） |
| 1.2.0 | 2025-10-17 | 用户个人信息API新增avatar字段（用户头像） |
| 1.1.0 | 2025-10-17 | 新增获取当前用户个人信息API文档 |
| 1.0.0 | 2025-10-17 | 初始版本，实现我的发表公告列表查询功能 |

---

**文档维护**: 后端开发团队  
**最后更新**: 2025-10-17  
**API版本**: v1.0.0  
**文档版本**: 1.3.0

