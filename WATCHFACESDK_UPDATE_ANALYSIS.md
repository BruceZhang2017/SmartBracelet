# WatchFaceSDK-ObjC 更新需求分析报告

生成时间: 2026-01-28

## 📊 执行摘要

WatchProtocolSDK 的 Objective-C 库已更新（新增 RaiseToWake 功能及其他改进），**WatchFaceSDK-Pure-ObjC 需要同步更新**以使用最新版本的 WatchProtocolSDK。

---

## 🔍 现状分析

### 1. WatchProtocolSDK 版本差异

| 项目 | 旧版本 (Output-ObjC) | 新版本 (Output-ObjC-Dynamic) | 差异 |
|------|---------------------|----------------------------|------|
| **头文件数量** | 7 个 | 12 个 | +5 个 ⬆️ |
| **库类型** | 静态库 | 动态库 | 类型变化 |
| **新增功能** | - | ✅ RaiseToWake（抬手亮屏） | 新功能 |

#### 新增的头文件（5个）
```
✅ WPCommands.h                   - 核心命令接口
✅ WPCommands+FindDevice.h        - 查找设备功能
✅ WPCommands+RaiseToWake.h       - 抬手亮屏功能（新）
✅ WPPeripheralInfo+WatchDevice.h - 设备信息扩展
✅ NSData+HexString.h             - 数据转换工具
```

### 2. WatchFaceSDK-Pure-ObjC 集成问题

#### 🚨 主要问题
WatchFaceSDK-Pure-ObjC 代码中有**多处 TODO 注释**，表明与 WatchProtocolSDK 的集成尚未完成。

#### 问题详情

**文件: `WFManager.m`**
```objc
❌ 第 11-12 行:
   // TODO: Import proper WatchProtocolSDK classes when available
   // #import <WatchProtocolSDK/WatchProtocolSDK.h>

❌ 第 45-52 行: getCurrentDeviceScreenInfo
   - 使用硬编码值（240x240）
   - 未从 WatchProtocolSDK 获取真实设备信息

❌ 第 55-58 行: isDeviceConnected
   - 总是返回 YES
   - 未调用 WPBluetoothManager 检查真实连接状态
```

**文件: `WFTransferEngine.m`**
```objc
❌ 第 9-10 行:
   // TODO: Import proper WatchProtocolSDK classes when available
   // #import <WatchProtocolSDK/WatchProtocolSDK.h>

❌ 第 134-136 行: setTimePositionAndColor
   - 仅有日志输出，无实际实现
   - 需要通过 WPCommands 发送设置指令

❌ 第 139-140 行: queryMTUAndStartTransfer
   - 使用硬编码 MTU = 240
   - 需要从 WPDeviceManager 查询真实 MTU

❌ 第 186-190 行: sendNextPacket
   - 使用模拟的数据发送（dispatch_after）
   - 需要通过 WPCommands 发送真实数据包

❌ 第 237 行:
   // TODO: Add type conversion methods when integrating with WatchProtocolSDK
```

---

## ✅ 需要更新的内容

### 1. 更新 WatchProtocolSDK 依赖

**当前:**
```bash
# build_pure_objc_framework.sh 第 25 行
WATCHPROTOCOL_FRAMEWORK="$PROJECT_DIR/Output-ObjC/WatchProtocolSDK.xcframework"
```

**建议更新为:**
```bash
# 使用新版本的动态库
WATCHPROTOCOL_FRAMEWORK="$PROJECT_DIR/Output-ObjC-Dynamic/WatchProtocolSDK.xcframework"
```

或者：
```bash
# 重新编译静态库版本到 Output-ObjC 目录
# 需要运行对应的静态库编译脚本
```

### 2. 完善 WFManager.m 集成

需要实现的功能：

```objc
// 导入 WatchProtocolSDK
#import <WatchProtocolSDK/WatchProtocolSDK.h>
#import <WatchProtocolSDK/WPBluetoothManager.h>
#import <WatchProtocolSDK/WPDeviceManager.h>

// 实现 getCurrentDeviceScreenInfo
- (WFDeviceScreenInfo *)getCurrentDeviceScreenInfo {
    // ✅ 从 WPDeviceManager 获取设备信息
    WPDeviceManager *deviceManager = [WPDeviceManager sharedInstance];
    // 获取设备屏幕参数
    // 转换为 WFDeviceScreenInfo
}

// 实现 isDeviceConnected
- (BOOL)isDeviceConnected {
    // ✅ 从 WPBluetoothManager 获取连接状态
    return [[WPBluetoothManager sharedInstance] isConnected];
}
```

### 3. 完善 WFTransferEngine.m 集成

需要实现的功能：

```objc
// 导入 WatchProtocolSDK
#import <WatchProtocolSDK/WatchProtocolSDK.h>
#import <WatchProtocolSDK/WPCommands.h>

// 实现 setTimePositionAndColor
- (void)setTimePositionAndColor:(WFTimePosition)position color:(WFDialColor)color {
    // ✅ 通过 WPCommands 发送设置指令
    // [WPCommands sendDialSettings:...];
}

// 实现 queryMTUAndStartTransfer
- (void)queryMTUAndStartTransfer {
    // ✅ 从 WPDeviceManager 查询 MTU
    WPDeviceManager *manager = [WPDeviceManager sharedInstance];
    NSInteger mtu = [manager getMTU];
    self.packetSize = mtu - 20;
    // ...
}

// 实现 sendNextPacket
- (void)sendNextPacket {
    // ✅ 使用 WPCommands 发送数据包
    // [WPCommands sendDialData:packetData completion:^(BOOL success) {
    //     if (success) {
    //         [self sendNextPacket];
    //     }
    // }];
}
```

### 4. 可选：集成 RaiseToWake 功能

如果表盘上传需要控制抬手亮屏：

```objc
#import <WatchProtocolSDK/WPCommands+RaiseToWake.h>

// 在表盘上传前/后设置抬手亮屏
- (void)configureRaiseToWake:(BOOL)enable {
    [WPCommands setRaiseToWake:enable completion:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"✅ 抬手亮屏设置成功");
        }
    }];
}
```

---

## 📋 更新步骤建议

### 方案 A：使用动态库（推荐）

1. **更新编译脚本依赖路径**
   ```bash
   # 修改 build_pure_objc_framework.sh
   WATCHPROTOCOL_FRAMEWORK="$PROJECT_DIR/Output-ObjC-Dynamic/WatchProtocolSDK.xcframework"
   ```

2. **实现 WatchProtocolSDK 集成代码**
   - 取消注释 WatchProtocolSDK 导入
   - 实现 WFManager.m 中的设备查询方法
   - 实现 WFTransferEngine.m 中的数据传输方法

3. **重新编译 WatchFaceSDK-Pure-ObjC**
   ```bash
   bash build_pure_objc_framework.sh
   ```

4. **验证功能**
   - 测试设备连接状态查询
   - 测试 MTU 查询
   - 测试表盘数据传输

### 方案 B：重新编译静态库

1. **重新编译 WatchProtocolSDK 静态库**
   ```bash
   # 运行对应的静态库编译脚本（需要找到该脚本）
   bash build_watchprotocol_objc_static.sh  # 假设存在此脚本
   ```

2. **按照方案 A 的步骤 2-4 执行**

---

## 🎯 预期收益

更新完成后的改进：

| 功能 | 更新前 | 更新后 |
|------|-------|-------|
| **设备连接检测** | ❌ 假返回 | ✅ 真实状态 |
| **设备屏幕信息** | ❌ 硬编码 240x240 | ✅ 动态查询 |
| **MTU 查询** | ❌ 硬编码 240 | ✅ 真实 MTU |
| **数据传输** | ❌ 模拟发送 | ✅ 真实蓝牙传输 |
| **抬手亮屏** | ❌ 不支持 | ✅ 支持（可选） |

---

## ⚠️ 风险与注意事项

1. **API 兼容性**
   - 需要确认 WatchProtocolSDK 提供的 API 与 WatchFaceSDK 的需求匹配
   - 可能需要添加适配层转换数据格式

2. **库类型变化**
   - 动态库需要 "Embed & Sign"
   - 静态库需要 "Do Not Embed"
   - 需要更新集成文档说明

3. **测试覆盖**
   - 更新后需要全面测试表盘上传流程
   - 测试各种屏幕尺寸和设备型号
   - 测试错误处理和重试机制

---

## 📝 结论

**强烈建议更新 WatchFaceSDK-Pure-ObjC**，原因：

1. ✅ 获得 WatchProtocolSDK 的新功能（RaiseToWake 等）
2. ✅ 实现真实的蓝牙通信（当前仅为占位实现）
3. ✅ 修复多处 TODO 代码，完善 SDK 功能
4. ✅ 提供完整可用的表盘上传功能

**优先级: 🔴 高**

---

## 📞 后续行动

需要确认：

1. 是否立即进行集成更新？
2. 选择方案 A（动态库）还是方案 B（静态库）？
3. 是否需要集成 RaiseToWake 功能？

请提供指示，我可以协助完成后续的代码更新工作。
