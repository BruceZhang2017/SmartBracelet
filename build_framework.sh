#!/bin/bash

# WatchProtocolSDK-ObjC Framework 打包脚本
# 生成支持 iOS 设备和模拟器的 XCFramework

set -e

echo "🚀 开始打包 WatchProtocolSDK-ObjC Framework..."

# 配置
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SDK_NAME="WatchProtocolSDK"
SDK_SOURCE_DIR="$PROJECT_DIR/WatchProtocolSDK-ObjC"
BUILD_DIR="$PROJECT_DIR/build/WatchProtocolSDK-ObjC-Framework"
OUTPUT_DIR="$PROJECT_DIR/Output-ObjC"

# 版本信息
SDK_VERSION="1.0.0"

# 清理之前的构建
echo "🧹 清理旧的构建文件..."
rm -rf "$BUILD_DIR"
rm -rf "$OUTPUT_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$OUTPUT_DIR"

# 创建临时项目目录
TEMP_PROJECT_DIR="$BUILD_DIR/TempProject"
mkdir -p "$TEMP_PROJECT_DIR"

echo "📦 准备源文件..."

# 复制源文件到临时目录
cp -R "$SDK_SOURCE_DIR"/* "$TEMP_PROJECT_DIR/"

# 创建 Info.plist
cat > "$TEMP_PROJECT_DIR/Info.plist" << EOF
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
    <key>NSPrincipalClass</key>
    <string></string>
</dict>
</plist>
EOF

# 收集所有源文件
echo "🔍 收集源文件..."
SOURCE_FILES=$(find "$TEMP_PROJECT_DIR" -name "*.m" ! -path "*/Examples/*" ! -path "*/.*")
HEADER_FILES=$(find "$TEMP_PROJECT_DIR" -name "*.h" ! -path "*/Examples/*" ! -path "*/.*")

# 公开头文件列表
PUBLIC_HEADERS=""
for header in $HEADER_FILES; do
    PUBLIC_HEADERS="$PUBLIC_HEADERS -public-header $header"
done

echo "📱 编译 iOS 设备版本 (arm64)..."
xcodebuild -create-xcframework \
    -library "$BUILD_DIR/libWatchProtocolSDK-device.a" \
    -headers "$TEMP_PROJECT_DIR" \
    -library "$BUILD_DIR/libWatchProtocolSDK-simulator.a" \
    -headers "$TEMP_PROJECT_DIR" \
    -output "$OUTPUT_DIR/${SDK_NAME}.xcframework" 2>/dev/null || {

    echo "⚠️  XCFramework 创建需要先编译静态库，使用备用方案..."

    # 备用方案：使用 libtool 创建静态库
    echo "📱 编译 iOS 设备版本 (arm64)..."

    # 编译设备版本的 .o 文件
    DEVICE_OBJECTS=""
    for source in $SOURCE_FILES; do
        filename=$(basename "$source" .m)
        xcrun clang -x objective-c \
            -target arm64-apple-ios13.0 \
            -isysroot $(xcrun --sdk iphoneos --show-sdk-path) \
            -I"$TEMP_PROJECT_DIR" \
            -I"$TEMP_PROJECT_DIR/Core" \
            -I"$TEMP_PROJECT_DIR/Models" \
            -I"$TEMP_PROJECT_DIR/Protocols" \
            -I"$TEMP_PROJECT_DIR/Utils" \
            -fmodules \
            -fobjc-arc \
            -c "$source" \
            -o "$BUILD_DIR/${filename}-device.o"
        DEVICE_OBJECTS="$DEVICE_OBJECTS $BUILD_DIR/${filename}-device.o"
    done

    # 创建设备版本静态库
    xcrun libtool -static -o "$BUILD_DIR/libWatchProtocolSDK-device.a" $DEVICE_OBJECTS

    echo "📱 编译模拟器版本 (arm64, x86_64)..."

    # 编译模拟器版本的 .o 文件
    SIMULATOR_OBJECTS=""
    for source in $SOURCE_FILES; do
        filename=$(basename "$source" .m)
        xcrun clang -x objective-c \
            -target arm64-apple-ios13.0-simulator \
            -isysroot $(xcrun --sdk iphonesimulator --show-sdk-path) \
            -I"$TEMP_PROJECT_DIR" \
            -I"$TEMP_PROJECT_DIR/Core" \
            -I"$TEMP_PROJECT_DIR/Models" \
            -I"$TEMP_PROJECT_DIR/Protocols" \
            -I"$TEMP_PROJECT_DIR/Utils" \
            -fmodules \
            -fobjc-arc \
            -c "$source" \
            -o "$BUILD_DIR/${filename}-sim-arm64.o"
        SIMULATOR_OBJECTS="$SIMULATOR_OBJECTS $BUILD_DIR/${filename}-sim-arm64.o"

        xcrun clang -x objective-c \
            -target x86_64-apple-ios13.0-simulator \
            -isysroot $(xcrun --sdk iphonesimulator --show-sdk-path) \
            -I"$TEMP_PROJECT_DIR" \
            -I"$TEMP_PROJECT_DIR/Core" \
            -I"$TEMP_PROJECT_DIR/Models" \
            -I"$TEMP_PROJECT_DIR/Protocols" \
            -I"$TEMP_PROJECT_DIR/Utils" \
            -fmodules \
            -fobjc-arc \
            -c "$source" \
            -o "$BUILD_DIR/${filename}-sim-x86_64.o"
        SIMULATOR_OBJECTS="$SIMULATOR_OBJECTS $BUILD_DIR/${filename}-sim-x86_64.o"
    done

    # 创建模拟器版本静态库
    xcrun libtool -static -o "$BUILD_DIR/libWatchProtocolSDK-simulator.a" $SIMULATOR_OBJECTS

    echo "📋 准备公开头文件..."
    # 创建扁平化的Headers目录(只包含.h文件,不包含子目录)
    HEADERS_DIR="$BUILD_DIR/Headers"
    mkdir -p "$HEADERS_DIR"

    # 只复制.h文件到Headers根目录(扁平化结构)
    for header in $HEADER_FILES; do
        cp "$header" "$HEADERS_DIR/"
    done

    # 创建Modules目录并复制module.modulemap（支持模块化导入）
    MODULES_DIR="$BUILD_DIR/Modules"
    mkdir -p "$MODULES_DIR"
    if [ -f "$SDK_SOURCE_DIR/module.modulemap" ]; then
        cp "$SDK_SOURCE_DIR/module.modulemap" "$MODULES_DIR/module.modulemap"
        echo "   ✅ 复制了 module.modulemap 到 Modules 目录"
    fi

    echo "   复制了 $(ls "$HEADERS_DIR"/*.h | wc -l | tr -d ' ') 个头文件到扁平化目录"

    echo "🔨 创建 XCFramework（支持模块化）..."
    xcodebuild -create-xcframework \
        -library "$BUILD_DIR/libWatchProtocolSDK-device.a" \
        -headers "$HEADERS_DIR" \
        -library "$BUILD_DIR/libWatchProtocolSDK-simulator.a" \
        -headers "$HEADERS_DIR" \
        -output "$OUTPUT_DIR/${SDK_NAME}.xcframework"

    # 手动添加Modules目录到XCFramework（xcodebuild不会自动添加）
    echo "📦 添加模块支持..."
    for arch_dir in "$OUTPUT_DIR/${SDK_NAME}.xcframework"/*/ ; do
        if [ -d "$arch_dir" ]; then
            cp -R "$MODULES_DIR" "$arch_dir/Modules"
            echo "   ✅ 添加了 Modules 目录到 $(basename "$arch_dir")"
        fi
    done
}

# 复制文档
echo "📄 复制文档..."
cp "$SDK_SOURCE_DIR/README.md" "$OUTPUT_DIR/"
cp "$PROJECT_DIR/WatchProtocolSDK-ObjC.podspec" "$OUTPUT_DIR/"

# 创建集成说明
cat > "$OUTPUT_DIR/INTEGRATION_GUIDE.md" << 'EOF'
# WatchProtocolSDK-ObjC Framework 集成指南

## 方式一：直接集成 XCFramework

### 1. 添加到项目

1. 将 `WatchProtocolSDK.xcframework` 拖入项目
2. 在 Target -> General -> Frameworks, Libraries, and Embedded Content 中：
   - 确认 `WatchProtocolSDK.xcframework` 已添加
   - 设置 Embed 为 **Embed & Sign**

### 2. 添加系统框架依赖

在 Target -> Build Phases -> Link Binary With Libraries 中添加：
- `CoreBluetooth.framework`
- `Foundation.framework`

### 3. 配置权限

在 `Info.plist` 中添加：

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>需要使用蓝牙连接智能手表设备</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>需要使用蓝牙与智能手表进行数据交互</string>
```

### 4. 导入使用

```objc
#import <WatchProtocolSDK/WatchProtocolSDK.h>

// 初始化
[[WPDeviceManager sharedInstance] initializeWithStorage:storage];
[[WPBluetoothManager sharedInstance] initCentral];
```

---

## 方式二：使用 CocoaPods

### 1. 添加到 Podfile

```ruby
pod 'WatchProtocolSDK-ObjC', :path => './WatchProtocolSDK-ObjC.podspec'
```

### 2. 安装

```bash
pod install
```

### 3. 导入使用

```objc
#import <WatchProtocolSDK/WatchProtocolSDK.h>
```

---

## 验证安装

```objc
// AppDelegate.m
#import <WatchProtocolSDK/WatchProtocolSDK.h>

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // 测试：获取单例
    WPDeviceManager *manager = [WPDeviceManager sharedInstance];
    NSLog(@"✅ WatchProtocolSDK 加载成功");

    return YES;
}
```

---

## 常见问题

### Q: 编译时提示找不到头文件？

**A**: 确保在 Build Settings -> Framework Search Paths 中添加了 framework 的路径。

### Q: 运行时提示 dyld: Library not loaded？

**A**: 确保 Embed 设置为 "Embed & Sign"，而不是 "Do Not Embed"。

### Q: 如何在 Objective-C++ 文件中使用？

**A**: 直接导入即可，framework 完全兼容 Objective-C++：

```objc
#import <WatchProtocolSDK/WatchProtocolSDK.h>
```

---

## 更多文档

请查看：
- `README.md` - 完整的 API 文档
- `WatchProtocolSDK-ObjC.podspec` - CocoaPods 配置
EOF

echo ""
echo "✅ 打包完成！"
echo ""
echo "📦 输出文件："
echo "   - XCFramework: $OUTPUT_DIR/${SDK_NAME}.xcframework"
echo "   - 文档: $OUTPUT_DIR/README.md"
echo "   - 集成指南: $OUTPUT_DIR/INTEGRATION_GUIDE.md"
echo ""
echo "🎉 Framework 已准备就绪，可以直接集成到项目中！"
