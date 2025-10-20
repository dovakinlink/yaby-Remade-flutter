#!/bin/bash

# 崖柏应用打包脚本
# 使用方法: ./scripts/build_release.sh [生产环境API地址]

# 生产环境API地址（可以通过命令行参数传入）
PROD_API="${1:-https://api.yabai.com}"

echo "================================"
echo "   崖柏应用打包脚本"
echo "================================"
echo "生产环境API: $PROD_API"
echo "开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "================================"
echo ""

# 清理旧的构建
echo "📦 清理旧的构建文件..."
flutter clean
echo ""

# 获取依赖
echo "📦 获取依赖包..."
flutter pub get
echo ""

# 打包 Android APK
echo "🤖 开始打包 Android APK..."
flutter build apk --release \
  --dart-define=BUILD_MODE=production \
  --dart-define=API_PRODUCTION_HOST="$PROD_API"

if [ $? -eq 0 ]; then
  echo "✅ Android APK 打包成功！"
  echo "   文件位置: build/app/outputs/flutter-apk/app-release.apk"
else
  echo "❌ Android APK 打包失败！"
  exit 1
fi
echo ""

# 打包 Android App Bundle (AAB)
echo "🤖 开始打包 Android App Bundle..."
flutter build appbundle --release \
  --dart-define=BUILD_MODE=production \
  --dart-define=API_PRODUCTION_HOST="$PROD_API"

if [ $? -eq 0 ]; then
  echo "✅ Android App Bundle 打包成功！"
  echo "   文件位置: build/app/outputs/bundle/release/app-release.aab"
else
  echo "❌ Android App Bundle 打包失败！"
fi
echo ""

# 打包 iOS
echo "🍎 开始打包 iOS..."
flutter build ios --release \
  --dart-define=BUILD_MODE=production \
  --dart-define=API_PRODUCTION_HOST="$PROD_API"

if [ $? -eq 0 ]; then
  echo "✅ iOS 打包成功！"
  echo "   请在 Xcode 中打开 ios/Runner.xcworkspace"
  echo "   然后执行 Product -> Archive 导出 IPA 文件"
else
  echo "❌ iOS 打包失败！"
fi
echo ""

echo "================================"
echo "打包完成！"
echo "完成时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "================================"
echo ""
echo "📱 Android 安装包:"
echo "   APK:  build/app/outputs/flutter-apk/app-release.apk"
echo "   AAB:  build/app/outputs/bundle/release/app-release.aab"
echo ""
echo "🍎 iOS 后续步骤:"
echo "   1. 在 Xcode 中打开 ios/Runner.xcworkspace"
echo "   2. 选择 Product -> Archive"
echo "   3. 在 Organizer 中导出 IPA"
echo ""

