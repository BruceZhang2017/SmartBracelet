# 🚀 WatchProtocolSDK 动态 Framework 快速开始

## ✨ 这是什么？

这是 **WatchProtocolSDK 的动态 Framework 版本**，支持标准的 iOS Framework 导入语法：

```objc
#import <WatchProtocolSDK/WatchProtocolSDK.h>  // ✅ 标准语法
```

## 📦 与静态库版本的区别

| 特性 | 动态 Framework (本版本) | 静态库版本 |
|------|----------------------|-----------|
| 导入语法 | `#import <Framework/Header.h>` ✅ | `@import Framework` 或 `#import "Header.h"` |
| Embed 设置 | **Embed & Sign** | Do Not Embed |
| 开发体验 | 符合 iOS 标准，易用 ✅ | 需要特殊配置 |
| 应用体积 | Framework 嵌入，略大 | 链接到可执行文件，更小 |
| 启动时间 | 需加载动态库 | 无额外开销 |

**推荐使用动态 Framework**，除非对应用体积有极致要求。

## 🔧 集成步骤（3步完成）

### 步骤 1：添加 Framework

1. 将 `WatchProtocolSDK.xcframework` 拖入 Xcode 项目
2. 确认勾选 "Copy items if needed"
3. 选择正确的 Target

### 步骤 2：配置 Embed（重要！）

1. 选择 Target → **General** 标签
2. 滚动到 **Frameworks, Libraries, and Embedded Content**
3. 找到 `WatchProtocolSDK.xcframework`
4. **将 Embed 设置为 "Embed & Sign"** （不是 "Do Not Embed"）

   ⚠️ **这一步非常重要！** 动态 Framework 必须嵌入应用包中。

### 步骤 3：导入并使用

```objc
//  AppDelegate.m

#import <WatchProtocolSDK/WatchProtocolSDK.h>  // ✅ 使用标准语法

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

## 📚 使用示例

### 导入方式

```objc
// 方式 1：导入主头文件（推荐）
#import <WatchProtocolSDK/WatchProtocolSDK.h>

// 方式 2：单独导入需要的头文件
#import <WatchProtocolSDK/WPHealthDataModels.h>
#import <WatchProtocolSDK/WPDeviceManager.h>
#import <WatchProtocolSDK/WPBluetoothManager.h>

// 方式 3：使用 @import（Swift 风格）
@import WatchProtocolSDK;
```

### 健康数据使用

```objc
#import <WatchProtocolSDK/WPHealthDataModels.h>

// 创建健康数据
WPHealthData *healthData = [[WPHealthData alloc] init];
healthData.steps = 10000;
healthData.heartRate = 75;
healthData.bloodOxygen = 98;

NSLog(@"步数: %d, 心率: %d", healthData.steps, healthData.heartRate);
```

### 设备管理

```objc
#import <WatchProtocolSDK/WPDeviceManager.h>

// 获取设备管理器
WPDeviceManager *manager = [WPDeviceManager sharedInstance];

// 初始化（传入存储实现，可选）
[manager initializeWithStorage:nil];

// 使用管理器
NSLog(@"设备管理器: %@", manager);
```

### 蓝牙扫描

```objc
#import <WatchProtocolSDK/WPBluetoothManager.h>

// 获取蓝牙管理器
WPBluetoothManager *btManager = [WPBluetoothManager sharedInstance];

// 初始化蓝牙
[btManager initCentral];

// 开始扫描
[btManager scanDevices];
```

## ⚠️ 常见问题

### Q: dyld: Library not loaded: @rpath/WatchProtocolSDK.framework/WatchProtocolSDK

**原因**：Embed 设置错误

**解决**：
1. Target → General → Frameworks, Libraries, and Embedded Content
2. 将 `WatchProtocolSDK.xcframework` 的 Embed 改为 **"Embed & Sign"**
3. Clean Build Folder (⇧⌘K) 后重新编译

### Q: 'WatchProtocolSDK/WatchProtocolSDK.h' file not found

**原因**：Framework Search Paths 配置不正确

**解决**：
1. 确认 Framework 已正确添加到项目
2. Build Settings → Framework Search Paths 应包含：`$(PROJECT_DIR)/Frameworks`（如果你的 framework 在 Frameworks 目录）
3. 清理 DerivedData：`rm -rf ~/Library/Developer/Xcode/DerivedData/*`

### Q: 模块 'WatchProtocolSDK' not found

**解决**：
1. Build Settings → Enable Modules 设置为 `YES`
2. 确认 Framework Search Paths 正确
3. 清理并重新编译

### Q: Swift 项目如何使用？

**方法 1：Bridging Header（Objective-C 混编）**

创建 `YourProject-Bridging-Header.h`：
```objc
#import <WatchProtocolSDK/WatchProtocolSDK.h>
```

**方法 2：直接导入（Swift 原生）**

```swift
import WatchProtocolSDK

// 使用
let manager = WPDeviceManager.shared()
```

### Q: 应用体积增加了多少？

动态 Framework 大小约 **3.9 MB**，会被完整嵌入到应用包中。

如果对体积敏感，可以使用静态库版本（在 `Output-ObjC/` 目录）。

## 📋 系统要求

- **iOS**: 13.0+
- **Xcode**: 14.0+
- **语言**: Objective-C / Swift 5.0+

## 🎯 验证集成

创建测试文件验证集成是否成功：

```objc
// TestWatchProtocolSDK.m

#import <WatchProtocolSDK/WatchProtocolSDK.h>

@implementation TestWatchProtocolSDK

+ (void)runTests {
    NSLog(@"========================================");
    NSLog(@"WatchProtocolSDK 集成测试");
    NSLog(@"========================================");

    // 测试 1: 创建健康数据
    WPHealthData *healthData = [[WPHealthData alloc] init];
    healthData.steps = 10000;
    NSLog(@"✅ 测试 1: WPHealthData 创建成功");

    // 测试 2: 获取设备管理器
    WPDeviceManager *manager = [WPDeviceManager sharedInstance];
    NSLog(@"✅ 测试 2: WPDeviceManager 初始化成功");

    // 测试 3: 获取蓝牙管理器
    WPBluetoothManager *btManager = [WPBluetoothManager sharedInstance];
    NSLog(@"✅ 测试 3: WPBluetoothManager 初始化成功");

    NSLog(@"========================================");
    NSLog(@"🎉 所有测试通过!");
    NSLog(@"========================================");
}

@end
```

在 `AppDelegate.m` 中调用：
```objc
[TestWatchProtocolSDK runTests];
```

## 📞 需要帮助？

如果遇到问题，请提供：
- Xcode 版本：`xcodebuild -version`
- 错误信息截图
- Build Settings 中的 Framework Search Paths 配置

## 🎉 完成！

现在你可以使用标准的 iOS Framework 导入语法来使用 WatchProtocolSDK 了！

```objc
#import <WatchProtocolSDK/WatchProtocolSDK.h>  // ✅ 就是这么简单！
```
