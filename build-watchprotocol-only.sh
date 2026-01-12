#!/bin/bash

# 单独编译 WatchProtocolSDK
# 生成到 build/WatchProtocolSDK-Release 目录供其他 SDK 使用

set -e

echo "========================================="
echo "WatchProtocolSDK 单独编译"
echo "========================================="
echo ""

# 配置
SDK_NAME="WatchProtocolSDK"
VERSION="1.0.2"
PROJECT_NAME="SmartBracelet.xcodeproj"
SCHEME_NAME="WatchProtocolSDK"

# 输出目录
BUILD_DIR="build"
SDK_OUTPUT_DIR="$BUILD_DIR/SDK_Protocol"
RELEASE_DIR="$BUILD_DIR/WatchProtocolSDK-Release"

# 清理
echo "🧹 清理旧的构建产物..."
rm -rf "$SDK_OUTPUT_DIR"
rm -rf "$RELEASE_DIR"
mkdir -p "$SDK_OUTPUT_DIR"
mkdir -p "$RELEASE_DIR"

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
  ONLY_ACTIVE_ARCH=NO

if [ $? -ne 0 ]; then
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
  ONLY_ACTIVE_ARCH=NO

if [ $? -ne 0 ]; then
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
  -output "$RELEASE_DIR/${SDK_NAME}.xcframework"

if [ $? -ne 0 ]; then
    echo "❌ XCFramework 创建失败"
    exit 1
fi
echo "✅ XCFramework 创建成功"

# 同时复制到 Output 目录
echo ""
echo "📦 复制到 Output 目录..."
mkdir -p Output
cp -R "$RELEASE_DIR/${SDK_NAME}.xcframework" "Output/"

echo ""
echo "========================================="
echo "✅ WatchProtocolSDK 编译完成！"
echo "========================================="
echo ""
echo "📦 输出位置:"
echo "   - $RELEASE_DIR/${SDK_NAME}.xcframework (供其他 SDK 依赖)"
echo "   - Output/${SDK_NAME}.xcframework (发布版本)"
echo ""
