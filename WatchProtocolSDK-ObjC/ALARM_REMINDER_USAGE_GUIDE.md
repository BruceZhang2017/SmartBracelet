# 闹钟、久坐提醒和喝水提醒使用指南

## 概述

WatchProtocolSDK v2.0.11+ 新增了闹钟、久坐提醒和喝水提醒的完整支持，参考抬手亮屏功能的封装方式，提供了易用的 API 接口。

## 目录

- [闹钟功能](#闹钟功能)
- [久坐提醒](#久坐提醒)
- [喝水提醒](#喝水提醒)
- [代理回调](#代理回调)
- [完整示例](#完整示例)

---

## 闹钟功能

### 1. 查询闹钟总数

```objc
[[WPBluetoothManager sharedInstance] queryAlarmCount:^(BOOL success, NSError *error) {
    if (success) {
        // 等待代理回调或直接读取设备属性
        NSInteger count = [WPBluetoothManager sharedInstance].currentDevice.alarmCount;
        NSInteger canUse = [WPBluetoothManager sharedInstance].currentDevice.alarmCanUse;
        NSLog(@"闹钟总数: %ld, 可用: %ld", count, canUse);
    } else {
        NSLog(@"查询失败: %@", error.localizedDescription);
    }
}];
```

### 2. 查询所有闹钟

```objc
[[WPBluetoothManager sharedInstance] queryAllAlarms:^(BOOL success, NSError *error) {
    if (success) {
        NSLog(@"✅ 所有闹钟查询完成");
        // 结果会通过代理方法 didUpdateAlarmInfo: 多次回调
    } else {
        NSLog(@"❌ 查询失败: %@", error.localizedDescription);
    }
}];
```

### 3. 查询指定闹钟

```objc
NSInteger alarmId = 0;
[[WPBluetoothManager sharedInstance] queryAlarmInfo:alarmId completion:^(BOOL success, NSError *error) {
    if (success) {
        // 等待代理回调或读取设备属性
        WPAlarmData *alarm = [WPBluetoothManager sharedInstance].currentDevice.alarms[alarmId];
        NSLog(@"闹钟 %ld: %02ld:%02ld, %@",
              alarmId, alarm.hour, alarm.minute,
              alarm.enabled ? @"开启" : @"关闭");
    }
}];
```

### 4. 设置闹钟

```objc
// 创建闹钟对象
WPAlarmData *alarm = [[WPAlarmData alloc] init];
alarm.alarmId = 0;           // 闹钟索引（从 0 开始）
alarm.enabled = YES;         // 开启闹钟
alarm.hour = 7;              // 7点
alarm.minute = 30;           // 30分
alarm.repeatDays = 0b01111110; // 周一到周五（位图表示）

// 发送设置指令
[[WPBluetoothManager sharedInstance] setAlarm:alarm completion:^(BOOL success, NSError *error) {
    if (success) {
        NSLog(@"✅ 闹钟设置成功");
    } else {
        NSLog(@"❌ 设置失败: %@", error.localizedDescription);
    }
}];
```

#### 重复周期位图说明

`repeatDays` 使用 8 位二进制表示一周的每一天：

```
位:  7  6  5  4  3  2  1  0
日: 周日 周六 周五 周四 周三 周二 周一
```

常用示例：
- `0b01111110` (0x7E) = 周一到周五
- `0b10000001` (0x81) = 周六和周日
- `0b11111111` (0xFF) = 每天
- `0b00000000` (0x00) = 一次性闹钟（不重复）

### 5. 删除闹钟

```objc
NSInteger alarmId = 0;
[[WPBluetoothManager sharedInstance] deleteAlarm:alarmId completion:^(BOOL success, NSError *error) {
    if (success) {
        NSLog(@"✅ 闹钟已删除");
    } else {
        NSLog(@"❌ 删除失败: %@", error.localizedDescription);
    }
}];
```

---

## 久坐提醒

### 1. 查询久坐提醒设置

```objc
[[WPBluetoothManager sharedInstance] queryLongSitReminder:^(BOOL success, NSError *error) {
    if (success) {
        WPReminderInfo *reminder = [WPBluetoothManager sharedInstance].currentDevice.longSit;
        NSLog(@"久坐提醒: %@", reminder.enabled ? @"开启" : @"关闭");
        NSLog(@"时段: %02ld:%02ld - %02ld:%02ld",
              reminder.startHour, reminder.startMinute,
              reminder.endHour, reminder.endMinute);
        NSLog(@"间隔: %ld 分钟", reminder.interval);
    }
}];
```

### 2. 设置久坐提醒（自定义参数）

```objc
WPReminderInfo *reminder = [[WPReminderInfo alloc] init];
reminder.enabled = YES;       // 开启提醒
reminder.startHour = 9;       // 开始时间：9:00
reminder.startMinute = 0;
reminder.endHour = 18;        // 结束时间：18:00
reminder.endMinute = 0;
reminder.interval = 60;       // 每 60 分钟提醒一次

[[WPBluetoothManager sharedInstance] setLongSitReminder:reminder completion:^(BOOL success, NSError *error) {
    if (success) {
        NSLog(@"✅ 久坐提醒设置成功");
    } else {
        NSLog(@"❌ 设置失败: %@", error.localizedDescription);
    }
}];
```

### 3. 快捷开启/关闭

```objc
// 开启久坐提醒（使用默认参数：9:00-18:00, 间隔60分钟）
[[WPBluetoothManager sharedInstance] enableLongSitReminderWithCompletion:^(BOOL success, NSError *error) {
    if (success) {
        NSLog(@"✅ 久坐提醒已开启");
    }
}];

// 关闭久坐提醒
[[WPBluetoothManager sharedInstance] disableLongSitReminderWithCompletion:^(BOOL success, NSError *error) {
    if (success) {
        NSLog(@"✅ 久坐提醒已关闭");
    }
}];
```

---

## 喝水提醒

### 1. 查询喝水提醒设置

```objc
[[WPBluetoothManager sharedInstance] queryDrinkWaterReminder:^(BOOL success, NSError *error) {
    if (success) {
        WPReminderInfo *reminder = [WPBluetoothManager sharedInstance].currentDevice.drinkWater;
        NSLog(@"喝水提醒: %@", reminder.enabled ? @"开启" : @"关闭");
        NSLog(@"时段: %02ld:%02ld - %02ld:%02ld",
              reminder.startHour, reminder.startMinute,
              reminder.endHour, reminder.endMinute);
        NSLog(@"间隔: %ld 分钟", reminder.interval);
    }
}];
```

### 2. 设置喝水提醒（自定义参数）

```objc
WPReminderInfo *reminder = [[WPReminderInfo alloc] init];
reminder.enabled = YES;       // 开启提醒
reminder.startHour = 8;       // 开始时间：8:00
reminder.startMinute = 0;
reminder.endHour = 20;        // 结束时间：20:00
reminder.endMinute = 0;
reminder.interval = 120;      // 每 120 分钟提醒一次

[[WPBluetoothManager sharedInstance] setDrinkWaterReminder:reminder completion:^(BOOL success, NSError *error) {
    if (success) {
        NSLog(@"✅ 喝水提醒设置成功");
    } else {
        NSLog(@"❌ 设置失败: %@", error.localizedDescription);
    }
}];
```

### 3. 快捷开启/关闭

```objc
// 开启喝水提醒（使用默认参数：8:00-20:00, 间隔120分钟）
[[WPBluetoothManager sharedInstance] enableDrinkWaterReminderWithCompletion:^(BOOL success, NSError *error) {
    if (success) {
        NSLog(@"✅ 喝水提醒已开启");
    }
}];

// 关闭喝水提醒
[[WPBluetoothManager sharedInstance] disableDrinkWaterReminderWithCompletion:^(BOOL success, NSError *error) {
    if (success) {
        NSLog(@"✅ 喝水提醒已关闭");
    }
}];
```

---

## 代理回调

### 实现代理协议

```objc
@interface YourViewController () <WPBluetoothManagerDelegate>
@end

@implementation YourViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // 设置代理
    [WPBluetoothManager sharedInstance].delegate = self;
}

#pragma mark - WPBluetoothManagerDelegate

// 闹钟总数更新
- (void)didUpdateAlarmCount:(NSInteger)count canUse:(NSInteger)canUse {
    NSLog(@"🔔 闹钟总数: %ld, 可用: %ld", count, canUse);
    // 更新 UI
    self.alarmCountLabel.text = [NSString stringWithFormat:@"%ld/%ld", canUse, count];
}

// 闹钟详细信息更新
- (void)didUpdateAlarmInfo:(WPAlarmData *)alarm {
    NSLog(@"🔔 闹钟 %ld 更新: %02ld:%02ld, %@, 重复=0x%02lX",
          alarm.alarmId, alarm.hour, alarm.minute,
          alarm.enabled ? @"开启" : @"关闭",
          (unsigned long)alarm.repeatDays);

    // 更新 UI
    [self reloadAlarmList];
}

// 久坐提醒更新
- (void)didUpdateLongSitReminder:(WPReminderInfo *)reminder {
    NSLog(@"🪑 久坐提醒更新: %@, 时段 %02ld:%02ld-%02ld:%02ld, 间隔 %ld 分钟",
          reminder.enabled ? @"开启" : @"关闭",
          reminder.startHour, reminder.startMinute,
          reminder.endHour, reminder.endMinute,
          reminder.interval);

    // 更新 UI
    self.longSitSwitch.on = reminder.enabled;
}

// 喝水提醒更新
- (void)didUpdateDrinkWaterReminder:(WPReminderInfo *)reminder {
    NSLog(@"💧 喝水提醒更新: %@, 时段 %02ld:%02ld-%02ld:%02ld, 间隔 %ld 分钟",
          reminder.enabled ? @"开启" : @"关闭",
          reminder.startHour, reminder.startMinute,
          reminder.endHour, reminder.endMinute,
          reminder.interval);

    // 更新 UI
    self.drinkWaterSwitch.on = reminder.enabled;
}

@end
```

---

## 完整示例

### 闹钟管理页面示例

```objc
@interface AlarmViewController () <WPBluetoothManagerDelegate>
@property (nonatomic, strong) NSMutableArray<WPAlarmData *> *alarms;
@end

@implementation AlarmViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [WPBluetoothManager sharedInstance].delegate = self;
    self.alarms = [NSMutableArray array];

    // 加载所有闹钟
    [self loadAllAlarms];
}

- (void)loadAllAlarms {
    [[WPBluetoothManager sharedInstance] queryAllAlarms:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"✅ 闹钟数据加载完成");
        } else {
            [self showError:error.localizedDescription];
        }
    }];
}

// 添加新闹钟
- (IBAction)addAlarmButtonTapped:(id)sender {
    WPAlarmData *alarm = [[WPAlarmData alloc] init];
    alarm.alarmId = self.alarms.count;
    alarm.enabled = YES;
    alarm.hour = 7;
    alarm.minute = 0;
    alarm.repeatDays = 0b01111110; // 工作日

    [[WPBluetoothManager sharedInstance] setAlarm:alarm completion:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"✅ 闹钟添加成功");
            [self loadAllAlarms]; // 重新加载
        } else {
            [self showError:error.localizedDescription];
        }
    }];
}

// 删除闹钟
- (void)deleteAlarmAtIndex:(NSInteger)index {
    [[WPBluetoothManager sharedInstance] deleteAlarm:index completion:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"✅ 闹钟已删除");
            [self loadAllAlarms];
        } else {
            [self showError:error.localizedDescription];
        }
    }];
}

#pragma mark - WPBluetoothManagerDelegate

- (void)didUpdateAlarmCount:(NSInteger)count canUse:(NSInteger)canUse {
    // 更新标题显示闹钟数量
    self.title = [NSString stringWithFormat:@"闹钟 (%ld/%ld)", canUse, count];
}

- (void)didUpdateAlarmInfo:(WPAlarmData *)alarm {
    // 更新本地数组
    if (alarm.alarmId < self.alarms.count) {
        self.alarms[alarm.alarmId] = alarm;
    } else {
        [self.alarms addObject:alarm];
    }

    // 刷新列表
    [self.tableView reloadData];
}

@end
```

### 提醒设置页面示例

```objc
@interface ReminderSettingsViewController () <WPBluetoothManagerDelegate>
@property (weak, nonatomic) IBOutlet UISwitch *longSitSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *drinkWaterSwitch;
@end

@implementation ReminderSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [WPBluetoothManager sharedInstance].delegate = self;

    // 加载当前设置
    [self loadCurrentSettings];
}

- (void)loadCurrentSettings {
    [[WPBluetoothManager sharedInstance] queryLongSitReminder:nil];
    [[WPBluetoothManager sharedInstance] queryDrinkWaterReminder:nil];
}

- (IBAction)longSitSwitchChanged:(UISwitch *)sender {
    if (sender.on) {
        [[WPBluetoothManager sharedInstance] enableLongSitReminderWithCompletion:^(BOOL success, NSError *error) {
            if (!success) {
                sender.on = NO;
                [self showError:error.localizedDescription];
            }
        }];
    } else {
        [[WPBluetoothManager sharedInstance] disableLongSitReminderWithCompletion:^(BOOL success, NSError *error) {
            if (!success) {
                sender.on = YES;
                [self showError:error.localizedDescription];
            }
        }];
    }
}

- (IBAction)drinkWaterSwitchChanged:(UISwitch *)sender {
    if (sender.on) {
        [[WPBluetoothManager sharedInstance] enableDrinkWaterReminderWithCompletion:^(BOOL success, NSError *error) {
            if (!success) {
                sender.on = NO;
                [self showError:error.localizedDescription];
            }
        }];
    } else {
        [[WPBluetoothManager sharedInstance] disableDrinkWaterReminderWithCompletion:^(BOOL success, NSError *error) {
            if (!success) {
                sender.on = YES;
                [self showError:error.localizedDescription];
            }
        }];
    }
}

#pragma mark - WPBluetoothManagerDelegate

- (void)didUpdateLongSitReminder:(WPReminderInfo *)reminder {
    self.longSitSwitch.on = reminder.enabled;
}

- (void)didUpdateDrinkWaterReminder:(WPReminderInfo *)reminder {
    self.drinkWaterSwitch.on = reminder.enabled;
}

@end
```

---

## 注意事项

### 1. 设备连接

所有功能都需要设备已连接，否则会返回错误：

```objc
NSError *error = [NSError errorWithDomain:@"..."
                                     code:XXX
                                 userInfo:@{NSLocalizedDescriptionKey: @"设备未连接，请先连接设备"}];
```

### 2. 参数验证

时间参数会自动验证：
- 小时：0-23
- 分钟：0-59
- 间隔：必须 >= 0

### 3. 异步回调

所有完成回调都在主线程执行，可以直接更新 UI。

### 4. 代理回调

代理方法会在设备返回数据后自动调用，同时会更新 `currentDevice` 的相应属性。

---

## 架构说明

本实现参考了抬手亮屏功能的封装方式，采用三层架构：

1. **WPCommands Category 层**
   - `WPCommands+Alarm` - 闹钟指令封装
   - `WPCommands+Reminder` - 提醒指令封装
   - 负责构建和发送蓝牙指令

2. **WPBluetoothManager 便捷方法层**
   - 提供简洁的 API 接口
   - 转发到 Category 层
   - 统一的错误处理

3. **代理回调层**
   - `WPBluetoothManagerDelegate` 协议
   - 自动解析设备响应
   - 更新 `currentDevice` 模型

---

## 更新日志

### v2.0.11 (2026-01-30)

- ✨ 新增 `WPCommands+Alarm` Category - 闹钟功能完整支持
- ✨ 新增 `WPCommands+Reminder` Category - 久坐/喝水提醒功能
- ✨ 在 `WPBluetoothManager` 中添加便捷方法
- 📝 添加完整的使用文档和示例代码
- 🎨 采用与抬手亮屏一致的 API 设计风格
