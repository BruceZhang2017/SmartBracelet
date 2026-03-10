#!/bin/bash

# WatchFaceSDK XCFramework 编译脚本（不依赖 Xcode 项目）
# 直接从源文件编译生成 Framework

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  WatchFaceSDK 编译工具 v1.0${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# 配置
FRAMEWORK_NAME="WatchFaceSDK"
VERSION="1.0.0"
BUILD_DIR="$(pwd)/build"
SOURCE_DIR="$(pwd)/WatchFaceSDK"

# 依赖路径
WATCH_PROTOCOL_SDK="../build/WatchProtocolSDK-Release/WatchProtocolSDK.xcframework"
ABPAR_TOOL="../ABParTool.xcframework"

# 清理
echo -e "${GREEN}🧹 清理旧文件...${NC}"
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# 检查源文件
echo -e "${GREEN}📂 检查源文件...${NC}"
SWIFT_FILES=$(find "${SOURCE_DIR}" -name "*.swift" | wc -l | tr -d ' ')
echo -e "   找到 ${SWIFT_FILES} 个 Swift 文件"

if [ "$SWIFT_FILES" -eq "0" ]; then
    echo -e "${RED}❌ 错误: 没有找到 Swift 源文件${NC}"
    exit 1
fi

# 检查依赖
echo -e "${GREEN}🔍 检查依赖...${NC}"
if [ ! -d "$WATCH_PROTOCOL_SDK" ]; then
    echo -e "${RED}❌ WatchProtocolSDK.xcframework 不存在: $WATCH_PROTOCOL_SDK${NC}"
    exit 1
fi
echo -e "   ✅ WatchProtocolSDK.xcframework"

if [ ! -d "$ABPAR_TOOL" ]; then
    echo -e "${RED}❌ ABParTool.xcframework 不存在: $ABPAR_TOOL${NC}"
    exit 1
fi
echo -e "   ✅ ABParTool.xcframework"
echo ""

# 提示用户
echo -e "${YELLOW}⚠️  注意: 此 SDK 需要在 Xcode 中创建 Framework 项目${NC}"
echo -e "${YELLOW}   请按以下步骤操作:${NC}"
echo ""
echo -e "${BLUE}📝 手动创建步骤:${NC}"
echo -e "1. 打开 Xcode"
echo -e "2. File > New > Project"
echo -e "3. 选择 Framework"
echo -e "4. Product Name: ${FRAMEWORK_NAME}"
echo -e "5. Organization Identifier: com.bruce.watch"
echo -e "6. 保存到当前目录: $(pwd)"
echo ""
echo -e "7. 添加源文件:"
echo -e "   - 将 WatchFaceSDK 文件夹拖入项目"
echo ""
echo -e "8. 添加依赖 Frameworks:"
echo -e "   - 将 ${WATCH_PROTOCOL_SDK} 拖入 Frameworks"
echo -e "   - 将 ${ABPAR_TOOL} 拖入 Frameworks"
echo ""
echo -e "9. Build Settings 配置:"
echo -e "   - Build Libraries for Distribution: YES"
echo -e "   - Skip Install: NO"
echo ""
echo -e "10. 运行以下命令编译:"
echo -e "    chmod +x build-with-xcode.sh"
echo -e "    ./build-with-xcode.sh"
echo ""

# 创建实际编译脚本
cat > build-with-xcode.sh << 'EOF'
#!/bin/bash

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

FRAMEWORK_NAME="WatchFaceSDK"
BUILD_DIR="./build"

echo -e "${GREEN}🏗️  开始编译 ${FRAMEWORK_NAME}...${NC}"

# 清理
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# 编译 iOS Simulator
echo -e "${BLUE}📱 编译 iOS Simulator...${NC}"
xcodebuild archive \
    -project ${FRAMEWORK_NAME}.xcodeproj \
    -scheme ${FRAMEWORK_NAME} \
    -configuration Release \
    -destination "generic/platform=iOS Simulator" \
    -archivePath "${BUILD_DIR}/${FRAMEWORK_NAME}-Simulator" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    ONLY_ACTIVE_ARCH=NO

# 编译 iOS Device
echo -e "${BLUE}📱 编译 iOS Device...${NC}"
xcodebuild archive \
    -project ${FRAMEWORK_NAME}.xcodeproj \
    -scheme ${FRAMEWORK_NAME} \
    -configuration Release \
    -destination "generic/platform=iOS" \
    -archivePath "${BUILD_DIR}/${FRAMEWORK_NAME}-iOS" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# 创建 XCFramework
echo -e "${BLUE}📦 创建 XCFramework...${NC}"
xcodebuild -create-xcframework \
    -framework "${BUILD_DIR}/${FRAMEWORK_NAME}-Simulator.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
    -framework "${BUILD_DIR}/${FRAMEWORK_NAME}-iOS.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
    -output "${BUILD_DIR}/${FRAMEWORK_NAME}.xcframework"

echo -e "${GREEN}✅ 编译完成！${NC}"
echo -e "📍 输出: ${BUILD_DIR}/${FRAMEWORK_NAME}.xcframework"

# 显示大小
du -sh "${BUILD_DIR}/${FRAMEWORK_NAME}.xcframework"
EOF

chmod +x build-with-xcode.sh

echo -e "${BLUE}================================${NC}"
echo -e "${GREEN}准备工作完成！${NC}"
echo -e "${BLUE}================================${NC}"
