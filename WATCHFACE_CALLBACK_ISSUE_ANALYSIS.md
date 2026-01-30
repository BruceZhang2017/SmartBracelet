# 表盘传输回调处理问题分析报告

## 📋 问题概述

在使用 WatchProtocolSDK-ObjC 和 WatchFaceSDK-Pure-ObjC 进行表盘传输时，出现以下问题：

1. **未处理的指令响应：** 设备返回的 0xE0（表盘市场）和 0xB5（睡眠监测）指令响应未被处理
2. **传输卡死：** 表盘传输在发送第一包后卡死，无法继续发送后续数据包

## 🔍 问题分析

### 1. WatchProtocolSDK-ObjC 缺少响应处理

**位置：** `WatchProtocolSDK-ObjC/Core/WPCommands.m:1167-1221`

**当前实现：**
```objc
+ (void)handleResponse:(NSData *)response {
    // ...
    WPCommandType commandType = (WPCommandType)commandCode;

    switch (commandType) {
        case WPCommandTypeSyncTime:
            [self handleSyncTimeResponse:response];
            break;
        case WPCommandTypeGetBatteryLevel:
            [self handleBatteryLevelResponse:response];
            break;
        // ... 其他指令

        default:
            [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"⚠️ 未处理的指令响应:0x%02X", commandCode]];
            break;
    }
}
```

**问题：**
- ❌ 缺少 `case WPCommandTypeDialMarket (0xE0)` 的处理
- ❌ 缺少 `case WPCommandTypeGetSleepMonitoring (0xB5)` 的处理
- 结果：这些响应被归入 default 分支，仅打印警告日志

### 2. WatchFaceSDK-Pure-ObjC 依赖通知机制

**位置：** `WatchFaceSDK-Pure-ObjC/Core/WFTransferEngine.m:50-54`

**当前实现：**
```objc
- (instancetype)init {
    self = [super init];
    if (self) {
        // ...
        // 注册通知
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleDialDataSendComplete:)
                                                     name:@"XGZTCommandDialDataSendCompleteCallback"
                                                   object:nil];
    }
    return self;
}

- (void)handleDialDataSendComplete:(NSNotification *)notification {
    // 一包数据发送完成，发送下一包
    [self sendNextPacket];
}
```

**问题：**
- ❌ WFTransferEngine 等待接收 `XGZTCommandDialDataSendCompleteCallback` 通知
- ❌ 但 WatchProtocolSDK-ObjC 从未发送此通知（因为没有处理 0xE0 响应）
- 结果：传输在第一包后卡死，`sendNextPacket` 永远不会被调用

### 3. Swift 版本的实现参考

**位置：** `WatchProtocolSDK/Core/XGZTCommands.swift:1810-1843`

**Swift 版本实现：**
```swift
case .dialMarket:
    guard response.count >= 7 else {
        XLogger.shared.log("dialMarket command response error")
        return
    }
    let value = response[5]
    if value == 0 {
        // 查询响应：更新设备 MTU 和屏幕信息
        if response.count >= 10 {
            XGZTBlueToothManager.shared.device?.mtu = (Int(response[7]) << 8) | Int(response[8])
            NotificationCenter.default.post(name: Notification.Name("ClockUseViewController"), object: 4)
            NotificationCenter.default.post(name: Notification.Name("MyClockViewController"), object: 4)
        }
        // ...
    } else if value == 1 {
        // 传输配置响应
        if response[6] == 0 {
            NotificationCenter.default.post(name: Notification.Name("ClockUseViewController"), object: 5)
            NotificationCenter.default.post(name: Notification.Name("MyClockViewController"), object: 5)
        }
    } else if value == 2 {
        // 数据传输响应
        let control = response[8]
        if control == 0 {
            // 继续传输
            NotificationCenter.default.post(name: Notification.Name("ClockUseViewController"), object: 5)
            NotificationCenter.default.post(name: Notification.Name("MyClockViewController"), object: 5)
        } else if control == 1 {
            // 传输完成
            NotificationCenter.default.post(name: Notification.Name("ClockUseViewController"), object: 6)
            NotificationCenter.default.post(name: Notification.Name("MyClockViewController"), object: 6)
        }
    }
```

**观察：**
- Swift 版本发送的通知名称是 `"ClockUseViewController"` 和 `"MyClockViewController"`
- ObjC 版本期望的通知名称是 `"XGZTCommandDialDataSendCompleteCallback"`
- ❌ 通知名称不匹配

## 📊 协议数据解析

根据日志中的设备响应：

### 响应 1: 传输配置确认
```
📥 接收指令 [7 bytes]: 0A E0 02 00 02 01 00
```
- `0xE0` = dialMarket 指令
- `response[5] = 0x01` = 传输配置响应
- `response[6] = 0x00` = 成功

### 响应 2: 数据传输确认
```
📥 接收指令 [10 bytes]: 0B E0 02 00 05 02 01 00 00 00
```
- `0xE0` = dialMarket 指令
- `response[5] = 0x02` = 数据传输响应
- `response[8] = 0x00` = 继续传输（control = 0）

### 响应 3: 睡眠监测数据
```
📥 接收指令 [11 bytes]: 0C B5 03 00 06 1C 00 28 00 12 00
```
- `0xB5` = getSleepMonitoring 指令
- 这是睡眠监测数据响应（与表盘传输无关）

## ✅ 解决方案

### 方案 1: 在 WPCommands.m 中添加响应处理（推荐）

**文件：** `WatchProtocolSDK-ObjC/Core/WPCommands.m`

**步骤 1：添加 case 分支**
```objc
+ (void)handleResponse:(NSData *)response {
    // ...
    switch (commandType) {
        // ... 现有 case

        case WPCommandTypeDialMarket:
            [self handleDialMarketResponse:response];
            break;

        case WPCommandTypeGetSleepMonitoring:
            [self handleSleepMonitoringResponse:response];
            break;

        default:
            [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"⚠️ 未处理的指令响应:0x%02X", commandCode]];
            break;
    }
}
```

**步骤 2：实现处理方法**
```objc
+ (void)handleDialMarketResponse:(NSData *)response {
    const uint8_t *bytes = (const uint8_t *)response.bytes;

    if (response.length < 7) {
        [[WPLogger sharedInstance] log:@"❌ 表盘市场响应数据长度不足"];
        return;
    }

    NSInteger responseType = bytes[5];

    if (responseType == 0) {
        // 查询响应：解析 MTU 和屏幕信息
        if (response.length >= 10) {
            NSInteger mtu = (bytes[7] << 8) | bytes[8];
            [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"📱 设备 MTU: %ld", (long)mtu]];

            // 更新设备 MTU
            WPBluetoothManager *manager = [WPBluetoothManager sharedInstance];
            if (manager.currentDevice) {
                manager.currentDevice.mtu = mtu;
            }
        }

        if (response.length >= 12) {
            NSInteger screenType = bytes[7];
            NSInteger screenWidth = (bytes[8] << 8) | bytes[9];
            NSInteger screenHeight = (bytes[10] << 8) | bytes[11];
            [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"📱 屏幕信息 - 类型:%ld 宽:%ld 高:%ld",
                                           (long)screenType, (long)screenWidth, (long)screenHeight]];

            // 更新设备屏幕信息
            WPBluetoothManager *manager = [WPBluetoothManager sharedInstance];
            if (manager.currentDevice) {
                manager.currentDevice.screenType = screenType;
                manager.currentDevice.screenWidth = screenWidth;
                manager.currentDevice.screenHeight = screenHeight;
            }
        }

    } else if (responseType == 1) {
        // 传输配置响应
        BOOL success = bytes[6] == 0x00;
        if (success) {
            [[WPLogger sharedInstance] log:@"✅ 表盘传输配置成功"];
            // 发送通知，允许开始数据传输
            [[NSNotificationCenter defaultCenter] postNotificationName:@"XGZTCommandDialDataSendCompleteCallback"
                                                                object:nil];
        } else {
            [[WPLogger sharedInstance] log:@"❌ 表盘传输配置失败"];
        }

    } else if (responseType == 2) {
        // 数据传输响应
        NSInteger control = bytes[8];

        if (control == 0) {
            // 继续传输下一包
            [[WPLogger sharedInstance] log:@"📦 数据包接收成功，继续传输"];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"XGZTCommandDialDataSendCompleteCallback"
                                                                object:nil];
        } else if (control == 1) {
            // 传输完成
            [[WPLogger sharedInstance] log:@"✅ 表盘传输完成"];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"XGZTCommandDialDataSendCompleteCallback"
                                                                object:@(1)]; // 传递完成标志
        } else {
            [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"⚠️ 未知控制值:%ld", (long)control]];
        }
    }
}

+ (void)handleSleepMonitoringResponse:(NSData *)response {
    const uint8_t *bytes = (const uint8_t *)response.bytes;

    if (response.length < 11) {
        [[WPLogger sharedInstance] log:@"❌ 睡眠监测响应数据长度不足"];
        return;
    }

    // 解析睡眠数据
    NSInteger deepSleep = bytes[6] | (bytes[7] << 8);    // 深睡时长（分钟）
    NSInteger lightSleep = bytes[8] | (bytes[9] << 8);   // 浅睡时长（分钟）
    NSInteger awake = bytes[10] | (bytes[11] << 8);      // 清醒时长（分钟）

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"😴 睡眠监测 - 深睡:%ldmin 浅睡:%ldmin 清醒:%ldmin",
                                   (long)deepSleep, (long)lightSleep, (long)awake]];

    // 通过代理回调（如果需要）
    WPBluetoothManager *manager = [WPBluetoothManager sharedInstance];
    if ([manager.delegate respondsToSelector:@selector(didReceiveSleepData:lightSleep:awake:)]) {
        [manager.delegate didReceiveSleepData:deepSleep lightSleep:lightSleep awake:awake];
    }
}
```

### 方案 2: 修改 WFTransferEngine 使用代理模式（替代方案）

如果不希望依赖通知机制，可以修改为代理模式：

**文件：** `WatchProtocolSDK-ObjC/Core/WPBluetoothManager.h`
```objc
@protocol WPBluetoothManagerDelegate <NSObject>
@optional
// ... 现有代理方法

/**
 * 表盘数据包发送完成回调
 * @param isComplete 是否为最后一包（YES=传输完成, NO=继续发送）
 */
- (void)didCompleteDialDataPacketWithCompletion:(BOOL)isComplete;

@end
```

**修改 WFTransferEngine：**
```objc
// 实现 WPBluetoothManagerDelegate
@interface WFTransferEngine () <WPBluetoothManagerDelegate>
// ...
@end

- (void)didCompleteDialDataPacketWithCompletion:(BOOL)isComplete {
    if (isComplete) {
        [self handleTransferComplete];
    } else {
        [self sendNextPacket];
    }
}
```

## 🎯 推荐实施步骤

1. **立即修复：** 实施方案 1，添加 0xE0 和 0xB5 响应处理
2. **测试验证：** 运行表盘传输，确认通知发送正常
3. **长期优化：** 考虑迁移到方案 2 的代理模式（可选）

## 📝 相关文件

- `WatchProtocolSDK-ObjC/Core/WPCommands.h` (指令定义)
- `WatchProtocolSDK-ObjC/Core/WPCommands.m` (需要修改)
- `WatchFaceSDK-Pure-ObjC/Core/WFTransferEngine.m` (依赖通知)
- `WatchProtocolSDK/Core/XGZTCommands.swift` (Swift 参考实现)

## 🔗 相关问题

- 问题 #11: WatchFaceSDK-Pure-ObjC 缺少 WatchProtocolSDK 集成
- 问题 #16: 缺少模块配置文件
- 问题 #17: 模块配置参考

---

**生成时间：** 2026-01-29
**SDK 版本：** v2.0.7+
