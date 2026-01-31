# 闹钟和久坐提醒功能实现解决方案

## 📋 概述

本文档提供了将 WatchProtocolSDK Swift 版本中的闹钟设置和久坐提醒功能移植到 Objective-C 版本的完整解决方案。

---

## 🔍 当前状态分析

### ✅ 已实现部分（Objective-C）

#### 1. 数据结构定义
`WatchProtocolSDK-ObjC/Models/WPDeviceModel.h`

```objc
// 闹钟数据结构
@interface WPAlarmData : NSObject
@property (nonatomic, assign) NSInteger alarmId;      // 闹钟索引
@property (nonatomic, assign) BOOL enabled;            // 是否启用
@property (nonatomic, assign) NSInteger hour;          // 小时
@property (nonatomic, assign) NSInteger minute;        // 分钟
@property (nonatomic, assign) NSInteger repeatDays;    // 重复天数（位图）
@end

// 提醒信息（久坐、喝水）
@interface WPReminderInfo : NSObject
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) NSInteger startHour;
@property (nonatomic, assign) NSInteger startMinute;
@property (nonatomic, assign) NSInteger endHour;
@property (nonatomic, assign) NSInteger endMinute;
@property (nonatomic, assign) NSInteger interval;
@end

// 提醒信息响应
@interface WPReminderInfoResponse : NSObject
@property (nonatomic, assign) NSInteger eventType;     // 0=久坐 1=喝水
@property (nonatomic, assign) NSInteger cycle;
@property (nonatomic, assign) NSInteger startHour;
@property (nonatomic, assign) NSInteger startMinute;
@property (nonatomic, assign) NSInteger endHour;
@property (nonatomic, assign) NSInteger endMinute;
@property (nonatomic, assign) NSInteger period;
@end
```

#### 2. 指令发送方法
`WatchProtocolSDK-ObjC/Core/WPCommands.m`

```objc
// ✅ 获取闹钟信息
+ (void)getAlarmInfo:(NSInteger)type {
    // 已实现 - 指令码 0x83
}

// ✅ 设置闹钟信息
+ (void)setAlarmInfo:(NSInteger)setCmd alarm:(WPAlarmData *)alarm {
    // 已实现 - 指令码 0x83
}

// ✅ 获取提醒信息
+ (void)getReminderInfo:(NSInteger)eventType {
    // 已实现 - 指令码 0x85
}

// ✅ 设置提醒信息
+ (void)setReminderInfo:(WPReminderInfoResponse *)response {
    // 已实现 - 指令码 0x85
}
```

### ❌ 缺失部分（需要补充）

**响应解析方法未实现** - 在 `handleResponse:` 方法的 switch 语句中缺少：
- `case WPCommandTypeAlarmInfo:` (0x83)
- `case WPCommandTypeReminderInfo:` (0x85)

---

## 📦 Swift 版本参考实现

### 闹钟响应解析（Swift）
`WatchProtocolSDK/Core/XGZTCommands.swift` 1515-1560行

```swift
case .alarmInfo:
    // 1. 返回闹钟总数和可用数量（长度 8）
    if response.count == 8 {
        XGZTBlueToothManager.shared.device?.alarmcount = Int(response[6])
        XGZTBlueToothManager.shared.device?.alarmCanUse = Int(response[7])
        return
    }

    // 2. 设置成功响应（长度 8 或 7）
    if response.count == 8 && response[5] == 0x01 && response[7] == 0x00 {
        XGZTCommand.getAlarmInfo(type: 1)
        XGZTCommand.getAlarmInfo(type: 2)
        return
    }
    if response.count == 7 && response[5] == 0x01 && response[6] == 0x00 {
        XGZTCommand.getAlarmInfo(type: 1)
        XGZTCommand.getAlarmInfo(type: 2)
        return
    }

    // 3. 闹钟详细信息（长度 14）
    if response.count == 14 {
        let index = Int(response[7])
        let switchValue = Int(response[8])
        let cycle = Int(response[9])
        let hour = Int(response[10])
        let minute = Int(response[11])
        let vibration = Int(response[12])
        let later = Int(response[13])

        let alarm = AlarmData(
            alarmIndex: index,
            mswitch: switchValue,
            alarmCycle: cycle,
            alarmHour: hour,
            alarmMinute: minute,
            vibrationMode: vibration,
            remindLater: later
        )

        // 更新或添加闹钟到数组
        if let alarms = XGZTBlueToothManager.shared.device?.alarms {
            var found = false
            for (key, item) in alarms.enumerated() {
                if item.alarmIndex == index {
                    XGZTBlueToothManager.shared.device?.alarms[key] = alarm
                    found = true
                    break
                }
            }
            if !found {
                XGZTBlueToothManager.shared.device?.alarms.append(alarm)
            }
        } else {
            XGZTBlueToothManager.shared.device?.alarms.append(alarm)
        }

        // 发送通知
        NotificationCenter.default.post(name: Notification.Name("Alarm"), object: nil)
    }
```

### 提醒信息响应解析（Swift）
`WatchProtocolSDK/Core/XGZTCommands.swift` 1561-1586行

```swift
case .reminderInfo:
    // 1. 设置成功响应（长度 7）
    if response.count == 7 {
        if response[6] == 0 {
            XLogger.shared.log("提醒协议设置成功")
        }
        return
    }

    // 2. 提醒详细信息（长度 >= 12）
    guard response.count >= 12 else {
        XLogger.shared.log("reminderInfo command response error")
        return
    }

    let eventType = Int(response[6])      // 0=久坐 1=喝水
    let cycle = Int(response[7])
    let startHour = Int(response[8])
    let startMinute = Int(response[9])
    let endHour = Int(response[10])
    let endMinute = Int(response[11])
    let period = Int(response[12])

    if eventType == 0 {
        // 久坐提醒
        XGZTBlueToothManager.shared.device?.longsit = ReminderInfoResponse(
            eventType: eventType,
            cycle: cycle,
            startHour: startHour,
            startMinute: startMinute,
            endHour: endHour,
            endMinute: endMinute,
            period: period
        )
        NotificationCenter.default.post(name: Notification.Name("XGZTBusinessHandler"), object: "13")
    } else if eventType == 1 {
        // 喝水提醒
        XGZTBlueToothManager.shared.device?.drinkWater = ReminderInfoResponse(
            eventType: eventType,
            cycle: cycle,
            startHour: startHour,
            startMinute: startMinute,
            endHour: endHour,
            endMinute: endMinute,
            period: period
        )
        NotificationCenter.default.post(name: Notification.Name("XGZTBusinessHandler"), object: "14")
        NotificationCenter.default.post(name: Notification.Name("DeviceSettings"), object: @1)
    }
```

---

## 🔧 Objective-C 实现方案

### 位置
`WatchProtocolSDK-ObjC/Core/WPCommands.m`

### 步骤 1：在 handleResponse: 的 switch 中添加 case

找到文件第 1180 行的 switch 语句，在 `case WPCommandTypeSwitchStatus:` 之前添加：

```objc
case WPCommandTypeAlarmInfo:
    [self handleAlarmInfoResponse:response];
    break;

case WPCommandTypeReminderInfo:
    [self handleReminderInfoResponse:response];
    break;
```

### 步骤 2：实现闹钟响应解析方法

在文件底部（具体响应解析方法区域）添加：

```objc
// MARK: - 闹钟响应解析

+ (void)handleAlarmInfoResponse:(NSData *)response {
    const uint8_t *bytes = (const uint8_t *)response.bytes;

    // 1. 返回闹钟总数和可用数量（长度 8，查询类型）
    if (response.length == 8 && bytes[5] == 0x00) {
        WPBluetoothWatchDevice *device = [WPBluetoothManager sharedInstance].currentDevice;
        device.alarmCount = bytes[6];
        device.alarmCanUse = bytes[7];

        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"⏰ 闹钟总数:%ld 可用数量:%ld",
                                       (long)device.alarmCount, (long)device.alarmCanUse]];

        // 通知代理
        id<WPBluetoothManagerDelegate> delegate = [WPBluetoothManager sharedInstance].delegate;
        if ([delegate respondsToSelector:@selector(didUpdateAlarmCount:canUse:)]) {
            [delegate didUpdateAlarmCount:device.alarmCount canUse:device.alarmCanUse];
        }
        return;
    }

    // 2. 设置成功响应（长度 8 或 7）
    if ((response.length == 8 && bytes[5] == 0x01 && bytes[7] == 0x00) ||
        (response.length == 7 && bytes[5] == 0x01 && bytes[6] == 0x00)) {
        [[WPLogger sharedInstance] log:@"✅ 闹钟设置成功"];

        // 重新获取闹钟列表
        [self getAlarmInfo:1];
        [self getAlarmInfo:2];
        return;
    }

    // 3. 闹钟详细信息（长度 14）
    if (response.length == 14) {
        NSInteger index = bytes[7];
        NSInteger switchValue = bytes[8];
        NSInteger cycle = bytes[9];
        NSInteger hour = bytes[10];
        NSInteger minute = bytes[11];
        NSInteger vibration = bytes[12];
        NSInteger later = bytes[13];

        // 创建闹钟对象
        WPAlarmData *alarm = [[WPAlarmData alloc] init];
        alarm.alarmId = index;
        alarm.enabled = (switchValue == 1);
        alarm.repeatDays = cycle;
        alarm.hour = hour;
        alarm.minute = minute;

        [[WPLogger sharedInstance] log:[NSString stringWithFormat:
            @"⏰ 闹钟信息 - ID:%ld 时间:%02ld:%02ld 启用:%@ 重复:0x%02lX",
            (long)index, (long)hour, (long)minute,
            alarm.enabled ? @"是" : @"否", (long)cycle]];

        // 更新设备闹钟列表
        WPBluetoothWatchDevice *device = [WPBluetoothManager sharedInstance].currentDevice;
        if (!device.alarms) {
            device.alarms = [NSMutableArray array];
        }

        // 查找并更新或添加
        BOOL found = NO;
        for (NSInteger i = 0; i < device.alarms.count; i++) {
            WPAlarmData *existingAlarm = device.alarms[i];
            if (existingAlarm.alarmId == index) {
                device.alarms[i] = alarm;
                found = YES;
                break;
            }
        }

        if (!found) {
            [device.alarms addObject:alarm];
        }

        // 发送通知
        [[NSNotificationCenter defaultCenter] postNotificationName:@"WPAlarmUpdated" object:alarm];

        // 通知代理
        id<WPBluetoothManagerDelegate> delegate = [WPBluetoothManager sharedInstance].delegate;
        if ([delegate respondsToSelector:@selector(didUpdateAlarmInfo:)]) {
            [delegate didUpdateAlarmInfo:alarm];
        }

        return;
    }

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"⚠️ 未识别的闹钟响应格式 - 长度:%lu", (unsigned long)response.length]];
}
```

### 步骤 3：实现提醒信息响应解析方法

紧接着添加：

```objc
// MARK: - 提醒信息响应解析

+ (void)handleReminderInfoResponse:(NSData *)response {
    const uint8_t *bytes = (const uint8_t *)response.bytes;

    // 1. 设置成功响应（长度 7）
    if (response.length == 7) {
        if (bytes[6] == 0) {
            [[WPLogger sharedInstance] log:@"✅ 提醒设置成功"];
        } else {
            [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"❌ 提醒设置失败 - 错误码:%d", bytes[6]]];
        }
        return;
    }

    // 2. 提醒详细信息（长度 >= 13）
    if (response.length < 13) {
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"❌ 提醒信息响应数据长度不足:%lu", (unsigned long)response.length]];
        return;
    }

    NSInteger eventType = bytes[6];      // 0=久坐提醒 1=喝水提醒
    NSInteger cycle = bytes[7];
    NSInteger startHour = bytes[8];
    NSInteger startMinute = bytes[9];
    NSInteger endHour = bytes[10];
    NSInteger endMinute = bytes[11];
    NSInteger period = bytes[12];

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:
        @"📌 提醒信息 - 类型:%@ 周期:0x%02lX 时间:%02ld:%02ld-%02ld:%02ld 间隔:%ld分钟",
        eventType == 0 ? @"久坐" : @"喝水",
        (long)cycle, (long)startHour, (long)startMinute,
        (long)endHour, (long)endMinute, (long)period]];

    // 创建提醒对象
    WPReminderInfoResponse *reminderResponse = [[WPReminderInfoResponse alloc] init];
    reminderResponse.eventType = eventType;
    reminderResponse.cycle = cycle;
    reminderResponse.startHour = startHour;
    reminderResponse.startMinute = startMinute;
    reminderResponse.endHour = endHour;
    reminderResponse.endMinute = endMinute;
    reminderResponse.period = period;

    // 转换为设备模型使用的 WPReminderInfo
    WPReminderInfo *reminderInfo = [[WPReminderInfo alloc] init];
    reminderInfo.enabled = (cycle > 0);  // 根据周期判断是否启用
    reminderInfo.startHour = startHour;
    reminderInfo.startMinute = startMinute;
    reminderInfo.endHour = endHour;
    reminderInfo.endMinute = endMinute;
    reminderInfo.interval = period;

    // 更新设备信息
    WPBluetoothWatchDevice *device = [WPBluetoothManager sharedInstance].currentDevice;

    if (eventType == 0) {
        // 久坐提醒
        device.longSit = reminderInfo;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"WPLongSitReminderUpdated" object:reminderInfo];

        // 通知代理
        id<WPBluetoothManagerDelegate> delegate = [WPBluetoothManager sharedInstance].delegate;
        if ([delegate respondsToSelector:@selector(didUpdateLongSitReminder:)]) {
            [delegate didUpdateLongSitReminder:reminderInfo];
        }
    } else if (eventType == 1) {
        // 喝水提醒
        device.drinkWater = reminderInfo;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"WPDrinkWaterReminderUpdated" object:reminderInfo];

        // 通知代理
        id<WPBluetoothManagerDelegate> delegate = [WPBluetoothManager sharedInstance].delegate;
        if ([delegate respondsToSelector:@selector(didUpdateDrinkWaterReminder:)]) {
            [delegate didUpdateDrinkWaterReminder:reminderInfo];
        }
    }
}
```

### 步骤 4：更新 WPBluetoothManagerDelegate 协议

在 `WPBluetoothManager.h` 中添加新的代理方法（可选）：

```objc
@protocol WPBluetoothManagerDelegate <NSObject>
@optional

// 闹钟相关回调
- (void)didUpdateAlarmCount:(NSInteger)count canUse:(NSInteger)canUse;
- (void)didUpdateAlarmInfo:(WPAlarmData *)alarm;

// 提醒相关回调
- (void)didUpdateLongSitReminder:(WPReminderInfo *)reminder;
- (void)didUpdateDrinkWaterReminder:(WPReminderInfo *)reminder;

@end
```

---

## 📊 协议格式说明

### 闹钟信息协议 (0x83)

#### 发送指令格式

**获取闹钟信息**
```
[0x00, 0x83, 0x01, 0x00, 0x02, 0x00, type]
                                      └─ 闹钟类型（0=查询总数, 1/2=查询具体闹钟）
```

**设置闹钟信息**
```
[0x00, 0x83, 0x01, 0x00, 0x09, 0x01, setCmd, index, switch, cycle, hour, minute, vibration, later]
                                      └─────┬─────┘ └──────────────┬──────────────┘
                                          设置命令              闹钟参数
```

- `setCmd`: 设置命令（通常为 0x01）
- `index`: 闹钟索引 (0-7)
- `switch`: 开关状态 (0=关闭, 1=开启)
- `cycle`: 重复周期位图（bit0=周一...bit6=周日, bit7=保留）
- `hour`: 小时 (0-23)
- `minute`: 分钟 (0-59)
- `vibration`: 振动模式
- `later`: 稍后提醒

#### 响应格式

**查询总数响应（长度 8）**
```
bytes[0] = 0x00
bytes[1] = 0x83
bytes[2-4] = ...
bytes[5] = 0x00 (查询标志)
bytes[6] = 闹钟总数
bytes[7] = 可用数量
```

**设置成功响应（长度 7 或 8）**
```
bytes[5] = 0x01 (设置标志)
bytes[6/7] = 0x00 (成功)
```

**闹钟详细信息响应（长度 14）**
```
bytes[7]  = 闹钟索引
bytes[8]  = 开关状态
bytes[9]  = 重复周期
bytes[10] = 小时
bytes[11] = 分钟
bytes[12] = 振动模式
bytes[13] = 稍后提醒
```

### 提醒信息协议 (0x85)

#### 发送指令格式

**获取提醒信息**
```
[0x00, 0x85, 0x01, 0x00, 0x02, 0x00, eventType]
                                      └─ 事件类型（0=久坐, 1=喝水）
```

**设置提醒信息**
```
[0x00, 0x85, 0x01, 0x00, 0x08, 0x01, eventType, cycle, startHour, startMinute, endHour, endMinute, period]
                                      └────────────────────┬────────────────────┘
                                                      提醒参数
```

- `eventType`: 事件类型 (0=久坐提醒, 1=喝水提醒)
- `cycle`: 重复周期位图（同闹钟）
- `startHour/startMinute`: 开始时间
- `endHour/endMinute`: 结束时间
- `period`: 提醒间隔（分钟）

#### 响应格式

**设置成功响应（长度 7）**
```
bytes[6] = 0x00 (成功)
```

**提醒详细信息响应（长度 >= 13）**
```
bytes[6]  = 事件类型 (0=久坐, 1=喝水)
bytes[7]  = 重复周期
bytes[8]  = 开始小时
bytes[9]  = 开始分钟
bytes[10] = 结束小时
bytes[11] = 结束分钟
bytes[12] = 提醒间隔（分钟）
```

---

## 🔔 通知机制

### NSNotification 通知名称

```objc
// 闹钟更新通知
@"WPAlarmUpdated"          // userInfo: alarm (WPAlarmData *)

// 久坐提醒更新通知
@"WPLongSitReminderUpdated"  // userInfo: reminder (WPReminderInfo *)

// 喝水提醒更新通知
@"WPDrinkWaterReminderUpdated"  // userInfo: reminder (WPReminderInfo *)
```

### 代理回调方法

```objc
// 闹钟总数更新
- (void)didUpdateAlarmCount:(NSInteger)count canUse:(NSInteger)canUse;

// 闹钟信息更新
- (void)didUpdateAlarmInfo:(WPAlarmData *)alarm;

// 久坐提醒更新
- (void)didUpdateLongSitReminder:(WPReminderInfo *)reminder;

// 喝水提醒更新
- (void)didUpdateDrinkWaterReminder:(WPReminderInfo *)reminder;
```

---

## 📝 使用示例

### 设置闹钟

```objc
// 创建闹钟对象
WPAlarmData *alarm = [[WPAlarmData alloc] init];
alarm.alarmId = 0;          // 闹钟索引
alarm.enabled = YES;         // 启用
alarm.hour = 8;             // 8点
alarm.minute = 30;          // 30分
alarm.repeatDays = 0x1F;    // 周一到周五 (bit0-bit4)

// 发送设置指令
[WPCommands setAlarmInfo:0x01 alarm:alarm];

// 监听响应
[[NSNotificationCenter defaultCenter] addObserver:self
    selector:@selector(onAlarmUpdated:)
    name:@"WPAlarmUpdated"
    object:nil];
```

### 设置久坐提醒

```objc
// 创建提醒对象
WPReminderInfoResponse *reminder = [[WPReminderInfoResponse alloc] init];
reminder.eventType = 0;        // 久坐提醒
reminder.cycle = 0x7F;         // 每天 (周一到周日)
reminder.startHour = 9;        // 9:00
reminder.startMinute = 0;
reminder.endHour = 18;         // 18:00
reminder.endMinute = 0;
reminder.period = 60;          // 每60分钟提醒一次

// 发送设置指令
[WPCommands setReminderInfo:reminder];

// 监听响应
[[NSNotificationCenter defaultCenter] addObserver:self
    selector:@selector(onLongSitReminderUpdated:)
    name:@"WPLongSitReminderUpdated"
    object:nil];
```

### 查询闹钟列表

```objc
// 先查询总数
[WPCommands getAlarmInfo:0];

// 实现代理方法
- (void)didUpdateAlarmCount:(NSInteger)count canUse:(NSInteger)canUse {
    NSLog(@"闹钟总数:%ld 可用:%ld", count, canUse);

    // 查询每个闹钟的详细信息
    for (NSInteger i = 1; i <= count; i++) {
        [WPCommands getAlarmInfo:i];
    }
}

// 处理闹钟详细信息
- (void)didUpdateAlarmInfo:(WPAlarmData *)alarm {
    NSLog(@"闹钟 %ld: %02ld:%02ld %@",
          alarm.alarmId, alarm.hour, alarm.minute,
          alarm.enabled ? @"开启" : @"关闭");
}
```

### 查询久坐提醒

```objc
// 查询久坐提醒（eventType=0）
[WPCommands getReminderInfo:0];

// 实现代理方法
- (void)didUpdateLongSitReminder:(WPReminderInfo *)reminder {
    NSLog(@"久坐提醒: %@, 时间段 %02ld:%02ld - %02ld:%02ld, 间隔 %ld 分钟",
          reminder.enabled ? @"开启" : @"关闭",
          reminder.startHour, reminder.startMinute,
          reminder.endHour, reminder.endMinute,
          reminder.interval);
}
```

---

## ✅ 验证清单

实现完成后，请验证以下功能：

### 闹钟功能
- [ ] 查询闹钟总数和可用数量
- [ ] 设置新闹钟
- [ ] 修改现有闹钟
- [ ] 启用/禁用闹钟
- [ ] 设置重复周期（工作日、周末、每天等）
- [ ] 查询所有闹钟列表
- [ ] 接收闹钟更新通知

### 久坐提醒功能
- [ ] 查询久坐提醒设置
- [ ] 设置久坐提醒时间段
- [ ] 设置提醒间隔
- [ ] 设置重复周期
- [ ] 启用/禁用久坐提醒
- [ ] 接收久坐提醒更新通知

### 喝水提醒功能
- [ ] 查询喝水提醒设置
- [ ] 设置喝水提醒时间段
- [ ] 设置提醒间隔
- [ ] 设置重复周期
- [ ] 启用/禁用喝水提醒
- [ ] 接收喝水提醒更新通知

---

## 🐛 已知问题和注意事项

1. **数据结构差异**
   - Swift 版本使用 `AlarmData.alarmIndex`，ObjC 使用 `WPAlarmData.alarmId`
   - Swift 版本使用 `mswitch`（Int），ObjC 使用 `enabled`（BOOL）
   - 需要在发送指令时正确映射

2. **振动模式和稍后提醒**
   - ObjC 版本的 `WPAlarmData` 未包含 `vibrationMode` 和 `remindLater` 属性
   - 当前实现使用默认值（振动=1，稍后=0）
   - 如需完整支持，需要扩展 `WPAlarmData` 结构

3. **周期位图**
   - bit0 = 周一, bit1 = 周二, ... bit6 = 周日
   - 0x7F = 每天，0x1F = 工作日，0x60 = 周末

4. **事件类型**
   - 0 = 久坐提醒（longSit）
   - 1 = 喝水提醒（drinkWater）
   - 其他类型可能在未来版本中扩展

---

## 📚 相关文件

- `WatchProtocolSDK-ObjC/Core/WPCommands.h` - 指令接口定义
- `WatchProtocolSDK-ObjC/Core/WPCommands.m` - 指令实现和响应解析
- `WatchProtocolSDK-ObjC/Models/WPDeviceModel.h` - 设备数据模型
- `WatchProtocolSDK/Core/XGZTCommands.swift` - Swift 版本参考实现

---

## 📞 技术支持

如有问题或建议，请联系开发团队。

**版本**: v2.0.11+
**更新日期**: 2026-01-30
