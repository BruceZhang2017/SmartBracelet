# WatchProtocolSDK-ObjC 设备列表读取问题分析

## 问题描述

第三方 App 使用 WatchProtocolSDK-ObjC 库后，反馈搜索设备后，读取 `cacheDevices` 返回都是 0 个设备数据。

## 问题根本原因

这是一个**概念混淆**导致的错误用法。`cacheDevices` 和 `discoveredPeripherals` 是**两个完全不同的设备列表**：

### 1️⃣ discoveredPeripherals（扫描设备列表）

- **用途**: 存储扫描时**实时发现**的设备
- **数据类型**: `NSArray<WPPeripheralInfo *>`
- **数据来源**: 蓝牙扫描
- **生命周期**: 临时的，停止扫描后可能清空
- **文件位置**: `WatchProtocolSDK-ObjC/Core/WPBluetoothManager.h:78`

```objective-c
// ✅ 扫描后正确读取设备列表
NSArray<WPPeripheralInfo *> *devices = [WPBluetoothManager sharedInstance].discoveredPeripherals;
```

### 2️⃣ cacheDevices（设备缓存列表）

- **用途**: 存储**已连接过并保存**的设备历史
- **数据类型**: `NSArray<WPBluetoothWatchDevice *>`
- **数据来源**:
  - 从 UserDefaults 加载（键名: `"xgzt"`）
  - 手动调用 `addDevice:` 添加
- **生命周期**: 持久化的，重启 App 后依然存在
- **文件位置**: `WatchProtocolSDK-ObjC/Core/WPDeviceManager.h:33`

## 数据流程分析

```
扫描设备流程：
┌─────────────┐
│ 开始扫描     │
└──────┬──────┘
       │
       ▼
┌─────────────────────────┐
│ 发现设备（BLE回调）      │
└──────┬──────────────────┘
       │
       ▼
┌──────────────────────────────────┐
│ 添加到 discoveredPeripherals ✅   │  ← 第三方App应该从这里读取
└──────────────────────────────────┘
       │
       ▼
┌────────────────────────────┐
│ 是否自动添加到 cacheDevices? │
└──────┬─────────────────────┘
       │
       ▼
      ❌ NO! 不会自动添加
       │
       │（需要手动操作）
       ▼
┌─────────────────────────┐
│ 1. 连接设备成功          │
│ 2. 保存到 UserDefaults   │  ← saveToSandbox:
│ 3. 重新加载缓存          │  ← reloadDevices
└──────┬──────────────────┘
       │
       ▼
┌──────────────────────────┐
│ cacheDevices 才有数据 ✅  │
└──────────────────────────┘
```

## 核心代码分析

### discoveredPeripherals 的实现

**文件**: `WatchProtocolSDK-ObjC/Core/WPBluetoothManager.m:94-96`

```objective-c
- (NSArray<WPPeripheralInfo *> *)discoveredPeripherals {
    return [self.mutableDiscoveredPeripherals copy];
}
```

该属性返回扫描过程中实时发现的设备列表。

### cacheDevices 的实现

**文件**: `WatchProtocolSDK-ObjC/Core/WPDeviceManager.m:69-74`

```objective-c
- (NSArray<WPBluetoothWatchDevice *> *)cacheDevices {
    [self.deviceCacheLock lock];
    NSArray *result = [self.mutableCacheDevices copy];
    [self.deviceCacheLock unlock];
    return result;
}
```

### cacheDevices 的数据加载

**文件**: `WatchProtocolSDK-ObjC/Core/WPDeviceManager.m:154-189`

```objective-c
- (void)reloadDevices {
    [self.deviceCacheLock lock];

    [self.mutableCacheDevices removeAllObjects];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *dic = [defaults dictionaryForKey:@"xgzt"];

    if (!dic || dic.count == 0) {
        [self.deviceCacheLock unlock];
        return;  // ← 如果没有持久化数据，直接返回空数组
    }

    // ... 从 UserDefaults 加载设备
}
```

**关键点**: `cacheDevices` 只从 UserDefaults 加载数据，不会包含刚扫描到的设备。

### 设备保存到缓存的流程

**文件**: `WatchProtocolSDK-ObjC/Models/WPDeviceModel.m:113-147`

```objective-c
+ (void)saveToSandbox:(WPBluetoothWatchDevice *)device {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // 安全检查
    if (!device.mac || device.mac.length == 0) {
        return;
    }

    if (!device.deviceName || device.deviceName.length == 0) {
        return;
    }

    NSMutableDictionary *dic = [[defaults dictionaryForKey:@"xgzt"] mutableCopy];
    if (!dic) {
        dic = [NSMutableDictionary dictionary];
    }

    // 存储设备
    dic[device.mac] = device.deviceName;
    [defaults setObject:dic forKey:@"xgzt"];
    [defaults synchronize];

    // 重新加载设备列表
    [WPBluetoothWatchDevice loadAll];
}
```

**关键点**: 必须手动调用 `saveToSandbox:` 才会将设备保存到持久化存储。

## 第三方 App 的错误用法

```objective-c
// ❌ 错误示例
[[WPBluetoothManager sharedInstance] startScanning:YES];
// ... 等待扫描 ...
[[WPBluetoothManager sharedInstance] stopScanning];

// 错误：尝试从 cacheDevices 读取扫描结果
NSArray *devices = [WPDeviceManager sharedInstance].cacheDevices;
// 返回 0 个，因为 cacheDevices 只存储"已连接过并保存的设备"
```

**为什么返回 0 个设备？**

1. 扫描只会填充 `discoveredPeripherals`，不会填充 `cacheDevices`
2. `cacheDevices` 只从 UserDefaults（键名 `"xgzt"`）加载数据
3. 如果之前从未连接过设备并调用 `saveToSandbox:`，UserDefaults 中没有数据
4. 因此 `cacheDevices` 返回空数组

## 正确的解决方案

### ✅ 方案1: 读取扫描到的设备（推荐）

#### 方式 A: 通过属性读取（扫描结束后）

```objective-c
- (void)scanDevices {
    // 1. 开始扫描
    [[WPBluetoothManager sharedInstance] startScanning:YES];

    // 2. 等待扫描完成（或手动停止）
    // ...

    // 3. 读取扫描结果
    NSArray<WPPeripheralInfo *> *devices = [WPBluetoothManager sharedInstance].discoveredPeripherals;
    NSLog(@"发现 %ld 个设备", devices.count);

    // 4. 遍历设备
    for (WPPeripheralInfo *info in devices) {
        NSString *deviceName = info.peripheral.name ?: @"未知设备";
        NSLog(@"设备: %@ [%@]", deviceName, info.macAddress);
    }
}
```

#### 方式 B: 通过代理实时接收（推荐）

```objective-c
@interface MyViewController () <WPBluetoothManagerDelegate>
@property (nonatomic, strong) NSMutableArray<WPPeripheralInfo *> *discoveredDevices;
@end

@implementation MyViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // 1. 设置代理
    [WPBluetoothManager sharedInstance].delegate = self;

    // 2. 初始化设备列表
    self.discoveredDevices = [NSMutableArray array];
}

- (void)startScan {
    // 清空列表
    [self.discoveredDevices removeAllObjects];

    // 开始扫描
    [[WPBluetoothManager sharedInstance] startScanning:YES];
}

// 代理方法：实时接收发现的设备
- (void)didDiscoverPeripheral:(WPPeripheralInfo *)peripheralInfo {
    dispatch_async(dispatch_get_main_queue(), ^{
        // 检查是否已存在（避免重复）
        BOOL exists = NO;
        for (WPPeripheralInfo *info in self.discoveredDevices) {
            if ([info.peripheral.identifier isEqual:peripheralInfo.peripheral.identifier]) {
                exists = YES;
                break;
            }
        }

        if (!exists) {
            [self.discoveredDevices addObject:peripheralInfo];
            NSLog(@"发现新设备: %@", peripheralInfo.peripheral.name);

            // 更新 UI
            [self.tableView reloadData];
        }
    });
}

@end
```

**参考示例**: `WatchProtocolSDK-ObjC/Examples/ExampleViewController.m:171-193`

### ✅ 方案2: 如果确实需要使用 cacheDevices

必须先连接设备并保存到持久化存储：

```objective-c
// 步骤1: 实现连接成功的代理方法
- (void)didConnectPeripheral:(CBPeripheral *)peripheral {
    // 1. 创建设备对象
    WPBluetoothWatchDevice *device = [[WPBluetoothWatchDevice alloc] init];
    device.deviceName = peripheral.name;
    device.mac = peripheral.identifier.UUIDString;

    // 2. 保存到沙盒（UserDefaults）
    [WPBluetoothWatchDevice saveToSandbox:device];

    // 3. 重新加载缓存
    [[WPDeviceManager sharedInstance] reloadDevices];

    NSLog(@"✅ 设备已保存到缓存");
}

// 步骤2: 现在可以从 cacheDevices 读取历史设备
- (void)loadCachedDevices {
    NSArray<WPBluetoothWatchDevice *> *cachedDevices = [WPDeviceManager sharedInstance].cacheDevices;
    NSLog(@"缓存设备数: %ld", cachedDevices.count);

    for (WPBluetoothWatchDevice *device in cachedDevices) {
        NSLog(@"历史设备: %@ [%@]", device.deviceName, device.mac);
    }
}

// 步骤3: 在 App 启动时加载历史设备
- (void)viewDidLoad {
    [super viewDidLoad];

    // 重新加载已保存的设备
    [[WPDeviceManager sharedInstance] reloadDevices];

    // 读取缓存的设备列表
    [self loadCachedDevices];
}
```

## 对比总结

| 对比项 | discoveredPeripherals | cacheDevices |
|--------|----------------------|--------------|
| **数据来源** | 蓝牙扫描 | UserDefaults 持久化存储 |
| **使用场景** | 获取扫描结果 | 获取已连接过的设备历史 |
| **扫描后是否有数据** | ✅ 有 | ❌ 无（除非之前连接过） |
| **数据类型** | `WPPeripheralInfo` | `WPBluetoothWatchDevice` |
| **生命周期** | 临时（重启 App 丢失） | 持久化（重启 App 保留） |
| **文件位置** | `WPBluetoothManager.h:78` | `WPDeviceManager.h:33` |
| **更新机制** | 扫描时自动填充 | 需手动调用 `saveToSandbox:` |

## 关键接口说明

### WPBluetoothManager

```objective-c
@interface WPBluetoothManager : NSObject

// 扫描到的设备列表（只读）
@property (nonatomic, strong, readonly) NSArray<WPPeripheralInfo *> *discoveredPeripherals;

// 开始扫描
- (void)startScanning:(BOOL)deleteCache;

// 停止扫描
- (void)stopScanning;

@end
```

### WPBluetoothManagerDelegate

```objective-c
@protocol WPBluetoothManagerDelegate <NSObject>

@optional

// 发现新设备时调用
- (void)didDiscoverPeripheral:(WPPeripheralInfo *)peripheralInfo;

// 连接成功时调用
- (void)didConnectPeripheral:(CBPeripheral *)peripheral;

@end
```

### WPDeviceManager

```objective-c
@interface WPDeviceManager : NSObject

// 设备缓存列表（只读）
@property (nonatomic, copy, readonly) NSArray<WPBluetoothWatchDevice *> *cacheDevices;

// 添加设备到缓存
- (void)addDevice:(WPBluetoothWatchDevice *)device;

// 重新加载设备（从 UserDefaults）
- (void)reloadDevices;

@end
```

### WPBluetoothWatchDevice

```objective-c
@interface WPBluetoothWatchDevice : NSObject

// 保存设备到沙盒（UserDefaults）
+ (void)saveToSandbox:(WPBluetoothWatchDevice *)device;

// 从沙盒加载设备
+ (nullable WPBluetoothWatchDevice *)loadFromSandboxWithMac:(NSString *)mac;

@end
```

## 最佳实践建议

### 1. 获取扫描结果 - 使用 discoveredPeripherals

```objective-c
// ✅ 正确
NSArray<WPPeripheralInfo *> *scanResults = [WPBluetoothManager sharedInstance].discoveredPeripherals;
```

```objective-c
// ❌ 错误
NSArray *scanResults = [WPDeviceManager sharedInstance].cacheDevices;
```

### 2. 保存设备历史 - 连接成功后调用 saveToSandbox:

```objective-c
- (void)didConnectPeripheral:(CBPeripheral *)peripheral {
    WPBluetoothWatchDevice *device = [[WPBluetoothWatchDevice alloc] init];
    device.deviceName = peripheral.name;
    device.mac = peripheral.identifier.UUIDString;

    // ✅ 保存到持久化存储
    [WPBluetoothWatchDevice saveToSandbox:device];
}
```

### 3. 读取设备历史 - 使用 cacheDevices

```objective-c
- (void)loadHistory {
    // 先重新加载
    [[WPDeviceManager sharedInstance] reloadDevices];

    // 再读取
    NSArray<WPBluetoothWatchDevice *> *history = [WPDeviceManager sharedInstance].cacheDevices;
}
```

## 常见问题 FAQ

### Q1: 为什么扫描后 cacheDevices 是空的？

**A**: 因为 `cacheDevices` 不是用来存储扫描结果的，它只存储已连接过并手动保存的设备。扫描结果应该从 `discoveredPeripherals` 读取。

### Q2: 如何让扫描到的设备出现在 cacheDevices 中？

**A**: 必须执行以下步骤：
1. 连接设备
2. 调用 `[WPBluetoothWatchDevice saveToSandbox:device]`
3. 调用 `[[WPDeviceManager sharedInstance] reloadDevices]`

### Q3: discoveredPeripherals 和 cacheDevices 有什么区别？

**A**:
- `discoveredPeripherals`: 扫描结果（临时）
- `cacheDevices`: 连接历史（持久化）

### Q4: 第三方 App 应该使用哪个？

**A**: 根据需求选择：
- 显示扫描结果 → 使用 `discoveredPeripherals`
- 显示历史设备 → 使用 `cacheDevices`

## 文档版本

- **创建日期**: 2026-01-15
- **SDK 版本**: WatchProtocolSDK-ObjC v1.0.x
- **适用场景**: 第三方 App 集成 WatchProtocolSDK-ObjC

## 相关文件

- `WatchProtocolSDK-ObjC/Core/WPBluetoothManager.h` - 蓝牙管理器头文件
- `WatchProtocolSDK-ObjC/Core/WPBluetoothManager.m` - 蓝牙管理器实现
- `WatchProtocolSDK-ObjC/Core/WPDeviceManager.h` - 设备管理器头文件
- `WatchProtocolSDK-ObjC/Core/WPDeviceManager.m` - 设备管理器实现
- `WatchProtocolSDK-ObjC/Models/WPDeviceModel.h` - 设备模型头文件
- `WatchProtocolSDK-ObjC/Models/WPDeviceModel.m` - 设备模型实现
- `WatchProtocolSDK-ObjC/Examples/ExampleViewController.m` - 使用示例
