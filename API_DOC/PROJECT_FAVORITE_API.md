# 项目收藏 API 文档

## 基础信息

- **服务器地址**: `http://localhost:8090`
- **API版本**: v1
- **内容类型**: `application/json`
- **编码格式**: `UTF-8`
- **认证方式**: Bearer Token（JWT）

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

## 分页响应格式

分页接口返回的 `data` 字段格式：

```json
{
  "data": [/* 数据列表 */],
  "page": 1,              // 当前页码
  "size": 20,             // 每页大小
  "total": 100,           // 总记录数
  "pages": 5,             // 总页数
  "hasNext": true,        // 是否有下一页
  "hasPrev": false        // 是否有上一页
}
```

## 项目收藏接口

### 1. 收藏项目

**接口描述**: 用户将指定项目添加到收藏列表，可选择性指定收藏夹分类和添加备注

- **URL**: `/api/v1/favorites`
- **方法**: `POST`
- **认证**: 需要认证（Bearer Token）

#### 请求参数

请求体（JSON格式）：

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| projectId | Long | 是 | 项目ID |
| folderId | Long | 否 | 收藏夹ID（不传则放入默认收藏夹） |
| note | String | 否 | 用户备注（最多255字符） |

#### 请求头

```
Authorization: Bearer {accessToken}
Content-Type: application/json
```

#### 请求示例

```json
{
  "projectId": 12,
  "folderId": null,
  "note": "重点关注的项目"
}
```

#### 响应示例

**成功响应 (200)**:
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "收藏成功",
  "data": null
}
```

**失败响应 - 已收藏 (200)**:
```json
{
  "success": false,
  "code": "ALREADY_FAVORITED",
  "message": "该项目已收藏",
  "data": null
}
```

**失败响应 - 项目ID无效 (200)**:
```json
{
  "success": false,
  "code": "INVALID_PROJECT_ID",
  "message": "项目ID不能为空",
  "data": null
}
```

**失败响应 - 未登录 (200)**:
```json
{
  "success": false,
  "code": "UNAUTHORIZED",
  "message": "请先登录",
  "data": null
}
```

#### Flutter 调用示例

```dart
Future<void> addFavorite(int projectId, {String? note}) async {
  final response = await http.post(
    Uri.parse('http://localhost:8090/api/v1/favorites'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken'
    },
    body: jsonEncode({
      'projectId': projectId,
      'note': note,
    }),
  );

  final result = jsonDecode(response.body);
  if (result['success']) {
    print('收藏成功');
    // 更新UI，显示已收藏状态
  } else {
    print('收藏失败: ${result['message']}');
  }
}
```

---

### 2. 取消收藏项目

**接口描述**: 用户将指定项目从收藏列表中移除

- **URL**: `/api/v1/favorites/{projectId}`
- **方法**: `DELETE`
- **认证**: 需要认证（Bearer Token）

#### 请求参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| projectId | Long | 是 | 项目ID（路径参数） |

#### 请求头

```
Authorization: Bearer {accessToken}
```

#### 响应示例

**成功响应 (200)**:
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "取消收藏成功",
  "data": null
}
```

**失败响应 - 未收藏 (200)**:
```json
{
  "success": false,
  "code": "NOT_FAVORITED",
  "message": "该项目未收藏",
  "data": null
}
```

**失败响应 - 项目ID无效 (200)**:
```json
{
  "success": false,
  "code": "INVALID_PROJECT_ID",
  "message": "项目ID不能为空",
  "data": null
}
```

**失败响应 - 未登录 (200)**:
```json
{
  "success": false,
  "code": "UNAUTHORIZED",
  "message": "请先登录",
  "data": null
}
```

#### Flutter 调用示例

```dart
Future<void> removeFavorite(int projectId) async {
  final response = await http.delete(
    Uri.parse('http://localhost:8090/api/v1/favorites/$projectId'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken'
    },
  );

  final result = jsonDecode(response.body);
  if (result['success']) {
    print('取消收藏成功');
    // 更新UI，显示未收藏状态
  } else {
    print('取消收藏失败: ${result['message']}');
  }
}
```

---

### 3. 获取我的收藏项目列表

**接口描述**: 查询当前登录用户收藏的项目列表，支持分页。按置顶状态和收藏时间排序，置顶的项目在前，新收藏的在前

- **URL**: `/api/v1/favorites`
- **方法**: `GET`
- **认证**: 需要认证（Bearer Token）

#### 请求参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| page | Integer | 否 | 1 | 页码，从1开始 |
| size | Integer | 否 | 20 | 每页大小，最大100 |

#### 请求头

```
Authorization: Bearer {accessToken}
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
        "favoriteId": 1,
        "projectId": 12,
        "projectName": "非小细胞肺癌一线治疗研究",
        "shortTitle": "肺癌研究",
        "sponsorName": "XX制药",
        "progressName": "进行中",
        "signedCount": 15,
        "totalSignCount": 50,
        "customTags": ["肺癌", "一线治疗"],
        "note": "重点关注的项目",
        "pinned": 0,
        "createdAt": "2024-03-20T10:30:00"
      },
      {
        "favoriteId": 2,
        "projectId": 18,
        "projectName": "乳腺癌新辅助治疗临床试验",
        "shortTitle": "乳腺癌试验",
        "sponsorName": "YY生物",
        "progressName": "待开始",
        "signedCount": 0,
        "totalSignCount": 30,
        "customTags": ["乳腺癌", "新辅助"],
        "note": null,
        "pinned": 0,
        "createdAt": "2024-03-18T14:15:00"
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

**失败响应 - 未登录 (200)**:
```json
{
  "success": false,
  "code": "UNAUTHORIZED",
  "message": "请先登录",
  "data": null
}
```

#### 响应字段说明

| 字段名 | 类型 | 说明 |
|--------|------|------|
| favoriteId | Long | 收藏记录ID |
| projectId | Long | 项目ID |
| projectName | String | 项目名称 |
| shortTitle | String | 项目简称 |
| sponsorName | String | 申办方名称 |
| progressName | String | 项目进度名称（如：进行中、待开始、已完成） |
| signedCount | Integer | 已签约例数 |
| totalSignCount | Integer | 总签约例数 |
| customTags | Array[String] | 自定义标签列表 |
| note | String | 用户备注（可能为null） |
| pinned | Integer | 是否置顶：0否，1是 |
| createdAt | DateTime | 收藏时间 |

#### Flutter 调用示例

```dart
Future<Map<String, dynamic>> getMyFavorites({
  int page = 1, 
  int size = 20
}) async {
  final response = await http.get(
    Uri.parse('http://localhost:8090/api/v1/favorites?page=$page&size=$size'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken'
    },
  );

  final result = jsonDecode(response.body);
  if (result['success']) {
    final data = result['data'];
    final favorites = data['data'] as List;
    final total = data['total'];
    final hasNext = data['hasNext'];
    
    print('收藏项目总数: $total');
    for (var fav in favorites) {
      print('${fav['projectName']} - ${fav['progressName']}');
    }
    
    return data;
  } else {
    throw Exception(result['message']);
  }
}
```

---

### 4. 检查项目收藏状态

**接口描述**: 查询指定项目是否已被当前用户收藏，用于在项目详情页显示收藏按钮状态

- **URL**: `/api/v1/favorites/check/{projectId}`
- **方法**: `GET`
- **认证**: 需要认证（Bearer Token）

#### 请求参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| projectId | Long | 是 | 项目ID（路径参数） |

#### 请求头

```
Authorization: Bearer {accessToken}
```

#### 响应示例

**成功响应 - 已收藏 (200)**:
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": true
}
```

**成功响应 - 未收藏 (200)**:
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": false
}
```

**失败响应 - 未登录 (200)**:
```json
{
  "success": false,
  "code": "UNAUTHORIZED",
  "message": "请先登录",
  "data": null
}
```

#### Flutter 调用示例

```dart
Future<bool> checkFavoriteStatus(int projectId) async {
  final response = await http.get(
    Uri.parse('http://localhost:8090/api/v1/favorites/check/$projectId'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken'
    },
  );

  final result = jsonDecode(response.body);
  if (result['success']) {
    return result['data'] as bool;
  } else {
    throw Exception(result['message']);
  }
}

// 使用示例：在项目详情页初始化收藏按钮状态
void initProjectDetail(int projectId) async {
  final isFavorited = await checkFavoriteStatus(projectId);
  setState(() {
    _isFavorited = isFavorited;
    // 更新UI，显示对应的收藏图标
  });
}
```

---

## 使用场景说明

### 场景1：项目详情页收藏功能

在项目详情页面显示收藏按钮，支持收藏和取消收藏：

```dart
class ProjectDetailPage extends StatefulWidget {
  final int projectId;
  
  @override
  _ProjectDetailPageState createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  bool _isFavorited = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  // 检查收藏状态
  Future<void> _checkFavoriteStatus() async {
    try {
      final isFavorited = await checkFavoriteStatus(widget.projectId);
      setState(() {
        _isFavorited = isFavorited;
      });
    } catch (e) {
      print('检查收藏状态失败: $e');
    }
  }

  // 切换收藏状态
  Future<void> _toggleFavorite() async {
    setState(() {
      _loading = true;
    });

    try {
      if (_isFavorited) {
        // 取消收藏
        await removeFavorite(widget.projectId);
        setState(() {
          _isFavorited = false;
        });
        showSnackBar('取消收藏成功');
      } else {
        // 收藏
        await addFavorite(widget.projectId);
        setState(() {
          _isFavorited = true;
        });
        showSnackBar('收藏成功');
      }
    } catch (e) {
      showSnackBar('操作失败: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('项目详情'),
        actions: [
          // 收藏按钮
          IconButton(
            icon: Icon(
              _isFavorited ? Icons.favorite : Icons.favorite_border,
              color: _isFavorited ? Colors.red : Colors.grey,
            ),
            onPressed: _loading ? null : _toggleFavorite,
          ),
        ],
      ),
      body: // 项目详情内容
    );
  }
}
```

### 场景2：我的收藏页面

创建独立的"我的收藏"页面，展示用户收藏的所有项目：

```dart
class MyFavoritesPage extends StatefulWidget {
  @override
  _MyFavoritesPageState createState() => _MyFavoritesPageState();
}

class _MyFavoritesPageState extends State<MyFavoritesPage> {
  List<dynamic> _favorites = [];
  int _currentPage = 1;
  bool _loading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  // 加载收藏列表
  Future<void> _loadFavorites({bool loadMore = false}) async {
    if (_loading) return;

    setState(() {
      _loading = true;
    });

    try {
      final page = loadMore ? _currentPage + 1 : 1;
      final data = await getMyFavorites(page: page, size: 20);
      
      setState(() {
        if (loadMore) {
          _favorites.addAll(data['data']);
          _currentPage++;
        } else {
          _favorites = data['data'];
          _currentPage = 1;
        }
        _hasMore = data['hasNext'];
      });
    } catch (e) {
      showSnackBar('加载失败: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  // 取消收藏后刷新列表
  Future<void> _removeFavorite(int projectId) async {
    try {
      await removeFavorite(projectId);
      showSnackBar('取消收藏成功');
      // 刷新列表
      _loadFavorites();
    } catch (e) {
      showSnackBar('操作失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('我的收藏'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadFavorites(),
        child: ListView.builder(
          itemCount: _favorites.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            // 加载更多指示器
            if (index == _favorites.length) {
              if (_hasMore && !_loading) {
                _loadFavorites(loadMore: true);
              }
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final favorite = _favorites[index];
            return _buildFavoriteItem(favorite);
          },
        ),
      ),
    );
  }

  Widget _buildFavoriteItem(dynamic favorite) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(favorite['projectName']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('申办方: ${favorite['sponsorName']}'),
            Text('进度: ${favorite['progressName']}'),
            if (favorite['note'] != null)
              Text('备注: ${favorite['note']}',
                style: TextStyle(color: Colors.blue)),
            // 显示标签
            if (favorite['customTags'] != null && 
                favorite['customTags'].isNotEmpty)
              Wrap(
                spacing: 4,
                children: (favorite['customTags'] as List)
                    .map((tag) => Chip(
                      label: Text(tag, 
                        style: TextStyle(fontSize: 12)),
                      padding: EdgeInsets.all(2),
                    ))
                    .toList(),
              ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.favorite, color: Colors.red),
          onPressed: () => _removeFavorite(favorite['projectId']),
        ),
        onTap: () {
          // 跳转到项目详情
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => 
                ProjectDetailPage(projectId: favorite['projectId']),
            ),
          );
        },
      ),
    );
  }
}
```

### 场景3：项目列表中显示收藏状态

在项目列表页面，为每个项目显示收藏图标：

```dart
// 批量检查多个项目的收藏状态（建议后端提供批量查询接口以提高性能）
Future<Map<int, bool>> batchCheckFavoriteStatus(List<int> projectIds) async {
  Map<int, bool> statusMap = {};
  
  // 当前方案：逐个检查（可优化为批量查询）
  for (var projectId in projectIds) {
    try {
      final isFavorited = await checkFavoriteStatus(projectId);
      statusMap[projectId] = isFavorited;
    } catch (e) {
      statusMap[projectId] = false;
    }
  }
  
  return statusMap;
}

// 或者更简单的方案：只在我的收藏列表中显示收藏图标
// 项目列表只提供"添加到收藏"功能，不显示实时状态
```

---

## 错误代码说明

| 错误代码 | 说明 | 解决方案 |
|---------|------|----------|
| UNAUTHORIZED | 用户未登录或Token失效 | 重新登录获取新的Token |
| INVALID_PROJECT_ID | 项目ID无效或为空 | 检查传入的项目ID参数 |
| ALREADY_FAVORITED | 项目已被收藏 | 提示用户该项目已在收藏列表中 |
| NOT_FAVORITED | 项目未被收藏 | 用户尝试取消未收藏的项目 |

---

## 注意事项

1. **防止重复收藏**：收藏接口会检查是否已收藏，如果已收藏则返回 `ALREADY_FAVORITED` 错误。

2. **分页限制**：收藏列表每页最多返回100条记录，建议使用默认值20条。

3. **排序规则**：
   - 置顶的项目优先显示（`pinned = 1`）
   - 相同置顶状态的项目按收藏时间倒序（新收藏的在前）

4. **权限隔离**：
   - 所有接口都基于当前登录用户
   - 只能收藏本组织内的项目
   - 只能查看和管理自己的收藏记录

5. **Token认证**：所有接口都需要在请求头中携带有效的 JWT Token。

6. **删除项目的影响**：如果项目被删除（`is_deleted = 1`），该项目不会在收藏列表中显示，但收藏记录仍然保留。

7. **收藏夹功能**：当前版本支持 `folderId` 参数，但暂未提供收藏夹管理接口。后续版本可扩展收藏夹的创建、修改、删除功能。

---

## 完整工作流程示例

### Flutter 完整示例代码

```dart
class FavoriteService {
  final String baseUrl = 'http://localhost:8090/api/v1';
  String? accessToken;

  // 设置Token
  void setToken(String token) {
    accessToken = token;
  }

  // 收藏项目
  Future<void> addFavorite(int projectId, {String? note}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/favorites'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken'
      },
      body: jsonEncode({
        'projectId': projectId,
        'note': note,
      }),
    );

    final result = jsonDecode(response.body);
    if (!result['success']) {
      throw Exception(result['message']);
    }
  }

  // 取消收藏
  Future<void> removeFavorite(int projectId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/favorites/$projectId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken'
      },
    );

    final result = jsonDecode(response.body);
    if (!result['success']) {
      throw Exception(result['message']);
    }
  }

  // 获取收藏列表
  Future<Map<String, dynamic>> getMyFavorites({
    int page = 1, 
    int size = 20
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/favorites?page=$page&size=$size'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken'
      },
    );

    final result = jsonDecode(response.body);
    if (result['success']) {
      return result['data'];
    }
    throw Exception(result['message']);
  }

  // 检查收藏状态
  Future<bool> checkFavoriteStatus(int projectId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/favorites/check/$projectId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken'
      },
    );

    final result = jsonDecode(response.body);
    if (result['success']) {
      return result['data'] as bool;
    }
    throw Exception(result['message']);
  }
}

// 使用示例
void main() async {
  final favoriteService = FavoriteService();
  favoriteService.setToken('your_access_token_here');

  try {
    // 1. 收藏项目
    await favoriteService.addFavorite(12, note: '重点关注');
    print('收藏成功');

    // 2. 检查收藏状态
    final isFavorited = await favoriteService.checkFavoriteStatus(12);
    print('项目12收藏状态: $isFavorited');

    // 3. 获取收藏列表
    final favoritesData = await favoriteService.getMyFavorites(page: 1);
    final favorites = favoritesData['data'] as List;
    print('收藏项目数量: ${favoritesData['total']}');

    // 4. 取消收藏
    await favoriteService.removeFavorite(12);
    print('取消收藏成功');
  } catch (e) {
    print('操作失败: $e');
  }
}
```

---

## 更新日志

- **2025-11-07**: 初始版本，实现四个核心接口
  - 收藏项目
  - 取消收藏项目
  - 获取我的收藏列表（分页）
  - 检查项目收藏状态

---

## 后续扩展功能（待实现）

1. **收藏夹管理**：
   - 创建收藏夹
   - 修改收藏夹名称
   - 删除收藏夹
   - 移动收藏项目到不同收藏夹

2. **批量操作**：
   - 批量收藏项目
   - 批量取消收藏
   - 批量检查收藏状态

3. **收藏项目置顶**：
   - 将收藏项目置顶
   - 取消置顶

4. **收藏项目排序**：
   - 手动调整收藏项目的显示顺序

5. **收藏统计**：
   - 查看项目被收藏的总次数（热度）
   - 统计用户的收藏习惯

