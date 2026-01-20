# WPBluetoothManager.currentDevice 使用说明

## 📋 属性定义

```objective-c
@interface WPBluetoothManager : NSObject

// MARK: - 当前设备
@property (nonatomic, strong, nullable) WPBluetoothWatchDevice *currentDevice;

@end
```

**位置**：`WatchProtocolSDK-ObjC/Core/WPBluetoothManager.h:81`

---

## 🎯 作用和设计意图

### 1. 核心作用

`currentDevice` 是一个**公开的、可读写的属性**，用于：

- **存储当前连接的设备信息**
- **支持设备重连功能**
- **提供全局访问当前设备的便捷方式**

### 2. 设计模式

这是一个**可选的便捷属性**，采用"**由第三方开发者管理**"的设计模式：

- ✅ SDK 提供属性定义和使用场景
- ✅ SDK 在重连等场景下读取该属性
- ❌ SDK **不会自动**给该属性赋值
- ✅ 由第三方开发者决定何时赋值

---

## ⏰ 什么时候有值？

### ❌ SDK 不会自动赋值

SDK 内部**不会**在以下场景自动赋值：
- 扫描到设备时
- 连接设备成功时
- 发送/接收数据时

### ✅ 需要手动赋值

第三方开发者需要在**连接成功后手动赋值**：

```objective-c
- (void)didConnectPeripheral:(WPPeripheralInfo *)peripheralInfo {
    // 1. 创建设备对象
    WPBluetoothWatchDevice *device = [WPBluetoothWatchDevice deviceFromPeripheralInfo:peripheralInfo];

    // 2. 保存到沙盒
    [WPBluetoothWatchDevice saveToSandbox:device];

    // 3. 【关键】赋值给 currentDevice
    [WPBluetoothManager sharedInstance].currentDevice = device;

    NSLog(@"✅ 已设置当前设备: %@", device.deviceName);
}
```

### ✅ 何时清空

建议在**断开连接时清空**：

```objective-c
- (void)didDisconnectPeripheral:(WPPeripheralInfo *)peripheralInfo error:(NSError *)error {
    // 清空当前设备
    [WPBluetoothManager sharedInstance].currentDevice = nil;

    NSLog(@"🔌 已清空当前设备");
}
```

---

## 🔄 SDK 内部如何使用？

### 重连功能

SDK 在 `reconnectToDevice` 方法中会使用 `currentDevice`：

```objective-c
// WPBluetoothManager.m:266-271
- (void)reconnectToDevice {
    // 重连逻辑（简化版本）
    if (self.currentDevice && self.currentDevice.mac) {
        [self connectToDeviceWithMac:self.currentDevice.mac];
    }
}
```

**工作原理**：
1. 检查 `currentDevice` 是否存在
2. 如果存在且有 MAC 地址，使用该 MAC 地址重连

---

## 💡 最佳实践

### 推荐做法

```objective-c
@interface MyViewController () <WPBluetoothManagerDelegate>
@end

@implementation MyViewController

// ✅ 连接成功时赋值
- (void)didConnectPeripheral:(WPPeripheralInfo *)peripheralInfo {
    dispatch_async(dispatch_get_main_queue(), ^{
        // 创建并保存设备
        WPBluetoothWatchDevice *device = [WPBluetoothWatchDevice deviceFromPeripheralInfo:peripheralInfo];
        [WPBluetoothWatchDevice saveToSandbox:device];

        // 【关键】设置为当前设备
        [WPBluetoothManager sharedInstance].currentDevice = device;

        // 现在可以使用重连功能了
        NSLog(@"✅ 当前设备已设置，支持重连功能");
    });
}

// ✅ 断开连接时清空
- (void)didDisconnectPeripheral:(WPPeripheralInfo *)peripheralInfo error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        // 清空当前设备
        [WPBluetoothManager sharedInstance].currentDevice = nil;

        NSLog(@"🔌 当前设备已清空");
    });
}

// ✅ 使用重连功能
- (void)handleReconnectButtonTapped {
    if ([WPBluetoothManager sharedInstance].currentDevice) {
        // currentDevice 有值，可以重连
        [[WPBluetoothManager sharedInstance] reconnectToDevice];
        NSLog(@"🔄 正在重连到: %@", [WPBluetoothManager sharedInstance].currentDevice.deviceName);
    } else {
        // currentDevice 为空，无法重连
        NSLog(@"⚠️ 没有当前设备，无法重连");
    }
}

@end
```

---

### 完整生命周期示例

```objective-c
// 1️⃣ 初始状态：currentDevice = nil
NSLog(@"currentDevice: %@", [WPBluetoothManager sharedInstance].currentDevice);
// 输出: currentDevice: (null)

// 2️⃣ 扫描设备
[[WPBluetoothManager sharedInstance] startScanning:YES];
// currentDevice 仍然为 nil（SDK 不会自动赋值）

// 3️⃣ 连接成功
- (void)didConnectPeripheral:(WPPeripheralInfo *)peripheralInfo {
    WPBluetoothWatchDevice *device = [WPBluetoothWatchDevice deviceFromPeripheralInfo:peripheralInfo];
    [WPBluetoothManager sharedInstance].currentDevice = device;  // 手动赋值

    NSLog(@"currentDevice: %@", [WPBluetoothManager sharedInstance].currentDevice.deviceName);
    // 输出: currentDevice: 我的手表
}

// 4️⃣ 意外断开连接
- (void)didDisconnectPeripheral:(WPPeripheralInfo *)peripheralInfo error:(NSError *)error {
    if (error) {
        // 意外断开，保留 currentDevice 用于重连
        NSLog(@"⚠️ 连接断开，保留设备信息用于重连");
        // currentDevice 仍然有值
    } else {
        // 主动断开，清空 currentDevice
        [WPBluetoothManager sharedInstance].currentDevice = nil;
        NSLog(@"currentDevice 已清空");
    }
}

// 5️⃣ 重连
[[WPBluetoothManager sharedInstance] reconnectToDevice];
// SDK 内部会使用 currentDevice.mac 进行重连
```

---

## 🆚 currentDevice vs connectedDevice

### 两种使用方式对比

| 属性 | 位置 | 管理方式 | 作用域 | 推荐场景 |
|------|------|---------|--------|---------|
| `[WPBluetoothManager sharedInstance].currentDevice` | SDK 提供 | 手动管理 | 全局 | 需要重连功能 |
| `self.connectedDevice` | 自己定义 | 自己管理 | 视图控制器内 | 不需要重连 |

### 示例对比

#### 方式 1：使用 SDK 的 currentDevice（推荐，支持重连）

```objective-c
@implementation MyViewController

- (void)didConnectPeripheral:(WPPeripheralInfo *)peripheralInfo {
    WPBluetoothWatchDevice *device = [WPBluetoothWatchDevice deviceFromPeripheralInfo:peripheralInfo];

    // 使用 SDK 的 currentDevice
    [WPBluetoothManager sharedInstance].currentDevice = device;

    // ✅ 支持重连
    [[WPBluetoothManager sharedInstance] reconnectToDevice];
}

@end
```

#### 方式 2：自己定义 connectedDevice（不支持重连）

```objective-c
@interface MyViewController ()
@property (nonatomic, strong) WPBluetoothWatchDevice *connectedDevice;
@end

@implementation MyViewController

- (void)didConnectPeripheral:(WPPeripheralInfo *)peripheralInfo {
    WPBluetoothWatchDevice *device = [WPBluetoothWatchDevice deviceFromPeripheralInfo:peripheralInfo];

    // 使用自己的属性
    self.connectedDevice = device;

    // ❌ 无法使用 SDK 的重连功能
    // [[WPBluetoothManager sharedInstance] reconnectToDevice];  // 这不会工作
}

@end
```

---

## ⚠️ 常见误区

### ❌ 误区 1：以为 SDK 会自动赋值

```objective-c
// ❌ 错误示例
- (void)didConnectPeripheral:(WPPeripheralInfo *)peripheralInfo {
    // 没有赋值 currentDevice

    // 稍后尝试重连
    [[WPBluetoothManager sharedInstance] reconnectToDevice];
    // ⚠️ 重连不会工作，因为 currentDevice 为 nil
}
```

**正确做法**：
```objective-c
// ✅ 正确示例
- (void)didConnectPeripheral:(WPPeripheralInfo *)peripheralInfo {
    // 手动赋值 currentDevice
    WPBluetoothWatchDevice *device = [WPBluetoothWatchDevice deviceFromPeripheralInfo:peripheralInfo];
    [WPBluetoothManager sharedInstance].currentDevice = device;

    // 现在可以重连了
    [[WPBluetoothManager sharedInstance] reconnectToDevice];  // ✅ 可以工作
}
```

---

### ❌ 误区 2：每次都清空 currentDevice

```objective-c
// ❌ 错误示例
- (void)didDisconnectPeripheral:(WPPeripheralInfo *)peripheralInfo error:(NSError *)error {
    // 不管什么原因断开，都清空
    [WPBluetoothManager sharedInstance].currentDevice = nil;

    // ⚠️ 现在无法重连了
}
```

**正确做法**：
```objective-c
// ✅ 正确示例
- (void)didDisconnectPeripheral:(WPPeripheralInfo *)peripheralInfo error:(NSError *)error {
    if (error) {
        // 意外断开，保留设备信息用于自动重连
        NSLog(@"⚠️ 意外断开，保留设备信息");
        // 不清空 currentDevice
    } else {
        // 主动断开，清空设备信息
        [WPBluetoothManager sharedInstance].currentDevice = nil;
    }
}
```

---

## 📚 总结

### 关键点

1. **不会自动赋值** - 需要手动在连接成功后赋值
2. **支持重连功能** - SDK 的 `reconnectToDevice` 方法依赖该属性
3. **全局访问** - 可以在任何地方访问当前连接的设备
4. **可选属性** - 如果不需要重连功能，可以不使用

### 使用决策树

```
需要使用重连功能？
├─ 是 → 使用 [WPBluetoothManager sharedInstance].currentDevice
│        在 didConnectPeripheral: 中手动赋值
│        在 didDisconnectPeripheral:error: 中根据情况决定是否清空
│
└─ 否 → 自己定义 self.connectedDevice
         自己管理生命周期
```

---

## 🔗 相关文档

- [WPBluetoothManager API 文档](README.md)
- [设备连接管理指南](PERIPHERAL_TO_DEVICE_GUIDE.md)
- [快速开始教程](README.md#快速开始)

---

**最后更新**：2026-01-19
