# 快速修复：'WatchProtocolSDK/WatchProtocolSDK.h' file not found

## 问题原因

你使用了动态 Framework 的导入方式，但 WatchProtocolSDK 是静态库 XCFramework。

## 🚀 立即修复（3步）

### 步骤 1：修改导入语句

打开 `AppDelegate.m`（第 9 行）：

```objc
// ❌ 删除这行
#import <WatchProtocolSDK/WatchProtocolSDK.h>

// ✅ 改为这行
@import WatchProtocolSDK;
```

### 步骤 2：检查 Embed 设置

1. 在 Xcode 中选择 Target
2. General 标签页
3. Frameworks, Libraries, and Embedded Content
4. 找到 `WatchProtocolSDK.xcframework`
5. 将 Embed 改为 **"Do Not Embed"**（静态库不需要嵌入）

### 步骤 3：清理并重新编译

```bash
# 在终端执行
cd /Users/anker/Downloads/testHuaxin_oc/testhuaxinOC
rm -rf ~/Library/Developer/Xcode/DerivedData/testhuaxinOC-*
```

然后在 Xcode 中：
- Product → Clean Build Folder (⇧⌘K)
- Product → Build (⌘B)

## 完整示例

```objc
//
//  AppDelegate.m
//  testhuaxinOC
//

#import "AppDelegate.h"
@import WatchProtocolSDK;  // ✅ 使用 @import

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // 测试 SDK
    WPDeviceManager *manager = [WPDeviceManager sharedInstance];
    NSLog(@"✅ WatchProtocolSDK 初始化成功: %@", manager);

    return YES;
}

@end
```

## 如果还有问题

### 方案 A：使用引号导入

```objc
#import "WatchProtocolSDK.h"  // 使用引号而不是尖括号
```

并添加 Header Search Paths：
- Build Settings → Header Search Paths
- 添加：`$(PROJECT_DIR)/Frameworks/WatchProtocolSDK.xcframework/ios-$(PLATFORM_NAME)/Headers`

### 方案 B：使用新版本 SDK

联系我们获取动态 Framework 版本，支持：
```objc
#import <WatchProtocolSDK/WatchProtocolSDK.h>  // 动态版本支持
```

## 为什么会这样？

| 类型 | 导入方式 | Embed 设置 |
|------|---------|-----------|
| 静态库 XCFramework | `@import` 或 `#import "..."` | Do Not Embed |
| 动态 Framework | `#import <Framework/...>` | Embed & Sign |

WatchProtocolSDK 当前是**静态库版本**。

## 联系我们

如果遇到问题，请发送：
- 错误截图
- Build Settings 配置
- Xcode 版本

我们会帮你快速解决！
