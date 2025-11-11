# 通讯录 API 文档

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

## 通讯录接口

### 1. 获取通讯录列表（按首字母分组）

**接口描述**: 查询当前用户组织下的所有人员和联系人，按姓名首字母分组返回，支持右侧字母索引快速定位功能

- **URL**: `/api/v1/address-book`
- **方法**: `GET`
- **认证**: 需要认证（Bearer Token）

#### 请求参数

无需请求参数

#### 请求头

```
Authorization: Bearer {accessToken}
```

#### 功能特点

1. **按首字母分组**：将所有人员按姓名首字母（A-Z和#）分组
2. **字母索引支持**：前端可以实现右侧字母条快速定位
3. **排序规则**：
   - 首字母 A-Z 按字母顺序排列
   - # 组（特殊字符或数字开头）排在最后
   - 每组内按姓名拼音排序
4. **角色翻译**：自动将角色代码翻译为中文名称
5. **数据来源**：整合人员表（t_person）和联系人表（t_contact）

#### 响应示例

**成功响应 (200)**:
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": [
    {
      "initial": "A",
      "items": [
        {
          "pk": "abc123",
          "userId": 5,
          "name": "安娜",
          "nameInitial": "A",
          "phone": "13800138001",
          "email": "anna@example.com",
          "roleCode": "CRC",
          "roleName": "临床研究协调员",
          "affiliationType": "HOSPITAL",
          "avatar": "https://example.com/avatar/anna.jpg",
          "srcType": "PERSON"
        },
        {
          "pk": "abc124",
          "userId": 8,
          "name": "安迪",
          "nameInitial": "A",
          "phone": "13800138002",
          "email": null,
          "roleCode": "PI",
          "roleName": "主要研究者",
          "affiliationType": "HOSPITAL",
          "avatar": null,
          "srcType": "PERSON"
        }
      ]
    },
    {
      "initial": "Z",
      "items": [
        {
          "pk": "xyz789",
          "userId": 12,
          "name": "张三",
          "nameInitial": "Z",
          "phone": "13900139002",
          "email": null,
          "roleCode": "PI",
          "roleName": "主要研究者",
          "affiliationType": "HOSPITAL",
          "avatar": null,
          "srcType": "PERSON"
        },
        {
          "pk": "xyz790",
          "userId": 15,
          "name": "赵丽",
          "nameInitial": "Z",
          "phone": "13900139003",
          "email": "zhaoli@example.com",
          "roleCode": "CRC",
          "roleName": "临床研究协调员",
          "affiliationType": "HOSPITAL",
          "avatar": "https://example.com/avatar/zhaoli.jpg",
          "srcType": "PERSON"
        }
      ]
    },
    {
      "initial": "#",
      "items": [
        {
          "pk": "999",
          "userId": null,
          "name": "123医疗公司",
          "nameInitial": "#",
          "phone": "400-123-4567",
          "email": "contact@123medical.com",
          "roleCode": null,
          "roleName": "",
          "affiliationType": null,
          "avatar": null,
          "srcType": "CONTACT"
        }
      ]
    }
  ]
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

**分组对象（AddressBookGroupVO）**:

| 字段名 | 类型 | 说明 |
|--------|------|------|
| initial | String | 首字母（A-Z或#） |
| items | Array | 该字母下的人员列表 |

**人员对象（AddressBookItemVO）**:

| 字段名 | 类型 | 说明 |
|--------|------|------|
| pk | String | 主键ID（人员UUID或联系人ID） |
| userId | Long | 用户ID（t_user.id），用于IM单聊，联系人类型为null |
| name | String | 姓名 |
| nameInitial | String | 姓名首字母（A-Z或#） |
| phone | String | 手机号 |
| email | String | 邮箱（可能为null） |
| roleCode | String | 角色代码（如CRC、PI等，联系人可能为null） |
| roleName | String | 角色中文名称（如"临床研究协调员"） |
| affiliationType | String | 归属类型（HOSPITAL/CRO/SPONSOR，联系人可能为null） |
| avatar | String | 头像URL（可能为null） |
| srcType | String | 来源类型（PERSON-人员表，CONTACT-联系人表） |

#### Flutter 调用示例

```dart
Future<List<AddressBookGroup>> getAddressBook() async {
  final response = await http.get(
    Uri.parse('http://localhost:8090/api/v1/address-book'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken'
    },
  );

  final result = jsonDecode(response.body);
  if (result['success']) {
    final data = result['data'] as List;
    return data.map((group) => AddressBookGroup.fromJson(group)).toList();
  } else {
    throw Exception(result['message']);
  }
}

// 数据模型
class AddressBookGroup {
  final String initial;
  final List<AddressBookItem> items;

  AddressBookGroup({required this.initial, required this.items});

  factory AddressBookGroup.fromJson(Map<String, dynamic> json) {
    return AddressBookGroup(
      initial: json['initial'],
      items: (json['items'] as List)
          .map((item) => AddressBookItem.fromJson(item))
          .toList(),
    );
  }
}

class AddressBookItem {
  final String pk;
  final int? userId;  // 用户ID，用于IM单聊（联系人为null）
  final String name;
  final String nameInitial;
  final String phone;
  final String? email;
  final String? roleCode;
  final String? roleName;
  final String? affiliationType;
  final String? avatar;
  final String srcType;

  AddressBookItem({
    required this.pk,
    this.userId,
    required this.name,
    required this.nameInitial,
    required this.phone,
    this.email,
    this.roleCode,
    this.roleName,
    this.affiliationType,
    this.avatar,
    required this.srcType,
  });

  factory AddressBookItem.fromJson(Map<String, dynamic> json) {
    return AddressBookItem(
      pk: json['pk'],
      userId: json['userId'],
      name: json['name'],
      nameInitial: json['nameInitial'],
      phone: json['phone'],
      email: json['email'],
      roleCode: json['roleCode'],
      roleName: json['roleName'],
      affiliationType: json['affiliationType'],
      avatar: json['avatar'],
      srcType: json['srcType'],
    );
  }
}
```

---

### 2. 搜索通讯录

**接口描述**: 根据关键词搜索通讯录，支持姓名、手机号、角色代码的模糊匹配

- **URL**: `/api/v1/address-book/search`
- **方法**: `GET`
- **认证**: 需要认证（Bearer Token）

#### 请求参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| keyword | String | 是 | 搜索关键词 |

#### 请求头

```
Authorization: Bearer {accessToken}
```

#### 功能特点

1. **多字段搜索**：同时搜索姓名、手机号、角色代码
2. **模糊匹配**：支持部分匹配（如搜索"张"可以找到"张三"、"张丽"等）
3. **OR逻辑**：三个字段之间是OR关系，满足任一条件即可
4. **排序规则**：结果按姓名拼音排序

#### 搜索示例

- 按姓名搜索：`keyword=张` → 找到所有姓张的人
- 按手机号搜索：`keyword=138` → 找到所有138开头的手机号
- 按角色搜索：`keyword=CRC` → 找到所有CRC角色的人

#### 响应示例

**成功响应 (200)**:
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": [
    {
      "pk": "xyz789",
      "userId": 12,
      "name": "张三",
      "nameInitial": "Z",
      "phone": "13900139002",
      "email": null,
      "roleCode": "PI",
      "roleName": "主要研究者",
      "affiliationType": "HOSPITAL",
      "avatar": null,
      "srcType": "PERSON"
    },
    {
      "pk": "xyz790",
      "userId": 15,
      "name": "张丽",
      "nameInitial": "Z",
      "phone": "13800138003",
      "email": "zhangli@example.com",
      "roleCode": "CRC",
      "roleName": "临床研究协调员",
      "affiliationType": "HOSPITAL",
      "avatar": "https://example.com/avatar/zhangli.jpg",
      "srcType": "PERSON"
    }
  ]
}
```

**成功响应 - 无结果 (200)**:
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": []
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
Future<List<AddressBookItem>> searchAddressBook(String keyword) async {
  final response = await http.get(
    Uri.parse('http://localhost:8090/api/v1/address-book/search?keyword=${Uri.encodeComponent(keyword)}'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken'
    },
  );

  final result = jsonDecode(response.body);
  if (result['success']) {
    final data = result['data'] as List;
    return data.map((item) => AddressBookItem.fromJson(item)).toList();
  } else {
    throw Exception(result['message']);
  }
}

// 使用示例
void onSearchChanged(String keyword) async {
  if (keyword.isEmpty) {
    // 清空搜索，显示完整列表
    await loadAddressBook();
  } else {
    // 执行搜索
    final results = await searchAddressBook(keyword);
    setState(() {
      _searchResults = results;
    });
  }
}
```

---

### 3. 患者倒查CRC

**接口描述**: 通过患者姓名简称或住院号反查负责该患者的CRC通讯录信息

- **URL**: `/api/v1/address-book/lookup-crc`
- **方法**: `GET`
- **认证**: 需要认证（Bearer Token）

#### 请求参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| keyword | String | 是 | 患者姓名简称或住院号 |

#### 请求头

```
Authorization: Bearer {accessToken}
```

#### 功能特点

1. **倒查功能**：通过患者信息查询负责的CRC
2. **自动去重**：同一个CRC只返回一次（即使负责多个项目）
3. **标准格式**：返回通讯录格式，前端可以统一处理
4. **快速联系**：可以直接拨打电话或发送消息

#### 使用场景

- 医生想知道某个患者由哪个CRC负责
- 需要快速联系负责某患者的CRC
- 获取CRC的完整联系方式

#### 响应示例

**成功响应 (200)**:
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": [
    {
      "pk": "abc123",
      "userId": 5,
      "name": "李四",
      "nameInitial": "L",
      "phone": "13700137001",
      "email": "lisi@example.com",
      "roleCode": "CRC",
      "roleName": "临床研究协调员",
      "affiliationType": "HOSPITAL",
      "avatar": "https://example.com/avatar/lisi.jpg",
      "srcType": "PERSON"
    },
    {
      "pk": "def456",
      "userId": 8,
      "name": "王五",
      "nameInitial": "W",
      "phone": "13700137002",
      "email": null,
      "roleCode": "CRC",
      "roleName": "临床研究协调员",
      "affiliationType": "HOSPITAL",
      "avatar": null,
      "srcType": "PERSON"
    }
  ]
}
```

**成功响应 - 无结果 (200)**:
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": []
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

返回的是标准的通讯录人员信息（AddressBookItemVO），与通讯录列表格式完全相同：

| 字段名 | 类型 | 说明 |
|--------|------|------|
| pk | String | CRC人员ID |
| userId | Long | 用户ID（t_user.id），用于IM单聊 |
| name | String | CRC姓名 |
| nameInitial | String | 姓名首字母（A-Z或#） |
| phone | String | 手机号 |
| email | String | 邮箱（可能为null） |
| roleCode | String | 角色代码（通常为CRC） |
| roleName | String | 角色中文名称（临床研究协调员） |
| affiliationType | String | 归属类型（HOSPITAL/CRO/SPONSOR） |
| avatar | String | 头像URL（可能为null） |
| srcType | String | 来源类型（PERSON-人员表） |

#### Flutter 调用示例

```dart
Future<List<AddressBookItem>> lookupCrcByPatient(String keyword) async {
  final response = await http.get(
    Uri.parse('http://localhost:8090/api/v1/address-book/lookup-crc?keyword=${Uri.encodeComponent(keyword)}'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken'
    },
  );

  final result = jsonDecode(response.body);
  if (result['success']) {
    final data = result['data'] as List;
    // 返回的是标准的通讯录格式，可以复用 AddressBookItem 类
    return data.map((item) => AddressBookItem.fromJson(item)).toList();
  } else {
    throw Exception(result['message']);
  }
}

// 使用示例：显示CRC列表
void showCrcList(List<AddressBookItem> crcList) {
  if (crcList.isEmpty) {
    print('未找到负责该患者的CRC');
    return;
  }

  print('负责该患者的CRC：');
  for (var crc in crcList) {
    print('${crc.name} (${crc.roleName})');
    print('电话: ${crc.phone}');
    if (crc.email != null) {
      print('邮箱: ${crc.email}');
    }
    print('---');
  }
}

// 使用示例：直接拨打CRC电话
void callCrc(AddressBookItem crc) {
  // 可以直接使用通讯录格式的数据
  // 调用拨号功能
  launch('tel:${crc.phone}');
}
```

---

## 使用场景说明

### 场景1：通讯录主页面（按字母索引）

实现带右侧字母条的通讯录列表：

```dart
class AddressBookPage extends StatefulWidget {
  @override
  _AddressBookPageState createState() => _AddressBookPageState();
}

class _AddressBookPageState extends State<AddressBookPage> {
  List<AddressBookGroup> _groups = [];
  bool _loading = false;
  
  // 滚动控制器
  ScrollController _scrollController = ScrollController();
  
  // 字母索引位置映射
  Map<String, double> _letterPositions = {};

  @override
  void initState() {
    super.initState();
    _loadAddressBook();
  }

  Future<void> _loadAddressBook() async {
    setState(() {
      _loading = true;
    });

    try {
      final groups = await getAddressBook();
      setState(() {
        _groups = groups;
        _calculateLetterPositions();
      });
    } catch (e) {
      showSnackBar('加载失败: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  // 计算每个字母的滚动位置
  void _calculateLetterPositions() {
    double position = 0;
    for (var group in _groups) {
      _letterPositions[group.initial] = position;
      // 估算高度：标题高度 + 每个item的高度
      position += 40 + (group.items.length * 70);
    }
  }

  // 点击字母索引
  void _scrollToLetter(String letter) {
    final position = _letterPositions[letter];
    if (position != null) {
      _scrollController.animateTo(
        position,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('通讯录'),
      ),
      body: Stack(
        children: [
          // 主列表
          RefreshIndicator(
            onRefresh: _loadAddressBook,
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _groups.length,
              itemBuilder: (context, index) {
                final group = _groups[index];
                return _buildGroup(group);
              },
            ),
          ),
          // 右侧字母索引
          Positioned(
            right: 0,
            top: 100,
            bottom: 100,
            child: _buildLetterIndex(),
          ),
        ],
      ),
    );
  }

  Widget _buildGroup(AddressBookGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 字母标题
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey[200],
          child: Text(
            group.initial,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        // 人员列表
        ...group.items.map((item) => _buildPersonItem(item)).toList(),
      ],
    );
  }

  Widget _buildPersonItem(AddressBookItem item) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: item.avatar != null
            ? NetworkImage(item.avatar!)
            : null,
        child: item.avatar == null
            ? Text(item.nameInitial)
            : null,
      ),
      title: Text(item.name),
      subtitle: Text('${item.roleName ?? ''} ${item.phone}'),
      onTap: () {
        // 拨打电话或查看详情
        _showContactActions(item);
      },
    );
  }

  Widget _buildLetterIndex() {
    final letters = _groups.map((g) => g.initial).toList();
    return Container(
      width: 30,
      child: ListView.builder(
        itemCount: letters.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _scrollToLetter(letters[index]),
            child: Container(
              height: 20,
              alignment: Alignment.center,
              child: Text(
                letters[index],
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showContactActions(AddressBookItem item) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.phone),
              title: Text('拨打电话'),
              onTap: () {
                // 调用拨号功能
                Navigator.pop(context);
              },
            ),
            if (item.email != null)
              ListTile(
                leading: Icon(Icons.email),
                title: Text('发送邮件'),
                onTap: () {
                  // 调用邮件功能
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}
```

### 场景2：通讯录搜索

在通讯录页面添加搜索功能：

```dart
class AddressBookPage extends StatefulWidget {
  // ... 
}

class _AddressBookPageState extends State<AddressBookPage> {
  List<AddressBookGroup> _groups = [];
  List<AddressBookItem> _searchResults = [];
  bool _isSearching = false;
  TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '搜索姓名、手机号或角色',
                  border: InputBorder.none,
                ),
                onChanged: _onSearchChanged,
              )
            : Text('通讯录'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchResults.clear();
                }
              });
            },
          ),
        ],
      ),
      body: _isSearching && _searchController.text.isNotEmpty
          ? _buildSearchResults()
          : _buildGroupedList(),
    );
  }

  void _onSearchChanged(String keyword) async {
    if (keyword.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    try {
      final results = await searchAddressBook(keyword);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      showSnackBar('搜索失败: $e');
    }
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Text('未找到匹配的结果'),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildPersonItem(_searchResults[index]);
      },
    );
  }

  Widget _buildGroupedList() {
    // 之前的分组列表实现
    // ...
  }
}
```

### 场景3：患者倒查CRC

在患者管理页面添加倒查功能：

```dart
class PatientCrcLookupPage extends StatefulWidget {
  @override
  _PatientCrcLookupPageState createState() => _PatientCrcLookupPageState();
}

class _PatientCrcLookupPageState extends State<PatientCrcLookupPage> {
  TextEditingController _patientController = TextEditingController();
  List<AddressBookItem> _results = [];
  bool _loading = false;

  Future<void> _lookup() async {
    final keyword = _patientController.text.trim();
    if (keyword.isEmpty) {
      showSnackBar('请输入患者姓名或住院号');
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final results = await lookupCrcByPatient(keyword);
      setState(() {
        _results = results;
      });

      if (results.isEmpty) {
        showSnackBar('未找到负责该患者的CRC');
      }
    } catch (e) {
      showSnackBar('查询失败: $e');
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
        title: Text('查找患者CRC'),
      ),
      body: Column(
        children: [
          // 搜索框
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _patientController,
                    decoration: InputDecoration(
                      hintText: '输入患者姓名或住院号',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _lookup(),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _lookup,
                  child: Text('查询'),
                ),
              ],
            ),
          ),
          // 结果列表
          Expanded(
            child: _buildResultList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultList() {
    if (_loading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_results.isEmpty) {
      return Center(
        child: Text('请输入患者信息进行查询'),
      );
    }

    // 显示CRC列表（标准通讯录格式）
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final crc = _results[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: crc.avatar != null
                  ? NetworkImage(crc.avatar!)
                  : null,
              child: crc.avatar == null
                  ? Text(crc.nameInitial)
                  : null,
            ),
            title: Text(crc.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(crc.roleName ?? ''),
                Text(crc.phone),
                if (crc.email != null)
                  Text(crc.email!, 
                    style: TextStyle(color: Colors.blue)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.phone, color: Colors.green),
                  onPressed: () {
                    // 拨打电话
                    launch('tel:${crc.phone}');
                  },
                ),
                if (crc.email != null)
                  IconButton(
                    icon: Icon(Icons.email, color: Colors.blue),
                    onPressed: () {
                      // 发送邮件
                      launch('mailto:${crc.email}');
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
```

---

## 错误代码说明

| 错误代码 | 说明 | 解决方案 |
|---------|------|----------|
| UNAUTHORIZED | 用户未登录或Token失效 | 重新登录获取新的Token |

---

## 注意事项

1. **组织隔离**：所有接口都基于当前用户的组织ID，只能查询本组织的数据。

2. **字母索引**：首字母分组支持A-Z和#（特殊字符），前端可以实现右侧字母条快速定位功能。

3. **角色翻译**：服务端会自动将角色代码（如CRC、PI）翻译为中文名称（临床研究协调员、主要研究者）。

4. **数据来源**：
   - 通讯录列表和搜索：来自 v_address_book 视图（整合人员和联系人）
   - 患者倒查：来自 v_patient_crc_lookup 视图（筛查记录关联）

5. **倒查结果**：同一患者可能在多个项目中，会返回多条记录。前端可以按CRC分组展示。

6. **Token认证**：所有接口都需要在请求头中携带有效的 JWT Token。

7. **srcType字段**：用于区分数据来源（PERSON-人员表，CONTACT-联系人表），前端可以根据需要做不同展示。

8. **userId字段**：
   - 对于来自人员表（srcType = PERSON）的记录，userId 是该人员对应的用户ID（t_user.id）
   - 对于来自联系人表（srcType = CONTACT）的记录，userId 为 null（因为联系人没有用户账号）
   - **IM集成**：在通讯录点击用户发起单聊时，使用 userId 调用 IM 模块的创建单聊接口 `/api/v1/im/conversations/single`
   - 如果 userId 为 null，说明该联系人没有系统账号，无法发起 IM 单聊

9. **IM单聊集成示例**：
   ```dart
   // 点击通讯录项，发起IM单聊
   void onAddressBookItemTap(AddressBookItem item) {
     if (item.userId != null) {
       // 有userId，可以发起IM单聊
       createSingleChat(item.userId!);
     } else {
       // 无userId（联系人类型），只能拨打电话或发邮件
       showContactActions(item);
     }
   }
   
   // 调用IM创建单聊接口
   Future<void> createSingleChat(int targetUserId) async {
     final response = await http.post(
       Uri.parse('http://localhost:8090/api/v1/im/conversations/single'),
       headers: {
         'Content-Type': 'application/json',
         'Authorization': 'Bearer $accessToken'
       },
       body: jsonEncode({
         'targetUserId': targetUserId
       }),
     );
     
     final result = jsonDecode(response.body);
     if (result['success']) {
       final conversationId = result['data']['conversationId'];
       // 跳转到聊天页面
       navigateToChatPage(conversationId);
     }
   }
   ```

---

## 角色代码对照表

| 角色代码 | 中文名称 |
|---------|---------|
| PI | 主要研究者 |
| CRC | 临床研究协调员 |
| CRA | 临床监查员 |
| PM | 项目经理 |
| DM | 数据管理员 |
| STAT | 统计师 |
| SUB_INVESTIGATOR | 研究者 |
| NURSE | 护士 |
| PHARMACIST | 药师 |
| LAB_TECHNICIAN | 检验技师 |

---

## 完整工作流程示例

### Flutter 完整示例代码

```dart
class AddressBookService {
  final String baseUrl = 'http://localhost:8090/api/v1';
  String? accessToken;

  // 设置Token
  void setToken(String token) {
    accessToken = token;
  }

  // 获取通讯录列表（按首字母分组）
  Future<List<AddressBookGroup>> getAddressBook() async {
    final response = await http.get(
      Uri.parse('$baseUrl/address-book'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken'
      },
    );

    final result = jsonDecode(response.body);
    if (result['success']) {
      final data = result['data'] as List;
      return data.map((group) => AddressBookGroup.fromJson(group)).toList();
    }
    throw Exception(result['message']);
  }

  // 搜索通讯录
  Future<List<AddressBookItem>> searchAddressBook(String keyword) async {
    final response = await http.get(
      Uri.parse('$baseUrl/address-book/search?keyword=${Uri.encodeComponent(keyword)}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken'
      },
    );

    final result = jsonDecode(response.body);
    if (result['success']) {
      final data = result['data'] as List;
      return data.map((item) => AddressBookItem.fromJson(item)).toList();
    }
    throw Exception(result['message']);
  }

  // 患者倒查CRC（返回标准通讯录格式）
  Future<List<AddressBookItem>> lookupCrcByPatient(String keyword) async {
    final response = await http.get(
      Uri.parse('$baseUrl/address-book/lookup-crc?keyword=${Uri.encodeComponent(keyword)}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken'
      },
    );

    final result = jsonDecode(response.body);
    if (result['success']) {
      final data = result['data'] as List;
      return data.map((item) => AddressBookItem.fromJson(item)).toList();
    }
    throw Exception(result['message']);
  }
}

// 使用示例
void main() async {
  final addressBookService = AddressBookService();
  addressBookService.setToken('your_access_token_here');

  // 1. 加载通讯录列表
  final groups = await addressBookService.getAddressBook();
  print('通讯录分组数: ${groups.length}');
  for (var group in groups) {
    print('${group.initial}: ${group.items.length}人');
  }

  // 2. 搜索通讯录
  final searchResults = await addressBookService.searchAddressBook('张');
  print('搜索结果: ${searchResults.length}人');

  // 3. 患者倒查CRC
  final crcList = await addressBookService.lookupCrcByPatient('王某');
  print('找到${crcList.length}个负责该患者的CRC');
  for (var crc in crcList) {
    print('CRC: ${crc.name} (${crc.phone})');
  }
}
```

---

## 更新日志

- **2025-11-11**: 添加 userId 字段支持 IM 单聊
  - 在所有接口响应中添加 userId 字段
  - userId 用于在通讯录中点击用户发起 IM 单聊
  - 更新 v_address_book 视图，关联 t_user 表获取 user_id
  - PERSON 类型记录包含 userId，CONTACT 类型记录 userId 为 null

- **2025-11-07**: 初始版本，实现三个核心接口
  - 获取通讯录列表（按首字母分组）
  - 搜索通讯录
  - 患者倒查CRC

