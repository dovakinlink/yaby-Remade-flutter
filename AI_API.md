# AI助手 API 文档

## 功能概述

AI助手API提供智能查询服务，通过Spring Boot代理层调用Python AI服务，支持临床试验项目智能匹配、自然语言查询等功能。所有AI交互都会被记录到数据库中，便于审计和追踪。

## 技术特点

- ✅ **JWT认证**：所有接口都需要JWT认证，确保数据安全
- ✅ **对话历史记录**：自动记录用户提问和AI回答，支持历史查询
- ✅ **双模式支持**：支持非流式和流式（SSE）两种调用方式
- ✅ **响应时间统计**：记录每次AI调用的响应时间
- ✅ **错误追踪**：记录失败请求的错误信息
- ✅ **多租户隔离**：按组织ID隔离数据，确保数据安全
- ✅ **会话管理**：支持多轮对话场景

## 目录

- [接口概览](#接口概览)
- [1. AI查询（非流式）](#1-ai查询非流式)
- [2. AI查询（流式）](#2-ai查询流式)
- [3. 查询对话历史](#3-查询对话历史)
- [4. 查询会话记录](#4-查询会话记录)
- [数据模型](#数据模型)
- [使用场景](#使用场景)
- [错误码说明](#错误码说明)
- [注意事项](#注意事项)

---

## 接口概览

| 接口 | 方法 | 路径 | 说明 |
|------|------|------|------|
| AI查询（非流式） | POST | `/api/v1/ai/query` | 一次性返回完整AI响应 |
| AI查询（流式） | POST | `/api/v1/ai/query-stream` | 使用SSE实时推送AI响应 |
| 查询对话历史 | GET | `/api/v1/ai/history` | 分页查询用户的AI对话历史 |
| 查询会话记录 | GET | `/api/v1/ai/session/{sessionId}` | 查询指定会话的所有对话 |

---

## 1. AI查询（非流式）

**接口描述**: 提交问题给AI助手，一次性返回完整的AI响应结果。适用于大多数查询场景。

- **URL**: `/api/v1/ai/query`
- **方法**: `POST`
- **认证**: 需要认证（Bearer Token）
- **超时时间**: 60秒

### 请求参数

**Body (application/json)**:

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| inputAsText | String | 是 | 用户输入文本，格式：orgId:1,disciplineId:2,用户问题 |
| sessionId | String | 否 | 会话ID，用于多轮对话场景 |

### 请求头

```
Authorization: Bearer {accessToken}
Content-Type: application/json
```

### 请求示例

```bash
curl -X POST http://localhost:8090/api/v1/ai/query \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9..." \
  -H "Content-Type: application/json" \
  -d '{
    "inputAsText": "orgId:1,disciplineId:2,食管癌一线有没有合适的项目？",
    "sessionId": "session-20241224-001"
  }'
```

### 响应示例

**成功响应 (200)**:

```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": {
    "answer": "根据您的查询条件，找到以下食管癌一线治疗的临床试验项目：\n\n1. 项目名称：食管癌免疫治疗研究\n   - 项目ID: 45\n   - 治疗线数: 一线\n   - 入组标准: 18-75岁，病理确诊的食管鳞癌患者\n   - 申办方: XX生物制药\n\n2. 项目名称：食管癌联合化疗方案研究\n   - 项目ID: 67\n   - 治疗线数: 一线\n   - 入组标准: 18-70岁，未接受过系统治疗的食管癌患者\n   - 申办方: YY医药科技",
    "projects": [
      {
        "projectId": "45",
        "title": "食管癌免疫治疗研究",
        "lineOfTherapy": 1,
        "tumorTypeCode": "食管癌",
        "inclusionCriteria": "18-75岁，病理确诊的食管鳞癌患者",
        "exclusionCriteria": "有严重心脏病史、肝肾功能不全"
      },
      {
        "projectId": "67",
        "title": "食管癌联合化疗方案研究",
        "lineOfTherapy": 1,
        "tumorTypeCode": "食管癌",
        "inclusionCriteria": "18-70岁，未接受过系统治疗的食管癌患者",
        "exclusionCriteria": "妊娠或哺乳期妇女、活动性感染"
      }
    ],
    "metadata": {
      "queryTime": "2024-12-24T10:30:00",
      "processingTimeMs": 2500,
      "resultCount": 2
    }
  }
}
```

**错误响应 (401)**:

```json
{
  "success": false,
  "code": "UNAUTHORIZED",
  "message": "用户未登录",
  "data": null
}
```

**错误响应 (500)**:

```json
{
  "success": false,
  "code": "AI_SERVICE_ERROR",
  "message": "AI服务调用失败: Connection timeout",
  "data": null
}
```

### Flutter 调用示例

```dart
Future<Map<String, dynamic>> queryAi(String question, {String? sessionId}) async {
  final response = await http.post(
    Uri.parse('http://localhost:8090/api/v1/ai/query'),
    headers: {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'inputAsText': 'orgId:$orgId,disciplineId:$disciplineId,$question',
      'sessionId': sessionId,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['success']) {
      return data['data'];
    } else {
      throw Exception(data['message']);
    }
  } else {
    throw Exception('AI查询失败: ${response.statusCode}');
  }
}
```

---

## 2. AI查询（流式）

**接口描述**: 使用Server-Sent Events (SSE)实时流式返回AI响应。适用于需要实时展示AI生成过程的场景。

- **URL**: `/api/v1/ai/query-stream`
- **方法**: `POST`
- **认证**: 需要认证（Bearer Token）
- **响应格式**: `text/event-stream`
- **超时时间**: 60秒

### 请求参数

**Body (application/json)**:

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| inputAsText | String | 是 | 用户输入文本 |
| sessionId | String | 否 | 会话ID |

### 请求头

```
Authorization: Bearer {accessToken}
Content-Type: application/json
Accept: text/event-stream
```

### 请求示例

```bash
curl -N -X POST http://localhost:8090/api/v1/ai/query-stream \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9..." \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -d '{
    "inputAsText": "orgId:1,disciplineId:2,肺癌二线有哪些项目？",
    "sessionId": "session-20241224-002"
  }'
```

### 响应示例

**成功响应 (200) - SSE格式**:

```
event: message
data: {"text": "正在搜索肺癌二线治疗项目..."}

event: message
data: {"text": "找到3个符合条件的项目"}

event: message
data: {"text": "1. 非小细胞肺癌靶向治疗研究"}

event: message
data: {"text": "2. 肺癌免疫联合治疗方案"}

event: message
data: {"text": "3. 肺癌二线化疗优化研究"}

event: done
data: {}
```

### Flutter 调用示例

```dart
Future<void> queryAiStream(String question, {String? sessionId}) async {
  final client = http.Client();
  final request = http.Request(
    'POST',
    Uri.parse('http://localhost:8090/api/v1/ai/query-stream'),
  );
  
  request.headers.addAll({
    'Authorization': 'Bearer $accessToken',
    'Content-Type': 'application/json',
    'Accept': 'text/event-stream',
  });
  
  request.body = jsonEncode({
    'inputAsText': 'orgId:$orgId,disciplineId:$disciplineId,$question',
    'sessionId': sessionId,
  });

  final response = await client.send(request);
  
  response.stream
    .transform(utf8.decoder)
    .transform(const LineSplitter())
    .listen((line) {
      if (line.startsWith('data: ')) {
        final data = line.substring(6);
        if (data.isNotEmpty && data != '{}') {
          final jsonData = jsonDecode(data);
          // 处理流式数据
          print('Received: ${jsonData['text']}');
        }
      } else if (line.startsWith('event: done')) {
        print('Stream completed');
        client.close();
      }
    });
}
```

---

## 3. 查询对话历史

**接口描述**: 分页查询当前用户的AI对话历史记录，按创建时间倒序排列。

- **URL**: `/api/v1/ai/history`
- **方法**: `GET`
- **认证**: 需要认证（Bearer Token）

### 请求参数

**Query Parameters**:

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| page | Integer | 否 | 1 | 页码，从1开始 |
| size | Integer | 否 | 20 | 每页大小，最大100 |

### 请求头

```
Authorization: Bearer {accessToken}
```

### 请求示例

```bash
curl -X GET "http://localhost:8090/api/v1/ai/history?page=1&size=20" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9..."
```

### 响应示例

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
        "sessionId": "session-20241224-001",
        "userQuestion": "orgId:1,disciplineId:2,食管癌一线有没有合适的项目？",
        "aiResponse": "{\"answer\":\"根据您的查询条件，找到以下食管癌一线治疗的临床试验项目...\",\"projects\":[...]}",
        "responseTimeMs": 2500,
        "status": "SUCCESS",
        "errorMessage": null,
        "createdAt": "2024-12-24T10:30:00"
      },
      {
        "id": 2,
        "sessionId": "session-20241224-002",
        "userQuestion": "orgId:1,disciplineId:2,肺癌二线有哪些项目？",
        "aiResponse": "{\"answer\":\"找到3个符合条件的项目...\",\"projects\":[...]}",
        "responseTimeMs": 1800,
        "status": "SUCCESS",
        "errorMessage": null,
        "createdAt": "2024-12-24T11:15:00"
      },
      {
        "id": 3,
        "sessionId": "session-20241224-003",
        "userQuestion": "orgId:1,disciplineId:2,结直肠癌有什么新药？",
        "aiResponse": null,
        "responseTimeMs": 5000,
        "status": "ERROR",
        "errorMessage": "AI service timeout",
        "createdAt": "2024-12-24T12:00:00"
      }
    ],
    "page": 1,
    "size": 20,
    "total": 50,
    "pages": 3,
    "hasNext": true,
    "hasPrev": false
  }
}
```

### Flutter 调用示例

```dart
Future<PageResponse<AiChatLog>> getChatHistory({int page = 1, int size = 20}) async {
  final response = await http.get(
    Uri.parse('http://localhost:8090/api/v1/ai/history?page=$page&size=$size'),
    headers: {
      'Authorization': 'Bearer $accessToken',
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['success']) {
      return PageResponse<AiChatLog>.fromJson(data['data']);
    } else {
      throw Exception(data['message']);
    }
  } else {
    throw Exception('查询历史失败: ${response.statusCode}');
  }
}
```

---

## 4. 查询会话记录

**接口描述**: 根据会话ID查询该会话的所有对话记录，按创建时间升序排列。适用于查看完整的多轮对话。

- **URL**: `/api/v1/ai/session/{sessionId}`
- **方法**: `GET`
- **认证**: 需要认证（Bearer Token）

### 请求参数

**Path Parameters**:

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| sessionId | String | 是 | 会话ID |

### 请求头

```
Authorization: Bearer {accessToken}
```

### 请求示例

```bash
curl -X GET "http://localhost:8090/api/v1/ai/session/session-20241224-001" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9..."
```

### 响应示例

**成功响应 (200)**:

```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": [
    {
      "id": 1,
      "sessionId": "session-20241224-001",
      "userQuestion": "orgId:1,disciplineId:2,食管癌一线有什么项目？",
      "aiResponse": "{\"answer\":\"找到2个食管癌一线项目...\",\"projects\":[...]}",
      "responseTimeMs": 2500,
      "status": "SUCCESS",
      "errorMessage": null,
      "createdAt": "2024-12-24T10:30:00"
    },
    {
      "id": 5,
      "sessionId": "session-20241224-001",
      "userQuestion": "orgId:1,disciplineId:2,这些项目的入排标准是什么？",
      "aiResponse": "{\"answer\":\"项目45的入排标准为：入组标准...\"}",
      "responseTimeMs": 1800,
      "status": "SUCCESS",
      "errorMessage": null,
      "createdAt": "2024-12-24T10:31:30"
    },
    {
      "id": 8,
      "sessionId": "session-20241224-001",
      "userQuestion": "orgId:1,disciplineId:2,有哪些项目正在招募？",
      "aiResponse": "{\"answer\":\"目前项目45正在招募中...\"}",
      "responseTimeMs": 1500,
      "status": "SUCCESS",
      "errorMessage": null,
      "createdAt": "2024-12-24T10:33:00"
    }
  ]
}
```

### Flutter 调用示例

```dart
Future<List<AiChatLog>> getSessionHistory(String sessionId) async {
  final response = await http.get(
    Uri.parse('http://localhost:8090/api/v1/ai/session/$sessionId'),
    headers: {
      'Authorization': 'Bearer $accessToken',
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['success']) {
      final List<dynamic> list = data['data'];
      return list.map((item) => AiChatLog.fromJson(item)).toList();
    } else {
      throw Exception(data['message']);
    }
  } else {
    throw Exception('查询会话失败: ${response.statusCode}');
  }
}
```

---

## 数据模型

### AiChatLogVO

对话历史记录视图对象

| 字段名 | 类型 | 说明 |
|--------|------|------|
| id | Long | 记录ID |
| sessionId | String | 会话ID（可选） |
| userQuestion | String | 用户提问 |
| aiResponse | String | AI返回结果（JSON字符串） |
| responseTimeMs | Integer | 响应耗时（毫秒） |
| status | String | 状态：SUCCESS-成功, ERROR-失败, PENDING-处理中 |
| errorMessage | String | 错误信息（仅status=ERROR时有值） |
| createdAt | DateTime | 创建时间 |

### AiQueryRequest

AI查询请求参数

| 字段名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| inputAsText | String | 是 | 用户输入文本 |
| sessionId | String | 否 | 会话ID，用于多轮对话 |

---

## 使用场景

### 场景1：单次AI查询

用户提出一个问题，获取AI回答：

```
1. 用户提问："食管癌一线有什么项目？"
2. 调用 POST /api/v1/ai/query
3. 获取AI返回的项目列表
4. 展示给用户
```

### 场景2：多轮对话

用户进行连续多次提问：

```
1. 第一轮：生成sessionId = "session-001"
   用户："食管癌一线有什么项目？"
   调用 POST /api/v1/ai/query (sessionId: session-001)

2. 第二轮：使用相同sessionId
   用户："这些项目的入排标准是什么？"
   调用 POST /api/v1/ai/query (sessionId: session-001)

3. 第三轮：使用相同sessionId
   用户："哪些项目正在招募？"
   调用 POST /api/v1/ai/query (sessionId: session-001)

4. 查看完整对话：
   调用 GET /api/v1/ai/session/session-001
```

### 场景3：实时展示AI生成过程

用户希望看到AI实时生成回答的过程：

```
1. 调用 POST /api/v1/ai/query-stream
2. 监听SSE事件流
3. 逐步展示AI生成的内容
4. 提供更好的用户体验
```

### 场景4：查看历史记录

用户查看之前的AI对话：

```
1. 调用 GET /api/v1/ai/history?page=1&size=20
2. 展示历史对话列表
3. 用户点击某条记录查看详情
```

---

## 错误码说明

| 错误码 | HTTP状态码 | 说明 |
|--------|-----------|------|
| SUCCESS | 200 | 请求成功 |
| UNAUTHORIZED | 401 | 用户未登录或Token无效 |
| FORBIDDEN | 403 | 无权限访问 |
| AI_SERVICE_ERROR | 500 | AI服务调用失败 |
| VALIDATION_ERROR | 400 | 请求参数验证失败 |
| TIMEOUT_ERROR | 504 | AI服务响应超时 |

---

## 注意事项

### 1. 输入文本格式

`inputAsText` 参数需要包含组织ID和学科ID前缀：

```
格式：orgId:{组织ID},disciplineId:{学科ID},{用户问题}
示例：orgId:1,disciplineId:2,食管癌一线有没有合适的项目？
```

### 2. 会话ID管理

- 会话ID由客户端生成和管理
- 建议格式：`session-{日期}-{序号}` 或使用UUID
- 同一会话的所有对话应使用相同的sessionId
- 新的对话主题应创建新的sessionId

### 3. 响应时间

- AI服务响应时间通常在2-10秒之间
- 复杂查询可能需要更长时间
- 接口设置了60秒超时时间
- 建议客户端显示加载状态

### 4. 流式接口注意事项

- 流式接口适用于长文本生成场景
- 客户端需要支持SSE（Server-Sent Events）
- 连接保持期间不能进行其他请求
- 建议在移动网络环境谨慎使用

### 5. 历史记录查询

- 历史记录按用户隔离，只能查看自己的记录
- 历史记录按组织隔离，切换组织后看不到其他组织的记录
- aiResponse字段是JSON字符串，需要解析后使用
- 查询历史不会重新调用AI服务，只返回存储的历史数据

### 6. 性能建议

- 避免频繁调用AI接口，建议增加防抖处理
- 优先使用非流式接口，流式接口仅在必要时使用
- 历史记录查询建议每页20-50条
- 建议实现本地缓存减少重复查询

### 7. 错误处理

- 网络错误：检查网络连接，重试请求
- 超时错误：增加超时时间或优化查询条件
- 认证错误：检查Token是否过期，重新登录
- AI服务错误：稍后重试或联系技术支持

### 8. 安全建议

- 始终使用HTTPS协议
- 不要在客户端硬编码Token
- Token过期后及时刷新
- 不要在日志中记录完整的AI响应内容

---

## 相关文档

- [AI代理实现文档](./AI_PROXY_IMPLEMENTATION.md)
- [用户认证API](./USER_PROFILE_API.md)
- [项目搜索API](./PROJECT_SEARCH_API.md)

---

## 更新日志

| 日期 | 版本 | 说明 |
|------|------|------|
| 2024-12-24 | 1.0.0 | 初始版本，包含4个API接口 |

