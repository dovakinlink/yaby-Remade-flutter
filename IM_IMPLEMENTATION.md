# IM 即时通讯模块实现说明

## 概述

本次实现完成了基于 WebSocket 的即时通讯功能，支持单聊、消息收发、本地存储等核心功能。

## 实现内容

### 1. 首页布局调整
- ✅ 底部导航栏第2个 Tab 改为"聊天"（原"学习"位置）
- ✅ 快速操作区域将"护理备忘"替换为"学习中心"
- ✅ 保持应用整体 UI 风格统一

### 2. 核心功能

#### WebSocket 实时通讯
- 自动连接/断开管理
- 心跳机制（每30秒）
- 自动重连（指数退避策略）
- 消息发送/接收
- 消息状态追踪

#### 消息类型支持
- ✅ 文本消息（TEXT）
- ✅ 图片消息（IMAGE）
- ✅ 文件消息（FILE）
- 🔄 音频消息（AUDIO）- 模型已完成
- 🔄 视频消息（VIDEO）- 模型已完成

#### 本地存储
- SQLite 数据库持久化
- 会话列表缓存
- 消息历史存储
- 已读位置记录

#### 功能特性
- 消息已读/未读状态
- 消息发送状态（发送中、已送达、失败）
- 会话列表实时更新
- 未读消息数量显示
- 消息时间格式化显示

## 技术架构

### 模块结构
```
lib/features/im/
├── data/
│   ├── models/                     # 数据模型
│   │   ├── conversation_model.dart # 会话模型
│   │   ├── im_message_model.dart   # 消息模型
│   │   ├── message_content.dart    # 消息内容（多种类型）
│   │   ├── group_model.dart        # 群组模型
│   │   ├── group_member_model.dart # 群成员模型
│   │   ├── ws_message.dart         # WebSocket 消息
│   │   └── ws_message_ack.dart     # 消息确认
│   ├── repositories/
│   │   └── im_repository.dart      # REST API 封装
│   ├── services/
│   │   └── websocket_service.dart  # WebSocket 服务
│   └── local/
│       └── im_database.dart        # 本地数据库
├── providers/                      # 状态管理
│   ├── websocket_provider.dart     # WebSocket 连接状态
│   ├── conversation_list_provider.dart # 会话列表状态
│   └── chat_provider.dart          # 聊天页面状态
└── presentation/
    ├── pages/                      # 页面
    │   ├── conversation_list_page.dart # 会话列表
    │   └── chat_page.dart              # 聊天页面
    └── widgets/                    # 组件
        ├── conversation_list_item.dart # 会话列表项
        ├── message_bubble.dart         # 消息气泡
        └── chat_input_bar.dart         # 输入栏
```

### 依赖包
- `web_socket_channel: ^3.0.1` - WebSocket 通讯
- `sqflite: ^2.4.1` - SQLite 数据库
- `path_provider: ^2.1.4` - 文件路径
- `image_picker: ^1.1.2` - 图片选择
- `file_picker: ^8.1.4` - 文件选择
- `cached_network_image: ^3.4.1` - 图片缓存
- `uuid: ^4.5.1` - UUID 生成

## 使用说明

### 配置 WebSocket 服务器

在应用启动后需要配置 WebSocket 连接（待后续实现自动连接逻辑）：

```dart
// 示例：登录成功后连接 WebSocket
final websocketProvider = context.read<WebSocketProvider>();
await websocketProvider.connect(
  'your-server-host',  // 服务器地址
  8090,                 // 端口号
  accessToken,          // JWT Token
);
```

### 进入聊天功能

1. 启动应用并登录
2. 点击底部导航栏第2个 Tab "聊天"
3. 进入会话列表页面

### 发起聊天

会话列表页面右上角 "+" 按钮：
- **发起单聊**：选择联系人创建一对一会话
- **创建群聊**：选择多个成员创建群聊（待实现）

### 发送消息

在聊天页面：
- **文本消息**：直接输入文本点击发送
- **图片消息**：点击 "+" 按钮选择 "发送图片"
- **文件消息**：点击 "+" 按钮选择 "发送文件"

## API 集成

### REST API 端点
- `GET /api/v1/im/conversations` - 获取会话列表
- `GET /api/v1/im/conversations/{convId}` - 获取会话详情
- `POST /api/v1/im/conversations/single` - 创建单聊
- `POST /api/v1/im/conversations/group` - 创建群聊
- `GET /api/v1/im/messages/{convId}/history` - 获取历史消息
- `PUT /api/v1/im/messages/{convId}/read` - 更新已读位置

### WebSocket 端点
- `ws://[host]:[port]/im/ws?token=[JWT_ACCESS_TOKEN]`

### 消息类型（WebSocket）
- `SEND_MSG` - 发送消息
- `MSG_RECEIVED` - 新消息通知
- `SYNC_REQ` - 同步消息请求
- `SYNC_RESP` - 同步消息响应
- `READ_ACK` - 已读确认

## 数据库表结构

### conversations（会话表）
- `conv_id` - 会话ID（主键）
- `type` - 会话类型（SINGLE/GROUP/SYSTEM）
- `title` - 会话标题
- `avatar` - 会话头像
- `last_message_seq` - 最后消息序号
- `last_message_at` - 最后消息时间
- `last_message_preview` - 最后消息预览
- `unread_count` - 未读数量
- `created_at` - 创建时间

### messages（消息表）
- `id` - 消息ID（主键）
- `conv_id` - 会话ID
- `seq` - 消息序号
- `sender_user_id` - 发送者ID
- `sender_name` - 发送者姓名
- `sender_avatar` - 发送者头像
- `msg_type` - 消息类型
- `body` - 消息内容（JSON）
- `mentions` - @用户列表
- `is_revoked` - 是否撤回
- `revoke_at` - 撤回时间
- `created_at` - 创建时间
- `client_msg_id` - 客户端消息ID
- `local_status` - 本地状态

### read_positions（已读位置表）
- `conv_id` - 会话ID（主键）
- `seq` - 已读序号
- `updated_at` - 更新时间

## 后续扩展功能

### 待实现功能（基础架构已完成）

1. **群组功能**
   - 创建群聊页面
   - 群组详情页面
   - 群成员管理
   - 添加/移除成员
   - 转让群主

2. **高级功能**
   - 完整的离线消息同步
   - 消息撤回（2分钟内）
   - @提醒功能
   - 语音/视频消息
   - 消息转发
   - 会话置顶
   - 消息搜索

3. **优化项**
   - 图片压缩上传
   - 大文件分片上传
   - 消息加载性能优化
   - 网络状态监听
   - 断线重连优化

## 故障排查

### WebSocket 连接失败
- 检查服务器地址和端口
- 确认 JWT Token 有效
- 检查网络连接
- 查看服务器日志

### 消息发送失败
- 检查 WebSocket 连接状态
- 确认会话ID有效
- 查看本地消息状态
- 重试发送或使用 REST API 备用

### 本地数据库问题
- 清除应用数据重新安装
- 检查存储权限
- 查看数据库文件是否损坏

## 测试建议

1. **单元测试**
   - 数据模型序列化/反序列化
   - Repository API 调用
   - Provider 状态管理逻辑

2. **集成测试**
   - WebSocket 连接/断开
   - 消息发送/接收流程
   - 本地数据库读写

3. **UI 测试**
   - 会话列表显示
   - 聊天页面交互
   - 消息气泡渲染

## 相关文档

- [IM API 文档](./API_DOC/IM_API.md) - 完整的 API 接口说明
- [Flutter 开发指南](./BUILD_GUIDE.md) - 项目构建说明

## 版本历史

- **v1.0.0** (2025-11-11)
  - 初始实现
  - WebSocket 实时通讯
  - 单聊功能
  - 文本/图片/文件消息
  - 本地存储
  - 基础 UI 组件

---

**开发者**: AI Assistant  
**最后更新**: 2025-11-11

