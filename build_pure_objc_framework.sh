#!/bin/bash

# WatchFaceSDK-ObjC 纯 Objective-C Framework 构建脚本
# 完全使用 Objective-C，无 Swift 依赖

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  WatchFaceSDK-ObjC 纯ObjC构建${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 配置
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
FRAMEWORK_NAME="WatchFaceSDK_ObjC"
BUILD_DIR="$PROJECT_DIR/build/WatchFaceObjC-Pure"
OUTPUT_DIR="$PROJECT_DIR/Output-WatchFace-ObjC"

# 依赖（使用动态库版本）
WATCHPROTOCOL_FRAMEWORK="$PROJECT_DIR/Output-ObjC-Dynamic/WatchProtocolSDK.xcframework"

# 清理
echo -e "${GREEN}🧹 清理构建目录...${NC}"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$OUTPUT_DIR"

# 检查依赖
echo -e "${GREEN}🔍 检查依赖...${NC}"
if [ ! -d "$WATCHPROTOCOL_FRAMEWORK" ]; then
    echo -e "${RED}❌ WatchProtocolSDK.xcframework 不存在${NC}"
    echo -e "   请先运行: ./build_framework.sh"
    exit 1
fi
echo -e "   ✅ WatchProtocolSDK.xcframework"

# 收集源文件 (仅 ObjC，排除 Swift)
echo -e "${GREEN}📦 收集源文件...${NC}"
OBJC_SOURCES=$(find "$PROJECT_DIR/WatchFaceSDK-Pure-ObjC" -name "*.m" ! -path "*/Examples/*" ! -path "*/.*")
OBJC_HEADERS=$(find "$PROJECT_DIR/WatchFaceSDK-Pure-ObjC" -name "*.h" ! -path "*/Examples/*" ! -path "*/.*")

echo "   找到 $(echo "$OBJC_SOURCES" | wc -l | tr -d ' ') 个 .m 文件"
echo "   找到 $(echo "$OBJC_HEADERS" | wc -l | tr -d ' ') 个 .h 文件"

# 为每个架构编译
echo ""
echo -e "${GREEN}📱 编译 iOS Device (arm64)...${NC}"

# iOS Device
DEVICE_BUILD="$BUILD_DIR/device"
mkdir -p "$DEVICE_BUILD"

# WatchProtocolSDK framework 路径（设备版本）
# 动态库的 framework 在子目录中
DEVICE_FRAMEWORK_PATH="$WATCHPROTOCOL_FRAMEWORK/ios-arm64/WatchProtocolSDK.framework"
ABPARTOOL_FRAMEWORK_PATH="$PROJECT_DIR/ABParTool.xcframework/ios-arm64/ABParTool.framework"

# 创建临时包含目录以支持 framework 风格的 import
TEMP_INCLUDE_DIR="$BUILD_DIR/temp_includes_device"
mkdir -p "$TEMP_INCLUDE_DIR/WatchProtocolSDK"
mkdir -p "$TEMP_INCLUDE_DIR/ABParTool"
# 递归查找并复制所有头文件（扁平化到根目录）
find "$DEVICE_FRAMEWORK_PATH/Headers" -name "*.h" -exec cp {} "$TEMP_INCLUDE_DIR/WatchProtocolSDK/" \;
find "$ABPARTOOL_FRAMEWORK_PATH/Headers" -name "*.h" -exec cp {} "$TEMP_INCLUDE_DIR/ABParTool/" \;
# 修复所有头文件中的 angle bracket imports 为 quote imports
find "$TEMP_INCLUDE_DIR/WatchProtocolSDK" -name "*.h" -exec sed -i '' 's|<WatchProtocolSDK/\([^>]*\)>|"\1"|g' {} \;
find "$TEMP_INCLUDE_DIR/ABParTool" -name "*.h" -exec sed -i '' 's|<ABParTool/\([^>]*\)>|"\1"|g' {} \; 2>/dev/null || true

# 编译 .m 文件为 .o
for source in $OBJC_SOURCES; do
    filename=$(basename "$source" .m)
    echo "   编译 $filename.m"

    xcrun clang -x objective-c \
        -target arm64-apple-ios13.0 \
        -isysroot $(xcrun --sdk iphoneos --show-sdk-path) \
        -I"$TEMP_INCLUDE_DIR" \
        -I"$DEVICE_FRAMEWORK_PATH/Headers" \
        -I"$PROJECT_DIR/WatchFaceSDK-Pure-ObjC" \
        -I"$PROJECT_DIR/WatchFaceSDK-Pure-ObjC/Core" \
        -I"$PROJECT_DIR/WatchFaceSDK-Pure-ObjC/Models" \
        -I"$PROJECT_DIR/WatchFaceSDK-Pure-ObjC/Protocols" \
        -fobjc-arc \
        -fPIC \
        -c "$source" \
        -o "$DEVICE_BUILD/${filename}.o"
done

# 创建动态库
echo -e "${GREEN}🔗 链接 Device Framework...${NC}"
DEVICE_OBJS=$(find "$DEVICE_BUILD" -name "*.o")

# 动态库链接 WatchProtocolSDK.framework
# DEVICE_FRAMEWORK_PATH 已经指向 .../WatchProtocolSDK.framework，需要使用其父目录
DEVICE_FRAMEWORK_SEARCH_PATH="$WATCHPROTOCOL_FRAMEWORK/ios-arm64"

xcrun clang -dynamiclib \
    -target arm64-apple-ios13.0 \
    -isysroot $(xcrun --sdk iphoneos --show-sdk-path) \
    -framework Foundation \
    -framework UIKit \
    -framework CoreGraphics \
    -framework CoreBluetooth \
    -F"$DEVICE_FRAMEWORK_SEARCH_PATH" \
    -framework WatchProtocolSDK \
    -F"$(dirname "$ABPARTOOL_FRAMEWORK_PATH")" \
    -framework ABParTool \
    -install_name "@rpath/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}" \
    -Xlinker -rpath -Xlinker @executable_path/Frameworks \
    -Xlinker -rpath -Xlinker @loader_path/Frameworks \
    -fobjc-arc \
    -fobjc-link-runtime \
    $DEVICE_OBJS \
    -o "$DEVICE_BUILD/lib${FRAMEWORK_NAME}.dylib"

# 创建 Framework 结构
DEVICE_FRAMEWORK="$DEVICE_BUILD/${FRAMEWORK_NAME}.framework"
mkdir -p "$DEVICE_FRAMEWORK"
cp "$DEVICE_BUILD/lib${FRAMEWORK_NAME}.dylib" "$DEVICE_FRAMEWORK/${FRAMEWORK_NAME}"

# 复制头文件
mkdir -p "$DEVICE_FRAMEWORK/Headers"
for header in $OBJC_HEADERS; do
    cp "$header" "$DEVICE_FRAMEWORK/Headers/"
done

# 复制 modulemap
mkdir -p "$DEVICE_FRAMEWORK/Modules"
if [ -f "$PROJECT_DIR/WatchFaceSDK-Pure-ObjC/module.modulemap" ]; then
    cp "$PROJECT_DIR/WatchFaceSDK-Pure-ObjC/module.modulemap" "$DEVICE_FRAMEWORK/Modules/module.modulemap"
fi

# 创建 Info.plist
cat > "$DEVICE_FRAMEWORK/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${FRAMEWORK_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.anker.watch.${FRAMEWORK_NAME}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${FRAMEWORK_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>MinimumOSVersion</key>
    <string>13.0</string>
</dict>
</plist>
EOF

echo ""
echo -e "${GREEN}📱 编译 iOS Simulator (arm64 + x86_64)...${NC}"

# iOS Simulator arm64
SIM_ARM64_BUILD="$BUILD_DIR/simulator-arm64"
mkdir -p "$SIM_ARM64_BUILD"

# WatchProtocolSDK framework 路径（模拟器版本）
# 动态库的 framework 在子目录中
SIM_FRAMEWORK_PATH="$WATCHPROTOCOL_FRAMEWORK/ios-arm64_x86_64-simulator/WatchProtocolSDK.framework"
ABPARTOOL_SIM_FRAMEWORK_PATH="$PROJECT_DIR/ABParTool.xcframework/ios-arm64_x86_64-simulator/ABParTool.framework"

# 创建临时包含目录以支持 framework 风格的 import
TEMP_INCLUDE_DIR_SIM="$BUILD_DIR/temp_includes_sim"
mkdir -p "$TEMP_INCLUDE_DIR_SIM/WatchProtocolSDK"
mkdir -p "$TEMP_INCLUDE_DIR_SIM/ABParTool"
# 递归查找并复制所有头文件（扁平化到根目录）
find "$SIM_FRAMEWORK_PATH/Headers" -name "*.h" -exec cp {} "$TEMP_INCLUDE_DIR_SIM/WatchProtocolSDK/" \;
find "$ABPARTOOL_SIM_FRAMEWORK_PATH/Headers" -name "*.h" -exec cp {} "$TEMP_INCLUDE_DIR_SIM/ABParTool/" \;
# 修复所有头文件中的 angle bracket imports 为 quote imports
find "$TEMP_INCLUDE_DIR_SIM/WatchProtocolSDK" -name "*.h" -exec sed -i '' 's|<WatchProtocolSDK/\([^>]*\)>|"\1"|g' {} \;
find "$TEMP_INCLUDE_DIR_SIM/ABParTool" -name "*.h" -exec sed -i '' 's|<ABParTool/\([^>]*\)>|"\1"|g' {} \; 2>/dev/null || true

for source in $OBJC_SOURCES; do
    filename=$(basename "$source" .m)

    xcrun clang -x objective-c \
        -target arm64-apple-ios13.0-simulator \
        -isysroot $(xcrun --sdk iphonesimulator --show-sdk-path) \
        -I"$TEMP_INCLUDE_DIR_SIM" \
        -I"$PROJECT_DIR/WatchFaceSDK-Pure-ObjC" \
        -I"$PROJECT_DIR/WatchFaceSDK-Pure-ObjC/Core" \
        -I"$PROJECT_DIR/WatchFaceSDK-Pure-ObjC/Models" \
        -I"$PROJECT_DIR/WatchFaceSDK-Pure-ObjC/Protocols" \
        -fobjc-arc \
        -fPIC \
        -c "$source" \
        -o "$SIM_ARM64_BUILD/${filename}.o"
done

# iOS Simulator x86_64
SIM_X86_BUILD="$BUILD_DIR/simulator-x86_64"
mkdir -p "$SIM_X86_BUILD"

for source in $OBJC_SOURCES; do
    filename=$(basename "$source" .m)

    xcrun clang -x objective-c \
        -target x86_64-apple-ios13.0-simulator \
        -isysroot $(xcrun --sdk iphonesimulator --show-sdk-path) \
        -I"$TEMP_INCLUDE_DIR_SIM" \
        -I"$PROJECT_DIR/WatchFaceSDK-Pure-ObjC" \
        -I"$PROJECT_DIR/WatchFaceSDK-Pure-ObjC/Core" \
        -I"$PROJECT_DIR/WatchFaceSDK-Pure-ObjC/Models" \
        -I"$PROJECT_DIR/WatchFaceSDK-Pure-ObjC/Protocols" \
        -fobjc-arc \
        -fPIC \
        -c "$source" \
        -o "$SIM_X86_BUILD/${filename}.o"
done

# 创建 Simulator Framework (Fat Binary)
echo -e "${GREEN}🔗 链接 Simulator Framework...${NC}"

SIM_ARM64_OBJS=$(find "$SIM_ARM64_BUILD" -name "*.o")
SIM_X86_OBJS=$(find "$SIM_X86_BUILD" -name "*.o")

# SIM_FRAMEWORK_PATH 已经指向 .../WatchProtocolSDK.framework，需要使用其父目录
SIM_FRAMEWORK_SEARCH_PATH="$WATCHPROTOCOL_FRAMEWORK/ios-arm64_x86_64-simulator"

# arm64 - 动态库链接 WatchProtocolSDK.framework
xcrun clang -dynamiclib \
    -target arm64-apple-ios13.0-simulator \
    -isysroot $(xcrun --sdk iphonesimulator --show-sdk-path) \
    -framework Foundation \
    -framework UIKit \
    -framework CoreGraphics \
    -framework CoreBluetooth \
    -F"$SIM_FRAMEWORK_SEARCH_PATH" \
    -framework WatchProtocolSDK \
    -F"$(dirname "$ABPARTOOL_SIM_FRAMEWORK_PATH")" \
    -framework ABParTool \
    -install_name "@rpath/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}" \
    -Xlinker -rpath -Xlinker @executable_path/Frameworks \
    -Xlinker -rpath -Xlinker @loader_path/Frameworks \
    -fobjc-arc \
    -fobjc-link-runtime \
    $SIM_ARM64_OBJS \
    -o "$SIM_ARM64_BUILD/lib${FRAMEWORK_NAME}-arm64.dylib"

# x86_64 - 动态库链接 WatchProtocolSDK.framework
xcrun clang -dynamiclib \
    -target x86_64-apple-ios13.0-simulator \
    -isysroot $(xcrun --sdk iphonesimulator --show-sdk-path) \
    -framework Foundation \
    -framework UIKit \
    -framework CoreGraphics \
    -framework CoreBluetooth \
    -F"$SIM_FRAMEWORK_SEARCH_PATH" \
    -framework WatchProtocolSDK \
    -F"$(dirname "$ABPARTOOL_SIM_FRAMEWORK_PATH")" \
    -framework ABParTool \
    -install_name "@rpath/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}" \
    -Xlinker -rpath -Xlinker @executable_path/Frameworks \
    -Xlinker -rpath -Xlinker @loader_path/Frameworks \
    -fobjc-arc \
    -fobjc-link-runtime \
    $SIM_X86_OBJS \
    -o "$SIM_X86_BUILD/lib${FRAMEWORK_NAME}-x86_64.dylib"

# 合并为 fat binary
lipo -create \
    "$SIM_ARM64_BUILD/lib${FRAMEWORK_NAME}-arm64.dylib" \
    "$SIM_X86_BUILD/lib${FRAMEWORK_NAME}-x86_64.dylib" \
    -output "$BUILD_DIR/lib${FRAMEWORK_NAME}-simulator.dylib"

# 创建 Simulator Framework 结构
SIM_DIR="$BUILD_DIR/simulator"
mkdir -p "$SIM_DIR"
SIM_FRAMEWORK="$SIM_DIR/${FRAMEWORK_NAME}.framework"
mkdir -p "$SIM_FRAMEWORK"
cp "$BUILD_DIR/lib${FRAMEWORK_NAME}-simulator.dylib" "$SIM_FRAMEWORK/${FRAMEWORK_NAME}"

# 复制头文件
mkdir -p "$SIM_FRAMEWORK/Headers"
for header in $OBJC_HEADERS; do
    cp "$header" "$SIM_FRAMEWORK/Headers/"
done

# 复制 modulemap
mkdir -p "$SIM_FRAMEWORK/Modules"
if [ -f "$PROJECT_DIR/WatchFaceSDK-Pure-ObjC/module.modulemap" ]; then
    cp "$PROJECT_DIR/WatchFaceSDK-Pure-ObjC/module.modulemap" "$SIM_FRAMEWORK/Modules/module.modulemap"
fi

# 复制 Info.plist
cp "$DEVICE_FRAMEWORK/Info.plist" "$SIM_FRAMEWORK/"

echo ""
echo -e "${GREEN}📦 创建 XCFramework...${NC}"

xcodebuild -create-xcframework \
    -framework "$DEVICE_FRAMEWORK" \
    -framework "$SIM_FRAMEWORK" \
    -output "$OUTPUT_DIR/${FRAMEWORK_NAME}.xcframework"

echo ""
echo -e "${GREEN}✅ 构建完成！${NC}"
echo ""
echo -e "📍 输出位置: ${BLUE}$OUTPUT_DIR/${FRAMEWORK_NAME}.xcframework${NC}"
echo ""

# 显示大小
du -sh "$OUTPUT_DIR/${FRAMEWORK_NAME}.xcframework"

echo ""
echo -e "${GREEN}🎉 纯 Objective-C Framework 构建成功！${NC}"
