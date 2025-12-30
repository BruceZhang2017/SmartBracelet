# WatchFaceSDK 编译配置指南

## 🔴 当前问题

编译失败，错误信息：
```
error: no such module 'WatchProtocolSDK'
```

## 🔧 解决方案

需要在 Xcode 项目中为 **WatchFaceSDK** target 添加依赖的 frameworks。

### 步骤 1: 打开项目

```bash
open SmartBracelet.xcworkspace
```

### 步骤 2: 选择 WatchFaceSDK Target

1. 在 Xcode 左侧项目导航器中选择 `SmartBracelet` 项目
2. 在 TARGETS 列表中选择 `WatchFaceSDK`

### 步骤 3: 添加依赖 Frameworks

在 **General** 标签页中：

1. 滚动到 **Frameworks, Libraries, and Embedded Content** 部分
2. 点击 **+** 按钮
3. 添加以下 frameworks：
   - `WatchProtocolSDK.framework` （选择项目中已有的）
   - `ABParTool.xcframework` （从文件浏览器添加：`../ABParTool.xcframework`）

4. 确保两个 frameworks 都设置为 **Embed & Sign**

### 步骤 4: 配置 Build Settings

在 **Build Settings** 标签页中：

1. 搜索 `Framework Search Paths`
2. 添加以下路径：
   ```
   $(PROJECT_DIR)/../build/WatchProtocolSDK-Release
   $(PROJECT_DIR)/..
   ```

3. 搜索 `Build Libraries for Distribution`
4. 设置为 **YES**

### 步骤 5: 添加 Target 依赖

在 **Build Phases** 标签页中：

1. 展开 **Dependencies** 部分
2. 点击 **+** 按钮
3. 添加 `WatchProtocolSDK` target

### 步骤 6: 重新编译

配置完成后，运行编译脚本：

```bash
./build_watchface_sdk.sh
```

## 📝 快速配置（命令行方式）

或者，你可以尝试以下自动配置命令：

```bash
# 方法 1: 使用现有的 WatchProtocolSDK target（推荐）
# 需要在 Xcode 中手动添加依赖关系

# 方法 2: 临时解决方案 - 直接指定 framework 路径
xcodebuild clean build \
  -project SmartBracelet.xcodeproj \
  -scheme WatchFaceSDK \
  -sdk iphoneos \
  -configuration Release \
  FRAMEWORK_SEARCH_PATHS='$(inherited) $(PROJECT_DIR)/../build/WatchProtocolSDK-Release $(PROJECT_DIR)/..'
```

## ⚠️ 注意事项

1. **WatchProtocolSDK** 必须先编译成功，xcframework 位于：
   ```
   build/WatchProtocolSDK-Release/WatchProtocolSDK.xcframework
   ```

2. **ABParTool.xcframework** 应该在项目根目录：
   ```
   ../ABParTool.xcframework
   ```

3. 如果依赖的 frameworks 不存在，请先编译 WatchProtocolSDK：
   ```bash
   ./build_sdk.sh
   ```

## ✅ 验证配置

配置完成后，检查以下内容：

1. WatchFaceSDK target 的 **Frameworks** 列表中应该包含：
   - WatchProtocolSDK.framework
   - ABParTool.xcframework
   - UIKit.framework
   - Foundation.framework

2. **Build Phases** > **Link Binary With Libraries** 中应该包含上述 frameworks

3. **Framework Search Paths** 应该包含正确的路径

## 🚀 编译成功后

编译成功后，输出文件位于：
```
build/WatchFaceSDK-Release/WatchFaceSDK.xcframework
```

可以将整个 `build/WatchFaceSDK-Release` 目录提供给第三方使用，其中包含：
- WatchFaceSDK.xcframework（主 SDK）
- README.md（使用文档）
- USAGE_EXAMPLES.md（示例代码）
- INTEGRATION_GUIDE.md（集成指南）
- VERSION.txt（版本信息）

---

**需要帮助？** 检查 Xcode 的编译错误日志，确保所有依赖都正确配置。
