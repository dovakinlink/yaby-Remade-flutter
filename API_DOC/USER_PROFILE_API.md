# 用户信息 API 文档

本文档描述用户个人信息管理相关的API接口，包括查询、更新用户信息等功能。

## 目录

- [接口概览](#接口概览)
- [1. 查询当前用户信息](#1-查询当前用户信息)
- [2. 查询指定用户信息](#2-查询指定用户信息)
- [3. 更新当前用户信息](#3-更新当前用户信息)
- [4. 修改密码](#4-修改密码)
- [数据模型](#数据模型)
- [使用场景](#使用场景)
- [注意事项](#注意事项)

---

## 接口概览

| 接口 | 方法 | 路径 | 说明 |
|------|------|------|------|
| 查询当前用户信息 | GET | `/api/v1/user-profile/me` | 获取当前登录用户的详细信息 |
| 查询指定用户信息 | GET | `/api/v1/user-profile/{userId}` | 获取指定用户的详细信息 |
| 更新当前用户信息 | PUT | `/api/v1/user-profile/me` | 更新当前登录用户的个人信息 |
| 修改密码 | PUT | `/api/v1/user-profile/change-password` | 修改当前用户的密码 |

---

## 1. 查询当前用户信息

**接口描述**: 查询当前登录用户的详细信息，包括基本信息、角色信息、归属信息等。

- **URL**: `/api/v1/user-profile/me`
- **方法**: `GET`
- **认证**: 需要认证（Bearer Token）

### 请求参数

无

### 请求头

```
Authorization: Bearer {accessToken}
Content-Type: application/json
```

### 响应示例

**成功响应 (200)**:

```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": {
    "id": 123,
    "username": "zhangsan",
    "nickname": "张医生",
    "phone": "13800138000",
    "email": "zhangsan@example.com",
    "avatar": "https://example.com/avatar.jpg",
    "orgId": 1,
    "status": 1,
    "createTime": "2025-01-01T10:00:00",
    "updateTime": "2025-10-19T15:30:00",
    "roleCode": "PI",
    "roleName": "主要研究者",
    "systemRoleId": 2,
    "systemRoleName": "医生",
    "affiliationType": "HOSPITAL",
    "hospitalId": 101,
    "hospitalName": "北京协和医院",
    "departmentId": 201,
    "departmentName": "肿瘤科",
    "companyId": null,
    "companyName": null
  }
}
```

**错误响应 (401)**:

```json
{
  "success": false,
  "code": "UNAUTHORIZED",
  "message": "请先登录",
  "data": null
}
```

### Flutter 调用示例

```dart
Future<UserProfile> getCurrentUserProfile() async {
  final response = await http.get(
    Uri.parse('http://localhost:8090/api/v1/user-profile/me'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken'
    },
  );

  final result = jsonDecode(response.body);
  if (result['success']) {
    return UserProfile.fromJson(result['data']);
  } else {
    throw Exception(result['message']);
  }
}
```

---

## 2. 查询指定用户信息

**接口描述**: 根据用户ID查询指定用户的详细信息，用于查看其他用户的个人资料。常用于评论列表、帖子作者、筛查记录等场景中点击用户名查看详情。

- **URL**: `/api/v1/user-profile/{userId}`
- **方法**: `GET`
- **认证**: 需要认证（Bearer Token）

### 请求参数

#### 路径参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| userId | Long | 是 | 要查询的用户ID |

### 请求头

```
Authorization: Bearer {accessToken}
Content-Type: application/json
```

### 响应示例

**成功响应 (200)**:

```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": {
    "id": 456,
    "username": "lisi",
    "nickname": "李CRC",
    "phone": "13900139000",
    "email": "lisi@example.com",
    "avatar": "https://example.com/avatar2.jpg",
    "orgId": 1,
    "status": 1,
    "createTime": "2024-12-01T09:00:00",
    "updateTime": "2025-10-18T14:20:00",
    "roleCode": "CRC",
    "roleName": "临床研究协调员",
    "systemRoleId": 3,
    "systemRoleName": "CRC",
    "affiliationType": "HOSPITAL",
    "hospitalId": 101,
    "hospitalName": "北京协和医院",
    "departmentId": 202,
    "departmentName": "研究中心",
    "companyId": null,
    "companyName": null
  }
}
```

**错误响应 (401)**:

```json
{
  "success": false,
  "code": "UNAUTHORIZED",
  "message": "请先登录",
  "data": null
}
```

**错误响应 (404)**:

```json
{
  "success": false,
  "code": "USER_NOT_FOUND",
  "message": "用户不存在",
  "data": null
}
```

### Flutter 调用示例

```dart
Future<UserProfile> getUserProfile(int userId) async {
  final response = await http.get(
    Uri.parse('http://localhost:8090/api/v1/user-profile/$userId'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken'
    },
  );

  final result = jsonDecode(response.body);
  if (result['success']) {
    return UserProfile.fromJson(result['data']);
  } else {
    throw Exception(result['message']);
  }
}

// 使用示例：在评论列表中点击用户名
void onUserNameTapped(int commentUserId) async {
  try {
    final userProfile = await getUserProfile(commentUserId);
    // 跳转到用户详情页面
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfilePage(profile: userProfile),
      ),
    );
  } catch (e) {
    showError('获取用户信息失败: $e');
  }
}
```

---

## 3. 更新当前用户信息

**接口描述**: 更新当前登录用户的个人信息，支持更新昵称、手机号、邮箱和头像。

- **URL**: `/api/v1/user-profile/me`
- **方法**: `PUT`
- **认证**: 需要认证（Bearer Token）

### 请求参数

#### Body 参数（JSON）

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| nickname | String | 否 | 用户昵称，最长50字符 |
| phone | String | 否 | 手机号码，需符合格式要求 |
| email | String | 否 | 邮箱地址，需符合格式要求 |
| avatar | String | 否 | 头像URL |

### 请求头

```
Authorization: Bearer {accessToken}
Content-Type: application/json
```

### 请求示例

```json
{
  "nickname": "张医生",
  "phone": "13800138001",
  "email": "zhangsan_new@example.com",
  "avatar": "https://example.com/new-avatar.jpg"
}
```

### 响应示例

**成功响应 (200)**:

```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": {
    "id": 123,
    "username": "zhangsan",
    "nickname": "张医生",
    "phone": "13800138001",
    "email": "zhangsan_new@example.com",
    "avatar": "https://example.com/new-avatar.jpg",
    "orgId": 1,
    "status": 1,
    "createTime": "2025-01-01T10:00:00",
    "updateTime": "2025-10-19T16:00:00",
    "roleCode": "PI",
    "roleName": "主要研究者",
    "systemRoleId": 2,
    "systemRoleName": "医生",
    "affiliationType": "HOSPITAL",
    "hospitalId": 101,
    "hospitalName": "北京协和医院",
    "departmentId": 201,
    "departmentName": "肿瘤科",
    "companyId": null,
    "companyName": null
  }
}
```

### Flutter 调用示例

```dart
Future<UserProfile> updateUserProfile({
  String? nickname,
  String? phone,
  String? email,
  String? avatar,
}) async {
  final requestBody = <String, dynamic>{};
  if (nickname != null) requestBody['nickname'] = nickname;
  if (phone != null) requestBody['phone'] = phone;
  if (email != null) requestBody['email'] = email;
  if (avatar != null) requestBody['avatar'] = avatar;

  final response = await http.put(
    Uri.parse('http://localhost:8090/api/v1/user-profile/me'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken'
    },
    body: jsonEncode(requestBody),
  );

  final result = jsonDecode(response.body);
  if (result['success']) {
    return UserProfile.fromJson(result['data']);
  } else {
    throw Exception(result['message']);
  }
}
```

---

## 4. 修改密码

**接口描述**: 修改当前用户的密码，需要验证旧密码。修改成功后，当前JWT Token仍然有效，用户无需重新登录。

- **URL**: `/api/v1/user-profile/change-password`
- **方法**: `PUT`
- **认证**: 需要认证（Bearer Token）

### 请求参数

#### Body 参数（JSON）

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| oldPassword | String | 是 | 旧密码（明文） |
| newPassword | String | 是 | 新密码（明文），最少6位 |

### 请求头

```
Authorization: Bearer {accessToken}
Content-Type: application/json
```

### 请求示例

```json
{
  "oldPassword": "oldPassword123",
  "newPassword": "newPassword456"
}
```

### 响应示例

**成功响应 (200)**:

```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": "密码修改成功"
}
```

**错误响应 (400)**:

```json
{
  "success": false,
  "code": "INVALID_PASSWORD",
  "message": "旧密码不正确",
  "data": null
}
```

### Flutter 调用示例

```dart
Future<void> changePassword(String oldPassword, String newPassword) async {
  final response = await http.put(
    Uri.parse('http://localhost:8090/api/v1/user-profile/change-password'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken'
    },
    body: jsonEncode({
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    }),
  );

  final result = jsonDecode(response.body);
  if (!result['success']) {
    throw Exception(result['message']);
  }
}
```

---

## 数据模型

### UserProfileVO

用户个人信息视图对象，包含用户的完整信息。

| 字段名 | 类型 | 说明 |
|--------|------|------|
| id | Long | 用户ID |
| username | String | 登录用户名 |
| nickname | String | 用户昵称 |
| phone | String | 手机号码 |
| email | String | 邮箱地址 |
| avatar | String | 用户头像URL |
| orgId | Long | 所属组织ID |
| status | Integer | 用户状态（1-正常，0-禁用） |
| createTime | DateTime | 注册时间 |
| updateTime | DateTime | 最后更新时间 |
| roleCode | String | 业务角色代码（如PI、CRC、CRA等） |
| roleName | String | 业务角色名称 |
| systemRoleId | Integer | 系统角色ID |
| systemRoleName | String | 系统角色名称 |
| affiliationType | String | 归属类型（HOSPITAL/CRO/SPONSOR） |
| hospitalId | Long | 医院ID（当归属类型为HOSPITAL时） |
| hospitalName | String | 医院名称 |
| departmentId | Long | 科室ID |
| departmentName | String | 科室名称 |
| companyId | Long | 公司ID（当归属类型为CRO或SPONSOR时） |
| companyName | String | 公司名称 |

---

## 使用场景

### 1. 个人信息页面

在用户个人中心页面显示当前用户的详细信息：

```dart
class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await getCurrentUserProfile();
    setState(() {
      _profile = profile;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_profile == null) {
      return Center(child: CircularProgressIndicator());
    }

    return ListView(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: NetworkImage(_profile!.avatar ?? ''),
        ),
        Text(_profile!.nickname ?? _profile!.username),
        Text(_profile!.roleName ?? ''),
        Text(_profile!.hospitalName ?? ''),
        // ... 其他信息
      ],
    );
  }
}
```

### 2. 查看其他用户信息

在评论列表、帖子、筛查记录等场景中点击用户名查看详情：

```dart
// 评论列表中的用户名可点击
Widget buildCommentItem(Comment comment) {
  return ListTile(
    leading: CircleAvatar(
      backgroundImage: NetworkImage(comment.userAvatar ?? ''),
    ),
    title: GestureDetector(
      onTap: () => _showUserProfile(comment.userId),
      child: Text(
        comment.userName,
        style: TextStyle(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
      ),
    ),
    subtitle: Text(comment.content),
  );
}

void _showUserProfile(int userId) async {
  final profile = await getUserProfile(userId);
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => UserProfileDetailPage(profile: profile),
    ),
  );
}
```

### 3. 项目成员列表

显示项目团队成员，点击可查看详细信息：

```dart
class ProjectMembersList extends StatelessWidget {
  final List<int> memberUserIds;

  Future<void> _showMemberDetail(BuildContext context, int userId) async {
    try {
      final profile = await getUserProfile(userId);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(profile.nickname ?? profile.username),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('角色: ${profile.roleName}'),
              Text('单位: ${profile.hospitalName}'),
              Text('科室: ${profile.departmentName}'),
              Text('电话: ${profile.phone}'),
              Text('邮箱: ${profile.email}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('关闭'),
            ),
          ],
        ),
      );
    } catch (e) {
      // 错误处理
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: memberUserIds.length,
      itemBuilder: (context, index) {
        final userId = memberUserIds[index];
        return ListTile(
          title: Text('成员 $userId'),
          trailing: Icon(Icons.arrow_forward_ios),
          onTap: () => _showMemberDetail(context, userId),
        );
      },
    );
  }
}
```

### 4. 筛查记录中的人员信息

在筛查详情页面显示医生和CRC的信息，点击可查看详情：

```dart
class ScreeningDetailPage extends StatelessWidget {
  final Screening screening;

  Widget _buildUserChip(BuildContext context, String label, int? userId, String userName) {
    if (userId == null) return SizedBox.shrink();
    
    return Chip(
      avatar: Icon(Icons.person),
      label: Text('$label: $userName'),
      onDeleted: () async {
        // 点击查看用户详情
        final profile = await getUserProfile(userId);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileDetailPage(profile: profile),
          ),
        );
      },
      deleteIcon: Icon(Icons.info_outline),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('筛查详情')),
      body: Column(
        children: [
          _buildUserChip(context, '提交医生', 
              screening.researcherUserId, screening.researcherName),
          _buildUserChip(context, '负责CRC', 
              screening.crcUserId, screening.crcName),
          // ... 其他筛查信息
        ],
      ),
    );
  }
}
```

---

## 注意事项

1. **认证要求**：
   - 所有接口都需要在请求头中携带有效的JWT Token
   - Token格式：`Authorization: Bearer {accessToken}`
   - Token过期时需要重新登录或刷新Token

2. **权限说明**：
   - 查询当前用户信息（`/me`）：只能查看自己的信息
   - 查询指定用户信息（`/{userId}`）：需要登录，可以查看任意用户的公开信息
   - 更新用户信息：只能更新自己的信息
   - 修改密码：只能修改自己的密码

3. **数据安全**：
   - 所有返回的用户信息均不包含密码等敏感信息
   - 密码在传输时使用HTTPS加密，存储时使用MD5加密

4. **更新限制**：
   - 用户名（username）不可修改
   - 用户角色和归属信息需要通过其他管理接口修改
   - 组织绑定关系需要通过用户组织管理接口修改

5. **错误处理**：
   - 401 UNAUTHORIZED：未登录或Token无效
   - 404 USER_NOT_FOUND：用户不存在
   - 400 INVALID_PASSWORD：密码验证失败
   - 400 VALIDATION_ERROR：参数验证失败

---

## 更新日志

- **2025-10-19**: 初始版本
  - 添加查询当前用户信息接口
  - 添加查询指定用户信息接口（新增）
  - 添加更新当前用户信息接口
  - 添加修改密码接口

