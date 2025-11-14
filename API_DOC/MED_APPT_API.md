# 用药预约 API 文档

## 概述

本文档描述了用药预约模块的API接口，包括：

1. **创建用药预约**：医生录入患者的用药计划信息
2. **查询周预约列表**：护士/医生查看某周（周一到周日）的用药排班
3. **查询月份预约日期**：查询指定月份中有预约的日期列表，用于日历组件标注
4. **确认用药预约**：护士确认预约安排

### 业务场景

- **医生端**：在APP中录入某患者的用药预约信息，包括项目、日期、时段、用药等
- **护士端**：在APP中通过日历选择某一天，查看该天所在周的所有用药预约，用于线下排班

### 权限说明

- 所有接口需要JWT认证
- 数据按**组织维度进行隔离**，用户只能操作本组织的数据
- 医生和护士都可以查看本组织的所有预约

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

---

## API 接口详情

### 1. 创建用药预约

**接口描述**: 医生在APP中录入患者的用药预约信息，包括项目、患者、日期、时段、用药明细等

- **URL**: `/api/v1/med-appt`
- **方法**: `POST`
- **认证**: 需要认证（Bearer Token）

#### 请求参数

请求体（JSON格式）：

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| projectId | Long | 是 | 项目ID（临床试验项目） |
| patientInNo | String | 是 | 患者住院号 |
| patientName | String | 是 | 患者姓名 |
| patientNameAbbr | String | 否 | 患者姓名简称/拼音 |
| planDate | String | 是 | 计划用药日期（格式：yyyy-MM-dd，建议默认为下周一） |
| timeSlot | String | 是 | 时段：AM（上午）/PM（下午）/EVE（晚上） |
| durationMinutes | Integer | 是 | 用药时长（分钟，大于0） |
| coreValidHours | Integer | 否 | 核心药物配制后有效时长（小时） |
| drugText | String | 是 | 具体用药（自由文本） |
| note | String | 否 | 备注 |

**说明**：
- 医生人员ID自动从当前登录用户获取，无需前端传入
- CRC人员ID和护士人员ID已移除，不再使用

#### 请求头

```
Authorization: Bearer {accessToken}
Content-Type: application/json
```

#### 请求示例

```json
{
  "projectId": 12,
  "patientInNo": "H20240001",
  "patientName": "张**",
  "patientNameAbbr": "张某",
  "planDate": "2024-11-18",
  "timeSlot": "AM",
  "durationMinutes": 120,
  "coreValidHours": 24,
  "drugText": "JMT103+唑来膦酸",
  "note": "无输液器"
}
```

#### cURL示例

```bash
curl -X POST 'http://localhost:8090/api/v1/med-appt' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer YOUR_ACCESS_TOKEN' \
  -d '{
    "projectId": 12,
    "patientInNo": "H20240001",
    "patientName": "张**",
    "planDate": "2024-11-18",
    "timeSlot": "AM",
    "durationMinutes": 120,
    "drugText": "JMT103+唑来膦酸"
  }'
```

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

**说明**: `data` 字段返回新建记录的ID

**失败响应 - 参数验证失败 (200)**:
```json
{
  "success": false,
  "code": "INVALID_PARAMETER",
  "message": "患者住院号不能为空",
  "data": null
}
```

**失败响应 - 用户未关联人员信息 (200)**:
```json
{
  "success": false,
  "code": "PERSON_ID_NOT_FOUND",
  "message": "当前用户未关联人员信息，无法创建用药预约",
  "data": null
}
```

**失败响应 - 项目不存在 (200)**:
```json
{
  "success": false,
  "code": "PROJECT_NOT_FOUND",
  "message": "项目不存在或无权访问",
  "data": null
}
```

**失败响应 - 时段格式错误 (200)**:
```json
{
  "success": false,
  "code": "INVALID_PARAMETER",
  "message": "时段必须为AM、PM或EVE",
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
Future<int?> createMedAppt({
  required int projectId,
  required String patientInNo,
  required String patientName,
  required String planDate,
  required String timeSlot,
  required int durationMinutes,
  required String drugText,
  String? patientNameAbbr,
  int? coreValidHours,
  String? note,
}) async {
  final response = await http.post(
    Uri.parse('http://localhost:8090/api/v1/med-appt'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken'
    },
    body: jsonEncode({
      'projectId': projectId,
      'patientInNo': patientInNo,
      'patientName': patientName,
      'patientNameAbbr': patientNameAbbr,
      'planDate': planDate,
      'timeSlot': timeSlot,
      'durationMinutes': durationMinutes,
      'coreValidHours': coreValidHours,
      'drugText': drugText,
      'note': note,
    }),
  );

  final result = jsonDecode(response.body);
  if (result['success']) {
    print('用药预约创建成功，ID: ${result['data']}');
    return result['data'] as int;
  } else {
    print('创建失败: ${result['message']}');
    return null;
  }
}
```

#### 业务说明

1. **医生ID自动获取**：医生人员ID自动从当前登录用户的 `person_id` 获取，无需前端传入
2. **用户验证**：如果当前用户未关联人员信息（`person_id` 为空），会返回错误提示
3. **日期选择**：建议APP在录入时，默认填写下周一的日期
4. **状态自动设置**：创建时状态自动设置为 `PENDING`（待确认）
5. **来源标记**：自动标记来源为 `APP`
6. **项目验证**：系统会验证项目是否存在且属于当前用户的组织
7. **周一计算**：数据库会自动计算 `plan_week_monday` 字段（该日期所在周的周一）
8. **CRC和护士字段**：CRC人员ID和护士人员ID已移除，不再使用

---

### 2. 查询周预约列表

**接口描述**: 根据指定日期查询该日期所在周（周一到周日）的所有用药预约，支持分页

- **URL**: `/api/v1/med-appt/week`
- **方法**: `GET`
- **认证**: 需要认证（Bearer Token）

#### 请求参数

查询参数（Query Parameters）：

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| date | String | 是 | - | 查询日期（格式：yyyy-MM-dd），系统会自动计算该日期所在周的周一 |
| page | Integer | 否 | 1 | 页码，从1开始 |
| size | Integer | 否 | 20 | 每页大小，最大100 |

#### 请求头

```
Authorization: Bearer {accessToken}
Content-Type: application/json
```

#### 请求示例

```http
GET /api/v1/med-appt/week?date=2024-11-18&page=1&size=20 HTTP/1.1
Host: localhost:8090
Content-Type: application/json
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

#### cURL示例

```bash
curl -X GET 'http://localhost:8090/api/v1/med-appt/week?date=2024-11-18&page=1&size=20' \
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
        "orgId": 1,
        "projectId": 12,
        "projName": "非小细胞肺癌一线治疗研究",
        "patientInNo": "H20240001",
        "patientName": "张**",
        "patientNameAbbr": "张某",
        "researcherPersonId": "abc123def456",
        "researcherName": "孟祥丽",
        "crcPersonId": "def456ghi789",
        "crcName": "李爱云",
        "nursePersonId": "ghi789jkl012",
        "nurseName": "王明新",
        "planDate": "2024-11-18",
        "planWeekMonday": "2024-11-18",
        "timeSlot": "AM",
        "durationMinutes": 120,
        "coreValidHours": 24,
        "drugText": "JMT103+唑来膦酸",
        "note": "无输液器",
        "status": "PENDING",
        "source": "APP",
        "createdBy": 1,
        "createdAt": "2024-11-09T10:30:00",
        "updatedBy": null,
        "updatedAt": "2024-11-09T10:30:00"
      },
      {
        "id": 2,
        "orgId": 1,
        "projectId": 15,
        "projName": "JS212临床研究",
        "patientInNo": "H20240002",
        "patientName": "李**",
        "patientNameAbbr": "李某",
        "researcherPersonId": "xyz789abc123",
        "researcherName": "申威",
        "crcPersonId": "def456ghi789",
        "crcName": "李爱云",
        "nursePersonId": null,
        "nurseName": null,
        "planDate": "2024-11-18",
        "planWeekMonday": "2024-11-18",
        "timeSlot": "PM",
        "durationMinutes": 240,
        "coreValidHours": 4,
        "drugText": "JS212",
        "note": null,
        "status": "CONFIRMED",
        "source": "APP",
        "createdBy": 2,
        "createdAt": "2024-11-08T14:20:00",
        "updatedBy": 2,
        "updatedAt": "2024-11-09T09:15:00"
      },
      {
        "id": 3,
        "orgId": 1,
        "projectId": 20,
        "projName": "BAT8008研究",
        "patientInNo": "H20240003",
        "patientName": "王**",
        "patientNameAbbr": "王某",
        "researcherPersonId": "xyz789abc123",
        "researcherName": "申威",
        "crcPersonId": "aaa111bbb222",
        "crcName": "李娜",
        "nursePersonId": "ghi789jkl012",
        "nurseName": "王明新",
        "planDate": "2024-11-19",
        "planWeekMonday": "2024-11-18",
        "timeSlot": "AM",
        "durationMinutes": 30,
        "coreValidHours": 6,
        "drugText": "BAT8008",
        "note": "有输液器",
        "status": "PENDING",
        "source": "APP",
        "createdBy": 2,
        "createdAt": "2024-11-09T11:00:00",
        "updatedBy": null,
        "updatedAt": "2024-11-09T11:00:00"
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

**失败响应 - 日期格式错误 (200)**:
```json
{
  "success": false,
  "code": "INVALID_PARAMETER",
  "message": "日期格式错误，请使用yyyy-MM-dd格式",
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
Future<List<MedAppt>?> getWeekAppointments({
  required String date,
  int page = 1,
  int size = 20,
}) async {
  final queryParams = {
    'date': date,
    'page': page.toString(),
    'size': size.toString(),
  };
  
  final uri = Uri.parse('http://localhost:8090/api/v1/med-appt/week')
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
    final data = result['data']['data'] as List;
    return data.map((item) => MedAppt.fromJson(item)).toList();
  } else {
    print('查询失败: ${result['message']}');
    return null;
  }
}

// 数据模型类
class MedAppt {
  final int id;
  final int projectId;
  final String projName;
  final String patientInNo;
  final String patientName;
  final String? patientNameAbbr;
  final String researcherName;
  final String? crcName;
  final String? nurseName;
  final String planDate;
  final String timeSlot;
  final int durationMinutes;
  final int? coreValidHours;
  final String drugText;
  final String? note;
  final String status;

  MedAppt({
    required this.id,
    required this.projectId,
    required this.projName,
    required this.patientInNo,
    required this.patientName,
    this.patientNameAbbr,
    required this.researcherName,
    this.crcName,
    this.nurseName,
    required this.planDate,
    required this.timeSlot,
    required this.durationMinutes,
    this.coreValidHours,
    required this.drugText,
    this.note,
    required this.status,
  });

  factory MedAppt.fromJson(Map<String, dynamic> json) {
    return MedAppt(
      id: json['id'],
      projectId: json['projectId'],
      projName: json['projName'],
      patientInNo: json['patientInNo'],
      patientName: json['patientName'],
      patientNameAbbr: json['patientNameAbbr'],
      researcherName: json['researcherName'],
      crcName: json['crcName'],
      nurseName: json['nurseName'],
      planDate: json['planDate'],
      timeSlot: json['timeSlot'],
      durationMinutes: json['durationMinutes'],
      coreValidHours: json['coreValidHours'],
      drugText: json['drugText'],
      note: json['note'],
      status: json['status'],
    );
  }
}
```

#### 业务说明

1. **周一自动计算**：传入任意日期（如2024-11-20 周三），系统会自动计算该周的周一（2024-11-18），并查询该周一到周日的所有预约
2. **排序规则**：结果按 `日期升序 + 时段（AM→PM→EVE）` 排序，方便护士按顺序查看
3. **扩展字段**：响应中包含项目名称、医生/CRC/护士姓名，无需再次查询
4. **状态说明**：
   - `PENDING`: 待确认
   - `CONFIRMED`: 已确认
   - `CANCELLED`: 已取消
   - `DONE`: 已完成

---

## 数据字典

### 时段 (timeSlot)

| 值 | 说明 |
|----|------|
| AM | 上午 |
| PM | 下午 |
| EVE | 晚上 |

### 预约状态 (status)

| 值 | 说明 |
|----|------|
| PENDING | 待确认 |
| CONFIRMED | 已确认 |
| CANCELLED | 已取消 |
| DONE | 已完成 |

### 来源 (source)

| 值 | 说明 |
|----|------|
| APP | 移动端 |
| WEB | 网页端 |
| IMPORT | 导入 |

---

### 3. 查询月份预约日期

**接口描述**: 查询指定月份中有预约的日期列表，用于APP日历组件标注有预约的日期

- **URL**: `/api/v1/med-appt/month-dates`
- **方法**: `GET`
- **认证**: 需要认证（Bearer Token）

#### 请求参数

查询参数（Query Parameters）：

| 参数名 | 类型   | 必填 | 说明                                    |
|--------|--------|------|-----------------------------------------|
| month  | String | 是   | 月份（格式：yyyy-MM，如：2025-11）     |

#### 请求头

```
Authorization: Bearer {accessToken}
Content-Type: application/json
```

#### 请求示例

```http
GET /api/v1/med-appt/month-dates?month=2025-11 HTTP/1.1
Host: localhost:8090
Content-Type: application/json
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

#### cURL示例

```bash
curl -X GET 'http://localhost:8090/api/v1/med-appt/month-dates?month=2025-11' \
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
    "month": "2025-11",
    "dates": [
      "2025-11-01",
      "2025-11-05",
      "2025-11-15",
      "2025-11-20",
      "2025-11-25"
    ]
  }
}
```

**响应字段说明**:

| 字段名 | 类型           | 说明                                    |
|--------|----------------|-----------------------------------------|
| month  | String         | 查询的月份（格式：yyyy-MM）             |
| dates  | Array<String>  | 该月中有预约的日期列表（格式：yyyy-MM-dd），按日期升序排列 |

**说明**:
- `dates` 数组中的日期已去重，每个日期只出现一次
- 如果该月没有任何预约，`dates` 为空数组 `[]`
- 日期格式统一为 `yyyy-MM-dd`，便于前端直接使用

**失败响应 - 月份格式错误 (200)**:
```json
{
  "success": false,
  "code": "INVALID_MONTH_FORMAT",
  "message": "月份格式不正确，应为 yyyy-MM 格式，如：2025-11",
  "data": null
}
```

**失败响应 - 月份范围错误 (200)**:
```json
{
  "success": false,
  "code": "INVALID_MONTH",
  "message": "月份必须在 1-12 之间",
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
Future<List<String>?> getMonthDates(String month) async {
  final uri = Uri.parse('http://localhost:8090/api/v1/med-appt/month-dates')
      .replace(queryParameters: {'month': month});
  
  final response = await http.get(
    uri,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken'
    },
  );

  final result = jsonDecode(response.body);
  if (result['success']) {
    final data = result['data'];
    print('${data['month']} 月有预约的日期: ${data['dates']}');
    return List<String>.from(data['dates']);
  } else {
    print('查询失败: ${result['message']}');
    return null;
  }
}

// 使用示例：在日历组件中标注有预约的日期
void markAppointmentDates() async {
  String currentMonth = '2025-11'; // 当前月份
  List<String>? dates = await getMonthDates(currentMonth);
  
  if (dates != null) {
    // 在日历组件中标注这些日期
    for (String date in dates) {
      // 例如：calendarWidget.markDate(date, hasAppointment: true);
      print('日期 $date 有预约');
    }
  }
}
```

#### JavaScript 调用示例

```javascript
async function getMonthDates(month) {
  try {
    const response = await fetch(
      `http://localhost:8090/api/v1/med-appt/month-dates?month=${month}`,
      {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${accessToken}`
        }
      }
    );
    
    const result = await response.json();
    if (result.success) {
      console.log(`${result.data.month} 月有预约的日期:`, result.data.dates);
      return result.data.dates;
    } else {
      console.error('查询失败:', result.message);
      return null;
    }
  } catch (error) {
    console.error('请求失败:', error);
    return null;
  }
}

// 使用示例
async function markCalendarDates() {
  const currentMonth = '2025-11';
  const dates = await getMonthDates(currentMonth);
  
  if (dates) {
    // 在日历组件中标注这些日期
    dates.forEach(date => {
      console.log(`日期 ${date} 有预约`);
      // 例如：calendar.markDate(date, { hasAppointment: true });
    });
  }
}
```

#### 业务说明

1. **用途**：主要用于APP日历组件，快速获取某个月份中哪些日期有预约，方便在日历上标注原点或特殊标记
2. **性能优化**：只返回日期列表，不返回完整的预约详情，减少数据传输量
3. **去重处理**：如果某一天有多个预约，该日期在结果中只出现一次
4. **排序**：日期列表按日期升序排列，便于前端处理
5. **组织隔离**：自动根据当前用户的组织ID过滤数据，只能查询本组织的预约
6. **空结果处理**：如果该月没有任何预约，返回空数组，前端应正常处理

---

### 4. 确认用药预约

**接口描述**: 护士确认用药预约安排，将预约状态从PENDING（待确认）更新为CONFIRMED（已确认）

- **URL**: `/api/v1/med-appt/{id}/confirm`
- **方法**: `PUT`
- **认证**: 需要认证（Bearer Token）

#### 请求参数

路径参数：

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| id | Long | 是 | 用药预约ID |

#### 请求头

```
Authorization: Bearer {accessToken}
Content-Type: application/json
```

#### 请求示例

```http
PUT /api/v1/med-appt/123/confirm HTTP/1.1
Host: localhost:8090
Content-Type: application/json
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

#### cURL示例

```bash
curl -X PUT 'http://localhost:8090/api/v1/med-appt/123/confirm' \
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
  "data": null
}
```

**失败响应 - 预约不存在 (200)**:
```json
{
  "success": false,
  "code": "APPT_NOT_FOUND",
  "message": "用药预约不存在",
  "data": null
}
```

**失败响应 - 无权操作 (200)**:
```json
{
  "success": false,
  "code": "APPT_NO_PERMISSION",
  "message": "无权操作该用药预约",
  "data": null
}
```

**失败响应 - 更新失败 (200)**:
```json
{
  "success": false,
  "code": "APPT_UPDATE_FAILED",
  "message": "更新预约状态失败",
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
Future<bool> confirmMedAppt(int apptId) async {
  final response = await http.put(
    Uri.parse('http://localhost:8090/api/v1/med-appt/$apptId/confirm'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken'
    },
  );

  final result = jsonDecode(response.body);
  if (result['success']) {
    print('用药预约确认成功');
    return true;
  } else {
    print('确认失败: ${result['message']}');
    return false;
  }
}
```

#### 业务说明

1. **状态更新**：将预约状态从 `PENDING` 更新为 `CONFIRMED`
2. **权限验证**：只能确认本组织的预约，防止跨组织操作
3. **记录更新人**：自动记录当前操作用户和更新时间
4. **幂等操作**：重复确认同一个预约不会报错，状态保持为 `CONFIRMED`

---

## 常见问题

### Q1: 如何获取下周一的日期？

**答**: 在Flutter中可以使用以下代码：

```dart
DateTime getNextMonday() {
  final now = DateTime.now();
  // 计算距离下周一的天数
  int daysUntilNextMonday = DateTime.monday - now.weekday + 7;
  if (daysUntilNextMonday == 7) {
    daysUntilNextMonday = 7; // 如果今天是周一，也返回下周一
  }
  final nextMonday = now.add(Duration(days: daysUntilNextMonday));
  return DateTime(nextMonday.year, nextMonday.month, nextMonday.day);
}

// 格式化为 yyyy-MM-dd
String formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

// 使用示例
final nextMondayStr = formatDate(getNextMonday());
print(nextMondayStr); // 输出: 2024-11-18
```

### Q2: 如何在日历组件中点击某一天后查询该周的预约？

**答**: 

```dart
// 假设用户在日历上点击了某一天
void onDateSelected(DateTime selectedDate) {
  // 格式化选中的日期
  final dateStr = formatDate(selectedDate);
  
  // 调用API查询该周的预约
  getWeekAppointments(date: dateStr).then((appointments) {
    if (appointments != null) {
      setState(() {
        _weekAppointments = appointments;
      });
    }
  });
}
```

### Q3: 如何实现项目选择页面？

**答**: 可以复用现有的项目搜索接口：

```dart
// 跳转到项目选择页面
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ProjectSelectionPage(
      onProjectSelected: (project) {
        // 用户选择项目后的回调
        setState(() {
          selectedProjectId = project.id;
          selectedProjectName = project.projName;
        });
      },
    ),
  ),
);
```

在项目选择页面中，使用项目搜索接口 `/api/v1/projects/search` 来搜索和选择项目。

### Q4: 列表如何按日期分组显示？

**答**: 在Flutter中可以这样处理：

```dart
// 按日期分组
Map<String, List<MedAppt>> groupByDate(List<MedAppt> appointments) {
  final grouped = <String, List<MedAppt>>{};
  for (var appt in appointments) {
    if (!grouped.containsKey(appt.planDate)) {
      grouped[appt.planDate] = [];
    }
    grouped[appt.planDate]!.add(appt);
  }
  return grouped;
}

// 在UI中展示
final groupedAppts = groupByDate(_weekAppointments);
ListView.builder(
  itemCount: groupedAppts.length,
  itemBuilder: (context, index) {
    final date = groupedAppts.keys.elementAt(index);
    final appointments = groupedAppts[date]!;
    
    return Column(
      children: [
        // 日期标题
        Text(date, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        // 该日期的预约列表
        ...appointments.map((appt) => AppointmentCard(appt)).toList(),
      ],
    );
  },
);
```

---

## 错误码说明

| 错误码 | 说明 | 处理建议 |
|--------|------|----------|
| SUCCESS | 成功 | - |
| INVALID_PARAMETER | 参数验证失败 | 检查请求参数格式和必填项 |
| PERSON_ID_NOT_FOUND | 用户未关联人员信息 | 确保当前登录用户已关联人员信息（person_id不为空） |
| USER_NOT_FOUND | 用户不存在 | 检查Token是否有效，用户是否存在 |
| PROJECT_NOT_FOUND | 项目不存在或无权访问 | 验证项目ID是否正确，是否属于当前组织 |
| APPT_NOT_FOUND | 用药预约不存在 | 检查预约ID是否正确 |
| APPT_NO_PERMISSION | 无权操作该用药预约 | 只能操作本组织的预约 |
| APPT_UPDATE_FAILED | 更新预约状态失败 | 检查预约是否存在，或联系技术支持 |
| INVALID_MONTH_FORMAT | 月份格式不正确 | 月份格式应为 yyyy-MM，如：2025-11 |
| INVALID_MONTH | 月份范围错误 | 月份必须在 1-12 之间 |
| UNAUTHORIZED | 未登录或Token过期 | 重新登录获取新Token |
| INTERNAL_ERROR | 服务器内部错误 | 联系技术支持 |

---

## 版本历史

| 版本 | 日期 | 说明 |
|------|------|------|
| v1.3 | 2024-11-12 | 新增查询月份预约日期接口，用于日历组件标注 |
| v1.2 | 2024-11-09 | 新增确认用药预约接口 |
| v1.1 | 2024-11-09 | 简化接口：医生ID自动从当前用户获取，移除CRC和护士字段 |
| v1.0 | 2024-11-09 | 初始版本，包含创建预约和查询周预约列表功能 |

