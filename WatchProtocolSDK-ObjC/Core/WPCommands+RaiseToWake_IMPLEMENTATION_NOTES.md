# WPCommands+RaiseToWake 实现说明

## 📚 参考来源
Swift 实现：`DeviceSettingsViewController.swift:436-448`

## 🔍 Swift 参考代码分析

### handleRaiseHandScreenSwitch 方法（第436-448行）
```swift
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

### getXGZTSwitchP0 方法（第519-530行）
```swift
private func getXGZTSwitchP0() -> UInt8 {
    guard let device = XGZTBlueToothManager.shared.device else { return 0 }
    var p0: UInt8 = 0
    p0 |= device.isAntilostSwitch ? (1 << 0) : 0                      // bit 0: 防丢开关
    p0 |= device.isRaisehandtobrightenscreen ? (1 << 1) : 0          // bit 1: 抬手亮屏 ⭐️
    p0 |= device.isAntilostSwitch ? (1 << 2) : 0                      // bit 2: 防丢开关（重复？）
    p0 |= device.isSleepmonitoringSwitch ? (1 << 4) : 0              // bit 4: 睡眠监测
    p0 |= device.isMessageremindermainswitch ? (1 << 5) : 0          // bit 5: 消息提醒总开关
    p0 |= device.isRegularexercisedatauploadswitch ? (1 << 6) : 0   // bit 6: 定期运动数据上传
    p0 |= device.isGoalachievementswitch ? (1 << 7) : 0              // bit 7: 目标达成开关
    return p0
}
```

## ✅ 当前 Objective-C 实现（已完成完整匹配）

### 已实现的功能
1. ✅ 蓝牙连接状态检查
2. ✅ 设备连接状态检查
3. ✅ 设备模型验证
4. ✅ 更新设备模型中的抬手亮屏状态
5. ✅ 读取设备的所有开关状态
6. ✅ 组合所有开关位到 p0 和 p1 字节
7. ✅ 发送完整的开关状态
8. ✅ 错误处理和回调
9. ✅ 详细的日志记录（包含 p0/p1 值）

### 完整实现
```objc
// 1. 获取当前设备模型
WPBluetoothWatchDevice *device = btManager.currentDevice;

// 2. 更新设备模型中的抬手亮屏状态
device.isRaiseHandToBrightenScreen = enable;

// 3. 计算完整的开关状态字节（组合所有开关位）
uint8_t p0 = [self calculateP0FromDevice:device];
uint8_t p1 = [self calculateP1FromDevice:device];

// 4. 发送指令
```

### 辅助方法
```objc
// 完全匹配 Swift 的 getXGZTSwitchP0() 方法
+ (uint8_t)calculateP0FromDevice:(WPBluetoothWatchDevice *)device;

// 完全匹配 Swift 的 getXGZTSwitchP1() 方法
+ (uint8_t)calculateP1FromDevice:(WPBluetoothWatchDevice *)device;
```

## ✅ 完整性验证

### Objective-C vs Swift 对比
| 实现步骤 | Swift 版本 | Objective-C 版本 | 状态 |
|---------|-----------|-----------------|------|
| 检查连接状态 | ✅ | ✅ | ✅ 完全匹配 |
| 获取设备模型 | `XGZTBlueToothManager.shared.device` | `btManager.currentDevice` | ✅ 完全匹配 |
| 更新抬手亮屏状态 | `device?.isRaisehandtobrightenscreen = isOn` | `device.isRaiseHandToBrightenScreen = enable` | ✅ 完全匹配 |
| 计算 p0 字节 | `getXGZTSwitchP0()` | `calculateP0FromDevice:` | ✅ 完全匹配 |
| 计算 p1 字节 | `getXGZTSwitchP1()` | `calculateP1FromDevice:` | ✅ 完全匹配 |
| 发送指令 | `XGZTCommand.setSwitchStatus(p0:p1:)` | `sendData:command` | ✅ 完全匹配 |

### Swift 版本的完整实现流程（已完全匹配）
Swift 版本先读取设备的所有开关状态，然后组合所有位：
1. ✅ 更新设备模型中的抬手亮屏状态
2. ✅ 读取设备的所有开关状态
3. ✅ 组合所有开关位到 p0 和 p1 字节
4. ✅ 发送完整的开关状态

## 🎉 已完成完整实现

### 实现方案：设备状态管理（已采用）
```objc
+ (void)setRaiseToWake:(BOOL)enable completion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion {
    // 1. 前置检查（蓝牙、连接、设备模型）
    WPBluetoothManager *btManager = [WPBluetoothManager sharedInstance];
    WPBluetoothWatchDevice *device = btManager.currentDevice;

    // 2. 更新抬手亮屏状态
    device.isRaiseHandToBrightenScreen = enable;

    // 3. 组合所有开关位（保护其他开关状态）
    uint8_t p0 = [self calculateP0FromDevice:device];
    uint8_t p1 = [self calculateP1FromDevice:device];

    // 4. 发送指令
    NSData *command = [self createCommandWithBytes:...];
    [btManager sendData:command];
}
```

### 核心优势
1. ✅ **完全匹配 Swift 逻辑**：实现流程与 Swift 版本一致
2. ✅ **保护其他开关**：不会意外影响其他功能开关
3. ✅ **可维护性高**：使用设备模型统一管理状态
4. ✅ **扩展性好**：其他开关功能可复用 `calculateP0/P1` 方法

## 📋 协议数据包结构

```
字节位置 | 值             | 说明
--------|----------------|------------------
0       | 0x00           | 帧头
1       | 0x80           | 命令类型（开关状态）
2       | 0x01           | 子命令序号
3       | 0x00           | 保留
4       | 0x05           | 数据长度
5       | 0x01           | 操作类型（0x00=查询, 0x01=设置）
6       | p0             | 开关状态字节 1
7       | p1             | 开关状态字节 2
8       | 0x00           | 保留
9       | 0x00           | 保留
```

### p0 字节的位定义
```
Bit | 功能                  | 掩码
----|----------------------|------
0   | 防丢开关              | 0x01
1   | 抬手亮屏 ⭐️           | 0x02
2   | 防丢开关（重复？）     | 0x04
3   | （未使用）            | 0x08
4   | 睡眠监测              | 0x10
5   | 消息提醒总开关         | 0x20
6   | 定期运动数据上传       | 0x40
7   | 目标达成开关          | 0x80
```

## 🧪 测试建议

1. **测试用例 1**：单独设置抬手亮屏
   - 验证抬手亮屏功能正常开启/关闭
   - 检查其他开关功能是否受影响

2. **测试用例 2**：与其他开关组合测试
   - 先开启睡眠监测
   - 再开启抬手亮屏
   - 验证两个功能都正常工作

3. **测试用例 3**：多次切换
   - 连续开关抬手亮屏功能
   - 验证状态稳定性

## 📝 后续优化建议

1. **实现设备状态管理**
   - 创建 `WPDeviceModel` 类存储所有开关状态
   - 在 `WPBluetoothManager` 中维护设备模型
   - 接收到状态响应时更新模型

2. **统一开关设置接口**
   - 创建通用的 `setSwitchStatus:` 方法
   - 各个功能开关调用统一接口
   - 避免代码重复

3. **增强错误处理**
   - 添加超时处理
   - 添加重试机制
   - 提供更详细的错误信息

## 📚 相关代码位置

- Swift 参考实现：`DeviceSettingsViewController.swift:436-448`
- 开关位计算：`DeviceSettingsViewController.swift:519-567`
- Objective-C 实现：`WatchProtocolSDK-ObjC/Core/WPCommands+RaiseToWake.m`
