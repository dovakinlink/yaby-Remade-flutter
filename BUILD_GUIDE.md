# 崖柏应用打包指南

## 📋 打包前准备

### 1. 生成 Android 签名密钥（首次打包）

```bash
cd android/app
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

**重要信息需记录**：
- Keystore 密码
- Key 密码  
- Alias 名称：upload

### 2. 配置签名文件

在 `android/` 目录下创建 `key.properties` 文件：

```properties
storePassword=你的keystore密码
keyPassword=你的key密码
keyAlias=upload
storeFile=app/upload-keystore.jks
```

⚠️ **重要**：此文件已加入 .gitignore，不要提交到 Git！

### 3. iOS 配置（需要 macOS）

1. 使用 Xcode 打开 `ios/Runner.xcworkspace`
2. 在项目设置中：
   - 修改 Bundle Identifier 为 `com.yabai.ctrial`
   - 配置 Team（需要 Apple Developer 账号）
   - 选择签名证书

## 🚀 快速打包

### 使用自动化脚本（推荐）

```bash
# 使用默认生产环境地址
./scripts/build_release.sh

# 指定生产环境API地址
./scripts/build_release.sh https://your-api-server.com
```

## 🔨 手动打包

### Android APK

```bash
# 开发环境（使用局域网地址）
flutter build apk --dart-define=BUILD_MODE=development

# 生产环境
flutter build apk --release \
  --dart-define=BUILD_MODE=production \
  --dart-define=API_PRODUCTION_HOST=https://your-api-server.com
```

**产物位置**：`build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (AAB)

```bash
flutter build appbundle --release \
  --dart-define=BUILD_MODE=production \
  --dart-define=API_PRODUCTION_HOST=https://your-api-server.com
```

**产物位置**：`build/app/outputs/bundle/release/app-release.aab`

**说明**：AAB 格式用于上架 Google Play Store

### iOS IPA

```bash
# 1. 构建 iOS
flutter build ios --release \
  --dart-define=BUILD_MODE=production \
  --dart-define=API_PRODUCTION_HOST=https://your-api-server.com

# 2. 在 Xcode 中归档
# - 打开 ios/Runner.xcworkspace
# - Product -> Archive
# - 在 Organizer 中导出 IPA
```

## 🌐 环境配置说明

### 编译时参数

- `BUILD_MODE`: 构建模式
  - `development`（默认）：开发环境，自动检测设备类型使用对应地址
  - `production`：生产环境，使用指定的 API 地址

- `API_PRODUCTION_HOST`: 生产环境 API 地址
  - 示例：`https://api.yabai.com`
  - 示例：`http://192.168.1.100:8090`

### 环境地址优先级

生产模式（`BUILD_MODE=production`）：
1. 使用 `API_PRODUCTION_HOST` 指定的地址

开发模式（`BUILD_MODE=development`）：
1. iOS 模拟器：`http://127.0.0.1:8090`
2. Android 模拟器：`http://10.0.2.2:8090`
3. 真机设备：`http://192.168.0.101:8090`（局域网）

## 📱 测试安装包

### Android

```bash
# 安装到连接的设备
adb install build/app/outputs/flutter-apk/app-release.apk

# 如果已安装，覆盖安装
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### iOS

使用 Xcode 或 TestFlight 进行分发测试

## ✅ 打包前检查清单

- [ ] 已生成 Android 签名密钥
- [ ] 已配置 `android/key.properties`（不提交到 Git）
- [ ] 已配置 iOS 签名证书（如需打包 iOS）
- [ ] 已确认生产环境 API 地址
- [ ] 已测试生产环境 API 连接
- [ ] 已更新版本号（如需要）
- [ ] 已清理调试代码和日志

## 🔍 常见问题

### Q1: Android 打包失败，提示签名错误

**A**: 检查 `android/key.properties` 文件是否正确配置，密码是否正确。

### Q2: iOS 打包失败，提示证书问题

**A**: 在 Xcode 中检查签名配置，确保选择了正确的 Team 和证书。

### Q3: 如何修改应用版本号？

**A**: 编辑 `pubspec.yaml` 中的 `version` 字段：
```yaml
version: 1.0.1+2  # 1.0.1 是版本名，2 是版本号
```

### Q4: 打包后无法连接服务器

**A**: 检查：
1. 编译时是否正确传入了 `API_PRODUCTION_HOST` 参数
2. 服务器地址是否正确
3. 是否配置了网络权限（已在 AndroidManifest.xml 中配置）

### Q5: 如何查看当前使用的 API 地址？

**A**: 应用启动后会在日志中打印：
- 开发环境：`使用开发环境API: xxx`
- 生产环境：`使用生产环境API: xxx`

## 📦 产物说明

### APK vs AAB

- **APK**：可直接安装的安装包，适合分发测试
- **AAB**：Google Play 上架格式，由商店动态生成 APK

### 文件大小

- Android APK：约 20-30 MB（未混淆）
- Android APK：约 15-20 MB（已混淆）
- iOS IPA：约 30-40 MB

## 🔐 安全注意事项

1. **签名文件**：
   - 不要将 `key.properties` 和 `.jks` 文件提交到 Git
   - 妥善保管签名密钥，丢失将无法更新应用

2. **API 地址**：
   - 生产环境建议使用 HTTPS
   - 不要在代码中硬编码敏感信息

3. **代码混淆**：
   - Release 版本已启用混淆（Android）
   - 保留混淆映射文件以便调试崩溃日志

## 📞 技术支持

如有问题，请参考：
- Flutter 官方文档：https://flutter.dev/docs/deployment
- Android 打包文档：https://flutter.dev/docs/deployment/android
- iOS 打包文档：https://flutter.dev/docs/deployment/ios

