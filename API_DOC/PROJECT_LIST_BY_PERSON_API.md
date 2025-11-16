# 根据人员ID查询项目列表 API 文档

## 功能概述

根据指定人员ID查询该人员参与的所有临床试验项目列表，支持分页查询。

## 技术特点

- ✅ **人员关联查询**：通过 `t_project_staff` 表关联查询人员参与的项目
- ✅ **分页支持**：支持分页查询，默认每页10条
- ✅ **多租户隔离**：自动根据用户组织ID过滤数据
- ✅ **数据格式统一**：返回格式与项目列表API一致
- ✅ **JWT 认证**：需要登录后才能访问

---

## API 接口

### 根据人员ID查询项目列表

**接口地址**
```
GET /api/v1/projects/by-person/{personId}
```

**功能说明**

查询指定人员参与的所有项目列表，支持分页。

查询逻辑：
- 通过 `t_project_staff` 表关联查询，根据 `person_id` 匹配
- 只返回未删除的项目（`is_deleted = 0`）
- 只返回当前组织下的项目（多租户隔离）
- 按 `order_no` 升序、`updated_at` 降序排序
- 返回格式与项目列表API一致，包含项目基本信息和自定义标签

**路径参数**

| 参数名   | 类型   | 必填 | 说明                    |
|----------|--------|------|-------------------------|
| personId | String | 是   | 人员ID（t_person.c_id） |

**查询参数**

| 参数名 | 类型    | 必填 | 默认值 | 说明                    |
|--------|---------|------|--------|-------------------------|
| page   | Integer | 否   | 1      | 页码，从1开始           |
| size   | Integer | 否   | 10     | 每页大小，最大100       |

**请求头**
```
Authorization: Bearer <JWT_TOKEN>
```

**请求示例**

1. 查询人员参与的项目列表（第一页，每页10条）：
```bash
curl -X GET "http://localhost:8080/api/v1/projects/by-person/0f17a701da3d415ea36ad5bd92b0712a?page=1&size=10" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9..."
```

2. 查询人员参与的项目列表（第二页，每页20条）：
```bash
curl -X GET "http://localhost:8080/api/v1/projects/by-person/0f17a701da3d415ea36ad5bd92b0712a?page=2&size=20" \
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
        "id": 19,
        "projName": "JAB-21822 联合 JAB-3312 对比替雷利珠单抗联合培美曲塞+卡铂一线治疗 KRAS p.G12C 突变的晚期非鳞状非小细胞肺癌的随机、阳性对照、开放标签的多中心Ⅲ期临床试验",
        "shortTitle": "G12C突变 不适合接受确定性治疗",
        "sponsorName": "XX生物制药",
        "progressName": "进行中",
        "signedCount": 8,
        "totalSignCount": 30,
        "customTags": ["肺癌", "G12C突变"],
        "createdAt": "2024-02-10T09:15:00",
        "updatedAt": "2024-03-18T16:45:00"
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

**响应字段说明**

| 字段名        | 类型     | 说明                                    |
|---------------|----------|-----------------------------------------|
| success       | Boolean  | 请求是否成功                            |
| code          | String   | 响应代码（SUCCESS表示成功）             |
| message       | String   | 响应消息                                |
| data          | Object   | 响应数据                                |
| data.data     | Array    | 项目列表                                |
| data.page     | Integer  | 当前页码                                |
| data.size     | Integer  | 每页大小                                |
| data.total    | Long     | 总记录数                                |
| data.pages    | Integer  | 总页数                                  |
| data.hasNext  | Boolean  | 是否有下一页                            |
| data.hasPrev  | Boolean  | 是否有上一页                            |

**项目对象字段说明**

| 字段名        | 类型     | 说明                                    |
|---------------|----------|-----------------------------------------|
| id            | Long     | 项目ID                                  |
| projName      | String   | 项目名称                                |
| shortTitle    | String   | 项目简称                                |
| sponsorName   | String   | 申办方名称                              |
| progressName  | String   | 项目进度名称（如：进行中、待开始等）    |
| signedCount   | Integer  | 已签约例数                              |
| totalSignCount| Integer  | 总签约例数                              |
| customTags    | Array    | 自定义标签列表                          |
| createdAt     | DateTime | 创建时间                                |
| updatedAt     | DateTime | 更新时间                                |

**错误响应**

1. 未授权（401 Unauthorized）：
```json
{
  "success": false,
  "code": "UNAUTHORIZED",
  "message": "未授权，请先登录",
  "data": null
}
```

2. 人员ID不存在或该人员未参与任何项目（200 OK，返回空列表）：
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": {
    "data": [],
    "page": 1,
    "size": 10,
    "total": 0,
    "pages": 0,
    "hasNext": false,
    "hasPrev": false
  }
}
```

3. 参数错误（400 Bad Request）：
```json
{
  "success": false,
  "code": "BAD_REQUEST",
  "message": "参数错误：page必须大于0",
  "data": null
}
```

---

## 业务说明

### 查询逻辑

1. **人员关联**：通过 `t_project_staff` 表的 `person_id` 字段关联查询
2. **多租户隔离**：只返回当前用户组织（`org_id`）下的项目
3. **数据过滤**：排除已删除的项目（`is_deleted = 0`）
4. **去重处理**：如果同一人员在同一个项目中担任多个角色，项目只返回一次（使用 `DISTINCT`）
5. **排序规则**：
   - 首先按 `order_no` 升序排序（数字越小越靠前）
   - 然后按 `updated_at` 降序排序（最近更新的在前）

### 数据范围

- **组织隔离**：只返回当前用户组织下的项目
- **人员范围**：查询指定 `personId` 参与的所有项目
- **项目状态**：包括所有未删除的项目（不区分项目状态）

### 使用场景

1. **查看人员参与的项目**：在人员详情页面，展示该人员参与的所有项目
2. **项目统计**：统计某个人员参与的项目数量
3. **项目筛选**：根据人员筛选项目列表

---

## 性能优化

### 查询优化

1. **索引利用**：
   - `t_project_staff.person_id` 索引（如果存在）
   - `t_project.org_id` + `is_deleted` 复合索引
   - `t_project.order_no` 和 `updated_at` 索引

2. **分页查询**：使用 `LIMIT` 和 `OFFSET` 限制返回数据量

3. **去重优化**：使用 `DISTINCT` 避免重复数据

### 建议

- 如果人员参与的项目数量较多，建议合理设置分页大小（建议不超过50）
- 前端可以缓存人员项目列表，减少重复请求

---

## 相关API

- [项目列表查询 API](./PROJECT_LIST_AND_DETAIL_API.md#1-项目列表查询)
- [项目详情查询 API](./PROJECT_LIST_AND_DETAIL_API.md#2-项目详情查询)
- [项目全局搜索 API](./PROJECT_SEARCH_API.md)

---

## 更新日志

- **2025-11-16**：新增根据人员ID查询项目列表API

