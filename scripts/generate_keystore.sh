#!/bin/bash

# 生成 Android 正式签名 keystore 文件
# 使用方法: ./scripts/generate_keystore.sh

KEYSTORE_PATH="android/app/ybkj-keystore.jks"
KEY_ALIAS="ybkj"
VALIDITY_DAYS=9125  # 25年

echo "================================"
echo "   生成 Android 正式签名"
echo "================================"
echo "Keystore 文件: $KEYSTORE_PATH"
echo "Key Alias: $KEY_ALIAS"
echo "有效期: 25年 ($VALIDITY_DAYS 天)"
echo "================================"
echo ""

# 检查是否已存在 keystore 文件
if [ -f "$KEYSTORE_PATH" ]; then
    echo "⚠️  警告: Keystore 文件已存在: $KEYSTORE_PATH"
    read -p "是否覆盖现有文件? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "已取消操作"
        exit 0
    fi
    rm -f "$KEYSTORE_PATH"
fi

# 生成 keystore
echo "正在生成 keystore 文件..."
echo "请按照提示输入以下信息："
echo "  - Keystore 密码（storePassword）"
echo "  - Key 密码（keyPassword，可以与 storePassword 相同）"
echo "  - 姓名、组织等信息（可直接按回车使用默认值）"
echo ""

keytool -genkey -v \
  -keystore "$KEYSTORE_PATH" \
  -alias "$KEY_ALIAS" \
  -keyalg RSA \
  -keysize 2048 \
  -validity $VALIDITY_DAYS \
  -storetype JKS

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Keystore 文件生成成功！"
    echo "   文件位置: $KEYSTORE_PATH"
    echo ""
    echo "⚠️  重要提示:"
    echo "   1. 请妥善保管 keystore 文件和密码"
    echo "   2. 如果丢失，将无法更新已发布的应用"
    echo "   3. 建议将密码保存在安全的地方"
    echo ""
    echo "下一步: 请运行脚本创建 key.properties 配置文件"
else
    echo ""
    echo "❌ Keystore 文件生成失败！"
    exit 1
fi

