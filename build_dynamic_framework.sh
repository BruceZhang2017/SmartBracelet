#!/bin/bash

# 构建动态 Framework XCFramework（支持标准导入语法）

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  WatchProtocolSDK 动态 Framework 构建${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 配置
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SDK_NAME="WatchProtocolSDK"
PROJECT_NAME="SmartBracelet.xcodeproj"
SCHEME_NAME="WatchProtocolSDK"
BUILD_DIR="$PROJECT_DIR/build/DynamicFramework"
OUTPUT_DIR="$PROJECT_DIR/Output-ObjC-Dynamic"

# 清理
echo -e "${GREEN}🧹 清理构建目录...${NC}"
rm -rf "$BUILD_DIR"
rm -rf "$OUTPUT_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$OUTPUT_DIR"

# 构建 iOS 设备版本
echo ""
echo -e "${GREEN}📱 构建 iOS 设备版本 (arm64)...${NC}"
xcodebuild archive \
  -project "$PROJECT_NAME" \
  -scheme "$SCHEME_NAME" \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "$BUILD_DIR/ios.xcarchive" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  ONLY_ACTIVE_ARCH=NO

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ iOS 设备版本构建失败${NC}"
    exit 1
fi
echo -e "${GREEN}✅ iOS 设备版本构建成功${NC}"

# 构建模拟器版本
echo ""
echo -e "${GREEN}🖥 构建模拟器版本 (arm64 + x86_64)...${NC}"
xcodebuild archive \
  -project "$PROJECT_NAME" \
  -scheme "$SCHEME_NAME" \
  -configuration Release \
  -destination "generic/platform=iOS Simulator" \
  -archivePath "$BUILD_DIR/ios-simulator.xcarchive" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  ONLY_ACTIVE_ARCH=NO

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ 模拟器版本构建失败${NC}"
    exit 1
fi
echo -e "${GREEN}✅ 模拟器版本构建成功${NC}"

# 查找 Framework 路径
echo ""
echo -e "${GREEN}📦 创建 XCFramework...${NC}"

DEVICE_FRAMEWORK=$(find "$BUILD_DIR/ios.xcarchive" -name "${SDK_NAME}.framework" | head -1)
SIMULATOR_FRAMEWORK=$(find "$BUILD_DIR/ios-simulator.xcarchive" -name "${SDK_NAME}.framework" | head -1)

if [ -z "$DEVICE_FRAMEWORK" ] || [ -z "$SIMULATOR_FRAMEWORK" ]; then
    echo -e "${RED}❌ 找不到构建的 Framework${NC}"
    echo "Device: $DEVICE_FRAMEWORK"
    echo "Simulator: $SIMULATOR_FRAMEWORK"
    exit 1
fi

echo "   Device Framework: $DEVICE_FRAMEWORK"
echo "   Simulator Framework: $SIMULATOR_FRAMEWORK"

# 创建 XCFramework
xcodebuild -create-xcframework \
  -framework "$DEVICE_FRAMEWORK" \
  -framework "$SIMULATOR_FRAMEWORK" \
  -output "$OUTPUT_DIR/${SDK_NAME}.xcframework"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ XCFramework 创建失败${NC}"
    exit 1
fi
echo -e "${GREEN}✅ XCFramework 创建成功${NC}"

# 复制文档
echo ""
echo -e "${GREEN}📄 复制文档...${NC}"
cp WatchProtocolSDK-ObjC/README.md "$OUTPUT_DIR/" 2>/dev/null || true

# 创建集成指南
cat > "$OUTPUT_DIR/INTEGRATION_GUIDE.md" << 'EOF'
# WatchProtocolSDK 动态 Framework 集成指南

## ✅ 动态 Framework 版本

本版本是**动态 Framework (.framework)**，支持标准的导入语法。

## 集成步骤

### 1. 添加 Framework

1. 将 `WatchProtocolSDK.xcframework` 拖入项目
2. Target → General → Frameworks, Libraries, and Embedded Content
3. **重要**：设置为 **"Embed & Sign"**（动态库需要嵌入）

### 2. 导入并使用

```objc
// AppDelegate.m

#import <WatchProtocolSDK/WatchProtocolSDK.h>  // ✅ 标准导入语法

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // 初始化 SDK
    WPDeviceManager *manager = [WPDeviceManager sharedInstance];
    [[WPBluetoothManager sharedInstance] initCentral];

    NSLog(@"✅ WatchProtocolSDK 初始化成功");

    return YES;
}

@end
```

### 3. 使用所有功能

```objc
// 导入主头文件
#import <WatchProtocolSDK/WatchProtocolSDK.h>

// 或者单独导入需要的头文件
#import <WatchProtocolSDK/WPHealthDataModels.h>
#import <WatchProtocolSDK/WPDeviceManager.h>
#import <WatchProtocolSDK/WPBluetoothManager.h>
```

## 优势

✅ **标准语法**：使用 `#import <Framework/Header.h>`
✅ **模块化**：自动支持 `@import WatchProtocolSDK`
✅ **符合规范**：遵循 iOS Framework 开发最佳实践
✅ **易于使用**：和其他系统 Framework 使用方式一致

## 与静态库版本的区别

| 特性 | 动态 Framework | 静态库 |
|------|---------------|--------|
| 导入语法 | `#import <Framework/...>` | `@import` 或 `#import "..."` |
| Embed 设置 | Embed & Sign | Do Not Embed |
| 应用体积 | Framework 嵌入到 App | 链接到可执行文件 |
| 启动时间 | 需要加载动态库 | 无额外加载 |

## 常见问题

### Q: dyld: Library not loaded？

**A**: 确保 Embed 设置为 "Embed & Sign"。

### Q: 和静态库版本哪个更好？

**A**:
- **动态 Framework**：开发体验更好，符合标准，易于集成
- **静态库**：应用体积更小，启动更快

推荐使用动态 Framework。

### Q: Swift 项目如何使用？

**A**: 创建 Bridging Header 或直接导入：

```swift
import WatchProtocolSDK

let manager = WPDeviceManager.shared()
```

## 系统要求

- iOS 13.0+
- Xcode 14.0+
- Swift 5.0+ (如果使用 Swift)

EOF

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ 动态 Framework 构建完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "📍 输出位置: ${BLUE}$OUTPUT_DIR/${SDK_NAME}.xcframework${NC}"
echo ""
echo -e "✨ 特性:"
echo -e "   ✅ 支持标准导入语法: #import <WatchProtocolSDK/WatchProtocolSDK.h>"
echo -e "   ✅ 完整的模块化支持"
echo -e "   ✅ 真正的动态 Framework"
echo ""

# 显示大小
du -sh "$OUTPUT_DIR/${SDK_NAME}.xcframework"

echo ""
echo -e "${GREEN}🎉 可以直接提供给第三方使用！${NC}"
echo ""
