#!/bin/bash

# WatchFaceSDK 快速重新编译脚本
# 修复 v1.0.2 的 rawImageData 崩溃问题

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  WatchFaceSDK v1.0.3 重新编译${NC}"
echo -e "${BLUE}  修复: uploadCustomWatchFace 崩溃${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 配置
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_DIR="$PROJECT_DIR/WatchFaceSDK/WatchFaceSDK"
BUILD_DIR="$PROJECT_DIR/build/WatchFaceSDK-v1.0.3"
OUTPUT_DIR="$PROJECT_DIR/Output2"

# 依赖路径
WATCHPROTOCOL_SDK="$PROJECT_DIR/build/WatchProtocolSDK-Release/WatchProtocolSDK.xcframework"
ABPAR_TOOL="$PROJECT_DIR/ABParTool.xcframework"

# 清理
echo -e "${GREEN}🧹 清理构建目录...${NC}"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# 检查依赖
echo -e "${GREEN}🔍 检查依赖...${NC}"
if [ ! -d "$WATCHPROTOCOL_SDK" ]; then
    echo -e "${RED}❌ WatchProtocolSDK.xcframework 不存在${NC}"
    echo -e "${RED}   路径: $WATCHPROTOCOL_SDK${NC}"
    echo ""
    echo -e "${YELLOW}请先构建 WatchProtocolSDK:${NC}"
    echo -e "   cd WatchProtocolSDK"
    echo -e "   ./build-framework.sh"
    exit 1
fi
echo -e "   ✅ WatchProtocolSDK.xcframework"

if [ ! -d "$ABPAR_TOOL" ]; then
    echo -e "${RED}❌ ABParTool.xcframework 不存在${NC}"
    exit 1
fi
echo -e "   ✅ ABParTool.xcframework"

# 检查源文件
echo ""
echo -e "${GREEN}📂 检查源文件...${NC}"
if [ ! -f "$SOURCE_DIR/Extensions/ImageProcessor.swift" ]; then
    echo -e "${RED}❌ 源文件不存在${NC}"
    exit 1
fi

# 验证修复已应用
echo -e "${GREEN}🔍 验证修复...${NC}"
if grep -q "var rawImageData: Data?" "$SOURCE_DIR/Extensions/ImageProcessor.swift"; then
    echo -e "${RED}❌ 错误: rawImageData 扩展仍然存在!${NC}"
    echo -e "${RED}   请确保已应用修复${NC}"
    exit 1
fi
echo -e "   ✅ 修复已应用"

# 收集所有 Swift 文件
echo ""
echo -e "${GREEN}📦 收集 Swift 源文件...${NC}"
SWIFT_FILES=$(find "$SOURCE_DIR" -name "*.swift" | tr '\n' ' ')
FILE_COUNT=$(find "$SOURCE_DIR" -name "*.swift" | wc -l | tr -d ' ')
echo -e "   找到 ${FILE_COUNT} 个 Swift 文件"

# 编译函数
compile_for_platform() {
    local PLATFORM=$1
    local SDK=$2
    local ARCH=$3
    local DEST_DIR=$4

    echo ""
    echo -e "${BLUE}📱 编译 ${PLATFORM}...${NC}"

    # 设置框架路径
    local WATCHPROTOCOL_FRAMEWORK="$WATCHPROTOCOL_SDK/${ARCH}/WatchProtocolSDK.framework"
    local ABPAR_FRAMEWORK="$ABPAR_TOOL/${ARCH}/ABParTool.framework"

    # 编译
    swiftc \
        -emit-library \
        -emit-module \
        -module-name WatchFaceSDK \
        -sdk $(xcrun --sdk $SDK --show-sdk-path) \
        -target $ARCH-apple-ios12.0 \
        -F "$WATCHPROTOCOL_SDK/${ARCH}" \
        -F "$ABPAR_TOOL/${ARCH}" \
        -Xlinker -rpath -Xlinker @executable_path/Frameworks \
        -Xlinker -rpath -Xlinker @loader_path/Frameworks \
        -o "$DEST_DIR/WatchFaceSDK" \
        $SWIFT_FILES

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}   ✅ ${PLATFORM} 编译成功${NC}"
    else
        echo -e "${RED}   ❌ ${PLATFORM} 编译失败${NC}"
        exit 1
    fi
}

# 编译各个平台
DEVICE_DIR="$BUILD_DIR/device"
SIMULATOR_DIR="$BUILD_DIR/simulator"
mkdir -p "$DEVICE_DIR"
mkdir -p "$SIMULATOR_DIR"

compile_for_platform "iOS Device" "iphoneos" "ios-arm64" "$DEVICE_DIR"
compile_for_platform "iOS Simulator" "iphonesimulator" "ios-arm64_x86_64-simulator" "$SIMULATOR_DIR"

# 创建 Framework 结构
echo ""
echo -e "${GREEN}📦 创建 Framework 结构...${NC}"

create_framework() {
    local DIR=$1
    local FRAMEWORK_DIR="$DIR/WatchFaceSDK.framework"

    mkdir -p "$FRAMEWORK_DIR/Modules"
    mkdir -p "$FRAMEWORK_DIR/Headers"
    mkdir -p "$FRAMEWORK_DIR/Frameworks"

    # 移动编译产物
    mv "$DIR/WatchFaceSDK" "$FRAMEWORK_DIR/"
    mv "$DIR/WatchFaceSDK.swiftmodule" "$FRAMEWORK_DIR/Modules/" 2>/dev/null || true

    # 复制依赖框架
    cp -R "$WATCHPROTOCOL_SDK/$(basename $DIR)/WatchProtocolSDK.framework" "$FRAMEWORK_DIR/Frameworks/"
    cp -R "$ABPAR_TOOL/$(basename $DIR)/ABParTool.framework" "$FRAMEWORK_DIR/Frameworks/"

    # 创建 Info.plist
    cat > "$FRAMEWORK_DIR/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>WatchFaceSDK</string>
    <key>CFBundleIdentifier</key>
    <string>com.anker.watch.WatchFaceSDK</string>
    <key>CFBundleVersion</key>
    <string>1.0.3</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.3</string>
</dict>
</plist>
EOF
}

create_framework "$DEVICE_DIR"
create_framework "$SIMULATOR_DIR"

# 创建 XCFramework
echo ""
echo -e "${GREEN}📦 创建 XCFramework...${NC}"
xcodebuild -create-xcframework \
    -framework "$DEVICE_DIR/WatchFaceSDK.framework" \
    -framework "$SIMULATOR_DIR/WatchFaceSDK.framework" \
    -output "$BUILD_DIR/WatchFaceSDK.xcframework"

echo -e "${GREEN}✅ XCFramework 创建完成${NC}"

# 更新 Output2
echo ""
echo -e "${GREEN}📤 更新 Output2...${NC}"
rm -rf "$OUTPUT_DIR/WatchFaceSDK.xcframework"
cp -R "$BUILD_DIR/WatchFaceSDK.xcframework" "$OUTPUT_DIR/"

# 更新版本文件
cat > "$OUTPUT_DIR/VERSION.txt" << EOF
WatchFaceSDK
Version: 1.0.3
Build Date: $(date +%Y-%m-%d)
Platform: iOS 12.0+
Swift Version: 5.0+

HOTFIX: Fixed EXC_BAD_ACCESS crash in uploadCustomWatchFace

Dependencies:
- WatchProtocolSDK v1.0.2

Changes in v1.0.3:
- 🔧 CRITICAL FIX: Removed duplicate UIImage.rawImageData extension
- 🔧 Fixed memory safety issue causing EXC_BAD_ACCESS
- 🔧 Now uses ABParTool's stable rawImageData implementation

Contents:
- Watch face upload functionality
- Custom watch face creation
- Market watch face transfer
- Image processing and PAR conversion
- Circle/Square screen adaptation
- Real-time transfer progress callbacks
EOF

# 显示结果
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}🎉 编译完成!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "📍 输出位置:"
echo -e "   ${OUTPUT_DIR}/WatchFaceSDK.xcframework"
echo ""

FRAMEWORK_SIZE=$(du -sh "$OUTPUT_DIR/WatchFaceSDK.xcframework" | cut -f1)
echo -e "📊 大小: ${FRAMEWORK_SIZE}"
echo ""

echo -e "${GREEN}✅ 可以将更新后的 Output2 目录提供给第三方使用${NC}"
echo -e "${YELLOW}⚠️  请通知用户这是关键的崩溃修复版本${NC}"
echo ""
