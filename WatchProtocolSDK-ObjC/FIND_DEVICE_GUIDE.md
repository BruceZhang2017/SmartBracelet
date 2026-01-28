# 查找设备功能使用指南

## 📖 简介

`WPCommands+FindDevice` 是 WatchProtocolSDK v2.0.7+ 提供的智能查找设备功能增强扩展。它为原有的 `findBand` 方法添加了完成回调、状态管理、自动停止等实用功能，极大提升了第三方开发者的使用体验。

## ✨ 新增功能

| 功能 | 说明 | 优势 |
|------|------|------|
| ✅ **完成回调** | 指令发送结果实时反馈 | 可在 UI 上提示用户操作结果 |
| ✅ **主动停止** | 随时停止手环震动/响铃 | 找到设备后立即停止，提升体验 |
| ✅ **自动停止** | 指定时长后自动停止 | 避免手环长时间震动耗电 |
| ✅ **状态检查** | 查询是否正在查找中 | 防止重复点击，动态更新 UI |
| ✅ **错误处理** | 自动检查连接状态 | 避免无效指令发送 |

---

## 🚀 快速开始

### 基础用法

```objc
#import <WatchProtocolSDK/WatchProtocolSDK.h>

// 1. 最简单的用法：查找手环
[WPCommands findBandWithCompletion:^(BOOL success, NSError *error) {
    if (success) {
        NSLog(@"✅ 手环正在震动，请留意周围");
    } else {
        NSLog(@"❌ 查找失败: %@", error.localizedDescription);
    }
}];

// 2. 用户找到设备后，停止震动
[WPCommands stopFindBandWithCompletion:^(BOOL success, NSError *error) {
    if (success) {
        NSLog(@"⏹ 已停止查找");
    }
}];
```

### 自动停止用法

```objc
// 查找 5 秒后自动停止
[WPCommands findBandWithDuration:5.0 completion:^(BOOL success, NSError *error) {
    if (success) {
        NSLog(@"查找已自动结束");
    } else {
        NSLog(@"查找失败: %@", error.localizedDescription);
    }
}];
```

---

## 📱 完整示例：查找设备页面

### ViewController.h

```objc
#import <UIKit/UIKit.h>

@interface FindDeviceViewController : UIViewController

@end
```

### ViewController.m

```objc
#import "FindDeviceViewController.h"
#import <WatchProtocolSDK/WatchProtocolSDK.h>

@interface FindDeviceViewController ()

@property (nonatomic, weak) IBOutlet UIButton *findButton;
@property (nonatomic, weak) IBOutlet UILabel *statusLabel;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

@implementation FindDeviceViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"查找设备";

    // 初始化 UI
    [self updateUI];
}

- (void)dealloc {
    // 页面销毁时取消所有查找任务
    [WPCommands cancelAllFindTasks];
}

// MARK: - 按钮点击事件

- (IBAction)findButtonTapped:(id)sender {
    if ([WPCommands isFindingDevice]) {
        // 正在查找中，点击停止
        [self stopFinding];
    } else {
        // 未在查找中，点击开始查找
        [self startFinding];
    }
}

// MARK: - 查找操作

- (void)startFinding {
    // 显示加载状态
    [self.activityIndicator startAnimating];
    self.findButton.enabled = NO;
    self.statusLabel.text = @"正在发送指令...";

    // 查找 10 秒后自动停止
    [WPCommands findBandWithDuration:10.0 completion:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.activityIndicator stopAnimating];
            self.findButton.enabled = YES;

            if (success) {
                // 查找成功（10秒后自动停止）
                self.statusLabel.text = @"查找已结束";
                [self showToast:@"已停止查找"];
            } else {
                // 查找失败
                self.statusLabel.text = error.localizedDescription;
                [self showError:error.localizedDescription];
            }

            [self updateUI];
        });
    }];

    // 立即更新 UI（开始查找）
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.activityIndicator stopAnimating];
        self.findButton.enabled = YES;

        if ([WPCommands isFindingDevice]) {
            self.statusLabel.text = @"手环正在震动，请留意周围 (10秒后自动停止)";
            [self updateUI];
        }
    });
}

- (void)stopFinding {
    // 显示加载状态
    [self.activityIndicator startAnimating];
    self.findButton.enabled = NO;
    self.statusLabel.text = @"正在停止...";

    [WPCommands stopFindBandWithCompletion:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.activityIndicator stopAnimating];
            self.findButton.enabled = YES;

            if (success) {
                self.statusLabel.text = @"已停止查找";
            } else {
                self.statusLabel.text = error.localizedDescription;
            }

            [self updateUI];
        });
    }];
}

// MARK: - UI 更新

- (void)updateUI {
    if ([WPCommands isFindingDevice]) {
        // 正在查找中
        [self.findButton setTitle:@"停止查找" forState:UIControlStateNormal];
        self.findButton.backgroundColor = [UIColor redColor];
    } else {
        // 未在查找中
        [self.findButton setTitle:@"查找设备" forState:UIControlStateNormal];
        self.findButton.backgroundColor = [UIColor systemBlueColor];
    }
}

// MARK: - 提示方法

- (void)showToast:(NSString *)message {
    // TODO: 显示 Toast 提示
    NSLog(@"Toast: %@", message);
}

- (void)showError:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"错误"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                             style:UIAlertActionStyleDefault
                                           handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
```

---

## 🎯 使用场景示例

### 场景 1：设备列表页的快捷查找

```objc
// 在设备列表的每一行添加"查找"按钮
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DeviceCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DeviceCell"];
    WPBluetoothWatchDevice *device = self.devices[indexPath.row];

    cell.deviceNameLabel.text = device.deviceName;

    // 查找按钮点击
    cell.findButtonHandler = ^{
        // 先连接设备，再查找
        [[WPBluetoothManager sharedInstance] connectToDeviceWithMac:device.mac];

        // 等待连接成功后查找（2秒延迟）
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [WPCommands findBandWithDuration:5.0 completion:^(BOOL success, NSError *error) {
                if (success) {
                    NSLog(@"查找完成");
                }
            }];
        });
    };

    return cell;
}
```

### 场景 2：设置页的防丢功能

```objc
@interface SettingsViewController ()
@property (nonatomic, weak) IBOutlet UISwitch *antiLostSwitch;
@end

@implementation SettingsViewController

- (IBAction)antiLostSwitchChanged:(UISwitch *)sender {
    if (sender.isOn) {
        // 开启防丢：每隔30秒检查一次连接，断开时震动
        [self startAntiLostMonitoring];
    } else {
        // 关闭防丢
        [self stopAntiLostMonitoring];
    }
}

- (void)startAntiLostMonitoring {
    // 监听蓝牙断开事件
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceDisconnected:)
                                                 name:@"WPDeviceDisconnected"
                                               object:nil];
}

- (void)deviceDisconnected:(NSNotification *)notification {
    // 设备断开时，如果用户还在附近，让手环震动提醒
    [WPCommands findBandWithDuration:3.0 completion:nil];
}

@end
```

### 场景 3：调试工具页

```objc
- (IBAction)testFindFeature:(id)sender {
    // 测试查找功能是否正常
    [WPCommands findBandWithCompletion:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"✅ 查找功能正常");

            // 3秒后自动停止
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [WPCommands stopFindBandWithCompletion:^(BOOL stopSuccess, NSError *stopError) {
                    if (stopSuccess) {
                        NSLog(@"✅ 停止功能正常");
                    }
                }];
            });
        } else {
            NSLog(@"❌ 查找功能异常: %@", error);
        }
    }];
}
```

---

## ⚠️ 注意事项

### 1. 连接状态检查

方法内部会自动检查设备连接状态，无需手动检查：

```objc
// ✅ 推荐：直接调用，SDK 会自动检查
[WPCommands findBandWithCompletion:^(BOOL success, NSError *error) {
    if (!success) {
        // 处理错误（可能是设备未连接）
        NSLog(@"%@", error.localizedDescription);
    }
}];

// ❌ 不推荐：重复检查
if ([[WPBluetoothManager sharedInstance] isConnected]) {
    [WPCommands findBandWithCompletion:nil];
}
```

### 2. 重复调用保护

SDK 会自动忽略重复的查找请求：

```objc
// 快速点击两次，第二次会被自动忽略
[WPCommands findBandWithCompletion:nil];
[WPCommands findBandWithCompletion:nil];  // 自动忽略
```

### 3. 页面销毁时清理

在页面销毁或应用进入后台时，建议清理查找任务：

```objc
- (void)dealloc {
    [WPCommands cancelAllFindTasks];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [WPCommands cancelAllFindTasks];
}
```

### 4. 自动停止时长建议

| 场景 | 推荐时长 | 说明 |
|------|----------|------|
| 快速定位 | 3-5 秒 | 适合设备就在附近的情况 |
| 普通查找 | 10-15 秒 | 适合需要仔细寻找的情况 |
| 持续查找 | 0（设备默认） | 让设备自行控制停止时间 |

---

## 🐛 错误处理

### 错误码说明

| 错误码 | 错误域 | 说明 | 处理建议 |
|--------|--------|------|----------|
| 1001 | `com.huaxin.watchprotocolsdk.finddevice` | 设备未连接 | 提示用户先连接设备 |
| 1002 | `com.huaxin.watchprotocolsdk.finddevice` | 指令发送失败 | 重试或检查蓝牙状态 |
| 1003 | `com.huaxin.watchprotocolsdk.finddevice` | 蓝牙未开启 | 引导用户打开蓝牙 |

### 错误处理示例

```objc
[WPCommands findBandWithCompletion:^(BOOL success, NSError *error) {
    if (!success) {
        switch (error.code) {
            case 1001:  // 设备未连接
                [self showAlert:@"请先连接设备"];
                break;

            case 1002:  // 发送失败
                [self showAlert:@"操作失败，请重试"];
                break;

            case 1003:  // 蓝牙未开启
                [self showAlert:@"请先打开蓝牙"];
                break;

            default:
                [self showAlert:error.localizedDescription];
                break;
        }
    }
}];
```

---

## 📚 API 参考

### findBandWithCompletion:

**声明**:
```objc
+ (void)findBandWithCompletion:(nullable WPFindDeviceCompletion)completion;
```

**参数**:
- `completion`: 完成回调，可为 `nil`

**回调参数**:
- `success`: 指令是否发送成功
- `error`: 错误信息（仅当 `success=NO` 时有值）

**说明**:
发送查找指令到手环，让手环震动/响铃。会自动检查蓝牙连接状态。

---

### stopFindBandWithCompletion:

**声明**:
```objc
+ (void)stopFindBandWithCompletion:(nullable WPFindDeviceCompletion)completion;
```

**参数**:
- `completion`: 完成回调，可为 `nil`

**说明**:
主动停止手环震动/响铃。如果未在查找中，直接返回成功。

---

### findBandWithDuration:completion:

**声明**:
```objc
+ (void)findBandWithDuration:(NSTimeInterval)duration
                  completion:(nullable WPFindDeviceCompletion)completion;
```

**参数**:
- `duration`: 持续时间（秒），`<= 0` 表示使用设备默认时长
- `completion`: 完成回调（在自动停止后调用）

**说明**:
查找指定时长后自动停止。如果在自动停止前手动调用 `stopFindBandWithCompletion:`，定时器会被自动取消。

---

### isFindingDevice

**声明**:
```objc
@property (class, nonatomic, readonly) BOOL isFindingDevice;
```

**说明**:
查询是否正在查找设备。可用于动态更新 UI 状态。

---

### cancelAllFindTasks

**声明**:
```objc
+ (void)cancelAllFindTasks;
```

**说明**:
取消所有查找任务，包括自动停止定时器。通常在页面销毁或应用进入后台时调用。

---

## 🔄 兼容性

- **最低支持版本**: WatchProtocolSDK v2.0.7+
- **iOS 版本**: iOS 13.0+
- **向后兼容**: 完全兼容原有的 `findBand` 和 `findPhone` 方法

---

## 📝 更新日志

### v2.0.7 (2026-01-27)

**新增**:
- ✅ `WPCommands+FindDevice` Category
- ✅ 带完成回调的查找方法
- ✅ 主动停止查找功能
- ✅ 自动定时停止功能
- ✅ 查找状态查询属性
- ✅ 完善的错误处理机制

---

## ❓ 常见问题

### Q1: 调用 findBand 后没有反应？

**A**: 请检查以下几点：
1. 设备是否已连接（使用 `isConnected` 属性检查）
2. 蓝牙是否开启
3. 手环电量是否充足
4. 查看日志中的错误信息

### Q2: 如何知道手环是否正在震动？

**A**: 使用 `isFindingDevice` 属性：

```objc
if ([WPCommands isFindingDevice]) {
    NSLog(@"手环正在震动");
}
```

### Q3: 可以自定义震动模式吗？

**A**: 当前协议不支持自定义震动模式，震动模式由手环固件控制。

### Q4: 查找过程中设备断开了怎么办？

**A**: SDK 不会自动处理断开情况。建议监听 `WPBluetoothManagerDelegate` 的 `didDisconnectPeripheral:error:` 方法，手动停止查找：

```objc
- (void)didDisconnectPeripheral:(WPPeripheralInfo *)peripheralInfo error:(NSError *)error {
    [WPCommands cancelAllFindTasks];
}
```

---

## 📞 技术支持

如有问题，请联系技术支持或提交 Issue。
