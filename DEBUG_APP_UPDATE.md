# APP 版本更新问题排查指南

## 问题描述
点击"立即更新"按钮后，提示"无法打开更新链接"。

## 已实现的修复

### 1. 添加详细日志输出

已在以下文件添加详细的调试日志：

- `lib/features/app_update/data/services/app_update_service.dart` - API 响应解析
- `lib/features/app_update/presentation/widgets/app_update_dialog.dart` - 链接打开逻辑

### 2. 日志输出内容

#### API 响应解析阶段：
```
📦 [AppUpdate] 检测更新...
📦 [AppUpdate] 版本: x.x.x (xx)
📦 [AppUpdate] 平台: android/ios, 渠道: official/appstore
📦 [AppUpdate] 设备ID: xxx
📦 [AppUpdate] 响应数据: {...}
📦 [AppUpdate] 解析结果: hasUpdate=true, force=false
📦 [AppUpdate] downloadUrl: https://...
📦 [AppUpdate] storeUrl: https://...
📦 [AppUpdate] 检测到更新: 1.3.1 (58)
📦 [AppUpdate] 文件大小: 31245678 bytes (29.8 MB)
📦 [AppUpdate] SHA256: xyz789...
```

#### 链接打开阶段：
```
🔄 [AppUpdate] 处理更新点击
🔄 [AppUpdate] Platform.isAndroid: true
🔄 [AppUpdate] downloadUrl: https://...
🔄 [AppUpdate] storeUrl: https://...
🔄 [AppUpdate] 使用 downloadUrl: https://...
🔄 [AppUpdate] 尝试打开链接: https://...
🔄 [AppUpdate] URI解析成功: https://...
🔄 [AppUpdate] URI scheme: https
🔄 [AppUpdate] URI host: cdn.example.com
🔄 [AppUpdate] canLaunchUrl 结果: true/false
🔄 [AppUpdate] 正在启动外部应用打开链接...
🔄 [AppUpdate] launchUrl 结果: true/false
```

## 排查步骤

### 步骤 1: 查看日志确认问题
运行应用并触发更新检测，查看控制台输出：

```bash
flutter run
# 或使用过滤查看相关日志
flutter logs | grep AppUpdate
```

### 步骤 2: 检查后端返回的数据

根据日志检查以下内容：

#### 2.1 URL 是否为空
如果日志显示：
```
🔄 [AppUpdate] downloadUrl: null
🔄 [AppUpdate] storeUrl: null
```
**原因**: 后端没有配置更新链接  
**解决方案**: 在后端数据库的 `app_release` 表中为对应版本配置 `download_url` 或 `store_url`

#### 2.2 URL 是否为空字符串
如果日志显示：
```
🔄 [AppUpdate] downloadUrl: 
🔄 [AppUpdate] storeUrl: 
```
**原因**: 后端返回了空字符串  
**解决方案**: 修改后端逻辑，null 值不应返回，或在 SQL 查询中使用 `NULLIF(download_url, '')` 处理

#### 2.3 URL 格式是否正确
检查日志中的 URL 格式：
```
🔄 [AppUpdate] 使用 downloadUrl: https://cdn.example.com/app.apk
```

**常见格式问题**：
- ❌ `http://example.com/app.apk` - 某些设备可能拒绝 http 协议
- ❌ `example.com/app.apk` - 缺少协议头
- ❌ `https://example.com/app .apk` - 包含空格
- ✅ `https://cdn.example.com/yaby-1.3.1.apk` - 正确格式

### 步骤 3: 检查 canLaunchUrl 结果

如果日志显示：
```
🔄 [AppUpdate] canLaunchUrl 结果: false
❌ [AppUpdate] canLaunchUrl 返回 false
```

**可能原因**：

1. **Android 权限问题** - 需要在 `AndroidManifest.xml` 中添加查询权限
2. **URL scheme 不支持** - 系统无法识别该 URL 的协议
3. **网络安全策略** - Android 9+ 默认禁止明文 http 流量

## 解决方案

### 方案 1: 检查 AndroidManifest.xml 配置

确保 `android/app/src/main/AndroidManifest.xml` 包含必要的权限：

```xml
<manifest>
    <!-- 网络访问权限 -->
    <uses-permission android:name="android.permission.INTERNET" />
    
    <!-- Android 11+ 需要声明可查询的 URL scheme -->
    <queries>
        <!-- 支持 HTTP/HTTPS -->
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="https" />
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="http" />
        </intent>
    </queries>
    
    <application>
        <!-- 允许 HTTP 流量（Android 9+ 需要） -->
        android:usesCleartextTraffic="true"
        
        <!-- 或使用网络安全配置 -->
        android:networkSecurityConfig="@xml/network_security_config"
    </application>
</manifest>
```

### 方案 2: 添加网络安全配置

创建 `android/app/src/main/res/xml/network_security_config.xml`：

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="true">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>
</network-security-config>
```

### 方案 3: 确保后端配置正确

检查数据库 `app_release` 表：

```sql
SELECT 
    id, 
    version_name, 
    build_number, 
    download_url, 
    store_url,
    is_active,
    is_published
FROM app_release
WHERE app_id = (SELECT id FROM app WHERE app_key = 'yaby_app')
  AND platform = 'android'
  AND is_active = 1
  AND is_published = 1
ORDER BY build_number DESC
LIMIT 1;
```

**确认**：
- ✅ `download_url` 或 `store_url` 不为空
- ✅ URL 格式正确（包含 https://）
- ✅ URL 可以在浏览器中直接访问
- ✅ `is_active = 1` 和 `is_published = 1`

### 方案 4: 验证 URL 可访问性

使用以下命令测试 URL 是否可访问：

```bash
# 测试 URL 是否可访问
curl -I https://your-download-url/app.apk

# 应该返回 200 状态码
HTTP/1.1 200 OK
```

### 方案 5: 临时使用应用商店链接

如果直接下载链接有问题，可以暂时使用应用商店链接：

1. 将应用上传到应用商店（如华为、小米应用市场）
2. 在数据库中配置 `store_url`：
   ```sql
   UPDATE app_release
   SET store_url = 'https://appstore.huawei.com/app/C123456789'
   WHERE id = YOUR_RELEASE_ID;
   ```

## 测试建议

### 1. 本地测试
使用测试 URL 验证功能：

```dart
// 在对话框中临时硬编码测试
final testUrl = 'https://www.baidu.com'; // 测试一个已知可打开的 URL
```

### 2. 真实环境测试
1. 上传 APK 到你的 CDN
2. 在数据库中配置正确的 download_url
3. 测试完整流程

## 常见错误和解决方案

| 错误提示 | 可能原因 | 解决方案 |
|---------|---------|---------|
| 无法获取更新链接 | downloadUrl 和 storeUrl 都为空 | 检查后端数据库配置 |
| 无法打开更新链接 | canLaunchUrl 返回 false | 检查 AndroidManifest.xml 权限配置 |
| 打开链接失败: FormatException | URL 格式错误 | 检查 URL 中是否包含空格或特殊字符 |
| 打开链接失败: ActivityNotFoundException | 没有应用能处理该 URL | 检查 URL scheme 是否正确 |

## 联系后端开发人员

如果确认是后端问题，请提供以下信息：

1. **应用信息**：
   - appKey: `yaby_app`
   - platform: `android` 或 `ios`
   - channelCode: `official` 或 `appstore`

2. **当前版本**：
   - versionName: `x.x.x`
   - buildNumber: `xx`

3. **请求后端检查**：
   - `app_release` 表中是否有更新版本记录
   - 该版本的 `download_url` 和 `store_url` 是否已配置
   - URL 是否可以正常访问
   - `app_update_rule` 表中的策略是否正确配置

## 下一步

请先运行应用，查看控制台日志输出，然后根据日志内容确定具体问题。
