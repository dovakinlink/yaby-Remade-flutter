# 临床试验筛查流程 API 文档

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

## 状态流转规则

筛查流程包含以下状态，按照严格的流转规则进行：

```
初始提交
    ↓
PENDING（待CRC审核）        ← 全部入排条件匹配
    ↓
    ├→ MATCH_FAILED（筛查失败）  ← CRC拒绝筛查
    └→ CRC_REVIEW（CRC审核中）   ← CRC审核通过
        ↓
        ├→ ICF_FAILED（知情失败）    ← 患者拒绝知情同意
        └→ ICF_SIGNED（已知情）       ← 患者同意并签署知情同意书
            ↓
        ENROLLED（已入组）            ← 提交入组信息
            ↓
        EXITED（已出组）              ← 临床试验结束
```

**状态说明**：
- `PENDING`: 医生提交初筛，等待CRC审核
- `CRC_REVIEW`: CRC正在审核中
- `MATCH_FAILED`: 筛查失败，不符合入排条件或CRC拒绝
- `ICF_SIGNED`: 已知情，患者已签署知情同意书
- `ICF_FAILED`: 知情失败，患者拒绝参与
- `ENROLLED`: 已入组，正式开始临床试验
- `EXITED`: 已出组，完成或退出临床试验

**审核权限规则**：
- 当筛查状态为`PENDING`时，只有该项目的CRC才能进行审核操作（通过或拒绝）
- 发起筛查的医生不能自己审核通过自己发起的筛查请求
- CRC可以拒绝筛查请求，状态变更为`MATCH_FAILED`

---

## 医生端接口

### 1. 提交初筛

**接口描述**: 医生提交受试者的初筛数据，包括患者信息和入排条件匹配结果。系统会：
1. 根据匹配结果自动判断初始状态（全部匹配→PENDING，有不匹配→MATCH_FAILED）
2. 自动关联项目的主要CRC（从项目人员表查询）

- **URL**: `/api/v1/screenings`
- **方法**: `POST`
- **认证**: 需要认证（Bearer Token）

#### 请求参数

```json
{
  "projectId": 1,
  "patientInNo": "202501001",
  "patientNameAbbr": "张**",
  "criteriaMatches": [
    {
      "criteriaId": 1,
      "matchResult": "MATCH",
      "remark": "患者符合年龄要求"
    },
    {
      "criteriaId": 2,
      "matchResult": "MATCH",
      "remark": "确诊为肺癌"
    },
    {
      "criteriaId": 3,
      "matchResult": "UNMATCH",
      "remark": "患者有心脏病史"
    }
  ]
}
```

**字段说明**：
| 字段名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| projectId | Long | 是 | 项目ID |
| patientInNo | String | 是 | 患者住院号/门诊号，最大64字符 |
| patientNameAbbr | String | 是 | 患者姓名简称（脱敏），最大50字符 |
| criteriaMatches | Array | 是 | 入排条件匹配列表 |
| criteriaMatches[].criteriaId | Long | 是 | 入排条目ID（从项目详情获取） |
| criteriaMatches[].matchResult | String | 是 | 匹配结果：MATCH/UNMATCH/NA |
| criteriaMatches[].remark | String | 否 | 补充说明，最大500字符 |

#### 响应示例

**成功响应 (200)**:
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": 123
}
```
*返回值为新创建的筛查记录ID*

**失败响应 (200)**:
```json
{
  "success": false,
  "code": "PROJECT_NOT_FOUND",
  "message": "项目不存在",
  "data": null
}
```

#### Flutter 调用示例

```dart
Future<int?> submitScreening({
  required int projectId,
  required String patientInNo,
  required String patientNameAbbr,
  required List<CriteriaMatch> matches,
}) async {
  final response = await http.post(
    Uri.parse('http://localhost:8090/api/v1/screenings'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken'
    },
    body: jsonEncode({
      'projectId': projectId,
      'patientInNo': patientInNo,
      'patientNameAbbr': patientNameAbbr,
      'criteriaMatches': matches.map((m) => {
        'criteriaId': m.criteriaId,
        'matchResult': m.matchResult,
        'remark': m.remark,
      }).toList(),
    }),
  );

  final result = jsonDecode(response.body);
  if (result['success']) {
    return result['data'] as int;
  } else {
    throw Exception(result['message']);
  }
}
```

---

### 2. 查询我的筛查列表

**接口描述**: 查询与当前用户相关的所有筛查记录，包括用户作为医生提交的记录和作为CRC负责的记录。支持按状态筛选，按创建时间倒序排列（最新的在前）

- **URL**: `/api/v1/screenings/my`
- **方法**: `GET`
- **认证**: 需要认证（Bearer Token）

#### 请求参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| statusCode | String | 否 | - | 状态筛选（如PENDING、ICF_SIGNED等），不传则查询所有 |
| page | Integer | 否 | 1 | 页码，从1开始 |
| size | Integer | 否 | 20 | 每页大小，最大100 |

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
        "projectId": 1,
        "projectName": "肺癌靶向药物临床试验",
        "patientInNo": "202501001",
        "patientNameAbbr": "张**",
        "researcherName": "李医生",
        "crcName": "王CRC",
        "statusCode": "PENDING",
        "statusText": "待CRC审核",
        "createdAt": "2025-10-19T10:30:00",
        "updatedAt": "2025-10-19T10:30:00"
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

#### Flutter 调用示例

```dart
Future<PageResponse<Screening>> getMyScreenings({
  String? statusCode,
  int page = 1,
  int size = 20,
}) async {
  final queryParams = {
    'page': page.toString(),
    'size': size.toString(),
  };
  if (statusCode != null && statusCode.isNotEmpty) {
    queryParams['statusCode'] = statusCode;
  }
  
  final uri = Uri.parse('http://localhost:8090/api/v1/screenings/my')
      .replace(queryParameters: queryParams);
  
  final response = await http.get(
    uri,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken'
    },
  );

  final result = jsonDecode(response.body);
  if (result['success']) {
    return PageResponse.fromJson(result['data']);
  } else {
    throw Exception(result['message']);
  }
}

// 使用示例：
// 1. 查询所有相关的筛查记录
final allScreenings = await getMyScreenings();

// 2. 只查询待审核的筛查记录
final pendingScreenings = await getMyScreenings(statusCode: 'PENDING');

// 3. 只查询已签署知情同意书的筛查记录
final icfSignedScreenings = await getMyScreenings(statusCode: 'ICF_SIGNED');
```

---

### 3. 查询筛查详情

**接口描述**: 查询指定筛查记录的详细信息，包含完整的入排条件匹配结果

- **URL**: `/api/v1/screenings/{id}`
- **方法**: `GET`
- **认证**: 需要认证（Bearer Token）

#### 请求参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| id | Long | 是 | 筛查记录ID（路径参数） |

#### 响应示例

**成功响应 (200)**:
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": {
    "id": 123,
    "orgId": 1,
    "hospitalId": null,
    "projectId": 1,
    "projectName": "肺癌靶向药物临床试验",
    "patientInNo": "202501001",
    "patientNameAbbr": "张**",
    "researcherUserId": 10,
    "researcherName": "李医生",
    "crcUserId": 20,
    "crcName": "王CRC",
    "statusCode": "ICF_SIGNED",
    "statusText": "已知情",
    "failReasonDictId": null,
    "failRemark": null,
    "createdAt": "2025-10-19T10:30:00",
    "updatedAt": "2025-10-19T14:20:00",
    "criteriaMatches": [
      {
        "id": 1,
        "criteriaType": "IN",
        "criteriaText": "年龄18-75岁",
        "matchResult": "MATCH",
        "remark": "患者52岁"
      },
      {
        "id": 2,
        "criteriaType": "IN",
        "criteriaText": "确诊为非小细胞肺癌",
        "matchResult": "MATCH",
        "remark": "病理确诊"
      },
      {
        "id": 3,
        "criteriaType": "EX",
        "criteriaText": "有严重心脏病史",
        "matchResult": "MATCH",
        "remark": "无心脏病史"
      }
    ]
  }
}
```

#### Flutter 调用示例

```dart
Future<ScreeningDetail> getScreeningDetail(int id) async {
  final response = await http.get(
    Uri.parse('http://localhost:8090/api/v1/screenings/$id'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken'
    },
  );

  final result = jsonDecode(response.body);
  if (result['success']) {
    return ScreeningDetail.fromJson(result['data']);
  } else {
    throw Exception(result['message']);
  }
}
```

---

## CRC端接口

### 4. 查询所有筛查列表

**接口描述**: 查询组织内所有的筛查记录，支持按状态筛选，按创建时间倒序排列

- **URL**: `/api/v1/screenings`
- **方法**: `GET`
- **认证**: 需要认证（Bearer Token）

#### 请求参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| statusCode | String | 否 | 无 | 状态代码筛选（为空则查询所有） |
| page | Integer | 否 | 1 | 页码，从1开始 |
| size | Integer | 否 | 20 | 每页大小，最大100 |

**statusCode可选值**：
- `PENDING` - 待CRC审核
- `CRC_REVIEW` - CRC审核中
- `MATCH_FAILED` - 筛查失败
- `ICF_SIGNED` - 已知情
- `ICF_FAILED` - 知情失败
- `ENROLLED` - 已入组
- `EXITED` - 已出组

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
        "projectId": 1,
        "projectName": "肺癌靶向药物临床试验",
        "patientInNo": "202501001",
        "patientNameAbbr": "张**",
        "researcherName": "李医生",
        "crcName": null,
        "statusCode": "PENDING",
        "statusText": "待CRC审核",
        "createdAt": "2025-10-19T10:30:00",
        "updatedAt": "2025-10-19T10:30:00"
      }
    ],
    "page": 1,
    "size": 20,
    "total": 50,
    "pages": 3,
    "hasNext": true,
    "hasPrev": false
  }
}
```

#### Flutter 调用示例

```dart
Future<PageResponse<Screening>> getAllScreenings({
  String? statusCode,
  int page = 1,
  int size = 20,
}) async {
  var url = 'http://localhost:8090/api/v1/screenings?page=$page&size=$size';
  if (statusCode != null) {
    url += '&statusCode=$statusCode';
  }
  
  final response = await http.get(
    Uri.parse(url),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken'
    },
  );

  final result = jsonDecode(response.body);
  if (result['success']) {
    return PageResponse.fromJson(result['data']);
  } else {
    throw Exception(result['message']);
  }
}
```

---

### 5. 更新筛查状态

**接口描述**: CRC更新筛查记录的状态，支持各种状态流转

- **URL**: `/api/v1/screenings/{id}/status`
- **方法**: `PUT`
- **认证**: 需要认证（Bearer Token）

#### 权限校验规则

当筛查状态为`PENDING`（待审核）时：
- **审核通过**（状态变更为`CRC_REVIEW`等非`MATCH_FAILED`状态）：只有该项目的CRC才能操作，且发起人不能自己审核通过
- **拒绝**（状态变更为`MATCH_FAILED`）：CRC可以执行拒绝操作

| 当前状态 | 目标状态 | 权限要求 |
|---------|---------|---------|
| PENDING | MATCH_FAILED | CRC可以拒绝 |
| PENDING | CRC_REVIEW | 必须是项目CRC，且不能是发起人 |
| PENDING | 其他状态 | 必须是项目CRC，且不能是发起人 |
| 其他状态 | 任意状态 | 保持现有逻辑 |

#### 请求参数

```json
{
  "status": "CRC_REVIEW",
  "failReasonDictId": null,
  "failRemark": null
}
```

**字段说明**：
| 字段名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| status | String | 是 | 新状态代码 |
| failReasonDictId | Long | 否 | 失败原因字典ID（状态为失败时填写） |
| failRemark | String | 否 | 失败备注，最大500字符 |

**拒绝筛查请求示例**：
```json
{
  "status": "MATCH_FAILED",
  "failReasonDictId": 101,
  "failRemark": "患者不符合入组条件"
}
```

#### 响应示例

**成功响应 (200)**:
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": "状态更新成功"
}
```

**失败响应 - 无权限 (200)**:
```json
{
  "success": false,
  "code": "FORBIDDEN",
  "message": "只有项目CRC才能审核通过",
  "data": null
}
```

**失败响应 - 不能自审 (200)**:
```json
{
  "success": false,
  "code": "FORBIDDEN",
  "message": "不能审核自己发起的筛查请求",
  "data": null
}
```

**失败响应 - 状态不允许 (200)**:
```json
{
  "success": false,
  "code": "INVALID_STATUS",
  "message": "当前状态不允许该操作",
  "data": null
}
```

#### Flutter 调用示例

```dart
Future<void> updateScreeningStatus({
  required int id,
  required String status,
  int? failReasonDictId,
  String? failRemark,
}) async {
  final response = await http.put(
    Uri.parse('http://localhost:8090/api/v1/screenings/$id/status'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken'
    },
    body: jsonEncode({
      'status': status,
      'failReasonDictId': failReasonDictId,
      'failRemark': failRemark,
    }),
  );

  final result = jsonDecode(response.body);
  if (!result['success']) {
    throw Exception(result['message']);
  }
}
```

---

### 6. 提交知情同意

**接口描述**: CRC提交受试者的知情同意信息，提交后状态自动变更为"已知情"（ICF_SIGNED）

- **URL**: `/api/v1/screenings/{id}/icf`
- **方法**: `POST`
- **认证**: 需要认证（Bearer Token）

#### 请求参数

```json
{
  "icfVersion": "V1.2",
  "icfDate": "2025-10-19",
  "signerName": "张某某",
  "fileIds": [101, 102]
}
```

**字段说明**：
| 字段名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| icfVersion | String | 是 | ICF版本/编号，最大100字符 |
| icfDate | Date | 是 | 签署日期（yyyy-MM-dd） |
| signerName | String | 是 | 签署人姓名，最大100字符 |
| fileIds | Array | 否 | 附件文件ID列表（可选） |

#### 响应示例

**成功响应 (200)**:
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": "知情同意提交成功"
}
```

**失败响应 (200)**:
```json
{
  "success": false,
  "code": "INVALID_STATUS",
  "message": "当前状态不允许提交知情同意",
  "data": null
}
```

#### Flutter 调用示例

```dart
Future<void> submitIcf({
  required int screeningId,
  required String icfVersion,
  required DateTime icfDate,
  required String signerName,
  List<int>? fileIds,
}) async {
  final response = await http.post(
    Uri.parse('http://localhost:8090/api/v1/screenings/$screeningId/icf'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken'
    },
    body: jsonEncode({
      'icfVersion': icfVersion,
      'icfDate': DateFormat('yyyy-MM-dd').format(icfDate),
      'signerName': signerName,
      'fileIds': fileIds,
    }),
  );

  final result = jsonDecode(response.body);
  if (!result['success']) {
    throw Exception(result['message']);
  }
}
```

---

## 入组出组管理接口

### 7. 提交入组信息

**接口描述**: 提交受试者的入组信息，包括入组号、入组日期等。提交后状态自动变更为"已入组"（ENROLLED）

- **URL**: `/api/v1/screenings/{id}/enrollment`
- **方法**: `POST`
- **认证**: 需要认证（Bearer Token）

#### 请求参数

```json
{
  "enrollNo": "2025-001-001",
  "enrollDate": "2025-10-20",
  "firstDoseDate": "2025-10-21"
}
```

**字段说明**：
| 字段名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| enrollNo | String | 是 | 入组号/随机号，最大100字符 |
| enrollDate | Date | 是 | 入组日期（yyyy-MM-dd） |
| firstDoseDate | Date | 否 | 首次用药日期（yyyy-MM-dd） |

#### 响应示例

**成功响应 (200)**:
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": "入组信息提交成功"
}
```

**失败响应 (200)**:
```json
{
  "success": false,
  "code": "INVALID_STATUS",
  "message": "只有已知情的受试者才能入组",
  "data": null
}
```

#### Flutter 调用示例

```dart
Future<void> submitEnrollment({
  required int screeningId,
  required String enrollNo,
  required DateTime enrollDate,
  DateTime? firstDoseDate,
}) async {
  final response = await http.post(
    Uri.parse('http://localhost:8090/api/v1/screenings/$screeningId/enrollment'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken'
    },
    body: jsonEncode({
      'enrollNo': enrollNo,
      'enrollDate': DateFormat('yyyy-MM-dd').format(enrollDate),
      'firstDoseDate': firstDoseDate != null 
          ? DateFormat('yyyy-MM-dd').format(firstDoseDate) 
          : null,
    }),
  );

  final result = jsonDecode(response.body);
  if (!result['success']) {
    throw Exception(result['message']);
  }
}
```

---

### 8. 标记出组

**接口描述**: 将已入组的受试者标记为出组状态（EXITED）

- **URL**: `/api/v1/screenings/{id}/exit`
- **方法**: `PUT`
- **认证**: 需要认证（Bearer Token）

#### 请求参数

无需请求体

#### 响应示例

**成功响应 (200)**:
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": "标记出组成功"
}
```

**失败响应 (200)**:
```json
{
  "success": false,
  "code": "INVALID_STATUS",
  "message": "只有已入组的受试者才能标记出组",
  "data": null
}
```

#### Flutter 调用示例

```dart
Future<void> markAsExited(int screeningId) async {
  final response = await http.put(
    Uri.parse('http://localhost:8090/api/v1/screenings/$screeningId/exit'),
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
```

---

### 9. 查询状态流转历史

**接口描述**: 查询筛查记录的完整状态流转历史，按时间正序排列

- **URL**: `/api/v1/screenings/{id}/status-log`
- **方法**: `GET`
- **认证**: 需要认证（Bearer Token）

#### 请求参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| id | Long | 是 | 筛查记录ID（路径参数） |

#### 响应示例

**成功响应 (200)**:
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": [
    {
      "id": 1,
      "fromStatus": null,
      "toStatus": "PENDING",
      "reasonDictId": null,
      "reasonRemark": null,
      "actedByName": "李医生",
      "createdAt": "2025-10-19T10:30:00"
    },
    {
      "id": 2,
      "fromStatus": "PENDING",
      "toStatus": "CRC_REVIEW",
      "reasonDictId": null,
      "reasonRemark": null,
      "actedByName": "王CRC",
      "createdAt": "2025-10-19T11:00:00"
    },
    {
      "id": 3,
      "fromStatus": "CRC_REVIEW",
      "toStatus": "ICF_SIGNED",
      "reasonDictId": null,
      "reasonRemark": null,
      "actedByName": "王CRC",
      "createdAt": "2025-10-19T14:20:00"
    }
  ]
}
```

#### Flutter 调用示例

```dart
Future<List<StatusLog>> getStatusHistory(int screeningId) async {
  final response = await http.get(
    Uri.parse('http://localhost:8090/api/v1/screenings/$screeningId/status-log'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken'
    },
  );

  final result = jsonDecode(response.body);
  if (result['success']) {
    return (result['data'] as List)
        .map((json) => StatusLog.fromJson(json))
        .toList();
  } else {
    throw Exception(result['message']);
  }
}
```

---

## 使用场景说明

### 场景1：医生提交初筛

医生在APP中搜索项目，选择合适的项目后，点击"提交初筛"：

1. 获取项目的入排标准列表（调用项目详情API）
2. 逐一判断患者是否符合入排条件
3. 填写患者信息（住院号、姓名简称）
4. 提交初筛数据
5. 系统自动判断：
   - 全部匹配 → 状态为PENDING（待CRC审核）
   - 有不匹配 → 状态为MATCH_FAILED（筛查失败）

```dart
// 完整流程示例
void submitScreeningFlow() async {
  // 1. 获取项目入排标准
  final project = await getProjectDetail(projectId);
  final criteria = project.criteria;
  
  // 2. 让医生逐一判断
  List<CriteriaMatch> matches = [];
  for (var item in criteria) {
    final result = await showCriteriaDialog(item);
    matches.add(CriteriaMatch(
      criteriaId: item.id,
      matchResult: result.isMatch ? 'MATCH' : 'UNMATCH',
      remark: result.remark,
    ));
  }
  
  // 3. 提交初筛
  final screeningId = await submitScreening(
    projectId: projectId,
    patientInNo: patientInNo,
    patientNameAbbr: patientNameAbbr,
    matches: matches,
  );
  
  print('筛查记录创建成功，ID: $screeningId');
}
```

### 场景2：CRC审核筛查

CRC登录后查看待审核的筛查列表，进行审核：

1. 查询所有PENDING状态的筛查
2. 查看筛查详情，包括患者信息和匹配结果
3. 更新状态为CRC_REVIEW（开始审核）
4. 线下与患者沟通知情同意
5. 根据结果：
   - 患者同意 → 提交知情同意（状态变为ICF_SIGNED）
   - 患者拒绝 → 更新状态为ICF_FAILED

```dart
// CRC审核流程
void crcReviewFlow(int screeningId) async {
  // 1. 查看详情
  final detail = await getScreeningDetail(screeningId);
  
  // 2. 开始审核
  await updateScreeningStatus(
    id: screeningId,
    status: 'CRC_REVIEW',
  );
  
  // 3. 线下沟通后，提交知情同意
  await submitIcf(
    screeningId: screeningId,
    icfVersion: 'V1.2',
    icfDate: DateTime.now(),
    signerName: '患者姓名',
  );
  
  print('知情同意提交成功，状态已更新为已知情');
}
```

### 场景3：入组和出组管理

患者签署知情同意后，进行入组操作；试验结束后标记出组：

```dart
// 入组流程
void enrollmentFlow(int screeningId) async {
  // 提交入组信息
  await submitEnrollment(
    screeningId: screeningId,
    enrollNo: '2025-001-001',
    enrollDate: DateTime.now(),
    firstDoseDate: DateTime.now().add(Duration(days: 1)),
  );
  
  print('入组成功');
}

// 出组流程
void exitFlow(int screeningId) async {
  // 标记出组
  await markAsExited(screeningId);
  
  print('已标记出组');
}
```

### 场景4：查看状态流转历史

查看筛查记录的完整流转历史，用于追溯和审计：

```dart
void viewStatusHistory(int screeningId) async {
  final logs = await getStatusHistory(screeningId);
  
  for (var log in logs) {
    print('${log.createdAt}: ${log.fromStatus} → ${log.toStatus} (${log.actedByName})');
  }
}
```

---

## 错误代码说明

| 错误代码 | 说明 | 解决方案 |
|---------|------|----------|
| UNAUTHORIZED | 用户未登录或Token失效 | 重新登录获取新的Token |
| PROJECT_NOT_FOUND | 项目不存在 | 检查项目ID是否正确 |
| USER_NOT_FOUND | 用户不存在 | 检查用户信息 |
| NO_CRITERIA | 项目没有设置入排标准 | 先为项目配置入排标准 |
| CRITERIA_NOT_FOUND | 入排条目不存在 | 检查条目ID是否正确 |
| SCREENING_NOT_FOUND | 筛查记录不存在 | 检查筛查记录ID |
| INVALID_STATUS | 当前状态不允许该操作 | 检查状态流转规则 |

---

## 注意事项

1. **状态流转限制**：
   - 状态流转必须按照规定的流程进行
   - 某些操作只能在特定状态下执行
   - 例如：只有ICF_SIGNED状态才能提交入组

2. **自动状态判断**：
   - 提交初筛时，系统会根据入排条件匹配结果自动设置初始状态
   - 全部MATCH → PENDING
   - 有UNMATCH → MATCH_FAILED

3. **自动关联CRC**：
   - 提交初筛时，系统会自动从项目人员表（t_project_staff）查询该项目的CRC
   - 优先选择主要负责人（is_primary=1）
   - 将CRC的用户ID和姓名填充到筛查记录中
   - 如果项目没有配置CRC，则CRC字段为空
   - CRC可以通过筛查列表查询到分配给自己的筛查记录

4. **状态流转日志**：
   - 所有状态变更都会自动记录到流转日志
   - 日志包含操作人、时间、原因等完整信息

5. **数据权限**：
   - 医生只能查看自己提交的筛查记录
   - CRC可以查看所有筛查记录
   - 基于组织ID（orgId）的多租户隔离

6. **事务一致性**：
   - 关键操作使用事务保证数据一致性
   - 提交初筛、提交知情同意、提交入组等操作都是原子性的

7. **Token认证**：
   - 所有接口都需要在请求头中携带有效的JWT Token
   - Token格式：`Authorization: Bearer {accessToken}`

8. **消息通知机制**：
   - 筛查创建时自动通知关联的CRC
   - 筛查状态变更时自动通知医生和CRC（不通知操作者自己）
   - 通知类型：
     - `SCREENING_CREATED`：筛查创建通知
     - `SCREENING_STATUS_CHANGED`：筛查状态变更通知
   - 通知可通过消息中心API查询（参见 MESSAGE_INBOX_API.md）
   - 通知内容包含：筛查ID、项目ID、患者信息、状态代码等

---

## 完整工作流程示例

### Flutter 完整示例代码

```dart
class ScreeningService {
  final String baseUrl = 'http://localhost:8090/api/v1';
  String? accessToken;

  void setToken(String token) {
    accessToken = token;
  }

  // 提交初筛
  Future<int> submitScreening({
    required int projectId,
    required String patientInNo,
    required String patientNameAbbr,
    required List<Map<String, dynamic>> criteriaMatches,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/screenings'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken'
      },
      body: jsonEncode({
        'projectId': projectId,
        'patientInNo': patientInNo,
        'patientNameAbbr': patientNameAbbr,
        'criteriaMatches': criteriaMatches,
      }),
    );

    final result = jsonDecode(response.body);
    if (result['success']) {
      return result['data'];
    }
    throw Exception(result['message']);
  }

  // 查询我的筛查列表
  Future<Map<String, dynamic>> getMyScreenings({
    int page = 1,
    int size = 20,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/screenings/my?page=$page&size=$size'),
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

  // 查询筛查详情
  Future<Map<String, dynamic>> getScreeningDetail(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/screenings/$id'),
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

  // 更新筛查状态（CRC端）
  Future<void> updateScreeningStatus({
    required int id,
    required String status,
    int? failReasonDictId,
    String? failRemark,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/screenings/$id/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken'
      },
      body: jsonEncode({
        'status': status,
        'failReasonDictId': failReasonDictId,
        'failRemark': failRemark,
      }),
    );

    final result = jsonDecode(response.body);
    if (!result['success']) {
      throw Exception(result['message']);
    }
  }

  // 提交知情同意（CRC端）
  Future<void> submitIcf({
    required int screeningId,
    required String icfVersion,
    required String icfDate,
    required String signerName,
    List<int>? fileIds,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/screenings/$screeningId/icf'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken'
      },
      body: jsonEncode({
        'icfVersion': icfVersion,
        'icfDate': icfDate,
        'signerName': signerName,
        'fileIds': fileIds,
      }),
    );

    final result = jsonDecode(response.body);
    if (!result['success']) {
      throw Exception(result['message']);
    }
  }

  // 提交入组信息
  Future<void> submitEnrollment({
    required int screeningId,
    required String enrollNo,
    required String enrollDate,
    String? firstDoseDate,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/screenings/$screeningId/enrollment'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken'
      },
      body: jsonEncode({
        'enrollNo': enrollNo,
        'enrollDate': enrollDate,
        'firstDoseDate': firstDoseDate,
      }),
    );

    final result = jsonDecode(response.body);
    if (!result['success']) {
      throw Exception(result['message']);
    }
  }

  // 标记出组
  Future<void> markAsExited(int screeningId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/screenings/$screeningId/exit'),
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

  // 查询状态流转历史
  Future<List<Map<String, dynamic>>> getStatusHistory(int screeningId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/screenings/$screeningId/status-log'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken'
      },
    );

    final result = jsonDecode(response.body);
    if (result['success']) {
      return List<Map<String, dynamic>>.from(result['data']);
    }
    throw Exception(result['message']);
  }
}

// 使用示例
void main() async {
  final screeningService = ScreeningService();
  screeningService.setToken('your_access_token_here');

  // 医生提交初筛
  final screeningId = await screeningService.submitScreening(
    projectId: 1,
    patientInNo: '202501001',
    patientNameAbbr: '张**',
    criteriaMatches: [
      {'criteriaId': 1, 'matchResult': 'MATCH', 'remark': '符合年龄要求'},
      {'criteriaId': 2, 'matchResult': 'MATCH', 'remark': '确诊肺癌'},
    ],
  );
  print('筛查ID: $screeningId');

  // 查询我的筛查列表
  final myScreenings = await screeningService.getMyScreenings(page: 1);
  print('我的筛查: ${myScreenings['total']} 条');

  // CRC提交知情同意
  await screeningService.submitIcf(
    screeningId: screeningId,
    icfVersion: 'V1.2',
    icfDate: '2025-10-19',
    signerName: '张某某',
  );
  print('知情同意提交成功');

  // 提交入组
  await screeningService.submitEnrollment(
    screeningId: screeningId,
    enrollNo: '2025-001-001',
    enrollDate: '2025-10-20',
  );
  print('入组成功');
}
```

### 消息通知流程说明

在整个筛查流程中，系统会自动发送消息通知给相关人员：

1. **医生提交初筛**
   - 系统自动通知：项目的CRC
   - 通知类型：`SCREENING_CREATED`
   - 通知内容："提交了初筛"

2. **CRC更新筛查状态**
   - 系统自动通知：医生和CRC（不通知操作者自己）
   - 通知类型：`SCREENING_STATUS_CHANGED`
   - 通知内容："将筛查状态更新为：XXX"

3. **CRC提交知情同意书**
   - 系统自动通知：医生和CRC（不通知操作者自己）
   - 通知类型：`SCREENING_STATUS_CHANGED`
   - 通知内容："提交了知情同意书"

4. **CRC提交入组信息**
   - 系统自动通知：医生和CRC（不通知操作者自己）
   - 通知类型：`SCREENING_STATUS_CHANGED`
   - 通知内容："完成了受试者入组"

5. **CRC标记出组**
   - 系统自动通知：医生和CRC（不通知操作者自己）
   - 通知类型：`SCREENING_STATUS_CHANGED`
   - 通知内容："标记受试者已出组"

**查询消息通知**：

用户可以通过消息中心API查询未读消息和消息详情（详见 `MESSAGE_INBOX_API.md`）：

```dart
// 获取未读消息数量
GET /api/v1/messages/unread-count

// 获取未读消息列表
GET /api/v1/messages/unread?page=1&size=20

// 获取消息详情（自动标记为已读）
GET /api/v1/messages/{id}
```

---

## 更新日志

- **2025-10-19**: 初始版本，实现完整的临床试验筛查流程
  - 医生端：提交初筛、查询我的筛查、查询详情
  - CRC端：查询所有筛查、更新状态、提交知情同意
  - 入组出组：提交入组、标记出组、查询状态历史
  - 支持完整的状态流转和日志记录

