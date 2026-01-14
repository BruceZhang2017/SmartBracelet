# WatchProtocolSDK-ObjC Framework 集成指南

## 方式一：直接集成 XCFramework

### 1. 添加到项目

1. 将 `WatchProtocolSDK.xcframework` 拖入项目
2. 在 Target -> General -> Frameworks, Libraries, and Embedded Content 中：
   - 确认 `WatchProtocolSDK.xcframework` 已添加
   - 设置 Embed 为 **Embed & Sign**

### 2. 添加系统框架依赖

在 Target -> Build Phases -> Link Binary With Libraries 中添加：
- `CoreBluetooth.framework`
- `Foundation.framework`

### 3. 配置权限

在 `Info.plist` 中添加：

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>需要使用蓝牙连接智能手表设备</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>需要使用蓝牙与智能手表进行数据交互</string>
```

### 4. 导入使用

```objc
#import <WatchProtocolSDK/WatchProtocolSDK.h>

// 初始化
[[WPDeviceManager sharedInstance] initializeWithStorage:storage];
[[WPBluetoothManager sharedInstance] initCentral];
```

---

## 方式二：使用 CocoaPods

### 1. 添加到 Podfile

```ruby
pod 'WatchProtocolSDK-ObjC', :path => './WatchProtocolSDK-ObjC.podspec'
```

### 2. 安装

```bash
pod install
```

### 3. 导入使用

```objc
#import <WatchProtocolSDK/WatchProtocolSDK.h>
```

---

## 验证安装

```objc
// AppDelegate.m
#import <WatchProtocolSDK/WatchProtocolSDK.h>

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // 测试：获取单例
    WPDeviceManager *manager = [WPDeviceManager sharedInstance];
    NSLog(@"✅ WatchProtocolSDK 加载成功");

    return YES;
}
```

---

## 常见问题

### Q: 编译时提示找不到头文件？

**A**: 确保在 Build Settings -> Framework Search Paths 中添加了 framework 的路径。

### Q: 运行时提示 dyld: Library not loaded？

**A**: 确保 Embed 设置为 "Embed & Sign"，而不是 "Do Not Embed"。

### Q: 如何在 Objective-C++ 文件中使用？

**A**: 直接导入即可，framework 完全兼容 Objective-C++：

```objc
#import <WatchProtocolSDK/WatchProtocolSDK.h>
```

---

## 更多文档

请查看：
- `README.md` - 完整的 API 文档
- `WatchProtocolSDK-ObjC.podspec` - CocoaPods 配置
