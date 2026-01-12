#!/bin/bash

# WatchFaceSDK 编译脚本 - 输出到 Output2
# 用于编译并打包 WatchFaceSDK，生成可分发的 XCFramework

set -e  # 遇到错误立即退出

echo "========================================="
echo "WatchFaceSDK 编译脚本 - Output2"
echo "========================================="
echo ""

# 配置
SDK_NAME="WatchFaceSDK"
VERSION="1.0.2"
PROJECT_NAME="SmartBracelet.xcodeproj"
SCHEME_NAME="WatchFaceSDK"

# 输出目录 - 使用 Output2
BUILD_DIR="build"
SDK_OUTPUT_DIR="$BUILD_DIR/SDK"
OUTPUT_DIR="Output2"

# 清理旧的构建产物
echo "🧹 清理旧的构建产物..."
rm -rf "$SDK_OUTPUT_DIR"
rm -rf "$OUTPUT_DIR/${SDK_NAME}.xcframework"
mkdir -p "$SDK_OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# 编译 iOS 真机版本
echo ""
echo "📱 编译 iOS 真机版本 (arm64)..."
xcodebuild clean build \
  -project "$PROJECT_NAME" \
  -scheme "$SCHEME_NAME" \
  -sdk iphoneos \
  -configuration Release \
  -derivedDataPath "$SDK_OUTPUT_DIR/iOS" \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  ONLY_ACTIVE_ARCH=NO \
  | grep -E "error:|warning:|BUILD" || true

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "❌ iOS 真机版本编译失败"
    exit 1
fi
echo "✅ iOS 真机版本编译成功"

# 编译模拟器版本
echo ""
echo "🖥 编译模拟器版本 (arm64 + x86_64)..."
xcodebuild clean build \
  -project "$PROJECT_NAME" \
  -scheme "$SCHEME_NAME" \
  -sdk iphonesimulator \
  -configuration Release \
  -derivedDataPath "$SDK_OUTPUT_DIR/Simulator" \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  ONLY_ACTIVE_ARCH=NO \
  | grep -E "error:|warning:|BUILD" || true

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "❌ 模拟器版本编译失败"
    exit 1
fi
echo "✅ 模拟器版本编译成功"

# 创建 XCFramework
echo ""
echo "📦 创建 XCFramework..."
xcodebuild -create-xcframework \
  -framework "$SDK_OUTPUT_DIR/iOS/Build/Products/Release-iphoneos/${SDK_NAME}.framework" \
  -framework "$SDK_OUTPUT_DIR/Simulator/Build/Products/Release-iphonesimulator/${SDK_NAME}.framework" \
  -output "$SDK_OUTPUT_DIR/${SDK_NAME}.xcframework"

if [ $? -ne 0 ]; then
    echo "❌ XCFramework 创建失败"
    exit 1
fi
echo "✅ XCFramework 创建成功"

# 复制到 Output2 目录
echo ""
echo "📂 复制到 Output2 目录..."
cp -R "$SDK_OUTPUT_DIR/${SDK_NAME}.xcframework" "$OUTPUT_DIR/"

# 显示结果
echo ""
echo "========================================="
echo "✅ 编译完成！"
echo "========================================="
echo ""
echo "📦 输出目录: $OUTPUT_DIR"
echo "   包含内容:"
echo "   ├── ${SDK_NAME}.xcframework"
echo "   ├── VERSION.txt"
echo "   ├── README.md"
echo "   ├── WatchFaceSDK-接入文档-中文.md"
echo "   ├── WatchFaceSDK-Integration-Guide-EN.md"
echo "   └── .gitignore"
echo ""
echo "🎉 SDK 已成功构建到 Output2 目录！"
echo ""
echo "========================================="
