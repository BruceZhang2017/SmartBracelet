# WPCommands+RaiseToWake 使用示例

## 📱 Swift 参考示例

参考 `DeviceSettingsViewController.swift:396` 中的开关切换处理：

```swift
@objc func switchValueChanged(_ sender: UISwitch) {
    let originalRow = sender.tag - 999
    let isSwitchOn = sender.isOn

    switch originalRow {
    case 2: handleRaiseHandScreenSwitch(isSwitchOn)
    // ...
    }
}

private func handleRaiseHandScreenSwitch(_ isOn: Bool) {
    if isXGZT {
        guard let device = XGZTBlueToothManager.shared.device else {
            Toast(text: "mine_unconnect".localized()).show()
            return
        }
        XGZTBlueToothManager.shared.device?.isRaisehandtobrightenscreen = isOn
        XGZTCommand.setSwitchStatus(p0: getXGZTSwitchP0(), p1: getXGZTSwitchP1())
    } else {
        bleSelf.functionSwitchModel.isLightScreen = isOn
        bleSelf.setSwitchForWristband(bleSelf.functionSwitchModel)
    }
}
```

## 🔧 Objective-C 使用示例

### 示例 1：基本使用

```objc
#import <WatchProtocolSDK/WPCommands+RaiseToWake.h>

// 开启抬手亮屏
[WPCommands setRaiseToWake:YES completion:^(BOOL success, NSError *error) {
    if (success) {
        NSLog(@"✅ 抬手亮屏已开启");
    } else {
        NSLog(@"❌ 设置失败: %@", error.localizedDescription);
    }
}];

// 关闭抬手亮屏
[WPCommands setRaiseToWake:NO completion:^(BOOL success, NSError *error) {
    if (success) {
        NSLog(@"✅ 抬手亮屏已关闭");
    } else {
        NSLog(@"❌ 设置失败: %@", error.localizedDescription);
    }
}];
```

### 示例 2：在 UISwitch 中使用

```objc
#import <WatchProtocolSDK/WPCommands+RaiseToWake.h>

@interface DeviceSettingsViewController ()
@property (weak, nonatomic) IBOutlet UISwitch *raiseToWakeSwitch;
@end

@implementation DeviceSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // 设置开关初始状态
    WPBluetoothManager *btManager = [WPBluetoothManager sharedInstance];
    self.raiseToWakeSwitch.on = btManager.currentDevice.isRaiseHandToBrightenScreen;

    // 添加事件监听
    [self.raiseToWakeSwitch addTarget:self
                               action:@selector(raiseToWakeSwitchChanged:)
                     forControlEvents:UIControlEventValueChanged];
}

- (void)raiseToWakeSwitchChanged:(UISwitch *)sender {
    // 发送设置指令
    [WPCommands setRaiseToWake:sender.isOn completion:^(BOOL success, NSError *error) {
        if (!success) {
            // 发送失败，恢复开关状态
            dispatch_async(dispatch_get_main_queue(), ^{
                sender.on = !sender.isOn;

                // 显示错误提示
                UIAlertController *alert = [UIAlertController
                    alertControllerWithTitle:@"设置失败"
                    message:error.localizedDescription
                    preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                                         style:UIAlertActionStyleDefault
                                                       handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
            });
        }
    }];
}

@end
```

### 示例 3：批量设置开关

```objc
#import <WatchProtocolSDK/WPCommands+RaiseToWake.h>

// 批量设置多个功能开关
- (void)configureDeviceDefaults {
    WPBluetoothManager *btManager = [WPBluetoothManager sharedInstance];

    // 确保设备已连接
    if (!btManager.isConnected) {
        NSLog(@"❌ 设备未连接");
        return;
    }

    // 设置 1: 开启抬手亮屏
    [WPCommands setRaiseToWake:YES completion:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"✅ 1/3 抬手亮屏已开启");

            // 设置 2: 开启睡眠监测（需要实现对应的方法）
            // [WPCommands setSleepMonitoring:YES completion:...];

        } else {
            NSLog(@"❌ 抬手亮屏设置失败: %@", error.localizedDescription);
        }
    }];
}
```

### 示例 4：错误处理

```objc
#import <WatchProtocolSDK/WPCommands+RaiseToWake.h>

- (void)setRaiseToWakeWithRetry:(BOOL)enable maxRetries:(NSInteger)maxRetries {
    [self setRaiseToWake:enable retryCount:0 maxRetries:maxRetries];
}

- (void)setRaiseToWake:(BOOL)enable
            retryCount:(NSInteger)retryCount
            maxRetries:(NSInteger)maxRetries {

    [WPCommands setRaiseToWake:enable completion:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"✅ 设置成功");
        } else {
            // 根据错误类型决定是否重试
            NSString *domain = error.domain;
            NSInteger code = error.code;

            if ([domain isEqualToString:@"com.huaxin.watchprotocolsdk.raisetowake"]) {
                switch (code) {
                    case 2001: // 设备未连接
                        NSLog(@"❌ 设备未连接，无法重试");
                        break;

                    case 2002: // 发送失败
                        if (retryCount < maxRetries) {
                            NSLog(@"⚠️ 发送失败，%ld 秒后重试 (%ld/%ld)",
                                  (long)2, (long)retryCount + 1, (long)maxRetries);

                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
                                         dispatch_get_main_queue(), ^{
                                [self setRaiseToWake:enable
                                          retryCount:retryCount + 1
                                          maxRetries:maxRetries];
                            });
                        } else {
                            NSLog(@"❌ 重试次数已达上限，设置失败");
                        }
                        break;

                    case 2003: // 蓝牙未开启
                        NSLog(@"❌ 蓝牙未开启，请先打开蓝牙");
                        break;
                }
            }
        }
    }];
}
```

### 示例 5：查询抬手亮屏状态

```objc
#import <WatchProtocolSDK/WPCommands+RaiseToWake.h>
#import <WatchProtocolSDK/WPBluetoothManager.h>

// 方法 1: 从设备模型读取（推荐 - 立即返回）
- (BOOL)getCurrentRaiseToWakeStatus {
    WPBluetoothManager *btManager = [WPBluetoothManager sharedInstance];
    return btManager.currentDevice.isRaiseHandToBrightenScreen;
}

// 方法 2: 发送查询指令（需要等待设备响应）
- (void)queryRaiseToWakeStatus {
    [WPCommands getRaiseToWakeStatus:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"✅ 查询指令已发送，等待设备响应");
            // 响应数据通过 WPBluetoothManagerDelegate 的 receiveData: 回调接收
        } else {
            NSLog(@"❌ 查询失败: %@", error.localizedDescription);
        }
    }];
}
```

## 📊 完整的设备设置界面示例

```objc
#import <WatchProtocolSDK/WPCommands+RaiseToWake.h>
#import <WatchProtocolSDK/WPBluetoothManager.h>

@interface DeviceSettingsViewController () <WPBluetoothManagerDelegate>
@property (weak, nonatomic) IBOutlet UISwitch *raiseToWakeSwitch;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;
@end

@implementation DeviceSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // 设置蓝牙代理
    [WPBluetoothManager sharedInstance].delegate = self;

    // 初始化 UI
    [self updateUI];
}

- (void)updateUI {
    WPBluetoothManager *btManager = [WPBluetoothManager sharedInstance];

    // 检查连接状态
    BOOL isConnected = btManager.isConnected;
    self.raiseToWakeSwitch.enabled = isConnected;

    if (isConnected && btManager.currentDevice) {
        // 从设备模型读取状态
        self.raiseToWakeSwitch.on = btManager.currentDevice.isRaiseHandToBrightenScreen;
    } else {
        self.raiseToWakeSwitch.on = NO;
    }
}

- (IBAction)raiseToWakeSwitchChanged:(UISwitch *)sender {
    // 显示加载指示器
    [self.loadingIndicator startAnimating];
    sender.enabled = NO;

    // 发送设置指令
    [WPCommands setRaiseToWake:sender.isOn completion:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.loadingIndicator stopAnimating];
            sender.enabled = YES;

            if (!success) {
                // 恢复开关状态
                sender.on = !sender.isOn;

                // 显示错误
                [self showError:error];
            }
        });
    }];
}

- (void)showError:(NSError *)error {
    NSString *message = error.localizedDescription ?: @"未知错误";

    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"设置失败"
        message:message
        preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                             style:UIAlertActionStyleDefault
                                           handler:nil]];

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - WPBluetoothManagerDelegate

- (void)didConnectPeripheral:(WPPeripheralInfo *)peripheralInfo {
    NSLog(@"✅ 设备已连接");
    [self updateUI];
}

- (void)didDisconnectPeripheral:(WPPeripheralInfo *)peripheralInfo error:(NSError *)error {
    NSLog(@"⚠️ 设备已断开");
    [self updateUI];
}

@end
```

## 🔍 调试技巧

### 启用详细日志

```objc
// 查看 WPLogger 输出
// 日志会显示：
// - ✋ 抬手亮屏设置指令已发送: 开启 (p0=0x02, p1=0x00)
// - ❌ 设置抬手亮屏失败: 设备未连接
```

### 检查设备模型状态

```objc
WPBluetoothManager *btManager = [WPBluetoothManager sharedInstance];
WPBluetoothWatchDevice *device = btManager.currentDevice;

NSLog(@"设备状态:");
NSLog(@"  抬手亮屏: %d", device.isRaiseHandToBrightenScreen);
NSLog(@"  睡眠监测: %d", device.isSleepMonitoringSwitch);
NSLog(@"  消息提醒: %d", device.isMessageReminderMainSwitch);
```

## ⚠️ 注意事项

1. **设备必须已连接**：调用前确保 `btManager.isConnected` 为 `YES`
2. **设备模型必须存在**：确保 `btManager.currentDevice` 不为 `nil`
3. **主线程更新 UI**：completion 回调会在主线程执行，可以直接更新 UI
4. **状态同步**：设置成功后，设备模型会自动更新，无需手动同步
5. **其他开关不受影响**：本方法会保护所有其他开关的状态

## 🔗 相关链接

- Swift 参考实现：`DeviceSettingsViewController.swift:436-448`
- 实现说明文档：`WPCommands+RaiseToWake_IMPLEMENTATION_NOTES.md`
- API 文档：`WPCommands+RaiseToWake.h`
