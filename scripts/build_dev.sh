#!/bin/bash

# 崖柏应用 - 开发环境打包脚本
# 使用方法: ./scripts/build_dev.sh

echo "================================"
echo "   崖柏应用 - 开发环境打包"
echo "================================"
echo "开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 打包 Android Debug APK（用于真机测试）
echo "🤖 开始打包 Android Debug APK..."
flutter build apk --debug \
  --dart-define=BUILD_MODE=development

if [ $? -eq 0 ]; then
  echo "✅ Android Debug APK 打包成功！"
  echo "   文件位置: build/app/outputs/flutter-apk/app-debug.apk"
  echo ""
  echo "📱 安装到设备："
  echo "   adb install -r build/app/outputs/flutter-apk/app-debug.apk"
else
  echo "❌ Android Debug APK 打包失败！"
  exit 1
fi
echo ""

echo "================================"
echo "打包完成！"
echo "完成时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "================================"

