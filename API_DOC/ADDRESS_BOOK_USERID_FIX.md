# 通讯录 IM 单聊 userId 字段修复

## 问题描述

之前通讯录集成 IM 单聊功能时，因为 API 没有返回 `userId` 字段，所以使用了 `pk` 字段并尝试将其转换为 `int` 类型的用户 ID。这种方式存在以下问题：

1. **数据类型不匹配**：`pk` 是 UUID 字符串，无法直接转换为 `int`
2. **错误提示不友好**：总是提示"无法解析用户ID"
3. **无法区分联系人类型**：不知道为什么无法发起单聊（是数据问题还是联系人没有账号）

## API 变更

根据最新的通讯录 API 文档（`ADDRESS_BOOK_API.md`），接口现在返回 `userId` 字段：

### 字段说明

```json
{
  "pk": "abc123",           // 主键ID（人员UUID或联系人ID）
  "userId": 5,              // 用户ID（t_user.id），用于IM单聊
  "name": "张三",
  "srcType": "PERSON"       // PERSON-人员表，CONTACT-联系人表
}
```

- **PERSON 类型**：`userId` 为该人员对应的用户 ID（`t_user.id`）
- **CONTACT 类型**：`userId` 为 `null`（联系人没有系统账号，无法发起 IM 单聊）

## 修复内容

### 1. 数据模型更新

**文件**：`lib/features/address_book/data/models/address_book_item_model.dart`

**新增字段**：
```dart
final int? userId; // 用户ID，用于IM单聊（联系人类型为null）
```

**新增便捷方法**：
```dart
/// 是否可以发起IM单聊（有userId）
bool get canStartImChat => userId != null;
```

**`fromJson` 解析**：
```dart
userId: json['userId'] as int?, // 直接解析为 int，可为 null
```

### 2. 通讯录卡片组件更新

**文件**：`lib/features/address_book/presentation/widgets/address_book_item_card.dart`

#### 修改 1：`_sendPrivateMessage` 方法

**之前**：
```dart
final userId = int.tryParse(item.pk);  // 尝试将 pk 转换为 int
if (userId == null) {
  showSnackBar('无法解析用户ID');
  return;
}
```

**现在**：
```dart
if (item.userId == null) {
  showSnackBar(
    item.isFromContact 
      ? '该联系人没有系统账号，无法发起单聊'
      : '无法获取用户ID，无法发起单聊'
  );
  return;
}

// 直接使用 item.userId
final conversation = await conversationProvider.createSingleConversation(item.userId!);
```

#### 修改 2：操作菜单显示

**之前**：
- "发送私信"选项始终可点击
- 点击后才发现无法发起单聊

**现在**：
- 根据 `item.canStartImChat` 判断是否可用
- 不可用时显示为灰色，并在副标题中说明原因
- 点击无效（`onTap: null`, `enabled: false`）

```dart
ListTile(
  leading: Icon(
    Icons.chat_bubble_outline,
    color: item.canStartImChat 
      ? AppColors.brandGreen 
      : Colors.grey,
  ),
  title: Text(
    '发送私信',
    style: TextStyle(
      color: item.canStartImChat
        ? Colors.black87
        : Colors.grey,
    ),
  ),
  subtitle: Text(
    item.canStartImChat 
      ? '发起单聊会话' 
      : (item.isFromContact ? '该联系人无系统账号' : '无法获取用户ID'),
  ),
  onTap: item.canStartImChat ? () {
    Navigator.pop(context);
    _sendPrivateMessage(context, item);
  } : null,
  enabled: item.canStartImChat,
)
```

## 用户体验改进

### 改进前

1. ❌ 点击联系人的"发送私信" → 提示"无法解析用户ID"
2. ❌ 不知道为什么无法发起单聊
3. ❌ 用户可能反复尝试，体验不好

### 改进后

1. ✅ 联系人的"发送私信"选项显示为灰色（不可点击）
2. ✅ 副标题明确说明："该联系人无系统账号"
3. ✅ 对于人员表数据，正常使用 `userId` 发起单聊
4. ✅ 错误提示更加友好和具体

## 测试场景

### 场景 1：人员表数据（有 userId）

```json
{
  "pk": "abc123",
  "userId": 5,
  "name": "张三",
  "srcType": "PERSON"
}
```

**预期行为**：
- ✅ "发送私信"选项正常显示（绿色图标）
- ✅ 点击后能成功创建单聊会话
- ✅ 跳转到聊天页面

### 场景 2：联系人表数据（无 userId）

```json
{
  "pk": "contact-123",
  "userId": null,
  "name": "外部联系人",
  "srcType": "CONTACT"
}
```

**预期行为**：
- ✅ "发送私信"选项显示为灰色（不可点击）
- ✅ 副标题显示："该联系人无系统账号"
- ✅ 点击无效，无法发起单聊
- ✅ 可以正常拨打电话

### 场景 3：数据异常（userId 为 null，但 srcType 是 PERSON）

```json
{
  "pk": "abc456",
  "userId": null,
  "name": "异常数据",
  "srcType": "PERSON"
}
```

**预期行为**：
- ✅ "发送私信"选项显示为灰色（不可点击）
- ✅ 副标题显示："无法获取用户ID"
- ✅ 点击无效，无法发起单聊

## 兼容性说明

### 向后兼容

- ✅ 对于旧版 API（没有 `userId` 字段）：
  - `userId` 解析为 `null`
  - 自动判断为不可发起单聊
  - 显示友好的错误提示

### 前向兼容

- ✅ 对于新版 API（有 `userId` 字段）：
  - 正确解析 `userId`
  - 正常发起 IM 单聊
  - 区分人员和联系人

## 相关文件

1. **数据模型**：
   - `lib/features/address_book/data/models/address_book_item_model.dart`

2. **UI 组件**：
   - `lib/features/address_book/presentation/widgets/address_book_item_card.dart`

3. **API 文档**：
   - `API_DOC/ADDRESS_BOOK_API.md` - 通讯录接口文档
   - `API_DOC/IM_API.md` - IM 即时通讯接口文档

## 修复日期

2025-11-11

## 测试建议

1. **测试人员表数据**：
   - 从通讯录选择一个有系统账号的人员
   - 点击"发送私信"
   - 验证能够成功创建单聊并跳转到聊天页面

2. **测试联系人表数据**：
   - 从通讯录选择一个外部联系人（如果有）
   - 验证"发送私信"选项显示为灰色
   - 验证副标题显示正确的提示信息
   - 验证点击无效

3. **测试头像显示**：
   - 验证通讯录列表中的头像能够正确显示
   - 验证聊天界面中的头像能够正确显示
   - 验证没有头像时显示首字母占位符

4. **测试离线消息同步**：
   - 发送一条消息后退出聊天
   - 重新进入聊天
   - 验证消息的发送者身份显示正确（自己的消息在右边，对方的消息在左边）

