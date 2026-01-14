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
