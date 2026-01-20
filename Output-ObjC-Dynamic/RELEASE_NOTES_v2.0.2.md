# WatchProtocolSDK-ObjC v2.0.2 发布说明

## 📦 版本信息

- **版本号**：v2.0.2
- **发布日期**：2026-01-20
- **构建类型**：动态 Framework (XCFramework)
- **最低系统要求**：iOS 13.0+

## 🐛 Bug 修复

### 修复电量值异常问题（BATTERY-127）

**问题描述**：
- 部分设备返回电量值为 127，超出协议规定的 0~100 范围
- 导致 UI 显示异常（显示 "127%"）
- 影响数据统计和业务逻辑

**修复内容**：
- ✅ 在 `WPCommands.m` 的 `handleBatteryLevelResponse:` 方法中添加范围检查
- ✅ 自动将超出范围的值（127）限制在 0~100
- ✅ 添加警告日志，便于追踪异常数据

**修复代码**：
```objc
// 🆕 v2.0.2: 范围检查和容错处理
NSInteger rawBatteryLevel = bytes[6] & 0x7F;
NSInteger batteryLevel = rawBatteryLevel;

if (rawBatteryLevel > 100) {
    batteryLevel = 100;  // 限制最大值为 100
    [[WPLogger sharedInstance] log:[NSString stringWithFormat:
        @"⚠️ 电量值异常:%ld (超出范围)，已修正为:100",
        (long)rawBatteryLevel]];
}
```

**修复效果**：

| 设备返回值 | v2.0.1 | v2.0.2 | 状态 |
|-----------|--------|--------|------|
| 0x00 (0) | 0% | 0% | ✅ 正常 |
| 0x32 (50) | 50% | 50% | ✅ 正常 |
| 0x64 (100) | 100% | 100% | ✅ 正常 |
| **0x7F (127)** | **127%** ⚠️ | **100%** ✅ | **已修复** |
| 0xFF (127+充电) | 127% | 100% | ✅ 已修复 |

**日志示例**（当设备返回 127 时）：
```
⚠️ 电量值异常:127 (超出范围)，已修正为:100
🔋 电量:100% 充电状态:未充电
```

## 📚 相关文档

为此问题创建了详细的文档：

1. **BATTERY_LEVEL_127_BUG_ANALYSIS.md**
   - 完整的问题分析报告
   - 协议解析说明
   - 多种解决方案
   - 测试验证用例

2. **BATTERY_127_FIX_GUIDE.md**
   - 快速修复指南
   - 升级步骤
   - 验证方法
   - 日志示例

3. **自动重连使用指南.md** / **AUTO_RECONNECT_GUIDE.md**
   - App 杀掉后自动重连的使用教程
   - 完整示例代码
   - 常见问题解答

## ✨ 特性

### v2.0.x 系列特性（保持不变）

- ✅ 纯 Objective-C 实现（无 Swift 依赖）
- ✅ 真正的动态 Framework
- ✅ 支持标准导入语法：`#import <WatchProtocolSDK/WatchProtocolSDK.h>`
- ✅ 完整的模块化支持
- ✅ 符号验证通过（WPBluetoothManager、WPDeviceManager 等）

### v2.0.1 新增功能（已包含）

- ✅ 设备连接后自动创建并保存 `currentDevice`
- ✅ 自动保存设备信息到沙盒（NSUserDefaults）
- ✅ 意外断开时保留 `currentDevice`，便于重连
- ✅ 新增健康数据查询 API：
  - `queryBatteryLevel` - 查询电量
  - `startHeartRateMonitoring` - 开始心率测量
  - `stopHeartRateMonitoring` - 停止心率测量
  - `measureHeartRateOnce` - 单次心率测量
- ✅ 新增代理回调：
  - `didReceiveBatteryLevel:isCharging:` - 电量数据回调
  - `didReceiveHeartRate:` - 心率数据回调
  - `didHeartRateMonitoringStatusChanged:` - 心率测量状态变化

## 📦 构建信息

- **Framework 大小**：832K
- **支持架构**：
  - iOS 设备：arm64
  - iOS 模拟器：arm64 + x86_64
- **系统框架依赖**：
  - CoreBluetooth.framework
  - Foundation.framework

## 🔄 升级指南

### 从 v2.0.0 / v2.0.1 升级

**无需修改代码**，仅需替换 Framework：

1. 删除旧版本的 `WatchProtocolSDK.xcframework`
2. 将新版本的 `WatchProtocolSDK.xcframework` 拖入项目
3. 确认 Embed 设置为 **"Embed & Sign"**
4. 清理并重新编译：
   ```bash
   # Xcode: Product → Clean Build Folder (⇧⌘K)
   # 或命令行：
   rm -rf ~/Library/Developer/Xcode/DerivedData/*
   ```

### 验证升级

运行 App 并调用 `queryBatteryLevel`，检查日志：

```objc
[[WPBluetoothManager sharedInstance] queryBatteryLevel];

// 如果设备返回异常值，将看到警告日志：
// ⚠️ 电量值异常:127 (超出范围)，已修正为:100
// 🔋 电量:100% 充电状态:未充电

// 回调中收到的值将是修正后的值（0~100）
- (void)didReceiveBatteryLevel:(NSInteger)batteryLevel isCharging:(BOOL)isCharging {
    NSAssert(batteryLevel >= 0 && batteryLevel <= 100,
            @"电量值超出范围: %ld", (long)batteryLevel);
    // 断言不会触发，说明修复成功
}
```

## 🔍 兼容性

### 向后兼容

- ✅ 完全兼容 v2.0.0 和 v2.0.1
- ✅ API 接口无任何变化
- ✅ 仅修复了内部的数据验证逻辑
- ✅ 不影响正常设备（电量值 ≤ 100）的使用

### 系统要求

| 项目 | 要求 |
|------|------|
| iOS 版本 | 13.0+ |
| Xcode 版本 | 12.0+ |
| macOS 版本 | 10.15+ |

## 📞 技术支持

### 问题反馈

如果升级后仍然遇到问题，请提供：

1. **设备信息**
   - 设备型号
   - 固件版本
   - MAC 地址（脱敏）

2. **完整日志**
   ```objc
   // 启用 SDK 日志
   [[WPLogger sharedInstance] setLogEnabled:YES];

   // 复制完整的蓝牙通信日志
   ```

3. **异常数据**
   - 原始电量值
   - 充电状态
   - 出现频率

### 联系方式

- 技术支持：SDK 技术团队
- 问题追踪：BATTERY-127

## 📝 开发建议

### 数据收集（可选）

如果希望收集异常电量数据，可以添加以下代码：

```objc
- (void)didReceiveBatteryLevel:(NSInteger)batteryLevel isCharging:(BOOL)isCharging {
    // 检测是否收到修正后的值
    if (batteryLevel == 100) {
        // 可能是正常的 100%，也可能是从 127 修正来的
        // 检查日志中是否有警告信息
    }

    // 正常使用电量数据
    self.batteryLabel.text = [NSString stringWithFormat:@"%ld%%", (long)batteryLevel];
    self.chargingIcon.hidden = !isCharging;
}
```

### 与设备团队协作

建议同时向设备固件团队反馈此问题：
- 了解 127 是否有特殊含义（如"未知"、"无效"等）
- 确认哪些设备型号/固件版本存在此问题
- 协调固件修复计划

## 🎉 总结

v2.0.2 是一个重要的 Bug 修复版本：
- 🐛 修复了电量值 127 异常问题
- ✅ 保证回调的电量值始终在 0~100 范围内
- 📝 提供了完整的分析文档和修复指南
- 🔄 完全向后兼容，无需修改代码

建议所有使用 v2.0.0 / v2.0.1 的用户升级到此版本。

---

**发布时间**：2026-01-20
**下一个版本计划**：根据用户反馈确定
**状态**：✅ 稳定版本，推荐使用
