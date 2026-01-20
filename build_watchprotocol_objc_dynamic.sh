#!/bin/bash

# WatchProtocolSDK-ObjC 动态 Framework 打包脚本
# 从 Objective-C 源码构建真正的动态 Framework XCFramework

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  WatchProtocolSDK-ObjC 动态 Framework ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 配置
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SDK_NAME="WatchProtocolSDK"
SDK_SOURCE_DIR="$PROJECT_DIR/WatchProtocolSDK-ObjC"
BUILD_DIR="$PROJECT_DIR/build/WatchProtocolSDK-ObjC-Dynamic"
OUTPUT_DIR="$PROJECT_DIR/Output-ObjC-Dynamic"
SDK_VERSION="2.0.2"

# 清理
echo -e "${GREEN}🧹 清理旧的构建文件...${NC}"
rm -rf "$BUILD_DIR"
rm -rf "$OUTPUT_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$OUTPUT_DIR"

# 创建临时目录
TEMP_DIR="$BUILD_DIR/Temp"
DEVICE_DIR="$BUILD_DIR/Device"
SIMULATOR_DIR="$BUILD_DIR/Simulator"
mkdir -p "$TEMP_DIR"
mkdir -p "$DEVICE_DIR"
mkdir -p "$SIMULATOR_DIR"

# 复制源文件
echo -e "${GREEN}📦 准备源文件...${NC}"
cp -R "$SDK_SOURCE_DIR"/* "$TEMP_DIR/"

# 收集所有源文件和头文件
echo -e "${GREEN}🔍 收集源文件...${NC}"
SOURCE_FILES=$(find "$TEMP_DIR" -name "*.m" ! -path "*/Examples/*" ! -path "*/.*")
HEADER_FILES=$(find "$TEMP_DIR" -name "*.h" ! -path "*/Examples/*" ! -path "*/.*")

SOURCE_COUNT=$(echo "$SOURCE_FILES" | wc -l | tr -d ' ')
HEADER_COUNT=$(echo "$HEADER_FILES" | wc -l | tr -d ' ')
echo "   找到 $SOURCE_COUNT 个源文件"
echo "   找到 $HEADER_COUNT 个头文件"

# ====================
# 编译 iOS 设备版本
# ====================
echo ""
echo -e "${GREEN}📱 编译 iOS 设备版本 (arm64)...${NC}"

DEVICE_OBJECTS=""
for source in $SOURCE_FILES; do
    filename=$(basename "$source" .m)
    echo "   编译: $filename.m"

    xcrun clang -x objective-c \
        -target arm64-apple-ios13.0 \
        -isysroot $(xcrun --sdk iphoneos --show-sdk-path) \
        -I"$TEMP_DIR" \
        -I"$TEMP_DIR/Core" \
        -I"$TEMP_DIR/Models" \
        -I"$TEMP_DIR/Protocols" \
        -I"$TEMP_DIR/Utils" \
        -I"$TEMP_DIR/Extensions" \
        -fmodules \
        -fobjc-arc \
        -fPIC \
        -c "$source" \
        -o "$DEVICE_DIR/${filename}.o"

    DEVICE_OBJECTS="$DEVICE_OBJECTS $DEVICE_DIR/${filename}.o"
done

# 链接成动态库
echo "   链接动态库..."
xcrun clang -dynamiclib \
    -target arm64-apple-ios13.0 \
    -isysroot $(xcrun --sdk iphoneos --show-sdk-path) \
    -install_name @rpath/${SDK_NAME}.framework/${SDK_NAME} \
    -Xlinker -rpath -Xlinker @executable_path/Frameworks \
    -Xlinker -rpath -Xlinker @loader_path/Frameworks \
    -framework CoreBluetooth \
    -framework Foundation \
    -fobjc-arc \
    -fobjc-link-runtime \
    $DEVICE_OBJECTS \
    -o "$DEVICE_DIR/${SDK_NAME}"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ iOS 设备版本链接失败${NC}"
    exit 1
fi

echo -e "${GREEN}✅ iOS 设备版本编译成功${NC}"

# ====================
# 编译模拟器版本
# ====================
echo ""
echo -e "${GREEN}🖥 编译模拟器版本 (arm64 + x86_64)...${NC}"

# arm64 模拟器
SIM_ARM64_OBJECTS=""
for source in $SOURCE_FILES; do
    filename=$(basename "$source" .m)
    echo "   编译 (arm64): $filename.m"

    xcrun clang -x objective-c \
        -target arm64-apple-ios13.0-simulator \
        -isysroot $(xcrun --sdk iphonesimulator --show-sdk-path) \
        -I"$TEMP_DIR" \
        -I"$TEMP_DIR/Core" \
        -I"$TEMP_DIR/Models" \
        -I"$TEMP_DIR/Protocols" \
        -I"$TEMP_DIR/Utils" \
        -I"$TEMP_DIR/Extensions" \
        -fmodules \
        -fobjc-arc \
        -fPIC \
        -c "$source" \
        -o "$SIMULATOR_DIR/${filename}-arm64.o"

    SIM_ARM64_OBJECTS="$SIM_ARM64_OBJECTS $SIMULATOR_DIR/${filename}-arm64.o"
done

# x86_64 模拟器
SIM_X86_64_OBJECTS=""
for source in $SOURCE_FILES; do
    filename=$(basename "$source" .m)
    echo "   编译 (x86_64): $filename.m"

    xcrun clang -x objective-c \
        -target x86_64-apple-ios13.0-simulator \
        -isysroot $(xcrun --sdk iphonesimulator --show-sdk-path) \
        -I"$TEMP_DIR" \
        -I"$TEMP_DIR/Core" \
        -I"$TEMP_DIR/Models" \
        -I"$TEMP_DIR/Protocols" \
        -I"$TEMP_DIR/Utils" \
        -I"$TEMP_DIR/Extensions" \
        -fmodules \
        -fobjc-arc \
        -fPIC \
        -c "$source" \
        -o "$SIMULATOR_DIR/${filename}-x86_64.o"

    SIM_X86_64_OBJECTS="$SIM_X86_64_OBJECTS $SIMULATOR_DIR/${filename}-x86_64.o"
done

# 链接 arm64 模拟器动态库
echo "   链接 arm64 模拟器动态库..."
xcrun clang -dynamiclib \
    -target arm64-apple-ios13.0-simulator \
    -isysroot $(xcrun --sdk iphonesimulator --show-sdk-path) \
    -install_name @rpath/${SDK_NAME}.framework/${SDK_NAME} \
    -Xlinker -rpath -Xlinker @executable_path/Frameworks \
    -Xlinker -rpath -Xlinker @loader_path/Frameworks \
    -framework CoreBluetooth \
    -framework Foundation \
    -fobjc-arc \
    -fobjc-link-runtime \
    $SIM_ARM64_OBJECTS \
    -o "$SIMULATOR_DIR/${SDK_NAME}-arm64"

# 链接 x86_64 模拟器动态库
echo "   链接 x86_64 模拟器动态库..."
xcrun clang -dynamiclib \
    -target x86_64-apple-ios13.0-simulator \
    -isysroot $(xcrun --sdk iphonesimulator --show-sdk-path) \
    -install_name @rpath/${SDK_NAME}.framework/${SDK_NAME} \
    -Xlinker -rpath -Xlinker @executable_path/Frameworks \
    -Xlinker -rpath -Xlinker @loader_path/Frameworks \
    -framework CoreBluetooth \
    -framework Foundation \
    -fobjc-arc \
    -fobjc-link-runtime \
    $SIM_X86_64_OBJECTS \
    -o "$SIMULATOR_DIR/${SDK_NAME}-x86_64"

# 合并模拟器架构
echo "   合并模拟器架构..."
lipo -create \
    "$SIMULATOR_DIR/${SDK_NAME}-arm64" \
    "$SIMULATOR_DIR/${SDK_NAME}-x86_64" \
    -output "$SIMULATOR_DIR/${SDK_NAME}"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ 模拟器版本链接失败${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 模拟器版本编译成功${NC}"

# ====================
# 创建 Framework 结构
# ====================
echo ""
echo -e "${GREEN}📦 创建 Framework 结构...${NC}"

# 设备版本 Framework
DEVICE_FRAMEWORK="$BUILD_DIR/Device/${SDK_NAME}.framework"
mkdir -p "$DEVICE_FRAMEWORK/Headers"
mkdir -p "$DEVICE_FRAMEWORK/Modules"
cp "$DEVICE_DIR/${SDK_NAME}" "$DEVICE_FRAMEWORK/${SDK_NAME}"
for header in $HEADER_FILES; do
    cp "$header" "$DEVICE_FRAMEWORK/Headers/"
done

# 模拟器版本 Framework
SIMULATOR_FRAMEWORK="$BUILD_DIR/Simulator/${SDK_NAME}.framework"
mkdir -p "$SIMULATOR_FRAMEWORK/Headers"
mkdir -p "$SIMULATOR_FRAMEWORK/Modules"
cp "$SIMULATOR_DIR/${SDK_NAME}" "$SIMULATOR_FRAMEWORK/${SDK_NAME}"
for header in $HEADER_FILES; do
    cp "$header" "$SIMULATOR_FRAMEWORK/Headers/"
done

# 创建 Info.plist
for framework in "$DEVICE_FRAMEWORK" "$SIMULATOR_FRAMEWORK"; do
    cat > "$framework/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${SDK_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.huaxin.${SDK_NAME}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${SDK_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>${SDK_VERSION}</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>MinimumOSVersion</key>
    <string>13.0</string>
</dict>
</plist>
EOF
done

# 创建 module.modulemap
for framework in "$DEVICE_FRAMEWORK" "$SIMULATOR_FRAMEWORK"; do
    cat > "$framework/Modules/module.modulemap" << EOF
framework module ${SDK_NAME} {
    umbrella header "${SDK_NAME}.h"
    export *
    module * { export * }
}
EOF
done

# 代码签名
echo "   签名 Framework..."
codesign --force --sign - "$DEVICE_FRAMEWORK/${SDK_NAME}"
codesign --force --sign - "$SIMULATOR_FRAMEWORK/${SDK_NAME}"

# ====================
# 创建 XCFramework
# ====================
echo ""
echo -e "${GREEN}🔨 创建 XCFramework...${NC}"
xcodebuild -create-xcframework \
    -framework "$DEVICE_FRAMEWORK" \
    -framework "$SIMULATOR_FRAMEWORK" \
    -output "$OUTPUT_DIR/${SDK_NAME}.xcframework"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ XCFramework 创建失败${NC}"
    exit 1
fi

echo -e "${GREEN}✅ XCFramework 创建成功${NC}"

# ====================
# 验证符号
# ====================
echo ""
echo -e "${GREEN}🔍 验证符号...${NC}"
DEVICE_BINARY="$OUTPUT_DIR/${SDK_NAME}.xcframework/ios-arm64/${SDK_NAME}.framework/${SDK_NAME}"

if nm -g "$DEVICE_BINARY" | grep -q "OBJC_CLASS.*WPBluetoothManager"; then
    echo -e "${GREEN}   ✅ 找到 WPBluetoothManager 符号${NC}"
else
    echo -e "${RED}   ❌ 未找到 WPBluetoothManager 符号${NC}"
fi

if nm -g "$DEVICE_BINARY" | grep -q "OBJC_CLASS.*WPDeviceManager"; then
    echo -e "${GREEN}   ✅ 找到 WPDeviceManager 符号${NC}"
else
    echo -e "${RED}   ❌ 未找到 WPDeviceManager 符号${NC}"
fi

if nm -g "$DEVICE_BINARY" | grep -q "OBJC_CLASS.*WPEmptyHealthDataStorage"; then
    echo -e "${GREEN}   ✅ 找到 WPEmptyHealthDataStorage 符号${NC}"
else
    echo -e "${RED}   ❌ 未找到 WPEmptyHealthDataStorage 符号${NC}"
fi

# 检查是否有 Swift 符号
if nm -g "$DEVICE_BINARY" | grep -q "_Tt"; then
    echo -e "${YELLOW}   ⚠️  警告: 检测到 Swift 符号${NC}"
else
    echo -e "${GREEN}   ✅ 无 Swift 符号（纯 Objective-C）${NC}"
fi

# ====================
# 复制文档
# ====================
echo ""
echo -e "${GREEN}📄 复制文档...${NC}"
cp "$SDK_SOURCE_DIR/README.md" "$OUTPUT_DIR/" 2>/dev/null || true

# 创建动态 Framework 集成指南
cat > "$OUTPUT_DIR/DYNAMIC_FRAMEWORK_INTEGRATION.md" << 'EOF'
# WatchProtocolSDK-ObjC 动态 Framework 集成指南

## ✅ 这是纯 Objective-C 动态 Framework

本版本从 **WatchProtocolSDK-ObjC** 源码编译，是真正的 Objective-C 动态 Framework。

## 集成步骤

### 1. 添加 Framework 到项目

1. 将 `WatchProtocolSDK.xcframework` 拖入项目
2. 选择 Target → **General** → **Frameworks, Libraries, and Embedded Content**
3. 找到 `WatchProtocolSDK.xcframework`
4. **重要**：设置 Embed 为 **"Embed & Sign"**（动态库必须嵌入）

### 2. 导入并使用

```objc
// AppDelegate.m
#import <WatchProtocolSDK/WatchProtocolSDK.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // 初始化 SDK
    [[WPDeviceManager sharedInstance] initializeWithStorage:nil];
    [[WPBluetoothManager sharedInstance] initCentral];

    NSLog(@"✅ WatchProtocolSDK 初始化成功");

    return YES;
}

@end
```

### 3. 使用所有功能

```objc
// ViewController.m
#import <WatchProtocolSDK/WatchProtocolSDK.h>
#import <WatchProtocolSDK/WPHealthDataModels.h>
#import <WatchProtocolSDK/WPDeviceManager.h>
#import <WatchProtocolSDK/WPBluetoothManager.h>

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // 使用健康数据模型
    WPStepData *stepData = [[WPStepData alloc] init];
    stepData.step = 10000;

    // 使用设备管理器
    WPDeviceManager *deviceManager = [WPDeviceManager sharedInstance];

    // 使用蓝牙管理器
    WPBluetoothManager *btManager = [WPBluetoothManager sharedInstance];
    [btManager startScanning:YES];
}

@end
```

## 与静态库版本的区别

| 特性 | 动态 Framework | 静态库 XCFramework |
|------|---------------|-------------------|
| 导入语法 | `#import <WatchProtocolSDK/Header.h>` ✅ | `@import WatchProtocolSDK` 或 `#import "WatchProtocolSDK.h"` |
| Embed 设置 | **Embed & Sign** | Do Not Embed |
| 应用体积 | Framework 嵌入到 App | 链接到可执行文件（体积更小） |
| 启动时间 | 需要加载动态库 | 无额外加载（更快） |
| 集成难度 | **更简单，标准语法** | 需要注意导入方式 |

## 优势

✅ **标准语法**：使用 iOS 开发者熟悉的 `#import <Framework/Header.h>` 语法
✅ **易于集成**：和系统 Framework 使用方式完全一致
✅ **模块化支持**：自动支持 `@import WatchProtocolSDK`
✅ **纯 Objective-C**：无 Swift 运行时依赖，体积更小

## 系统要求

- iOS 13.0+
- Xcode 12.0+
- 仅依赖系统框架：CoreBluetooth、Foundation

## 常见问题

### Q: dyld: Library not loaded 错误？

**A**: 检查以下设置：
1. Target → General → Frameworks, Libraries, and Embedded Content
2. 确认 `WatchProtocolSDK.xcframework` 的 Embed 设置为 **"Embed & Sign"**
3. 如果设置为 "Do Not Embed"，运行时会找不到动态库

### Q: 链接错误：Undefined symbols for architecture arm64？

**A**: 检查以下设置：
1. 确认 `WatchProtocolSDK.xcframework` 已添加到项目
2. Target → Build Phases → Link Binary With Libraries 中应该包含 WatchProtocolSDK
3. 清理项目：Product → Clean Build Folder (⇧⌘K)
4. 删除 DerivedData：`rm -rf ~/Library/Developer/Xcode/DerivedData/*`

### Q: 如何验证 Framework 是否正确？

**A**: 运行以下命令检查符号：
```bash
nm -g path/to/WatchProtocolSDK.xcframework/ios-arm64/WatchProtocolSDK.framework/WatchProtocolSDK | grep WPBluetoothManager
```

应该能看到：
```
... T _OBJC_CLASS_$_WPBluetoothManager
... T _OBJC_METACLASS_$_WPBluetoothManager
```

### Q: Swift 项目如何使用？

**A**: 创建 Bridging Header：
```objc
// YourProject-Bridging-Header.h
#import <WatchProtocolSDK/WatchProtocolSDK.h>
```

然后在 Swift 中直接使用：
```swift
let manager = WPDeviceManager.shared()
manager.initialize(withStorage: storage)
```

## 技术支持

如有问题，请联系：315082431@qq.com

提供问题时，请附上：
1. Xcode 版本
2. 完整错误信息
3. Build Settings 中的 Framework Search Paths 配置
EOF

# 创建快速修复指南
cat > "$OUTPUT_DIR/LINKER_ERROR_FIX.md" << 'EOF'
# 链接错误快速修复指南

## 问题症状

```
Undefined symbols for architecture arm64:
  "_OBJC_CLASS_$_WPBluetoothManager", referenced from:
  "_OBJC_CLASS_$_WPDeviceManager", referenced from:
  "_OBJC_CLASS_$_WPEmptyHealthDataStorage", referenced from:
ld: symbol(s) not found for architecture arm64
```

## 🚀 快速修复（3 步）

### 步骤 1：确认 Framework 已添加

1. Xcode → 选择 Target
2. **General** 标签页
3. **Frameworks, Libraries, and Embedded Content** 部分
4. 确认 `WatchProtocolSDK.xcframework` **在列表中**

**如果不在**：点击 **"+"** → **"Add Other..."** → 选择 `WatchProtocolSDK.xcframework`

### 步骤 2：设置正确的 Embed 选项 ⭐ 最重要

找到 `WatchProtocolSDK.xcframework`，右侧的 Embed 列必须设置为：

**"Embed & Sign"**

❌ 如果是 "Do Not Embed" → 改为 "Embed & Sign"
❌ 如果是 "Embed Without Signing" → 改为 "Embed & Sign"

### 步骤 3：清理并重新编译

```bash
# 清理 DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```

然后在 Xcode 中：
- **Product** → **Clean Build Folder** (⇧⌘K)
- **Product** → **Build** (⌘B)

## 验证修复

运行项目，如果看到以下日志，说明集成成功：

```objc
#import <WatchProtocolSDK/WatchProtocolSDK.h>

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    WPDeviceManager *manager = [WPDeviceManager sharedInstance];
    NSLog(@"✅ WatchProtocolSDK 可用: %@", manager);

    return YES;
}
```

## 其他常见问题

### 问题 A：搜索路径警告

```
ld: warning: search path 'xxx' not found
```

**解决方案**：
1. Target → **Build Settings**
2. 搜索 **"Framework Search Paths"**
3. 删除所有不存在的路径（红色或无效路径）

### 问题 B：CoreAudioTypes 框架警告

```
ld: warning: Could not find or use auto-linked framework 'CoreAudioTypes'
```

**解决方案**：
1. Target → **General** → **Deployment Info**
2. 将 **"iOS Deployment Target"** 设置为 **13.0** 或更高

### 问题 C：重复库警告

```
ld: warning: ignoring duplicate libraries: '-lc++', '-lxml2'
```

**解决方案**：
1. Target → **Build Settings**
2. 搜索 **"Other Linker Flags"**
3. 删除重复的 `-lc++`、`-lxml2`、`-lz` 等

## 仍然无法解决？

请提供以下信息：
1. Xcode 版本：`xcodebuild -version`
2. macOS 版本：`sw_vers`
3. 完整的链接错误日志
4. Build Settings 中的 FRAMEWORK_SEARCH_PATHS 值

联系：315082431@qq.com
EOF

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ 动态 Framework 构建完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "📍 输出位置: ${BLUE}$OUTPUT_DIR/${SDK_NAME}.xcframework${NC}"
echo ""
echo -e "✨ 特性:"
echo -e "   ✅ 纯 Objective-C 实现（无 Swift 依赖）"
echo -e "   ✅ 支持标准导入语法: #import <WatchProtocolSDK/WatchProtocolSDK.h>"
echo -e "   ✅ 完整的模块化支持"
echo -e "   ✅ 真正的动态 Framework"
echo ""
echo -e "📄 文档:"
echo -e "   - DYNAMIC_FRAMEWORK_INTEGRATION.md - 完整集成指南"
echo -e "   - LINKER_ERROR_FIX.md - 链接错误快速修复"
echo -e "   - README.md - API 文档"
echo ""

# 显示大小
FRAMEWORK_SIZE=$(du -sh "$OUTPUT_DIR/${SDK_NAME}.xcframework" | cut -f1)
echo -e "📦 Framework 大小: ${BLUE}$FRAMEWORK_SIZE${NC}"
echo ""
echo -e "${GREEN}🎉 可以直接提供给第三方使用！${NC}"
echo ""
