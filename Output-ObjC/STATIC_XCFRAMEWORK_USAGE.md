# WatchProtocolSDK 静态库 XCFramework 使用指南

## ⚠️ 重要：静态库 XCFramework 的导入方式

由于 WatchProtocolSDK 是**静态库(.a) 打包的 XCFramework**，而不是动态 Framework，所以导入方式需要特别注意。

## ✅ 正确的导入方式

###方式 1：使用 @import（推荐） ⭐

```objc
// AppDelegate.m
@import WatchProtocolSDK;

// 使用
WPDeviceManager *manager = [WPDeviceManager sharedInstance];
```

### 方式 2：直接导入主头文件

```objc
// AppDelegate.m
#import "WatchProtocolSDK.h"

// 使用
WPDeviceManager *manager = [WPDeviceManager sharedInstance];
```

## ❌ 错误的导入方式（不要使用）

```objc
// ❌ 这种方式只适用于动态 Framework，静态库不支持
#import <WatchProtocolSDK/WatchProtocolSDK.h>

// ❌ 也不支持单独导入子头文件
#import <WatchProtocolSDK/WPHealthDataModels.h>
```

## 为什么？

### 静态库 vs 动态 Framework

| 特性 | 静态库 XCFramework | 动态 Framework |
|------|-------------------|----------------|
| 文件结构 | `.a` + Headers | `.framework` 包 |
| 模块路径 | 扁平化头文件 | 支持子路径 |
| 导入语法 | `@import` 或 `#import "..."` | `#import <Framework/...>` |
| 嵌入方式 | Do Not Embed | Embed & Sign |

WatchProtocolSDK 是静态库打包的 XCFramework，头文件是扁平化的，不支持 `<WatchProtocolSDK/...>` 路径前缀。

## 完整集成步骤

### 1. 添加 XCFramework

1. 将 `WatchProtocolSDK.xcframework` 拖入项目
2. Target → General → Frameworks, Libraries, and Embedded Content
3. **重要**：设置为 **"Do Not Embed"**（静态库不需要嵌入）

### 2. 配置 Build Settings

通常 Xcode 会自动配置，但如果有问题，检查：

- **Framework Search Paths**：包含 `$(PROJECT_DIR)/Frameworks`（如果 framework 在 Frameworks 目录）
- **Enable Modules**：设置为 `YES`

### 3. 导入并使用

```objc
//  AppDelegate.m

@import WatchProtocolSDK;  // ✅ 使用 @import

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

### 4. 使用 SDK 功能

```objc
// ViewController.m

@import WatchProtocolSDK;

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // 使用健康数据模型
    WPHealthData *healthData = [[WPHealthData alloc] init];
    healthData.steps = 10000;
    healthData.heartRate = 75;

    // 使用设备管理器
    WPDeviceManager *manager = [WPDeviceManager sharedInstance];

    // 使用蓝牙管理器
    WPBluetoothManager *btManager = [WPBluetoothManager sharedInstance];
    [btManager scanDevices];
}

@end
```

## 如果必须使用 #import

如果你的项目不支持 `@import`（虽然很少见），可以使用：

```objc
#import "WatchProtocolSDK.h"
```

**配置要求**：
- Build Settings → Header Search Paths 中添加：  `$(PROJECT_DIR)/Frameworks/WatchProtocolSDK.xcframework/ios-$(PLATFORM_NAME)/Headers`

## 常见问题

### Q: 为什么不能用 `#import <WatchProtocolSDK/...>`？

**A**: 因为这是静态库 XCFramework，不是真正的 .framework 包。头文件路径是扁平化的，不支持子路径。

### Q: 编译时提示 "module 'WatchProtocolSDK' not found"？

**A**: 检查：
1. Framework Search Paths 是否包含 framework 所在目录
2. Enable Modules 是否设置为 YES
3. 清理 DerivedData：`rm -rf ~/Library/Developer/Xcode/DerivedData/*`

### Q: 我可以转换成动态 Framework 吗？

**A**: 可以，但需要重新构建。动态 Framework 的优势：
- 支持 `#import <Framework/Header.h>` 语法
- 更符合 iOS 开发习惯
- 支持资源文件

缺点：
- 应用体积可能更大（动态库会被嵌入）
- 启动时间可能稍长

### Q: Swift 项目如何使用？

**A**: 创建 Bridging Header：

```objc
// YourProject-Bridging-Header.h
@import WatchProtocolSDK;
```

然后在 Swift 中：

```swift
import Foundation

// 直接使用
let manager = WPDeviceManager.shared()
```

## 总结

✅ **推荐做法**：
```objc
@import WatchProtocolSDK;
```

✅ **备用方案**：
```objc
#import "WatchProtocolSDK.h"
```

❌ **不要使用**：
```objc
#import <WatchProtocolSDK/WatchProtocolSDK.h>  // 静态库不支持！
```

## 需要帮助？

如果遇到集成问题，请提供：
1. Xcode 版本
2. 完整的错误信息
3. Build Settings 中的 Framework Search Paths 和 Header Search Paths 配置
