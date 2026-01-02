# APP 应用内更新检测 API 文档

## 📋 概述

本文档描述 APP 应用内更新检测功能的 API 接口，支持：
- 版本更新检测
- 强制更新控制
- 灰度发布策略
- 多语言更新说明
- 时间窗口控制

客户端在启动时调用更新检测接口，服务端根据更新策略返回是否需要更新、是否强制更新等信息。

---

## 🗄️ 数据库表结构

### 1. `app` - 应用表

存储应用基本信息。

| 字段 | 类型 | 说明 |
|------|------|------|
| id | bigint | 主键ID |
| app_key | varchar(64) | 应用唯一标识（如 yaby_app） |
| name | varchar(128) | 应用名称 |
| status | tinyint | 状态：1启用 0停用 |
| created_at | datetime | 创建时间 |
| updated_at | datetime | 更新时间 |

**索引：**
- `uk_app_key`：唯一索引（app_key）

---

### 2. `app_channel` - 发布渠道表

存储各平台的发布渠道信息。

| 字段 | 类型 | 说明 |
|------|------|------|
| id | bigint | 主键ID |
| app_id | bigint | 应用ID（app.id） |
| platform | varchar(16) | 平台：android/ios |
| channel_code | varchar(32) | 渠道码：googleplay/huawei/xiaomi/appstore/internal等 |
| channel_name | varchar(64) | 渠道名称 |
| status | tinyint | 状态：1启用 0停用 |
| created_at | datetime | 创建时间 |
| updated_at | datetime | 更新时间 |

**索引：**
- `uk_app_platform_channel`：唯一索引（app_id, platform, channel_code）
- `idx_app_platform`：索引（app_id, platform）

---

### 3. `app_release` - 版本发布表

存储每个版本的详细信息。

| 字段 | 类型 | 说明 |
|------|------|------|
| id | bigint | 主键ID |
| app_id | bigint | 应用ID（app.id） |
| platform | varchar(16) | 平台：android/ios |
| channel_code | varchar(32) | 渠道码（iOS可固定default/appstore） |
| version_name | varchar(32) | 语义版本号，如 1.3.2 |
| build_number | int | build号：iOS CFBundleVersion / Android versionCode |
| is_active | tinyint | 是否可用（下架/回滚）：1可用 0不可用 |
| is_published | tinyint | 是否已发布：1已发布 0预发布 |
| published_at | datetime | 发布时间 |
| store_url | varchar(512) | 应用商店链接 |
| download_url | varchar(512) | APK直接下载链接（Android专用） |
| file_sha256 | varchar(64) | APK文件SHA256校验值 |
| file_size | bigint | 文件大小（字节） |
| created_at | datetime | 创建时间 |
| updated_at | datetime | 更新时间 |

**索引：**
- `uk_release_unique`：唯一索引（app_id, platform, channel_code, version_name, build_number）
- `idx_release_lookup`：索引（app_id, platform, channel_code, is_published, is_active, published_at）
- `idx_release_version`：索引（app_id, platform, channel_code, version_name, build_number）

---

### 4. `app_release_note` - 版本更新说明表

存储每个版本的更新说明（支持多语言、多条）。

| 字段 | 类型 | 说明 |
|------|------|------|
| id | bigint | 主键ID |
| release_id | bigint | 版本发布ID（app_release.id） |
| lang | varchar(16) | 语言代码：zh-CN/en-US等 |
| note_order | int | 排序号 |
| content | varchar(512) | 更新说明单条内容 |
| created_at | datetime | 创建时间 |

**索引：**
- `idx_note_release_lang`：索引（release_id, lang）

---

### 5. `app_update_rule` - 更新策略表（核心）

定义更新检测的策略规则。

| 字段 | 类型 | 说明 |
|------|------|------|
| id | bigint | 主键ID |
| app_id | bigint | 应用ID（app.id） |
| platform | varchar(16) | 平台：android/ios |
| channel_code | varchar(32) | 渠道码 |
| status | tinyint | 状态：1启用 0停用 |
| latest_release_id | bigint | 最新版本ID（提示更新） |
| min_supported_release_id | bigint | 最低支持版本ID（低于则强制更新） |
| force_update | tinyint | 是否强制更新：1强更 0可选 |
| rollout_percent | int | 灰度比例0-100 |
| rollout_salt | varchar(32) | 灰度盐值（变更可重新洗牌） |
| start_time | datetime | 生效开始时间（可空=立即） |
| end_time | datetime | 生效结束时间（可空=永久） |
| created_at | datetime | 创建时间 |
| updated_at | datetime | 更新时间 |

**索引：**
- `uk_rule_unique`：唯一索引（app_id, platform, channel_code）
- `idx_rule_active`：索引（app_id, platform, channel_code, status, start_time, end_time）

---

## 🔧 数据库初始化示例

### 示例场景

假设我们有一个名为 "YABY" 的 APP：
- iOS 版本：1.3.2 (build 60) 最新版，1.2.0 (build 30) 最低支持版
- Android 版本：1.3.1 (build 58) 最新版，1.1.5 (build 25) 最低支持版
- 灰度发布：50% 用户可见更新

```sql
-- ============================================
-- 1. 创建应用
-- ============================================
INSERT INTO app (id, app_key, name, status, created_at, updated_at) 
VALUES (1, 'yaby_app', 'YABY临床试验管理', 1, NOW(), NOW());

-- ============================================
-- 2. 创建发布渠道
-- ============================================
-- iOS 渠道
INSERT INTO app_channel (id, app_id, platform, channel_code, channel_name, status, created_at, updated_at)
VALUES 
(1, 1, 'ios', 'appstore', 'App Store', 1, NOW(), NOW()),
(2, 1, 'ios', 'internal', '内部测试版', 1, NOW(), NOW());

-- Android 渠道
INSERT INTO app_channel (id, app_id, platform, channel_code, channel_name, status, created_at, updated_at)
VALUES 
(3, 1, 'android', 'googleplay', 'Google Play', 1, NOW(), NOW()),
(4, 1, 'android', 'huawei', '华为应用市场', 1, NOW(), NOW()),
(5, 1, 'android', 'xiaomi', '小米应用商店', 1, NOW(), NOW()),
(6, 1, 'android', 'internal', '内部测试版', 1, NOW(), NOW());

-- ============================================
-- 3. 创建版本发布记录
-- ============================================

-- iOS 版本
-- 最低支持版本 1.2.0 (build 30)
INSERT INTO app_release (id, app_id, platform, channel_code, version_name, build_number, 
                         is_active, is_published, published_at, store_url, 
                         download_url, file_sha256, file_size, created_at, updated_at)
VALUES (1, 1, 'ios', 'appstore', '1.2.0', 30, 1, 1, '2025-11-01 10:00:00',
        'https://apps.apple.com/app/id1234567890',
        NULL, NULL, NULL, NOW(), NOW());

-- 当前版本 1.2.3 (build 45)
INSERT INTO app_release (id, app_id, platform, channel_code, version_name, build_number, 
                         is_active, is_published, published_at, store_url, 
                         download_url, file_sha256, file_size, created_at, updated_at)
VALUES (2, 1, 'ios', 'appstore', '1.2.3', 45, 1, 1, '2025-12-01 10:00:00',
        'https://apps.apple.com/app/id1234567890',
        NULL, NULL, NULL, NOW(), NOW());

-- 最新版本 1.3.2 (build 60)
INSERT INTO app_release (id, app_id, platform, channel_code, version_name, build_number, 
                         is_active, is_published, published_at, store_url, 
                         download_url, file_sha256, file_size, created_at, updated_at)
VALUES (3, 1, 'ios', 'appstore', '1.3.2', 60, 1, 1, '2026-01-03 10:00:00',
        'https://apps.apple.com/app/id1234567890',
        NULL, NULL, NULL, NOW(), NOW());

-- Android 版本
-- 最低支持版本 1.1.5 (build 25)
INSERT INTO app_release (id, app_id, platform, channel_code, version_name, build_number, 
                         is_active, is_published, published_at, store_url, 
                         download_url, file_sha256, file_size, created_at, updated_at)
VALUES (4, 1, 'android', 'default', '1.1.5', 25, 1, 1, '2025-10-15 10:00:00',
        'https://play.google.com/store/apps/details?id=com.yaby.app',
        'https://cdn.example.com/yaby-1.1.5.apk',
        'abc123def456...', 28567890, NOW(), NOW());

-- 最新版本 1.3.1 (build 58)
INSERT INTO app_release (id, app_id, platform, channel_code, version_name, build_number, 
                         is_active, is_published, published_at, store_url, 
                         download_url, file_sha256, file_size, created_at, updated_at)
VALUES (5, 1, 'android', 'default', '1.3.1', 58, 1, 1, '2026-01-02 10:00:00',
        'https://play.google.com/store/apps/details?id=com.yaby.app',
        'https://cdn.example.com/yaby-1.3.1.apk',
        'xyz789uvw012...', 31245678, NOW(), NOW());

-- ============================================
-- 4. 创建版本更新说明
-- ============================================

-- iOS 1.3.2 更新说明（中文）
INSERT INTO app_release_note (release_id, lang, note_order, content, created_at)
VALUES 
(3, 'zh-CN', 1, '修复了闪退问题，提升了应用稳定性', NOW()),
(3, 'zh-CN', 2, '新增项目收藏功能', NOW()),
(3, 'zh-CN', 3, '优化了 AI 流式问答体验', NOW()),
(3, 'zh-CN', 4, '界面细节优化', NOW());

-- iOS 1.3.2 更新说明（英文）
INSERT INTO app_release_note (release_id, lang, note_order, content, created_at)
VALUES 
(3, 'en-US', 1, 'Fixed crash issues and improved stability', NOW()),
(3, 'en-US', 2, 'Added project favorite feature', NOW()),
(3, 'en-US', 3, 'Optimized AI streaming Q&A experience', NOW()),
(3, 'en-US', 4, 'UI improvements', NOW());

-- Android 1.3.1 更新说明（中文）
INSERT INTO app_release_note (release_id, lang, note_order, content, created_at)
VALUES 
(5, 'zh-CN', 1, '修复了部分机型闪退问题', NOW()),
(5, 'zh-CN', 2, '新增项目收藏与分享功能', NOW()),
(5, 'zh-CN', 3, '优化了网络请求性能', NOW());

-- ============================================
-- 5. 创建更新策略规则
-- ============================================

-- iOS 更新规则（50% 灰度发布）
INSERT INTO app_update_rule (id, app_id, platform, channel_code, status,
                              latest_release_id, min_supported_release_id,
                              force_update, rollout_percent, rollout_salt,
                              start_time, end_time, created_at, updated_at)
VALUES (1, 1, 'ios', 'appstore', 1,
        3,  -- 最新版本：1.3.2 (build 60)
        1,  -- 最低支持：1.2.0 (build 30)
        0,  -- 不强制更新（但低于最低支持版本时会自动强制）
        50, -- 50% 灰度
        'v1', -- 灰度盐值
        NULL, NULL, NOW(), NOW());

-- Android 更新规则（100% 全量发布）
INSERT INTO app_update_rule (id, app_id, platform, channel_code, status,
                              latest_release_id, min_supported_release_id,
                              force_update, rollout_percent, rollout_salt,
                              start_time, end_time, created_at, updated_at)
VALUES (2, 1, 'android', 'default', 1,
        5,  -- 最新版本：1.3.1 (build 58)
        4,  -- 最低支持：1.1.5 (build 25)
        0,  -- 不强制更新
        100, -- 100% 全量发布
        'v1',
        NULL, NULL, NOW(), NOW());
```

---

## 📡 API 接口

### POST /api/app/update/check

检测应用是否有新版本可更新。

**请求方式：** POST  
**Content-Type：** application/json  
**是否需要认证：** ❌ 否（公开接口）

#### 请求参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| appKey | String | ✅ | 应用唯一标识，如 `yaby_app` |
| platform | String | ✅ | 平台：`android` / `ios` |
| channelCode | String | ❌ | 渠道码，默认 `default` |
| versionName | String | ❌ | 当前版本号，如 `1.2.3` |
| buildNumber | Integer | ✅ | 当前 build 号 |
| deviceId | String | ❌ | 设备ID（用于灰度发布判断） |

#### 请求示例

```json
{
  "appKey": "yaby_app",
  "platform": "ios",
  "channelCode": "appstore",
  "versionName": "1.2.3",
  "buildNumber": 45,
  "deviceId": "xxx-匿名设备id"
}
```

#### 响应参数

| 参数 | 类型 | 说明 |
|------|------|------|
| hasUpdate | Boolean | 是否有更新 |
| force | Boolean | 是否强制更新 |
| latestVersionName | String | 最新版本号 |
| latestBuildNumber | Integer | 最新版本 build 号 |
| minSupportedVersionName | String | 最低支持版本号 |
| minSupportedBuildNumber | Integer | 最低支持版本 build 号 |
| storeUrl | String | 应用商店链接 |
| downloadUrl | String | APK 直接下载链接（Android 专用） |
| fileSha256 | String | APK 文件 SHA256 校验值 |
| fileSize | Long | 文件大小（字节） |
| releaseNotes | List&lt;String&gt; | 更新说明列表 |

#### 响应示例

**场景1：有更新（非强制）**

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "hasUpdate": true,
    "force": false,
    "latestVersionName": "1.3.2",
    "latestBuildNumber": 60,
    "minSupportedVersionName": "1.2.0",
    "minSupportedBuildNumber": 30,
    "storeUrl": "https://apps.apple.com/app/id1234567890",
    "downloadUrl": null,
    "fileSha256": null,
    "fileSize": null,
    "releaseNotes": [
      "修复了闪退问题，提升了应用稳定性",
      "新增项目收藏功能",
      "优化了 AI 流式问答体验",
      "界面细节优化"
    ]
  }
}
```

**场景2：有更新（强制更新）**

当用户当前版本 build 号小于最低支持版本时：

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "hasUpdate": true,
    "force": true,
    "latestVersionName": "1.3.2",
    "latestBuildNumber": 60,
    "minSupportedVersionName": "1.2.0",
    "minSupportedBuildNumber": 30,
    "storeUrl": "https://apps.apple.com/app/id1234567890",
    "downloadUrl": null,
    "fileSha256": null,
    "fileSize": null,
    "releaseNotes": [
      "修复了闪退问题，提升了应用稳定性",
      "新增项目收藏功能",
      "优化了 AI 流式问答体验",
      "界面细节优化"
    ]
  }
}
```

**场景3：无更新**

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "hasUpdate": false,
    "force": false
  }
}
```

**场景4：Android APK 下载**

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "hasUpdate": true,
    "force": false,
    "latestVersionName": "1.3.1",
    "latestBuildNumber": 58,
    "minSupportedVersionName": "1.1.5",
    "minSupportedBuildNumber": 25,
    "storeUrl": "https://play.google.com/store/apps/details?id=com.yaby.app",
    "downloadUrl": "https://cdn.example.com/yaby-1.3.1.apk",
    "fileSha256": "xyz789uvw012...",
    "fileSize": 31245678,
    "releaseNotes": [
      "修复了部分机型闪退问题",
      "新增项目收藏与分享功能",
      "优化了网络请求性能"
    ]
  }
}
```

---

## 🔄 业务流程

### 更新检测流程

```
┌─────────┐
│ 客户端  │
│ 启动    │
└────┬────┘
     │
     ▼
┌─────────────────────────┐
│ POST /api/app/update/check │
│ {appKey, platform, ...}    │
└────────┬────────────────┘
         │
         ▼
    ┌────────────┐
    │ 查找应用   │ ──────► 应用不存在 ──► 返回无更新
    └─────┬──────┘
          │
          ▼
    ┌────────────┐
    │ 查找规则   │ ──────► 规则无效 ──► 返回无更新
    └─────┬──────┘
          │
          ▼
    ┌─────────────────┐
    │ 获取最新版本信息 │
    └─────┬───────────┘
          │
          ▼
    ┌─────────────┐
    │ 比较版本号   │ ──────► 无新版本 ──► 返回无更新
    └─────┬───────┘
          │
          ▼
    ┌─────────────┐
    │ 检查灰度策略 │ ──────► 未命中 ──► 返回无更新
    └─────┬───────┘
          │
          ▼
    ┌─────────────┐
    │ 获取更新说明 │
    └─────┬───────┘
          │
          ▼
    ┌─────────────┐
    │ 返回更新信息 │
    └─────────────┘
```

### 版本比较逻辑

版本比较以 `buildNumber` 为主要依据：

```java
if (currentBuildNumber < latestBuildNumber) {
    hasUpdate = true;
    
    // 判断是否强制更新
    if (currentBuildNumber < minSupportedBuildNumber) {
        force = true;  // 低于最低支持版本，强制更新
    } else if (rule.forceUpdate == 1) {
        force = true;  // 规则配置了强制更新
    }
}
```

### 灰度发布算法

使用 `hash(deviceId + salt) % 100 < percent` 判断设备是否命中灰度：

```java
// 示例：rolloutPercent = 50, rolloutSalt = "v1"
String key = deviceId + "v1";
int hash = Math.abs(key.hashCode()) % 100;  // 0-99
if (hash < 50) {
    // 命中灰度，允许看到更新
}
```

**灰度盐值（rolloutSalt）的作用：**
- 更换 `rolloutSalt` 可以重新洗牌，让不同的设备命中灰度
- 例如：从 `v1` 改为 `v2`，设备的哈希值会重新计算

---

## ⚠️ 错误码

| 错误码 | 说明 | 解决方案 |
|--------|------|----------|
| 0 | 成功 | - |
| 400 | 参数错误 | 检查请求参数是否完整 |
| 500 | 服务器内部错误 | 联系技术支持 |

---

## ❓ 常见问题 FAQ

### 1. 为什么我的设备看不到更新？

可能原因：
1. **灰度发布未命中**：规则配置了灰度比例（如 50%），您的设备未命中灰度策略
2. **时间窗口未生效**：规则配置了 `start_time`，还未到生效时间
3. **规则已过期**：规则配置了 `end_time`，已过生效时间
4. **版本已是最新**：您的 `buildNumber` 已经是最新版本

### 2. 如何配置强制更新？

有两种方式：

**方式1：规则级强制更新**
```sql
UPDATE app_update_rule 
SET force_update = 1 
WHERE app_id = 1 AND platform = 'ios';
```
所有低于最新版本的用户都会收到强制更新提示。

**方式2：最低支持版本**
```sql
UPDATE app_update_rule 
SET min_supported_release_id = 2  -- 设置最低支持版本
WHERE app_id = 1 AND platform = 'ios';
```
只有低于最低支持版本的用户才会收到强制更新提示（推荐）。

### 3. 如何实现灰度发布？

**步骤1：设置灰度比例**
```sql
-- 初始：10% 灰度
UPDATE app_update_rule 
SET rollout_percent = 10 
WHERE id = 1;
```

**步骤2：逐步放量**
```sql
-- 观察稳定后，扩大到 50%
UPDATE app_update_rule 
SET rollout_percent = 50 
WHERE id = 1;

-- 最终全量发布
UPDATE app_update_rule 
SET rollout_percent = 100 
WHERE id = 1;
```

**步骤3：重新洗牌（可选）**

如果想让不同的设备命中灰度：
```sql
UPDATE app_update_rule 
SET rollout_salt = 'v2'  -- 从 v1 改为 v2
WHERE id = 1;
```

### 4. 如何配置时间窗口发布？

**场景：希望在 2026-01-10 10:00 开始推送更新，2026-01-20 10:00 停止**

```sql
UPDATE app_update_rule 
SET start_time = '2026-01-10 10:00:00',
    end_time = '2026-01-20 10:00:00'
WHERE id = 1;
```

### 5. iOS 和 Android 渠道码如何配置？

**iOS：**
- 推荐使用 `appstore`（App Store 正式版）
- 内部测试版可使用 `internal`

**Android：**
- 推荐使用 `default`（通用渠道）
- 或使用具体渠道码：`googleplay`、`huawei`、`xiaomi` 等

### 6. 更新说明支持哪些语言？

目前默认使用 `zh-CN`（简体中文），可扩展支持：
- `zh-CN`：简体中文
- `en-US`：英文
- `zh-TW`：繁体中文
- 等...

客户端可根据系统语言传递 `lang` 参数（需要扩展接口）。

### 7. 如何回滚版本？

**方式1：停用当前版本**
```sql
UPDATE app_release 
SET is_active = 0 
WHERE id = 3;  -- 停用有问题的版本
```

**方式2：更新规则指向旧版本**
```sql
UPDATE app_update_rule 
SET latest_release_id = 2  -- 指向旧版本
WHERE id = 1;
```

### 8. Android APK 下载链接如何配置？

建议使用 CDN 加速：

```sql
UPDATE app_release 
SET download_url = 'https://cdn.example.com/yaby-1.3.1.apk',
    file_sha256 = 'xyz789uvw012...',  -- 必须配置校验值
    file_size = 31245678
WHERE id = 5;
```

客户端下载后应验证 SHA256 校验值。

---

## 📝 Flutter 客户端集成示例

```dart
import 'package:dio/dio.dart';

class AppUpdateService {
  final Dio _dio;
  
  AppUpdateService(this._dio);
  
  /// 检查应用更新
  Future<AppUpdateCheckVO?> checkUpdate({
    required String appKey,
    required String platform,
    required String versionName,
    required int buildNumber,
    String? channelCode,
    String? deviceId,
  }) async {
    try {
      final response = await _dio.post(
        '/api/app/update/check',
        data: {
          'appKey': appKey,
          'platform': platform,
          'channelCode': channelCode ?? 'default',
          'versionName': versionName,
          'buildNumber': buildNumber,
          'deviceId': deviceId ?? '',
        },
      );
      
      if (response.data['code'] == 0) {
        return AppUpdateCheckVO.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      print('检查更新失败: $e');
      return null;
    }
  }
}

// VO 类
class AppUpdateCheckVO {
  final bool hasUpdate;
  final bool force;
  final String? latestVersionName;
  final int? latestBuildNumber;
  final String? minSupportedVersionName;
  final int? minSupportedBuildNumber;
  final String? storeUrl;
  final String? downloadUrl;
  final String? fileSha256;
  final int? fileSize;
  final List<String>? releaseNotes;
  
  AppUpdateCheckVO({
    required this.hasUpdate,
    required this.force,
    this.latestVersionName,
    this.latestBuildNumber,
    this.minSupportedVersionName,
    this.minSupportedBuildNumber,
    this.storeUrl,
    this.downloadUrl,
    this.fileSha256,
    this.fileSize,
    this.releaseNotes,
  });
  
  factory AppUpdateCheckVO.fromJson(Map<String, dynamic> json) {
    return AppUpdateCheckVO(
      hasUpdate: json['hasUpdate'] ?? false,
      force: json['force'] ?? false,
      latestVersionName: json['latestVersionName'],
      latestBuildNumber: json['latestBuildNumber'],
      minSupportedVersionName: json['minSupportedVersionName'],
      minSupportedBuildNumber: json['minSupportedBuildNumber'],
      storeUrl: json['storeUrl'],
      downloadUrl: json['downloadUrl'],
      fileSha256: json['fileSha256'],
      fileSize: json['fileSize'],
      releaseNotes: (json['releaseNotes'] as List?)?.cast<String>(),
    );
  }
}
```

### 使用示例

```dart
// 在 APP 启动时检查更新
void checkAppUpdate() async {
  final updateService = AppUpdateService(dio);
  
  final result = await updateService.checkUpdate(
    appKey: 'yaby_app',
    platform: Platform.isIOS ? 'ios' : 'android',
    versionName: '1.2.3',
    buildNumber: 45,
    channelCode: 'appstore',
    deviceId: await getDeviceId(),
  );
  
  if (result != null && result.hasUpdate) {
    if (result.force) {
      // 强制更新，不允许关闭对话框
      showForceUpdateDialog(result);
    } else {
      // 可选更新，允许稍后提醒
      showOptionalUpdateDialog(result);
    }
  }
}
```

---

## 📊 版本日志

| 版本 | 日期 | 说明 |
|------|------|------|
| v1.0.0 | 2026-01-03 | 初始版本，实现基本的更新检测功能 |

---

## 📞 技术支持

如有问题，请联系技术团队。

**相关文档：**
- [Flutter API 集成指南](./flutter-api-integration-guide.md)
- [API 总览](./API_DOCS.md)
