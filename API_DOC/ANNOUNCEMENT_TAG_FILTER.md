# 通知公告标签筛选功能说明

## 功能概述

为通知公告列表API增加标签筛选功能，支持通过 `tag_id` 参数过滤用户帖子。

## 改造日期

2025-10-21

## 改造背景

原有的通知公告列表API虽然返回了标签信息（`tagId` 和 `tagName`），但不支持通过标签进行筛选查询。为了提升用户体验，特别是在查看特定标签下的用户帖子时，需要增加按标签筛选的功能。

## 影响的接口

### 1. 首页公告分页查询接口

**接口路径**: `GET /api/v1/announcements/home`

**新增请求参数**:
| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| tag-id | Long | 否 | 标签ID，用于筛选指定标签的用户帖子 |

**使用示例**:
```bash
# 查询所有公告（不过滤标签）
GET /api/v1/announcements/home?page=1&size=10

# 查询指定标签的帖子
GET /api/v1/announcements/home?page=1&size=10&tag-id=3

# 查询用户帖子类型下的指定标签
GET /api/v1/announcements/home?page=1&size=10&notice-type=1&tag-id=3
```

### 2. 公告列表查询接口

**接口路径**: `GET /api/v1/announcements`

**新增请求参数**:
| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| tag-id | Long | 否 | 标签ID，用于筛选指定标签的用户帖子 |

**使用示例**:
```bash
# 查询所有公告（不过滤标签）
GET /api/v1/announcements

# 查询指定标签的帖子
GET /api/v1/announcements?tag-id=3

# 组合多个过滤条件
GET /api/v1/announcements?org-id=10001&status=1&tag-id=3
```

## 技术实现

### 修改的文件列表

1. **DTO层**: `src/main/java/com/example/app/dto/HomeAnnouncementRequest.java`
   - 新增 `tagId` 字段
   - 新增对应的 getter/setter 方法

2. **Controller层**: `src/main/java/com/example/app/controller/AnnouncementController.java`
   - `/home` 接口：更新注释说明支持标签筛选
   - `/list` 接口：新增 `tag-id` 请求参数

3. **Service层**: `src/main/java/com/example/app/service/AnnouncementService.java`
   - `getHomePage()` 方法：传递 `tagId` 到 Mapper 层
   - `list()` 方法：新增 `tagId` 参数并传递到 Mapper 层

4. **Mapper层**: `src/main/java/com/example/app/mapper/AnnouncementMapper.java`
   - `findList()` 方法：新增 `tagId` 参数
   - `findHomePageList()` 方法：新增 `tagId` 参数
   - `countHomePageList()` 方法：新增 `tagId` 参数

5. **XML映射**: `src/main/resources/mapper/AnnouncementMapper.xml`
   - `findList` SQL：添加标签ID过滤条件
   - `findHomePageList` SQL：添加标签ID过滤条件
   - `countHomePageList` SQL：添加标签ID过滤条件

### 核心代码示例

#### DTO 层新增字段
```java
/** 标签ID过滤，可选（仅对用户帖子有效） */
private Long tagId;

public Long getTagId() {
    return tagId;
}

public void setTagId(Long tagId) {
    this.tagId = tagId;
}
```

#### SQL 过滤条件
```xml
<!-- 标签ID过滤（仅对用户帖子有效） -->
<if test="tagId != null">AND t_notice.tag_id = #{tagId}</if>
```

## 使用场景

### 场景1：查看特定话题的帖子

用户想查看所有"病例讨论"标签的帖子：
```bash
GET /api/v1/announcements/home?notice-type=1&tag-id=1&page=1&size=10
```

### 场景2：首页按标签分类展示

移动端首页可以提供标签快捷筛选按钮，点击后使用标签筛选：
```bash
# 用户点击"经验分享"标签
GET /api/v1/announcements/home?tag-id=2&page=1&size=10
```

### 场景3：组合筛选

结合公告类型和标签进行精确筛选：
```bash
# 只看用户帖子中的"病例讨论"
GET /api/v1/announcements/home?notice-type=1&tag-id=1
```

## 兼容性说明

### 向后兼容

- 新增的 `tag-id` 参数为**可选参数**
- 不传递该参数时，接口行为与之前完全一致
- 现有的客户端代码无需修改即可继续使用

### 数据过滤逻辑

1. **不传递 `tag-id`**: 返回所有公告（根据其他筛选条件）
2. **传递 `tag-id`**: 只返回 `t_notice.tag_id = 指定值` 的记录
3. **标签筛选对所有类型生效**: 虽然标签主要用于用户帖子（`notice_type=1`），但过滤条件对所有类型都有效

## 注意事项

### 1. 标签仅用于用户帖子

- 官方公告（`notice_type=0`）通常不使用标签（`tag_id` 为 `null`）
- 建议前端在筛选官方公告时不显示标签筛选选项
- 如果对官方公告使用标签筛选，会返回空结果（因为官方公告的 `tag_id` 为 `null`）

### 2. 标签数据来源

- 标签数据存储在 `t_notice_tag` 表
- 公告表（`t_notice`）中的 `tag_id` 和 `tag_name` 是快照数据
- 筛选时使用 `tag_id` 字段，确保即使标签被删除，历史数据仍可筛选

### 3. 性能考虑

- 建议在 `t_notice.tag_id` 字段上建立索引以提升查询性能
- 标签筛选条件会直接作用于 SQL WHERE 子句，不影响性能

### 4. 权限控制

- 标签筛选不影响现有的权限控制逻辑
- 官方公告仍然只能查看当前用户组织的
- 用户帖子仍然对所有用户可见

## 测试建议

### 功能测试

1. **不传递标签参数**
   - 验证返回所有公告（与之前行为一致）

2. **传递有效的标签ID**
   - 验证只返回指定标签的公告
   - 验证分页功能正常
   - 验证总数计算正确

3. **传递不存在的标签ID**
   - 验证返回空列表
   - 验证不报错

4. **组合筛选**
   - 同时传递 `notice-type=1` 和 `tag-id`
   - 验证只返回用户帖子中的指定标签

### 性能测试

1. 测试标签筛选的查询速度
2. 验证索引是否生效
3. 大数据量下的分页性能

### 接口测试示例

```bash
# 1. 登录获取 token
TOKEN=$(curl -X POST http://localhost:8090/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"123456"}' \
  | jq -r '.data.accessToken')

# 2. 测试不带标签筛选
curl "http://localhost:8090/api/v1/announcements/home?page=1&size=10" \
  -H "Authorization: Bearer $TOKEN"

# 3. 测试带标签筛选
curl "http://localhost:8090/api/v1/announcements/home?page=1&size=10&tag-id=1" \
  -H "Authorization: Bearer $TOKEN"

# 4. 测试组合筛选（用户帖子 + 标签）
curl "http://localhost:8090/api/v1/announcements/home?page=1&size=10&notice-type=1&tag-id=2" \
  -H "Authorization: Bearer $TOKEN"

# 5. 测试不存在的标签
curl "http://localhost:8090/api/v1/announcements/home?page=1&size=10&tag-id=99999" \
  -H "Authorization: Bearer $TOKEN"
```

## 前端集成建议

### Flutter 示例

```dart
// 1. 定义标签筛选参数
class AnnouncementListParams {
  final int page;
  final int size;
  final int? noticeType;
  final int? tagId;  // 新增标签筛选
  
  AnnouncementListParams({
    this.page = 1,
    this.size = 10,
    this.noticeType,
    this.tagId,
  });
  
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'page': page.toString(),
      'size': size.toString(),
    };
    if (noticeType != null) {
      params['notice-type'] = noticeType.toString();
    }
    if (tagId != null) {
      params['tag-id'] = tagId.toString();
    }
    return params;
  }
}

// 2. 标签选择器 Widget
class TagSelector extends StatelessWidget {
  final List<NoticeTag> tags;
  final int? selectedTagId;
  final Function(int?) onTagSelected;
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // "全部"按钮
          FilterChip(
            label: Text('全部'),
            selected: selectedTagId == null,
            onSelected: (_) => onTagSelected(null),
          ),
          SizedBox(width: 8),
          // 标签按钮
          ...tags.map((tag) => Padding(
            padding: EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(tag.tagName),
              selected: selectedTagId == tag.id,
              onSelected: (_) => onTagSelected(tag.id),
            ),
          )),
        ],
      ),
    );
  }
}

// 3. 使用示例
class AnnouncementListPage extends StatefulWidget {
  @override
  _AnnouncementListPageState createState() => _AnnouncementListPageState();
}

class _AnnouncementListPageState extends State<AnnouncementListPage> {
  int? _selectedTagId;
  
  void _onTagSelected(int? tagId) {
    setState(() {
      _selectedTagId = tagId;
    });
    _refreshList();
  }
  
  void _refreshList() {
    final params = AnnouncementListParams(
      noticeType: 1,  // 用户帖子
      tagId: _selectedTagId,
    );
    // 调用API刷新列表
    announcementService.getHomePage(params);
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 标签筛选器
        TagSelector(
          tags: _tags,
          selectedTagId: _selectedTagId,
          onTagSelected: _onTagSelected,
        ),
        // 公告列表
        Expanded(
          child: AnnouncementList(...),
        ),
      ],
    );
  }
}
```

## 数据库索引建议

为了优化标签筛选的查询性能，建议添加以下索引：

```sql
-- 为 tag_id 字段添加索引
CREATE INDEX idx_notice_tag_id ON t_notice(tag_id);

-- 如果需要组合查询优化，可以添加组合索引
CREATE INDEX idx_notice_type_tag ON t_notice(notice_type, tag_id, status, is_deleted);
```

## 总结

此次改造为通知公告列表API增加了标签筛选功能，主要特点：

✅ **向后兼容**: 新参数为可选，不影响现有功能  
✅ **易于使用**: 只需传递 `tag-id` 参数即可  
✅ **性能优化**: 使用索引确保查询效率  
✅ **灵活组合**: 可与现有筛选条件组合使用  
✅ **代码规范**: 遵循项目架构和编码规范  

该功能特别适用于：
- 移动端首页按标签分类展示帖子
- 用户查看特定话题的讨论
- 社区功能的标签导航

## 相关文档

- [通知公告标签字段功能说明](ANNOUNCEMENT_TAG_FEATURE.md)
- [用户帖子功能说明](USER_POST_FEATURE.md)
- [API文档](../API-Documentation.md)

