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
- [5. 小白Agent问答（非流式）](#5-小白agent问答非流式)
- [6. 小白Agent问答（流式）](#6-小白agent问答流式)
- [7. 查询患者关联项目](#7-查询患者关联项目)
- [8. 小白Agent历史会话列表](#8-小白agent历史会话列表)
- [9. 小白Agent会话详情](#9-小白agent会话详情)
- [数据模型](#数据模型)
- [使用场景](#使用场景)
- [错误码说明](#错误码说明)
- [注意事项](#注意事项)

---

## 接口概览

| 接口 | 方法 | 路径 | 说明 |
|------|------|------|------|
| AI查询（非流式） | POST | `/api/v1/ai/query` | 临床试验筛选匹配，一次性返回完整AI响应 |
| AI查询（流式） | POST | `/api/v1/ai/query-stream` | 临床试验筛选匹配，使用SSE实时推送AI响应 |
| 查询对话历史 | GET | `/api/v1/ai/history` | 分页查询用户的AI对话历史 |
| 查询会话记录 | GET | `/api/v1/ai/session/{sessionId}` | 查询指定会话的所有对话 |
| 小白Agent问答（非流式） | POST | `/api/v1/ai/xiaobai/ask` | 项目方案知识库问答，一次性返回结果 |
| 小白Agent问答（流式） | POST | `/api/v1/ai/xiaobai/ask-stream` | 项目方案知识库问答，使用SSE实时推送 |
| 查询患者关联项目 | POST | `/api/v1/ai/patient-projects` | 根据患者标识查询关联的项目列表 |
| 小白Agent历史会话列表 | GET | `/api/v1/ai/xiaobai/sessions` | 分页查询小白Agent的历史会话列表 |
| 小白Agent会话详情 | GET | `/api/v1/ai/xiaobai/sessions/{sessionId}` | 查询指定会话的完整对话记录 |

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

**接口描述**: 分页查询当前用户的AI对话历史记录，按创建时间倒序排列。支持按 Agent 类型过滤。

- **URL**: `/api/v1/ai/history`
- **方法**: `GET`
- **认证**: 需要认证（Bearer Token）

### 请求参数

**Query Parameters**:

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| page | Integer | 否 | 1 | 页码，从1开始 |
| size | Integer | 否 | 20 | 每页大小，最大100 |
| agent | String | 否 | - | Agent类型，如 `xiaobai`，不传则查询所有类型的对话历史 |

### 请求头

```
Authorization: Bearer {accessToken}
```

### 请求示例

**查询所有对话历史**:
```bash
curl -X GET "http://localhost:8090/api/v1/ai/history?page=1&size=20" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9..."
```

**仅查询小白Agent的对话历史**:
```bash
curl -X GET "http://localhost:8090/api/v1/ai/history?page=1&size=20&agent=xiaobai" \
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

**查询所有对话历史**:
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

**按Agent类型查询对话历史**:
```dart
Future<PageResponse<AiChatLog>> getChatHistoryByAgent({
  int page = 1, 
  int size = 20, 
  String? agent
}) async {
  var queryParams = {'page': page.toString(), 'size': size.toString()};
  if (agent != null && agent.isNotEmpty) {
    queryParams['agent'] = agent;
  }
  
  final uri = Uri.parse('http://localhost:8090/api/v1/ai/history')
      .replace(queryParameters: queryParams);
      
  final response = await http.get(
    uri,
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

// 使用示例
// 查询所有对话
final allHistory = await getChatHistoryByAgent(page: 1, size: 20);

// 只查询小白Agent的对话
final xiaobaiHistory = await getChatHistoryByAgent(page: 1, size: 20, agent: 'xiaobai');
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

## 5. 小白Agent问答（非流式）

**接口描述**: 基于项目方案文件进行智能知识库问答。小白Agent专注于临床试验方案相关问题，支持入排标准判断、药物禁用/慎用判断、不良事件处理等场景。

- **URL**: `/api/v1/ai/xiaobai/ask`
- **方法**: `POST`
- **认证**: 需要认证（Bearer Token）
- **超时时间**: 120秒

### 请求参数

**Body (application/json)**:

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| question | String | 是 | 用户问题 |
| projectId | Long | 是 | 项目ID，用于定位项目方案文件 |
| patientName | String | 否 | 患者标识（姓名或住院号），用于关联患者 |
| sessionId | String | 否 | 会话ID，用于多轮对话场景 |

### 请求头

```
Authorization: Bearer {accessToken}
Content-Type: application/json
```

### 请求示例

```bash
curl -X POST http://localhost:8090/api/v1/ai/xiaobai/ask \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9..." \
  -H "Content-Type: application/json" \
  -d '{
    "question": "这个患者是否符合入组标准？",
    "projectId": 28,
    "patientName": "张三",
    "sessionId": "session-xiaobai-001"
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
    "success": true,
    "data": {
      "answer": "✅ 可入组\n\n根据方案，入组标准包括：\n1. 经组织学确诊为食管癌\n2. 年龄≥18岁\n3. ECOG评分0-1\n4. 未接受过系统性治疗\n\n该患者符合上述所有入组标准，可以入组。",
      "question": "这个患者是否符合入组标准？",
      "project_code": "28"
    }
  }
}
```

**判断为不可入组的响应**:

```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": {
    "success": true,
    "data": {
      "answer": "❌ 不可入组\n\n根据方案排除标准第3条：\n\"有严重心脏病史或心功能不全者\"\n\n该患者有心梗病史，不符合入组条件。",
      "question": "这个患者是否符合入组标准？",
      "project_code": "28"
    }
  }
}
```

**错误响应 (500)**:

```json
{
  "success": false,
  "code": "AI_SERVICE_ERROR",
  "message": "小白Agent服务调用失败: Connection timeout",
  "data": null
}
```

### 支持的问题类型

| 类型 | 说明 | 示例 |
|------|------|------|
| 入排标准判断 | 评估患者是否符合入组/排除标准 | "这个患者是否符合入组标准？" |
| 入组标准查询 | 查询项目的具体入组标准 | "入组标准是什么？" |
| 排除标准查询 | 查询项目的排除标准 | "有哪些排除标准？" |
| 药物禁用判断 | 评估合并用药的安全性 | "患者正在服用阿司匹林，是否可以入组？" |
| 不良事件处理 | AE管理、剂量调整建议 | "如果出现3级皮疹应该怎么处理？" |
| 方案细节查询 | 查询试验方案的具体内容 | "访视周期是怎样安排的？" |

### Flutter 调用示例

```dart
Future<Map<String, dynamic>> askXiaobai({
  required String question,
  required int projectId,
  String? patientName,
  String? sessionId,
}) async {
  final response = await http.post(
    Uri.parse('http://localhost:8090/api/v1/ai/xiaobai/ask'),
    headers: {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'question': question,
      'projectId': projectId,
      'patientName': patientName,
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
    throw Exception('小白Agent调用失败: ${response.statusCode}');
  }
}
```

---

## 6. 小白Agent问答（流式）

**接口描述**: 使用Server-Sent Events (SSE)实时流式返回小白Agent的回答。适用于需要实时展示AI生成过程的场景。

- **URL**: `/api/v1/ai/xiaobai/ask-stream`
- **方法**: `POST`
- **认证**: 需要认证（Bearer Token）
- **响应格式**: `text/event-stream`
- **超时时间**: 120秒

### 请求参数

**Body (application/json)**:

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| question | String | 是 | 用户问题 |
| projectId | Long | 是 | 项目ID |
| patientName | String | 否 | 患者标识 |
| sessionId | String | 否 | 会话ID |

### 请求头

```
Authorization: Bearer {accessToken}
Content-Type: application/json
Accept: text/event-stream
```

### 请求示例

```bash
curl -N -X POST http://localhost:8090/api/v1/ai/xiaobai/ask-stream \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9..." \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -d '{
    "question": "入组标准是什么？",
    "projectId": 28,
    "patientName": "李四",
    "sessionId": "session-xiaobai-002"
  }'
```

### 响应示例

**成功响应 (200) - SSE格式**:

```
event: start
data: {"question": "入组标准是什么？", "project_code": "28"}

event: message
data: {"text": "✅ 根据项目方案，入组标准如下："}

event: message
data: {"text": "\n\n1. 经组织学或细胞学确诊的食管癌患者"}

event: message
data: {"text": "\n2. 年龄≥18岁且≤75岁"}

event: message
data: {"text": "\n3. ECOG体能状态评分0-1分"}

event: message
data: {"text": "\n4. 既往未接受过系统性抗肿瘤治疗"}

event: result
data: {"answer": "完整答案...", "question": "入组标准是什么？", "project_code": "28"}

event: done
data: {}
```

### Flutter 调用示例

```dart
Future<void> askXiaobaiStream({
  required String question,
  required int projectId,
  String? patientName,
  String? sessionId,
  required Function(String) onMessage,
  required Function() onDone,
  Function(String)? onError,
}) async {
  final client = http.Client();
  final request = http.Request(
    'POST',
    Uri.parse('http://localhost:8090/api/v1/ai/xiaobai/ask-stream'),
  );
  
  request.headers.addAll({
    'Authorization': 'Bearer $accessToken',
    'Content-Type': 'application/json',
    'Accept': 'text/event-stream',
  });
  
  request.body = jsonEncode({
    'question': question,
    'projectId': projectId,
    'patientName': patientName,
    'sessionId': sessionId,
  });

  final response = await client.send(request);
  
  response.stream
    .transform(utf8.decoder)
    .transform(const LineSplitter())
    .listen(
      (line) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          if (data.isNotEmpty && data != '{}') {
            try {
              final jsonData = jsonDecode(data);
              if (jsonData['text'] != null) {
                onMessage(jsonData['text']);
              }
            } catch (e) {
              // 忽略解析错误
            }
          }
        } else if (line.startsWith('event: done')) {
          onDone();
          client.close();
        } else if (line.startsWith('event: error')) {
          // 下一行是错误数据
        }
      },
      onError: (error) {
        onError?.call(error.toString());
        client.close();
      },
    );
}

// 使用示例
void example() {
  final StringBuffer answer = StringBuffer();
  
  askXiaobaiStream(
    question: '入组标准是什么？',
    projectId: 28,
    patientName: '张三',
    onMessage: (text) {
      answer.write(text);
      // 实时更新UI显示
      setState(() {
        displayText = answer.toString();
      });
    },
    onDone: () {
      print('回答完成：${answer.toString()}');
    },
    onError: (error) {
      print('发生错误：$error');
    },
  );
}
```

---

## 7. 查询患者关联项目

**接口描述**: 根据患者住院号或姓名查询该患者关联的所有项目信息。这是AI问答流程中的辅助接口，用于快速定位患者参与的项目，便于后续进行项目方案问答。

- **URL**: `/api/v1/ai/patient-projects`
- **方法**: `POST`
- **认证**: 需要认证（Bearer Token）

### 请求参数

**Body (application/json)**:

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| patientIdentifier | String | 是 | 患者标识（住院号或姓名） |

### 请求头

```
Authorization: Bearer {accessToken}
Content-Type: application/json
```

### 请求示例

```bash
curl -X POST http://localhost:8090/api/v1/ai/patient-projects \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9..." \
  -H "Content-Type: application/json" \
  -d '{
    "patientIdentifier": "202412250001"
  }'
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
      "projectId": 28,
      "projectName": "食管癌免疫治疗临床研究",
      "shortTitle": "食管癌免疫研究",
      "patientInNo": "202412250001",
      "patientNameAbbr": "张某",
      "statusCode": "ENROLLED",
      "statusText": "已入组"
    },
    {
      "projectId": 45,
      "projectName": "非小细胞肺癌靶向治疗研究",
      "shortTitle": "肺癌靶向研究",
      "patientInNo": "202412250001",
      "patientNameAbbr": "张某",
      "statusCode": "ICF_SIGNED",
      "statusText": "已签署知情同意书"
    }
  ]
}
```

**患者无关联项目的响应 (200)**:

```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": []
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

### 筛查状态说明

| 状态码 | 状态名称 | 说明 |
|--------|---------|------|
| PENDING | 待审核 | 医生已提交筛查，等待CRC审核 |
| CRC_REVIEW | CRC审核中 | CRC正在审核患者筛查信息 |
| MATCH_FAILED | 筛查失败 | 患者不符合入排标准 |
| ICF_SIGNED | 已签署知情同意书 | 患者已签署ICF |
| ICF_FAILED | 知情失败 | 患者拒绝签署ICF |
| ENROLLED | 已入组 | 患者已正式入组 |
| EXITED | 已退出 | 患者已退出研究 |

### Flutter 调用示例

```dart
Future<List<PatientProject>> getPatientProjects(String patientIdentifier) async {
  final response = await http.post(
    Uri.parse('http://localhost:8090/api/v1/ai/patient-projects'),
    headers: {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'patientIdentifier': patientIdentifier,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['success']) {
      final List<dynamic> list = data['data'];
      return list.map((item) => PatientProject.fromJson(item)).toList();
    } else {
      throw Exception(data['message']);
    }
  } else {
    throw Exception('查询失败: ${response.statusCode}');
  }
}

// 使用示例：在小白Agent问答前先查询患者项目
void askAboutPatient(String patientId) async {
  // 1. 先查询患者关联的项目
  final projects = await getPatientProjects(patientId);
  
  if (projects.isEmpty) {
    print('该患者没有参与任何项目');
    return;
  }
  
  // 2. 让用户选择项目或自动选择第一个
  final selectedProject = projects.first;
  
  // 3. 使用项目ID进行小白Agent问答
  final answer = await askXiaobai(
    question: '这个患者是否符合入组标准？',
    projectId: selectedProject.projectId,
    patientName: patientId,
  );
  
  print('AI回答：${answer['data']['answer']}');
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

AI查询请求参数（临床试验筛选）

| 字段名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| inputAsText | String | 是 | 用户输入文本，格式：orgId:X,disciplineId:Y,问题 |
| sessionId | String | 否 | 会话ID，用于多轮对话 |

### XiaobaiQueryRequest

小白Agent查询请求参数（项目方案知识库问答）

| 字段名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| question | String | 是 | 用户问题 |
| projectId | Long | 是 | 项目ID，用于定位项目方案文件 |
| patientName | String | 否 | 患者标识（姓名或住院号） |
| sessionId | String | 否 | 会话ID，用于多轮对话 |

### PatientProjectQueryRequest

患者项目查询请求参数

| 字段名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| patientIdentifier | String | 是 | 患者标识（住院号或姓名） |

### PatientProjectVO

患者关联项目信息

| 字段名 | 类型 | 说明 |
|--------|------|------|
| projectId | Long | 项目ID |
| projectName | String | 项目名称 |
| shortTitle | String | 项目简称 |
| patientInNo | String | 患者住院号 |
| patientNameAbbr | String | 患者姓名简称 |
| statusCode | String | 筛查状态代码 |
| statusText | String | 筛查状态文本 |

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

### 场景5：小白Agent入排标准判断

医生需要判断某个患者是否符合项目入排标准：

```
1. 选择项目（获取projectId）
2. 输入患者标识（patientName，可选）
3. 提问："这个患者是否符合入组标准？"
4. 调用 POST /api/v1/ai/xiaobai/ask
5. 获取判断结果（✅ 可入组 或 ❌ 不可入组）
6. 展示给医生
```

### 场景6：小白Agent方案查询

用户需要查询项目方案的具体内容：

```
1. 选择项目（获取projectId）
2. 提问："入组标准是什么？" / "访视安排是怎样的？"
3. 调用 POST /api/v1/ai/xiaobai/ask
4. 获取方案内容
5. 展示给用户
```

### 场景7：小白Agent多轮对话

用户就同一项目进行连续提问：

```
1. 第一轮：生成sessionId
   提问："入组标准是什么？"
   调用 POST /api/v1/ai/xiaobai/ask (projectId: 28, sessionId: session-001)

2. 第二轮：使用相同sessionId
   提问："如果患者年龄超过75岁怎么办？"
   调用 POST /api/v1/ai/xiaobai/ask (projectId: 28, sessionId: session-001)

3. 第三轮：使用相同sessionId
   提问："有没有年龄豁免的情况？"
   调用 POST /api/v1/ai/xiaobai/ask (projectId: 28, sessionId: session-001)

4. 查看完整对话：
   调用 GET /api/v1/ai/session/session-001
```

### 场景8：通过患者标识快速开始AI问答

用户输入患者住院号或姓名，快速定位患者项目并开始问答：

```
1. 用户输入患者标识："202412250001"
2. 调用 POST /api/v1/ai/patient-projects 查询患者关联的项目
3. 返回项目列表（可能包含多个项目）
4. 用户选择目标项目（或系统自动选择第一个）
5. 使用projectId调用小白Agent进行问答
   调用 POST /api/v1/ai/xiaobai/ask (projectId: 28, patientName: "202412250001")
6. 获取AI回答并展示
```

### 场景9：浏览小白Agent历史会话

用户查看与小白Agent的历史对话记录：

```
1. 进入小白Agent页面，查看历史会话列表
   调用 GET /api/v1/ai/xiaobai/sessions?page=1&size=20

2. 返回会话列表（按最近聊天时间倒序）：
   - session-001: "患者李某某可以使用阿司匹林吗？" (5条消息，最后聊天：2小时前)
   - session-002: "布洛芬的禁忌症有哪些？" (3条消息，最后聊天：昨天)
   - session-003: "如何处理3级不良事件？" (7条消息，最后聊天：2天前)

3. 用户点击某个会话，查看完整对话
   调用 GET /api/v1/ai/xiaobai/sessions/session-001

4. 返回完整对话记录（按时间正序排列）：
   - Q1: "患者李某某可以使用阿司匹林吗？"
   - A1: "根据项目方案第5.3节..."
   - Q2: "那布洛芬呢？"
   - A2: "布洛芬属于NSAIDs类药物..."
   - ...

5. 用户可以在会话详情页继续提问（使用相同的sessionId）
```

---

## 8. 小白Agent历史会话列表

**接口描述**: 分页查询当前用户的小白Agent历史会话列表，按session_id聚合，展示每个会话的摘要信息。会话按最后消息时间倒序排列。

- **URL**: `/api/v1/ai/xiaobai/sessions`
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
curl -X GET "http://localhost:8090/api/v1/ai/xiaobai/sessions?page=1&size=20" \
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
        "sessionId": "session-20251228-001",
        "title": "患者李某某可以使用阿司匹林吗？",
        "messageCount": 5,
        "lastMessageAt": "2025-12-28T15:30:00",
        "createdAt": "2025-12-28T14:00:00"
      },
      {
        "sessionId": "session-20251227-002",
        "title": "布洛芬的禁忌症有哪些？",
        "messageCount": 3,
        "lastMessageAt": "2025-12-27T10:20:00",
        "createdAt": "2025-12-27T10:00:00"
      },
      {
        "sessionId": "session-20251226-003",
        "title": "如何处理3级不良事件？",
        "messageCount": 7,
        "lastMessageAt": "2025-12-26T16:45:00",
        "createdAt": "2025-12-26T15:00:00"
      }
    ],
    "page": 1,
    "size": 20,
    "total": 15,
    "pages": 1,
    "hasNext": false,
    "hasPrev": false
  }
}
```

### 字段说明

| 字段名 | 类型 | 说明 |
|--------|------|------|
| sessionId | String | 会话ID，用于查询会话详情 |
| title | String | 会话标题（第一条消息的问题） |
| messageCount | Integer | 该会话的消息总数 |
| lastMessageAt | DateTime | 最后一条消息的时间 |
| createdAt | DateTime | 会话创建时间（第一条消息时间） |

### Flutter 调用示例

```dart
Future<PageResponse<XiaobaiSessionVO>> getXiaobaiSessions({int page = 1, int size = 20}) async {
  final response = await http.get(
    Uri.parse('http://localhost:8090/api/v1/ai/xiaobai/sessions?page=$page&size=$size'),
    headers: {
      'Authorization': 'Bearer $accessToken',
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['success']) {
      return PageResponse<XiaobaiSessionVO>.fromJson(data['data']);
    } else {
      throw Exception(data['message']);
    }
  } else {
    throw Exception('查询历史会话失败: ${response.statusCode}');
  }
}
```

---

## 9. 小白Agent会话详情

**接口描述**: 获取指定会话的完整对话记录，包括会话标题和所有对话消息。对话记录按创建时间正序排列，符合时间线展示习惯。

- **URL**: `/api/v1/ai/xiaobai/sessions/{sessionId}`
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
curl -X GET "http://localhost:8090/api/v1/ai/xiaobai/sessions/session-20251228-001" \
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
    "sessionId": "session-20251228-001",
    "title": "患者可以使用阿司匹林吗？",
    "projectId": 38,
    "projectName": "食管癌免疫治疗临床研究",
    "messages": [
      {
        "id": 101,
        "sessionId": "session-20251228-001",
        "userQuestion": "患者可以使用阿司匹林吗？",
        "aiResponse": "根据项目方案第5.3节禁用药物列表，阿司匹林属于NSAIDs类药物，在本试验中为禁用药物...",
        "responseTimeMs": 2500,
        "status": "SUCCESS",
        "errorMessage": null,
        "createdAt": "2025-12-28T14:00:00"
      },
      {
        "id": 102,
        "sessionId": "session-20251228-001",
        "userQuestion": "那布洛芬呢？",
        "aiResponse": "布洛芬同样属于NSAIDs类药物，根据方案要求也在禁用药物范围内...",
        "responseTimeMs": 1800,
        "status": "SUCCESS",
        "errorMessage": null,
        "createdAt": "2025-12-28T14:05:00"
      },
      {
        "id": 103,
        "sessionId": "session-20251228-001",
        "userQuestion": "如果患者已经在服用阿司匹林怎么办？",
        "aiResponse": "根据方案第8.2节处理流程，如果患者正在使用禁用药物，需要在入组前停药至少7天...",
        "responseTimeMs": 2200,
        "status": "SUCCESS",
        "errorMessage": null,
        "createdAt": "2025-12-28T14:10:00"
      },
      {
        "id": 104,
        "sessionId": "session-20251228-001",
        "userQuestion": "停药期间有什么注意事项？",
        "aiResponse": "停药期间需要注意：1) 密切监测患者症状；2) 必要时可使用替代药物；3) 记录停药时间...",
        "responseTimeMs": 1900,
        "status": "SUCCESS",
        "errorMessage": null,
        "createdAt": "2025-12-28T14:15:00"
      },
      {
        "id": 105,
        "sessionId": "session-20251228-001",
        "userQuestion": "有哪些替代药物可以使用？",
        "aiResponse": "根据方案第5.4节允许合并用药，替代药物包括：1) 对乙酰氨基酚（扑热息痛）；2) 曲马多...",
        "responseTimeMs": 2100,
        "status": "SUCCESS",
        "errorMessage": null,
        "createdAt": "2025-12-28T14:20:00"
      }
    ]
  }
}
```

**错误响应 - 会话不存在 (404)**:

```json
{
  "success": false,
  "code": "NOT_FOUND",
  "message": "会话不存在",
  "data": null
}
```

**错误响应 - 无权访问 (403)**:

```json
{
  "success": false,
  "code": "FORBIDDEN",
  "message": "无权访问该会话",
  "data": null
}
```

### 字段说明

| 字段名 | 类型 | 说明 |
|--------|------|------|
| sessionId | String | 会话ID |
| title | String | 会话标题（第一条消息的问题，已格式化去除项目前缀） |
| projectId | Long | 项目ID |
| projectName | String | 项目名称 |
| messages | Array | 对话记录列表，按创建时间正序排列 |
| messages[].id | Long | 消息ID |
| messages[].sessionId | String | 会话ID |
| messages[].userQuestion | String | 用户提问（已格式化去除项目前缀） |
| messages[].aiResponse | String | AI回答（已提取answer字段内容） |
| messages[].responseTimeMs | Integer | 响应耗时（毫秒） |
| messages[].status | String | 状态：SUCCESS/ERROR/PENDING |
| messages[].errorMessage | String | 错误信息（如有） |
| messages[].createdAt | DateTime | 创建时间 |

### Flutter 调用示例

```dart
Future<XiaobaiSessionDetailVO> getXiaobaiSessionDetail(String sessionId) async {
  final response = await http.get(
    Uri.parse('http://localhost:8090/api/v1/ai/xiaobai/sessions/$sessionId'),
    headers: {
      'Authorization': 'Bearer $accessToken',
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['success']) {
      return XiaobaiSessionDetailVO.fromJson(data['data']);
    } else {
      throw Exception(data['message']);
    }
  } else if (response.statusCode == 404) {
    throw Exception('会话不存在');
  } else if (response.statusCode == 403) {
    throw Exception('无权访问该会话');
  } else {
    throw Exception('查询会话详情失败: ${response.statusCode}');
  }
}
```

### 使用场景

1. **查看历史对话**：用户点击会话列表中的某个会话，查看完整对话内容
2. **继续会话**：在会话详情页面，用户可以继续提问（使用相同的sessionId）
3. **审计追溯**：查看历史对话记录，用于医疗质量审计
4. **知识回顾**：复习之前咨询过的问题和答案

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

### 9. 小白Agent使用建议

- **项目ID必填**：小白Agent需要projectId来定位项目方案文件
- **患者标识可选**：patientName可以是姓名或住院号，用于关联患者信息
- **响应时间较长**：知识库问答可能需要10-30秒，建议使用流式接口
- **超时时间**：小白Agent接口设置了120秒超时，比普通AI接口更长
- **数据记录**：所有问答都会记录到数据库，包含agent="xiaobai"标识

### 10. 两种Agent的区别

| 特性 | AI查询（/query） | 小白Agent（/xiaobai/ask） |
|------|------------------|---------------------------|
| 用途 | 临床试验筛选匹配 | 项目方案知识库问答 |
| 输入格式 | orgId:X,disciplineId:Y,问题 | 直接输入问题 |
| 必填参数 | inputAsText | question, projectId |
| 可选参数 | sessionId | patientName, sessionId |
| 超时时间 | 60秒 | 120秒 |
| Python接口 | /run, /run_stream | /ask, /ask_stream |
| 数据库agent标识 | null | xiaobai |

### 11. 患者项目查询接口使用建议

- **快速定位**：在小白Agent问答前，先调用此接口获取患者关联的项目列表
- **项目选择**：如果患者参与多个项目，需让用户选择目标项目
- **数据缓存**：可以缓存患者项目列表，避免重复查询
- **错误处理**：如果查询结果为空，提示用户该患者尚未参与任何项目
- **隐私保护**：接口返回的患者姓名已脱敏（patientNameAbbr）

---

## 相关文档

- [AI代理实现文档](./AI_PROXY_IMPLEMENTATION.md)
- [YABY Agent Server API文档](./API_DOCS.md) - Python AI服务接口文档
- [用户认证API](./USER_PROFILE_API.md)
- [项目搜索API](./PROJECT_SEARCH_API.md)

---

## 更新日志

| 日期 | 版本 | 说明 |
|------|------|------|
| 2024-12-25 | 1.2.0 | 新增患者关联项目查询接口，支持AI问答流程中快速定位患者项目 |
| 2024-12-25 | 1.1.0 | 新增小白Agent（Xiaobai）知识库问答接口，支持项目方案智能问答 |
| 2024-12-24 | 1.0.0 | 初始版本，包含4个API接口 |

