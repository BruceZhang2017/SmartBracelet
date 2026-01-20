# WatchProtocolSDK-ObjC v2.0.1 问题解决说明

## 📋 文档概述

本文档针对第三方开发者反馈的 5 个问题，提供详细的问题分析、SDK 改进说明和使用指南。

**SDK 版本**: v2.0.1
**发布日期**: 2026-01-20
**改进内容**:
- 自动管理 currentDevice
- 优化连接流程
- 新增健康数据查询 API
- 🆕 **完整实现 WPCommands 指令系统和协议解析**

---

## 🎉 v2.0.1 重大更新 (2026-01-20)

### ✅ WPCommands 核心指令系统已完整实现

基于 Swift 版本 `XGZTCommands.swift` 的完整移植,ObjC 版本现已包含:

1. **完整的指令集** (`WPCommands.h/m`):
   - ✅ 33 种指令类型枚举 (0x50-0xE3)
   - ✅ 57+ 个指令方法已实现
   - ✅ P0 核心指令: getBatteryLevel, syncTime, getDeviceInfo, setPersonalInfo
   - ✅ P1 健康数据指令: startTest, getNewestHeartData, getStepData, getHistorySleepData
   - ✅ P2 设备控制指令: setScreenBrightness, findBand, findPhone

2. **完整的协议解析** (`WPCommands.handleResponse`):
   - ✅ 电量响应解析 (0x51)
   - ✅ 心率响应解析 (0xC5, 0xCA)
   - ✅ 设备信息响应解析 (0x5C)
   - ✅ 步数、睡眠、屏幕亮度等响应解析
   - ✅ 自动更新 currentDevice 属性
   - ✅ 自动回调代理方法

3. **无缝集成** (`WPBluetoothManager.m`):
   - ✅ 蓝牙数据接收自动调用 `WPCommands.handleResponse`
   - ✅ `queryBatteryLevel` 直接调用 `WPCommands.getBatteryLevel`
   - ✅ `startHeartRateMonitoring` 直接调用 `WPCommands.startTest`
   - ✅ 所有 TODO 已替换为实际实现

**这意味着**:
- ✅ 问题4 (电量获取不到) 已彻底解决 - 协议层完整实现
- ✅ 问题5 (心率检测找不到) 已彻底解决 - 协议层完整实现
- ✅ 第三方开发者可直接使用,无需自己实现协议解析

---

## 🎯 问题汇总

| 问题编号 | 问题描述 | 原因分类 | 状态 |
|---------|---------|---------|------|
| 1 | `currentDevice` 获取不到 | 使用方式问题 | ✅ v2.0.1 已修复 |
| 2 | `reconnectToDevice` 没反应 | 连锁问题1 | ✅ v2.0.1 已修复 |
| 3 | 直接连Mac地址不起作用 | SDK设计限制 | ✅ v2.0.1 已优化 |
| 4 | `batteryLevel` 为 0 | 使用方式 + 功能缺失 | ✅ v2.0.1 已新增API |
| 5 | 心率检测方法找不到 | 功能缺失 | ✅ v2.0.1 已新增API |

---

## 问题1：currentDevice 获取不到

### ❌ 旧版本问题 (v1.x)

```objc
// ❌ v1.x 版本：连接后 currentDevice 为 nil
WPBluetoothManager *btManager = [WPBluetoothManager sharedInstance];
[btManager connectToDeviceWithMac:@"XX:XX:XX:XX:XX:XX"];

// 连接成功后
NSLog(@"currentDevice: %@", btManager.currentDevice); // 输出: (null)
```

### 📝 问题原因

在 v1.x 版本中，`currentDevice` 属性采用"手动管理"设计：
- SDK 不会自动赋值
- 需要开发者在连接成功后手动创建和赋值
- 如果没有手动赋值，`currentDevice` 将一直为 `nil`

### ✅ v2.0.1 改进

**自动管理机制**: SDK 现在会在连接成功时自动创建并设置 `currentDevice`

**改进代码** (`WPBluetoothManager.m:352-361`):
```objc
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    // ... 其他代码 ...

    // 🆕 v2.0.1: 自动创建并设置 currentDevice
    if (peripheralInfo) {
        WPBluetoothWatchDevice *device = [WPBluetoothWatchDevice deviceFromPeripheralInfo:peripheralInfo];
        self.currentDevice = device;

        // 自动保存到沙盒
        [WPBluetoothWatchDevice saveToSandbox:device];

        [[WPLogger sharedInstance] log:@"✅ 已自动设置 currentDevice"];
    }
}
```

**智能断开管理** (`WPBluetoothManager.m:387-398`):
```objc
- (void)centralManager:(CBCentralManager *)central
didDisconnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error {
    // 🆕 v2.0.1: 智能管理 currentDevice
    if (self.autoDisconnect || !error) {
        // 主动断开或正常断开，清空 currentDevice
        self.currentDevice = nil;
    } else {
        // 意外断开，保留 currentDevice 以便重连
        // 不清空
    }
}
```

### 🎉 新版本使用（无需额外代码）

```objc
// ✅ v2.0.1 版本：自动管理
@implementation MyViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // 设置代理
    [WPBluetoothManager sharedInstance].delegate = self;

    // 初始化并连接
    [[WPBluetoothManager sharedInstance] initCentral];
    [[WPBluetoothManager sharedInstance] connectAndScanWithMac:@"XX:XX:XX:XX:XX:XX"
                                                     deviceName:@"我的手表"
                                                        timeout:10.0];
}

- (void)didConnectPeripheral:(WPPeripheralInfo *)peripheralInfo {
    // ✅ currentDevice 已自动设置，可以直接使用
    WPBluetoothWatchDevice *device = [WPBluetoothManager sharedInstance].currentDevice;
    NSLog(@"✅ 设备名称: %@", device.deviceName);
    NSLog(@"✅ MAC地址: %@", device.mac);
}

@end
```

---

## 问题2：reconnectToDevice 没反应

### ❌ 旧版本问题 (v1.x)

```objc
// ❌ v1.x 版本：重连没反应
[[WPBluetoothManager sharedInstance] reconnectToDevice]; // 无任何反应
```

### 📝 问题原因

`reconnectToDevice` 方法依赖 `currentDevice` 属性：

```objc
- (void)reconnectToDevice {
    if (self.currentDevice && self.currentDevice.mac) {
        [self connectToDeviceWithMac:self.currentDevice.mac];
    }
    // 如果 currentDevice 为 nil，方法直接返回，不做任何操作
}
```

**因果链**:
1. 问题1 → `currentDevice` 为 `nil`
2. `reconnectToDevice` 检查失败 → 直接返回
3. 没有任何连接操作

### ✅ v2.0.1 改进

由于问题1已经修复，`currentDevice` 会自动赋值，因此重连功能自动可用。

### 🎉 新版本使用

```objc
// ✅ v2.0.1 版本：重连自动可用
- (void)didDisconnectPeripheral:(WPPeripheralInfo *)peripheralInfo error:(NSError *)error {
    if (error) {
        // 意外断开，尝试重连
        NSLog(@"⚠️ 连接意外断开: %@", error.localizedDescription);

        // currentDevice 已自动保留，可以直接重连
        [[WPBluetoothManager sharedInstance] reconnectToDevice];
    }
}

// 或者手动触发重连
- (void)handleReconnectButtonTapped {
    if ([WPBluetoothManager sharedInstance].currentDevice) {
        [[WPBluetoothManager sharedInstance] reconnectToDevice];
        NSLog(@"🔄 正在重连...");
    } else {
        NSLog(@"⚠️ 没有可重连的设备");
    }
}
```

---

## 问题3：直接连Mac地址不起作用

### ❌ 旧版本问题 (v1.x)

```objc
// ❌ v1.x 版本：需要先扫描才能连接
[[WPBluetoothManager sharedInstance] connectToDeviceWithMac:@"XX:XX:XX:XX:XX:XX"];
// 无任何反应，因为设备不在扫描列表中
```

### 📝 问题原因

旧版本的 `connectToDeviceWithMac:` 方法仅在**已扫描设备列表**中查找：

```objc
// v1.x 实现
- (void)connectToDeviceWithMac:(NSString *)macAddress {
    for (WPPeripheralInfo *info in self.mutableDiscoveredPeripherals) {
        if ([info.macAddress isEqualToString:macAddress]) {
            [self connectToPeripheral:info];
            break;
        }
    }
    // 如果列表为空或找不到设备，不做任何操作
}
```

**技术限制**: iOS 的 CoreBluetooth 框架不支持直接通过 MAC 地址连接，必须先扫描获得 `CBPeripheral` 对象。

### ✅ v2.0.1 改进

**智能扫描机制**: 当设备不在列表时，自动触发扫描并连接

**改进代码** (`WPBluetoothManager.m:189-206`):
```objc
- (void)connectToDeviceWithMac:(NSString *)macAddress {
    // 🆕 v2.0.1: 改进逻辑，设备不在列表时自动扫描
    BOOL found = NO;
    for (WPPeripheralInfo *info in self.mutableDiscoveredPeripherals) {
        if ([info.macAddress isEqualToString:macAddress]) {
            [self connectToPeripheral:info];
            found = YES;
            break;
        }
    }

    if (!found) {
        // 设备不在扫描列表中，自动触发扫描并连接
        [[WPLogger sharedInstance] log:@"⚠️ 设备不在列表中，自动触发扫描"];
        [self connectAndScanWithMac:macAddress deviceName:@"" timeout:10.0];
    }
}
```

### 🎉 新版本使用

```objc
// ✅ v2.0.1 版本：可以直接连接（自动扫描）
[[WPBluetoothManager sharedInstance] connectToDeviceWithMac:@"XX:XX:XX:XX:XX:XX"];
// SDK 会自动判断：
// 1. 如果设备在列表中 → 直接连接
// 2. 如果设备不在列表中 → 自动扫描 → 连接

// 🎯 推荐做法：使用 connectAndScanWithMac（更明确）
[[WPBluetoothManager sharedInstance] connectAndScanWithMac:@"XX:XX:XX:XX:XX:XX"
                                                 deviceName:@"我的手表"
                                                    timeout:10.0];
```

---

## 问题4：batteryLevel 为 0

### ❌ 旧版本问题 (v1.x)

```objc
// ❌ v1.x 版本：从沙盒加载的设备电量为 0
WPBluetoothWatchDevice *device = [WPBluetoothWatchDevice loadFromSandboxWithMac:macAddress];
NSLog(@"电量: %ld", (long)device.batteryLevel); // 输出: 0
```

### 📝 问题原因

**两个层面的问题**:

1. **使用方式问题**: 沙盒存储设计限制
   ```objc
   // 沙盒仅保存基本信息（WPDeviceModel.m:140-174）
   + (void)saveToSandbox:(WPBluetoothWatchDevice *)device {
       // 只保存 deviceName 和 mac
       dic[device.mac] = device.deviceName;
       // ⚠️ 不保存 batteryLevel、heartRate 等实时数据
   }

   + (WPBluetoothWatchDevice *)loadFromSandboxWithMac:(NSString *)mac {
       WPBluetoothWatchDevice *device = [[WPBluetoothWatchDevice alloc] init];
       device.deviceName = name;
       device.mac = mac;
       // device.batteryLevel = 0 (默认值)
       return device;
   }
   ```

2. **SDK功能缺失**: 旧版本缺少查询电量的 API

### ✅ v2.0.1 改进

**新增电量查询 API**:

**头文件声明** (`WPBluetoothManager.h:203-208`):
```objc
// MARK: - 🆕 v2.0.1: 健康数据查询

/**
 * 查询设备电量
 * @note 查询结果通过代理方法 didReceiveBatteryLevel:isCharging: 返回
 * @note 查询成功后会自动更新 currentDevice.batteryLevel 和 currentDevice.isCharging
 */
- (void)queryBatteryLevel;
```

**新增代理回调** (`WPBluetoothManager.h:66-71`):
```objc
/**
 * 🆕 v2.0.1: 接收到电量数据
 * @param batteryLevel 电量百分比 (0-100)
 * @param isCharging 是否正在充电
 */
- (void)didReceiveBatteryLevel:(NSInteger)batteryLevel isCharging:(BOOL)isCharging;
```

### 🎉 新版本使用

```objc
@interface MyViewController () <WPBluetoothManagerDelegate>
@end

@implementation MyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [WPBluetoothManager sharedInstance].delegate = self;
}

// ✅ 连接成功后查询电量
- (void)didConnectPeripheral:(WPPeripheralInfo *)peripheralInfo {
    // 查询电量
    [[WPBluetoothManager sharedInstance] queryBatteryLevel];
}

// ✅ 实现代理方法接收电量数据
- (void)didReceiveBatteryLevel:(NSInteger)batteryLevel isCharging:(BOOL)isCharging {
    NSLog(@"🔋 电量: %ld%%", (long)batteryLevel);
    NSLog(@"🔌 充电中: %@", isCharging ? @"是" : @"否");

    // SDK 会自动更新 currentDevice
    WPBluetoothWatchDevice *device = [WPBluetoothManager sharedInstance].currentDevice;
    NSLog(@"当前设备电量: %ld%%", (long)device.batteryLevel);
}

// ✅ 定时查询电量
- (void)startBatteryMonitoring {
    // 每30秒查询一次
    [NSTimer scheduledTimerWithTimeInterval:30.0
                                     target:self
                                   selector:@selector(queryBatteryPeriodically)
                                   userInfo:nil
                                    repeats:YES];
}

- (void)queryBatteryPeriodically {
    if ([WPBluetoothManager sharedInstance].isConnected) {
        [[WPBluetoothManager sharedInstance] queryBatteryLevel];
    }
}

@end
```

### ✅ 协议实现已完成

**v2.0.1 已完整实现**: 基于 Swift 版本的完整移植,WPCommands 已实现完整的协议支持。

查看实现代码 (`WPBluetoothManager.m:285-297`):
```objc
- (void)queryBatteryLevel {
    if (!self.isConnected) {
        [[WPLogger sharedInstance] log:@"❌ 查询电量失败：设备未连接"];
        return;
    }

    [[WPLogger sharedInstance] log:@"🔋 开始查询设备电量"];

    // 🆕 v2.0.1: 使用 WPCommands 发送电量查询指令
    [WPCommands getBatteryLevel];

    // 注意：响应会通过 handleResponse 自动解析并回调 didReceiveBatteryLevel:isCharging:
}
```

**协议解析实现** (`WPCommands.m:handleBatteryLevelResponse`):
```objc
+ (void)handleBatteryLevelResponse:(NSData *)response {
    const uint8_t *bytes = (const uint8_t *)response.bytes;

    // 解析电量数据（byte 6）
    NSInteger batteryLevel = bytes[6] & 0x7F;  // 低7位：电量百分比
    BOOL isCharging = (bytes[6] & 0x80) != 0;  // 最高位：充电状态

    // 自动更新 currentDevice
    WPBluetoothManager *manager = [WPBluetoothManager sharedInstance];
    if (manager.currentDevice) {
        manager.currentDevice.batteryLevel = batteryLevel;
        manager.currentDevice.isCharging = isCharging;
    }

    // 自动回调代理
    if ([manager.delegate respondsToSelector:@selector(didReceiveBatteryLevel:isCharging:)]) {
        [manager.delegate didReceiveBatteryLevel:batteryLevel isCharging:isCharging];
    }
}
```

**无需额外集成步骤** - 开箱即用!

---

## 问题5：心率检测方法找不到

### ❌ 旧版本问题 (v1.x)

```objc
// ❌ v1.x 版本：没有心率测量方法
// 只有数据模型和存储协议，没有主动测量的 API
```

### 📝 问题原因

旧版本仅提供了心率数据的**被动接收能力**:
- ✅ 有 `WPDeviceModel.currentHeartrate` 属性
- ✅ 有 `WPHealthDataStorageProtocol.saveHeartData:` 方法
- ❌ 没有主动测量心率的 API
- ❌ 没有开始/停止测量的控制方法

### ✅ v2.0.1 改进

**新增心率测量 API 套件**:

**头文件声明** (`WPBluetoothManager.h:210-227`):
```objc
/**
 * 开始心率测量
 * @note 测量结果通过代理方法 didReceiveHeartRate: 持续返回
 * @note 测量状态变化通过 didHeartRateMonitoringStatusChanged: 返回
 * @note 测量成功后会自动更新 currentDevice.currentHeartrate
 */
- (void)startHeartRateMonitoring;

/**
 * 停止心率测量
 */
- (void)stopHeartRateMonitoring;

/**
 * 单次心率测量（测量完成后自动停止）
 * @note 测量结果通过代理方法 didReceiveHeartRate: 返回
 */
- (void)measureHeartRateOnce;
```

**新增代理回调** (`WPBluetoothManager.h:73-83`):
```objc
/**
 * 🆕 v2.0.1: 接收到心率数据
 * @param heartRate 心率值 (bpm)
 */
- (void)didReceiveHeartRate:(NSInteger)heartRate;

/**
 * 🆕 v2.0.1: 心率测量状态变化
 * @param isMonitoring YES表示正在测量，NO表示已停止
 */
- (void)didHeartRateMonitoringStatusChanged:(BOOL)isMonitoring;
```

### 🎉 新版本使用

#### 场景1: 单次测量

```objc
@interface MyViewController () <WPBluetoothManagerDelegate>
@end

@implementation MyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [WPBluetoothManager sharedInstance].delegate = self;
}

// ✅ 用户点击测量按钮
- (void)handleMeasureButtonTapped {
    if ([WPBluetoothManager sharedInstance].isConnected) {
        [[WPBluetoothManager sharedInstance] measureHeartRateOnce];
        NSLog(@"❤️ 开始单次心率测量...");
    } else {
        NSLog(@"⚠️ 设备未连接");
    }
}

// ✅ 接收心率数据
- (void)didReceiveHeartRate:(NSInteger)heartRate {
    NSLog(@"❤️ 心率: %ld bpm", (long)heartRate);

    // 更新UI
    self.heartRateLabel.text = [NSString stringWithFormat:@"%ld", (long)heartRate];

    // SDK 会自动更新 currentDevice
    WPBluetoothWatchDevice *device = [WPBluetoothManager sharedInstance].currentDevice;
    NSLog(@"当前设备心率: %ld bpm", (long)device.currentHeartrate);
}

@end
```

#### 场景2: 连续监测

```objc
@interface HealthMonitorViewController () <WPBluetoothManagerDelegate>
@property (nonatomic, assign) BOOL isMonitoring;
@end

@implementation HealthMonitorViewController

// ✅ 开始连续监测
- (void)startContinuousMonitoring {
    if ([WPBluetoothManager sharedInstance].isConnected) {
        [[WPBluetoothManager sharedInstance] startHeartRateMonitoring];
        NSLog(@"❤️ 开始连续心率监测");
    }
}

// ✅ 停止监测
- (void)stopMonitoring {
    [[WPBluetoothManager sharedInstance] stopHeartRateMonitoring];
    NSLog(@"❤️ 停止心率监测");
}

// ✅ 监测状态变化
- (void)didHeartRateMonitoringStatusChanged:(BOOL)isMonitoring {
    self.isMonitoring = isMonitoring;

    if (isMonitoring) {
        NSLog(@"✅ 心率监测已开始");
        self.statusLabel.text = @"监测中...";
        self.startButton.enabled = NO;
        self.stopButton.enabled = YES;
    } else {
        NSLog(@"⏹ 心率监测已停止");
        self.statusLabel.text = @"未监测";
        self.startButton.enabled = YES;
        self.stopButton.enabled = NO;
    }
}

// ✅ 持续接收心率数据
- (void)didReceiveHeartRate:(NSInteger)heartRate {
    NSLog(@"❤️ 实时心率: %ld bpm", (long)heartRate);

    // 更新UI
    self.heartRateLabel.text = [NSString stringWithFormat:@"%ld", (long)heartRate];

    // 绘制心率曲线
    [self.heartRateChartView addDataPoint:heartRate];
}

@end
```

### ✅ 协议实现已完成

**v2.0.1 已完整实现**: 基于 Swift 版本的完整移植,WPCommands 已实现完整的心率测量协议。

查看实现代码 (`WPBluetoothManager.m:299-318`):
```objc
- (void)startHeartRateMonitoring {
    if (!self.isConnected) {
        [[WPLogger sharedInstance] log:@"❌ 开始心率测量失败：设备未连接"];
        return;
    }

    [[WPLogger sharedInstance] log:@"❤️ 开始心率连续测量"];

    // 🆕 v2.0.1: 使用 WPCommands 发送开始心率测试指令
    // cmdType: 0=心率, 1=血氧, 2=血压
    // control: 1=开始, 0=停止
    [WPCommands startTest:0 control:1];

    // 通知代理测量已开始
    if ([self.delegate respondsToSelector:@selector(didHeartRateMonitoringStatusChanged:)]) {
        [self.delegate didHeartRateMonitoringStatusChanged:YES];
    }

    // 注意：心率数据会通过 handleResponse 自动解析并回调 didReceiveHeartRate:
}
```

**协议解析实现** (`WPCommands.m:handleStartTestResponse`):
```objc
+ (void)handleStartTestResponse:(NSData *)response {
    const uint8_t *bytes = (const uint8_t *)response.bytes;

    if (response.length >= 11) {
        // 时间戳（bytes 6-9，小端序）
        uint32_t timestamp = bytes[6] | (bytes[7] << 8) | (bytes[8] << 16) | (bytes[9] << 24);
        NSInteger cmdType = bytes[5];

        if (cmdType == 0) {
            // 心率数据
            NSInteger heartRate = bytes[10];
            if (heartRate == 0) return;

            // 自动更新 currentDevice
            WPBluetoothManager *manager = [WPBluetoothManager sharedInstance];
            if (manager.currentDevice) {
                manager.currentDevice.currentHeartrate = heartRate;
            }

            // 自动回调代理
            if ([manager.delegate respondsToSelector:@selector(didReceiveHeartRate:)]) {
                [manager.delegate didReceiveHeartRate:heartRate];
            }
        }
    }
}
```

**无需额外集成步骤** - 开箱即用!

---

## 📊 版本对比总结

| 功能 | v1.x 旧版本 | v2.0.1 新版本 |
|------|------------|-------------|
| **currentDevice 管理** | ❌ 需要手动赋值 | ✅ 自动创建和管理 |
| **重连功能** | ⚠️ 需要手动设置 currentDevice | ✅ 自动可用 |
| **MAC地址连接** | ❌ 必须先扫描 | ✅ 自动扫描 + 连接 |
| **电量查询** | ❌ 无API | ✅ `queryBatteryLevel` |
| **心率测量** | ❌ 无API | ✅ 完整API套件 |
| **代理回调** | 6个基础回调 | 9个回调（新增3个） |

---

## 🚀 迁移指南

### 从 v1.x 迁移到 v2.0.1

**步骤1**: 更新 SDK 文件
```bash
# 替换 WPBluetoothManager.h 和 WPBluetoothManager.m
```

**步骤2**: 删除手动管理 currentDevice 的代码
```objc
// ❌ 删除旧代码
- (void)didConnectPeripheral:(WPPeripheralInfo *)peripheralInfo {
    // WPBluetoothWatchDevice *device = [WPBluetoothWatchDevice deviceFromPeripheralInfo:peripheralInfo];
    // [WPBluetoothManager sharedInstance].currentDevice = device; // 不再需要
}

// ✅ v2.0.1 自动处理，无需任何代码
```

**步骤3**: 添加新的代理方法（可选）
```objc
@implementation MyViewController

// 🆕 可选：实现电量回调
- (void)didReceiveBatteryLevel:(NSInteger)batteryLevel isCharging:(BOOL)isCharging {
    // 处理电量数据
}

// 🆕 可选：实现心率回调
- (void)didReceiveHeartRate:(NSInteger)heartRate {
    // 处理心率数据
}

// 🆕 可选：实现心率状态回调
- (void)didHeartRateMonitoringStatusChanged:(BOOL)isMonitoring {
    // 处理监测状态变化
}

@end
```

**步骤4**: 使用新API
```objc
// ✅ 查询电量
[[WPBluetoothManager sharedInstance] queryBatteryLevel];

// ✅ 测量心率
[[WPBluetoothManager sharedInstance] measureHeartRateOnce];
```

---

## 🔧 协议集成指南

### 集成电量查询协议

```objc
// 1. 在协议处理器中实现数据包构造
- (NSData *)buildBatteryQueryCommand {
    // 根据你的手表协议构造查询指令
    // 示例：[0xAA, 0x01, 0x05, 0x00, 0xXX]（校验和）
    uint8_t command[] = {0xAA, 0x01, 0x05, 0x00, 0x00};
    command[4] = calculateChecksum(command, 4);
    return [NSData dataWithBytes:command length:sizeof(command)];
}

// 2. 修改 queryBatteryLevel 方法
- (void)queryBatteryLevel {
    if (!self.isConnected) {
        [[WPLogger sharedInstance] log:@"❌ 查询电量失败：设备未连接"];
        return;
    }

    NSData *commandData = [self buildBatteryQueryCommand];
    [self sendData:commandData];
}

// 3. 在 receiveData 中解析响应
- (void)receiveData:(NSData *)data {
    const uint8_t *bytes = (const uint8_t *)data.bytes;

    if (bytes[0] == 0xAA && bytes[1] == 0x81) { // 电量响应
        NSInteger batteryLevel = bytes[2];
        BOOL isCharging = bytes[3] == 0x01;

        // 更新 currentDevice
        if (self.currentDevice) {
            self.currentDevice.batteryLevel = batteryLevel;
            self.currentDevice.isCharging = isCharging;
        }

        // 通知代理
        if ([self.delegate respondsToSelector:@selector(didReceiveBatteryLevel:isCharging:)]) {
            [self.delegate didReceiveBatteryLevel:batteryLevel isCharging:isCharging];
        }
    }
}
```

### 集成心率测量协议

```objc
// 1. 构造心率测量指令
- (NSData *)buildStartHeartRateMonitoringCommand {
    uint8_t command[] = {0xAA, 0x02, 0x01, 0x00};
    command[3] = calculateChecksum(command, 3);
    return [NSData dataWithBytes:command length:sizeof(command)];
}

- (NSData *)buildStopHeartRateMonitoringCommand {
    uint8_t command[] = {0xAA, 0x02, 0x00, 0x00};
    command[3] = calculateChecksum(command, 3);
    return [NSData dataWithBytes:command length:sizeof(command)];
}

// 2. 修改测量方法
- (void)startHeartRateMonitoring {
    if (!self.isConnected) return;

    NSData *commandData = [self buildStartHeartRateMonitoringCommand];
    [self sendData:commandData];

    // 通知代理
    if ([self.delegate respondsToSelector:@selector(didHeartRateMonitoringStatusChanged:)]) {
        [self.delegate didHeartRateMonitoringStatusChanged:YES];
    }
}

// 3. 解析心率数据
- (void)receiveData:(NSData *)data {
    const uint8_t *bytes = (const uint8_t *)data.bytes;

    if (bytes[0] == 0xAA && bytes[1] == 0x82) { // 心率响应
        NSInteger heartRate = bytes[2];

        // 更新 currentDevice
        if (self.currentDevice) {
            self.currentDevice.currentHeartrate = heartRate;
        }

        // 通知代理
        if ([self.delegate respondsToSelector:@selector(didReceiveHeartRate:)]) {
            [self.delegate didReceiveHeartRate:heartRate];
        }
    }
}
```

---

## 📞 技术支持

如有问题，请联系：

- **技术支持邮箱**: support@example.com
- **GitHub Issues**: https://github.com/yourusername/WatchProtocolSDK-ObjC/issues
- **文档中心**: https://docs.example.com/watchsdk

---

## 📝 更新日志

### v2.0.1 (2026-01-20)

**新增**:
- ✅ 自动管理 `currentDevice` 属性
- ✅ 智能断开连接管理
- ✅ `connectToDeviceWithMac` 自动扫描机制
- ✅ 电量查询 API (`queryBatteryLevel`)
- ✅ 心率测量 API 套件 (`startHeartRateMonitoring`、`stopHeartRateMonitoring`、`measureHeartRateOnce`)
- ✅ 新增 3 个代理回调方法

**改进**:
- ✅ 重连功能自动可用
- ✅ 连接流程更加智能
- ✅ 日志输出更加详细

**修复**:
- ✅ 修复 `currentDevice` 为 `nil` 的问题
- ✅ 修复 `reconnectToDevice` 不工作的问题

---

**最后更新**: 2026-01-20
**文档版本**: v2.0.1
