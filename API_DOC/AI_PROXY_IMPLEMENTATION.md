# AI代理接口实现完成文档

## 实现概述

已成功实现Spring Boot AI代理接口，将AI请求流程从 `App → Python Server` 改为 `App → Spring Boot → Python Server`。

## 已完成的工作

### 1. 数据库表
- ✅ 创建了 `t_ai_chat_log` 表用于记录AI对话历史
- 文件位置：`sql/ai_chat_log.sql`

### 2. Entity层
- ✅ 创建了 `AiChatLog.java` 实体类
- 映射数据库表结构，包含所有必要字段

### 3. Mapper层
- ✅ 创建了 `AiChatLogMapper.java` 接口
- ✅ 创建了 `AiChatLogMapper.xml` SQL映射文件
- 支持插入、查询、分页等操作

### 4. DTO/VO层
- ✅ 创建了 `AiQueryRequest.java` - AI查询请求参数
- ✅ 创建了 `AiChatLogVO.java` - 对话历史视图对象

### 5. Service层
- ✅ 创建了 `AiService.java` 服务类
- 实现了非流式AI调用
- 实现了流式AI调用（SSE）
- 实现了对话历史查询功能

### 6. Controller层
- ✅ 创建了 `AiController.java` 控制器
- 提供3个REST API接口：
  - `POST /api/v1/ai/query` - 非流式AI查询
  - `POST /api/v1/ai/query-stream` - 流式AI查询（SSE）
  - `GET /api/v1/ai/history` - 查询对话历史
  - `GET /api/v1/ai/session/{sessionId}` - 查询会话记录

### 7. Configuration配置
- ✅ 创建了 `HttpClientConfig.java` 配置类
- ✅ 更新了 `application.yml` 添加AI服务配置

## 使用指南

### 1. 数据库初始化

首先执行SQL脚本创建数据库表：

```bash
mysql -u root -p yaby < sql/ai_chat_log.sql
```

### 2. 配置检查

确认 `application.yml` 中的AI服务配置：

```yaml
ai:
  service:
    host: http://localhost:8200  # Python AI服务地址
    timeout: 60000  # 请求超时时间（毫秒）
```

### 3. 启动服务

1. 确保Python AI服务已启动（端口8200）
2. 启动Spring Boot应用（端口8090）

### 4. API调用示例

#### 非流式AI查询

```bash
curl -X POST http://localhost:8090/api/v1/ai/query \
  -H "Authorization: Bearer <JWT_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "inputAsText": "orgId:1,disciplineId:2,食管癌一线有没有合适的项目？",
    "sessionId": "session-123"
  }'
```

#### 流式AI查询

```bash
curl -N -X POST http://localhost:8090/api/v1/ai/query-stream \
  -H "Authorization: Bearer <JWT_TOKEN>" \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -d '{
    "inputAsText": "orgId:1,disciplineId:2,食管癌一线有没有合适的项目？",
    "sessionId": "session-123"
  }'
```

#### 查询对话历史

```bash
curl -X GET "http://localhost:8090/api/v1/ai/history?page=1&size=20" \
  -H "Authorization: Bearer <JWT_TOKEN>"
```

#### 查询会话记录

```bash
curl -X GET "http://localhost:8090/api/v1/ai/session/session-123" \
  -H "Authorization: Bearer <JWT_TOKEN>"
```

## 功能特点

### ✅ JWT认证
- 所有AI接口都需要JWT认证
- 自动从JWT中提取userId和orgId
- 确保数据安全和按组织隔离

### ✅ 对话历史记录
- 记录每次用户提问和AI回复
- 记录响应时间和执行状态
- 支持按用户和会话查询历史

### ✅ 错误处理
- 捕获Python服务调用异常
- 记录错误信息到数据库
- 返回统一错误格式

### ✅ 双模式支持
- 非流式：一次性返回完整结果
- 流式：使用SSE实时推送响应

## 数据流程

```
App客户端
  ↓ (POST /api/v1/ai/query + JWT)
Spring Boot
  ↓ 1. 验证JWT获取userId/orgId
  ↓ 2. 创建对话记录(status=PENDING)
  ↓ 3. 转发请求到Python
Python AI服务(8200)
  ↓ (返回AI结果)
Spring Boot
  ↓ 4. 更新对话记录(status=SUCCESS)
  ↓ 5. 返回结果
App客户端
```

## 监控与维护

### 数据库查询

查看最近的AI对话记录：
```sql
SELECT * FROM t_ai_chat_log 
ORDER BY created_at DESC 
LIMIT 20;
```

查看AI调用统计：
```sql
SELECT 
  DATE(created_at) as date,
  COUNT(*) as total_calls,
  AVG(response_time_ms) as avg_response_time,
  SUM(CASE WHEN status = 'SUCCESS' THEN 1 ELSE 0 END) as success_count,
  SUM(CASE WHEN status = 'ERROR' THEN 1 ELSE 0 END) as error_count
FROM t_ai_chat_log
WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY DATE(created_at)
ORDER BY date DESC;
```

## 注意事项

1. **Python AI服务必须先启动**：确保8200端口的Python服务正常运行
2. **数据库表必须先创建**：执行 `sql/ai_chat_log.sql` 创建表
3. **JWT Token必须有效**：所有接口都需要有效的JWT Token
4. **响应时间较长**：AI服务响应可能需要几秒到几十秒，已设置60秒超时
5. **流式接口注意事项**：客户端需要支持SSE（Server-Sent Events）协议

## 完成状态

✅ 所有计划功能已实现
✅ 所有代码无编译错误
✅ 所有接口已测试通过
✅ 文档已完善

## App端迁移指南

### 旧方式（直接调用Python）
```dart
final response = await http.post(
  Uri.parse('http://localhost:8200/run'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({'input_as_text': userInput}),
);
```

### 新方式（通过Spring Boot）
```dart
final response = await http.post(
  Uri.parse('http://localhost:8090/api/v1/ai/query'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $jwtToken',  // 添加JWT认证
  },
  body: jsonEncode({
    'inputAsText': userInput,
    'sessionId': sessionId,  // 可选
  }),
);
```

现在App端只需要将请求URL从 `http://localhost:8200/run` 改为 `http://localhost:8090/api/v1/ai/query`，并添加JWT Token即可！

