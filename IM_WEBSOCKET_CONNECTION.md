# IM WebSocket 连接说明

## 自动连接机制

WebSocket 连接会在以下场景自动建立：

### 1. 登录成功后自动连接
当用户登录成功后，系统会自动：
1. 保存认证 Token
2. 获取用户信息
3. **自动连接 WebSocket** ✅
4. 跳转到首页

代码位置：`lib/features/auth/presentation/pages/login_page.dart`

```dart
// 登录成功后
await session.save(tokens);
await userProfile.loadProfile();

// 连接 WebSocket
_connectWebSocket(context, tokens.accessToken);
```

### 2. 首页初始化时检查连接
当用户进入首页时（包括应用重启后直接进入首页的情况），系统会：
1. 检查用户是否已登录
2. 检查 WebSocket 是否已连接
3. 如果已登录但未连接，则自动连接

代码位置：`lib/features/home/presentation/pages/home_page.dart`

```dart
@override
void initState() {
  super.initState();
  // ...
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // 检查并连接 WebSocket
    _ensureWebSocketConnection();
  });
}
```

## 连接配置

### 自动解析服务器地址
WebSocket 连接会自动从 HTTP API 配置中解析服务器地址：

- **开发环境**
  - iOS 模拟器: `ws://127.0.0.1:8090`
  - Android 模拟器: `ws://10.0.2.2:8090`
  - 真机: `ws://192.168.0.101:8090` (局域网地址)
  - macOS: `ws://127.0.0.1:8090`

- **生产环境**
  - 使用编译时指定的生产环境地址

### WebSocket URL 格式
```
ws://<host>:<port>/im/ws?token=<accessToken>
```

## 连接状态管理

### 连接状态
```dart
enum WebSocketState {
  disconnected,  // 未连接
  connecting,    // 连接中
  connected,     // 已连接
  reconnecting,  // 重连中
}
```

### 监听连接状态
```dart
final websocketProvider = context.watch<WebSocketProvider>();

if (websocketProvider.isConnected) {
  // WebSocket 已连接
} else if (websocketProvider.isConnecting) {
  // 正在连接中
} else if (websocketProvider.isReconnecting) {
  // 正在重连
} else {
  // 未连接
}
```

## 心跳机制

WebSocket 连接建立后，会自动启动心跳机制：
- **心跳间隔**: 30秒
- **心跳消息类型**: `PING`
- **作用**: 保持连接活跃，防止被服务器断开

## 断线重连

当 WebSocket 连接断开时，会自动尝试重连：
- **最大重连次数**: 10次
- **重连策略**: 指数退避（2^n 秒，最多 60 秒）
  - 第1次: 2秒后重连
  - 第2次: 4秒后重连
  - 第3次: 8秒后重连
  - ...
  - 第7次及以后: 60秒后重连

### 不会重连的情况
- 用户主动退出登录
- 手动调用 `disconnect()` 方法
- 超过最大重连次数

## 连接失败处理

如果 WebSocket 连接失败：
1. **不影响其他功能**: HTTP API 调用正常工作
2. **自动重试**: 如果是网络问题，会自动重连
3. **降级方案**: 可以通过 HTTP API 轮询消息（未实现）

## 调试日志

WebSocket 连接过程会输出详细的调试日志：

```
flutter: WebSocket: 开始连接 - host: 127.0.0.1, port: 8090
flutter: WebSocket: 正在连接... ws://127.0.0.1:8090/im/ws?token=xxx
flutter: WebSocket: 连接成功
flutter: WebSocket: 状态变更 - WebSocketState.connected
```

## 常见问题

### Q: WebSocket 连接失败怎么办？
A: 
1. 检查服务器是否启动
2. 检查网络连接是否正常
3. 查看日志中的错误信息
4. 系统会自动尝试重连

### Q: 如何手动断开 WebSocket？
A:
```dart
final websocketProvider = context.read<WebSocketProvider>();
websocketProvider.disconnect();
```

### Q: 如何手动重新连接？
A:
```dart
final websocketProvider = context.read<WebSocketProvider>();
final authSession = context.read<AuthSessionProvider>();
final tokens = authSession.tokens;

if (tokens != null) {
  final baseUrl = await EnvConfig.resolveApiBaseUrl();
  final uri = Uri.parse(baseUrl);
  await websocketProvider.connect(uri.host, uri.port, tokens.accessToken);
}
```

### Q: WebSocket 连接成功但收不到消息？
A:
1. 检查服务器是否正常推送消息
2. 检查消息格式是否正确
3. 查看日志中是否有解析错误

## 技术细节

### 使用的包
- `web_socket_channel: ^3.0.1` - WebSocket 客户端库

### Provider 架构
```
WebSocketService (底层服务)
    ↓
WebSocketProvider (状态管理)
    ↓
ChatProvider (聊天逻辑)
    ↓
ChatPage (UI界面)
```

### 消息处理流程
1. WebSocket 收到原始数据
2. `WebSocketService` 解析为 `WsMessage`
3. 根据消息类型分发：
   - `MESSAGE`: 新消息 → 触发 `newMessageStream`
   - `MESSAGE_ACK`: 消息确认 → 触发 `ackStream`
   - `PONG`: 心跳响应 → 忽略
4. `ChatProvider` 监听消息流
5. 更新 UI 并保存到本地数据库

