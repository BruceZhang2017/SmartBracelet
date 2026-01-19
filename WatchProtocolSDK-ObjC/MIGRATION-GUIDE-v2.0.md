# WatchProtocolSDK-ObjC v2.0 迁移指南

## 📋 目录

- [概述](#概述)
- [破坏性变更](#破坏性变更)
- [迁移步骤](#迁移步骤)
- [常见问题](#常见问题)
- [完整示例](#完整示例)

---

## 概述

### 为什么升级到 v2.0？

v2.0 版本统一了所有公开 API 的参数类型，使用 `WPPeripheralInfo` 替代 `CBPeripheral`，带来以下好处：

✅ **更一致的 API 设计** - 所有方法使用统一的设备信息类型
✅ **更丰富的设备信息** - 直接包含 MAC 地址等扩展信息
✅ **更简化的使用方式** - 无需在 `CBPeripheral` 和 `WPPeripheralInfo` 之间手动转换
✅ **更好的封装性** - 隐藏底层蓝牙实现细节

### 版本兼容性

| 版本 | 兼容性 | 说明 |
|------|--------|------|
| v1.x → v2.0 | ❌ 不兼容 | 需要修改代码 |
| v2.0+ | ✅ 向下兼容 | 未来小版本更新保持兼容 |

---

## 破坏性变更

### 1. 连接方法参数变更

#### `connectToPeripheral:` 方法

```objective-c
// ❌ v1.x 旧版本
WPPeripheralInfo *info = ...;
[[WPBluetoothManager sharedInstance] connectToPeripheral:info.peripheral];

// ✅ v2.0 新版本
WPPeripheralInfo *info = ...;
[[WPBluetoothManager sharedInstance] connectToPeripheral:info];
```

**变更说明**：
- 旧版本：接收 `CBPeripheral *` 参数
- 新版本：接收 `WPPeripheralInfo *` 参数
- 影响范围：所有调用 `connectToPeripheral:` 的代码

---

### 2. 代理方法参数变更

#### `didConnectPeripheral:` 连接成功回调

```objective-c
// ❌ v1.x 旧版本
- (void)didConnectPeripheral:(CBPeripheral *)peripheral {
    NSString *name = peripheral.name;
    NSString *uuid = peripheral.identifier.UUIDString;

    // 需要手动查找 WPPeripheralInfo
    WPPeripheralInfo *info = nil;
    for (WPPeripheralInfo *item in self.discoveredDevices) {
        if ([item.peripheral.identifier isEqual:peripheral.identifier]) {
            info = item;
            break;
        }
    }

    // 手动创建设备对象
    WPBluetoothWatchDevice *device = [[WPBluetoothWatchDevice alloc] init];
    device.deviceName = peripheral.name;
    device.mac = info.macAddress;
}

// ✅ v2.0 新版本
- (void)didConnectPeripheral:(WPPeripheralInfo *)peripheralInfo {
    NSString *name = peripheralInfo.peripheral.name;  // 通过 .peripheral 访问
    NSString *mac = peripheralInfo.macAddress;         // 直接获取 MAC 地址

    // 使用工厂方法创建设备对象
    WPBluetoothWatchDevice *device = [WPBluetoothWatchDevice deviceFromPeripheralInfo:peripheralInfo];
}
```

**变更说明**：
- 旧版本：接收 `CBPeripheral *` 参数，需要手动查找 `WPPeripheralInfo`
- 新版本：直接接收 `WPPeripheralInfo *` 参数，无需手动查找
- 优势：代码更简洁，减少出错可能

---

#### `didDisconnectPeripheral:error:` 断开连接回调

```objective-c
// ❌ v1.x 旧版本
- (void)didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"设备断开: %@", peripheral.name);
}

// ✅ v2.0 新版本
- (void)didDisconnectPeripheral:(WPPeripheralInfo *)peripheralInfo error:(NSError *)error {
    NSLog(@"设备断开: %@ [%@]",
          peripheralInfo.peripheral.name,
          peripheralInfo.macAddress);  // 可以直接获取 MAC 地址
}
```

**变更说明**：
- 旧版本：接收 `CBPeripheral *` 参数
- 新版本：接收 `WPPeripheralInfo *` 参数
- 优势：可以直接获取 MAC 地址等扩展信息

---

## 迁移步骤

### 步骤 1：更新 SDK 版本

将 WatchProtocolSDK-ObjC 升级到 v2.0.0 或更高版本。

**CocoaPods**:
```ruby
pod 'WatchProtocolSDK-ObjC', '~> 2.0'
```

**手动集成**:
替换 `WatchProtocolSDK.xcframework` 为 v2.0.0 版本。

---

### 步骤 2：修改代理方法签名

在所有实现 `WPBluetoothManagerDelegate` 的类中，修改以下方法的参数类型：

```objective-c
@interface YourViewController () <WPBluetoothManagerDelegate>
@end

@implementation YourViewController

// 修改前 ❌
- (void)didConnectPeripheral:(CBPeripheral *)peripheral {
    // ...
}

// 修改后 ✅
- (void)didConnectPeripheral:(WPPeripheralInfo *)peripheralInfo {
    // 如果需要访问 CBPeripheral，使用 peripheralInfo.peripheral
}

// 修改前 ❌
- (void)didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    // ...
}

// 修改后 ✅
- (void)didDisconnectPeripheral:(WPPeripheralInfo *)peripheralInfo error:(NSError *)error {
    // 如果需要访问 CBPeripheral，使用 peripheralInfo.peripheral
}

@end
```

---

### 步骤 3：更新连接调用

找到所有调用 `connectToPeripheral:` 的代码，修改参数：

```objective-c
// 修改前 ❌
WPPeripheralInfo *info = [WPBluetoothManager sharedInstance].discoveredPeripherals.firstObject;
[[WPBluetoothManager sharedInstance] connectToPeripheral:info.peripheral];

// 修改后 ✅
WPPeripheralInfo *info = [WPBluetoothManager sharedInstance].discoveredPeripherals.firstObject;
[[WPBluetoothManager sharedInstance] connectToPeripheral:info];
```

---

### 步骤 4：简化设备对象创建（可选但推荐）

如果你的代码中有手动创建 `WPBluetoothWatchDevice` 的逻辑，建议使用 v1.1.0 引入的工厂方法简化：

```objective-c
// 旧代码（仍然有效，但不推荐）❌
- (void)didConnectPeripheral:(WPPeripheralInfo *)peripheralInfo {
    WPBluetoothWatchDevice *device = [[WPBluetoothWatchDevice alloc] init];
    device.deviceName = peripheralInfo.peripheral.name;
    device.mac = peripheralInfo.macAddress;
    [WPBluetoothWatchDevice saveToSandbox:device];
}

// 新代码（推荐）✅
- (void)didConnectPeripheral:(WPPeripheralInfo *)peripheralInfo {
    WPBluetoothWatchDevice *device = [WPBluetoothWatchDevice deviceFromPeripheralInfo:peripheralInfo];
    [WPBluetoothWatchDevice saveToSandbox:device];

    // 或者更简洁（一行代码）
    // [WPBluetoothWatchDevice savePeripheralInfoToSandbox:peripheralInfo];
}
```

---

### 步骤 5：编译和测试

1. **清理构建**：`⇧⌘K` (Shift + Command + K)
2. **重新编译**：`⌘B` (Command + B)
3. **修复编译错误**：根据编译器提示修改参数类型
4. **运行测试**：确保蓝牙连接和断开功能正常

---

## 常见问题

### Q1: 如何在 v2.0 中访问原始的 CBPeripheral 对象？

**A**: 通过 `peripheralInfo.peripheral` 访问：

```objective-c
- (void)didConnectPeripheral:(WPPeripheralInfo *)peripheralInfo {
    CBPeripheral *peripheral = peripheralInfo.peripheral;  // 获取原始对象
    NSString *name = peripheral.name;
}
```

---

### Q2: 我的代码中有很多地方使用 CBPeripheral，需要全部修改吗?

**A**: 只需要修改以下两处：

1. **代理方法的参数类型**（必须修改）
2. **调用 `connectToPeripheral:` 时的参数**（必须修改）

其他地方可以通过 `peripheralInfo.peripheral` 继续使用 `CBPeripheral`。

---

### Q3: v2.0 是否移除了某些功能？

**A**: 没有。v2.0 仅改变了参数类型，所有功能保持不变。

---

### Q4: 我可以同时使用 CBPeripheral 和 WPPeripheralInfo 吗？

**A**: 可以。`WPPeripheralInfo` 内部包含 `CBPeripheral` 对象，你可以随时通过 `.peripheral` 属性访问：

```objective-c
WPPeripheralInfo *info = ...;
CBPeripheral *peripheral = info.peripheral;  // 随时访问
```

---

### Q5: 迁移大约需要多长时间？

**A**: 通常 10-30 分钟，取决于代码规模：
- 小型项目（1-2个文件）：~10 分钟
- 中型项目（3-5个文件）：~20 分钟
- 大型项目（6+个文件）：~30 分钟

主要时间用于查找和修改所有调用点。

---

## 完整示例

### 迁移前代码（v1.x）

```objective-c
#import <WatchProtocolSDK/WatchProtocolSDK.h>

@interface MyViewController () <WPBluetoothManagerDelegate>
@property (nonatomic, strong) NSMutableArray<WPPeripheralInfo *> *discoveredDevices;
@end

@implementation MyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [WPBluetoothManager sharedInstance].delegate = self;
    self.discoveredDevices = [NSMutableArray array];
}

// 扫描并连接
- (void)scanAndConnect {
    [[WPBluetoothManager sharedInstance] startScanning:YES];
}

// 发现设备
- (void)didDiscoverPeripheral:(WPPeripheralInfo *)peripheralInfo {
    [self.discoveredDevices addObject:peripheralInfo];
}

// 连接设备 ❌ 旧版本
- (void)connectToDevice:(WPPeripheralInfo *)info {
    [[WPBluetoothManager sharedInstance] connectToPeripheral:info.peripheral];
}

// 连接成功 ❌ 旧版本
- (void)didConnectPeripheral:(CBPeripheral *)peripheral {
    // 需要手动查找 WPPeripheralInfo
    WPPeripheralInfo *info = nil;
    for (WPPeripheralInfo *item in self.discoveredDevices) {
        if ([item.peripheral.identifier isEqual:peripheral.identifier]) {
            info = item;
            break;
        }
    }

    if (info) {
        WPBluetoothWatchDevice *device = [[WPBluetoothWatchDevice alloc] init];
        device.deviceName = peripheral.name;
        device.mac = info.macAddress;
        [WPBluetoothWatchDevice saveToSandbox:device];
    }
}

// 断开连接 ❌ 旧版本
- (void)didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"设备断开: %@", peripheral.name);
}

@end
```

---

### 迁移后代码（v2.0）

```objective-c
#import <WatchProtocolSDK/WatchProtocolSDK.h>

@interface MyViewController () <WPBluetoothManagerDelegate>
@property (nonatomic, strong) NSMutableArray<WPPeripheralInfo *> *discoveredDevices;
@end

@implementation MyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [WPBluetoothManager sharedInstance].delegate = self;
    self.discoveredDevices = [NSMutableArray array];
}

// 扫描并连接（无需修改）
- (void)scanAndConnect {
    [[WPBluetoothManager sharedInstance] startScanning:YES];
}

// 发现设备（无需修改）
- (void)didDiscoverPeripheral:(WPPeripheralInfo *)peripheralInfo {
    [self.discoveredDevices addObject:peripheralInfo];
}

// 连接设备 ✅ 新版本 - 直接传 WPPeripheralInfo
- (void)connectToDevice:(WPPeripheralInfo *)info {
    [[WPBluetoothManager sharedInstance] connectToPeripheral:info];
}

// 连接成功 ✅ 新版本 - 直接接收 WPPeripheralInfo
- (void)didConnectPeripheral:(WPPeripheralInfo *)peripheralInfo {
    // 无需手动查找，直接使用
    WPBluetoothWatchDevice *device = [WPBluetoothWatchDevice deviceFromPeripheralInfo:peripheralInfo];
    [WPBluetoothWatchDevice saveToSandbox:device];
}

// 断开连接 ✅ 新版本 - 直接接收 WPPeripheralInfo
- (void)didDisconnectPeripheral:(WPPeripheralInfo *)peripheralInfo error:(NSError *)error {
    NSLog(@"设备断开: %@ [%@]",
          peripheralInfo.peripheral.name,
          peripheralInfo.macAddress);
}

@end
```

---

## 迁移检查清单

使用以下清单确保迁移完整：

- [ ] 更新 SDK 版本到 v2.0.0
- [ ] 修改所有 `didConnectPeripheral:` 方法的参数类型
- [ ] 修改所有 `didDisconnectPeripheral:error:` 方法的参数类型
- [ ] 修改所有 `connectToPeripheral:` 调用的参数
- [ ] 清理构建并重新编译
- [ ] 测试蓝牙扫描功能
- [ ] 测试蓝牙连接功能
- [ ] 测试蓝牙断开功能
- [ ] 测试设备保存功能
- [ ] 运行完整的回归测试

---

## 需要帮助？

如果在迁移过程中遇到问题：

1. **查看示例代码**：`WatchProtocolSDK-ObjC/Examples/ExampleViewController.m`
2. **阅读 API 文档**：`WatchProtocolSDK-ObjC/README.md`
3. **联系技术支持**：提交 Issue 或发送邮件

---

## 总结

v2.0 迁移虽然是破坏性更新，但带来了更统一、更易用的 API 设计。只需要修改少量代码即可完成迁移，并能享受到更好的开发体验。

**推荐迁移！** 🚀

---

最后更新：2026-01-19
