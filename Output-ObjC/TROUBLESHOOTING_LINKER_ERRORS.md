# WatchProtocolSDK 链接错误故障排除指南

## 🔴 错误症状

```
Undefined symbols for architecture arm64:
  "_OBJC_CLASS_$_WPBluetoothManager", referenced from:
  "_OBJC_CLASS_$_WPDeviceManager", referenced from:
  "_OBJC_CLASS_$_WPEmptyHealthDataStorage", referenced from:
ld: symbol(s) not found for architecture arm64
```

## 🎯 问题诊断

此错误表明：**链接器找不到 WatchProtocolSDK 的符号**，即 XCFramework 没有正确链接到项目中。

---

## ✅ 解决方案（按优先级排列）

### 方案 1：检查 XCFramework 是否正确添加 ⭐ 最常见

#### 步骤 1：确认 XCFramework 已添加到项目

1. 在 Xcode 中打开你的项目
2. 选择项目 Target
3. 切换到 **"General"** 标签页
4. 找到 **"Frameworks, Libraries, and Embedded Content"** 部分
5. 确认 `WatchProtocolSDK.xcframework` 在列表中

**如果不在列表中**：
- 点击 **"+"** 按钮
- 选择 **"Add Other..."** → **"Add Files..."**
- 选择 `WatchProtocolSDK.xcframework` 文件夹
- 点击 **"Open"**

#### 步骤 2：设置正确的 Embed 选项

⚠️ **关键**：WatchProtocolSDK 是**静态库 XCFramework**，必须设置为 **"Do Not Embed"**

1. 在 "Frameworks, Libraries, and Embedded Content" 列表中找到 `WatchProtocolSDK.xcframework`
2. 右侧的 Embed 列应该显示 **"Do Not Embed"**
3. 如果显示其他选项（如 "Embed & Sign"），点击下拉菜单改为 **"Do Not Embed"**

#### 步骤 3：验证 Framework Search Paths

1. 选择 Target → **"Build Settings"**
2. 搜索 **"Framework Search Paths"**
3. 确认包含 XCFramework 所在的路径，例如：
   - `$(PROJECT_DIR)/Frameworks`
   - `$(PROJECT_DIR)/ThirdLibrary`
   - 或者你放置 XCFramework 的实际路径

**如果路径不正确**：
- 双击 "Framework Search Paths" 行
- 点击 **"+"** 添加正确的路径
- 可以使用相对路径或绝对路径

#### 步骤 4：清理并重新编译

```bash
# 清理 DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```

然后在 Xcode 中：
- **Product** → **Clean Build Folder** (⇧⌘K)
- **Product** → **Build** (⌘B)

---

### 方案 2：修复搜索路径配置错误

错误信息中显示：
```
ld: warning: search path '/Users/jh/Desktop/xingwangjiankang-ios/SmartWatch/ThirdLibrary/NewSDK/ios-arm64' not found
ld: warning: search path '/Users/jh/Desktop/xingwangjiankang-ios/SmartWatch/ThirdLibrary/BaiDuFaceSDK' not found
```

这表明项目中有**无效的搜索路径**。

#### 清理无效的搜索路径

1. Target → **"Build Settings"**
2. 搜索 **"Framework Search Paths"**
3. 删除所有不存在的路径（显示红色或无法找到的路径）
4. 搜索 **"Library Search Paths"**
5. 同样删除所有不存在的路径
6. 搜索 **"Header Search Paths"**
7. 删除无效路径

---

### 方案 3：解决 CoreAudioTypes 框架问题

错误信息：
```
ld: warning: Could not find or use auto-linked framework 'CoreAudioTypes': framework 'CoreAudioTypes' not found
```

**原因**：`CoreAudioTypes` 是 iOS 17+ 的新框架，在旧版本 iOS 中不存在。

#### 解决方法 A：升级部署目标（推荐）

1. Target → **"General"** → **"Deployment Info"**
2. 将 **"iOS Deployment Target"** 设置为 **13.0** 或更高（推荐 13.0）
3. WatchProtocolSDK 最低支持 iOS 13.0

#### 解决方法 B：弱链接（如果必须支持旧版本）

1. Target → **"Build Phases"** → **"Link Binary With Libraries"**
2. 找到 `CoreAudioTypes.framework`（如果存在）
3. 将其 **"Status"** 从 "Required" 改为 **"Optional"**

---

### 方案 4：检查架构配置

#### 验证架构设置

1. Target → **"Build Settings"**
2. 搜索 **"Architectures"**
3. 确认包含 **arm64**（真机）
4. 搜索 **"Valid Architectures"**
5. 确认包含 **arm64**
6. 搜索 **"Excluded Architectures"**
7. 确保 **arm64 没有被排除**

---

### 方案 5：修复重复链接警告

错误信息：
```
ld: warning: ignoring duplicate libraries: '-lc++', '-lxml2', '-lz'
```

虽然这个警告不会导致链接失败，但建议清理：

1. Target → **"Build Settings"**
2. 搜索 **"Other Linker Flags"**
3. 检查是否有重复的 `-lc++`、`-lxml2`、`-lz`
4. 删除重复项，每个库只保留一个

---

## 🧪 验证 SDK 是否正确集成

### 测试代码

在 `AppDelegate.m` 中添加测试代码：

```objc
#import "AppDelegate.h"
@import WatchProtocolSDK;  // 或 #import "WatchProtocolSDK.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // 测试 SDK 类是否可用
    WPDeviceManager *deviceManager = [WPDeviceManager sharedInstance];
    WPBluetoothManager *btManager = [WPBluetoothManager sharedInstance];
    WPEmptyHealthDataStorage *storage = [[WPEmptyHealthDataStorage alloc] init];

    NSLog(@"✅ WatchProtocolSDK 集成成功！");
    NSLog(@"   - WPDeviceManager: %@", deviceManager);
    NSLog(@"   - WPBluetoothManager: %@", btManager);
    NSLog(@"   - WPEmptyHealthDataStorage: %@", storage);

    return YES;
}

@end
```

### 预期结果

编译成功，控制台输出：
```
✅ WatchProtocolSDK 集成成功！
   - WPDeviceManager: <WPDeviceManager: 0x...>
   - WPBluetoothManager: <WPBluetoothManager: 0x...>
   - WPEmptyHealthDataStorage: <WPEmptyHealthDataStorage: 0x...>
```

---

## 📋 完整检查清单

使用以下清单逐项检查：

- [ ] XCFramework 已添加到 "Frameworks, Libraries, and Embedded Content"
- [ ] Embed 设置为 **"Do Not Embed"**（静态库）
- [ ] Framework Search Paths 包含 XCFramework 所在目录
- [ ] 没有无效的搜索路径（红色或不存在的路径）
- [ ] iOS Deployment Target 设置为 13.0 或更高
- [ ] 架构包含 arm64，且未被排除
- [ ] 导入语句使用 `@import WatchProtocolSDK` 或 `#import "WatchProtocolSDK.h"`
- [ ] 已清理 DerivedData 并重新编译

---

## 🔍 高级诊断

### 检查 XCFramework 内容

在终端中执行：

```bash
# 检查 XCFramework 结构
ls -la path/to/WatchProtocolSDK.xcframework/

# 检查静态库是否包含符号
nm -g path/to/WatchProtocolSDK.xcframework/ios-arm64/libWatchProtocolSDK-device.a | grep WPBluetoothManager

# 检查架构
lipo -info path/to/WatchProtocolSDK.xcframework/ios-arm64/libWatchProtocolSDK-device.a
```

**预期结果**：
- 应该能看到 `_OBJC_CLASS_$_WPBluetoothManager` 等符号
- 架构应该显示 `arm64`

### 检查链接器命令

1. Xcode → **"Report Navigator"**（最右侧的图标）
2. 选择最近的编译记录
3. 找到 "Link" 阶段
4. 查看完整的链接命令

**检查**：
- 是否包含 `-framework WatchProtocolSDK`
- Framework search paths 是否正确

---

## 🆘 仍然无法解决？

如果以上方案都无法解决问题，请提供以下信息：

### 1. 环境信息
- Xcode 版本：`xcodebuild -version`
- macOS 版本：`sw_vers`
- iOS Deployment Target：（在 Xcode 中查看）

### 2. 配置信息

在终端执行并提供输出：

```bash
# 进入项目目录
cd /path/to/your/project

# 导出 Build Settings
xcodebuild -project YourProject.xcodeproj -target YourTarget -showBuildSettings > build_settings.txt
```

提供 `build_settings.txt` 中以下配置：
- `FRAMEWORK_SEARCH_PATHS`
- `LIBRARY_SEARCH_PATHS`
- `HEADER_SEARCH_PATHS`
- `OTHER_LDFLAGS`
- `IPHONEOS_DEPLOYMENT_TARGET`
- `ARCHS`

### 3. 完整错误日志

提供完整的编译错误信息，特别是：
- 所有 "Undefined symbols" 错误
- 所有 "warning" 信息
- Link 阶段的完整输出

---

## 📚 相关文档

- [STATIC_XCFRAMEWORK_USAGE.md](./STATIC_XCFRAMEWORK_USAGE.md) - 静态库 XCFramework 使用指南
- [INTEGRATION_GUIDE.md](./INTEGRATION_GUIDE.md) - 完整集成指南
- [QUICK_FIX.md](./QUICK_FIX.md) - 快速修复常见问题
- [README.md](./README.md) - SDK 文档

---

## 💡 提示

**90% 的链接错误都是因为 XCFramework 没有正确添加到项目**。请优先检查方案 1。

如果你是从旧版本升级，建议：
1. 完全删除旧的 framework
2. 清理 DerivedData
3. 重新添加新的 XCFramework
4. 按照本文档重新配置

---

## 📧 技术支持

如有问题，请联系：315082431@qq.com

提供问题时，请附上：
1. 完整错误信息
2. Build Settings 截图
3. Xcode 版本
