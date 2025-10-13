# Flutter首页公告分页API集成指南

> 本文档专为Flutter端AI Agent设计，提供完整的API对接指南和代码示例

## 📋 API概述

### 功能描述
首页公告分页查询API，支持权限控制和公告类型过滤，专为移动端首页设计。

### 核心特性
- ✅ 分页查询支持
- ✅ 权限自动控制（基于JWT中的组织信息）
- ✅ 公告类型过滤（官方公告/用户帖子）
- ✅ 数据安全（只返回已发布内容）
- ✅ 排序优化（置顶优先）

## 🔐 认证方式

### JWT Bearer Token
```dart
// HTTP请求头设置
Map<String, String> headers = {
  'Authorization': 'Bearer $accessToken',
  'Content-Type': 'application/json',
};
```

### 权限逻辑
- **官方公告** (`notice_type=0`): 只能查看当前用户组织的公告
- **用户帖子** (`notice_type=1`): 所有用户可查看
- **混合查询** (`notice_type=null`): 应用上述权限规则

## 🚀 API接口详情

### 端点信息
```
GET /api/v1/announcements/home
```

### 请求参数

| 参数名 | 类型 | 必填 | 默认值 | 取值范围 | 说明 |
|--------|------|------|--------|----------|------|
| page | int | 否 | 1 | ≥1 | 页码，从1开始 |
| size | int | 否 | 10 | 1-100 | 每页记录数 |
| notice-type | int | 否 | null | 0,1,null | 公告类型过滤 |
| status | int | 否 | null | 0,1,null | 状态过滤（通常不需要） |

### notice-type参数说明
```dart
enum NoticeType {
  official(0),    // 官方公告 - 需要权限控制
  userPost(1);    // 用户帖子 - 无权限限制
  
  const NoticeType(this.value);
  final int value;
}
```

## 📊 响应数据结构

### 成功响应格式
```json
{
  "success": true,
  "code": "SUCCESS", 
  "message": "OK",
  "data": {
    "data": [/* 公告列表 */],
    "page": 1,
    "size": 10,
    "total": 25,
    "pages": 3,
    "hasNext": true,
    "hasPrev": false
  }
}
```

### 公告对象结构
```json
{
  "id": 1,
  "orgId": 1001,
  "hospitalId": 2001,
  "title": "公告标题",
  "noticeType": 0,
  "top": false,
  "status": 1,
  "orderNo": 100,
  "contentHtml": "<p>HTML格式内容</p>",
  "contentText": "纯文本内容",
  "createdBy": 1,
  "createdAt": "2024-10-10T15:30:00",
  "updatedAt": "2024-10-10T15:30:00"
}
```

## 🛠️ Flutter数据模型

### 分页响应模型
```dart
class PageResponse<T> {
  final List<T> data;
  final int page;
  final int size;
  final int total;
  final int pages;
  final bool hasNext;
  final bool hasPrev;

  PageResponse({
    required this.data,
    required this.page,
    required this.size,
    required this.total,
    required this.pages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PageResponse<T>(
      data: (json['data'] as List)
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
      page: json['page'] as int,
      size: json['size'] as int,
      total: json['total'] as int,
      pages: json['pages'] as int,
      hasNext: json['hasNext'] as bool,
      hasPrev: json['hasPrev'] as bool,
    );
  }
}
```

### 公告模型
```dart
class AnnouncementModel {
  final int id;
  final int? orgId;
  final int? hospitalId;
  final String title;
  final int noticeType;
  final bool isTop;
  final int status;
  final int? orderNo;
  final String? contentHtml;
  final String? contentText;
  final int? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  AnnouncementModel({
    required this.id,
    this.orgId,
    this.hospitalId,
    required this.title,
    required this.noticeType,
    required this.isTop,
    required this.status,
    this.orderNo,
    this.contentHtml,
    this.contentText,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] as int,
      orgId: json['orgId'] as int?,
      hospitalId: json['hospitalId'] as int?,
      title: json['title'] as String,
      noticeType: json['noticeType'] as int,
      isTop: json['top'] as bool,
      status: json['status'] as int,
      orderNo: json['orderNo'] as int?,
      contentHtml: json['contentHtml'] as String?,
      contentText: json['contentText'] as String?,
      createdBy: json['createdBy'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  // 便利方法
  bool get isOfficial => noticeType == 0;
  bool get isUserPost => noticeType == 1;
  
  String get displayContent => contentText ?? contentHtml ?? '';
}
```

## 🔧 API服务类实现

### HTTP服务类
```dart
import 'package:dio/dio.dart';

class AnnouncementApiService {
  final Dio _dio;
  final String baseUrl = 'https://your-api-domain.com/api/v1';

  AnnouncementApiService(this._dio);

  /// 获取首页公告列表
  Future<ApiResponse<PageResponse<AnnouncementModel>>> getHomePage({
    int page = 1,
    int size = 10,
    int? noticeType,
    int? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };
      
      if (noticeType != null) {
        queryParams['notice-type'] = noticeType;
      }
      
      if (status != null) {
        queryParams['status'] = status;
      }

      final response = await _dio.get(
        '$baseUrl/announcements/home',
        queryParameters: queryParams,
      );

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(response.data);
      
      if (apiResponse.success) {
        final pageResponse = PageResponse<AnnouncementModel>.fromJson(
          apiResponse.data!,
          AnnouncementModel.fromJson,
        );
        
        return ApiResponse<PageResponse<AnnouncementModel>>(
          success: true,
          code: apiResponse.code,
          message: apiResponse.message,
          data: pageResponse,
        );
      } else {
        return ApiResponse<PageResponse<AnnouncementModel>>(
          success: false,
          code: apiResponse.code,
          message: apiResponse.message,
        );
      }
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResponse<PageResponse<AnnouncementModel>>(
        success: false,
        code: 'UNKNOWN_ERROR',
        message: '未知错误: $e',
      );
    }
  }

  ApiResponse<PageResponse<AnnouncementModel>> _handleDioError(DioException e) {
    String code = 'NETWORK_ERROR';
    String message = '网络请求失败';

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        code = 'TIMEOUT_ERROR';
        message = '请求超时，请稍后重试';
        break;
      case DioExceptionType.badResponse:
        if (e.response?.statusCode == 401) {
          code = 'UNAUTHORIZED';
          message = '请重新登录';
        } else if (e.response?.statusCode == 403) {
          code = 'FORBIDDEN';
          message = '没有访问权限';
        } else {
          message = '服务器错误 (${e.response?.statusCode})';
        }
        break;
      case DioExceptionType.cancel:
        code = 'REQUEST_CANCELLED';
        message = '请求已取消';
        break;
      default:
        message = '网络连接失败，请检查网络设置';
    }

    return ApiResponse<PageResponse<AnnouncementModel>>(
      success: false,
      code: code,
      message: message,
    );
  }
}
```

### API响应包装类
```dart
class ApiResponse<T> {
  final bool success;
  final String code;
  final String message;
  final T? data;

  ApiResponse({
    required this.success,
    required this.code,
    required this.message,
    this.data,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse<T>(
      success: json['success'] as bool,
      code: json['code'] as String,
      message: json['message'] as String,
      data: json['data'] as T?,
    );
  }
}
```

## 📱 Widget集成示例

### 分页列表Widget
```dart
class HomeAnnouncementList extends StatefulWidget {
  final int? noticeType;
  
  const HomeAnnouncementList({
    Key? key,
    this.noticeType,
  }) : super(key: key);

  @override
  State<HomeAnnouncementList> createState() => _HomeAnnouncementListState();
}

class _HomeAnnouncementListState extends State<HomeAnnouncementList> {
  final AnnouncementApiService _apiService = GetIt.instance<AnnouncementApiService>();
  final List<AnnouncementModel> _announcements = [];
  final ScrollController _scrollController = ScrollController();
  
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _announcements.clear();
      _currentPage = 1;
      _hasMore = true;
    });

    await _loadPage(1);
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || !_hasMore) return;
    
    setState(() {
      _isLoading = true;
    });

    await _loadPage(_currentPage + 1);
  }

  Future<void> _loadPage(int page) async {
    try {
      final response = await _apiService.getHomePage(
        page: page,
        size: 10,
        noticeType: widget.noticeType,
      );

      if (response.success && response.data != null) {
        setState(() {
          if (page == 1) {
            _announcements.clear();
          }
          _announcements.addAll(response.data!.data);
          _currentPage = page;
          _hasMore = response.data!.hasNext;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '加载失败: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_announcements.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_announcements.isEmpty && _errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFirstPage,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _announcements.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _announcements.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final announcement = _announcements[index];
          return AnnouncementListItem(announcement: announcement);
        },
      ),
    );
  }
}
```

### 公告列表项Widget
```dart
class AnnouncementListItem extends StatelessWidget {
  final AnnouncementModel announcement;

  const AnnouncementListItem({
    Key? key,
    required this.announcement,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _navigateToDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行
              Row(
                children: [
                  // 置顶标签
                  if (announcement.isTop)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '置顶',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  if (announcement.isTop) const SizedBox(width: 8),
                  
                  // 类型标签
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: announcement.isOfficial ? Colors.blue : Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      announcement.isOfficial ? '官方' : '帖子',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // 时间
                  Text(
                    _formatDate(announcement.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // 标题
              Text(
                announcement.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // 内容预览
              if (announcement.displayContent.isNotEmpty)
                Text(
                  announcement.displayContent,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnnouncementDetailPage(
          announcementId: announcement.id,
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
}
```

## 🔍 使用场景示例

### 场景1: 首页显示全部公告
```dart
// 显示所有类型的公告（权限自动控制）
HomeAnnouncementList()
```

### 场景2: 只显示官方公告
```dart
// 只显示当前用户组织的官方公告
HomeAnnouncementList(noticeType: 0)
```

### 场景3: 只显示用户帖子
```dart
// 显示所有用户发布的帖子
HomeAnnouncementList(noticeType: 1)
```

### 场景4: 状态管理集成(使用Provider)
```dart
class AnnouncementProvider extends ChangeNotifier {
  final AnnouncementApiService _apiService;
  
  List<AnnouncementModel> _announcements = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  List<AnnouncementModel> get announcements => _announcements;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AnnouncementProvider(this._apiService);

  Future<void> loadAnnouncements({
    int page = 1,
    int? noticeType,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getHomePage(
        page: page,
        noticeType: noticeType,
      );

      if (response.success && response.data != null) {
        _announcements = response.data!.data;
        _errorMessage = null;
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = '加载失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

## ⚠️ 错误处理指南

### 常见错误码
| 错误码 | 说明 | 处理建议 |
|--------|------|----------|
| UNAUTHORIZED | 未授权 | 引导用户重新登录 |
| FORBIDDEN | 无权限访问 | 显示权限不足提示 |
| INVALID_PARAM | 参数错误 | 检查请求参数 |
| SERVER_ERROR | 服务器错误 | 显示重试按钮 |
| NETWORK_ERROR | 网络错误 | 检查网络连接 |

### 错误处理最佳实践
```dart
void _handleApiError(ApiResponse response) {
  switch (response.code) {
    case 'UNAUTHORIZED':
      // 清除本地认证信息，跳转到登录页
      AuthService.clearAuth();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      break;
    case 'FORBIDDEN':
      // 显示权限不足对话框
      _showPermissionDialog();
      break;
    case 'NETWORK_ERROR':
      // 显示网络错误提示
      _showNetworkErrorSnackBar();
      break;
    default:
      // 显示通用错误提示
      _showGenericErrorSnackBar(response.message);
  }
}
```

## 🎯 最佳实践建议

### 1. 缓存策略
```dart
// 使用内存缓存减少网络请求
class AnnouncementCache {
  static final Map<String, CacheEntry<PageResponse<AnnouncementModel>>> _cache = {};
  static const Duration _cacheTimeout = Duration(minutes: 5);

  static String _buildKey(int page, int size, int? noticeType) {
    return 'page_${page}_size_${size}_type_${noticeType ?? 'null'}';
  }

  static PageResponse<AnnouncementModel>? get(int page, int size, int? noticeType) {
    final key = _buildKey(page, size, noticeType);
    final entry = _cache[key];
    
    if (entry != null && !entry.isExpired) {
      return entry.data;
    }
    
    _cache.remove(key);
    return null;
  }

  static void set(int page, int size, int? noticeType, PageResponse<AnnouncementModel> data) {
    final key = _buildKey(page, size, noticeType);
    _cache[key] = CacheEntry(data, DateTime.now().add(_cacheTimeout));
  }
}
```

### 2. 预加载优化
```dart
// 预加载下一页数据
void _preloadNextPage() {
  if (_hasMore && !_isLoading) {
    _apiService.getHomePage(
      page: _currentPage + 1,
      size: 10,
      noticeType: widget.noticeType,
    );
  }
}
```

### 3. 列表性能优化
```dart
// 使用ListView.builder而不是ListView
// 实现懒加载和回收机制
ListView.builder(
  itemCount: _announcements.length,
  itemBuilder: (context, index) {
    return AnnouncementListItem(
      key: ValueKey(_announcements[index].id),
      announcement: _announcements[index],
    );
  },
)
```

## 📝 总结

此API集成指南提供了完整的Flutter对接方案，包括：

- ✅ 完整的数据模型定义
- ✅ HTTP服务层实现
- ✅ Widget集成示例
- ✅ 错误处理方案
- ✅ 性能优化建议
- ✅ 最佳实践指导

使用本指南，AI Agent可以快速理解API结构并生成高质量的Flutter集成代码。

---

*最后更新: 2024-10-10*
*API版本: v1.0*
