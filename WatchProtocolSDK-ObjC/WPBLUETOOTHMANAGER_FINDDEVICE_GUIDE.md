# WPBluetoothManager 查找设备功能使用指南

## 📖 简介

从 WatchProtocolSDK v2.0.7 开始，`WPBluetoothManager` 类集成了查找设备功能，提供了更加便捷的实例方法来查找手环。

## 🆚 两种使用方式对比

### 方式 1：通过 WPCommands（类方法）

```objc
#import <WatchProtocolSDK/WatchProtocolSDK.h>

[WPCommands findBandWithCompletion:^(BOOL success, NSError *error) {
    if (success) {
        NSLog(@"✅ 查找成功");
    }
}];
```

### 方式 2：通过 WPBluetoothManager（实例方法）⭐️ 推荐

```objc
#import <WatchProtocolSDK/WatchProtocolSDK.h>

WPBluetoothManager *manager = [WPBluetoothManager sharedInstance];

[manager findDeviceWithCompletion:^(BOOL success, NSError *error) {
    if (success) {
        NSLog(@"✅ 查找成功");
    }
}];
```

## ✨ 为什么推荐使用 WPBluetoothManager？

| 特性 | WPCommands | WPBluetoothManager |
|------|------------|--------------------|
| 代码风格 | 类方法（静态） | 实例方法（面向对象） |
| 一致性 | 独立接口 | ✅ 与其他功能统一（如 `queryBatteryLevel`） |
| 可测试性 | 难以 Mock | ✅ 易于 Mock 和单元测试 |
| 扩展性 | 功能分散 | ✅ 集中管理，便于扩展 |
| 易用性 | 需要记忆多个类 | ✅ 只需使用 `WPBluetoothManager` |

## 🚀 快速开始

### 1. 基础用法

```objc
WPBluetoothManager *manager = [WPBluetoothManager sharedInstance];

// 开始查找
[manager findDeviceWithCompletion:^(BOOL success, NSError *error) {
    if (success) {
        NSLog(@"✅ 手环正在震动");
    } else {
        NSLog(@"❌ 查找失败: %@", error.localizedDescription);
    }
}];

// 停止查找
[manager stopFindDeviceWithCompletion:^(BOOL success, NSError *error) {
    if (success) {
        NSLog(@"⏹ 已停止查找");
    }
}];
```

### 2. 自动停止（推荐）

```objc
WPBluetoothManager *manager = [WPBluetoothManager sharedInstance];

// 查找 5 秒后自动停止
[manager findDeviceWithDuration:5.0 completion:^(BOOL success, NSError *error) {
    if (success) {
        NSLog(@"✅ 查找已自动结束");
    }
}];
```

### 3. 状态查询

```objc
WPBluetoothManager *manager = [WPBluetoothManager sharedInstance];

if (manager.isFindingDevice) {
    NSLog(@"🔍 正在查找中...");
    [self.findButton setTitle:@"停止查找" forState:UIControlStateNormal];
} else {
    NSLog(@"⏹ 未在查找");
    [self.findButton setTitle:@"查找设备" forState:UIControlStateNormal];
}
```

## 📋 完整 API 参考

### findDeviceWithCompletion:

**声明**:
```objc
- (void)findDeviceWithCompletion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion;
```

**参数**:
- `completion`: 完成回调，可为 `nil`
  - `success`: 指令是否发送成功
  - `error`: 错误信息（仅当 `success=NO` 时有值）

**说明**:
发送查找指令到手环，让手环震动/响铃。会自动检查蓝牙连接状态。

---

### stopFindDeviceWithCompletion:

**声明**:
```objc
- (void)stopFindDeviceWithCompletion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion;
```

**参数**:
- `completion`: 完成回调，可为 `nil`

**说明**:
主动停止手环震动/响铃。如果未在查找中，直接返回成功。

---

### findDeviceWithDuration:completion:

**声明**:
```objc
- (void)findDeviceWithDuration:(NSTimeInterval)duration
                    completion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion;
```

**参数**:
- `duration`: 持续时间（秒），`<= 0` 表示使用设备默认时长
- `completion`: 完成回调（在自动停止后调用），可为 `nil`

**说明**:
查找指定时长后自动停止。如果在自动停止前手动调用 `stopFindDeviceWithCompletion:`，定时器会被自动取消。

---

### isFindingDevice

**声明**:
```objc
@property (nonatomic, readonly) BOOL isFindingDevice;
```

**说明**:
查询是否正在查找设备。可用于动态更新 UI 状态。

---

## 🎯 实际应用示例

### 示例 1：智能按钮切换

```objc
- (IBAction)findButtonTapped:(id)sender {
    WPBluetoothManager *manager = [WPBluetoothManager sharedInstance];

    if (manager.isFindingDevice) {
        // 正在查找中，点击停止
        [manager stopFindDeviceWithCompletion:^(BOOL success, NSError *error) {
            if (success) {
                [self updateUI];
            }
        }];
    } else {
        // 未在查找中，点击开始查找（10秒后自动停止）
        [manager findDeviceWithDuration:10.0 completion:^(BOOL success, NSError *error) {
            if (success) {
                [self updateUI];
            } else {
                [self showError:error.localizedDescription];
            }
        }];
    }
}

- (void)updateUI {
    WPBluetoothManager *manager = [WPBluetoothManager sharedInstance];

    if (manager.isFindingDevice) {
        [self.findButton setTitle:@"停止查找" forState:UIControlStateNormal];
        self.findButton.backgroundColor = [UIColor redColor];
        self.statusLabel.text = @"手环正在震动...";
    } else {
        [self.findButton setTitle:@"查找设备" forState:UIControlStateNormal];
        self.findButton.backgroundColor = [UIColor systemBlueColor];
        self.statusLabel.text = @"准备就绪";
    }
}
```

### 示例 2：设备列表快捷查找

```objc
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DeviceCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DeviceCell"];
    WPBluetoothWatchDevice *device = self.devices[indexPath.row];

    cell.deviceNameLabel.text = device.deviceName;

    // 查找按钮点击
    __weak typeof(self) weakSelf = self;
    cell.findButtonHandler = ^{
        [weakSelf findDevice:device];
    };

    return cell;
}

- (void)findDevice:(WPBluetoothWatchDevice *)device {
    WPBluetoothManager *manager = [WPBluetoothManager sharedInstance];

    // 如果未连接，先连接
    if (!manager.isConnected) {
        [manager connectToDeviceWithMac:device.mac];

        // 连接成功后查找（实际应监听 didConnectPeripheral: 代理）
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self performQuickFind];
        });
    } else {
        [self performQuickFind];
    }
}

- (void)performQuickFind {
    WPBluetoothManager *manager = [WPBluetoothManager sharedInstance];

    // 快速查找：5秒后自动停止
    [manager findDeviceWithDuration:5.0 completion:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"✅ 快速查找完成");
        }
    }];
}
```

### 示例 3：完整的错误处理

```objc
- (void)findDeviceWithErrorHandling {
    WPBluetoothManager *manager = [WPBluetoothManager sharedInstance];

    // 1. 检查蓝牙状态
    if (manager.isBluetoothPoweredOff) {
        [self showAlert:@"请先打开蓝牙"];
        return;
    }

    // 2. 检查设备连接状态
    if (!manager.isConnected) {
        [self showAlert:@"请先连接设备"];
        return;
    }

    // 3. 检查查找状态
    if (manager.isFindingDevice) {
        NSLog(@"ℹ️ 已在查找中");
        return;
    }

    // 4. 开始查找
    [manager findDeviceWithDuration:10.0 completion:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"✅ 查找完成");
        } else {
            // 5. 错误处理
            [self handleFindError:error];
        }
    }];
}

- (void)handleFindError:(NSError *)error {
    NSString *errorDomain = @"com.huaxin.watchprotocolsdk.finddevice";

    if ([error.domain isEqualToString:errorDomain]) {
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
}
```

## ⚠️ 注意事项

1. **连接状态检查**
   - SDK 会自动检查设备连接状态，无需手动检查
   - 如果设备未连接，会返回错误

2. **重复调用保护**
   - SDK 会自动忽略重复的查找请求
   - 快速点击不会造成问题

3. **状态管理**
   - 使用 `isFindingDevice` 属性查询当前状态
   - 可用于动态更新 UI（按钮文字、颜色等）

4. **推荐时长**
   - 快速定位：3-5 秒
   - 普通查找：10-15 秒
   - 持续查找：0（设备默认）

5. **生命周期管理**
   - 无需手动清理，SDK 内部管理
   - 页面销毁时会自动取消定时器

## 🔄 迁移指南

如果你之前使用 `WPCommands` 的类方法，迁移到 `WPBluetoothManager` 非常简单：

### 迁移前（v2.0.6 及更早版本）

```objc
[WPCommands findBandWithCompletion:^(BOOL success, NSError *error) {
    // ...
}];

[WPCommands stopFindBandWithCompletion:^(BOOL success, NSError *error) {
    // ...
}];

BOOL isFinding = [WPCommands isFindingDevice];
```

### 迁移后（v2.0.7+）⭐️ 推荐

```objc
WPBluetoothManager *manager = [WPBluetoothManager sharedInstance];

[manager findDeviceWithCompletion:^(BOOL success, NSError *error) {
    // ...
}];

[manager stopFindDeviceWithCompletion:^(BOOL success, NSError *error) {
    // ...
}];

BOOL isFinding = manager.isFindingDevice;
```

## ✅ 兼容性说明

- **v2.0.7+**: 两种方式都可用
  - `WPCommands` 类方法（保持向后兼容）
  - `WPBluetoothManager` 实例方法（推荐使用）

- **v2.0.6 及更早版本**: 仅支持 `WPCommands` 类方法

## 📚 相关文档

- [FIND_DEVICE_GUIDE.md](../Output-ObjC-Dynamic/FIND_DEVICE_GUIDE.md) - WPCommands 查找设备详细指南
- [FindDeviceWithBluetoothManagerExample.m](./Examples/FindDeviceWithBluetoothManagerExample.m) - 完整代码示例
- [WPBluetoothManager.h](./Core/WPBluetoothManager.h) - API 头文件

---

**版本**: v2.0.7+
**更新日期**: 2026-01-27
**作者**: Claude
