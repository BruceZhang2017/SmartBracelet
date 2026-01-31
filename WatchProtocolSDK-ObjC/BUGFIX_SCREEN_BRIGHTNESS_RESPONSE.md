# 🐛 屏幕亮度响应处理完善

## 📋 问题描述

`handleScreenBrightnessResponse:` 方法原本只更新了设备属性，但缺少了以下关键功能：
1. **代理回调通知应用层**
2. **通知发送**（NotificationCenter）

这导致应用层无法及时响应屏幕亮度数据变化。

## 🎯 修复目标

参考 Swift 版本的 `XGZTCommands.swift` 中 `case .switchStatus` 处理模式，完善 `handleScreenBrightnessResponse:` 方法，确保：
- ✅ 更新设备属性
- ✅ 通过代理回调通知应用层
- ✅ 发送系统通知

## 🔧 修复内容

### 1️⃣ 添加代理方法定义

**文件**: `WPBluetoothManager.h`

在 `WPBluetoothManagerDelegate` 协议中添加：

```objc
/**
 * 🆕 v2.0.10: 接收到屏幕亮度数据
 * @param brightness 屏幕亮度值（0-100）
 * @discussion 当接收到设备的屏幕亮度查询响应时触发（指令 0x52）
 * @note 此回调会自动更新 currentDevice.screenBrightness 属性
 * @note 参考 Swift 实现：XGZTCommands.swift switchStatus 处理模式
 */
- (void)didReceiveScreenBrightness:(NSInteger)brightness;
```

### 2️⃣ 完善响应处理逻辑

**文件**: `WPCommands.m`

修改前：
```objc
+ (void)handleScreenBrightnessResponse:(NSData *)response {
    // ...
    if (bytes[5] == 0x00) {
        // 查询响应
        NSInteger brightness = bytes[6];
        WPBluetoothManager *manager = [WPBluetoothManager sharedInstance];
        if (manager.currentDevice) {
            manager.currentDevice.screenBrightness = brightness;
        }
        // ❌ 缺少代理回调和通知
    }
}
```

修改后：
```objc
+ (void)handleScreenBrightnessResponse:(NSData *)response {
    // ...
    WPBluetoothManager *manager = [WPBluetoothManager sharedInstance];

    if (bytes[5] == 0x00) {
        // ====== 查询响应：解析亮度值并通知应用层 ======
        NSInteger brightness = bytes[6];

        // 1. 更新设备属性
        if (manager.currentDevice) {
            manager.currentDevice.screenBrightness = brightness;
        }

        // 2. ✅ 通过代理回调通知应用层（参考 Swift: switchStatus 模式）
        if ([manager.delegate respondsToSelector:@selector(didReceiveScreenBrightness:)]) {
            [manager.delegate performSelector:@selector(didReceiveScreenBrightness:)
                                   withObject:@(brightness)];
        }

        // 3. ✅ 发送通知（参考 Swift: NotificationCenter.default.post）
        if (bytes[2] == 3) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DeviceSettings"
                                                                object:@(1)];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"XGZTBusinessHandler"
                                                                object:@"52"]; // 0x52 = 屏幕亮度指令
        }
    }
}
```

## 📊 参考实现

### Swift 版本参考（XGZTCommands.swift）

```swift
case .switchStatus:
    guard response.count >= 7 else {
        XLogger.shared.log("switchStatus command response error")
        return
    }
    if response.count >= 10 {
        // 更新设备属性
        XGZTBlueToothManager.shared.device?.isRaisehandtobrightenscreen = ((response[6] >> 1) & 1) > 0
        // ... 其他属性

        // 发送通知 ⭐️
        if response[2] == 3 {
            NotificationCenter.default.post(name: Notification.Name("DeviceSettings"), object: 1)
        } else {
            NotificationCenter.default.post(name: Notification.Name("XGZTBusinessHandler"), object: "11")
        }
    }
```

### ObjC 参考实现（handleSwitchStatusResponse:）

```objc
+ (void)handleSwitchStatusResponse:(NSData *)response {
    WPBluetoothManager *manager = [WPBluetoothManager sharedInstance];

    if (response.length >= 10) {
        // 1. 更新设备属性
        manager.currentDevice.isRaiseHandToBrightenScreen = ((p0 >> 1) & 1) > 0;

        // 2. 代理回调 ⭐️
        if ([manager.delegate respondsToSelector:@selector(didReceiveSwitchStatus:p1:)]) {
            // ... 调用代理方法
        }

        // 3. 发送通知 ⭐️
        if (bytes[2] == 3) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DeviceSettings" object:@(1)];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"XGZTBusinessHandler" object:@"11"];
        }
    }
}
```

## ✅ 修复效果

修复后，屏幕亮度响应处理流程完整：

```
设备返回亮度数据
    ↓
handleScreenBrightnessResponse:
    ↓
1. 更新 currentDevice.screenBrightness
    ↓
2. 触发代理回调 didReceiveScreenBrightness:
    ↓
3. 发送通知 NotificationCenter
    ↓
应用层接收到亮度变化事件 ✅
```

## 📝 使用示例

### 应用层代理实现

```objc
// 实现代理方法
- (void)didReceiveScreenBrightness:(NSInteger)brightness {
    NSLog(@"💡 收到屏幕亮度: %ld", (long)brightness);

    // 更新 UI
    dispatch_async(dispatch_get_main_queue(), ^{
        self.brightnessSlider.value = brightness;
        self.brightnessLabel.text = [NSString stringWithFormat:@"%ld%%", (long)brightness];
    });
}
```

### 通知监听

```objc
// 监听通知
[[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(handleDeviceSettingsChange:)
                                             name:@"DeviceSettings"
                                           object:nil];

- (void)handleDeviceSettingsChange:(NSNotification *)notification {
    NSLog(@"📢 设备设置变化: %@", notification.object);
    // 刷新UI
}
```

## 🔍 测试验证

```objc
// 1. 查询屏幕亮度
[WPCommands getScreenBrightness];

// 等待响应...
// ✅ 触发代理回调: didReceiveScreenBrightness:
// ✅ 发送通知: DeviceSettings 或 XGZTBusinessHandler

// 2. 设置屏幕亮度
[WPCommands setScreenBrightness:80];

// ✅ 日志输出: "设置屏幕亮度成功"
```

## 📦 影响范围

- **修改文件**:
  - `WPBluetoothManager.h` (新增代理方法)
  - `WPCommands.m` (完善响应处理)

- **兼容性**:
  - ✅ 向下兼容（新增可选代理方法）
  - ✅ 不影响现有功能
  - ✅ 与 Swift SDK 行为一致

## 📌 版本信息

- **修复版本**: v2.0.10
- **修复日期**: 2026-01-30
- **参考版本**: Swift SDK (XGZTCommands.swift)
