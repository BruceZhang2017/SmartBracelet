# WatchProtocolSDK 自动重连使用指南

## 🆕 v2.0.2 新增功能

本版本新增了支持 **App 重启后自动回连** 的功能，提供了多种便捷的重连方法。

---

## 📋 使用场景

### 场景 1：App 运行时设备意外断开
- SDK 会自动保留 `currentDevice`
- 可直接调用 `reconnectToDevice` 进行重连

### 场景 2：App 完全重启后需要重连
- App 重启后 `currentDevice` 会被清空
- **需要使用新的 API** 传入设备信息进行重连

---

## 🔧 新增 API

### 1. 使用设备对象进行重连

```objc
/**
 * 使用指定设备进行自动重连
 * @param device 要重连的设备对象
 */
- (void)reconnectWithDevice:(WPBluetoothWatchDevice *)device;

/**
 * 使用指定设备进行自动重连（带超时时间）
 * @param device 要重连的设备对象
 * @param timeout 扫描超时时间（秒），0 或负数表示不限时
 */
- (void)reconnectWithDevice:(WPBluetoothWatchDevice *)device timeout:(NSTimeInterval)timeout;
```

### 2. 从沙盒恢复设备并重连（推荐）

```objc
/**
 * 从沙盒恢复设备并自动重连
 * @param macAddress 设备的 MAC 地址
 * @return 是否成功恢复并启动重连（如果沙盒中没有该设备信息，返回 NO）
 */
- (BOOL)reconnectFromSandboxWithMac:(NSString *)macAddress;

/**
 * 从沙盒恢复设备并自动重连（带超时时间）
 * @param macAddress 设备的 MAC 地址
 * @param timeout 扫描超时时间（秒），0 或负数表示不限时
 * @return 是否成功恢复并启动重连（如果沙盒中没有该设备信息，返回 NO）
 */
- (BOOL)reconnectFromSandboxWithMac:(NSString *)macAddress timeout:(NSTimeInterval)timeout;
```

---

## 💡 使用示例

### 示例 1：方案一 - 使用沙盒自动恢复（推荐 ⭐️）

这是**最简单**的方式，SDK 会自动从沙盒读取设备信息。

```objc
// 在 AppDelegate.m 的 application:didFinishLaunchingWithOptions: 中

#import "WPBluetoothManager.h"

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // 1. 初始化蓝牙管理器
    [[WPBluetoothManager sharedInstance] initCentral];

    // 2. 从本地存储读取上次连接的设备 MAC 地址
    NSString *lastConnectedMac = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastConnectedDeviceMac"];

    if (lastConnectedMac) {
        // 3. 等待蓝牙就绪后，使用沙盒恢复并重连
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            BOOL success = [[WPBluetoothManager sharedInstance] reconnectFromSandboxWithMac:lastConnectedMac
                                                                                     timeout:15.0];
            if (success) {
                NSLog(@"✅ 正在尝试自动重连设备: %@", lastConnectedMac);
            } else {
                NSLog(@"⚠️ 沙盒中没有该设备信息，请先手动连接一次");
            }
        });
    }

    return YES;
}
```

**要点说明**：
- SDK 在设备首次连接成功时，会自动调用 `[WPBluetoothWatchDevice saveToSandbox:device]` 保存设备信息
- App 重启后，只需要保存上次连接的 MAC 地址，然后调用 `reconnectFromSandboxWithMac:` 即可
- SDK 会自动从沙盒加载完整的设备信息并发起重连

### 示例 2：方案二 - 手动传入设备对象

如果您自己管理了设备信息的存储，可以手动传入设备对象。

```objc
// 在 AppDelegate.m 中

#import "WPBluetoothManager.h"
#import "WPDeviceModel.h"

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // 1. 初始化蓝牙管理器
    [[WPBluetoothManager sharedInstance] initCentral];

    // 2. 从您自己的存储读取设备信息
    WPBluetoothWatchDevice *lastDevice = [self loadLastDeviceFromYourStorage];

    if (lastDevice) {
        // 3. 等待蓝牙就绪后，使用设备对象进行重连
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[WPBluetoothManager sharedInstance] reconnectWithDevice:lastDevice timeout:15.0];
            NSLog(@"✅ 正在尝试自动重连设备: %@", lastDevice.deviceName);
        });
    }

    return YES;
}

// 您自己的设备信息加载方法示例
- (WPBluetoothWatchDevice *)loadLastDeviceFromYourStorage {
    // 从 UserDefaults、数据库或其他存储读取设备信息
    NSString *mac = [[NSUserDefaults standardUserDefaults] objectForKey:@"device_mac"];
    NSString *name = [[NSUserDefaults standardUserDefaults] objectForKey:@"device_name"];

    if (!mac) return nil;

    WPBluetoothWatchDevice *device = [[WPBluetoothWatchDevice alloc] init];
    device.mac = mac;
    device.deviceName = name;

    return device;
}
```

### 示例 3：保存设备 MAC 地址以便下次重连

```objc
// 在设备连接成功的回调中保存 MAC 地址

- (void)didConnectPeripheral:(WPPeripheralInfo *)peripheralInfo {
    NSLog(@"✅ 设备连接成功: %@", peripheralInfo.peripheral.name);

    // 保存 MAC 地址，用于 App 重启后自动重连
    [[NSUserDefaults standardUserDefaults] setObject:peripheralInfo.macAddress
                                               forKey:@"LastConnectedDeviceMac"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
```

---

## 📊 重连流程对比

### ❌ 旧方式（v2.0.1 及之前）

```
App 启动
  ↓
currentDevice = nil（因为重启）
  ↓
调用 reconnectToDevice
  ↓
❌ 失败（因为 currentDevice 为空）
  ↓
需要手动重新扫描和连接
```

### ✅ 新方式（v2.0.2）

```
App 启动
  ↓
从 UserDefaults 读取上次连接的 MAC
  ↓
调用 reconnectFromSandboxWithMac:
  ↓
SDK 自动从沙盒恢复设备信息
  ↓
设置 currentDevice 并启动扫描连接
  ↓
✅ 自动重连成功
```

---

## ⚙️ 参数说明

### timeout（超时时间）

- **默认值**：10 秒（不带 timeout 参数的方法）
- **推荐值**：10-15 秒
- **说明**：
  - 如果在指定时间内未扫描到目标设备，会触发 `didScanTimeout:` 回调
  - 设置为 0 或负数表示不限时扫描（不推荐）

### macAddress（MAC 地址）

- **格式**：大小写均可，SDK 内部会自动转换为大写
- **示例**：
  - `"AA:BB:CC:DD:EE:FF"` ✅
  - `"aa:bb:cc:dd:ee:ff"` ✅
  - `"AABBCCDDEEFF"` ✅（不带冒号）

---

## 🔔 回调说明

### 扫描超时回调（新增 v2.0.2）

如果在超时时间内未找到目标设备，会触发此回调：

```objc
- (void)didScanTimeout:(NSString *)macAddress {
    NSLog(@"⚠️ 扫描超时，未找到设备: %@", macAddress);

    // 可选：提示用户重试或手动连接
    [self showRetryAlert];
}
```

### 连接成功回调

```objc
- (void)didConnectPeripheral:(WPPeripheralInfo *)peripheralInfo {
    NSLog(@"✅ 自动重连成功: %@", peripheralInfo.peripheral.name);

    // 设备已连接，可以开始使用
}
```

### 连接失败回调

```objc
- (void)didDisconnectPeripheral:(WPPeripheralInfo *)peripheralInfo error:(NSError *)error {
    if (error) {
        NSLog(@"❌ 自动重连失败: %@", error.localizedDescription);

        // 可选：延迟后重试
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[WPBluetoothManager sharedInstance] reconnectToDevice];
        });
    }
}
```

---

## ⚠️ 注意事项

1. **蓝牙权限**
   - 确保在 `Info.plist` 中添加了蓝牙权限说明
   - 用户首次使用需要授权蓝牙访问

2. **延迟调用**
   - 建议在 App 启动后延迟 1 秒再调用重连方法
   - 确保蓝牙中心管理器已完全初始化

3. **设备信息保存**
   - SDK 会在设备首次连接成功时自动保存到沙盒
   - 您只需要保存 MAC 地址即可（推荐使用 `UserDefaults`）

4. **错误处理**
   - 检查 `reconnectFromSandboxWithMac:` 的返回值
   - 如果返回 `NO`，说明沙盒中没有该设备信息，需要引导用户手动连接一次

5. **超时时间设置**
   - 建议设置合理的超时时间（10-15秒）
   - 避免无限扫描导致的电量消耗

---

## 🎯 最佳实践

### 推荐流程

```objc
// 1. App 启动时
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[WPBluetoothManager sharedInstance] initCentral];
    [[WPBluetoothManager sharedInstance] setDelegate:self];

    // 延迟后尝试自动重连
    [self performSelector:@selector(autoReconnectIfNeeded) withObject:nil afterDelay:1.0];

    return YES;
}

// 2. 自动重连逻辑
- (void)autoReconnectIfNeeded {
    NSString *lastMac = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastConnectedDeviceMac"];

    if (lastMac) {
        BOOL success = [[WPBluetoothManager sharedInstance] reconnectFromSandboxWithMac:lastMac timeout:15.0];
        if (!success) {
            NSLog(@"⚠️ 需要手动连接设备");
            // 显示设备列表让用户选择
        }
    }
}

// 3. 设备连接成功时保存 MAC
- (void)didConnectPeripheral:(WPPeripheralInfo *)peripheralInfo {
    // 保存 MAC 用于下次自动重连
    [[NSUserDefaults standardUserDefaults] setObject:peripheralInfo.macAddress forKey:@"LastConnectedDeviceMac"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// 4. 主动断开时清除记录
- (void)userDidLogoutOrUnpairDevice {
    // 清除保存的 MAC，避免下次自动重连
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"LastConnectedDeviceMac"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    // 断开连接
    [[WPBluetoothManager sharedInstance] disconnect];
}
```

---

## 📞 技术支持

如有问题，请联系技术支持或查看完整 API 文档。

---

**版本**: v2.0.2
**更新日期**: 2026-01-21
