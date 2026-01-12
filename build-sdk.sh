#!/bin/bash

# WatchProtocolSDK 编译脚本
# 版本: v1.0.2
# 生成 xcframework 用于分发

set -e

PROJECT_DIR=$(pwd)
SDK_NAME="WatchProtocolSDK"
SDK_VERSION="1.0.2"
BUILD_DIR="${PROJECT_DIR}/build"
OUTPUT_DIR="${PROJECT_DIR}/Output"
FRAMEWORK_NAME="${SDK_NAME}.xcframework"

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}开始编译 ${SDK_NAME} v${SDK_VERSION}${NC}"
echo -e "${GREEN}========================================${NC}"

# 清理之前的构建
echo -e "${YELLOW}清理之前的构建...${NC}"
rm -rf "${BUILD_DIR}"
rm -rf "${OUTPUT_DIR}/${FRAMEWORK_NAME}"

# 创建输出目录
mkdir -p "${OUTPUT_DIR}"

# 编译 iOS 设备架构
echo -e "${YELLOW}编译 iOS 设备架构 (arm64)...${NC}"
xcodebuild archive \
    -scheme SmartBracelet \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -archivePath "${BUILD_DIR}/ios.xcarchive" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    ONLY_ACTIVE_ARCH=NO

# 编译 iOS 模拟器架构
echo -e "${YELLOW}编译 iOS 模拟器架构 (x86_64, arm64)...${NC}"
xcodebuild archive \
    -scheme SmartBracelet \
    -configuration Release \
    -destination 'generic/platform=iOS Simulator' \
    -archivePath "${BUILD_DIR}/ios-simulator.xcarchive" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    ONLY_ACTIVE_ARCH=NO

# 创建 XCFramework
echo -e "${YELLOW}创建 XCFramework...${NC}"

# 检查是否有 WatchProtocolSDK.framework 在 archive 中
if [ ! -d "${BUILD_DIR}/ios.xcarchive/Products/Library/Frameworks" ]; then
    echo -e "${RED}错误: 找不到编译后的 framework${NC}"
    echo -e "${YELLOW}尝试使用其他方式编译...${NC}"

    # 直接编译 framework
    xcodebuild build \
        -scheme SmartBracelet \
        -configuration Release \
        -destination 'generic/platform=iOS' \
        -derivedDataPath "${BUILD_DIR}/DerivedData" \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES

    xcodebuild build \
        -scheme SmartBracelet \
        -configuration Release \
        -destination 'generic/platform=iOS Simulator' \
        -derivedDataPath "${BUILD_DIR}/DerivedData" \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES

    echo -e "${GREEN}编译完成！${NC}"
    echo -e "${YELLOW}注意: 由于项目结构原因，SDK 已作为主项目的一部分编译${NC}"
    echo -e "${YELLOW}SDK 源代码位于: ${PROJECT_DIR}/WatchProtocolSDK${NC}"

else
    xcodebuild -create-xcframework \
        -framework "${BUILD_DIR}/ios.xcarchive/Products/Library/Frameworks/${SDK_NAME}.framework" \
        -framework "${BUILD_DIR}/ios-simulator.xcarchive/Products/Library/Frameworks/${SDK_NAME}.framework" \
        -output "${OUTPUT_DIR}/${FRAMEWORK_NAME}"

    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}编译完成！${NC}"
    echo -e "${GREEN}XCFramework 位置: ${OUTPUT_DIR}/${FRAMEWORK_NAME}${NC}"
    echo -e "${GREEN}========================================${NC}"
fi

# 创建版本信息文件
cat > "${OUTPUT_DIR}/VERSION.txt" << EOF
WatchProtocolSDK
Version: ${SDK_VERSION}
Build Date: $(date +"%Y-%m-%d %H:%M:%S")
Platform: iOS 13.0+
Swift Version: 5.0+

Contents:
- Bluetooth device connection management
- Health data synchronization
- Protocol-based storage interface
EOF

echo -e "${GREEN}版本信息已保存到: ${OUTPUT_DIR}/VERSION.txt${NC}"
