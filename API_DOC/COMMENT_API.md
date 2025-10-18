# 帖子评论 API 文档

## 概述

本文档描述了帖子评论功能相关的API接口，包括：

1. **创建评论**：用户可以评论帖子或回复其他用户的评论
2. **获取评论列表**：分页查询帖子的所有评论
3. **删除评论**：用户可以删除自己发表的评论
4. **消息通知**：评论和回复会自动发送消息通知

### 功能特点

- **一级评论结构**：所有评论平铺展示，通过回复关系关联
- **@回复语义**：回复评论时自动添加"@被回复人"前缀
- **消息推送**：评论帖子通知发帖人，回复评论通知被回复人
- **权限控制**：用户只能删除自己的评论

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

### 1. 创建评论/回复评论

**接口描述**: 用户可以评论帖子，也可以回复其他用户的评论。回复评论时，内容会自动添加@前缀。

- **URL**: `/api/v1/notices/{noticeId}/comments`
- **方法**: `POST`
- **认证**: 需要JWT Token

#### 路径参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| noticeId | number | 是 | 帖子ID |

#### 请求参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| content | string | 是 | 评论内容（不含@前缀，最多1000字符） |
| replyToCommentId | number | 否 | 被回复的评论ID（为空表示评论帖子，不为空表示回复评论） |

#### 请求示例

**评论帖子**:

```http
POST /api/v1/notices/1/comments HTTP/1.1
Host: localhost:8090
Content-Type: application/json
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

{
  "content": "这是一条评论"
}
```

**回复评论**:

```http
POST /api/v1/notices/1/comments HTTP/1.1
Host: localhost:8090
Content-Type: application/json
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

{
  "content": "我也这么认为",
  "replyToCommentId": 123
}
```

#### cURL示例

**评论帖子**:

```bash
curl -X POST 'http://localhost:8090/api/v1/notices/1/comments' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer YOUR_ACCESS_TOKEN' \
  -d '{
    "content": "这是一条评论"
  }'
```

**回复评论**:

```bash
curl -X POST 'http://localhost:8090/api/v1/notices/1/comments' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer YOUR_ACCESS_TOKEN' \
  -d '{
    "content": "我也这么认为",
    "replyToCommentId": 123
  }'
```

#### 响应示例

**成功响应 (200)**:

```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": {
    "id": 124,
    "noticeId": 1,
    "commenterId": 5,
    "commenterName": "张三",
    "commenterAvatar": null,
    "content": "@李四 我也这么认为",
    "replyToCommentId": 123,
    "replyToUserId": 4,
    "replyToName": "李四",
    "createdAt": "2025-10-18T20:30:00",
    "canDelete": true
  }
}
```

**失败响应 - 帖子不存在 (404)**:

```json
{
  "success": false,
  "code": "NOTICE_NOT_FOUND",
  "message": "帖子不存在",
  "data": null
}
```

**失败响应 - 被回复的评论不存在 (404)**:

```json
{
  "success": false,
  "code": "COMMENT_NOT_FOUND",
  "message": "被回复的评论不存在",
  "data": null
}
```

**失败响应 - 只能评论用户帖子 (400)**:

```json
{
  "success": false,
  "code": "NOT_USER_POST",
  "message": "只能评论用户发布的帖子",
  "data": null
}
```

#### 响应字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| id | number | 评论ID |
| noticeId | number | 帖子ID |
| commenterId | number | 评论人用户ID |
| commenterName | string | 评论人姓名 |
| commenterAvatar | string \| null | 评论人头像URL |
| content | string | 评论内容（包含@前缀） |
| replyToCommentId | number \| null | 被回复的评论ID |
| replyToUserId | number \| null | 被回复的用户ID |
| replyToName | string \| null | 被回复人姓名 |
| createdAt | string | 创建时间（ISO 8601格式） |
| canDelete | boolean | 是否可删除（当前用户是否为评论人） |

#### 业务规则

1. **帖子验证**：只能评论用户发布的帖子（notice_type=1），不能评论官方公告
2. **回复验证**：如果是回复评论，被回复的评论必须存在且属于同一个帖子
3. **@前缀**：回复评论时，后端会自动在content前添加"@被回复人 "
4. **消息通知**：
   - 评论帖子 → 发帖人收到通知
   - 回复评论 → 被回复人收到通知
   - 不给自己发通知（评论自己的帖子或回复自己的评论）

---

### 2. 获取评论列表

**接口描述**: 分页查询指定帖子的所有评论，按创建时间正序排列。

- **URL**: `/api/v1/notices/{noticeId}/comments`
- **方法**: `GET`
- **认证**: 可选（未登录也能查看，但canDelete字段为false）

#### 路径参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| noticeId | number | 是 | 帖子ID |

#### 查询参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| page | number | 否 | 1 | 页码，从1开始 |
| size | number | 否 | 20 | 每页大小，建议10-50 |

#### 请求示例

```http
GET /api/v1/notices/1/comments?page=1&size=20 HTTP/1.1
Host: localhost:8090
Content-Type: application/json
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

#### cURL示例

```bash
curl -X GET 'http://localhost:8090/api/v1/notices/1/comments?page=1&size=20' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer YOUR_ACCESS_TOKEN'
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
        "noticeId": 1,
        "commenterId": 4,
        "commenterName": "李四",
        "commenterAvatar": "/uploads/avatar/lisi.jpg",
        "content": "这是一条评论",
        "replyToCommentId": null,
        "replyToUserId": null,
        "replyToName": null,
        "createdAt": "2025-10-18T20:00:00",
        "canDelete": false
      },
      {
        "id": 124,
        "noticeId": 1,
        "commenterId": 5,
        "commenterName": "张三",
        "commenterAvatar": "/uploads/avatar/zhangsan.jpg",
        "content": "@李四 我也这么认为",
        "replyToCommentId": 123,
        "replyToUserId": 4,
        "replyToName": "李四",
        "createdAt": "2025-10-18T20:30:00",
        "canDelete": true
      },
      {
        "id": 125,
        "noticeId": 1,
        "commenterId": 4,
        "commenterName": "李四",
        "commenterAvatar": "/uploads/avatar/lisi.jpg",
        "content": "@张三 有道理",
        "replyToCommentId": 124,
        "replyToUserId": 5,
        "replyToName": "张三",
        "createdAt": "2025-10-18T20:45:00",
        "canDelete": false
      }
    ],
    "page": 1,
    "size": 20,
    "total": 3,
    "pages": 1,
    "hasNext": false,
    "hasPrev": false
  }
}
```

#### 响应字段说明

**分页对象**:

| 字段 | 类型 | 说明 |
|------|------|------|
| data | array | 评论列表数据 |
| page | number | 当前页码 |
| size | number | 每页大小 |
| total | number | 总记录数 |
| pages | number | 总页数 |
| hasNext | boolean | 是否有下一页 |
| hasPrev | boolean | 是否有上一页 |

**评论对象字段**（同创建评论响应）

#### 排序规则

- 按创建时间正序排列（早的在前）
- 适合从上往下阅读的评论流

---

### 3. 删除评论

**接口描述**: 删除自己发表的评论（逻辑删除）。

- **URL**: `/api/v1/comments/{commentId}`
- **方法**: `DELETE`
- **认证**: 需要JWT Token

#### 路径参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| commentId | number | 是 | 评论ID |

#### 请求示例

```http
DELETE /api/v1/comments/124 HTTP/1.1
Host: localhost:8090
Content-Type: application/json
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

#### cURL示例

```bash
curl -X DELETE 'http://localhost:8090/api/v1/comments/124' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer YOUR_ACCESS_TOKEN'
```

#### 响应示例

**成功响应 (200)**:

```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": "删除评论成功"
}
```

**失败响应 - 评论不存在 (404)**:

```json
{
  "success": false,
  "code": "COMMENT_NOT_FOUND",
  "message": "评论不存在",
  "data": null
}
```

**失败响应 - 无权删除 (403)**:

```json
{
  "success": false,
  "code": "PERMISSION_DENIED",
  "message": "无权删除该评论",
  "data": null
}
```

#### 权限规则

- 只能删除自己发表的评论
- 删除是逻辑删除，数据库记录保留但不再显示

---

## Flutter 集成示例

### 1. 定义数据模型

```dart
// 评论模型
class Comment {
  final int id;
  final int noticeId;
  final int commenterId;
  final String commenterName;
  final String? commenterAvatar;
  final String content;
  final int? replyToCommentId;
  final int? replyToUserId;
  final String? replyToName;
  final DateTime createdAt;
  final bool canDelete;

  Comment({
    required this.id,
    required this.noticeId,
    required this.commenterId,
    required this.commenterName,
    this.commenterAvatar,
    required this.content,
    this.replyToCommentId,
    this.replyToUserId,
    this.replyToName,
    required this.createdAt,
    required this.canDelete,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      noticeId: json['noticeId'],
      commenterId: json['commenterId'],
      commenterName: json['commenterName'],
      commenterAvatar: json['commenterAvatar'],
      content: json['content'],
      replyToCommentId: json['replyToCommentId'],
      replyToUserId: json['replyToUserId'],
      replyToName: json['replyToName'],
      createdAt: DateTime.parse(json['createdAt']),
      canDelete: json['canDelete'],
    );
  }

  // 是否为回复评论
  bool get isReply => replyToCommentId != null;

  // 获取头像URL（带默认值）
  String get avatarUrl {
    if (commenterAvatar != null && commenterAvatar!.isNotEmpty) {
      return 'http://localhost:8090$commenterAvatar';
    }
    return 'assets/images/default_avatar.png';
  }

  // 格式化时间显示
  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
    }
  }
}

// 创建评论请求
class CreateCommentRequest {
  final String content;
  final int? replyToCommentId;

  CreateCommentRequest({
    required this.content,
    this.replyToCommentId,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      if (replyToCommentId != null) 'replyToCommentId': replyToCommentId,
    };
  }
}
```

### 2. API服务类

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class CommentApiService {
  static const String baseUrl = 'http://localhost:8090';
  final String accessToken;

  CommentApiService(this.accessToken);

  /// 创建评论或回复评论
  Future<Comment?> createComment({
    required int noticeId,
    required String content,
    int? replyToCommentId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/notices/$noticeId/comments');
      
      final request = CreateCommentRequest(
        content: content,
        replyToCommentId: replyToCommentId,
      );

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(request.toJson()),
      );

      final data = jsonDecode(response.body);

      if (data['success']) {
        return Comment.fromJson(data['data']);
      } else {
        print('创建评论失败: ${data['message']}');
        return null;
      }
    } catch (e) {
      print('请求失败: $e');
      return null;
    }
  }

  /// 获取评论列表（分页）
  Future<PageResponse<Comment>?> getCommentList({
    required int noticeId,
    int page = 1,
    int size = 20,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/api/v1/notices/$noticeId/comments?page=$page&size=$size',
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
          (json) => Comment.fromJson(json),
        );
      } else {
        print('获取评论列表失败: ${data['message']}');
        return null;
      }
    } catch (e) {
      print('请求失败: $e');
      return null;
    }
  }

  /// 删除评论
  Future<bool> deleteComment(int commentId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/comments/$commentId');

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      final data = jsonDecode(response.body);

      if (data['success']) {
        return true;
      } else {
        print('删除评论失败: ${data['message']}');
        return false;
      }
    } catch (e) {
      print('请求失败: $e');
      return false;
    }
  }
}
```

### 3. 评论列表页面

```dart
import 'package:flutter/material.dart';

class CommentListPage extends StatefulWidget {
  final int noticeId;
  final String noticeTitle;
  final String accessToken;

  const CommentListPage({
    Key? key,
    required this.noticeId,
    required this.noticeTitle,
    required this.accessToken,
  }) : super(key: key);

  @override
  _CommentListPageState createState() => _CommentListPageState();
}

class _CommentListPageState extends State<CommentListPage> {
  late CommentApiService _apiService;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _commentController = TextEditingController();

  List<Comment> _comments = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isSubmitting = false;

  // 当前正在回复的评论
  Comment? _replyingTo;

  @override
  void initState() {
    super.initState();
    _apiService = CommentApiService(widget.accessToken);
    _loadComments();

    // 监听滚动，实现分页加载
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.9 &&
        !_isLoading &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadComments() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final response = await _apiService.getCommentList(
      noticeId: widget.noticeId,
      page: _currentPage,
      size: 20,
    );

    if (response != null) {
      setState(() {
        if (_currentPage == 1) {
          _comments = response.data;
        } else {
          _comments.addAll(response.data);
        }
        _hasMore = response.hasNext;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    _currentPage++;
    await _loadComments();
  }

  Future<void> _refresh() async {
    _currentPage = 1;
    _hasMore = true;
    await _loadComments();
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('评论内容不能为空')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final comment = await _apiService.createComment(
      noticeId: widget.noticeId,
      content: content,
      replyToCommentId: _replyingTo?.id,
    );

    setState(() => _isSubmitting = false);

    if (comment != null) {
      _commentController.clear();
      _replyingTo = null;
      // 刷新列表
      await _refresh();
      // 滚动到底部显示新评论
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('发表评论失败')),
      );
    }
  }

  Future<void> _deleteComment(Comment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条评论吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _apiService.deleteComment(comment.id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除成功')),
        );
        await _refresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除失败')),
        );
      }
    }
  }

  void _replyToComment(Comment comment) {
    setState(() {
      _replyingTo = comment;
    });
    FocusScope.of(context).requestFocus(FocusNode());
    _commentController.text = '';
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('评论'),
        backgroundColor: Colors.blue[700],
      ),
      body: Column(
        children: [
          // 评论列表
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: _comments.isEmpty && !_isLoading
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _comments.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _comments.length) {
                          return _buildLoadingIndicator();
                        }
                        return _buildCommentCard(_comments[index]);
                      },
                    ),
            ),
          ),

          // 评论输入框
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildCommentCard(Comment comment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 评论人信息
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(comment.avatarUrl),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.commenterName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        comment.formattedTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // 删除按钮
                if (comment.canDelete)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: Colors.red,
                    onPressed: () => _deleteComment(comment),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // 评论内容
            Text(
              comment.content,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),

            // 回复按钮
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _replyToComment(comment),
                icon: const Icon(Icons.reply, size: 16),
                label: const Text('回复'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue[700],
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 回复提示
            if (_replyingTo != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.blue[50],
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '回复 ${_replyingTo!.commenterName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: _cancelReply,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

            // 输入框
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: _replyingTo != null
                            ? '回复 ${_replyingTo!.commenterName}'
                            : '写评论...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submitComment(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isSubmitting ? null : _submitComment,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    color: Colors.blue[700],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.comment_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '暂无评论',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            '快来发表第一条评论吧',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
```

---

## 常见问题 FAQ

### Q1: 如何区分评论帖子和回复评论？

**A**: 通过`replyToCommentId`字段判断：
- `replyToCommentId`为`null` → 评论帖子
- `replyToCommentId`不为`null` → 回复评论

前端创建评论时：
```dart
// 评论帖子
await apiService.createComment(
  noticeId: 1,
  content: '这是评论',
  replyToCommentId: null,  // 或不传该字段
);

// 回复评论
await apiService.createComment(
  noticeId: 1,
  content: '我也这么认为',
  replyToCommentId: 123,  // 被回复的评论ID
);
```

### Q2: @前缀是前端还是后端添加的？

**A**: @前缀由**后端自动添加**：
- 前端提交时只需发送纯文本内容，不要手动添加@
- 后端会根据`replyToCommentId`判断是否需要添加@前缀
- 前端显示时直接使用后端返回的`content`字段即可

例如：
```
前端提交：content = "我也这么认为"
后端返回：content = "@李四 我也这么认为"
```

### Q3: 消息通知如何工作？

**A**: 消息通知机制：

1. **评论帖子**：
   - 系统自动向发帖人发送通知
   - 通知类别：`NOTICE_COMMENT`
   - 提示："XXX评论了你的帖子"

2. **回复评论**：
   - 系统自动向被回复人发送通知
   - 通知类别：`COMMENT_REPLY`
   - 提示："XXX回复了你的评论"

3. **特殊规则**：
   - 不给自己发通知（评论自己的帖子或回复自己的评论）
   - 消息存储在`t_message_inbox`表
   - 后续可实现消息中心查看和已读标记功能

### Q4: 为什么评论列表按时间正序排列？

**A**: 按时间正序（早的在前）有以下优点：
- 符合对话逻辑，能看到讨论的发展过程
- 回复评论时能看到上下文
- 适合连续阅读的场景

如果需要倒序显示（最新的在前），可以：
1. 后端修改SQL的`ORDER BY`
2. 前端加载后反转数组
3. 提供排序选项让用户选择

### Q5: 如何实现评论的楼中楼效果？

**A**: 当前实现是**一级评论结构**（平铺展示），如需楼中楼效果：

**方案1：前端分组显示**（推荐）
```dart
// 将评论按回复关系分组
Map<int?, List<Comment>> groupComments(List<Comment> comments) {
  Map<int?, List<Comment>> grouped = {};
  for (var comment in comments) {
    if (comment.replyToCommentId == null) {
      // 一级评论
      grouped[comment.id] = [];
    }
  }
  for (var comment in comments) {
    if (comment.replyToCommentId != null) {
      // 回复评论，归到父评论下
      if (grouped.containsKey(comment.replyToCommentId)) {
        grouped[comment.replyToCommentId]!.add(comment);
      }
    }
  }
  return grouped;
}
```

**方案2：后端改造**（不推荐）
- 改为真正的树形结构
- 需要递归查询
- 性能开销较大

### Q6: 删除评论后会影响回复吗？

**A**: 当前实现：
- 删除是**逻辑删除**（is_deleted=1）
- 被删除的评论不再显示在列表中
- 对该评论的回复也会一并隐藏（因为找不到父评论）

建议优化方案：
1. 删除评论时显示占位符："该评论已被删除"
2. 保留回复的显示，只隐藏原评论内容
3. 或提示用户：删除评论会影响X条回复

### Q7: 如何限制评论频率？

**A**: 防止刷屏的方案：

**后端限制**（建议）：
```java
// 在Service层添加
private Map<Long, LocalDateTime> lastCommentTime = new ConcurrentHashMap<>();

public void checkCommentFrequency(Long userId) {
    LocalDateTime last = lastCommentTime.get(userId);
    if (last != null) {
        long seconds = ChronoUnit.SECONDS.between(last, LocalDateTime.now());
        if (seconds < 10) {  // 10秒内只能评论一次
            throw new BusinessException("TOO_FREQUENT", "评论太频繁，请稍后再试");
        }
    }
    lastCommentTime.put(userId, LocalDateTime.now());
}
```

**前端限制**（辅助）：
```dart
DateTime? _lastCommentTime;

bool _canComment() {
  if (_lastCommentTime == null) return true;
  final diff = DateTime.now().difference(_lastCommentTime!);
  return diff.inSeconds >= 10;
}
```

### Q8: 如何实现评论@多人？

**A**: 当前实现只支持@一个人（被回复人）。如需@多人：

**方案1：富文本@**
- 前端使用富文本编辑器
- 支持输入`@`时弹出用户选择
- 后端解析富文本中的@标记
- 给所有被@的人发送通知

**方案2：简化版@**
- 回复时自动@被回复人（当前实现）
- 评论内容中可以手动输入`@用户名`
- 后端使用正则匹配`@用户名`
- 根据匹配结果发送通知

### Q9: 评论支持表情和图片吗？

**A**: 当前实现只支持纯文本。如需扩展：

**表情支持**：
- 前端：使用emoji键盘或表情选择器
- 后端：无需改动，emoji本质上是Unicode字符
- 存储：contentText字段已支持

**图片支持**：
- 需要修改数据库表，添加图片字段或使用contentHtml
- 先上传图片到服务器，获取URL
- 评论时带上图片URL
- 前端使用富文本或混合布局展示

### Q10: 如何实现评论搜索？

**A**: 评论搜索实现方案：

**后端添加搜索接口**：
```java
// Mapper
List<Map<String, Object>> searchComments(
    @Param("noticeId") Long noticeId,
    @Param("keyword") String keyword,
    @Param("offset") Integer offset,
    @Param("size") Integer size
);

// XML
WHERE notice_id = #{noticeId}
  AND content_text LIKE CONCAT('%', #{keyword}, '%')
  AND status = 1
  AND is_deleted = 0
```

**前端添加搜索框**：
```dart
TextField(
  decoration: InputDecoration(
    hintText: '搜索评论...',
    prefixIcon: Icon(Icons.search),
  ),
  onSubmitted: (keyword) {
    // 调用搜索接口
    _searchComments(keyword);
  },
)
```

---

## 错误码说明

| 错误码 | HTTP状态码 | 说明 | 解决方案 |
|--------|-----------|------|----------|
| `SUCCESS` | 200 | 请求成功 | - |
| `UNAUTHORIZED` | 401 | 未登录或Token无效 | 重新登录获取Token |
| `PERMISSION_DENIED` | 403 | 无权删除该评论 | 只能删除自己的评论 |
| `NOTICE_NOT_FOUND` | 404 | 帖子不存在 | 确认帖子ID是否正确 |
| `COMMENT_NOT_FOUND` | 404 | 评论不存在 | 确认评论ID是否正确，或评论已被删除 |
| `NOT_USER_POST` | 400 | 只能评论用户帖子 | 官方公告不支持评论 |
| `NOTICE_DISABLED` | 400 | 帖子已被禁用 | 该帖子不可评论 |
| `COMMENT_NOT_MATCH` | 400 | 被回复的评论不属于该帖子 | 检查replyToCommentId是否正确 |
| `DELETE_FAILED` | 500 | 删除评论失败 | 稍后重试或联系技术支持 |
| `INVALID_PARAMETER` | 400 | 参数错误 | 检查请求参数格式和内容 |

---

## 使用场景

### 1. 帖子详情页评论区

在帖子详情页面展示评论列表：
- 查看所有评论
- 发表新评论
- 回复其他用户的评论
- 删除自己的评论

### 2. 消息通知

用户收到评论通知：
- "XXX评论了你的帖子"
- "XXX回复了你的评论"
- 点击通知跳转到帖子详情页

### 3. 个人主页

展示用户的评论历史：
- 我发表的评论
- 我收到的回复
- 评论统计数据

### 4. 社区互动

促进用户间交流：
- 学术讨论
- 经验分享
- 问题解答
- 意见反馈

---

## 性能优化建议

### 1. 分页大小选择

- 移动端建议：`size = 20`
- 评论较少的帖子：`size = 50`
- 避免一次加载过多导致卡顿

### 2. 图片加载优化

- 头像使用缩略图
- 懒加载，滚动到可见区域再加载
- 使用占位图和加载动画

### 3. 缓存策略

- 评论列表缓存：缓存5分钟
- 发表评论后立即刷新
- 删除评论后更新本地列表

### 4. 网络优化

- 评论提交时显示乐观更新
- 提交失败后回滚
- 使用连接池复用HTTP连接

### 5. 列表优化

- 使用`ListView.builder`懒加载
- 避免在itemBuilder中创建大量对象
- 复用Widget

---

## 安全建议

1. **Token安全**: 使用`flutter_secure_storage`安全存储JWT令牌
2. **内容审核**: 前端做基本的内容过滤（敏感词、长度限制）
3. **频率限制**: 后端限制评论频率，防止刷屏
4. **权限验证**: 删除操作必须验证用户身份
5. **XSS防护**: 如支持富文本，必须过滤危险HTML标签

---

## 更新日志

| 版本 | 日期 | 说明 |
|------|------|------|
| 1.0.0 | 2025-10-18 | 初始版本，提供评论、回复、删除功能 |

---

**文档维护**: 后端开发团队  
**最后更新**: 2025-10-18  
**API版本**: v1.0.0  
**文档版本**: 1.0.0

