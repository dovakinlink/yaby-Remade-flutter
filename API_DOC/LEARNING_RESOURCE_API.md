# 学习资源中心 API 文档

## 概述

本文档描述了学习资源中心相关的API接口，包括：

1. **学习资源列表**：查询当前用户可访问的学习资源（分页）
2. **学习资源详情**：获取学习资源详细信息及关联的文件列表

### 权限说明

学习资源按**医院维度进行数据隔离**：
- 用户只能访问所属医院的学习资源
- 系统自动根据用户的`hospital_id`进行权限验证
- 只展示已启用（`status=1`）且未删除（`is_deleted=0`）的资源

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

### 获取学习资源列表（分页）

**接口描述**: 查询当前登录用户所属医院的学习资源列表，支持分页。

- **URL**: `/api/v1/learning-resources`
- **方法**: `GET`
- **认证**: 需要JWT Token

#### 请求参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| page | number | 否 | 1 | 页码，从1开始 |
| size | number | 否 | 10 | 每页大小，建议10-50 |

#### 请求示例

```http
GET /api/v1/learning-resources?page=1&size=10 HTTP/1.1
Host: localhost:8090
Content-Type: application/json
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

#### cURL示例

```bash
curl -X GET 'http://localhost:8090/api/v1/learning-resources?page=1&size=10' \
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
        "id": 1,
        "name": "临床试验培训教程",
        "orderNo": 100,
        "remark": "面向新入职CRC的基础培训教程",
        "createdAt": "2025-09-01T10:00:00",
        "updatedAt": "2025-10-01T15:30:00"
      },
      {
        "id": 2,
        "name": "GCP规范学习手册",
        "orderNo": 90,
        "remark": "GCP规范详细解读及案例分析",
        "createdAt": "2025-09-05T14:20:00",
        "updatedAt": "2025-09-20T09:15:00"
      }
    ],
    "page": 1,
    "size": 10,
    "total": 2,
    "pages": 1,
    "hasNext": false,
    "hasPrev": false
  }
}
```

**失败响应 - 未登录 (401)**:

```json
{
  "success": false,
  "code": "UNAUTHORIZED",
  "message": "请先登录",
  "data": null
}
```

**失败响应 - 用户未关联医院 (400)**:

```json
{
  "success": false,
  "code": "HOSPITAL_NOT_FOUND",
  "message": "用户未关联医院，无法访问学习资源",
  "data": null
}
```

#### 响应字段说明

**分页对象**:

| 字段 | 类型 | 说明 |
|------|------|------|
| data | array | 学习资源列表数据 |
| page | number | 当前页码 |
| size | number | 每页大小 |
| total | number | 总记录数 |
| pages | number | 总页数 |
| hasNext | boolean | 是否有下一页 |
| hasPrev | boolean | 是否有上一页 |

**学习资源对象字段**:

| 字段 | 类型 | 说明 |
|------|------|------|
| id | number | 资源ID |
| name | string | 资源名称 |
| orderNo | number | 排序号（越大越靠前） |
| remark | string \| null | 备注说明 |
| createdAt | string | 创建时间（ISO 8601格式） |
| updatedAt | string | 最后更新时间（ISO 8601格式） |

#### 业务规则

1. **医院隔离**: 自动按用户所属医院筛选资源
2. **状态过滤**: 只返回启用状态（status=1）的资源
3. **逻辑删除**: 已删除的资源不会显示
4. **排序规则**: 按`orderNo`降序排列，orderNo相同时按ID降序

---

### 获取学习资源详情

**接口描述**: 获取指定学习资源的详细信息，包含关联的文件列表。

- **URL**: `/api/v1/learning-resources/{id}`
- **方法**: `GET`
- **认证**: 需要JWT Token

#### 路径参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| id | number | 是 | 学习资源ID |

#### 请求示例

```http
GET /api/v1/learning-resources/1 HTTP/1.1
Host: localhost:8090
Content-Type: application/json
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

#### cURL示例

```bash
curl -X GET 'http://localhost:8090/api/v1/learning-resources/1' \
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
    "id": 1,
    "name": "临床试验培训教程",
    "orderNo": 100,
    "remark": "面向新入职CRC的基础培训教程",
    "createdAt": "2025-09-01T10:00:00",
    "updatedAt": "2025-10-01T15:30:00",
    "files": [
      {
        "fileId": 10,
        "displayName": "第一章：临床试验概述",
        "filename": "chapter1.pdf",
        "ext": ".pdf",
        "mimeType": "application/pdf",
        "sizeBytes": 2048576,
        "url": "/uploads/learning/chapter1.pdf",
        "sortNo": 1
      },
      {
        "fileId": 11,
        "displayName": "第二章：GCP基础知识",
        "filename": "chapter2.pdf",
        "ext": ".pdf",
        "mimeType": "application/pdf",
        "sizeBytes": 3145728,
        "url": "/uploads/learning/chapter2.pdf",
        "sortNo": 2
      },
      {
        "fileId": 12,
        "displayName": "培训考试题库",
        "filename": "exam-questions.xlsx",
        "ext": ".xlsx",
        "mimeType": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "sizeBytes": 102400,
        "url": "/uploads/learning/exam-questions.xlsx",
        "sortNo": 3
      }
    ]
  }
}
```

**失败响应 - 资源不存在 (404)**:

```json
{
  "success": false,
  "code": "RESOURCE_NOT_FOUND",
  "message": "学习资源不存在",
  "data": null
}
```

**失败响应 - 无权访问 (403)**:

```json
{
  "success": false,
  "code": "PERMISSION_DENIED",
  "message": "无权访问该学习资源",
  "data": null
}
```

**失败响应 - 资源已禁用 (400)**:

```json
{
  "success": false,
  "code": "RESOURCE_DISABLED",
  "message": "该学习资源已被禁用",
  "data": null
}
```

#### 响应字段说明

**学习资源详情对象**:

| 字段 | 类型 | 说明 |
|------|------|------|
| id | number | 资源ID |
| name | string | 资源名称 |
| orderNo | number | 排序号 |
| remark | string \| null | 备注说明 |
| createdAt | string | 创建时间（ISO 8601格式） |
| updatedAt | string | 最后更新时间（ISO 8601格式） |
| files | array | 关联的文件列表 |

**文件对象字段**:

| 字段 | 类型 | 说明 |
|------|------|------|
| fileId | number | 文件ID |
| displayName | string | 前端展示名称（优先显示，若为空则显示filename） |
| filename | string | 文件原始名称 |
| ext | string | 文件扩展名（如：.pdf, .docx） |
| mimeType | string | 文件MIME类型 |
| sizeBytes | number | 文件大小（字节） |
| url | string | 文件访问URL |
| sortNo | number | 排序号（控制文件在列表中的显示顺序） |

#### 文件URL访问说明

- 文件URL格式：`/uploads/...` 或云存储URL
- 支持直接浏览器访问下载
- PDF文件可在线预览
- 图片文件可直接显示

#### 权限验证

1. 验证用户已登录
2. 验证资源存在且未删除
3. 验证资源的`hospital_id`与当前用户的`hospital_id`匹配
4. 验证资源状态为启用（status=1）

---

## Flutter 集成示例

### 1. 定义数据模型

```dart
// 学习资源模型
class LearningResource {
  final int id;
  final String name;
  final int orderNo;
  final String? remark;
  final DateTime createdAt;
  final DateTime updatedAt;

  LearningResource({
    required this.id,
    required this.name,
    required this.orderNo,
    this.remark,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LearningResource.fromJson(Map<String, dynamic> json) {
    return LearningResource(
      id: json['id'],
      name: json['name'],
      orderNo: json['orderNo'],
      remark: json['remark'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

// 资源文件模型
class ResourceFile {
  final int fileId;
  final String displayName;
  final String filename;
  final String ext;
  final String mimeType;
  final int sizeBytes;
  final String url;
  final int sortNo;

  ResourceFile({
    required this.fileId,
    required this.displayName,
    required this.filename,
    required this.ext,
    required this.mimeType,
    required this.sizeBytes,
    required this.url,
    required this.sortNo,
  });

  factory ResourceFile.fromJson(Map<String, dynamic> json) {
    return ResourceFile(
      fileId: json['fileId'],
      displayName: json['displayName'],
      filename: json['filename'],
      ext: json['ext'],
      mimeType: json['mimeType'],
      sizeBytes: json['sizeBytes'],
      url: json['url'],
      sortNo: json['sortNo'],
    );
  }

  // 格式化文件大小
  String get formattedSize {
    if (sizeBytes < 1024) {
      return '$sizeBytes B';
    } else if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  // 判断是否为PDF文件
  bool get isPdf => ext.toLowerCase() == '.pdf';

  // 判断是否为图片文件
  bool get isImage => ['.jpg', '.jpeg', '.png', '.gif', '.webp']
      .contains(ext.toLowerCase());

  // 判断是否为Office文档
  bool get isOfficeDoc => ['.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx']
      .contains(ext.toLowerCase());
}

// 学习资源详情模型
class LearningResourceDetail {
  final int id;
  final String name;
  final int orderNo;
  final String? remark;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ResourceFile> files;

  LearningResourceDetail({
    required this.id,
    required this.name,
    required this.orderNo,
    this.remark,
    required this.createdAt,
    required this.updatedAt,
    required this.files,
  });

  factory LearningResourceDetail.fromJson(Map<String, dynamic> json) {
    return LearningResourceDetail(
      id: json['id'],
      name: json['name'],
      orderNo: json['orderNo'],
      remark: json['remark'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      files: (json['files'] as List)
          .map((file) => ResourceFile.fromJson(file))
          .toList(),
    );
  }

  // 是否有文件
  bool get hasFiles => files.isNotEmpty;

  // 文件总数
  int get fileCount => files.length;
}
```

### 2. API服务类

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class LearningResourceApiService {
  static const String baseUrl = 'http://localhost:8090';
  final String accessToken;

  LearningResourceApiService(this.accessToken);

  /// 获取学习资源列表（分页）
  Future<PageResponse<LearningResource>?> getResourceList({
    int page = 1,
    int size = 10,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/api/v1/learning-resources?page=$page&size=$size',
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
          (json) => LearningResource.fromJson(json),
        );
      } else {
        print('获取学习资源列表失败: ${data['message']}');
        return null;
      }
    } catch (e) {
      print('请求失败: $e');
      return null;
    }
  }

  /// 获取学习资源详情
  Future<LearningResourceDetail?> getResourceDetail(int resourceId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/learning-resources/$resourceId');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      final data = jsonDecode(response.body);

      if (data['success']) {
        return LearningResourceDetail.fromJson(data['data']);
      } else {
        print('获取学习资源详情失败: ${data['message']}');
        return null;
      }
    } catch (e) {
      print('请求失败: $e');
      return null;
    }
  }
}
```

### 3. 学习资源列表页面

```dart
import 'package:flutter/material.dart';

class LearningResourceListPage extends StatefulWidget {
  final String accessToken;

  const LearningResourceListPage({Key? key, required this.accessToken})
      : super(key: key);

  @override
  _LearningResourceListPageState createState() =>
      _LearningResourceListPageState();
}

class _LearningResourceListPageState extends State<LearningResourceListPage> {
  late LearningResourceApiService _apiService;
  final ScrollController _scrollController = ScrollController();

  List<LearningResource> _resources = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _apiService = LearningResourceApiService(widget.accessToken);
    _loadResources();

    // 监听滚动，实现分页加载
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
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

  Future<void> _loadResources() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final response = await _apiService.getResourceList(
      page: _currentPage,
      size: 10,
    );

    if (response != null) {
      setState(() {
        if (_currentPage == 1) {
          _resources = response.data;
        } else {
          _resources.addAll(response.data);
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
    await _loadResources();
  }

  Future<void> _refresh() async {
    _currentPage = 1;
    _hasMore = true;
    await _loadResources();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('学习资源中心'),
        backgroundColor: Colors.blue[700],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _resources.isEmpty && !_isLoading
            ? _buildEmptyState()
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _resources.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _resources.length) {
                    return _buildLoadingIndicator();
                  }
                  return _buildResourceCard(_resources[index]);
                },
              ),
      ),
    );
  }

  Widget _buildResourceCard(LearningResource resource) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToDetail(resource.id),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.school, color: Colors.blue[700], size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      resource.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
              if (resource.remark != null && resource.remark!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  resource.remark!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '更新于 ${_formatDate(resource.updatedAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '暂无学习资源',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _navigateToDetail(int resourceId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LearningResourceDetailPage(
          resourceId: resourceId,
          accessToken: widget.accessToken,
        ),
      ),
    );
  }
}
```

### 4. 学习资源详情页面

```dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LearningResourceDetailPage extends StatefulWidget {
  final int resourceId;
  final String accessToken;

  const LearningResourceDetailPage({
    Key? key,
    required this.resourceId,
    required this.accessToken,
  }) : super(key: key);

  @override
  _LearningResourceDetailPageState createState() =>
      _LearningResourceDetailPageState();
}

class _LearningResourceDetailPageState
    extends State<LearningResourceDetailPage> {
  late LearningResourceApiService _apiService;
  LearningResourceDetail? _detail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _apiService = LearningResourceApiService(widget.accessToken);
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);

    final detail = await _apiService.getResourceDetail(widget.resourceId);

    setState(() {
      _detail = detail;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('资源详情'),
        backgroundColor: Colors.blue[700],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _detail == null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 资源信息卡片
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.school, color: Colors.blue[700], size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _detail!.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_detail!.remark != null &&
                      _detail!.remark!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      _detail!.remark!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '更新于 ${_formatDateTime(_detail!.updatedAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 文件列表
          if (_detail!.hasFiles) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.attach_file, color: Colors.grey[700]),
                  const SizedBox(width: 8),
                  Text(
                    '学习资料 (${_detail!.fileCount})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ..._detail!.files.map((file) => _buildFileCard(file)).toList(),
          ] else ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  '暂无文件',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFileCard(ResourceFile file) {
    IconData fileIcon;
    Color iconColor;

    if (file.isPdf) {
      fileIcon = Icons.picture_as_pdf;
      iconColor = Colors.red;
    } else if (file.isImage) {
      fileIcon = Icons.image;
      iconColor = Colors.blue;
    } else if (file.isOfficeDoc) {
      fileIcon = Icons.description;
      iconColor = Colors.orange;
    } else {
      fileIcon = Icons.insert_drive_file;
      iconColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: Icon(fileIcon, color: iconColor, size: 32),
        title: Text(
          file.displayName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${file.formattedSize} • ${file.ext}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (file.isPdf)
              IconButton(
                icon: const Icon(Icons.visibility, color: Colors.blue),
                onPressed: () => _previewFile(file),
                tooltip: '预览',
              ),
            IconButton(
              icon: const Icon(Icons.download, color: Colors.green),
              onPressed: () => _downloadFile(file),
              tooltip: '下载',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadDetail,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _previewFile(ResourceFile file) async {
    // 实现预览逻辑（如使用flutter_pdfview）
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('预览: ${file.displayName}')),
    );
  }

  Future<void> _downloadFile(ResourceFile file) async {
    final url = 'http://localhost:8090${file.url}';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法下载文件')),
      );
    }
  }
}
```

---

## 常见问题 FAQ

### Q1: 如何下载资源文件？

**A**: 文件下载步骤：
1. 从详情接口获取文件的`url`字段
2. 拼接完整URL：`http://localhost:8090 + url`
3. 使用浏览器或HTTP客户端访问该URL即可下载
4. Flutter中可以使用`url_launcher`包或`dio`包进行下载

### Q2: 支持哪些文件类型？

**A**: 系统支持所有常见文件类型，包括但不限于：
- **文档**: PDF、Word (.doc, .docx)、Excel (.xls, .xlsx)、PowerPoint (.ppt, .pptx)
- **图片**: JPG、PNG、GIF、WebP
- **压缩包**: ZIP、RAR
- **视频**: MP4、AVI（如果服务器支持）

具体可查看文件的`mimeType`字段判断类型。

### Q3: 文件大小限制是多少？

**A**: 
- 文件上传大小限制由服务器配置决定
- 通过`sizeBytes`字段可以看到每个文件的实际大小
- 建议单个文件不超过100MB，以确保良好的下载体验
- 大文件建议使用分片下载或断点续传

### Q4: 为什么看不到某些资源？

**A**: 可能的原因：
1. **医院权限隔离**: 您只能看到所属医院的资源
2. **资源已禁用**: 管理员禁用的资源不会显示（status=0）
3. **资源已删除**: 已删除的资源不会显示（is_deleted=1）
4. **未登录**: 需要先登录并获取JWT Token

### Q5: 如何实现文件预览？

**A**: 不同文件类型的预览方案：

**PDF文件**:
```dart
// 使用flutter_pdfview插件
import 'package:flutter_pdfview/flutter_pdfview.dart';

PDFView(
  filePath: localFilePath,
)
```

**图片文件**:
```dart
// 直接使用Image.network
Image.network('http://localhost:8090${file.url}')
```

**Office文档**:
- 需要先下载到本地
- 使用第三方库（如open_file）打开系统默认应用

### Q6: 列表如何实现无限滚动加载？

**A**: 实现步骤：
1. 监听ScrollController的滚动位置
2. 当滚动到接近底部（如90%位置）时触发加载
3. 检查`hasNext`字段，如果为true则加载下一页
4. 将新数据追加到现有列表

参考代码：
```dart
_scrollController.addListener(() {
  if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.9 &&
      !_isLoading && _hasMore) {
    _loadMore();
  }
});
```

### Q7: 如何处理文件下载失败？

**A**: 建议的错误处理策略：
1. **网络检查**: 下载前检查网络连接状态
2. **重试机制**: 下载失败后提供重试选项
3. **进度显示**: 大文件下载时显示进度条
4. **错误提示**: 明确告知用户失败原因（网络、权限、文件不存在等）

### Q8: 资源列表的排序规则是什么？

**A**: 排序规则：
- 主要按`orderNo`字段降序排列（数值越大越靠前）
- `orderNo`相同时按资源ID降序排列（新资源在前）
- 管理员可以通过设置`orderNo`来控制显示顺序

### Q9: 如何实现下拉刷新？

**A**: Flutter中使用`RefreshIndicator`组件：
```dart
RefreshIndicator(
  onRefresh: () async {
    // 重置页码为1
    _currentPage = 1;
    _hasMore = true;
    // 重新加载第一页数据
    await _loadResources();
  },
  child: ListView(...),
)
```

### Q10: 文件URL是相对路径还是绝对路径？

**A**: 
- API返回的`url`字段是相对路径（如：`/uploads/learning/file.pdf`）
- 客户端需要拼接服务器地址：`http://localhost:8090 + url`
- 生产环境需要替换为实际的服务器地址
- 某些文件可能使用云存储，此时url为完整的HTTP/HTTPS链接

---

## 错误码说明

| 错误码 | HTTP状态码 | 说明 | 解决方案 |
|--------|-----------|------|----------|
| `SUCCESS` | 200 | 请求成功 | - |
| `UNAUTHORIZED` | 401 | 未登录或Token无效 | 重新登录获取Token |
| `PERMISSION_DENIED` | 403 | 无权访问该资源 | 确认资源属于当前用户所在医院 |
| `RESOURCE_NOT_FOUND` | 404 | 学习资源不存在 | 确认资源ID是否正确 |
| `RESOURCE_DISABLED` | 400 | 资源已被禁用 | 联系管理员启用资源 |
| `HOSPITAL_NOT_FOUND` | 400 | 用户未关联医院 | 确保用户账号已绑定医院 |
| `USER_NOT_FOUND` | 404 | 用户不存在 | 重新登录 |
| `SERVER_ERROR` | 500 | 服务器内部错误 | 稍后重试或联系技术支持 |

---

## 使用场景

### 1. 学习中心页面展示

在APP的学习中心页面，展示所有可用的学习资源：
- 使用列表接口获取资源列表
- 支持下拉刷新和上拉加载更多
- 点击资源卡片进入详情页面

### 2. 培训资料下载

为新员工提供系统培训资料：
- 查看资源详情和文件列表
- 下载培训文档到本地学习
- 支持离线查看（需要先下载）

### 3. 在线预览学习

直接在APP内预览学习资料：
- PDF文件在线预览
- 图片直接显示
- 视频在线播放

### 4. 考试题库管理

存储和分发考试相关资料：
- 题库文件（Excel、Word格式）
- 答案解析文档
- 历年真题集

---

## 性能优化建议

### 1. 分页大小选择

- 移动端建议：`size = 10`
- 平板端建议：`size = 20`
- 避免设置过大导致加载缓慢

### 2. 文件预览优化

- 小文件（<1MB）：直接下载预览
- 大文件：提供流式预览或分片下载
- PDF文件：使用专业PDF查看器
- 图片：使用缩略图加快加载

### 3. 缓存策略

- 资源列表缓存：缓存第一页数据（5分钟有效期）
- 文件缓存：下载后的文件保存到本地
- 离线模式：支持查看已缓存的资源和文件

### 4. 网络优化

- 使用连接池复用HTTP连接
- 大文件下载支持断点续传
- 图片懒加载，滚动到可见区域再加载

---

## 安全建议

1. **Token安全**: 使用`flutter_secure_storage`安全存储JWT令牌
2. **HTTPS**: 生产环境必须使用HTTPS协议传输
3. **文件验证**: 下载后验证文件完整性（MD5/SHA256）
4. **权限控制**: 确保只能访问所属医院的资源
5. **防盗链**: 文件URL可以添加时效性token防止盗链

---

## 更新日志

| 版本 | 日期 | 说明 |
|------|------|------|
| 1.0.0 | 2025-10-18 | 初始版本，提供学习资源列表和详情API |

---

**文档维护**: 后端开发团队  
**最后更新**: 2025-10-18  
**API版本**: v1.0.0  
**文档版本**: 1.0.0

