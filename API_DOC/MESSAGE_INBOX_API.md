# 消息中心 API 文档

## 基础信息

- **服务器地址**: `http://localhost:8090`
- **API版本**: v1
- **内容类型**: `application/json`
- **编码格式**: `UTF-8`
- **认证方式**: Bearer Token（JWT）

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

## 分页响应格式

分页接口返回的 `data` 字段格式：

```json
{
  "data": [/* 数据列表 */],
  "page": 1,              // 当前页码
  "size": 20,             // 每页大小
  "total": 100,           // 总记录数
  "pages": 5,             // 总页数
  "hasNext": true,        // 是否有下一页
  "hasPrev": false        // 是否有上一页
}
```

## 消息中心接口

### 1. 获取未读消息数量

**接口描述**: 获取当前登录用户的未读消息数量，用于在APP顶部显示红点提示

- **URL**: `/api/v1/messages/unread-count`
- **方法**: `GET`
- **认证**: 需要认证（Bearer Token）

#### 请求参数

无需请求参数

#### 请求头

```
Authorization: Bearer {accessToken}
```

#### 响应示例

**成功响应 (200)**:
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": 5
}
```

**失败响应 (200)**:
```json
{
  "success": false,
  "code": "UNAUTHORIZED",
  "message": "请先登录",
  "data": null
}
```

#### Flutter 调用示例

```dart
final response = await http.get(
  Uri.parse('http://localhost:8090/api/v1/messages/unread-count'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $accessToken'
  },
);

final data = jsonDecode(response.body);
if (data['success']) {
  final unreadCount = data['data'];
  print('未读消息数量: $unreadCount');
  // 显示红点提示
}
```

---

### 2. 获取未读消息列表

**接口描述**: 获取当前登录用户的未读消息列表，支持分页，按创建时间倒序排列（最新的在前）

- **URL**: `/api/v1/messages/unread`
- **方法**: `GET`
- **认证**: 需要认证（Bearer Token）

#### 请求参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| page | Integer | 否 | 1 | 页码，从1开始 |
| size | Integer | 否 | 20 | 每页大小，最大100 |

#### 请求头

```
Authorization: Bearer {accessToken}
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
        "id": 1,
        "category": "NOTICE_COMMENT",
        "resourceType": "NOTICE",
        "resourceId": 5,
        "title": "项目启动会通知",
        "contentExcerpt": "张三评论了你的帖子：这个项目时间安排很合理...",
        "fromUserName": "张三",
        "extraJson": "{\"noticeId\":5,\"commentId\":10}",
        "isRead": 0,
        "readAt": null,
        "createdAt": "2025-10-19T10:30:00"
      },
      {
        "id": 2,
        "category": "COMMENT_REPLY",
        "resourceType": "COMMENT",
        "resourceId": 8,
        "title": "Re: 项目启动会通知",
        "contentExcerpt": "李四回复了你的评论：@你的名字 我也同意这个时间...",
        "fromUserName": "李四",
        "extraJson": "{\"noticeId\":5,\"commentId\":12,\"replyToCommentId\":8}",
        "isRead": 0,
        "readAt": null,
        "createdAt": "2025-10-19T09:15:00"
      }
    ],
    "page": 1,
    "size": 20,
    "total": 2,
    "pages": 1,
    "hasNext": false,
    "hasPrev": false
  }
}
```

**失败响应 (200)**:
```json
{
  "success": false,
  "code": "UNAUTHORIZED",
  "message": "请先登录",
  "data": null
}
```

#### 响应字段说明

| 字段名 | 类型 | 说明 |
|--------|------|------|
| id | Long | 消息ID |
| category | String | 消息类别：NOTICE_COMMENT(评论帖子)、COMMENT_REPLY(回复评论) |
| resourceType | String | 资源类型：NOTICE(帖子)、COMMENT(评论) |
| resourceId | Long | 资源ID（帖子ID或评论ID） |
| title | String | 消息标题/摘要 |
| contentExcerpt | String | 内容摘录（评论内容预览） |
| fromUserName | String | 触发人姓名 |
| extraJson | String | 扩展信息（JSON格式），包含跳转所需的相关ID |
| isRead | Integer | 是否已读：0未读，1已读 |
| readAt | DateTime | 阅读时间（未读时为null） |
| createdAt | DateTime | 创建时间 |

#### Flutter 调用示例

```dart
final response = await http.get(
  Uri.parse('http://localhost:8090/api/v1/messages/unread?page=1&size=20'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $accessToken'
  },
);

final result = jsonDecode(response.body);
if (result['success']) {
  final data = result['data'];
  final messages = data['data'] as List;
  final total = data['total'];
  final hasNext = data['hasNext'];
  
  print('未读消息总数: $total');
  for (var msg in messages) {
    print('${msg['fromUserName']}: ${msg['contentExcerpt']}');
  }
  
  // 加载更多判断
  if (hasNext) {
    print('还有更多消息');
  }
}
```

---

### 3. 获取消息详情

**接口描述**: 查看指定消息的详细信息。**重要：查看消息后会自动标记为已读**。只能查看自己的消息，无法查看其他用户的消息。

- **URL**: `/api/v1/messages/{id}`
- **方法**: `GET`
- **认证**: 需要认证（Bearer Token）

#### 请求参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| id | Long | 是 | 消息ID（路径参数） |

#### 请求头

```
Authorization: Bearer {accessToken}
```

#### 响应示例

**成功响应 (200)**:
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": {
    "id": 1,
    "category": "NOTICE_COMMENT",
    "resourceType": "NOTICE",
    "resourceId": 5,
    "title": "项目启动会通知",
    "contentExcerpt": "张三评论了你的帖子：这个项目时间安排很合理，我们团队可以按时完成...",
    "fromUserName": "张三",
    "extraJson": "{\"noticeId\":5,\"commentId\":10}",
    "isRead": 1,
    "readAt": "2025-10-19T11:00:00",
    "createdAt": "2025-10-19T10:30:00"
  }
}
```

**失败响应 - 消息不存在 (200)**:
```json
{
  "success": false,
  "code": "MESSAGE_NOT_FOUND",
  "message": "消息不存在",
  "data": null
}
```

**失败响应 - 无权访问 (200)**:
```json
{
  "success": false,
  "code": "MESSAGE_ACCESS_DENIED",
  "message": "无权访问该消息",
  "data": null
}
```

**失败响应 - 未登录 (200)**:
```json
{
  "success": false,
  "code": "UNAUTHORIZED",
  "message": "请先登录",
  "data": null
}
```

#### Flutter 调用示例

```dart
final messageId = 1;
final response = await http.get(
  Uri.parse('http://localhost:8090/api/v1/messages/$messageId'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $accessToken'
  },
);

final result = jsonDecode(response.body);
if (result['success']) {
  final message = result['data'];
  print('消息详情: ${message['contentExcerpt']}');
  
  // 解析 extraJson 获取跳转信息
  final extra = jsonDecode(message['extraJson']);
  final noticeId = extra['noticeId'];
  final commentId = extra['commentId'];
  
  // 跳转到对应的帖子或评论
  // Navigator.push(...) 根据 category 和 resourceType 决定跳转页面
} else {
  print('错误: ${result['message']}');
}
```

---

## 使用场景说明

### 场景1：显示消息红点

在APP首页或导航栏，需要显示未读消息数量的红点提示：

```dart
// 获取未读消息数量
final count = await getUnreadCount();
if (count > 0) {
  // 显示红点，数量为 count
  showBadge(count);
}
```

### 场景2：消息列表页面

用户点击消息图标，进入消息列表页面，显示所有未读消息：

```dart
// 加载第一页未读消息
final messages = await getUnreadMessages(page: 1, size: 20);

// 支持下拉刷新和上拉加载更多
if (messages.hasNext) {
  // 加载下一页
  final nextPage = await getUnreadMessages(page: 2, size: 20);
}
```

### 场景3：查看消息详情并跳转

用户点击某条消息，查看详情并跳转到相关的帖子或评论：

```dart
// 1. 获取消息详情（自动标记已读）
final message = await getMessageDetail(messageId);

// 2. 解析 extraJson 获取跳转信息
final extra = jsonDecode(message.extraJson);

// 3. 根据 category 和 resourceType 决定跳转逻辑
if (message.category == 'NOTICE_COMMENT') {
  // 跳转到帖子详情，定位到对应评论
  navigateToNoticeDetail(
    noticeId: extra['noticeId'],
    commentId: extra['commentId']
  );
} else if (message.category == 'COMMENT_REPLY') {
  // 跳转到帖子详情，定位到回复
  navigateToNoticeDetail(
    noticeId: extra['noticeId'],
    commentId: extra['commentId'],
    replyToCommentId: extra['replyToCommentId']
  );
}

// 4. 刷新未读消息数量
await refreshUnreadCount();
```

---

## 错误代码说明

| 错误代码 | 说明 | 解决方案 |
|---------|------|----------|
| UNAUTHORIZED | 用户未登录或Token失效 | 重新登录获取新的Token |
| MESSAGE_NOT_FOUND | 消息不存在 | 可能已被删除，刷新列表 |
| MESSAGE_ACCESS_DENIED | 无权访问该消息 | 只能查看自己的消息 |

---

## 注意事项

1. **自动标记已读**：调用消息详情接口（`GET /api/v1/messages/{id}`）会自动将消息标记为已读，`isRead` 变为 1，`readAt` 记录阅读时间。

2. **分页限制**：未读消息列表每页最多返回100条记录，建议使用默认值20条。

3. **排序规则**：未读消息列表按创建时间倒序排列，最新的消息在最前面。

4. **权限隔离**：所有接口都基于当前登录用户，只能查看自己的消息，无法查看其他用户的消息。

5. **extraJson字段**：该字段包含跳转所需的完整信息，前端应根据 `category` 和 `resourceType` 解析并决定跳转逻辑。

6. **Token认证**：所有接口都需要在请求头中携带有效的 JWT Token。

---

## 完整工作流程示例

### Flutter 完整示例代码

```dart
class MessageService {
  final String baseUrl = 'http://localhost:8090/api/v1';
  String? accessToken;

  // 设置Token
  void setToken(String token) {
    accessToken = token;
  }

  // 获取未读消息数量
  Future<int> getUnreadCount() async {
    final response = await http.get(
      Uri.parse('$baseUrl/messages/unread-count'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken'
      },
    );

    final result = jsonDecode(response.body);
    if (result['success']) {
      return result['data'] as int;
    }
    throw Exception(result['message']);
  }

  // 获取未读消息列表
  Future<Map<String, dynamic>> getUnreadMessages({
    int page = 1, 
    int size = 20
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/messages/unread?page=$page&size=$size'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken'
      },
    );

    final result = jsonDecode(response.body);
    if (result['success']) {
      return result['data'];
    }
    throw Exception(result['message']);
  }

  // 获取消息详情（自动标记已读）
  Future<Map<String, dynamic>> getMessageDetail(int messageId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/messages/$messageId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken'
      },
    );

    final result = jsonDecode(response.body);
    if (result['success']) {
      return result['data'];
    }
    throw Exception(result['message']);
  }
}

// 使用示例
void main() async {
  final messageService = MessageService();
  messageService.setToken('your_access_token_here');

  // 1. 显示未读消息数量
  final count = await messageService.getUnreadCount();
  print('未读消息: $count');

  // 2. 加载未读消息列表
  final messagesData = await messageService.getUnreadMessages(page: 1);
  final messages = messagesData['data'] as List;
  print('消息列表: ${messages.length} 条');

  // 3. 查看第一条消息详情
  if (messages.isNotEmpty) {
    final firstMessageId = messages[0]['id'];
    final detail = await messageService.getMessageDetail(firstMessageId);
    print('消息详情: ${detail['contentExcerpt']}');
    
    // 4. 解析跳转信息
    final extra = jsonDecode(detail['extraJson']);
    print('跳转到帖子: ${extra['noticeId']}');
  }
}
```

---

## 更新日志

- **2025-10-19**: 初始版本，实现三个核心接口
  - 获取未读消息数量
  - 获取未读消息列表（分页）
  - 获取消息详情（自动标记已读）

