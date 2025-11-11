# IM 即时通讯模块 API 文档

## 概述

本文档描述 IM 即时通讯模块的 REST API 和 WebSocket 接口，包括会话管理、消息收发、群组管理、设备注册等功能。

### 技术架构

- **通讯协议**：WebSocket（实时消息） + REST API（会话管理）
- **消息序号**：使用 Redis INCR 生成会话内递增 seq
- **在线投递**：通过 WebSocket 实时推送
- **离线同步**：客户端根据 seq 拉取未读消息
- **数据隔离**：所有表带 `org_id`，实现 SaaS 多租户隔离

---

## Redis 配置说明

### 1. 配置要求

IM 模块依赖 Redis 用于生成消息序号（seq），请确保 Redis 已安装并正确配置。

**最低版本要求**：Redis 3.0+

### 2. 配置方式

在 `application.yml` 中配置 Redis 连接参数：

```yaml
spring:
  data:
    redis:
      host: localhost           # Redis 服务器地址
      port: 6379               # Redis 端口
      password:                # Redis 密码（如有）
      database: 0              # 数据库编号（0-15）
      timeout: 3000ms          # 连接超时时间
      lettuce:
        pool:
          max-active: 8        # 最大活跃连接数
          max-idle: 8          # 最大空闲连接数
          min-idle: 0          # 最小空闲连接数
          max-wait: -1ms       # 最大等待时间（-1表示不限制）
```

### 3. Redis Key 说明

IM 模块使用的 Redis Key 格式：

| Key 格式 | 说明 | 类型 | 过期时间 |
|---------|------|------|---------|
| `im:conv:seq:{convId}` | 会话消息序号计数器 | String | 永久 |

**示例**：
- `im:conv:seq:abc123def456...` → 值为该会话当前最大 seq

### 4. Redis 使用场景

- **消息 seq 生成**：通过 `INCR im:conv:seq:{convId}` 生成会话内递增序号
- **并发安全**：Redis 原子操作保证高并发下 seq 不重复
- **性能优化**：避免数据库锁竞争，提升消息发送性能

### 5. 故障处理

**Redis 连接失败**：
- 现象：消息发送失败，返回 500 错误
- 排查：检查 Redis 服务是否运行，网络是否可达
- 解决：重启 Redis 服务或检查配置

**Redis 内存不足**：
- 建议：定期清理过期数据或增加内存配置
- 监控：关注 Redis 内存使用率

---

## WebSocket 连接

### 1. 连接地址

```
ws://[host]:[port]/im/ws?token=[JWT_ACCESS_TOKEN]
```

**示例**：
```
ws://localhost:8090/im/ws?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 2. 连接流程

1. 客户端携带 JWT Token 在查询参数中发起 WebSocket 连接
2. 服务端在握手阶段验证 Token
3. 验证成功后建立连接，用户进入在线状态
4. 连接断开后用户进入离线状态

### 3. 心跳保持

**心跳机制**：
- 客户端每 30 秒发送一次纯文本消息 `PING`（不是 JSON 格式）
- 服务端收到 `PING` 后自动响应纯文本 `PONG`
- 超过 60 秒无活动可能自动断开连接

**心跳示例**：
```javascript
// 客户端发送（纯文本，不是JSON）
ws.send("PING");

// 服务端响应（纯文本，不是JSON）
"PONG"
```

**注意**：心跳消息是纯文本格式，不要包装成 JSON 对象。

### 4. 消息格式

所有 WebSocket 消息使用 JSON 格式，统一包装为 `WsMessage` 结构：

```json
{
  "type": "消息类型",
  "payload": "消息负载（具体内容根据type不同）",
  "msgId": "消息ID（客户端生成，用于追踪）",
  "timestamp": 1699999999999
}
```

### 5. 消息类型

#### 5.1 客户端发送消息类型

| type | 说明 | payload 结构 |
|------|------|-------------|
| `SEND_MSG` | 发送消息 | `{ convId, msgType, content, mentions?, mentionAll? }` |
| `SYNC_REQ` | 同步消息请求 | `{ convId, fromSeq, limit? }` |
| `READ_ACK` | 已读确认 | `{ convId, seq }` |

#### 5.2 服务端推送消息类型

| type | 说明 | payload 结构 |
|------|------|-------------|
| `MSG_RECEIVED` | 新消息通知 | `ImMessageVO` 对象 |
| `SYNC_RESP` | 同步消息响应 | `{ messages: [...] }` |
| `SYSTEM_NOTIFY` | 系统通知 | `{ title, content, ... }` |

#### 5.3 服务端确认消息类型

所有客户端请求都会收到 `WsMessageAck` 确认：

```json
{
  "msgId": "原消息ID",
  "success": true,
  "data": { "seq": 123, "messageId": 456 },
  "error": null
}
```

---

## REST API 接口

### 通用说明

- **Base URL**：`/api/v1/im`
- **认证方式**：JWT Bearer Token（Header: `Authorization: Bearer {token}`）
- **响应格式**：统一使用 `ApiResponse<T>` 包装

**ApiResponse 结构**：
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": { ... }
}
```

---

## 一、会话管理 API

### 1.1 获取会话列表

**接口**：`GET /conversations`

**描述**：获取当前用户的会话列表，按最后消息时间倒序排列

**请求参数**：

| 参数 | 类型 | 必填 | 说明 |
|-----|------|-----|------|
| page | Integer | 否 | 页码，默认 1 |
| pageSize | Integer | 否 | 每页数量，默认 20 |

**请求示例**：
```http
GET /api/v1/im/conversations?page=1&pageSize=20
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**响应示例**：
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": [
    {
      "convId": "abc123def456...",
      "type": "SINGLE",
      "title": "张三",
      "avatar": "https://example.com/avatar.jpg",
      "lastMessageSeq": 125,
      "lastMessageAt": "2025-11-11T10:30:00",
      "lastMessageContent": "好的，明天见",
      "lastMessageType": "TEXT",
      "unreadCount": 3,
      "createdAt": "2025-11-10T08:00:00"
    },
    {
      "convId": "xyz789ghi012...",
      "type": "GROUP",
      "title": "项目讨论组",
      "avatar": "https://example.com/group.jpg",
      "lastMessageSeq": 89,
      "lastMessageAt": "2025-11-11T09:15:00",
      "lastMessageContent": "[图片]",
      "lastMessageType": "IMAGE",
      "unreadCount": 0,
      "createdAt": "2025-11-08T14:20:00"
    }
  ]
}
```

**字段说明**：

| 字段 | 类型 | 说明 |
|-----|------|------|
| convId | String | 会话ID（32字符） |
| type | String | 会话类型：SINGLE（单聊）/GROUP（群聊）/SYSTEM（系统） |
| title | String | 会话标题（单聊为对方昵称，群聊为群名） |
| avatar | String | 会话头像URL |
| lastMessageSeq | Long | 最新消息seq |
| lastMessageAt | DateTime | 最新消息时间 |
| lastMessageContent | String | 最后一条消息内容摘要（用于列表展示） |
| lastMessageType | String | 最后一条消息类型（TEXT/IMAGE/FILE/AUDIO/VIDEO/CARD/SYSTEM） |
| unreadCount | Integer | 未读数量 |
| createdAt | DateTime | 创建时间 |

**重要说明 - title 和 avatar 动态获取逻辑**：

- **单聊会话（SINGLE）**：
  - `title`：对方用户的昵称（nickname），如果没有昵称则使用用户名（username）
  - `avatar`：对方用户的头像URL（从 t_person.avatar 关联获取）
  - 这些信息是动态查询的，而非存储在 im_conversation 表中

- **群聊会话（GROUP）**：
  - `title`：群组名称（存储在 im_group.name）
  - `avatar`：群组头像URL（存储在 im_group.avatar）
  - 这些信息存储在群组表中

- **系统会话（SYSTEM）**：
  - `title` 和 `avatar` 使用系统预设值

**重要说明 - lastMessageContent 消息摘要生成规则**：

`lastMessageContent` 字段用于在会话列表中显示最后一条消息的摘要，根据不同的消息类型生成：

| 消息类型 | 显示规则 |
|---------|---------|
| TEXT | 显示文本内容（最多50字，超出显示省略号） |
| IMAGE | 显示 "[图片]" |
| FILE | 显示 "[文件] 文件名" |
| AUDIO | 显示 "[语音]" |
| VIDEO | 显示 "[视频]" |
| CARD | 显示 "[卡片] 标题" |
| SYSTEM | 显示 "[系统消息]" |
| 已撤回消息 | 显示 "[消息已撤回]" |
| 无消息 | `null` |

**示例**：
- 文本消息：`"明天下午2点开会"`
- 长文本消息：`"这是一条很长很长的消息内容，超过50个字符后会自动截断并..."`
- 图片消息：`"[图片]"`
- 文件消息：`"[文件] 项目文档.pdf"`
- 撤回的消息：`"[消息已撤回]"`

---

### 1.2 获取会话详情

**接口**：`GET /conversations/{convId}`

**描述**：获取指定会话的详细信息

**路径参数**：

| 参数 | 类型 | 必填 | 说明 |
|-----|------|-----|------|
| convId | String | 是 | 会话ID |

**请求示例**：
```http
GET /api/v1/im/conversations/abc123def456...
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**响应示例**：
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": {
    "convId": "abc123def456...",
    "type": "SINGLE",
    "title": "张三",
    "avatar": "https://example.com/avatar.jpg",
    "lastMessageSeq": 125,
    "lastMessageAt": "2025-11-11T10:30:00",
    "lastMessageContent": "好的，明天见",
    "lastMessageType": "TEXT",
    "unreadCount": 3,
    "createdAt": "2025-11-10T08:00:00"
  }
}
```

---

### 1.3 获取未读消息总数

**接口**：`GET /conversations/unread-count`

**描述**：获取当前用户所有会话的未读消息总数，用于首页消息图标的角标显示

**请求参数**：无

**请求示例**：
```http
GET /api/v1/im/conversations/unread-count
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**响应示例**：
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": {
    "totalUnread": 15
  }
}
```

**字段说明**：

| 字段 | 类型 | 说明 |
|-----|------|------|
| totalUnread | Integer | 未读消息总数（所有会话的未读消息之和） |

**计算逻辑**：
- 查询用户所有会话的成员记录
- 对于每个会话，计算未读数 = `lastMessageSeq - lastReadSeq`
- 将所有会话的未读数求和得到总未读数
- 如果某个会话的 `lastMessageSeq` 为 null（无消息）或 `lastReadSeq >= lastMessageSeq`（已读完），则该会话未读数为 0

**使用场景**：
- 首页进入时显示消息图标角标
- 定时轮询更新角标数字（建议间隔30秒-1分钟）
- 发送/接收消息后刷新角标

**Flutter 调用示例**：
```dart
Future<int> getUnreadCount() async {
  final response = await http.get(
    Uri.parse('http://localhost:8090/api/v1/im/conversations/unread-count'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken'
    },
  );

  final result = jsonDecode(response.body);
  if (result['success']) {
    return result['data']['totalUnread'] as int;
  } else {
    throw Exception(result['message']);
  }
}

// 使用示例：显示角标
void updateBadge() async {
  try {
    int unreadCount = await getUnreadCount();
    setState(() {
      _badgeCount = unreadCount;
    });
    
    // 如果有未读消息，显示角标
    if (unreadCount > 0) {
      // 更新 UI 显示角标
      // 例如：Badge(count: unreadCount, child: Icon(Icons.message))
    }
  } catch (e) {
    print('获取未读消息总数失败: $e');
  }
}
```

---

### 1.4 创建单聊会话

**接口**：`POST /conversations/single`

**描述**：创建一对一单聊会话，如果已存在则返回现有会话

**请求体**：
```json
{
  "targetUserId": 123
}
```

**请求参数**：

| 参数 | 类型 | 必填 | 说明 |
|-----|------|-----|------|
| targetUserId | Long | 是 | 对方用户ID |

**请求示例**：
```http
POST /api/v1/im/conversations/single
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "targetUserId": 123
}
```

**响应示例**：
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": {
    "convId": "abc123def456...",
    "type": "SINGLE",
    "title": null,
    "avatar": null,
    "lastMessageSeq": 0,
    "lastMessageAt": null,
    "unreadCount": 0,
    "createdAt": "2025-11-11T10:35:00"
  }
}
```

---

### 1.5 创建群聊会话

**接口**：`POST /conversations/group`

**描述**：创建群聊会话

**请求体**：
```json
{
  "name": "项目讨论组",
  "memberUserIds": [123, 456, 789],
  "avatar": "https://example.com/group.jpg",
  "notice": "欢迎加入项目讨论组"
}
```

**请求参数**：

| 参数 | 类型 | 必填 | 说明 |
|-----|------|-----|------|
| name | String | 是 | 群名称（最长200字符） |
| memberUserIds | Array<Long> | 是 | 群成员用户ID列表（不包含创建者，至少1个） |
| avatar | String | 否 | 群头像URL |
| notice | String | 否 | 群公告 |

**请求示例**：
```http
POST /api/v1/im/conversations/group
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "name": "项目讨论组",
  "memberUserIds": [123, 456, 789],
  "avatar": "https://example.com/group.jpg",
  "notice": "欢迎加入项目讨论组"
}
```

**响应示例**：
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": null
}
```

---

## 二、消息管理 API

### 2.1 发送消息（备用）

**接口**：`POST /messages`

**描述**：通过 REST API 发送消息（主要通过 WebSocket 发送，此接口作为备用）

**请求体**：
```json
{
  "convId": "abc123def456...",
  "msgType": "TEXT",
  "content": "你好，这是一条测试消息",
  "mentions": [123, 456],
  "mentionAll": false
}
```

**请求参数**：

| 参数 | 类型 | 必填 | 说明 |
|-----|------|-----|------|
| convId | String | 是 | 会话ID |
| msgType | String | 是 | 消息类型：TEXT/IMAGE/FILE/AUDIO/VIDEO/CARD/SYSTEM |
| content | Object | 是 | 消息内容（根据msgType不同而不同） |
| mentions | Array<Long> | 否 | @的用户ID列表 |
| mentionAll | Boolean | 否 | 是否@所有人 |

**消息内容格式**：

根据 `msgType` 不同，`content` 的格式也不同：

**TEXT（文本消息）**：
```json
{
  "text": "你好，这是一条测试消息"
}
```

**IMAGE（图片消息）**：
```json
{
  "fileId": 123,
  "url": "https://example.com/image.jpg",
  "width": 800,
  "height": 600,
  "size": 102400
}
```

**FILE（文件消息）**：
```json
{
  "fileId": 456,
  "url": "https://example.com/document.pdf",
  "filename": "项目方案.pdf",
  "size": 2048000
}
```

**请求示例**：
```http
POST /api/v1/im/messages
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "convId": "abc123def456...",
  "msgType": "TEXT",
  "content": {
    "text": "你好，这是一条测试消息"
  }
}
```

**响应示例**：
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": {
    "id": 1001,
    "convId": "abc123def456...",
    "seq": 126,
    "senderUserId": 100,
    "senderName": "李四",
    "senderAvatar": "https://example.com/avatar.jpg",
    "msgType": "TEXT",
    "body": {
      "text": "你好，这是一条测试消息"
    },
    "mentions": null,
    "isRevoked": false,
    "revokeAt": null,
    "createdAt": "2025-11-11T10:40:00"
  }
}
```

**消息对象字段说明**：

| 字段 | 类型 | 说明 |
|-----|------|------|
| id | Long | 消息ID |
| convId | String | 会话ID |
| seq | Long | 会话内序号（递增） |
| senderUserId | Long | 发送人用户ID |
| senderName | String | 发送人姓名（动态查询） |
| senderAvatar | String | 发送人头像URL（动态查询） |
| msgType | String | 消息类型（TEXT/IMAGE/FILE/AUDIO/VIDEO/CARD/SYSTEM） |
| body | Object | 消息内容（根据msgType不同而不同） |
| mentions | Object | @信息（可选） |
| isRevoked | Boolean | 是否已撤回 |
| revokeAt | DateTime | 撤回时间（可选） |
| createdAt | DateTime | 创建时间 |

**重要说明 - senderName 和 senderAvatar 动态获取逻辑**：

- **senderName**：发送人的姓名，从 t_user 表查询，优先使用 `nickname`（昵称），如果为空则使用 `username`（用户名）
- **senderAvatar**：发送人的头像URL，从 t_person.avatar 关联查询获取
- 这两个字段是在返回消息时动态查询填充的，而非存储在 im_message 表中
- 如果查询不到发送人信息，这两个字段可能为 null

---

### 2.2 获取历史消息

**接口**：`GET /messages/{convId}/history`

**描述**：获取会话的历史消息，按 seq 倒序返回

**路径参数**：

| 参数 | 类型 | 必填 | 说明 |
|-----|------|-----|------|
| convId | String | 是 | 会话ID |

**查询参数**：

| 参数 | 类型 | 必填 | 说明 |
|-----|------|-----|------|
| maxSeq | Long | 否 | 最大seq（不包含），不传表示从最新开始 |
| limit | Integer | 否 | 限制数量，默认50 |

**请求示例**：
```http
GET /api/v1/im/messages/abc123def456.../history?maxSeq=125&limit=20
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**响应示例**：
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": [
    {
      "id": 1001,
      "convId": "abc123def456...",
      "seq": 124,
      "senderUserId": 100,
      "senderName": "李四",
      "senderAvatar": "https://example.com/avatar.jpg",
      "msgType": "TEXT",
      "body": {
        "text": "好的，明天见"
      },
      "mentions": null,
      "isRevoked": false,
      "revokeAt": null,
      "createdAt": "2025-11-11T10:30:00"
    },
    {
      "id": 1000,
      "convId": "abc123def456...",
      "seq": 123,
      "senderUserId": 123,
      "senderName": "张三",
      "senderAvatar": "https://example.com/avatar2.jpg",
      "msgType": "TEXT",
      "body": {
        "text": "明天下午开会"
      },
      "mentions": null,
      "isRevoked": false,
      "revokeAt": null,
      "createdAt": "2025-11-11T10:25:00"
    }
  ]
}
```

**使用场景**：
- 初次进入会话，加载最近的消息
- 向上滚动查看更早的消息（传入当前最小 seq 作为 maxSeq）

---

### 2.3 撤回消息

**接口**：`DELETE /messages/{messageId}`

**描述**：撤回已发送的消息（仅限发送者，发送后2分钟内）

**路径参数**：

| 参数 | 类型 | 必填 | 说明 |
|-----|------|-----|------|
| messageId | Long | 是 | 消息ID |

**请求示例**：
```http
DELETE /api/v1/im/messages/1001
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**响应示例**：
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": "消息已撤回"
}
```

**错误示例**：
```json
{
  "success": false,
  "code": "REVOKE_TIMEOUT",
  "message": "消息发送超过2分钟，无法撤回",
  "data": null
}
```

---

### 2.4 更新已读位置

**接口**：`PUT /messages/{convId}/read`

**描述**：更新用户在会话中的已读位置

**路径参数**：

| 参数 | 类型 | 必填 | 说明 |
|-----|------|-----|------|
| convId | String | 是 | 会话ID |

**请求体**：
```json
{
  "convId": "abc123def456...",
  "seq": 125
}
```

**请求参数**：

| 参数 | 类型 | 必填 | 说明 |
|-----|------|-----|------|
| convId | String | 是 | 会话ID（必须与路径参数一致） |
| seq | Long | 是 | 已读到的seq |

**请求示例**：
```http
PUT /api/v1/im/messages/abc123def456.../read
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "convId": "abc123def456...",
  "seq": 125
}
```

**响应示例**：
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": "已读位置已更新"
}
```

---

## 三、群组管理 API

### 3.1 获取群组详情

**接口**：`GET /groups/{convId}`

**描述**：获取群组的详细信息

**路径参数**：

| 参数 | 类型 | 必填 | 说明 |
|-----|------|-----|------|
| convId | String | 是 | 会话ID（群聊） |

**请求示例**：
```http
GET /api/v1/im/groups/xyz789ghi012...
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**响应示例**：
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": {
    "convId": "xyz789ghi012...",
    "name": "项目讨论组",
    "avatar": "https://example.com/group.jpg",
    "notice": "欢迎加入项目讨论组",
    "ownerUserId": 100,
    "memberCount": 15,
    "joinApprove": false,
    "createdAt": "2025-11-08T14:20:00"
  }
}
```

**字段说明**：

| 字段 | 类型 | 说明 |
|-----|------|------|
| convId | String | 会话ID |
| name | String | 群名称 |
| avatar | String | 群头像URL |
| notice | String | 群公告 |
| ownerUserId | Long | 群主用户ID |
| memberCount | Integer | 群成员数量 |
| joinApprove | Boolean | 加群是否需要审核 |
| createdAt | DateTime | 创建时间 |

---

### 3.2 更新群信息

**接口**：`PUT /groups/{convId}`

**描述**：更新群聊的名称、头像、公告等信息（需要群主或管理员权限）

**路径参数**：

| 参数 | 类型 | 必填 | 说明 |
|-----|------|-----|------|
| convId | String | 是 | 会话ID |

**请求体**：
```json
{
  "name": "项目核心讨论组",
  "avatar": "https://example.com/new_group.jpg",
  "notice": "本群仅讨论项目核心问题"
}
```

**请求参数**（所有参数都是可选的，只更新提供的字段）：

| 参数 | 类型 | 必填 | 说明 |
|-----|------|-----|------|
| name | String | 否 | 群名称 |
| avatar | String | 否 | 群头像URL |
| notice | String | 否 | 群公告 |

**请求示例**：
```http
PUT /api/v1/im/groups/xyz789ghi012...
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "name": "项目核心讨论组",
  "notice": "本群仅讨论项目核心问题"
}
```

**响应示例**：
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": "群信息已更新"
}
```

---

### 3.3 添加群成员

**接口**：`POST /groups/{convId}/members`

**描述**：向群聊添加新成员

**路径参数**：

| 参数 | 类型 | 必填 | 说明 |
|-----|------|-----|------|
| convId | String | 是 | 会话ID |

**请求体**：
```json
{
  "userIds": [200, 201, 202]
}
```

**请求参数**：

| 参数 | 类型 | 必填 | 说明 |
|-----|------|-----|------|
| userIds | Array<Long> | 是 | 要添加的用户ID列表（至少1个） |

**请求示例**：
```http
POST /api/v1/im/groups/xyz789ghi012.../members
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "userIds": [200, 201, 202]
}
```

**响应示例**：
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": "成员已添加"
}
```

---

### 3.4 移除群成员

**接口**：`DELETE /groups/{convId}/members/{userId}`

**描述**：从群聊中移除成员（需要群主或管理员权限，不能移除群主）

**路径参数**：

| 参数 | 类型 | 必填 | 说明 |
|-----|------|-----|------|
| convId | String | 是 | 会话ID |
| userId | Long | 是 | 要移除的用户ID |

**请求示例**：
```http
DELETE /api/v1/im/groups/xyz789ghi012.../members/200
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**响应示例**：
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": "成员已移除"
}
```

---

### 3.5 退出群聊

**接口**：`POST /groups/{convId}/quit`

**描述**：退出群聊（群主需要先转让群主才能退出）

**路径参数**：

| 参数 | 类型 | 必填 | 说明 |
|-----|------|-----|------|
| convId | String | 是 | 会话ID |

**请求示例**：
```http
POST /api/v1/im/groups/xyz789ghi012.../quit
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**响应示例**：
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": "已退出群聊"
}
```

**错误示例**：
```json
{
  "success": false,
  "code": "OWNER_CANNOT_QUIT",
  "message": "群主不能退出群聊，请先转让群主",
  "data": null
}
```

---

### 3.6 转让群主

**接口**：`POST /groups/{convId}/transfer`

**描述**：将群主转让给其他成员（仅限群主操作）

**路径参数**：

| 参数 | 类型 | 必填 | 说明 |
|-----|------|-----|------|
| convId | String | 是 | 会话ID |

**请求体**：
```json
{
  "newOwnerId": 123
}
```

**请求参数**：

| 参数 | 类型 | 必填 | 说明 |
|-----|------|-----|------|
| newOwnerId | Long | 是 | 新群主的用户ID |

**请求示例**：
```http
POST /api/v1/im/groups/xyz789ghi012.../transfer
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "newOwnerId": 123
}
```

**响应示例**：
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": "群主已转让"
}
```

---

### 3.7 获取群成员列表

**接口**：`GET /groups/{convId}/members`

**描述**：获取群聊的所有成员列表

**路径参数**：

| 参数 | 类型 | 必填 | 说明 |
|-----|------|-----|------|
| convId | String | 是 | 会话ID |

**请求示例**：
```http
GET /api/v1/im/groups/xyz789ghi012.../members
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**响应示例**：
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": [
    {
      "userId": 100,
      "userName": "李四",
      "userAvatar": "https://example.com/avatar.jpg",
      "role": 2,
      "roleName": "群主",
      "joinAt": "2025-11-08T14:20:00",
      "isMuted": false
    },
    {
      "userId": 123,
      "userName": "张三",
      "userAvatar": "https://example.com/avatar2.jpg",
      "role": 0,
      "roleName": "成员",
      "joinAt": "2025-11-08T14:25:00",
      "isMuted": false
    }
  ]
}
```

**字段说明**：

| 字段 | 类型 | 说明 |
|-----|------|------|
| userId | Long | 用户ID |
| userName | String | 用户姓名 |
| userAvatar | String | 用户头像URL |
| role | Integer | 角色：0=普通成员，1=管理员，2=群主 |
| roleName | String | 角色名称 |
| joinAt | DateTime | 加入时间 |
| isMuted | Boolean | 是否被禁言 |

---

## 四、设备管理 API

### 4.1 注册设备

**接口**：`POST /devices`

**描述**：注册或更新设备信息，为推送功能做准备

**请求体**：
```json
{
  "platform": "iOS",
  "deviceId": "DEVICE-UUID-12345",
  "pushToken": "apns-token-abcdef...",
  "appBundle": "com.example.app"
}
```

**请求参数**：

| 参数 | 类型 | 必填 | 说明 |
|-----|------|-----|------|
| platform | String | 是 | 平台：iOS/Android/Web |
| deviceId | String | 是 | 设备唯一标识 |
| pushToken | String | 否 | 推送令牌（APNs/FCM等） |
| appBundle | String | 否 | 应用包名/Bundle ID |

**请求示例**：
```http
POST /api/v1/im/devices
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "platform": "iOS",
  "deviceId": "DEVICE-UUID-12345",
  "pushToken": "apns-token-abcdef...",
  "appBundle": "com.example.app"
}
```

**响应示例**：
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": {
    "id": 1,
    "platform": "iOS",
    "deviceId": "DEVICE-UUID-12345",
    "lastActiveAt": "2025-11-11T10:50:00",
    "isActive": true
  }
}
```

---

### 4.2 获取设备列表

**接口**：`GET /devices`

**描述**：获取当前用户的所有设备列表

**请求示例**：
```http
GET /api/v1/im/devices
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**响应示例**：
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": [
    {
      "id": 1,
      "platform": "iOS",
      "deviceId": "DEVICE-UUID-12345",
      "lastActiveAt": "2025-11-11T10:50:00",
      "isActive": true
    },
    {
      "id": 2,
      "platform": "Android",
      "deviceId": "DEVICE-UUID-67890",
      "lastActiveAt": "2025-11-10T15:30:00",
      "isActive": false
    }
  ]
}
```

---

### 4.3 删除设备

**接口**：`DELETE /devices/{deviceId}`

**描述**：删除指定设备

**路径参数**：

| 参数 | 类型 | 必填 | 说明 |
|-----|------|-----|------|
| deviceId | Long | 是 | 设备ID |

**请求示例**：
```http
DELETE /api/v1/im/devices/2
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**响应示例**：
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": "设备已删除"
}
```

---

## 五、WebSocket 消息示例

### 5.1 发送文本消息

**客户端发送**：
```json
{
  "type": "SEND_MSG",
  "msgId": "client-msg-001",
  "timestamp": 1699999999999,
  "payload": {
    "convId": "abc123def456...",
    "msgType": "TEXT",
    "content": {
      "text": "你好，这是通过WebSocket发送的消息"
    }
  }
}
```

**服务端确认**：
```json
{
  "msgId": "client-msg-001",
  "success": true,
  "data": {
    "seq": 127,
    "messageId": 1002
  },
  "error": null
}
```

**其他在线成员收到通知**：
```json
{
  "type": "MSG_RECEIVED",
  "payload": {
    "id": 1002,
    "convId": "abc123def456...",
    "seq": 127,
    "senderUserId": 100,
    "senderName": "李四",
    "senderAvatar": "https://example.com/avatar.jpg",
    "msgType": "TEXT",
    "body": {
      "text": "你好，这是通过WebSocket发送的消息"
    },
    "mentions": null,
    "isRevoked": false,
    "revokeAt": null,
    "createdAt": "2025-11-11T11:00:00"
  },
  "msgId": null,
  "timestamp": 1699999999999
}
```

---

### 5.2 同步新消息

**客户端请求**：
```json
{
  "type": "SYNC_REQ",
  "msgId": "client-sync-001",
  "timestamp": 1699999999999,
  "payload": {
    "convId": "abc123def456...",
    "fromSeq": 120,
    "limit": 50
  }
}
```

**服务端响应**：
```json
{
  "msgId": "client-sync-001",
  "success": true,
  "data": {
    "messages": [
      {
        "id": 998,
        "convId": "abc123def456...",
        "seq": 121,
        "senderUserId": 123,
        "msgType": "TEXT",
        "body": { "text": "消息1" },
        "createdAt": "2025-11-11T09:00:00"
      },
      {
        "id": 999,
        "convId": "abc123def456...",
        "seq": 122,
        "senderUserId": 100,
        "msgType": "TEXT",
        "body": { "text": "消息2" },
        "createdAt": "2025-11-11T09:05:00"
      }
    ]
  },
  "error": null
}
```

---

### 5.3 更新已读

**客户端发送**：
```json
{
  "type": "READ_ACK",
  "msgId": "client-read-001",
  "timestamp": 1699999999999,
  "payload": {
    "convId": "abc123def456...",
    "seq": 127
  }
}
```

**服务端确认**：
```json
{
  "msgId": "client-read-001",
  "success": true,
  "data": null,
  "error": null
}
```

---

## 六、错误码说明

### 6.1 通用错误码

| 错误码 | 说明 | HTTP状态码 |
|-------|------|-----------|
| SUCCESS | 成功 | 200 |
| UNAUTHORIZED | 未认证/Token无效 | 401 |
| FORBIDDEN | 无权限 | 403 |
| NOT_FOUND | 资源不存在 | 404 |
| INTERNAL_ERROR | 服务器内部错误 | 500 |

### 6.2 IM 模块错误码

| 错误码 | 说明 |
|-------|------|
| CONV_NOT_FOUND | 会话不存在 |
| NOT_MEMBER | 不是会话成员 |
| MSG_NOT_FOUND | 消息不存在 |
| NOT_SENDER | 不是消息发送者 |
| REVOKE_TIMEOUT | 撤回超时（超过2分钟） |
| GROUP_NOT_FOUND | 群组不存在 |
| NOT_OWNER | 不是群主 |
| NO_PERMISSION | 无权限操作 |
| CANNOT_REMOVE_OWNER | 不能移除群主 |
| OWNER_CANNOT_QUIT | 群主不能退出（需先转让） |
| INVALID_PARAM | 参数无效 |
| JSON_ERROR | JSON转换失败 |

---

## 七、客户端集成指南

### 7.1 连接流程

```javascript
// 1. 获取 JWT Token（登录后获得）
const token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...";

// 2. 建立 WebSocket 连接
const ws = new WebSocket(`ws://localhost:8090/im/ws?token=${token}`);

// 3. 监听连接事件
ws.onopen = () => {
  console.log('WebSocket 连接已建立');
  
  // 启动心跳
  startHeartbeat();
};

ws.onmessage = (event) => {
  const data = event.data;
  
  // 处理心跳响应（纯文本）
  if (data === "PONG") {
    console.log('收到心跳响应');
    return;
  }
  
  // 处理业务消息（JSON格式）
  try {
    const message = JSON.parse(data);
    handleMessage(message);
  } catch (e) {
    console.error('解析消息失败:', e);
  }
};

ws.onerror = (error) => {
  console.error('WebSocket 错误:', error);
};

ws.onclose = () => {
  console.log('WebSocket 连接已关闭');
  stopHeartbeat();
  // 可以实现自动重连逻辑
};

// 心跳定时器
let heartbeatTimer = null;

// 启动心跳
function startHeartbeat() {
  heartbeatTimer = setInterval(() => {
    if (ws.readyState === WebSocket.OPEN) {
      ws.send("PING");  // 发送纯文本PING
      console.log('发送心跳PING');
    }
  }, 30000); // 每30秒发送一次
}

// 停止心跳
function stopHeartbeat() {
  if (heartbeatTimer) {
    clearInterval(heartbeatTimer);
    heartbeatTimer = null;
  }
}
```

### 7.2 发送消息

```javascript
function sendMessage(convId, text) {
  const message = {
    type: 'SEND_MSG',
    msgId: generateMsgId(), // 生成唯一ID
    timestamp: Date.now(),
    payload: {
      convId: convId,
      msgType: 'TEXT',
      content: { text: text }
    }
  };
  
  ws.send(JSON.stringify(message));
}
```

### 7.3 处理接收消息

```javascript
function handleMessage(message) {
  // 处理服务端确认
  if (message.msgId && message.success !== undefined) {
    handleAck(message);
    return;
  }
  
  // 处理不同类型的消息
  switch (message.type) {
    case 'MSG_RECEIVED':
      onNewMessage(message.payload);
      break;
    case 'SYNC_RESP':
      onSyncResponse(message.payload);
      break;
    case 'SYSTEM_NOTIFY':
      onSystemNotify(message.payload);
      break;
  }
}
```

### 7.4 同步离线消息

```javascript
function syncMessages(convId, fromSeq) {
  const message = {
    type: 'SYNC_REQ',
    msgId: generateMsgId(),
    timestamp: Date.now(),
    payload: {
      convId: convId,
      fromSeq: fromSeq,
      limit: 50
    }
  };
  
  ws.send(JSON.stringify(message));
}
```

### 7.5 更新已读

```javascript
function updateRead(convId, seq) {
  const message = {
    type: 'READ_ACK',
    msgId: generateMsgId(),
    timestamp: Date.now(),
    payload: {
      convId: convId,
      seq: seq
    }
  };
  
  ws.send(JSON.stringify(message));
}
```

---

## 八、数据库表结构

### 8.1 核心表

| 表名 | 说明 |
|-----|------|
| im_conversation | 会话表 |
| im_conversation_member | 会话成员表 |
| im_message | 消息表 |
| im_group | 群组信息表 |
| im_device | 设备表 |
| im_attachment | 附件表 |
| im_msg_read | 消息已读明细表 |

详细表结构请参考数据库 DDL 文件：`sql/im-sql.sql`

---

## 九、性能优化建议

### 9.1 Redis 优化

- **连接池配置**：根据并发量调整 max-active 和 max-idle
- **超时设置**：合理设置 timeout 避免长时间等待
- **内存监控**：定期监控 Redis 内存使用情况

### 9.2 WebSocket 优化

- **心跳机制**：实现心跳保持连接活跃
- **断线重连**：客户端实现自动重连逻辑
- **消息确认**：使用 msgId 追踪消息状态

### 9.3 消息查询优化

- **分页加载**：历史消息采用分页加载，避免一次加载过多
- **seq 索引**：数据库中 seq 字段已建立索引，查询效率高
- **本地缓存**：客户端缓存已加载的消息，减少网络请求

---

## 十、常见问题 FAQ

### Q1: Redis 连接失败怎么办？
**A**: 检查以下几点：
1. Redis 服务是否正在运行
2. 配置的 host 和 port 是否正确
3. 是否需要密码认证
4. 防火墙是否允许访问

### Q2: WebSocket 连接失败？
**A**: 常见原因：
1. Token 无效或过期
2. WebSocket 端点路径错误
3. 网络不可达
4. 服务端未启动

### Q3: 如何判断消息是否发送成功？
**A**: 通过 msgId 追踪：
1. 发送消息时生成唯一 msgId
2. 等待服务端返回带有相同 msgId 的确认消息
3. 确认消息中 success=true 表示成功

### Q4: 离线消息如何同步？
**A**: 
1. 客户端记录本地最后一条消息的 seq
2. 重新连接后使用 SYNC_REQ 请求，传入 fromSeq
3. 服务端返回所有 seq > fromSeq 的消息

### Q5: 群聊消息如何显示已读人数？
**A**: 
- 群聊消息的已读明细存储在 `im_msg_read` 表
- 可通过查询该表统计已读人数
- 当前 API 暂未提供，可根据需要扩展

---

## 附录

### A. 消息类型详细说明

| msgType | 说明 | content 结构示例 |
|---------|------|-----------------|
| TEXT | 文本消息 | `{ "text": "消息内容" }` |
| IMAGE | 图片消息 | `{ "fileId": 123, "url": "...", "width": 800, "height": 600 }` |
| FILE | 文件消息 | `{ "fileId": 456, "url": "...", "filename": "文件名", "size": 1024 }` |
| AUDIO | 语音消息 | `{ "fileId": 789, "url": "...", "duration": 30 }` |
| VIDEO | 视频消息 | `{ "fileId": 101, "url": "...", "duration": 120, "cover": "..." }` |
| CARD | 卡片消息 | `{ "title": "标题", "desc": "描述", "url": "链接" }` |
| SYSTEM | 系统消息 | `{ "action": "JOIN", "userId": 123, "userName": "张三" }` |

### B. 联系方式

如有问题或建议，请联系开发团队。

---

## 更新日志

### v1.1 (2025-11-11)

**新增功能**：
- 新增获取未读消息总数接口 `GET /conversations/unread-count`
  - 用于首页消息图标角标显示
  - 返回所有会话的未读消息总和
  - 支持定时轮询更新
  - 修复：兼容 MySQL BIGINT 类型，安全处理 `BigInteger` 转换

- **会话列表增强**：
  - 新增 `lastMessageContent` 字段：显示最后一条消息的内容摘要
  - 新增 `lastMessageType` 字段：标识最后一条消息的类型
  - 智能生成消息摘要：
    - 文本消息显示原文（最多50字）
    - 图片/文件/语音/视频等显示类型标识（如 "[图片]"）
    - 已撤回消息显示 "[消息已撤回]"
  - 用于会话列表中展示最后一条消息内容

**Bug 修复**：
- 修复会话列表和会话详情接口中 `avatar` 字段返回 null 的问题
- 修复单聊会话 `title` 字段未正确显示对方用户昵称的问题
- 修复消息接口中 `senderName` 和 `senderAvatar` 字段返回 null 的问题

**实现细节**：
- **会话相关**：
  - 单聊会话的 `title` 和 `avatar` 现在动态从对方用户信息中获取
  - `title` 优先使用对方用户的 `nickname`，如果为空则使用 `username`
  - `avatar` 从 `t_person.avatar` 关联查询获取
  - 群聊会话继续使用存储在 `im_group` 表中的群名和群头像

- **消息相关**：
  - 消息的 `senderName` 和 `senderAvatar` 现在动态从发送者用户信息中获取
  - `senderName` 优先使用发送者的 `nickname`，如果为空则使用 `username`
  - `senderAvatar` 从 `t_person.avatar` 关联查询获取
  - 适用于所有消息相关接口：发送消息、获取历史消息、WebSocket 实时推送

- **未读消息总数**：
  - 通过 JOIN 查询用户所有会话及其最新消息 seq
  - 对每个会话计算未读数（lastMessageSeq - lastReadSeq）
  - 求和得到总未读数

### v1.0 (2025-11-11)

**初始版本**：
- 实现 WebSocket 实时通讯
- 实现会话管理（单聊/群聊）
- 实现消息收发（文本/图片/文件/语音/视频）
- 实现已读回执功能
- 实现设备注册接口（为推送做准备）
- 集成 Redis 用于消息序号生成

---

**文档版本**: v1.1  
**最后更新**: 2025-11-11  
**维护者**: 开发团队

