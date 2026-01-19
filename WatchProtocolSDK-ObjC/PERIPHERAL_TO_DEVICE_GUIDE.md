# WPPeripheralInfo 转 WPBluetoothWatchDevice 使用指南

## 📋 问题背景

在之前的版本中，扫描设备和保存设备使用了不同的数据类型：

- **扫描返回**: `WPPeripheralInfo *`
- **保存需要**: `WPBluetoothWatchDevice *`

这导致第三方开发者需要手动创建和转换对象，增加了使用复杂度。

## ✅ 解决方案（v1.1.0+）

我们提供了**三种便捷方法**来解决这个问题，满足不同开发者的使用习惯。

---

## 🚀 使用方法

### 方法 1：工厂方法（推荐，架构清晰）

```objective-c
#import "WPDeviceModel.h"
#import "WPBluetoothManager.h"

// 获取扫描到的设备
NSArray<WPPeripheralInfo *> *devices = [WPBluetoothManager sharedInstance].discoveredPeripherals;
WPPeripheralInfo *info = devices.firstObject;

// 使用工厂方法创建设备对象
WPBluetoothWatchDevice *device = [WPBluetoothWatchDevice deviceFromPeripheralInfo:info];

// 保存到沙盒
[WPBluetoothWatchDevice saveToSandbox:device];
```

**优点**：
- 代码清晰，架构规范
- 适合需要对设备对象进行额外处理的场景

---

### 方法 2：一步保存（推荐，最简洁）

```objective-c
#import "WPDeviceModel.h"
#import "WPBluetoothManager.h"

// 获取扫描到的设备
NSArray<WPPeripheralInfo *> *devices = [WPBluetoothManager sharedInstance].discoveredPeripherals;
WPPeripheralInfo *info = devices.firstObject;

// 直接保存到沙盒（一行代码完成）
[WPBluetoothWatchDevice savePeripheralInfoToSandbox:info];
```

**优点**：
- 最简洁，一行代码搞定
- 适合只需要保存设备的场景

---

### 方法 3：Category 便捷方法（可选，链式调用风格）

```objective-c
#import "WPBluetoothManager.h"
#import "WPPeripheralInfo+WatchDevice.h"  // 导入 Category 扩展

// 获取扫描到的设备
NSArray<WPPeripheralInfo *> *devices = [WPBluetoothManager sharedInstance].discoveredPeripherals;
WPPeripheralInfo *info = devices.firstObject;

// 方式 A：转换为设备对象
WPBluetoothWatchDevice *device = [info toWatchDevice];
[WPBluetoothWatchDevice saveToSandbox:device];

// 方式 B：直接保存（一行代码）
[info saveToSandbox];
```

**优点**：
- 链式调用风格，代码更简洁
- 符合部分开发者的使用习惯

**注意**：需要导入 `WPPeripheralInfo+WatchDevice.h`

---

## 📖 完整示例

### 示例 1：扫描并保存所有设备

```objective-c
#import "WPBluetoothManager.h"
#import "WPDeviceModel.h"

- (void)scanAndSaveAllDevices {
    // 1. 开始扫描
    [[WPBluetoothManager sharedInstance] startScanning:YES];

    // 2. 等待扫描完成（或在代理回调中处理）
    // ...

    // 3. 获取扫描结果
    NSArray<WPPeripheralInfo *> *devices = [WPBluetoothManager sharedInstance].discoveredPeripherals;

    // 4. 批量保存所有设备（方法 2 - 最简洁）
    for (WPPeripheralInfo *info in devices) {
        [WPBluetoothWatchDevice savePeripheralInfoToSandbox:info];
    }

    NSLog(@"✅ 已保存 %ld 个设备到沙盒", devices.count);
}
```

---

### 示例 2：在代理回调中保存设备

```objective-c
#import "WPBluetoothManager.h"
#import "WPDeviceModel.h"

@interface MyViewController () <WPBluetoothManagerDelegate>
@property (nonatomic, strong) NSMutableArray<WPPeripheralInfo *> *discoveredDevices;
@end

@implementation MyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [WPBluetoothManager sharedInstance].delegate = self;
    self.discoveredDevices = [NSMutableArray array];
}

// 代理方法：发现新设备时调用
- (void)didDiscoverPeripheral:(WPPeripheralInfo *)peripheralInfo {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.discoveredDevices addObject:peripheralInfo];

        // 可选：自动保存新发现的设备
        [WPBluetoothWatchDevice savePeripheralInfoToSandbox:peripheralInfo];

        NSLog(@"📱 发现并保存设备: %@", peripheralInfo.peripheral.name);
    });
}

// 代理方法：连接成功时调用
- (void)didConnectPeripheral:(CBPeripheral *)peripheral {
    dispatch_async(dispatch_get_main_queue(), ^{
        // 从已发现的设备中找到对应的 peripheralInfo
        WPPeripheralInfo *peripheralInfo = nil;
        for (WPPeripheralInfo *info in self.discoveredDevices) {
            if ([info.peripheral.identifier isEqual:peripheral.identifier]) {
                peripheralInfo = info;
                break;
            }
        }

        if (peripheralInfo) {
            // 使用工厂方法创建设备对象
            WPBluetoothWatchDevice *device = [WPBluetoothWatchDevice deviceFromPeripheralInfo:peripheralInfo];

            // 连接成功后，可以更新设备的更多信息
            device.batteryLevel = 80;  // 示例：从设备读取电量
            device.mtu = 512;          // 示例：从设备读取 MTU

            // 保存更新后的设备信息
            [WPBluetoothWatchDevice saveToSandbox:device];
        }
    });
}

@end
```

---

## 🔧 API 参考

### WPBluetoothWatchDevice 工厂方法

#### `+ (instancetype)deviceFromPeripheralInfo:(WPPeripheralInfo *)peripheralInfo`

从扫描到的外设信息创建设备对象。

**参数**：
- `peripheralInfo`: 扫描到的外设信息

**返回**：
- 设备对象（仅包含基本信息：设备名和 MAC 地址）

**注意**：
- 创建的设备对象仅包含扫描时可获取的基本信息
- 其他属性（如电量、MTU 等）需要连接设备后获取

**示例**：
```objective-c
WPBluetoothWatchDevice *device = [WPBluetoothWatchDevice deviceFromPeripheralInfo:info];
```

---

#### `+ (void)savePeripheralInfoToSandbox:(WPPeripheralInfo *)peripheralInfo`

从扫描到的外设信息创建设备对象并保存到沙盒。

**参数**：
- `peripheralInfo`: 扫描到的外设信息

**注意**：
- 这是一个便捷方法，等同于：
  ```objective-c
  WPBluetoothWatchDevice *device = [WPBluetoothWatchDevice deviceFromPeripheralInfo:peripheralInfo];
  [WPBluetoothWatchDevice saveToSandbox:device];
  ```

**示例**：
```objective-c
[WPBluetoothWatchDevice savePeripheralInfoToSandbox:info];
```

---

### WPPeripheralInfo Category 扩展（可选）

#### `- (WPBluetoothWatchDevice *)toWatchDevice`

将外设信息转换为设备对象。

**返回**：
- 设备对象（仅包含基本信息：设备名和 MAC 地址）

**注意**：
- 需要导入 `WPPeripheralInfo+WatchDevice.h`
- 内部调用 `[WPBluetoothWatchDevice deviceFromPeripheralInfo:self]`

**示例**：
```objective-c
#import "WPPeripheralInfo+WatchDevice.h"

WPBluetoothWatchDevice *device = [info toWatchDevice];
```

---

#### `- (void)saveToSandbox`

将外设信息转换为设备对象并保存到沙盒。

**注意**：
- 需要导入 `WPPeripheralInfo+WatchDevice.h`
- 内部调用 `[WPBluetoothWatchDevice savePeripheralInfoToSandbox:self]`

**示例**：
```objective-c
#import "WPPeripheralInfo+WatchDevice.h"

[info saveToSandbox];
```

---

## 💡 最佳实践

### 1. 选择合适的方法

| 场景 | 推荐方法 | 理由 |
|------|---------|------|
| 只需要保存设备 | `savePeripheralInfoToSandbox:` | 最简洁，一行代码 |
| 需要处理设备对象 | `deviceFromPeripheralInfo:` | 架构清晰，灵活 |
| 喜欢链式调用 | Category 扩展 | 代码简洁，风格统一 |

---

### 2. 连接成功后更新设备信息

```objective-c
- (void)didConnectPeripheral:(CBPeripheral *)peripheral {
    // 1. 从 peripheralInfo 创建设备对象
    WPBluetoothWatchDevice *device = [WPBluetoothWatchDevice deviceFromPeripheralInfo:peripheralInfo];

    // 2. 连接成功后，更新更多设备信息
    device.batteryLevel = [self readBatteryLevel];
    device.mtu = [self readMTU];
    device.firmwareVersion = [self readFirmwareVersion];

    // 3. 保存完整的设备信息
    [WPBluetoothWatchDevice saveToSandbox:device];
}
```

---

### 3. 避免重复保存

```objective-c
// 在保存前检查设备是否已存在
WPBluetoothWatchDevice *existingDevice = [WPBluetoothWatchDevice loadFromSandboxWithMac:info.macAddress];
if (!existingDevice) {
    // 设备不存在，保存新设备
    [WPBluetoothWatchDevice savePeripheralInfoToSandbox:info];
}
```

**注意**：`saveToSandbox:` 方法内部已经包含了重复检查逻辑，不会重复保存同一 MAC 地址的设备。

---

## 🔄 迁移指南

### 从旧版本迁移

**旧代码（手动创建对象）**：
```objective-c
WPPeripheralInfo *info = ...;

// ❌ 旧方式：手动创建
WPBluetoothWatchDevice *device = [[WPBluetoothWatchDevice alloc] init];
device.deviceName = info.peripheral.name;
device.mac = info.macAddress;
[WPBluetoothWatchDevice saveToSandbox:device];
```

**新代码（使用工厂方法）**：
```objective-c
WPPeripheralInfo *info = ...;

// ✅ 新方式：工厂方法
WPBluetoothWatchDevice *device = [WPBluetoothWatchDevice deviceFromPeripheralInfo:info];
[WPBluetoothWatchDevice saveToSandbox:device];

// 或者更简洁
[WPBluetoothWatchDevice savePeripheralInfoToSandbox:info];
```

---

## 📚 相关文档

- [WatchProtocolSDK-ObjC README](README.md)
- [设备列表读取问题分析](WatchProtocolSDK-ObjC设备列表读取问题分析.md)
- [API 文档](Core/WPBluetoothManager.h)

---

## ⚠️ 注意事项

1. **数据完整性**：
   - 从 `WPPeripheralInfo` 创建的设备对象仅包含基本信息（设备名、MAC 地址）
   - 其他属性（电量、MTU、固件版本等）需要连接设备后获取

2. **线程安全**：
   - 所有方法都是线程安全的
   - 建议在主线程更新 UI

3. **存储机制**：
   - 设备信息保存在 `NSUserDefaults` 中（键名：`"xgzt"`）
   - 使用 MAC 地址作为唯一标识

---

## 🐛 常见问题

### Q1: 为什么从 `WPPeripheralInfo` 创建的设备对象只有设备名和 MAC 地址？

**A**: 因为在蓝牙扫描阶段，只能获取到设备的广播信息（设备名、MAC 地址）。其他属性（如电量、MTU、固件版本等）需要连接设备后通过指令查询获取。

---

### Q2: 三种方法有什么区别？应该用哪个？

**A**:
- **工厂方法**（`deviceFromPeripheralInfo:`）：架构清晰，适合需要对设备对象进行额外处理的场景
- **一步保存**（`savePeripheralInfoToSandbox:`）：最简洁，适合只需要保存设备的场景
- **Category 扩展**（`toWatchDevice`、`saveToSandbox`）：链式调用风格，需要导入额外头文件

推荐根据个人习惯选择，功能完全相同。

---

### Q3: 我已经在用旧方式手动创建对象，需要立即迁移吗？

**A**: 不需要。旧方式依然有效，新方法只是提供了更便捷的选择。你可以：
- 保持现有代码不变
- 在新代码中使用新方法
- 渐进式重构旧代码

---

## 📝 更新日志

### v1.1.0 (2026-01-19)

**新增**：
- ✅ 添加 `deviceFromPeripheralInfo:` 工厂方法
- ✅ 添加 `savePeripheralInfoToSandbox:` 便捷方法
- ✅ 添加 `WPPeripheralInfo+WatchDevice` Category 扩展
- ✅ 更新示例代码和文档

**改进**：
- ✅ 简化了从扫描设备到保存设备的流程
- ✅ 提供了三种不同风格的 API，满足不同开发者的使用习惯

---

## 📧 技术支持

如有问题，请联系技术支持团队或提交 Issue。
