# WatchProtocolSDK-ObjC v2.0.12 发布说明

## 🎉 版本信息

- **版本**: v2.0.12
- **发布日期**: 2026-01-30
- **类型**: 功能更新 + Bug 修复
- **兼容性**: 向后兼容 v2.0.11

---

## ✨ 新增功能

### 1. ⏰ 完整的闹钟管理系统

新增专用的闹钟管理 API，提供完整的闹钟生命周期管理。

**主要特性**:
- ✅ 查询闹钟总数和可用数量
- ✅ 查询单个或所有闹钟详情
- ✅ 设置闹钟（支持重复周期）
- ✅ 删除闹钟
- ✅ **新增支持**：振动模式和稍后提醒

**使用示例**:
```objc
// 设置工作日早晨闹钟
WPAlarmData *alarm = [[WPAlarmData alloc] init];
alarm.alarmIndex = 0;
alarm.mswitch = 1;              // 开启
alarm.alarmHour = 7;
alarm.alarmMinute = 30;
alarm.alarmCycle = 0b01111110;  // 周一到周五
alarm.vibrationMode = 1;        // 振动提醒
alarm.remindLater = 5;          // 稍后提醒 5 分钟

[[WPBluetoothManager sharedInstance] setAlarm:alarm completion:^(BOOL success, NSError *error) {
    if (success) NSLog(@"✅ 闹钟设置成功");
}];
```

**新增 API**:
```objc
// WPBluetoothManager 便捷方法
- (void)queryAlarmCount:(completion);
- (void)queryAlarmInfo:(alarmId completion);
- (void)queryAllAlarms:(completion);
- (void)setAlarm:(alarm completion);
- (void)deleteAlarm:(alarmId completion);

// WPCommands+Alarm Category
+ (void)queryAlarmCount:(completion);
+ (void)queryAlarmInfo:(alarmId completion);
+ (void)setAlarm:(alarm completion);
+ (void)deleteAlarm:(alarmId completion);
+ (void)queryAllAlarms:(completion);
```

**新增代理回调**:
```objc
@protocol WPBluetoothManagerDelegate
- (void)didUpdateAlarmCount:(NSInteger)count canUse:(NSInteger)canUse;
- (void)didUpdateAlarmInfo:(WPAlarmData *)alarm;
@end
```

---

### 2. 🪑 久坐提醒功能

帮助用户养成健康习惯，定时提醒久坐的用户起身活动。

**主要特性**:
- ✅ 查询当前久坐提醒设置
- ✅ 自定义时间段和提醒间隔
- ✅ 快捷开启/关闭（使用默认参数）

**使用示例**:
```objc
// 快速开启（默认 9:00-18:00，每 60 分钟提醒）
[[WPBluetoothManager sharedInstance] enableLongSitReminderWithCompletion:^(BOOL success, NSError *error) {
    if (success) NSLog(@"✅ 久坐提醒已开启");
}];

// 自定义设置
WPReminderInfo *reminder = [[WPReminderInfo alloc] init];
reminder.enabled = YES;
reminder.startHour = 9;
reminder.startMinute = 0;
reminder.endHour = 18;
reminder.endMinute = 0;
reminder.interval = 60;  // 每 60 分钟提醒

[[WPBluetoothManager sharedInstance] setLongSitReminder:reminder completion:nil];
```

**新增 API**:
```objc
// WPBluetoothManager 便捷方法
- (void)queryLongSitReminder:(completion);
- (void)setLongSitReminder:(reminder completion);
- (void)enableLongSitReminderWithCompletion:(completion);
- (void)disableLongSitReminderWithCompletion:(completion);

// WPCommands+Reminder Category
+ (void)queryLongSitReminder:(completion);
+ (void)setLongSitReminder:(reminder completion);
+ (void)enableLongSitReminderWithCompletion:(completion);
+ (void)disableLongSitReminderWithCompletion:(completion);
```

**新增代理回调**:
```objc
@protocol WPBluetoothManagerDelegate
- (void)didUpdateLongSitReminder:(WPReminderInfo *)reminder;
@end
```

---

### 3. 💧 喝水提醒功能

帮助用户保持良好的饮水习惯，定时提醒补充水分。

**主要特性**:
- ✅ 查询当前喝水提醒设置
- ✅ 自定义时间段和提醒间隔
- ✅ 快捷开启/关闭（使用默认参数）

**使用示例**:
```objc
// 快速开启（默认 8:00-20:00，每 120 分钟提醒）
[[WPBluetoothManager sharedInstance] enableDrinkWaterReminderWithCompletion:^(BOOL success, NSError *error) {
    if (success) NSLog(@"✅ 喝水提醒已开启");
}];

// 自定义设置
WPReminderInfo *reminder = [[WPReminderInfo alloc] init];
reminder.enabled = YES;
reminder.startHour = 8;
reminder.startMinute = 0;
reminder.endHour = 20;
reminder.endMinute = 0;
reminder.interval = 90;  // 每 90 分钟提醒

[[WPBluetoothManager sharedInstance] setDrinkWaterReminder:reminder completion:nil];
```

**新增 API**:
```objc
// WPBluetoothManager 便捷方法
- (void)queryDrinkWaterReminder:(completion);
- (void)setDrinkWaterReminder:(reminder completion);
- (void)enableDrinkWaterReminderWithCompletion:(completion);
- (void)disableDrinkWaterReminderWithCompletion:(completion);

// WPCommands+Reminder Category
+ (void)queryDrinkWaterReminder:(completion);
+ (void)setDrinkWaterReminder:(reminder completion);
+ (void)enableDrinkWaterReminderWithCompletion:(completion);
+ (void)disableDrinkWaterReminderWithCompletion:(completion);
```

**新增代理回调**:
```objc
@protocol WPBluetoothManagerDelegate
- (void)didUpdateDrinkWaterReminder:(WPReminderInfo *)reminder;
@end
```

---

## 🔧 Bug 修复

### 修复 1: 查询提醒指令格式错误 🔴 严重

**问题**: 查询久坐/喝水提醒时，指令长度字节错误导致设备无法正确响应。

**影响范围**: v2.0.11 及之前版本（如果有实现提醒查询功能）

**修复内容**:
```objc
// ❌ 修复前：长度字节错误
[0x00, 0x85, 0x01, 0x00, 0x03, 0x00, reminderType, 0x00]

// ✅ 修复后：长度字节正确
[0x00, 0x85, 0x01, 0x00, 0x02, 0x00, reminderType]
```

**修复位置**: `WPCommands+Reminder.m` Line 100-112

---

### 修复 2: 删除闹钟时字段初始化不完整 🟡 一般

**问题**: 删除闹钟时，振动模式和稍后提醒字段未初始化，可能产生随机值。

**影响范围**: 不影响功能，但代码不规范

**修复内容**:
```objc
// ✅ 修复后：完整初始化所有字段
WPAlarmData *alarm = [[WPAlarmData alloc] init];
alarm.alarmIndex = alarmId;
alarm.mswitch = 0;
alarm.alarmHour = 0;
alarm.alarmMinute = 0;
alarm.alarmCycle = 0;
alarm.vibrationMode = 0;     // ✅ 新增
alarm.remindLater = 0;       // ✅ 新增
```

**修复位置**: `WPCommands+Alarm.m` Line 253-265

---

## 📦 数据模型增强

### WPAlarmData 模型扩展

新增字段以支持完整的闹钟功能：

```objc
@interface WPAlarmData : NSObject

// 核心字段（与 Swift 版本一致）
@property (nonatomic, assign) NSInteger alarmIndex;       // 闹钟索引
@property (nonatomic, assign) NSInteger mswitch;          // 开关
@property (nonatomic, assign) NSInteger alarmCycle;       // 重复周期
@property (nonatomic, assign) NSInteger alarmHour;        // 小时
@property (nonatomic, assign) NSInteger alarmMinute;      // 分钟
@property (nonatomic, assign) NSInteger vibrationMode;    // ✅ 新增：振动模式
@property (nonatomic, assign) NSInteger remindLater;      // ✅ 新增：稍后提醒

// 便捷属性（向后兼容）
@property (nonatomic, assign) NSInteger alarmId;          // = alarmIndex
@property (nonatomic, assign) BOOL enabled;               // = (mswitch == 1)
@property (nonatomic, assign) NSInteger hour;             // = alarmHour
@property (nonatomic, assign) NSInteger minute;           // = alarmMinute
@property (nonatomic, assign) NSInteger repeatDays;       // = alarmCycle

@end
```

**向后兼容性**:
- ✅ 旧代码可继续使用 `alarmId`、`enabled`、`hour`、`minute`、`repeatDays`
- ✅ 新代码推荐使用完整字段获得所有功能

---

## 🎯 协议兼容性

### 与 Swift 版本对照

本版本确保所有协议实现与 Swift 版本（XGZTCommands.swift）完全一致：

| 功能 | 协议 | 兼容性 |
|------|------|--------|
| 查询闹钟总数 | 0x83 | ✅ 100% 一致 |
| 查询闹钟详细 | 0x83 | ✅ 100% 一致 |
| 设置闹钟 | 0x83 | ✅ 100% 一致 |
| 查询提醒 | 0x85 | ✅ 已修复，100% 一致 |
| 设置提醒 | 0x85 | ✅ 100% 一致 |

**验证文档**: 查看 `PROTOCOL_VERIFICATION_FINAL.md` 了解详细验证报告

---

## 📚 新增文档

本版本新增以下完整文档：

1. **ALARM_REMINDER_USAGE_GUIDE.md**
   - 完整的使用指南
   - 所有功能的代码示例
   - 代理回调示例
   - 完整的页面实现示例

2. **ALARM_REMINDER_PROTOCOL_FIX.md**
   - 协议修正详细说明
   - 与 Swift 实现的对比
   - 修复前后对比

3. **PROTOCOL_VERIFICATION_FINAL.md**
   - 最终协议验证报告
   - 完整的测试用例
   - 验证通过证明

4. **PROTOCOL_CHECK_REPORT.md**
   - 详细检查报告
   - 发现的问题和修复建议

---

## 🔄 迁移指南

### 从 v2.0.11 升级到 v2.0.12

**无需任何代码修改** - 完全向后兼容！

如果你正在使用旧版本的便捷属性，代码可以继续工作：

```objc
// ✅ 旧代码继续有效
WPAlarmData *alarm = [[WPAlarmData alloc] init];
alarm.alarmId = 0;           // 自动映射到 alarmIndex
alarm.enabled = YES;         // 自动映射到 mswitch = 1
alarm.hour = 7;              // 自动映射到 alarmHour
alarm.minute = 30;           // 自动映射到 alarmMinute
alarm.repeatDays = 0b01111110; // 自动映射到 alarmCycle
```

**推荐新代码使用完整字段以获得所有功能**:

```objc
// ✅ 新代码推荐写法（获得振动和稍后提醒功能）
alarm.alarmIndex = 0;
alarm.mswitch = 1;
alarm.alarmHour = 7;
alarm.alarmMinute = 30;
alarm.alarmCycle = 0b01111110;
alarm.vibrationMode = 1;     // 振动提醒
alarm.remindLater = 5;       // 稍后 5 分钟
```

---

## ⚠️ 注意事项

### 设备兼容性

- ✅ 所有功能需要设备支持对应协议
- ✅ 建议先查询设备功能再使用相关 API
- ✅ 不支持的功能会返回错误，不会崩溃

### 错误处理

所有新增 API 都提供完整的错误处理：

```objc
[[WPBluetoothManager sharedInstance] setAlarm:alarm completion:^(BOOL success, NSError *error) {
    if (success) {
        NSLog(@"✅ 设置成功");
    } else {
        // 处理错误
        switch (error.code) {
            case WPAlarmErrorCodeBluetoothOff:
                NSLog(@"蓝牙未开启");
                break;
            case WPAlarmErrorCodeDeviceNotConnected:
                NSLog(@"设备未连接");
                break;
            case WPAlarmErrorCodeInvalidParameter:
                NSLog(@"参数无效");
                break;
            default:
                NSLog(@"其他错误: %@", error.localizedDescription);
        }
    }
}];
```

---

## 🚀 快速开始

### 集成 Framework

1. 将 `WatchProtocolSDK.xcframework` 拖入项目
2. 设置 Embed 为 **"Embed & Sign"**（动态库必须嵌入）
3. 导入头文件：
```objc
#import <WatchProtocolSDK/WatchProtocolSDK.h>
```

### 使用新功能

```objc
// 1. 设置闹钟
WPAlarmData *alarm = [[WPAlarmData alloc] init];
alarm.alarmIndex = 0;
alarm.mswitch = 1;
alarm.alarmHour = 7;
alarm.alarmMinute = 30;
alarm.alarmCycle = 0b01111110;
alarm.vibrationMode = 1;
alarm.remindLater = 5;
[[WPBluetoothManager sharedInstance] setAlarm:alarm completion:nil];

// 2. 开启久坐提醒
[[WPBluetoothManager sharedInstance] enableLongSitReminderWithCompletion:nil];

// 3. 开启喝水提醒
[[WPBluetoothManager sharedInstance] enableDrinkWaterReminderWithCompletion:nil];
```

---

## 📊 版本对比

| 功能 | v2.0.11 | v2.0.12 |
|------|---------|---------|
| 闹钟管理 | ❌ | ✅ 完整支持 |
| 振动模式 | ❌ | ✅ 支持 |
| 稍后提醒 | ❌ | ✅ 支持 |
| 久坐提醒 | ❌ | ✅ 完整支持 |
| 喝水提醒 | ❌ | ✅ 完整支持 |
| 协议兼容性 | ⚠️ 部分不一致 | ✅ 100% 一致 |
| Framework 大小 | ~1.3M | ~1.4M |

---

## 🔗 相关链接

- **使用指南**: [ALARM_REMINDER_USAGE_GUIDE.md](./ALARM_REMINDER_USAGE_GUIDE.md)
- **协议验证**: [PROTOCOL_VERIFICATION_FINAL.md](./PROTOCOL_VERIFICATION_FINAL.md)
- **构建报告**: [BUILD_REPORT_v2.0.12.md](./BUILD_REPORT_v2.0.12.md)
- **集成指南**: [DYNAMIC_FRAMEWORK_INTEGRATION.md](./DYNAMIC_FRAMEWORK_INTEGRATION.md)

---

## 📞 技术支持

如有问题，请联系：**315082431@qq.com**

提供问题时，请附上：
1. SDK 版本号（v2.0.12）
2. Xcode 版本
3. 完整错误信息
4. 设备型号和固件版本

---

**感谢使用 WatchProtocolSDK-ObjC！**

🎉 v2.0.12 - 功能更完整，协议更准确，体验更流畅！
