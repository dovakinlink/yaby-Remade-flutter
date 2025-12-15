#!/bin/bash

# 导出 Android 签名公钥证书
# 使用方法: ./scripts/export_public_key.sh

KEYSTORE_PATH="android/app/ybkj-keystore.jks"
KEY_ALIAS="ybkj"
CERT_OUTPUT="android/app/ybkj-public-key.cer"
MD5_OUTPUT="android/app/ybkj-public-key-md5.txt"
SHA1_OUTPUT="android/app/ybkj-public-key-sha1.txt"
SHA256_OUTPUT="android/app/ybkj-public-key-sha256.txt"

echo "================================"
echo "   导出 Android 签名公钥"
echo "================================"
echo "Keystore 文件: $KEYSTORE_PATH"
echo "Key Alias: $KEY_ALIAS"
echo "================================"
echo ""

# 检查 keystore 文件是否存在
if [ ! -f "$KEYSTORE_PATH" ]; then
    echo "❌ 错误: Keystore 文件不存在: $KEYSTORE_PATH"
    echo "   请先运行 ./scripts/generate_keystore.sh 生成 keystore 文件"
    exit 1
fi

# 读取密码
read -sp "请输入 keystore 密码: " STORE_PASSWORD
echo ""

# 1. 导出证书文件（.cer 格式）
echo "📄 正在导出公钥证书..."
keytool -exportcert \
  -alias "$KEY_ALIAS" \
  -keystore "$KEYSTORE_PATH" \
  -storepass "$STORE_PASSWORD" \
  -file "$CERT_OUTPUT"

if [ $? -eq 0 ]; then
    echo "✅ 证书文件已导出: $CERT_OUTPUT"
    # 同时生成 PEM 格式（用于 openssl 计算 MD5）
    openssl x509 -inform DER -in "$CERT_OUTPUT" -outform PEM -out "${CERT_OUTPUT%.cer}.pem" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "✅ PEM 格式证书已生成: ${CERT_OUTPUT%.cer}.pem"
    fi
else
    echo "❌ 证书导出失败"
    exit 1
fi
echo ""

# 2. 显示证书详细信息（包括各种指纹）
echo "📋 证书详细信息:"
echo "----------------------------------------"
keytool -list -v \
  -keystore "$KEYSTORE_PATH" \
  -alias "$KEY_ALIAS" \
  -storepass "$STORE_PASSWORD"
echo ""

# 3. 提取并保存各种指纹
echo "🔑 提取公钥指纹..."

# MD5 指纹（新版本 keytool 不显示 MD5，使用 openssl 计算）
PEM_FILE="${CERT_OUTPUT%.cer}.pem"
if [ -f "$PEM_FILE" ]; then
    openssl x509 -fingerprint -md5 -noout -in "$PEM_FILE" 2>/dev/null | \
      sed 's/.*=//' | tr '[:lower:]' '[:upper:]' | \
      sed 's/\(..\)/\1:/g; s/:$//' > "$MD5_OUTPUT"
else
    # 如果 PEM 文件不存在，尝试从 keytool 输出中提取（可能为空）
    keytool -list -v \
      -keystore "$KEYSTORE_PATH" \
      -alias "$KEY_ALIAS" \
      -storepass "$STORE_PASSWORD" 2>/dev/null | \
      grep -i "MD5" | \
      sed 's/.*MD5: *//' > "$MD5_OUTPUT" || echo "" > "$MD5_OUTPUT"
fi

# SHA1 指纹
keytool -list -v \
  -keystore "$KEYSTORE_PATH" \
  -alias "$KEY_ALIAS" \
  -storepass "$STORE_PASSWORD" 2>/dev/null | \
  grep -i "SHA1" | \
  sed 's/.*SHA1: *//' > "$SHA1_OUTPUT"

# SHA256 指纹
keytool -list -v \
  -keystore "$KEYSTORE_PATH" \
  -alias "$KEY_ALIAS" \
  -storepass "$STORE_PASSWORD" 2>/dev/null | \
  grep -i "SHA256" | \
  sed 's/.*SHA256: *//' > "$SHA256_OUTPUT"

echo "✅ 指纹已保存:"
echo "   MD5:    $(cat $MD5_OUTPUT)"
echo "   SHA1:   $(cat $SHA1_OUTPUT)"
echo "   SHA256: $(cat $SHA256_OUTPUT)"
echo ""

# 4. 显示 Base64 编码的证书（用于某些平台配置）
echo "📝 Base64 编码的证书（用于 Google Play 等平台）:"
echo "----------------------------------------"
openssl x509 -inform DER -in "$CERT_OUTPUT" -outform PEM | \
  grep -v "BEGIN\|END" | tr -d '\n'
echo ""
echo ""

echo "================================"
echo "导出完成！"
echo "================================"
echo "生成的文件:"
echo "  - 证书文件: $CERT_OUTPUT"
echo "  - MD5 指纹: $MD5_OUTPUT"
echo "  - SHA1 指纹: $SHA1_OUTPUT"
echo "  - SHA256 指纹: $SHA256_OUTPUT"
echo ""
echo "⚠️  注意: 这些文件包含公钥信息，可以安全分享"
echo "   但请妥善保管 keystore 文件（包含私钥）"

