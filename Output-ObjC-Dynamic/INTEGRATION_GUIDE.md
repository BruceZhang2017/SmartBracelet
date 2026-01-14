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

