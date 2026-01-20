#!/bin/bash

# WatchFaceSDK v1.0.3 快速重新编译脚本
# 修复 uploadCustomWatchFace 崩溃问题

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
WORKSPACE="SmartBracelet.xcworkspace"
SCHEME="WatchFaceSDK"
BUILD_DIR="$PROJECT_DIR/build/WatchFaceSDK-Release"
OUTPUT_DIR="$PROJECT_DIR/Output2"

# 验证修复
echo -e "${GREEN}🔍 验证修复已应用...${NC}"
SOURCE_FILE="$PROJECT_DIR/WatchFaceSDK/WatchFaceSDK/Extensions/ImageProcessor.swift"
if grep -q "var rawImageData: Data?" "$SOURCE_FILE" 2>/dev/null; then
    echo -e "${RED}❌ 错误: 有问题的 rawImageData 扩展仍然存在!${NC}"
    echo -e "${RED}   文件: $SOURCE_FILE${NC}"
    echo ""
    echo -e "${YELLOW}修复应该已经应用。请检查文件末尾是否还有 'extension UIImage' 代码${NC}"
    exit 1
fi
echo -e "   ✅ 修复已应用"
echo ""

# 清理
echo -e "${GREEN}🧹 清理旧的构建文件...${NC}"
rm -rf "$BUILD_DIR"
rm -rf "$PROJECT_DIR/DerivedData"

# 编译 iOS Device
echo ""
echo -e "${GREEN}📱 编译 iOS Device (arm64)...${NC}"
xcodebuild archive \
    -workspace "$WORKSPACE" \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination "generic/platform=iOS" \
    -archivePath "$BUILD_DIR/WatchFaceSDK-iOS.xcarchive" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    -quiet

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ iOS Device 编译成功${NC}"
else
    echo -e "${RED}❌ iOS Device 编译失败${NC}"
    exit 1
fi

# 编译 iOS Simulator
echo ""
echo -e "${GREEN}📱 编译 iOS Simulator (arm64 + x86_64)...${NC}"
xcodebuild archive \
    -workspace "$WORKSPACE" \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination "generic/platform=iOS Simulator" \
    -archivePath "$BUILD_DIR/WatchFaceSDK-Simulator.xcarchive" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    ONLY_ACTIVE_ARCH=NO \
    -quiet

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ iOS Simulator 编译成功${NC}"
else
    echo -e "${RED}❌ iOS Simulator 编译失败${NC}"
    exit 1
fi

# 创建 XCFramework
echo ""
echo -e "${GREEN}📦 创建 XCFramework...${NC}"
xcodebuild -create-xcframework \
    -framework "$BUILD_DIR/WatchFaceSDK-iOS.xcarchive/Products/Library/Frameworks/WatchFaceSDK.framework" \
    -framework "$BUILD_DIR/WatchFaceSDK-Simulator.xcarchive/Products/Library/Frameworks/WatchFaceSDK.framework" \
    -output "$BUILD_DIR/WatchFaceSDK.xcframework"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ XCFramework 创建完成${NC}"
else
    echo -e "${RED}❌ XCFramework 创建失败${NC}"
    exit 1
fi

# 更新 Output2
echo ""
echo -e "${GREEN}📤 更新 Output2...${NC}"
if [ -d "$OUTPUT_DIR/WatchFaceSDK.xcframework" ]; then
    echo -e "   备份旧版本到 Output2/WatchFaceSDK.xcframework.v1.0.2.backup"
    rm -rf "$OUTPUT_DIR/WatchFaceSDK.xcframework.v1.0.2.backup"
    mv "$OUTPUT_DIR/WatchFaceSDK.xcframework" "$OUTPUT_DIR/WatchFaceSDK.xcframework.v1.0.2.backup"
fi

cp -R "$BUILD_DIR/WatchFaceSDK.xcframework" "$OUTPUT_DIR/"
echo -e "${GREEN}✅ Output2 已更新${NC}"

# 更新版本文件
echo ""
echo -e "${GREEN}📝 更新版本信息...${NC}"
cat > "$OUTPUT_DIR/VERSION.txt" << 'EOF'
WatchFaceSDK
Version: 1.0.3
Build Date: 2026-01-14
Platform: iOS 12.0+
Swift Version: 5.0+

⚠️  CRITICAL HOTFIX: Fixed EXC_BAD_ACCESS crash in uploadCustomWatchFace

Dependencies:
- WatchProtocolSDK v1.0.2
- ABParTool.xcframework (included)

Release Notes:
v1.0.3 (2026-01-14) - HOTFIX
- 🔧 CRITICAL: Fixed EXC_BAD_ACCESS crash in UIImage.rawImageData
- 🔧 Removed duplicate UIImage extension causing symbol conflict
- 🔧 Now uses ABParTool's stable Objective-C rawImageData implementation
- ✅ No API changes - drop-in replacement for v1.0.2

v1.0.2 (2026-01-11)
- Synchronized version with WatchProtocolSDK v1.0.2
- Enhanced transfer stability
- Improved image processing performance

v1.0.1 (2026-01-05)
- Added support for custom watch faces
- Improved market watch face upload

v1.0.0 (2025-12-30)
- Initial release

Contents:
- Watch face upload functionality
- Custom watch face creation
- Market watch face transfer
- Image processing and PAR conversion
- Circle/Square screen adaptation
- Real-time transfer progress callbacks

IMPORTANT:
This is a critical bug fix release. All users experiencing crashes
when calling uploadCustomWatchFace() should upgrade immediately.
EOF

# 显示结果
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}🎉 编译完成!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 显示文件信息
FRAMEWORK_SIZE=$(du -sh "$OUTPUT_DIR/WatchFaceSDK.xcframework" | cut -f1)
echo -e "📍 输出位置:"
echo -e "   ${OUTPUT_DIR}/WatchFaceSDK.xcframework"
echo ""
echo -e "📊 大小: ${FRAMEWORK_SIZE}"
echo ""

# 显示支持的架构
echo -e "🏗️  支持的架构:"
find "$OUTPUT_DIR/WatchFaceSDK.xcframework" -name "WatchFaceSDK" -type f -exec lipo -info {} \; 2>/dev/null
echo ""

# 清理说明
echo -e "${GREEN}✅ 发布准备就绪!${NC}"
echo ""
echo -e "${YELLOW}📦 提供给第三方的文件:${NC}"
echo -e "   • Output2/WatchFaceSDK.xcframework"
echo -e "   • Output2/VERSION.txt"
echo -e "   • Output2/README.md"
echo -e "   • Output2/HOTFIX-v1.0.3-CRASH-FIX.md"
echo -e "   • Output2/WatchFaceSDK-接入文档-中文.md"
echo -e "   • Output2/WatchFaceSDK-Integration-Guide-EN.md"
echo ""
echo -e "${RED}⚠️  重要提醒:${NC}"
echo -e "   请通知所有用户这是关键的崩溃修复版本!"
echo -e "   v1.0.2 版本存在严重的内存访问问题,必须升级。"
echo ""
