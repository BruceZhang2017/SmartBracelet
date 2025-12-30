#!/bin/bash

# WatchProtocolSDK 编译脚本
# 用于编译并打包 WatchProtocolSDK，生成可分发的 XCFramework

set -e  # 遇到错误立即退出

echo "========================================="
echo "WatchProtocolSDK 编译脚本"
echo "========================================="
echo ""

# 配置
SDK_NAME="WatchProtocolSDK"
VERSION="1.0.0"
PROJECT_NAME="SmartBracelet.xcodeproj"
SCHEME_NAME="WatchProtocolSDK"

# 输出目录
BUILD_DIR="build"
SDK_OUTPUT_DIR="$BUILD_DIR/SDK"
RELEASE_DIR="$BUILD_DIR/${SDK_NAME}-Release"
ZIP_NAME="${SDK_NAME}-v${VERSION}.zip"

# 清理旧的构建产物
echo "🧹 清理旧的构建产物..."
rm -rf "$BUILD_DIR"
mkdir -p "$SDK_OUTPUT_DIR"

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

# 准备发布目录
echo ""
echo "📂 准备发布目录..."
mkdir -p "$RELEASE_DIR"
cp -R "$SDK_OUTPUT_DIR/${SDK_NAME}.xcframework" "$RELEASE_DIR/"

# 检查文档是否存在，如果不存在则创建基本文档
if [ ! -f "$RELEASE_DIR/README.md" ]; then
    echo "📝 生成 README.md..."
    cat > "$RELEASE_DIR/README.md" << EOF
# ${SDK_NAME} v${VERSION}

智能手表通信协议 SDK

## 版本信息
- 版本: ${VERSION}
- 最低支持: iOS 12.0+
- 编译日期: $(date +"%Y-%m-%d")

## 集成方法
1. 将 ${SDK_NAME}.xcframework 拖入你的 Xcode 项目
2. 设置为 Embed & Sign
3. 导入模块: import ${SDK_NAME}

详细文档请联系技术支持团队。
EOF
fi

# 生成版本信息
echo "📄 生成版本信息..."
cat > "$RELEASE_DIR/VERSION.txt" << EOF
${SDK_NAME} v${VERSION}

Build Date: $(date +"%Y-%m-%d %H:%M:%S")
Build Configuration: Release
Supported Platforms:
  - iOS Device (arm64)
  - iOS Simulator (arm64, x86_64)

Minimum iOS Version: 12.0
Framework Format: XCFramework
EOF

# 打包
echo ""
echo "🗜 打包成 ZIP 文件..."
cd "$BUILD_DIR"
zip -r "$ZIP_NAME" "${SDK_NAME}-Release/" > /dev/null
cd ..

# 生成校验和
echo "🔐 生成 SHA256 校验和..."
shasum -a 256 "$BUILD_DIR/$ZIP_NAME" > "$BUILD_DIR/${ZIP_NAME}.sha256"

# 显示结果
echo ""
echo "========================================="
echo "✅ 编译完成！"
echo "========================================="
echo ""
echo "📦 输出文件:"
echo "   - $BUILD_DIR/$ZIP_NAME"
echo "   - $BUILD_DIR/${ZIP_NAME}.sha256"
echo ""
echo "📁 解压目录: $RELEASE_DIR"
echo ""
echo "📊 文件大小: $(du -h "$BUILD_DIR/$ZIP_NAME" | cut -f1)"
echo "🔐 SHA256: $(cat "$BUILD_DIR/${ZIP_NAME}.sha256" | cut -d' ' -f1)"
echo ""
echo "========================================="
