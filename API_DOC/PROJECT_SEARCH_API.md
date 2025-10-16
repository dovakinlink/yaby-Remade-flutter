# 项目全局搜索 API 文档

## 功能概述

项目全局搜索功能允许用户通过关键词搜索项目，支持搜索项目名称、自定义标签、CRC人员姓名、项目成员等信息。

## 技术特点

- ✅ **全文索引搜索**：使用 MySQL FULLTEXT 索引，支持中文分词（ngram）
- ✅ **模糊匹配兜底**：结合 LIKE 模糊匹配，确保搜索覆盖率
- ✅ **按相关性排序**：全文搜索得分高的项目优先展示
- ✅ **分页支持**：支持分页查询，提升性能
- ✅ **多租户隔离**：自动根据用户组织ID过滤数据
- ✅ **JWT 认证**：需要登录后才能访问

## API 接口

### 搜索项目

**接口地址**
```
GET /api/v1/projects/search
```

**请求参数**

| 参数名  | 类型    | 必填 | 默认值 | 说明                        |
|---------|---------|------|--------|----------------------------|
| keyword | String  | 是   | -      | 搜索关键词（至少2个字符）    |
| page    | Integer | 否   | 1      | 页码，从1开始               |
| size    | Integer | 否   | 10     | 每页大小，最大100           |

**请求头**
```
Authorization: Bearer <JWT_TOKEN>
```

**请求示例**
```bash
curl -X GET "http://localhost:8080/api/v1/projects/search?keyword=肺癌&page=1&size=10" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9..."
```

**响应示例**

成功响应（200 OK）：
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": {
    "data": [
      {
        "id": 12,
        "projName": "非小细胞肺癌一线治疗研究",
        "shortTitle": "肺癌研究",
        "sponsorName": "XX制药有限公司",
        "progressName": "进行中",
        "signedCount": 15,
        "totalSignCount": 50,
        "customTags": ["肺癌", "一线治疗", "靶向药物"],
        "createdAt": "2024-01-15T10:30:00",
        "updatedAt": "2024-03-20T14:20:00"
      },
      {
        "id": 23,
        "projName": "肺癌免疫治疗临床研究",
        "shortTitle": null,
        "sponsorName": "YY生物科技",
        "progressName": "待开始",
        "signedCount": 0,
        "totalSignCount": 30,
        "customTags": ["肺癌", "免疫治疗"],
        "createdAt": "2024-02-01T09:15:00",
        "updatedAt": "2024-02-10T16:45:00"
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

关键词为空时（400 Bad Request）：
```json
{
  "success": false,
  "code": "VALIDATION_ERROR",
  "message": "搜索关键词不能为空",
  "data": null
}
```

未登录（401 Unauthorized）：
```json
{
  "success": false,
  "code": "UNAUTHORIZED",
  "message": "用户未登录",
  "data": null
}
```

## 响应字段说明

### ProjectDetailVO 字段

| 字段名           | 类型              | 说明                        |
|------------------|-------------------|-----------------------------|
| id               | Long              | 项目ID                      |
| projName         | String            | 项目名称                    |
| shortTitle       | String            | 项目简称（可为空）          |
| sponsorName      | String            | 申办方名称（可为空）        |
| progressName     | String            | 项目进度名称（如"进行中"）  |
| signedCount      | Integer           | 已签约例数                  |
| totalSignCount   | Integer           | 总签约例数                  |
| customTags       | List\<String\>    | 自定义标签列表              |
| createdAt        | LocalDateTime     | 创建时间                    |
| updatedAt        | LocalDateTime     | 最后更新时间                |

### PageResponse 字段

| 字段名   | 类型    | 说明                        |
|----------|---------|----------------------------|
| data     | List    | 当前页的数据列表            |
| page     | Integer | 当前页码                    |
| size     | Integer | 每页大小                    |
| total    | Long    | 总记录数                    |
| pages    | Integer | 总页数                      |
| hasNext  | Boolean | 是否有下一页                |
| hasPrev  | Boolean | 是否有上一页                |

## 搜索范围

搜索功能会在以下字段中查找关键词：

1. **项目标题** (`t_project.proj_name`)
2. **自定义标签** (`t_project_custom_tag.tag_text`)
3. **CRC 人员姓名** (`t_person.name` where role = 'CRC')
4. **项目成员** (所有角色的人员姓名)

所有这些字段的内容都已经预先同步到 `t_project_search.search_text` 字段中。

## 搜索算法

### 双重匹配策略

```sql
WHERE (
  MATCH(ps.search_text) AGAINST(#{keyword} IN NATURAL LANGUAGE MODE)  -- 全文索引
  OR
  ps.search_text LIKE CONCAT('%', #{keyword}, '%')                     -- 模糊匹配
)
```

### 排序规则

1. **相关性得分**：全文搜索得分高的优先
2. **更新时间**：相关性相同时，最近更新的优先

```sql
ORDER BY 
  relevance_score DESC,
  p.updated_at DESC
```

## 性能优化

### 全文索引

数据库已配置 `ngram` 全文索引，支持中文分词：

```sql
FULLTEXT KEY `ft_search` (`search_text`) WITH PARSER `ngram`
```

### 索引覆盖

查询使用了以下索引：
- `t_project_search.ft_search` - 全文索引
- `t_project_search.idx_org_hosp` - 组织和医院索引
- `t_project.is_deleted` - 逻辑删除索引

### 定时同步

搜索数据通过定时任务自动同步：
- 应用启动时：执行一次全量同步
- 运行期间：每30分钟增量同步一次

详见：[PROJECT_SEARCH_SYNC_TASK.md](./PROJECT_SEARCH_SYNC_TASK.md)

## 使用限制

### 关键词要求
- 最少2个字符
- 自动去除前后空格
- 关键词为空时返回空结果

### 分页限制
- 页码最小为 1
- 每页大小最小为 1，最大为 100

## 测试建议

### 测试场景

1. **精确匹配**
   - 搜索完整的项目名称
   - 搜索精确的标签名

2. **模糊匹配**
   - 搜索项目名称的一部分
   - 搜索 CRC 人员姓名

3. **中文分词**
   - 搜索 "肺癌"，应该匹配 "非小细胞肺癌"
   - 搜索 "治疗"，应该匹配包含该词的所有项目

4. **边界情况**
   - 空关键词
   - 单字符关键词
   - 特殊字符
   - 超长关键词

5. **分页测试**
   - 第一页
   - 最后一页
   - 超出范围的页码

### 测试数据准备

确保数据库中有：
1. 已同步的项目搜索数据（`t_project_search` 表有数据）
2. 项目有自定义标签
3. 项目有 CRC 人员

## 常见问题

### Q1: 搜索不到结果？

**可能原因：**
1. 搜索索引未同步 - 检查 `t_project_search` 表是否有数据
2. 关键词太短 - 至少需要2个字符
3. 组织隔离 - 确认项目属于当前用户的组织

**解决方法：**
```sql
-- 检查搜索索引数据
SELECT * FROM t_project_search WHERE org_id = <your_org_id>;

-- 手动触发同步（重启应用）
```

### Q2: 搜索结果不准确？

**可能原因：**
1. 搜索数据未及时更新
2. 全文索引缓存

**解决方法：**
- 等待定时任务执行（最多30分钟）
- 或重启应用触发全量同步

### Q3: 搜索很慢？

**可能原因：**
1. 数据量大，索引未生效
2. 复杂的 LIKE 查询

**解决方法：**
```sql
-- 检查索引是否存在
SHOW INDEX FROM t_project_search;

-- 优化查询
EXPLAIN SELECT ... FROM t_project_search WHERE ...;
```

## 后续扩展

1. **搜索高亮**：在响应中标记匹配的关键词
2. **搜索历史**：记录用户的搜索历史
3. **热门搜索**：统计和展示热门搜索词
4. **搜索建议**：输入时提供自动补全
5. **高级筛选**：支持按项目状态、时间范围等筛选
6. **搜索缓存**：对热门关键词进行 Redis 缓存

## 相关文档

- [项目搜索同步任务](./PROJECT_SEARCH_SYNC_TASK.md)
- [API 总览](../API-Documentation.md)

