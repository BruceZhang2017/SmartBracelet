#!/bin/bash

# WatchProtocolSDK v2.0.7 打包脚本
# 将 SDK 打包成可分发的 ZIP 文件

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  WatchProtocolSDK v2.0.7 打包工具  ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

VERSION="2.0.7"
OUTPUT_DIR="Output-ObjC-Dynamic"
PACKAGE_NAME="WatchProtocolSDK-v${VERSION}"
ZIP_FILE="${PACKAGE_NAME}.zip"

# 检查输出目录
if [ ! -d "$OUTPUT_DIR" ]; then
    echo -e "${RED}❌ 找不到 Output-ObjC-Dynamic 目录${NC}"
    exit 1
fi

echo -e "${GREEN}📦 准备打包内容...${NC}"

# 创建临时打包目录
TEMP_DIR="build/${PACKAGE_NAME}"
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

# 复制 Framework
echo "   复制 Framework..."
cp -R "$OUTPUT_DIR/WatchProtocolSDK.xcframework" "$TEMP_DIR/"

# 复制文档
echo "   复制文档..."
cp "$OUTPUT_DIR/README.md" "$TEMP_DIR/"
cp "$OUTPUT_DIR/FIND_DEVICE_GUIDE.md" "$TEMP_DIR/" 2>/dev/null || true
cp "$OUTPUT_DIR/FINDDEVICE_ENHANCEMENT_SUMMARY.md" "$TEMP_DIR/" 2>/dev/null || true
cp "$OUTPUT_DIR/RELEASE_NOTES_v2.0.7.md" "$TEMP_DIR/" 2>/dev/null || true
cp "$OUTPUT_DIR/DYNAMIC_FRAMEWORK_INTEGRATION.md" "$TEMP_DIR/"
cp "$OUTPUT_DIR/LINKER_ERROR_FIX.md" "$TEMP_DIR/"

# 复制示例代码
echo "   复制示例代码..."
if [ -d "WatchProtocolSDK-ObjC/Examples" ]; then
    mkdir -p "$TEMP_DIR/Examples"
    cp WatchProtocolSDK-ObjC/Examples/*.h "$TEMP_DIR/Examples/" 2>/dev/null || true
    cp WatchProtocolSDK-ObjC/Examples/*.m "$TEMP_DIR/Examples/" 2>/dev/null || true
fi

# 创建 README
cat > "$TEMP_DIR/快速开始.md" << 'EOF'
# WatchProtocolSDK v2.0.7 快速开始

## 📦 包含内容

- `WatchProtocolSDK.xcframework` - 主 Framework
- `README.md` - 完整 API 文档
- `FIND_DEVICE_GUIDE.md` - 查找设备功能使用指南
- `RELEASE_NOTES_v2.0.7.md` - 版本发布说明
- `DYNAMIC_FRAMEWORK_INTEGRATION.md` - 集成指南
- `LINKER_ERROR_FIX.md` - 常见问题修复
- `Examples/` - 示例代码

## 🚀 快速集成（3 步）

### 步骤 1：添加 Framework

1. 将 `WatchProtocolSDK.xcframework` 拖入项目
2. 选择 Target → General → Frameworks, Libraries, and Embedded Content
3. 找到 `WatchProtocolSDK.xcframework`
4. **重要**：设置 Embed 为 **"Embed & Sign"**

### 步骤 2：导入并初始化

```objc
// AppDelegate.m
#import <WatchProtocolSDK/WatchProtocolSDK.h>

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // 初始化 SDK
    [[WPDeviceManager sharedInstance] initializeWithStorage:nil];
    [[WPBluetoothManager sharedInstance] initCentral];

    return YES;
}
```

### 步骤 3：使用新功能

```objc
// ViewController.m
#import <WatchProtocolSDK/WatchProtocolSDK.h>

// 查找手环（新功能）
[WPCommands findBandWithCompletion:^(BOOL success, NSError *error) {
    if (success) {
        NSLog(@"✅ 手环正在震动");
    } else {
        NSLog(@"❌ 查找失败: %@", error.localizedDescription);
    }
}];
```

## 📚 详细文档

- **完整 API**: 查看 `README.md`
- **查找设备功能**: 查看 `FIND_DEVICE_GUIDE.md`
- **集成指南**: 查看 `DYNAMIC_FRAMEWORK_INTEGRATION.md`
- **示例代码**: 查看 `Examples/` 目录

## ❓ 遇到问题？

参考 `LINKER_ERROR_FIX.md` 快速修复常见链接错误。

## 📞 技术支持

Email: 315082431@qq.com
EOF

# 打包
echo ""
echo -e "${GREEN}🗜  压缩文件...${NC}"
cd build
rm -f "../${ZIP_FILE}"
zip -r "../${ZIP_FILE}" "${PACKAGE_NAME}" -q

if [ $? -eq 0 ]; then
    cd ..
    echo -e "${GREEN}✅ 打包成功！${NC}"
    echo ""
    echo -e "📦 文件位置: ${BLUE}${ZIP_FILE}${NC}"
    echo -e "📏 文件大小: ${BLUE}$(du -sh "${ZIP_FILE}" | cut -f1)${NC}"
    echo ""
    echo -e "${GREEN}可以将此 ZIP 文件发送给第三方使用。${NC}"
    echo ""

    # 显示内容清单
    echo -e "${BLUE}包含内容:${NC}"
    unzip -l "${ZIP_FILE}" | head -20

else
    echo -e "${RED}❌ 打包失败${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}🎉 打包完成！${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
