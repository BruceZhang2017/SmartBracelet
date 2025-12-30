#!/bin/bash

# WatchFaceSDK Framework 编译脚本
# 用途：生成支持 iOS 真机和模拟器的 .xcframework

set -e  # 遇到错误立即退出

# ==================== 配置参数 ====================
FRAMEWORK_NAME="WatchFaceSDK"
SCHEME_NAME="WatchFaceSDK"
BUILD_DIR="$(pwd)/build"
DERIVED_DATA_DIR="$(pwd)/DerivedData"

# 版本信息
VERSION="1.0.0"
BUILD_NUMBER="1"

# 颜色输出
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   WatchFaceSDK Framework 编译工具${NC}"
echo -e "${BLUE}   版本: ${VERSION} (Build ${BUILD_NUMBER})${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# ==================== 清理旧文件 ====================
echo -e "${GREEN}🧹 清理旧的编译文件...${NC}"
rm -rf "${BUILD_DIR}"
rm -rf "${DERIVED_DATA_DIR}"
mkdir -p "${BUILD_DIR}"

# ==================== 检查依赖 ====================
echo -e "${GREEN}🔍 检查依赖 frameworks...${NC}"

WATCH_PROTOCOL_SDK="../build/WatchProtocolSDK-Release/WatchProtocolSDK.xcframework"
ABPAR_TOOL="../ABParTool.xcframework"

if [ ! -d "$WATCH_PROTOCOL_SDK" ]; then
    echo -e "${RED}❌ 错误: WatchProtocolSDK.xcframework 不存在${NC}"
    echo -e "${RED}   路径: $WATCH_PROTOCOL_SDK${NC}"
    exit 1
fi

if [ ! -d "$ABPAR_TOOL" ]; then
    echo -e "${RED}❌ 错误: ABParTool.xcframework 不存在${NC}"
    echo -e "${RED}   路径: $ABPAR_TOOL${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 依赖检查完成${NC}"
echo ""

# ==================== 编译 iOS 模拟器版本 ====================
echo -e "${GREEN}📱 编译 iOS Simulator 版本...${NC}"

xcodebuild archive \
    -workspace "${FRAMEWORK_NAME}.xcworkspace" \
    -scheme "${SCHEME_NAME}" \
    -configuration Release \
    -destination "generic/platform=iOS Simulator" \
    -archivePath "${BUILD_DIR}/${FRAMEWORK_NAME}-Simulator.xcarchive" \
    -derivedDataPath "${DERIVED_DATA_DIR}" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    ONLY_ACTIVE_ARCH=NO

echo -e "${GREEN}✅ iOS Simulator 编译完成${NC}"
echo ""

# ==================== 编译 iOS 真机版本 ====================
echo -e "${GREEN}📱 编译 iOS Device 版本...${NC}"

xcodebuild archive \
    -workspace "${FRAMEWORK_NAME}.xcworkspace" \
    -scheme "${SCHEME_NAME}" \
    -configuration Release \
    -destination "generic/platform=iOS" \
    -archivePath "${BUILD_DIR}/${FRAMEWORK_NAME}-iOS.xcarchive" \
    -derivedDataPath "${DERIVED_DATA_DIR}" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES

echo -e "${GREEN}✅ iOS Device 编译完成${NC}"
echo ""

# ==================== 创建 XCFramework ====================
echo -e "${GREEN}📦 创建 XCFramework...${NC}"

xcodebuild -create-xcframework \
    -framework "${BUILD_DIR}/${FRAMEWORK_NAME}-Simulator.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
    -framework "${BUILD_DIR}/${FRAMEWORK_NAME}-iOS.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
    -output "${BUILD_DIR}/${FRAMEWORK_NAME}.xcframework"

echo -e "${GREEN}✅ XCFramework 创建完成${NC}"
echo ""

# ==================== 清理临时文件 ====================
echo -e "${GREEN}🧹 清理临时文件...${NC}"
rm -rf "${DERIVED_DATA_DIR}"

# ==================== 显示结果 ====================
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}🎉 编译完成！${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "📍 Framework 位置:"
echo -e "   ${BUILD_DIR}/${FRAMEWORK_NAME}.xcframework"
echo ""

# 显示文件大小
FRAMEWORK_SIZE=$(du -sh "${BUILD_DIR}/${FRAMEWORK_NAME}.xcframework" | cut -f1)
echo -e "📊 文件大小: ${FRAMEWORK_SIZE}"
echo ""

# 显示支持的架构
echo -e "🏗️  支持的架构:"
xcodebuild -version
echo ""
find "${BUILD_DIR}/${FRAMEWORK_NAME}.xcframework" -name "${FRAMEWORK_NAME}" -type f -exec lipo -info {} \;
echo ""

echo -e "${GREEN}✅ 可以将以下目录提供给第三方使用：${NC}"
echo -e "   ${BUILD_DIR}/${FRAMEWORK_NAME}.xcframework"
echo ""
