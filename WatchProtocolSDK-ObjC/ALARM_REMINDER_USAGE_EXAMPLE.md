# 闹钟和久坐提醒功能 - 使用示例

## 📱 完整示例代码

### 1. 设置代理

在你的 ViewController 中实现代理方法：

```objc
#import "WPBluetoothManager.h"
#import "WPCommands.h"
#import "WPDeviceModel.h"

@interface YourViewController () <WPBluetoothManagerDelegate>
@end

@implementation YourViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // 设置代理
    [WPBluetoothManager sharedInstance].delegate = self;

    // 注册通知（可选）
    [self registerNotifications];
}

- (void)registerNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(onAlarmUpdated:)
        name:@"WPAlarmUpdated"
        object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(onLongSitReminderUpdated:)
        name:@"WPLongSitReminderUpdated"
        object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(onDrinkWaterReminderUpdated:)
        name:@"WPDrinkWaterReminderUpdated"
        object:nil];
}
```

### 2. 闹钟功能示例

#### 2.1 查询闹钟列表

```objc
- (void)queryAllAlarms {
    // 先查询闹钟总数
    [WPCommands getAlarmInfo:0];
}

// 代理方法：收到闹钟总数
- (void)didUpdateAlarmCount:(NSInteger)count canUse:(NSInteger)canUse {
    NSLog(@"设备支持 %ld 个闹钟，可用 %ld 个", count, canUse);

    // 查询每个闹钟的详细信息
    for (NSInteger i = 1; i <= count; i++) {
        [WPCommands getAlarmInfo:i];
    }
}

// 代理方法：收到闹钟详情
- (void)didUpdateAlarmInfo:(WPAlarmData *)alarm {
    NSLog(@"闹钟 %ld: %02ld:%02ld %@ 重复:0x%02lX",
          alarm.alarmId,
          alarm.hour,
          alarm.minute,
          alarm.enabled ? @"开启" : @"关闭",
          alarm.repeatDays);

    // 更新 UI
    [self updateAlarmUI];
}

// 通知回调
- (void)onAlarmUpdated:(NSNotification *)notification {
    WPAlarmData *alarm = notification.object;
    NSLog(@"闹钟已更新: %ld", alarm.alarmId);
}
```

#### 2.2 设置新闹钟

```objc
- (void)setMorningAlarm {
    // 创建闹钟：每天早上 7:30
    WPAlarmData *alarm = [[WPAlarmData alloc] init];
    alarm.alarmId = 0;          // 闹钟索引 0-7
    alarm.enabled = YES;         // 启用
    alarm.hour = 7;             // 7点
    alarm.minute = 30;          // 30分
    alarm.repeatDays = 0x7F;    // 每天 (周一到周日)

    // 发送设置指令
    [WPCommands setAlarmInfo:0x01 alarm:alarm];

    NSLog(@"已设置早晨闹钟：7:30 每天");
}

- (void)setWorkdayAlarm {
    // 创建闹钟：工作日早上 6:30
    WPAlarmData *alarm = [[WPAlarmData alloc] init];
    alarm.alarmId = 1;
    alarm.enabled = YES;
    alarm.hour = 6;
    alarm.minute = 30;
    alarm.repeatDays = 0x1F;    // 工作日 (周一到周五)

    [WPCommands setAlarmInfo:0x01 alarm:alarm];

    NSLog(@"已设置工作日闹钟：6:30 周一到周五");
}

- (void)setWeekendAlarm {
    // 创建闹钟：周末早上 9:00
    WPAlarmData *alarm = [[WPAlarmData alloc] init];
    alarm.alarmId = 2;
    alarm.enabled = YES;
    alarm.hour = 9;
    alarm.minute = 0;
    alarm.repeatDays = 0x60;    // 周末 (周六周日)

    [WPCommands setAlarmInfo:0x01 alarm:alarm];

    NSLog(@"已设置周末闹钟：9:00 周六周日");
}
```

#### 2.3 开启/关闭闹钟

```objc
- (void)toggleAlarm:(WPAlarmData *)alarm {
    // 切换开关状态
    alarm.enabled = !alarm.enabled;

    // 发送更新指令
    [WPCommands setAlarmInfo:0x01 alarm:alarm];

    NSLog(@"闹钟 %ld 已%@", alarm.alarmId, alarm.enabled ? @"开启" : @"关闭");
}
```

#### 2.4 删除闹钟

```objc
- (void)deleteAlarm:(NSInteger)alarmId {
    // 创建一个禁用的闹钟来"删除"
    WPAlarmData *alarm = [[WPAlarmData alloc] init];
    alarm.alarmId = alarmId;
    alarm.enabled = NO;
    alarm.hour = 0;
    alarm.minute = 0;
    alarm.repeatDays = 0;

    [WPCommands setAlarmInfo:0x01 alarm:alarm];

    NSLog(@"已删除闹钟 %ld", alarmId);
}
```

### 3. 久坐提醒功能示例

#### 3.1 查询久坐提醒设置

```objc
- (void)queryLongSitReminder {
    // 查询久坐提醒（eventType=0）
    [WPCommands getReminderInfo:0];
}

// 代理方法：收到久坐提醒信息
- (void)didUpdateLongSitReminder:(WPReminderInfo *)reminder {
    NSLog(@"久坐提醒: %@ 时间段 %02ld:%02ld - %02ld:%02ld 间隔 %ld 分钟",
          reminder.enabled ? @"开启" : @"关闭",
          reminder.startHour,
          reminder.startMinute,
          reminder.endHour,
          reminder.endMinute,
          reminder.interval);

    // 更新 UI
    [self updateLongSitReminderUI];
}

// 通知回调
- (void)onLongSitReminderUpdated:(NSNotification *)notification {
    WPReminderInfo *reminder = notification.object;
    NSLog(@"久坐提醒已更新");
}
```

#### 3.2 设置久坐提醒

```objc
- (void)enableLongSitReminder {
    // 创建久坐提醒：工作日 9:00-18:00，每60分钟提醒一次
    WPReminderInfoResponse *reminder = [[WPReminderInfoResponse alloc] init];
    reminder.eventType = 0;        // 0 = 久坐提醒
    reminder.cycle = 0x1F;         // 工作日（周一到周五）
    reminder.startHour = 9;        // 开始时间 9:00
    reminder.startMinute = 0;
    reminder.endHour = 18;         // 结束时间 18:00
    reminder.endMinute = 0;
    reminder.period = 60;          // 每60分钟提醒一次

    [WPCommands setReminderInfo:reminder];

    NSLog(@"已设置久坐提醒：9:00-18:00 每60分钟");
}

- (void)disableLongSitReminder {
    // 关闭久坐提醒
    WPReminderInfoResponse *reminder = [[WPReminderInfoResponse alloc] init];
    reminder.eventType = 0;
    reminder.cycle = 0;            // 周期为 0 表示关闭
    reminder.startHour = 0;
    reminder.startMinute = 0;
    reminder.endHour = 0;
    reminder.endMinute = 0;
    reminder.period = 0;

    [WPCommands setReminderInfo:reminder];

    NSLog(@"已关闭久坐提醒");
}
```

### 4. 喝水提醒功能示例

#### 4.1 查询喝水提醒设置

```objc
- (void)queryDrinkWaterReminder {
    // 查询喝水提醒（eventType=1）
    [WPCommands getReminderInfo:1];
}

// 代理方法：收到喝水提醒信息
- (void)didUpdateDrinkWaterReminder:(WPReminderInfo *)reminder {
    NSLog(@"喝水提醒: %@ 时间段 %02ld:%02ld - %02ld:%02ld 间隔 %ld 分钟",
          reminder.enabled ? @"开启" : @"关闭",
          reminder.startHour,
          reminder.startMinute,
          reminder.endHour,
          reminder.endMinute,
          reminder.interval);

    // 更新 UI
    [self updateDrinkWaterReminderUI];
}

// 通知回调
- (void)onDrinkWaterReminderUpdated:(NSNotification *)notification {
    WPReminderInfo *reminder = notification.object;
    NSLog(@"喝水提醒已更新");
}
```

#### 4.2 设置喝水提醒

```objc
- (void)enableDrinkWaterReminder {
    // 创建喝水提醒：每天 8:00-22:00，每2小时提醒一次
    WPReminderInfoResponse *reminder = [[WPReminderInfoResponse alloc] init];
    reminder.eventType = 1;        // 1 = 喝水提醒
    reminder.cycle = 0x7F;         // 每天（周一到周日）
    reminder.startHour = 8;        // 开始时间 8:00
    reminder.startMinute = 0;
    reminder.endHour = 22;         // 结束时间 22:00
    reminder.endMinute = 0;
    reminder.period = 120;         // 每120分钟（2小时）提醒一次

    [WPCommands setReminderInfo:reminder];

    NSLog(@"已设置喝水提醒：8:00-22:00 每2小时");
}

- (void)disableDrinkWaterReminder {
    // 关闭喝水提醒
    WPReminderInfoResponse *reminder = [[WPReminderInfoResponse alloc] init];
    reminder.eventType = 1;
    reminder.cycle = 0;
    reminder.startHour = 0;
    reminder.startMinute = 0;
    reminder.endHour = 0;
    reminder.endMinute = 0;
    reminder.period = 0;

    [WPCommands setReminderInfo:reminder];

    NSLog(@"已关闭喝水提醒");
}
```

### 5. UI 界面示例

#### 5.1 闹钟列表界面

```objc
- (void)updateAlarmUI {
    WPBluetoothWatchDevice *device = [WPBluetoothManager sharedInstance].currentDevice;

    // 清空列表
    [self.alarms removeAllObjects];

    // 获取所有闹钟
    for (WPAlarmData *alarm in device.alarms) {
        [self.alarms addObject:alarm];
    }

    // 刷新 TableView
    [self.tableView reloadData];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AlarmCell"];

    WPAlarmData *alarm = self.alarms[indexPath.row];

    // 显示时间
    cell.textLabel.text = [NSString stringWithFormat:@"%02ld:%02ld", alarm.hour, alarm.minute];

    // 显示重复周期
    cell.detailTextLabel.text = [self formatRepeatDays:alarm.repeatDays];

    // 显示开关状态
    UISwitch *switchView = [[UISwitch alloc] init];
    switchView.on = alarm.enabled;
    switchView.tag = indexPath.row;
    [switchView addTarget:self action:@selector(alarmSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = switchView;

    return cell;
}

- (void)alarmSwitchChanged:(UISwitch *)sender {
    WPAlarmData *alarm = self.alarms[sender.tag];
    [self toggleAlarm:alarm];
}

- (NSString *)formatRepeatDays:(NSInteger)repeatDays {
    if (repeatDays == 0) return @"仅一次";
    if (repeatDays == 0x7F) return @"每天";
    if (repeatDays == 0x1F) return @"工作日";
    if (repeatDays == 0x60) return @"周末";

    NSMutableArray *days = [NSMutableArray array];
    NSArray *dayNames = @[@"一", @"二", @"三", @"四", @"五", @"六", @"日"];

    for (int i = 0; i < 7; i++) {
        if ((repeatDays >> i) & 1) {
            [days addObject:dayNames[i]];
        }
    }

    return [NSString stringWithFormat:@"周%@", [days componentsJoinedByString:@","]];
}
```

#### 5.2 提醒设置界面

```objc
- (void)updateLongSitReminderUI {
    WPBluetoothWatchDevice *device = [WPBluetoothManager sharedInstance].currentDevice;
    WPReminderInfo *reminder = device.longSit;

    if (reminder) {
        self.longSitSwitch.on = reminder.enabled;
        self.longSitStartTimeLabel.text = [NSString stringWithFormat:@"%02ld:%02ld",
            reminder.startHour, reminder.startMinute];
        self.longSitEndTimeLabel.text = [NSString stringWithFormat:@"%02ld:%02ld",
            reminder.endHour, reminder.endMinute];
        self.longSitIntervalLabel.text = [NSString stringWithFormat:@"%ld 分钟", reminder.interval];
    }
}

- (void)updateDrinkWaterReminderUI {
    WPBluetoothWatchDevice *device = [WPBluetoothManager sharedInstance].currentDevice;
    WPReminderInfo *reminder = device.drinkWater;

    if (reminder) {
        self.drinkWaterSwitch.on = reminder.enabled;
        self.drinkWaterStartTimeLabel.text = [NSString stringWithFormat:@"%02ld:%02ld",
            reminder.startHour, reminder.startMinute];
        self.drinkWaterEndTimeLabel.text = [NSString stringWithFormat:@"%02ld:%02ld",
            reminder.endHour, reminder.endMinute];
        self.drinkWaterIntervalLabel.text = [NSString stringWithFormat:@"%ld 分钟", reminder.interval];
    }
}
```

### 6. 完整工作流程

```objc
- (void)setupAlarmsAndReminders {
    // 1. 查询闹钟列表
    [self queryAllAlarms];

    // 2. 查询久坐提醒
    [self queryLongSitReminder];

    // 3. 查询喝水提醒
    [self queryDrinkWaterReminder];
}

- (void)onDeviceConnected {
    // 设备连接成功后，查询所有设置
    [self setupAlarmsAndReminders];
}
```

### 7. 常用工具方法

```objc
// 周期位图转换
+ (NSInteger)repeatDaysFromWeekdays:(NSArray<NSNumber *> *)weekdays {
    NSInteger repeatDays = 0;
    for (NSNumber *day in weekdays) {
        // day: 1=周一, 2=周二, ..., 7=周日
        if (day.integerValue >= 1 && day.integerValue <= 7) {
            repeatDays |= (1 << (day.integerValue - 1));
        }
    }
    return repeatDays;
}

// 示例：设置周一、周三、周五的闹钟
- (void)setCustomAlarm {
    NSArray *weekdays = @[@1, @3, @5];  // 周一、周三、周五
    NSInteger repeatDays = [YourClass repeatDaysFromWeekdays:weekdays];

    WPAlarmData *alarm = [[WPAlarmData alloc] init];
    alarm.alarmId = 3;
    alarm.enabled = YES;
    alarm.hour = 7;
    alarm.minute = 0;
    alarm.repeatDays = repeatDays;

    [WPCommands setAlarmInfo:0x01 alarm:alarm];
}
```

## 📌 重要提示

1. **连接状态检查**：在调用任何指令前，确保设备已连接
   ```objc
   if (![WPBluetoothManager sharedInstance].isConnected) {
       NSLog(@"设备未连接");
       return;
   }
   ```

2. **响应延迟**：设备响应可能需要几百毫秒，不要频繁发送指令

3. **数组索引**：闹钟索引从 0 开始，通常支持 0-7 共 8 个闹钟

4. **周期位图**：
   - bit0 = 周一, bit1 = 周二, ..., bit6 = 周日
   - 0x7F (0b01111111) = 每天
   - 0x1F (0b00011111) = 工作日
   - 0x60 (0b01100000) = 周末

5. **提醒类型**：
   - eventType = 0：久坐提醒
   - eventType = 1：喝水提醒

## 🔔 通知名称

```objc
@"WPAlarmUpdated"              // 闹钟更新
@"Alarm"                       // 闹钟更新（通用）
@"WPLongSitReminderUpdated"    // 久坐提醒更新
@"XGZTBusinessHandler"         // 业务处理通知（object: @"13" 或 @"14"）
@"WPDrinkWaterReminderUpdated" // 喝水提醒更新
@"DeviceSettings"              // 设备设置更新（object: @1）
```

---

**版本**: v2.0.11+
**更新**: 2026-01-30
