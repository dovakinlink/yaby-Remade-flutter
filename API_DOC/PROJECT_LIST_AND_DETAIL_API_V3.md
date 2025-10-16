# 项目列表与详情 API 文档

## 功能概述

项目管理的核心 API，提供以下功能：
- **项目列表查询**：支持分页和基于自定义属性的动态筛选
- **项目详情查询**：返回项目的完整信息（包括自定义属性、标签、入排标准、附件、人员等）

## 技术特点

- ✅ **动态筛选**：基于 EAV 模型（t_project_attr_value）的动态筛选查询
- ✅ **完整信息组装**：详情接口关联多张表返回完整数据
- ✅ **多租户隔离**：自动根据用户组织ID过滤数据
- ✅ **灵活排序**：按 order_no 和 updated_at 排序
- ✅ **JWT 认证**：需要登录后才能访问

---

## API 接口

### 1. 项目列表查询

**接口地址**
```
GET /api/v1/projects
```

**功能说明**

查询当前用户组织下的项目列表，支持：
- 分页查询
- 基于自定义属性的动态筛选（EAV 模型）
- 按 order_no 排序

**请求参数**

| 参数名      | 类型                | 必填 | 默认值 | 说明                                      |
|-------------|---------------------|------|--------|-------------------------------------------|
| page        | Integer             | 否   | 1      | 页码，从1开始                             |
| size        | Integer             | 否   | 10     | 每页大小，最大100                         |
| attrFilters | Map<String, String> | 否   | -      | 自定义属性筛选条件（详见下方说明）        |

**attrFilters 参数说明**

自定义属性筛选条件，格式为：`attrFilters.属性code=选项ID或值`

- **格式**: 以 `attrFilters.` 为前缀，后跟属性编码
- **key**: 属性编码（如 tumor_type, tumor_stage）
- **value**: 选项ID或属性值
- **多个条件**: 多个筛选条件之间是 AND 关系
- **支持类型**:
  - **单选选项** (option): 通过 `option_id` 匹配
  - **多选选项** (multi_option): 通过 `option_ids_json` 匹配（JSON数组）
  - **整数** (int): 通过 `int_val` 匹配
  - **文本** (text): 通过 `text_val` 匹配

**请求头**
```
Authorization: Bearer <JWT_TOKEN>
```

**请求示例**

1. 不带筛选条件（查询所有项目）：
```bash
curl -X GET "http://localhost:8080/api/v1/projects?page=1&size=10" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9..."
```

2. 按瘤种筛选：
```bash
curl -X GET "http://localhost:8080/api/v1/projects?page=1&size=10&attrFilters.tumor_type=3" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9..."
```

3. 多条件筛选（瘤种 + 肿瘤分期）：
```bash
curl -X GET "http://localhost:8080/api/v1/projects?page=1&size=10&attrFilters.tumor_type=3&attrFilters.tumor_stage=1" \
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
    "total": 25,
    "pages": 3,
    "hasNext": true,
    "hasPrev": false
  }
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

---

### 2. 获取属性定义

**接口地址**
```
GET /api/v1/projects/attr-definitions
```

**功能说明**

查询项目模板的自定义属性定义，供前端：
- 知道可以筛选哪些自定义属性
- 获取每个属性的类型信息用于表单渲染
- 对于选项类型的属性，获取所有可选项

**请求参数**

| 参数名       | 类型 | 必填 | 默认值 | 说明                                          |
|--------------|------|------|--------|-----------------------------------------------|
| templateId   | Long | 否   | -      | 模板ID（如果指定，查询该模板的属性定义）      |
| disciplineId | Long | 否   | -      | 学科ID（如果指定，查询该学科活跃模板的属性）  |

**参数说明**：
- 如果传入 `templateId`，查询指定模板的属性定义
- 如果传入 `disciplineId`，查询该学科下活跃模板的属性定义
- 如果都不传，查询第一个活跃模板的属性定义

**请求头**
```
Authorization: Bearer <JWT_TOKEN>
```

**请求示例**

1. 查询默认模板的属性定义：
```bash
curl -X GET "http://localhost:8080/api/v1/projects/attr-definitions" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9..."
```

2. 查询指定模板的属性定义：
```bash
curl -X GET "http://localhost:8080/api/v1/projects/attr-definitions?templateId=1" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9..."
```

3. 查询指定学科的属性定义：
```bash
curl -X GET "http://localhost:8080/api/v1/projects/attr-definitions?disciplineId=1" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9..."
```

**响应示例**

成功响应（200 OK）：
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": [
    {
      "id": 1,
      "code": "tumor_stage",
      "label": "肿瘤分期",
      "dataType": "multi_option",
      "control": "multi_select",
      "required": true,
      "searchable": true,
      "unit": null,
      "placeholder": "",
      "helpText": "",
      "sort": 1,
      "options": [
        {
          "id": 1,
          "code": "stage_i",
          "label": "I期",
          "sort": 1,
          "enabled": true
        },
        {
          "id": 2,
          "code": "stage_ii",
          "label": "II期",
          "sort": 2,
          "enabled": true
        }
      ]
    },
    {
      "id": 2,
      "code": "tumor_type",
      "label": "瘤种",
      "dataType": "multi_option",
      "control": "multi_select",
      "required": true,
      "searchable": true,
      "unit": null,
      "placeholder": "",
      "helpText": "",
      "sort": 2,
      "options": [
        {
          "id": 3,
          "code": "SOFT_TISSUE_SARCOMA",
          "label": "软组织肉瘤",
          "sort": 1,
          "enabled": true
        },
        {
          "id": 4,
          "code": "URINARY_TRACT_CANCER",
          "label": "泌尿系",
          "sort": 2,
          "enabled": true
        }
      ]
    }
  ]
}
```

没有找到活跃模板（400 Bad Request）：
```json
{
  "success": false,
  "code": "NO_ACTIVE_TEMPLATE",
  "message": "没有找到活跃的项目模板",
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

---

### 3. 项目详情查询

**接口地址**
```
GET /api/v1/projects/{id}
```

**功能说明**

查询项目的完整信息，包括：
- 基本信息（项目名称、申办方、进度、签约例数等）
- 自定义属性（基于 EAV 模型的动态字段）
- 自定义标签
- 入排标准
- 附件列表
- 项目人员

**路径参数**

| 参数名 | 类型 | 必填 | 说明     |
|--------|------|------|----------|
| id     | Long | 是   | 项目ID   |

**请求头**
```
Authorization: Bearer <JWT_TOKEN>
```

**请求示例**

```bash
curl -X GET "http://localhost:8080/api/v1/projects/12" \
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
    "id": 12,
    "projName": "非小细胞肺癌一线治疗研究",
    "shortTitle": "肺癌研究",
    "sponsorName": "XX制药有限公司",
    "progressName": "进行中",
    "signedCount": 15,
    "totalSignCount": 50,
    "remark": "这是一个针对非小细胞肺癌患者的一线治疗临床研究项目",
    "customTags": ["肺癌", "一线治疗", "靶向药物"],
    "customAttrs": [
      {
        "attrId": 1,
        "code": "tumor_stage",
        "label": "肿瘤分期",
        "dataType": "option",
        "boolValue": null,
        "intValue": null,
        "decimalValue": null,
        "dateValue": null,
        "textValue": null,
        "optionId": 1,
        "optionLabel": "I期",
        "multiOptionLabels": null
      },
      {
        "attrId": 2,
        "code": "tumor_type",
        "label": "瘤种",
        "dataType": "option",
        "boolValue": null,
        "intValue": null,
        "decimalValue": null,
        "dateValue": null,
        "textValue": null,
        "optionId": 3,
        "optionLabel": "软组织肉瘤",
        "multiOptionLabels": null
      }
    ],
    "criteria": [
      {
        "itemNo": 1,
        "itemType": "IN",
        "content": "年龄18-75岁的患者"
      },
      {
        "itemNo": 2,
        "itemType": "IN",
        "content": "组织学或细胞学确诊的非小细胞肺癌"
      },
      {
        "itemNo": 3,
        "itemType": "EX",
        "content": "既往接受过系统性抗肿瘤治疗"
      }
    ],
    "files": [
      {
        "fileId": 1,
        "fileName": "protocol_v1.0.pdf",
        "fileUrl": "/files/2024/01/protocol_v1.0.pdf",
        "displayName": "研究方案 v1.0",
        "category": "protocol",
        "sizeBytes": 1024000,
        "mimeType": "application/pdf",
        "sortNo": 1
      },
      {
        "fileId": 2,
        "fileName": "icf_v1.0.pdf",
        "fileUrl": "/files/2024/01/icf_v1.0.pdf",
        "displayName": "知情同意书 v1.0",
        "category": "icf",
        "sizeBytes": 512000,
        "mimeType": "application/pdf",
        "sortNo": 2
      }
    ],
    "staff": [
      {
        "personId": "abc123def456",
        "personName": "张三",
        "roleName": "CRC",
        "isPrimary": true,
        "note": "主要负责人"
      },
      {
        "personId": "xyz789uvw012",
        "personName": "李四",
        "roleName": "PI",
        "isPrimary": false,
        "note": null
      }
    ],
    "createdAt": "2024-01-15T10:30:00",
    "updatedAt": "2024-03-20T14:20:00"
  }
}
```

项目不存在或无权访问（400 Bad Request）：
```json
{
  "success": false,
  "code": "PROJECT_NOT_FOUND",
  "message": "项目不存在或无权访问",
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

---

## 响应字段说明

### ProjectDetailVO 字段（列表和详情共用）

| 字段名           | 类型                              | 说明                              |
|------------------|-----------------------------------|-----------------------------------|
| id               | Long                              | 项目ID                            |
| projName         | String                            | 项目名称                          |
| shortTitle       | String                            | 项目简称（可为空）                |
| sponsorName      | String                            | 申办方名称（可为空）              |
| progressName     | String                            | 项目进度名称（如"进行中"）        |
| signedCount      | Integer                           | 已签约例数                        |
| totalSignCount   | Integer                           | 总签约例数                        |
| remark           | String                            | 项目备注（详情接口返回）          |
| customTags       | List\<String\>                    | 自定义标签列表                    |
| customAttrs      | List\<ProjectAttrVO\>             | 自定义属性列表（详情接口返回）    |
| criteria         | List\<ProjectCriteriaItemVO\>     | 入排标准列表（详情接口返回）      |
| files            | List\<ProjectFileVO\>             | 附件列表（详情接口返回）          |
| staff            | List\<ProjectStaffVO\>            | 项目人员列表（详情接口返回）      |
| createdAt        | LocalDateTime                     | 创建时间                          |
| updatedAt        | LocalDateTime                     | 最后更新时间                      |

### ProjectAttrVO 字段（自定义属性）

| 字段名             | 类型              | 说明                                           |
|--------------------|-------------------|------------------------------------------------|
| attrId             | Long              | 属性定义ID                                     |
| code               | String            | 属性编码（如 tumor_type, tumor_stage）         |
| label              | String            | 属性显示名称（如"瘤种"、"肿瘤分期"）           |
| dataType           | String            | 数据类型（bool/int/decimal/date/text/option/multi_option） |
| boolValue          | Boolean           | 布尔值（dataType=bool 时使用）                 |
| intValue           | Long              | 整数值（dataType=int 时使用）                  |
| decimalValue       | BigDecimal        | 小数值（dataType=decimal 时使用）              |
| dateValue          | LocalDate         | 日期值（dataType=date 时使用）                 |
| textValue          | String            | 文本值（dataType=text 时使用）                 |
| optionId           | Long              | 选项ID（dataType=option 时使用）               |
| optionLabel        | String            | 选项标签（dataType=option 时使用）             |
| multiOptionLabels  | List\<String\>    | 多选项标签列表（dataType=multi_option 时使用） |

### ProjectCriteriaItemVO 字段（入排标准）

| 字段名   | 类型    | 说明                         |
|----------|---------|------------------------------|
| itemNo   | Integer | 序号（从1开始）              |
| itemType | String  | 类型（IN=入组, EX=排除）     |
| content  | String  | 条目内容                     |

### ProjectFileVO 字段（附件）

| 字段名      | 类型    | 说明                                    |
|-------------|---------|-----------------------------------------|
| fileId      | Long    | 文件ID                                  |
| fileName    | String  | 文件名                                  |
| fileUrl     | String  | 文件访问URL                             |
| displayName | String  | 展示名称（优先使用，否则使用 fileName） |
| category    | String  | 文件分类（如 protocol, icf, crf）       |
| sizeBytes   | Long    | 文件大小（字节）                        |
| mimeType    | String  | MIME 类型                               |
| sortNo      | Integer | 排序号                                  |

### ProjectStaffVO 字段（项目人员）

| 字段名     | 类型    | 说明                        |
|------------|---------|-----------------------------|
| personId   | String  | 人员ID                      |
| personName | String  | 人员姓名                    |
| roleName   | String  | 角色名称（如 CRC、PI、CRA） |
| isPrimary  | Boolean | 是否主要负责人              |
| note       | String  | 备注                        |

### PageResponse 字段（分页响应）

| 字段名   | 类型    | 说明           |
|----------|---------|----------------|
| data     | List    | 当前页的数据   |
| page     | Integer | 当前页码       |
| size     | Integer | 每页大小       |
| total    | Long    | 总记录数       |
| pages    | Integer | 总页数         |
| hasNext  | Boolean | 是否有下一页   |
| hasPrev  | Boolean | 是否有上一页   |

---

## 自定义属性筛选说明

### 筛选机制

项目列表支持基于自定义属性的动态筛选，这些属性存储在 EAV 模型中：
- **t_project_attr_def**: 属性定义表（定义属性的名称、类型等）
- **t_project_attr_value**: 属性值表（存储每个项目的属性值）
- **t_project_attr_option**: 选项表（单选/多选类型的可选项）

### 筛选示例

假设有以下自定义属性：
- `tumor_type`（瘤种）：选项类型，选项ID=3 表示"肺癌"
- `tumor_stage`（肿瘤分期）：选项类型，选项ID=1 表示"I期"

**示例 1：按瘤种筛选**
```
GET /api/v1/projects?attrFilters.tumor_type=3
```
返回所有瘤种为"肺癌"的项目

**示例 2：多条件筛选（瘤种 + 分期）**
```
GET /api/v1/projects?attrFilters.tumor_type=3&attrFilters.tumor_stage=1
```
返回瘤种为"肺癌"且分期为"I期"的项目（AND 关系）

**示例 3：文本类型筛选**
```
GET /api/v1/projects?attrFilters.custom_field=某个文本值
```
返回 custom_field 等于"某个文本值"的项目

### 筛选数据类型支持

- **option（单选）**: 传递选项ID（option_id）
- **int（整数）**: 传递整数值（int_val）
- **text（文本）**: 传递文本值（text_val）

注意：目前不支持范围筛选（如日期范围、数值范围），仅支持精确匹配。

---

## 排序规则

### 列表接口排序

项目列表按以下顺序排序：
1. **order_no ASC**: 排序号升序（数字越小越靠前）
2. **updated_at DESC**: 更新时间降序（最近更新的在前）

### 详情接口子列表排序

- **自定义属性**: 按 `t_project_attr_def.sort` 排序
- **自定义标签**: 按创建时间排序
- **入排标准**: 按 `item_no` 排序
- **附件**: 按 `sort_no` 和创建时间排序
- **人员**: 主要负责人优先，然后按姓名排序

---

## 性能优化

### 列表查询优化

1. **动态筛选使用 EXISTS 子查询**：利用索引，避免全表扫描
2. **分页查询**：使用 LIMIT 和 OFFSET 限制返回数据量
3. **索引利用**：
   - `t_project.org_id` + `is_deleted` 复合索引
   - `t_project_attr_value` 的 `idx_attr_int`、`idx_attr_opt` 索引

### 详情查询优化

1. **多次查询而非一次大 JOIN**：避免笛卡尔积，减少数据传输
2. **按需加载**：只查询需要的字段
3. **索引覆盖**：大部分查询都能命中索引

---

## 多租户隔离

所有接口都自动基于 JWT 中的 `orgId` 进行数据隔离：
- 列表接口：只返回当前组织的项目
- 详情接口：只能查询当前组织的项目，否则返回 404

这确保了数据的安全性和隔离性。

---

## 常见问题

### Q1: 如何获取可用的属性编码（code）？

A: 调用 `/api/v1/projects/attr-definitions` 接口获取当前模板下的所有可用属性定义，从中获取 `code` 字段。

### Q2: 筛选条件如何传递？

A: 使用查询参数格式：`attrFilters.code=value`，多个条件重复使用该格式。例如：`attrFilters.tumor_type=3&attrFilters.tumor_stage=1`。

### Q3: 为什么详情接口返回的自定义属性有多个值字段？

A: 因为基于 EAV 模型，不同类型的属性值存储在不同的字段中。前端应根据 `dataType` 字段判断使用哪个值字段。

### Q4: 如何判断项目是否有下一页？

A: 使用响应中的 `hasNext` 字段，或者判断 `page < pages`。

### Q5: 列表接口返回的数据包含完整信息吗？

A: 列表接口只返回基本信息和自定义标签，不包含自定义属性、入排标准、附件和人员。需要完整信息时请调用详情接口。

### Q6: 如何知道某个属性是单选还是多选？

A: 调用属性定义接口，查看 `dataType` 字段：
- `option` = 单选
- `multi_option` = 多选

同时可以参考 `control` 字段获取建议的前端控件类型。

### Q7: 属性选项会变化吗？

A: 会的。属性选项可以被管理员添加、修改或停用。建议前端定期刷新属性定义，或在每次进入筛选页面时重新获取。

---

## 错误码说明

| 错误码              | HTTP 状态码 | 说明                   |
|---------------------|-------------|------------------------|
| SUCCESS             | 200         | 请求成功               |
| UNAUTHORIZED        | 401         | 未登录或 Token 无效    |
| PROJECT_NOT_FOUND   | 400         | 项目不存在或无权访问   |
| NO_ACTIVE_TEMPLATE  | 400         | 没有找到活跃的项目模板 |
| VALIDATION_ERROR    | 400         | 参数验证失败           |
| INTERNAL_ERROR      | 500         | 服务器内部错误         |

---

## 相关文档

- [项目全局搜索 API](./PROJECT_SEARCH_API.md)
- [项目搜索同步任务](./PROJECT_SEARCH_SYNC_TASK.md)
- [API 总览](../API-Documentation.md)

---

## 更新日志

- **v1.0.1** (2025-10-16): 添加属性定义查询接口，支持获取模板的自定义属性及选项
- **v1.0.0** (2025-10-16): 初始版本，实现项目列表和详情查询接口

