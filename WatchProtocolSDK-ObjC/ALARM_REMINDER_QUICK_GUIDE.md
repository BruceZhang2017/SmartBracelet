# 闹钟和久坐提醒 - 快速实现指南

## 🚀 3步快速实现

### 步骤 1：在 handleResponse: 中添加 case
**文件**: `WatchProtocolSDK-ObjC/Core/WPCommands.m` (第 1180 行左右)

在 switch 语句中添加：

```objc
case WPCommandTypeAlarmInfo:
    [self handleAlarmInfoResponse:response];
    break;

case WPCommandTypeReminderInfo:
    [self handleReminderInfoResponse:response];
    break;
```

### 步骤 2：实现闹钟响应解析
在文件底部添加以下方法：

```objc
+ (void)handleAlarmInfoResponse:(NSData *)response {
    const uint8_t *bytes = (const uint8_t *)response.bytes;
    WPBluetoothWatchDevice *device = [WPBluetoothManager sharedInstance].currentDevice;

    // 查询总数响应
    if (response.length == 8 && bytes[5] == 0x00) {
        device.alarmCount = bytes[6];
        device.alarmCanUse = bytes[7];
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"⏰ 闹钟总数:%ld 可用:%ld", (long)device.alarmCount, (long)device.alarmCanUse]];
        return;
    }

    // 设置成功响应
    if ((response.length == 8 && bytes[5] == 0x01 && bytes[7] == 0x00) ||
        (response.length == 7 && bytes[5] == 0x01 && bytes[6] == 0x00)) {
        [[WPLogger sharedInstance] log:@"✅ 闹钟设置成功"];
        [self getAlarmInfo:1];
        [self getAlarmInfo:2];
        return;
    }

    // 闹钟详细信息
    if (response.length == 14) {
        WPAlarmData *alarm = [[WPAlarmData alloc] init];
        alarm.alarmId = bytes[7];
        alarm.enabled = (bytes[8] == 1);
        alarm.repeatDays = bytes[9];
        alarm.hour = bytes[10];
        alarm.minute = bytes[11];

        // 更新设备闹钟列表
        if (!device.alarms) device.alarms = [NSMutableArray array];

        BOOL found = NO;
        for (NSInteger i = 0; i < device.alarms.count; i++) {
            if (((WPAlarmData *)device.alarms[i]).alarmId == alarm.alarmId) {
                device.alarms[i] = alarm;
                found = YES;
                break;
            }
        }
        if (!found) [device.alarms addObject:alarm];

        [[NSNotificationCenter defaultCenter] postNotificationName:@"WPAlarmUpdated" object:alarm];
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"⏰ 闹钟 %ld: %02ld:%02ld %@",
            (long)alarm.alarmId, (long)alarm.hour, (long)alarm.minute, alarm.enabled ? @"开启" : @"关闭"]];
    }
}
```

### 步骤 3：实现提醒响应解析
继续添加：

```objc
+ (void)handleReminderInfoResponse:(NSData *)response {
    const uint8_t *bytes = (const uint8_t *)response.bytes;
    WPBluetoothWatchDevice *device = [WPBluetoothManager sharedInstance].currentDevice;

    // 设置成功响应
    if (response.length == 7) {
        if (bytes[6] == 0) {
            [[WPLogger sharedInstance] log:@"✅ 提醒设置成功"];
        }
        return;
    }

    // 提醒详细信息
    if (response.length >= 13) {
        NSInteger eventType = bytes[6];  // 0=久坐 1=喝水

        WPReminderInfo *reminder = [[WPReminderInfo alloc] init];
        reminder.enabled = (bytes[7] > 0);
        reminder.startHour = bytes[8];
        reminder.startMinute = bytes[9];
        reminder.endHour = bytes[10];
        reminder.endMinute = bytes[11];
        reminder.interval = bytes[12];

        if (eventType == 0) {
            device.longSit = reminder;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"WPLongSitReminderUpdated" object:reminder];
            [[WPLogger sharedInstance] log:@"📌 久坐提醒已更新"];
        } else if (eventType == 1) {
            device.drinkWater = reminder;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"WPDrinkWaterReminderUpdated" object:reminder];
            [[WPLogger sharedInstance] log:@"📌 喝水提醒已更新"];
        }
    }
}
```

## 📌 协议格式速查

### 闹钟协议 (0x83)

#### 获取闹钟
```objc
[WPCommands getAlarmInfo:0];  // 查询总数
[WPCommands getAlarmInfo:1];  // 查询闹钟1
[WPCommands getAlarmInfo:2];  // 查询闹钟2
```

#### 设置闹钟
```objc
WPAlarmData *alarm = [[WPAlarmData alloc] init];
alarm.alarmId = 0;          // 索引 0-7
alarm.enabled = YES;
alarm.hour = 8;
alarm.minute = 30;
alarm.repeatDays = 0x7F;    // 每天

[WPCommands setAlarmInfo:0x01 alarm:alarm];
```

**repeatDays 位图**:
- `0x7F` (0b01111111) = 每天
- `0x1F` (0b00011111) = 工作日（周一到周五）
- `0x60` (0b01100000) = 周末（周六周日）
- bit0=周一, bit1=周二, ..., bit6=周日

#### 响应格式
- **查询总数**: 长度8, bytes[6]=总数, bytes[7]=可用数量
- **设置成功**: 长度7或8, bytes[6]或bytes[7]=0x00
- **闹钟详情**: 长度14
  ```
  bytes[7]  = 索引
  bytes[8]  = 开关 (0/1)
  bytes[9]  = 重复周期
  bytes[10] = 小时
  bytes[11] = 分钟
  bytes[12] = 振动模式
  bytes[13] = 稍后提醒
  ```

### 提醒协议 (0x85)

#### 获取提醒
```objc
[WPCommands getReminderInfo:0];  // 久坐提醒
[WPCommands getReminderInfo:1];  // 喝水提醒
```

#### 设置提醒
```objc
WPReminderInfoResponse *reminder = [[WPReminderInfoResponse alloc] init];
reminder.eventType = 0;        // 0=久坐 1=喝水
reminder.cycle = 0x7F;         // 每天
reminder.startHour = 9;
reminder.startMinute = 0;
reminder.endHour = 18;
reminder.endMinute = 0;
reminder.period = 60;          // 间隔60分钟

[WPCommands setReminderInfo:reminder];
```

#### 响应格式
- **设置成功**: 长度7, bytes[6]=0x00
- **提醒详情**: 长度13+
  ```
  bytes[6]  = 事件类型 (0=久坐 1=喝水)
  bytes[7]  = 重复周期
  bytes[8]  = 开始小时
  bytes[9]  = 开始分钟
  bytes[10] = 结束小时
  bytes[11] = 结束分钟
  bytes[12] = 间隔（分钟）
  ```

## 🔔 监听通知

```objc
// 闹钟更新
[[NSNotificationCenter defaultCenter] addObserver:self
    selector:@selector(onAlarmUpdated:)
    name:@"WPAlarmUpdated"
    object:nil];

// 久坐提醒更新
[[NSNotificationCenter defaultCenter] addObserver:self
    selector:@selector(onLongSitUpdated:)
    name:@"WPLongSitReminderUpdated"
    object:nil];

// 喝水提醒更新
[[NSNotificationCenter defaultCenter] addObserver:self
    selector:@selector(onDrinkWaterUpdated:)
    name:@"WPDrinkWaterReminderUpdated"
    object:nil];
```

## ✅ 测试步骤

1. **测试闹钟查询**
   ```objc
   [WPCommands getAlarmInfo:0];  // 应该收到总数响应
   ```

2. **测试闹钟设置**
   ```objc
   WPAlarmData *alarm = [[WPAlarmData alloc] init];
   alarm.alarmId = 0;
   alarm.enabled = YES;
   alarm.hour = 8;
   alarm.minute = 0;
   alarm.repeatDays = 0x7F;
   [WPCommands setAlarmInfo:0x01 alarm:alarm];  // 应该收到设置成功响应
   ```

3. **测试久坐提醒查询**
   ```objc
   [WPCommands getReminderInfo:0];  // 应该收到久坐提醒详情
   ```

4. **测试久坐提醒设置**
   ```objc
   WPReminderInfoResponse *reminder = [[WPReminderInfoResponse alloc] init];
   reminder.eventType = 0;
   reminder.cycle = 0x7F;
   reminder.startHour = 9;
   reminder.startMinute = 0;
   reminder.endHour = 18;
   reminder.endMinute = 0;
   reminder.period = 60;
   [WPCommands setReminderInfo:reminder];  // 应该收到设置成功响应
   ```

## 🐛 调试技巧

1. **启用日志**
   ```objc
   [[WPLogger sharedInstance] setLogLevel:WPLogLevelDebug];
   ```

2. **监控原始数据**
   - 在 `handleResponse:` 开始处添加打印
   - 查看响应数据的长度和内容

3. **验证数据包**
   - 闹钟查询响应应该是 8 字节
   - 闹钟详情响应应该是 14 字节
   - 提醒详情响应应该是 13+ 字节

## 📚 完整文档

详细实现说明请参考：`ALARM_REMINDER_SOLUTION.md`

---

**版本**: v2.0.11+
**更新**: 2026-01-30
