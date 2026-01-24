# WatchProtocolSDK-ObjC v2.0.2 修复说明

## 问题描述

第三方用户反馈按使用指南执行自动重连时出现问题：
- 打开 app 后开始重连
- 接着开始扫描
- 然后就没有任何回调，用户不知道发生了什么

## 问题根因分析

### 1. UUID 大小写匹配问题 ⚠️

**问题**：
- iOS 的 CoreBluetooth 框架不提供真实的蓝牙 MAC 地址
- SDK 使用 `peripheral.identifier.UUIDString` 作为设备标识符
- UUID 字符串在不同设备、不同 iOS 版本可能有大小写差异
- 原代码使用区分大小写的 `containsString:` 进行匹配
- 导致保存的 UUID 与扫描时获取的 UUID 无法匹配

**影响代码位置**：
- `WPBluetoothManager.m:412` - `didDiscoverPeripheral` 回调中的设备匹配
- `WPBluetoothManager.m:195` - `connectToDeviceWithMac` 方法中的设备查找
- `WPBluetoothManager.m:219` - `connectAndScanWithMac` 方法中的设备查找

**示例**：
```objc
// 保存时的 UUID（大写）
"457E5B71-DB8B-B7A9-9B0B-B33129B39AD9"

// 扫描时获取的 UUID（可能是小写）
"457e5b71-db8b-b7a9-9b0b-b33129b39ad9"

// 原代码使用 containsString: 无法匹配（大小写敏感）
```

### 2. 扫描超时无反馈 ⚠️

**问题**：
- 设置了 10 秒扫描超时
- 超时后自动停止扫描（`scanTimerFired:` 方法）
- 但没有通知代理或用户扫描超时
- 用户无法知道是扫描超时还是其他问题

**影响**：
- 用户体验差
- 无法诊断问题（设备不在范围内？蓝牙未开启？权限问题？）

### 3. 日志输出不完整

**问题**：
- 没有详细的设备匹配日志
- 扫描超时时没有日志输出
- 无法通过日志排查问题

## 修复方案

### 1. 修复 UUID 大小写匹配问题 ✅

**修改内容**：

#### `WPBluetoothManager.m:390` - didDiscoverPeripheral 回调
```objc
// 🆕 v2.0.2: 统一转换为大写，避免大小写匹配问题
NSString *macAddress = [peripheral.identifier.UUIDString uppercaseString];
```

#### `WPBluetoothManager.m:419-425` - 自动连接目标设备
```objc
// 🆕 v2.0.2: 自动连接目标设备（忽略大小写）
if (self.scanMacAddress.length > 0) {
    NSString *targetMac = [self.scanMacAddress uppercaseString];
    if ([macAddress containsString:targetMac]) {
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"✅ 找到目标设备 %@，准备连接", peripheral.name]];
        [self stopScanning];
        [self connectToPeripheral:info];
    }
}
```

#### `WPBluetoothManager.m:196-216` - connectToDeviceWithMac
```objc
// 🆕 v2.0.2: 忽略大小写进行匹配
NSString *targetMac = [macAddress uppercaseString];

for (WPPeripheralInfo *info in self.mutableDiscoveredPeripherals) {
    if ([[info.macAddress uppercaseString] isEqualToString:targetMac]) {
        // ...连接设备
    }
}
```

#### `WPBluetoothManager.m:222-240` - connectAndScanWithMac
```objc
// 🆕 v2.0.2: 统一转换为大写
self.scanMacAddress = [macAddress uppercaseString];

// 🆕 v2.0.2: 检查是否已经在扫描结果中（忽略大小写）
NSString *targetMac = [macAddress uppercaseString];
for (WPPeripheralInfo *info in self.mutableDiscoveredPeripherals) {
    if ([[info.macAddress uppercaseString] isEqualToString:targetMac]) {
        // ...直接连接
    }
}
```

### 2. 添加扫描超时回调 ✅

**新增代理方法**：

#### `WPBluetoothManager.h:66-70`
```objc
/**
 * 🆕 v2.0.2: 扫描超时（未找到目标设备）
 * @param macAddress 目标设备的 MAC 地址
 */
- (void)didScanTimeout:(NSString *)macAddress;
```

**实现超时通知**：

#### `WPBluetoothManager.m:171-182` - scanTimerFired
```objc
- (void)scanTimerFired:(NSTimer *)timer {
    if (self.isScanning) {
        [[WPLogger sharedInstance] log:@"⏰ 扫描超时，停止扫描"];
        [self stopScanning];

        // 🆕 v2.0.2: 通知代理扫描超时
        if (self.scanMacAddress.length > 0 && [self.delegate respondsToSelector:@selector(didScanTimeout:)]) {
            [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"⚠️ 未找到目标设备: %@", self.scanMacAddress]];
            [self.delegate didScanTimeout:self.scanMacAddress];
        }
    }
}
```

### 3. 改进日志输出 ✅

**新增日志**：
- ✅ 找到目标设备时的日志
- ⚠️ 未找到目标设备时的日志
- 🔍 扫描目标设备时显示设备名称和 MAC 地址

## 示例代码更新

### 实现新的超时回调

```objc
// 🆕 v2.0.2: 扫描超时回调
- (void)didScanTimeout:(NSString *)macAddress {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.statusLabel.text = [NSString stringWithFormat:@"⏰ 扫描超时，未找到设备: %@", macAddress];
        NSLog(@"⏰ 扫描超时，未找到目标设备: %@", macAddress);

        // 可以在这里提示用户：
        // 1. 检查手表是否开启
        // 2. 检查手表是否在蓝牙范围内
        // 3. 尝试重新扫描
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"连接失败"
                                                                       message:@"未找到目标设备。请确保设备已开启且在蓝牙范围内。"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    });
}
```

## 使用建议

### 1. 实现超时回调（推荐）⭐

```objc
- (void)didScanTimeout:(NSString *)macAddress {
    // 提示用户扫描超时
    // 可以选择：
    // 1. 自动重试（延迟后再次扫描）
    // 2. 提示用户手动重试
    // 3. 检查设备状态
}
```

### 2. 调整扫描超时时间（可选）

```objc
// 默认 10 秒超时
[[WPBluetoothManager sharedInstance] connectAndScanWithMac:mac
                                                 deviceName:name
                                                    timeout:10.0];

// 如果设备较远或蓝牙信号弱，可以增加超时时间
[[WPBluetoothManager sharedInstance] connectAndScanWithMac:mac
                                                 deviceName:name
                                                    timeout:20.0];
```

### 3. 日志输出

现在会看到更详细的日志：
```
✅ 蓝牙已开启
🔍 开始扫描目标设备: e watch (457E5B71-DB8B-B7A9-9B0B-B33329B39AD9)
🔍 发现设备: e watch [457E5B71-DB8B-B7A9-9B0B-B33329B39AD9]
✅ 找到目标设备 e watch，准备连接
⏹ 停止扫描
📱 连接指定的蓝牙设备: e watch
✅ 设备连接成功: e watch
```

或者超时情况：
```
✅ 蓝牙已开启
🔍 开始扫描目标设备: e watch (457E5B71-DB8B-B7A9-9B0B-B33329B39AD9)
🔍 发现设备: Other Device [123ABC...]
⏰ 扫描超时，停止扫描
⚠️ 未找到目标设备: 457E5B71-DB8B-B7A9-9B0B-B33329B39AD9
```

## 兼容性说明

### 向后兼容 ✅

- 新增的 `didScanTimeout:` 代理方法为 `@optional`
- 不实现该方法不会影响现有功能
- 旧代码无需修改即可使用

### 行为变化

1. **UUID 统一为大写**：
   - 所有保存到沙盒的设备 UUID 现在都是大写
   - 旧的小写 UUID 仍可正常匹配（自动转换）

2. **扫描超时通知**：
   - 现在会收到超时回调，可以及时处理
   - 建议实现该回调提升用户体验

## 测试建议

### 1. 正常连接测试
- 设备在范围内
- 应该能看到完整的连接日志
- 连接成功

### 2. 超时测试
- 设备不在范围内或已关机
- 应该在 10 秒后收到超时回调
- 日志显示"未找到目标设备"

### 3. UUID 大小写测试
- 尝试使用不同大小写的 UUID
- 都应该能正常匹配和连接

## 版本历史

### v2.0.2 (2026-01-21)
- 🐛 修复 UUID 大小写匹配问题
- ✨ 新增扫描超时回调 `didScanTimeout:`
- 📝 改进日志输出
- 📚 更新示例代码

### v2.0.1
- ✨ 新增健康数据查询功能
- ✨ 自动创建和保存 currentDevice

### v2.0.0
- 🎉 初始版本发布
