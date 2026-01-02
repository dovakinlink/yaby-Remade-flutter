# IM 模块图片和文件发送功能实现文档

## 功能概述

实现了 IM 即时通讯模块中发送图片和文件的完整功能，包括：

1. ✅ **图片选择与发送**：从相册选择图片，上传到服务器，发送到聊天
2. ✅ **文件选择与发送**：选择任意类型文件，上传到服务器，发送到聊天
3. ✅ **上传进度提示**：显示上传进度对话框，提升用户体验
4. ✅ **自动获取图片尺寸**：上传图片时自动获取宽度和高度信息
5. ✅ **错误处理**：完善的错误提示和异常处理

## 实现内容

### 1. 文件上传服务

**新增文件**：`lib/core/services/file_upload_service.dart`

提供统一的文件上传服务，包括：

#### 核心方法

```dart
/// 上传单个文件
Future<Map<String, dynamic>> uploadFile(
  File file, {
  Function(double)? onProgress,
}) async
```

**返回格式**：
```json
{
  "fileId": 123,
  "url": "/uploads/2025/11/11/xxxxx.jpg",
  "filename": "image.jpg",
  "size": 102400
}
```

#### 其他方法

- `uploadFiles()` - 批量上传文件
- `getImageDimensions()` - 获取图片尺寸（宽度和高度）

#### API 接口

**上传接口**：`POST /api/v1/files/upload`

**请求格式**：`multipart/form-data`

```http
POST /api/v1/files/upload
Content-Type: multipart/form-data
Authorization: Bearer {accessToken}

file: (binary data)
```

**响应格式**：
```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "上传成功",
  "data": {
    "fileId": 123,
    "url": "/uploads/2025/11/11/xxxxx.jpg",
    "filename": "image.jpg",
    "size": 102400
  }
}
```

### 2. 聊天页面功能更新

**修改文件**：`lib/features/im/presentation/pages/chat_page.dart`

#### 新增导入

```dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:yabai_app/core/services/file_upload_service.dart';
import 'package:yabai_app/core/network/api_client.dart';
```

#### 新增方法

**1. 发送图片**：`_handleSendImage()`

```dart
Future<void> _handleSendImage() async {
  // 1. 使用 ImagePicker 选择图片
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 1920,
    maxHeight: 1920,
    imageQuality: 85,
  );
  
  // 2. 显示上传进度对话框
  showDialog(...);
  
  // 3. 上传图片到服务器
  final uploadResult = await uploadService.uploadFile(file);
  
  // 4. 获取图片尺寸
  final dimensions = await uploadService.getImageDimensions(file);
  
  // 5. 发送图片消息
  await provider.sendImageMessage(
    fileId: uploadResult['fileId'],
    url: uploadResult['url'],
    width: dimensions['width'],
    height: dimensions['height'],
    size: uploadResult['size'],
  );
}
```

**2. 发送文件**：`_handleSendFile()`

```dart
Future<void> _handleSendFile() async {
  // 1. 使用 FilePicker 选择文件
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.any,
    allowMultiple: false,
  );
  
  // 2. 显示上传进度对话框
  showDialog(...);
  
  // 3. 上传文件到服务器
  final uploadResult = await uploadService.uploadFile(file);
  
  // 4. 发送文件消息
  await provider.sendFileMessage(
    fileId: uploadResult['fileId'],
    url: uploadResult['url'],
    filename: uploadResult['filename'],
    size: uploadResult['size'],
  );
}
```

#### 新增组件

**上传进度对话框**：`_UploadProgressDialog`

```dart
class _UploadProgressDialog extends StatelessWidget {
  final String title;

  const _UploadProgressDialog({required this.title});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(...),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
```

### 3. 输入栏组件连接

**文件**：`lib/features/im/presentation/widgets/chat_input_bar.dart`

#### 回调参数

```dart
class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSendText;
  final VoidCallback? onSendImage;  // 发送图片回调
  final VoidCallback? onSendFile;   // 发送文件回调
  ...
}
```

#### UI 交互

点击 "+" 按钮 → 显示底部菜单 → 选择"发送图片"或"发送文件"

```dart
void _showAttachmentMenu(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image, color: AppColors.brandGreen),
              title: const Text('发送图片'),
              onTap: () {
                Navigator.pop(context);
                onSendImage?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file, color: AppColors.brandGreen),
              title: const Text('发送文件'),
              onTap: () {
                Navigator.pop(context);
                onSendFile?.call();
              },
            ),
          ],
        ),
      );
    },
  );
}
```

## 完整流程图

### 发送图片流程

```
用户操作
   ↓
点击 "+" 按钮
   ↓
选择 "发送图片"
   ↓
打开相册选择图片
   ↓
压缩图片（最大1920x1920，质量85%）
   ↓
显示上传进度对话框
   ↓
上传到服务器 (/api/v1/files/upload)
   ↓
获取 fileId、url、size
   ↓
获取图片尺寸（width、height）
   ↓
关闭进度对话框
   ↓
调用 provider.sendImageMessage()
   ↓
通过 WebSocket 发送图片消息
   ↓
保存到本地数据库
   ↓
显示在聊天界面
   ↓
滚动到底部
```

### 发送文件流程

```
用户操作
   ↓
点击 "+" 按钮
   ↓
选择 "发送文件"
   ↓
打开文件选择器
   ↓
选择文件（任意类型）
   ↓
显示上传进度对话框
   ↓
上传到服务器 (/api/v1/files/upload)
   ↓
获取 fileId、url、filename、size
   ↓
关闭进度对话框
   ↓
调用 provider.sendFileMessage()
   ↓
通过 WebSocket 发送文件消息
   ↓
保存到本地数据库
   ↓
显示在聊天界面
   ↓
滚动到底部
```

## 技术细节

### 1. 图片压缩

使用 `image_picker` 插件的参数进行图片压缩：

```dart
await picker.pickImage(
  source: ImageSource.gallery,
  maxWidth: 1920,      // 最大宽度
  maxHeight: 1920,     // 最大高度
  imageQuality: 85,    // 质量（0-100）
);
```

**优点**：
- 减少上传流量
- 加快上传速度
- 节省服务器存储空间

### 2. 图片尺寸获取

使用 `dart:ui` 包的 `instantiateImageCodec` 方法：

```dart
Future<Map<String, int>> getImageDimensions(File imageFile) async {
  final bytes = await imageFile.readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;
  
  return {
    'width': image.width,
    'height': image.height,
  };
}
```

**用途**：
- 在聊天界面按比例显示图片
- 避免图片变形
- 优化加载性能

### 3. 错误处理

#### 场景 1：用户取消选择

```dart
if (image == null) return;  // 用户取消，直接返回
```

#### 场景 2：上传失败

```dart
try {
  final uploadResult = await uploadService.uploadFile(file);
} catch (e) {
  // 关闭进度对话框
  if (mounted) Navigator.pop(context);
  
  // 显示错误提示
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('发送图片失败: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

#### 场景 3：网络错误

```dart
on DioException catch (e) {
  if (e.response != null) {
    throw Exception(e.response?.data['message'] ?? '上传失败');
  }
  throw Exception('网络连接失败，请检查网络');
}
```

### 4. 生命周期管理

所有异步操作都检查 `mounted` 状态：

```dart
if (!mounted) return;

// 安全地进行UI操作
if (mounted) {
  Navigator.pop(context);
  ScaffoldMessenger.of(context).showSnackBar(...);
}
```

## 依赖包

### 已有依赖（已在 pubspec.yaml 中）

```yaml
dependencies:
  image_picker: ^1.1.2      # 图片选择
  file_picker: ^8.1.4       # 文件选择
  dio: ^5.7.0               # 网络请求
```

### 系统权限

#### iOS (Info.plist)

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册以选择图片</string>
<key>NSCameraUsageDescription</key>
<string>需要访问相机以拍照</string>
```

#### Android (AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.CAMERA"/>
```

## 用户体验优化

### 1. 上传进度提示

- ✅ 显示"正在上传图片/文件"对话框
- ✅ 防止用户重复点击（`barrierDismissible: false`）
- ✅ 上传完成后自动关闭

### 2. 即时反馈

- ✅ 上传成功后立即显示在聊天界面
- ✅ 自动滚动到底部
- ✅ 错误时显示红色 SnackBar 提示

### 3. 性能优化

- ✅ 图片压缩（最大1920x1920）
- ✅ 质量控制（85%）
- ✅ 异步处理，不阻塞UI

## 测试场景

### 场景 1：发送图片

1. 打开聊天页面
2. 点击输入框左侧的 "+" 按钮
3. 选择"发送图片"
4. 从相册选择一张图片
5. 等待上传完成（显示进度对话框）
6. 图片显示在聊天界面右侧
7. 自动滚动到底部

**预期结果**：
- ✅ 图片按比例显示
- ✅ 发送者显示为当前用户（右侧绿色气泡）
- ✅ 点击图片可查看大图（如果实现了）

### 场景 2：发送文件

1. 打开聊天页面
2. 点击输入框左侧的 "+" 按钮
3. 选择"发送文件"
4. 从文件管理器选择一个文件（如PDF、Word等）
5. 等待上传完成（显示进度对话框）
6. 文件信息显示在聊天界面右侧
7. 自动滚动到底部

**预期结果**：
- ✅ 显示文件图标、文件名、文件大小
- ✅ 发送者显示为当前用户（右侧绿色气泡）
- ✅ 点击文件可下载（如果实现了）

### 场景 3：取消选择

1. 点击"发送图片"或"发送文件"
2. 在选择器中点击"取消"

**预期结果**：
- ✅ 无任何操作
- ✅ 返回聊天界面

### 场景 4：上传失败

1. 断开网络连接
2. 尝试发送图片或文件

**预期结果**：
- ✅ 关闭进度对话框
- ✅ 显示红色 SnackBar："发送图片失败: 网络连接失败，请检查网络"

### 场景 5：消息接收

1. 用户 A 发送图片/文件给用户 B
2. 用户 B 收到 WebSocket 推送
3. 消息显示在用户 B 的聊天界面

**预期结果**：
- ✅ 图片/文件显示在左侧（灰色气泡）
- ✅ 发送者显示为对方用户
- ✅ 头像显示正确

## 未来扩展

### 可选功能

1. **拍照发送**：
   ```dart
   await picker.pickImage(source: ImageSource.camera);
   ```

2. **多图片选择**：
   ```dart
   await picker.pickMultiImage();
   ```

3. **图片预览**：
   - 点击图片查看大图
   - 缩放、平移功能

4. **文件下载**：
   - 点击文件下载到本地
   - 显示下载进度

5. **上传进度条**：
   - 在进度对话框中显示百分比
   - 使用 `onSendProgress` 回调

6. **文件大小限制**：
   ```dart
   if (file.lengthSync() > 10 * 1024 * 1024) {  // 10MB
     throw Exception('文件大小不能超过10MB');
   }
   ```

7. **文件类型限制**：
   ```dart
   final allowedExtensions = ['.jpg', '.png', '.pdf', '.docx'];
   ```

## 相关文件

### 新增文件

1. **文件上传服务**：
   - `lib/core/services/file_upload_service.dart`

### 修改文件

2. **聊天页面**：
   - `lib/features/im/presentation/pages/chat_page.dart`

### 已有文件（已实现，无需修改）

3. **数据模型**：
   - `lib/features/im/data/models/message_content.dart` - ImageContent、FileContent
   - `lib/features/im/data/models/im_message_model.dart` - ImMessage

4. **Provider**：
   - `lib/features/im/providers/chat_provider.dart` - sendImageMessage()、sendFileMessage()

5. **UI 组件**：
   - `lib/features/im/presentation/widgets/chat_input_bar.dart` - 输入栏（已有回调参数）
   - `lib/features/im/presentation/widgets/message_bubble.dart` - 消息气泡（已支持图片和文件显示）

## API 文档参考

详见 **`API_DOC/IM_API.md`** 文档：

- **发送消息**：第 2.1 节 - 消息类型支持 IMAGE 和 FILE
- **消息内容格式**：
  - IMAGE: `{ fileId, url, width, height, size }`
  - FILE: `{ fileId, url, filename, size }`

## 修复日期

2025-11-11

## 总结

✅ **完整实现**：从选择文件到显示在聊天界面的完整流程  
✅ **用户体验**：上传进度提示、错误处理、自动滚动  
✅ **代码质量**：无 linter 错误，通过 flutter analyze  
✅ **可扩展性**：易于添加更多功能（拍照、多选、预览等）  
✅ **文档完善**：详细的技术文档和测试场景

现在可以在应用中测试发送图片和文件功能了！🎉

