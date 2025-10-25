# 通知公告标签列表API说明

## 功能概述

提供获取通知公告标签列表的API接口，用于APP首页展示所有可用的标签并提供选择。

## 创建日期

2025-10-25

## 接口详情

### 获取可用标签列表

**接口路径**: `GET /api/v1/announcements/tags`

**接口说明**: 获取当前用户可用的帖子标签列表，用于标签筛选器、发帖时的标签选择等场景。

**请求方式**: GET

**是否需要认证**: 是（需要JWT Token）

**请求参数**: 无

**请求示例**:
```bash
# 获取标签列表
curl -X GET "http://localhost:8090/api/v1/announcements/tags" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**响应格式**:
```json
{
  "code": "SUCCESS",
  "message": "操作成功",
  "data": [
    {
      "id": 1,
      "tagCode": "case_discussion",
      "tagName": "病例讨论",
      "description": "分享和讨论临床病例",
      "orderNo": 1
    },
    {
      "id": 2,
      "tagCode": "experience_share",
      "tagName": "经验分享",
      "description": "分享临床经验和心得",
      "orderNo": 2
    },
    {
      "id": 3,
      "tagCode": "question_answer",
      "tagName": "问题解答",
      "description": "提问和解答临床问题",
      "orderNo": 3
    }
  ]
}
```

**响应字段说明**:

| 字段 | 类型 | 说明 |
|------|------|------|
| id | Long | 标签ID |
| tagCode | String | 标签编码（唯一标识） |
| tagName | String | 标签名称（显示用） |
| description | String | 标签说明 |
| orderNo | Integer | 排序序号 |

**数据说明**:
- 返回的标签按 `orderNo` 升序、`id` 升序排列
- 只返回启用状态（status=1）且未删除的标签
- 当前只返回组织级通用标签（hospital_id为null的标签）
- 不同组织会看到不同的标签列表

**错误响应示例**:

1. 未登录或Token无效
```json
{
  "code": "UNAUTHORIZED",
  "message": "请先登录",
  "data": null
}
```

2. 用户未登录（Token过期）
```json
{
  "code": "UNAUTHORIZED",
  "message": "认证失败",
  "data": null
}
```

## 使用场景

### 场景1：首页标签筛选器

移动端首页展示标签选择器，用户可以选择标签来筛选帖子：

```dart
// 1. 获取标签列表
final tags = await announcementApi.getTags();

// 2. 显示标签选择器
TagSelector(
  tags: tags,
  onTagSelected: (tagId) {
    // 3. 使用选中的标签筛选帖子
    loadAnnouncements(tagId: tagId);
  },
)
```

### 场景2：发帖时选择标签

用户发表新帖子时，选择合适的标签：

```dart
// 1. 获取标签列表
final tags = await announcementApi.getTags();

// 2. 显示标签选择对话框
showDialog(
  context: context,
  builder: (context) => TagPickerDialog(
    tags: tags,
    onSelected: (tagId) {
      // 3. 设置帖子的标签
      postForm.tagId = tagId;
    },
  ),
)
```

### 场景3：标签导航

在社区功能中，按标签分类展示内容：

```dart
// 1. 获取标签列表
final tags = await announcementApi.getTags();

// 2. 创建标签导航页面
TabBar(
  tabs: tags.map((tag) => Tab(text: tag.tagName)).toList(),
)

TabBarView(
  children: tags.map((tag) => 
    AnnouncementListView(tagId: tag.id)
  ).toList(),
)
```

## 配合使用的接口

此API通常与以下接口配合使用：

### 1. 首页公告分页查询（带标签筛选）

**接口**: `GET /api/v1/announcements/home`

**使用示例**:
```bash
# 先获取标签列表
GET /api/v1/announcements/tags

# 然后使用标签ID筛选帖子
GET /api/v1/announcements/home?page=1&size=10&tag-id=1
```

### 2. 公告列表查询（带标签筛选）

**接口**: `GET /api/v1/announcements`

**使用示例**:
```bash
# 获取标签列表后筛选
GET /api/v1/announcements?tag-id=2
```

详见：[通知公告标签筛选功能说明](ANNOUNCEMENT_TAG_FILTER.md)

## 技术实现

### 涉及的文件

1. **VO层**: `src/main/java/com/example/app/vo/NoticeTagVO.java`
   - 标签视图对象，只包含必要的展示字段

2. **Service层**: `src/main/java/com/example/app/service/NoticeTagService.java`
   - 标签业务逻辑服务
   - 查询可用标签并转换为VO对象

3. **Controller层**: `src/main/java/com/example/app/controller/AnnouncementController.java`
   - 新增 `/tags` 接口

4. **Mapper层**: `src/main/java/com/example/app/mapper/NoticeTagMapper.java`
   - 已有的 `findAvailableTags` 方法

5. **XML映射**: `src/main/resources/mapper/NoticeTagMapper.xml`
   - 已有的标签查询SQL

### 核心代码

#### Controller层

```java
/**
 * 获取可用标签列表接口
 */
@GetMapping("/tags")
public ApiResponse<List<NoticeTagVO>> getTags() {
    return ApiResponse.success(noticeTagService.getAvailableTags());
}
```

#### Service层

```java
/**
 * 获取当前用户可用的标签列表
 */
public List<NoticeTagVO> getAvailableTags() {
    // 获取当前用户的组织ID
    Long orgId = SecurityUtils.getCurrentOrgId();
    
    // 查询可用标签列表（传递null作为hospitalId，只返回组织级通用标签）
    List<NoticeTag> tags = noticeTagMapper.findAvailableTags(orgId, null);
    
    // 转换为VO对象
    return tags.stream()
            .map(this::convertToVO)
            .collect(Collectors.toList());
}
```

#### SQL查询

```xml
<select id="findAvailableTags" resultMap="NoticeTagResultMap">
    SELECT <include refid="BaseColumns" />
    FROM t_notice_tag
    WHERE org_id = #{orgId}
      AND is_deleted = 0
      AND status = 1
      AND (
        hospital_id IS NULL  -- 组织级通用标签
        OR hospital_id = #{hospitalId}  -- 指定医院的标签
      )
    ORDER BY order_no ASC, id ASC
</select>
```

## 数据库表结构

### t_notice_tag（标签表）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT | 标签主键ID |
| org_id | BIGINT | 组织ID（多租户隔离） |
| hospital_id | BIGINT | 医院ID（NULL表示组织级通用标签） |
| scope_hosp_id | BIGINT | 作用域医院ID（自动生成） |
| tag_code | VARCHAR | 标签编码（唯一标识） |
| tag_name | VARCHAR | 标签名称 |
| description | VARCHAR | 标签说明 |
| order_no | INT | 排序序号 |
| status | TINYINT | 状态（1-启用，0-停用） |
| is_deleted | TINYINT | 逻辑删除标记 |
| created_at | DATETIME | 创建时间 |
| updated_at | DATETIME | 更新时间 |

### 索引建议

```sql
-- 主键索引（已有）
PRIMARY KEY (id)

-- 组织ID索引（建议添加，提升查询性能）
CREATE INDEX idx_org_status ON t_notice_tag(org_id, status, is_deleted);

-- 唯一约束：组织内标签编码唯一
CREATE UNIQUE INDEX uk_org_code ON t_notice_tag(org_id, tag_code, is_deleted);
```

## 前端集成示例

### Flutter代码示例

```dart
// 1. API Service 层
class AnnouncementApi {
  final Dio dio;
  
  AnnouncementApi(this.dio);
  
  /// 获取可用标签列表
  Future<List<NoticeTag>> getTags() async {
    final response = await dio.get('/api/v1/announcements/tags');
    final List<dynamic> data = response.data['data'];
    return data.map((json) => NoticeTag.fromJson(json)).toList();
  }
}

// 2. 数据模型
class NoticeTag {
  final int id;
  final String tagCode;
  final String tagName;
  final String description;
  final int orderNo;
  
  NoticeTag({
    required this.id,
    required this.tagCode,
    required this.tagName,
    required this.description,
    required this.orderNo,
  });
  
  factory NoticeTag.fromJson(Map<String, dynamic> json) {
    return NoticeTag(
      id: json['id'],
      tagCode: json['tagCode'],
      tagName: json['tagName'],
      description: json['description'] ?? '',
      orderNo: json['orderNo'],
    );
  }
}

// 3. 标签选择器 Widget
class TagSelector extends StatelessWidget {
  final List<NoticeTag> tags;
  final int? selectedTagId;
  final Function(int?) onTagSelected;
  
  const TagSelector({
    Key? key,
    required this.tags,
    this.selectedTagId,
    required this.onTagSelected,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // "全部"按钮
          _buildTagChip(
            label: '全部',
            isSelected: selectedTagId == null,
            onTap: () => onTagSelected(null),
          ),
          SizedBox(width: 8),
          
          // 标签按钮
          ...tags.map((tag) => Padding(
            padding: EdgeInsets.only(right: 8),
            child: _buildTagChip(
              label: tag.tagName,
              isSelected: selectedTagId == tag.id,
              onTap: () => onTagSelected(tag.id),
            ),
          )),
        ],
      ),
    );
  }
  
  Widget _buildTagChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// 4. 使用示例
class AnnouncementListPage extends StatefulWidget {
  @override
  _AnnouncementListPageState createState() => _AnnouncementListPageState();
}

class _AnnouncementListPageState extends State<AnnouncementListPage> {
  List<NoticeTag> _tags = [];
  int? _selectedTagId;
  bool _isLoadingTags = true;
  
  @override
  void initState() {
    super.initState();
    _loadTags();
  }
  
  /// 加载标签列表
  Future<void> _loadTags() async {
    try {
      final tags = await announcementApi.getTags();
      setState(() {
        _tags = tags;
        _isLoadingTags = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingTags = false;
      });
      // 显示错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载标签失败: $e')),
      );
    }
  }
  
  /// 标签选择事件处理
  void _onTagSelected(int? tagId) {
    setState(() {
      _selectedTagId = tagId;
    });
    _refreshAnnouncementList();
  }
  
  /// 刷新公告列表
  void _refreshAnnouncementList() {
    // 使用选中的标签筛选公告
    // 调用公告列表API，传递 tagId 参数
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('通知公告')),
      body: Column(
        children: [
          // 标签筛选器
          if (_isLoadingTags)
            Center(child: CircularProgressIndicator())
          else
            TagSelector(
              tags: _tags,
              selectedTagId: _selectedTagId,
              onTagSelected: _onTagSelected,
            ),
          
          // 公告列表
          Expanded(
            child: AnnouncementList(
              tagId: _selectedTagId,
            ),
          ),
        ],
      ),
    );
  }
}
```

## 性能优化建议

### 1. 缓存标签列表

标签数据相对稳定，建议在客户端进行缓存：

```dart
class TagCache {
  static List<NoticeTag>? _cachedTags;
  static DateTime? _cacheTime;
  static const _cacheDuration = Duration(hours: 1);
  
  static Future<List<NoticeTag>> getTags(AnnouncementApi api) async {
    // 检查缓存是否有效
    if (_cachedTags != null && 
        _cacheTime != null && 
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cachedTags!;
    }
    
    // 从服务器获取
    final tags = await api.getTags();
    _cachedTags = tags;
    _cacheTime = DateTime.now();
    
    return tags;
  }
  
  static void clearCache() {
    _cachedTags = null;
    _cacheTime = null;
  }
}
```

### 2. 数据库索引优化

确保数据库表有适当的索引，提升查询性能：

```sql
-- 组织ID和状态组合索引
CREATE INDEX idx_org_status ON t_notice_tag(org_id, status, is_deleted);
```

### 3. 响应数据压缩

对于标签列表较长的情况，建议启用HTTP压缩（gzip）减少传输数据量。

## 测试建议

### 1. 功能测试

```bash
# 测试1：正常获取标签列表
curl -X GET "http://localhost:8090/api/v1/announcements/tags" \
  -H "Authorization: Bearer VALID_TOKEN"

# 测试2：未登录访问（应该返回401）
curl -X GET "http://localhost:8090/api/v1/announcements/tags"

# 测试3：使用过期Token（应该返回401）
curl -X GET "http://localhost:8090/api/v1/announcements/tags" \
  -H "Authorization: Bearer EXPIRED_TOKEN"
```

### 2. 数据验证

- 验证返回的标签按 `orderNo` 排序
- 验证只返回启用状态的标签（status=1）
- 验证只返回未删除的标签（is_deleted=0）
- 验证不同组织看到不同的标签列表

### 3. 性能测试

- 测试并发请求的响应时间
- 验证数据库索引是否生效
- 测试大量标签（100+）时的性能

## 注意事项

### 1. 权限控制

- 接口需要JWT认证，未登录用户无法访问
- 用户只能看到自己组织的标签
- 通过多租户隔离（org_id）确保数据安全

### 2. 数据范围

- 当前只返回组织级通用标签（hospital_id为null）
- 如果后续需要支持医院级标签，需要修改Service层代码，从数据库查询用户的医院ID

### 3. 缓存策略

- 建议客户端缓存标签列表，减少网络请求
- 缓存有效期建议设置为1小时
- 当用户切换组织时，需要清空缓存

### 4. 空列表处理

- 如果组织没有配置任何标签，返回空数组
- 前端需要妥善处理空列表的情况，不影响用户体验

## 版本历史

### v1.0.0 (2025-10-25)
- ✨ 新增标签列表API接口
- 📝 创建API文档
- ✅ 实现VO、Service、Controller层代码

## 相关文档

- [通知公告标签筛选功能说明](ANNOUNCEMENT_TAG_FILTER.md)
- [通知公告标签字段功能说明](ANNOUNCEMENT_TAG_FEATURE.md)
- [用户帖子功能说明](USER_POST_FEATURE.md)
- [API文档](../API-Documentation.md)

