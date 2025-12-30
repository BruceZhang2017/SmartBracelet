#!/bin/bash

# WatchFaceSDK 编译脚本
# 用于编译并打包 WatchFaceSDK，生成可分发的 XCFramework

set -e  # 遇到错误立即退出

echo "========================================="
echo "WatchFaceSDK 编译脚本"
echo "========================================="
echo ""

# 配置
SDK_NAME="WatchFaceSDK"
VERSION="1.0.0"
PROJECT_NAME="SmartBracelet.xcodeproj"
SCHEME_NAME="WatchFaceSDK"

# 输出目录
BUILD_DIR="build"
SDK_OUTPUT_DIR="$BUILD_DIR/SDK"
RELEASE_DIR="$BUILD_DIR/${SDK_NAME}-Release"
ZIP_NAME="${SDK_NAME}-v${VERSION}.zip"

# 清理旧的构建产物（保留 WatchProtocolSDK-Release）
echo "🧹 清理旧的构建产物..."
rm -rf "$SDK_OUTPUT_DIR"
rm -rf "$RELEASE_DIR"
rm -f "$BUILD_DIR/$ZIP_NAME"
rm -f "$BUILD_DIR/${ZIP_NAME}.sha256"
mkdir -p "$SDK_OUTPUT_DIR"

# 编译 iOS 真机版本
echo ""
echo "📱 编译 iOS 真机版本 (arm64)..."
xcodebuild clean build \
  -project "$PROJECT_NAME" \
  -scheme "$SCHEME_NAME" \
  -sdk iphoneos \
  -configuration Release \
  -derivedDataPath "$SDK_OUTPUT_DIR/iOS" \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  ONLY_ACTIVE_ARCH=NO \
  | grep -E "error:|warning:|BUILD" || true

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "❌ iOS 真机版本编译失败"
    exit 1
fi
echo "✅ iOS 真机版本编译成功"

# 编译模拟器版本
echo ""
echo "🖥 编译模拟器版本 (arm64 + x86_64)..."
xcodebuild clean build \
  -project "$PROJECT_NAME" \
  -scheme "$SCHEME_NAME" \
  -sdk iphonesimulator \
  -configuration Release \
  -derivedDataPath "$SDK_OUTPUT_DIR/Simulator" \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  ONLY_ACTIVE_ARCH=NO \
  | grep -E "error:|warning:|BUILD" || true

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "❌ 模拟器版本编译失败"
    exit 1
fi
echo "✅ 模拟器版本编译成功"

# 创建 XCFramework
echo ""
echo "📦 创建 XCFramework..."
xcodebuild -create-xcframework \
  -framework "$SDK_OUTPUT_DIR/iOS/Build/Products/Release-iphoneos/${SDK_NAME}.framework" \
  -framework "$SDK_OUTPUT_DIR/Simulator/Build/Products/Release-iphonesimulator/${SDK_NAME}.framework" \
  -output "$SDK_OUTPUT_DIR/${SDK_NAME}.xcframework"

if [ $? -ne 0 ]; then
    echo "❌ XCFramework 创建失败"
    exit 1
fi
echo "✅ XCFramework 创建成功"

# 准备发布目录
echo ""
echo "📂 准备发布目录..."
mkdir -p "$RELEASE_DIR"
cp -R "$SDK_OUTPUT_DIR/${SDK_NAME}.xcframework" "$RELEASE_DIR/"

# 复制依赖框架
echo "📦 复制依赖框架..."
if [ -d "build/WatchProtocolSDK-Release/WatchProtocolSDK.xcframework" ]; then
    cp -R "build/WatchProtocolSDK-Release/WatchProtocolSDK.xcframework" "$RELEASE_DIR/"
    echo "   ✅ WatchProtocolSDK.xcframework 已复制"
fi
if [ -d "ABParTool.xcframework" ]; then
    cp -R "ABParTool.xcframework" "$RELEASE_DIR/"
    echo "   ✅ ABParTool.xcframework 已复制"
fi

# 复制文档
echo "📝 复制文档..."
if [ -f "WatchFaceSDK/README.md" ]; then
    cp "WatchFaceSDK/README.md" "$RELEASE_DIR/"
fi
if [ -f "WatchFaceSDK/USAGE_EXAMPLES.md" ]; then
    cp "WatchFaceSDK/USAGE_EXAMPLES.md" "$RELEASE_DIR/"
fi
if [ -f "WatchFaceSDK_ARCHITECTURE.md" ]; then
    cp "WatchFaceSDK_ARCHITECTURE.md" "$RELEASE_DIR/"
fi
if [ -f "WatchFaceSDK/INTEGRATION_GUIDE_CN.md" ]; then
    cp "WatchFaceSDK/INTEGRATION_GUIDE_CN.md" "$RELEASE_DIR/"
fi
if [ -f "WatchFaceSDK/INTEGRATION_GUIDE_EN.md" ]; then
    cp "WatchFaceSDK/INTEGRATION_GUIDE_EN.md" "$RELEASE_DIR/"
fi
if [ -f "WatchFaceSDK/DOCUMENTATION_INDEX.md" ]; then
    cp "WatchFaceSDK/DOCUMENTATION_INDEX.md" "$RELEASE_DIR/"
fi
if [ -f "WatchFaceSDK/START_HERE.md" ]; then
    cp "WatchFaceSDK/START_HERE.md" "$RELEASE_DIR/"
fi

# 生成版本信息
echo "📄 生成版本信息..."
cat > "$RELEASE_DIR/VERSION.txt" << EOF
${SDK_NAME} v${VERSION}

Build Date: $(date +"%Y-%m-%d %H:%M:%S")
Build Configuration: Release
Supported Platforms:
  - iOS Device (arm64)
  - iOS Simulator (arm64, x86_64)

Minimum iOS Version: 12.0
Framework Format: XCFramework
Protocol: XGZT

Dependencies:
  - WatchProtocolSDK v1.0.0
  - ABParTool.xcframework

Features:
  - 市场表盘上传
  - 自定义表盘上传
  - 智能图片处理（PAR 转换）
  - 圆形/方形屏幕适配
  - 实时传输进度回调

Author: ANKER Development Team
Copyright © 2025 Anker Innovations. All rights reserved.
EOF

# 生成集成指南
echo "📋 生成集成指南..."
cat > "$RELEASE_DIR/INTEGRATION_GUIDE.md" << EOF
# WatchFaceSDK 集成指南

## 📦 安装

### 1. 添加 SDK 到项目

将以下 XCFramework 拖入你的 Xcode 项目:
- \`${SDK_NAME}.xcframework\`
- \`WatchProtocolSDK.xcframework\` (依赖)
- \`ABParTool.xcframework\` (依赖)

在 **General** > **Frameworks, Libraries, and Embedded Content** 中设置为 **Embed & Sign**。

### 2. 导入模块

\`\`\`swift
import ${SDK_NAME}
\`\`\`

## 🚀 快速开始

### 上传自定义表盘

\`\`\`swift
import ${SDK_NAME}

class MyViewController: UIViewController, TransferDelegate {
    func uploadCustomWatchFace() {
        guard let image = UIImage(named: "my_watchface") else { return }

        do {
            try WatchFaceManager.shared.uploadCustomWatchFace(
                image: image,
                timePosition: .center,
                color: .white,
                delegate: self
            )
        } catch {
            print("❌ 上传失败: \\(error)")
        }
    }

    // MARK: - TransferDelegate

    func transferDidStart() {
        print("🚀 开始传输")
    }

    func transferDidUpdateProgress(_ progress: TransferProgress) {
        print("📊 进度: \\(progress.percentage * 100)%")
    }

    func transferDidComplete() {
        print("✅ 传输成功")
    }

    func transferDidFail(error: Error) {
        print("❌ 传输失败: \\(error)")
    }
}
\`\`\`

### 上传市场表盘

\`\`\`swift
let fileURL = // ... 表盘文件路径
do {
    try WatchFaceManager.shared.uploadMarketWatchFace(
        fileURL: fileURL,
        delegate: self
    )
} catch {
    print("❌ 上传失败: \\(error)")
}
\`\`\`

## 📚 更多文档

- \`README.md\` - 完整使用手册
- \`USAGE_EXAMPLES.md\` - 详细示例代码
- \`WatchFaceSDK_ARCHITECTURE.md\` - 架构设计文档

## ⚠️ 注意事项

1. **设备连接**: 使用前确保设备已通过 WatchProtocolSDK 连接
2. **图片尺寸**: 建议图片尺寸大于等于设备屏幕尺寸
3. **文件大小**: 自定义表盘会自动压缩到 120KB 以内
4. **线程安全**: 回调方法可能在后台线程调用，UI 更新需要切换到主线程

## 🆘 支持

如有问题，请联系技术支持团队。
EOF

# 打包
echo ""
echo "🗜 打包成 ZIP 文件..."
cd "$BUILD_DIR"
zip -r "$ZIP_NAME" "${SDK_NAME}-Release/" > /dev/null
cd ..

# 生成校验和
echo "🔐 生成 SHA256 校验和..."
shasum -a 256 "$BUILD_DIR/$ZIP_NAME" > "$BUILD_DIR/${ZIP_NAME}.sha256"

# 显示结果
echo ""
echo "========================================="
echo "✅ 编译完成！"
echo "========================================="
echo ""
echo "📦 输出文件:"
echo "   - $BUILD_DIR/$ZIP_NAME"
echo "   - $BUILD_DIR/${ZIP_NAME}.sha256"
echo ""
echo "📁 解压目录: $RELEASE_DIR"
echo "   包含内容:"
echo "   📦 核心框架:"
echo "   ├── ${SDK_NAME}.xcframework"
echo "   ├── WatchProtocolSDK.xcframework (依赖)"
echo "   └── ABParTool.xcframework (依赖)"
echo ""
echo "   📚 文档:"
echo "   ├── 👋 START_HERE.md (⭐️ 从这里开始)"
echo "   ├── DOCUMENTATION_INDEX.md (文档索引)"
echo "   ├── INTEGRATION_GUIDE_CN.md (🇨🇳 中文接入指南)"
echo "   ├── INTEGRATION_GUIDE_EN.md (🇬🇧 英文接入指南)"
echo "   ├── INTEGRATION_GUIDE.md (快速集成指南)"
echo "   ├── README.md (使用手册)"
echo "   ├── USAGE_EXAMPLES.md (示例代码)"
echo "   ├── WatchFaceSDK_ARCHITECTURE.md (架构文档)"
echo "   └── VERSION.txt (版本信息)"
echo ""
echo "📊 文件大小: $(du -h "$BUILD_DIR/$ZIP_NAME" | cut -f1)"
echo "🔐 SHA256: $(cat "$BUILD_DIR/${ZIP_NAME}.sha256" | cut -d' ' -f1)"
echo ""
echo "🎉 可以将 $BUILD_DIR/$ZIP_NAME 提供给第三方使用！"
echo ""
echo "========================================="
