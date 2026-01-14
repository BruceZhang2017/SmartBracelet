# WatchProtocolSDK-ObjC 动态 Framework 集成指南

## ✅ 这是纯 Objective-C 动态 Framework

本版本从 **WatchProtocolSDK-ObjC** 源码编译，是真正的 Objective-C 动态 Framework。

## 集成步骤

### 1. 添加 Framework 到项目

1. 将 `WatchProtocolSDK.xcframework` 拖入项目
2. 选择 Target → **General** → **Frameworks, Libraries, and Embedded Content**
3. 找到 `WatchProtocolSDK.xcframework`
4. **重要**：设置 Embed 为 **"Embed & Sign"**（动态库必须嵌入）

### 2. 导入并使用

```objc
// AppDelegate.m
#import <WatchProtocolSDK/WatchProtocolSDK.h>

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

### 3. 使用所有功能

```objc
// ViewController.m
#import <WatchProtocolSDK/WatchProtocolSDK.h>
#import <WatchProtocolSDK/WPHealthDataModels.h>
#import <WatchProtocolSDK/WPDeviceManager.h>
#import <WatchProtocolSDK/WPBluetoothManager.h>

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // 使用健康数据模型
    WPStepData *stepData = [[WPStepData alloc] init];
    stepData.step = 10000;

    // 使用设备管理器
    WPDeviceManager *deviceManager = [WPDeviceManager sharedInstance];

    // 使用蓝牙管理器
    WPBluetoothManager *btManager = [WPBluetoothManager sharedInstance];
    [btManager startScanning:YES];
}

@end
```

## 与静态库版本的区别

| 特性 | 动态 Framework | 静态库 XCFramework |
|------|---------------|-------------------|
| 导入语法 | `#import <WatchProtocolSDK/Header.h>` ✅ | `@import WatchProtocolSDK` 或 `#import "WatchProtocolSDK.h"` |
| Embed 设置 | **Embed & Sign** | Do Not Embed |
| 应用体积 | Framework 嵌入到 App | 链接到可执行文件（体积更小） |
| 启动时间 | 需要加载动态库 | 无额外加载（更快） |
| 集成难度 | **更简单，标准语法** | 需要注意导入方式 |

## 优势

✅ **标准语法**：使用 iOS 开发者熟悉的 `#import <Framework/Header.h>` 语法
✅ **易于集成**：和系统 Framework 使用方式完全一致
✅ **模块化支持**：自动支持 `@import WatchProtocolSDK`
✅ **纯 Objective-C**：无 Swift 运行时依赖，体积更小

## 系统要求

- iOS 13.0+
- Xcode 12.0+
- 仅依赖系统框架：CoreBluetooth、Foundation

## 常见问题

### Q: dyld: Library not loaded 错误？

**A**: 检查以下设置：
1. Target → General → Frameworks, Libraries, and Embedded Content
2. 确认 `WatchProtocolSDK.xcframework` 的 Embed 设置为 **"Embed & Sign"**
3. 如果设置为 "Do Not Embed"，运行时会找不到动态库

### Q: 链接错误：Undefined symbols for architecture arm64？

**A**: 检查以下设置：
1. 确认 `WatchProtocolSDK.xcframework` 已添加到项目
2. Target → Build Phases → Link Binary With Libraries 中应该包含 WatchProtocolSDK
3. 清理项目：Product → Clean Build Folder (⇧⌘K)
4. 删除 DerivedData：`rm -rf ~/Library/Developer/Xcode/DerivedData/*`

### Q: 如何验证 Framework 是否正确？

**A**: 运行以下命令检查符号：
```bash
nm -g path/to/WatchProtocolSDK.xcframework/ios-arm64/WatchProtocolSDK.framework/WatchProtocolSDK | grep WPBluetoothManager
```

应该能看到：
```
... T _OBJC_CLASS_$_WPBluetoothManager
... T _OBJC_METACLASS_$_WPBluetoothManager
```

### Q: Swift 项目如何使用？

**A**: 创建 Bridging Header：
```objc
// YourProject-Bridging-Header.h
#import <WatchProtocolSDK/WatchProtocolSDK.h>
```

然后在 Swift 中直接使用：
```swift
let manager = WPDeviceManager.shared()
manager.initialize(withStorage: storage)
```

## 技术支持

如有问题，请联系：315082431@qq.com

提供问题时，请附上：
1. Xcode 版本
2. 完整错误信息
3. Build Settings 中的 Framework Search Paths 配置
