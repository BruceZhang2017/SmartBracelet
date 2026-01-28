# WatchProtocolSDK-ObjC 接入文档

## 版本信息
- **SDK 版本**: v2.0.8
- **发布日期**: 2026-01-27
- **更新内容**: 🐛 修正查找设备参数值（开始查找传0，停止查找传1）
- **支持平台**: iOS 13.0+
- **开发语言**: Objective-C

---

## 目录
1. [SDK 简介](#sdk-简介)
2. [系统要求](#系统要求)
3. [SDK 集成](#sdk-集成)
4. [快速开始](#快速开始)
5. [核心功能](#核心功能)
6. [API 参考](#api-参考)
7. [示例代码](#示例代码)
8. [常见问题](#常见问题)

---

## SDK 简介

WatchProtocolSDK-ObjC 是一款专为智能手表设备开发的 iOS 蓝牙通信协议 SDK，使用纯 Objective-C 实现。它提供了完整的设备连接管理、健康数据同步、协议指令处理等功能，帮助 Objective-C 项目快速集成智能手表设备功能。

### 主要特性

- ✅ **纯 Objective-C 实现**: 完全兼容 Objective-C 项目，无需 Swift 环境
- ✅ **蓝牙设备管理**: 支持设备扫描、连接、断开、重连等完整生命周期管理
- ✅ **健康数据同步**: 支持步数、睡眠、心率、血氧、血压等多种健康数据同步
- ✅ **协议化存储**: 基于协议的数据存储设计，灵活适配不同存储方案
- ✅ **线程安全**: 核心管理类采用线程安全设计
- ✅ **日志系统**: 内置完善的日志记录系统，便于问题排查
- ✅ **模块化架构**: 清晰的模块划分，易于维护和扩展

---

## 系统要求

| 项目 | 要求 |
|------|------|
| iOS 版本 | iOS 13.0 及以上 |
| Xcode 版本 | Xcode 12.0 及以上 |
| 开发语言 | Objective-C |
| 设备蓝牙 | 支持 Bluetooth 4.0 (BLE) |

### 依赖框架

- `CoreBluetooth.framework` (系统框架)
- `Foundation.framework` (系统框架)

---

## SDK 集成

### 方式一：手动集成

1. 将 `WatchProtocolSDK-ObjC` 文件夹拖入项目
2. 在项目 Target -> Build Phases -> Link Binary With Libraries 中添加：
   - `CoreBluetooth.framework`
   - `Foundation.framework`

### 方式二：使用 CocoaPods

在 `Podfile` 中添加：

```ruby
pod 'WatchProtocolSDK-ObjC', :path => './WatchProtocolSDK-ObjC.podspec'
```

然后执行：
```bash
pod install
```

### 配置项目

1. **添加蓝牙权限**
   在 `Info.plist` 中添加以下权限描述：

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>需要使用蓝牙连接智能手表设备</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>需要使用蓝牙与智能手表进行数据交互</string>
```

2. **导入框架**

```objc
#import <WatchProtocolSDK/WatchProtocolSDK.h>
```

---

## 快速开始

### 1. 实现数据存储协议

```objc
// MyHealthDataStorage.h
#import <Foundation/Foundation.h>
#import <WatchProtocolSDK/WPHealthDataStorage.h>

@interface MyHealthDataStorage : NSObject <WPHealthDataStorageProtocol>
@end

// MyHealthDataStorage.m
#import "MyHealthDataStorage.h"
#import <WatchProtocolSDK/WPHealthDataModels.h>

@implementation MyHealthDataStorage

- (void)saveStepData:(WPStepData *)data {
    NSLog(@"保存步数数据: %ld steps on %@", (long)data.step, data.date);
    // TODO: 保存到数据库
}

- (void)saveSleepData:(WPSleepData *)data {
    NSLog(@"保存睡眠数据: deep=%ld, light=%ld, awake=%ld",
          (long)data.deep, (long)data.light, (long)data.awake);
    // TODO: 保存到数据库
}

- (void)saveHeartData:(WPHeartData *)data {
    NSLog(@"保存心率数据: %ld bpm", (long)data.heart);
    // TODO: 保存到数据库
}

- (void)saveOxygenData:(WPOxygenData *)data {
    NSLog(@"保存血氧数据: %ld%%", (long)data.oxygen);
    // TODO: 保存到数据库
}

- (void)saveBloodPressureData:(WPBloodPressureData *)data {
    NSLog(@"保存血压数据: %ld/%ld mmHg", (long)data.max, (long)data.min);
    // TODO: 保存到数据库
}

@end
```

### 2. 初始化 SDK

```objc
// AppDelegate.m
#import "AppDelegate.h"
#import "MyHealthDataStorage.h"
#import <WatchProtocolSDK/WatchProtocolSDK.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // 1. 创建数据存储实例
    MyHealthDataStorage *storage = [[MyHealthDataStorage alloc] init];

    // 2. 初始化设备管理器
    [[WPDeviceManager sharedInstance] initializeWithStorage:storage];

    // 3. 初始化蓝牙管理器
    [[WPBluetoothManager sharedInstance] initCentral];

    return YES;
}

@end
```

### 3. 扫描和连接设备

```objc
#import <WatchProtocolSDK/WatchProtocolSDK.h>

@interface ViewController () <WPBluetoothManagerDelegate>
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // 设置蓝牙代理
    [WPBluetoothManager sharedInstance].delegate = self;
}

- (IBAction)startScanButtonTapped:(id)sender {
    // 开始扫描设备
    [[WPBluetoothManager sharedInstance] startScanning:YES];
}

- (IBAction)stopScanButtonTapped:(id)sender {
    // 停止扫描
    [[WPBluetoothManager sharedInstance] stopScanning];
}

- (void)connectToDeviceWithMac:(NSString *)macAddress {
    // 连接指定 MAC 地址的设备
    [[WPBluetoothManager sharedInstance] connectToDeviceWithMac:macAddress];
}

// MARK: - WPBluetoothManagerDelegate

- (void)onBleReady {
    NSLog(@"蓝牙已准备就绪");
}

- (void)didDiscoverPeripheral:(WPPeripheralInfo *)peripheralInfo {
    NSLog(@"发现设备: %@ [%@]",
          peripheralInfo.peripheral.name ?: @"未知",
          peripheralInfo.macAddress);

    // TODO: 更新 UI 显示设备列表
}

- (void)didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"设备连接成功: %@", peripheral.name);

    // TODO: 更新 UI 状态
}

- (void)didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"设备已断开: %@ - %@", peripheral.name, error.localizedDescription);

    // TODO: 更新 UI 状态
}

- (void)receiveData:(NSData *)data {
    NSLog(@"接收到数据: %@", data);

    // TODO: 处理接收的数据
}

@end
```

---

## 核心功能

### 设备管理

```objc
// 获取设备管理器
WPDeviceManager *manager = [WPDeviceManager sharedInstance];

// 获取设备缓存列表
NSArray<WPBluetoothWatchDevice *> *devices = manager.cacheDevices;

// 添加设备到缓存
[manager addDevice:device];

// 查找指定 MAC 地址的设备
WPBluetoothWatchDevice *device = [manager findDeviceWithMac:@"XX:XX:XX:XX:XX:XX"];

// 获取最后一个设备
WPBluetoothWatchDevice *lastDevice = [manager lastDevice];

// 清空设备缓存
[manager clearDeviceCache];

// 重新加载设备（从 UserDefaults）
[manager reloadDevices];
```

### 蓝牙管理

```objc
// 获取蓝牙管理器
WPBluetoothManager *btManager = [WPBluetoothManager sharedInstance];

// 初始化蓝牙中心
[btManager initCentral];

// 开始扫描设备（清空之前的扫描结果）
[btManager startScanning:YES];

// 开始扫描设备（保留之前的扫描结果）
[btManager startScanning:NO];

// 停止扫描
[btManager stopScanning];

// 连接指定外设
[btManager connectToPeripheral:peripheral];

// 连接指定 MAC 地址的设备
[btManager connectToDeviceWithMac:@"XX:XX:XX:XX:XX:XX"];

// 扫描并连接指定设备
[btManager connectAndScanWithMac:@"XX:XX:XX:XX:XX:XX" deviceName:@"MyWatch"];

// 断开当前连接
[btManager disconnect];

// 发送数据
NSData *data = [@"Hello" dataUsingEncoding:NSUTF8StringEncoding];
BOOL success = [btManager sendData:data];
```

### 扫描设备保存（v1.1.0+）

**新功能**：提供三种便捷方法，简化从扫描设备到保存设备的流程。

```objc
// 获取扫描到的设备
NSArray<WPPeripheralInfo *> *devices = [WPBluetoothManager sharedInstance].discoveredPeripherals;
WPPeripheralInfo *info = devices.firstObject;

// 方法 1：工厂方法（推荐，架构清晰）
WPBluetoothWatchDevice *device = [WPBluetoothWatchDevice deviceFromPeripheralInfo:info];
[WPBluetoothWatchDevice saveToSandbox:device];

// 方法 2：一步保存（推荐，最简洁）
[WPBluetoothWatchDevice savePeripheralInfoToSandbox:info];

// 方法 3：Category 便捷方法（可选，需导入头文件）
#import "WPPeripheralInfo+WatchDevice.h"
WPBluetoothWatchDevice *device = [info toWatchDevice];
[info saveToSandbox];
```

**详细说明**：参考 [扫描设备保存使用指南](PERIPHERAL_TO_DEVICE_GUIDE.md)

### 连接失败诊断

```objc
WPDeviceManager *manager = [WPDeviceManager sharedInstance];

// 追加连接失败信息
[manager appendFailMessage:@"连接超时"];

// 获取所有失败信息
NSString *allFailures = manager.connectFailMessage;

// 获取最近的失败信息数组
NSArray<NSString *> *failures = manager.recentFailMessages;

// 获取最近 5 条失败信息
NSArray<NSString *> *recent5 = [manager getRecentFailMessagesWithCount:5];

// 清空失败信息
[manager clearFailMessages];
```

### 🔥 查找设备（v2.0.7+）

**新功能**：智能查找设备功能，让手环震动/响铃以帮助用户找到设备。

#### 基础用法

```objc
// 1. 查找手环（带完成回调）
[WPCommands findBandWithCompletion:^(BOOL success, NSError *error) {
    if (success) {
        NSLog(@"✅ 手环正在震动，请留意周围");
    } else {
        NSLog(@"❌ 查找失败: %@", error.localizedDescription);
    }
}];

// 2. 停止查找
[WPCommands stopFindBandWithCompletion:^(BOOL success, NSError *error) {
    if (success) {
        NSLog(@"⏹ 已停止查找");
    }
}];

// 3. 自动停止（5秒后）
[WPCommands findBandWithDuration:5.0 completion:^(BOOL success, NSError *error) {
    NSLog(@"查找已结束");
}];

// 4. 查询查找状态
if ([WPCommands isFindingDevice]) {
    NSLog(@"正在查找中...");
}

// 5. 取消所有查找任务
[WPCommands cancelAllFindTasks];
```

#### 核心优势

| 功能 | 说明 |
|------|------|
| ✅ 完成回调 | 指令发送结果实时反馈 |
| ✅ 主动停止 | 随时停止手环震动/响铃 |
| ✅ 自动停止 | 指定时长后自动停止 |
| ✅ 状态检查 | 查询是否正在查找中 |
| ✅ 错误处理 | 自动检查蓝牙和连接状态 |

#### 典型场景

```objc
// 场景 1：设备列表快捷查找
- (void)onFindButtonTapped:(WPBluetoothWatchDevice *)device {
    [WPCommands findBandWithDuration:5.0 completion:^(BOOL success, NSError *error) {
        if (success) {
            [self showToast:@"查找完成"];
        }
    }];
}

// 场景 2：动态更新 UI
- (void)updateUI {
    if ([WPCommands isFindingDevice]) {
        [self.findButton setTitle:@"停止查找" forState:UIControlStateNormal];
    } else {
        [self.findButton setTitle:@"查找设备" forState:UIControlStateNormal];
    }
}

// 场景 3：页面销毁时清理
- (void)dealloc {
    [WPCommands cancelAllFindTasks];
}
```

**详细说明**：参考 [查找设备使用指南](FIND_DEVICE_GUIDE.md)

#### ⭐️ 推荐：通过 WPBluetoothManager 使用（v2.0.7+）

**优势**：与其他功能（如 `queryBatteryLevel`）保持一致的 API 风格，面向对象设计，更易于测试和维护。

```objc
WPBluetoothManager *manager = [WPBluetoothManager sharedInstance];

// 1. 查找手环
[manager findDeviceWithCompletion:^(BOOL success, NSError *error) {
    if (success) {
        NSLog(@"✅ 手环正在震动");
    } else {
        NSLog(@"❌ 查找失败: %@", error.localizedDescription);
    }
}];

// 2. 停止查找
[manager stopFindDeviceWithCompletion:^(BOOL success, NSError *error) {
    if (success) {
        NSLog(@"⏹ 已停止查找");
    }
}];

// 3. 自动停止（5秒后）
[manager findDeviceWithDuration:5.0 completion:^(BOOL success, NSError *error) {
    NSLog(@"查找已结束");
}];

// 4. 查询查找状态
if (manager.isFindingDevice) {
    NSLog(@"正在查找中...");
}
```

**详细说明**：参考 [WPBluetoothManager 查找设备指南](WPBLUETOOTHMANAGER_FINDDEVICE_GUIDE.md)

---

## API 参考

### WPDeviceManager

| 方法 | 说明 |
|------|------|
| `+sharedInstance` | 获取单例实例 |
| `-initializeWithStorage:` | 初始化设备管理器（配置数据存储） |
| `-addDevice:` | 添加设备到缓存 |
| `-removeDeviceWithMac:` | 移除指定 MAC 地址的设备 |
| `-findDeviceWithMac:` | 查找指定 MAC 地址的设备 |
| `-lastDevice` | 获取最后一个设备 |
| `-clearDeviceCache` | 清空所有设备缓存 |
| `-reloadDevices` | 重新加载所有设备 |
| `-appendFailMessage:` | 追加连接失败信息 |
| `-clearFailMessages` | 清空所有连接失败信息 |

### WPBluetoothManager

| 方法 | 说明 |
|------|------|
| `+sharedInstance` | 获取单例实例 |
| `-initCentral` | 初始化中心管理器 |
| `-startScanning:` | 开始扫描设备 |
| `-stopScanning` | 停止扫描设备 |
| `-connectToPeripheral:` | 连接指定外设 |
| `-connectToDeviceWithMac:` | 连接指定 MAC 地址的设备 |
| `-connectAndScanWithMac:deviceName:` | 扫描并连接指定设备 |
| `-disconnect` | 断开当前连接 |
| `-sendData:` | 发送数据到设备 |
| **🔥 `-findDeviceWithCompletion:`** | **(v2.0.7+)** 查找手环（带完成回调） |
| **🔥 `-stopFindDeviceWithCompletion:`** | **(v2.0.7+)** 停止查找手环 |
| **🔥 `-findDeviceWithDuration:completion:`** | **(v2.0.7+)** 查找手环（自动停止） |
| **🔥 `.isFindingDevice`** | **(v2.0.7+)** 是否正在查找设备（只读属性） |

### WPCommands+FindDevice (v2.0.7+)

| 方法 | 说明 |
|------|------|
| `+findBandWithCompletion:` | 查找手环（带完成回调） |
| `+stopFindBandWithCompletion:` | 停止查找手环 |
| `+findBandWithDuration:completion:` | 查找手环（自动停止） |
| `+isFindingDevice` | 是否正在查找设备（只读属性） |
| `+cancelAllFindTasks` | 取消所有查找任务 |
| `+findPhoneWithCompletion:` | 查找手机（兼容性方法） |

---

## 示例代码

完整的示例项目请参考 `Examples` 文件夹。

---

## 常见问题

### 1. 如何检查蓝牙是否已开启？

```objc
BOOL isOff = [[WPBluetoothManager sharedInstance] isBluetoothPoweredOff];
if (isOff) {
    NSLog(@"请打开蓝牙");
}
```

### 2. 如何检查设备是否已连接？

```objc
BOOL connected = [[WPBluetoothManager sharedInstance] isConnected];
```

### 3. 如何保存设备到沙盒？

```objc
WPBluetoothWatchDevice *device = [[WPBluetoothWatchDevice alloc] init];
device.deviceName = @"MyWatch";
device.mac = @"XX:XX:XX:XX:XX:XX";

[WPBluetoothWatchDevice saveToSandbox:device];
```

### 4. 如何从沙盒加载设备？

```objc
// 通过 MAC 加载
WPBluetoothWatchDevice *device = [WPBluetoothWatchDevice loadFromSandboxWithMac:@"XX:XX:XX:XX:XX:XX"];

// 通过设备名称加载
WPBluetoothWatchDevice *device = [WPBluetoothWatchDevice loadFromSandboxWithDeviceName:@"MyWatch"];
```

### 5. 如何查看日志文件？

```objc
NSString *logPath = [[WPLogger sharedInstance] logFilePath];
NSLog(@"日志文件路径: %@", logPath);
```

---

## 技术支持

如有问题，请联系：315082431@qq.com

---

## 许可证

MIT License
