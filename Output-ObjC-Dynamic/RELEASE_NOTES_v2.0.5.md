# WatchProtocolSDK v2.0.5 发布说明

**发布日期**: 2026年1月23日
**版本号**: 2.0.5
**构建类型**: Dynamic XCFramework
**最低系统**: iOS 13.0+

## 🎉 概述

WatchProtocolSDK v2.0.5 是基于纯 Objective-C 实现的智能手表蓝牙通信 SDK 的最新维护版本。本次发布主要完善了头文件导出和文档体系，确保第三方集成时的完整性。

## ✨ 新增内容

### 1. 公开头文件完善
- ✅ 新增 `NSData+HexString.h` 到公开头文件列表
- ✅ 确保所有工具类头文件正确导出
- ✅ 优化 Framework 模块化支持

### 2. 文档体系完善
- ✅ 创建 `VERSION.txt` 版本信息文件
- ✅ 完善 `INTEGRATION_CHECKLIST_v2.0.5.md` 集成检查清单
- ✅ 更新 `DYNAMIC_FRAMEWORK_INTEGRATION.md` 集成指南
- ✅ 改进 `LINKER_ERROR_FIX.md` 故障排除指南

### 3. 构建流程优化
- ✅ 优化 Framework 编译流程
- ✅ 改进符号导出验证
- ✅ 增强代码签名流程

## 🔧 技术规格

### Framework 信息
```
名称: WatchProtocolSDK.xcframework
类型: Dynamic Framework
大小: 900KB
架构:
  - iOS 设备: arm64
  - iOS 模拟器: arm64 + x86_64
```

### 依赖框架
```
- CoreBluetooth.framework (系统框架)
- Foundation.framework (系统框架)
```

### 导出符号统计
```
核心管理类: 4 个
  - WPBluetoothManager
  - WPDeviceManager
  - WPCommands
  - WPLogger

数据模型类: 11 个
  - WPStepData
  - WPHeartData
  - WPOxygenData
  - WPBloodPressureData
  - WPSleepData
  - WPAlarmData
  - WPDoNotDisturb
  - WPReminderInfo
  - WPDeviceInfoResponse
  - WPHeartRateResponse
  - WPBatteryLevelResponse

存储协议类: 1 个
  - WPEmptyHealthDataStorage

工具类: 2 个
  - NSData+HexString
  - WPPeripheralInfo+WatchDevice
```

## 📦 包内容

```
Output-ObjC-Dynamic/
├── WatchProtocolSDK.xcframework/
│   ├── ios-arm64/
│   │   └── WatchProtocolSDK.framework/
│   └── ios-arm64_x86_64-simulator/
│       └── WatchProtocolSDK.framework/
├── README.md
├── DYNAMIC_FRAMEWORK_INTEGRATION.md
├── LINKER_ERROR_FIX.md
├── INTEGRATION_CHECKLIST_v2.0.5.md
├── RELEASE_NOTES_v2.0.5.md
└── VERSION.txt
```

## 🚀 快速开始

### 1. 添加 Framework
将 `WatchProtocolSDK.xcframework` 拖入项目，设置 Embed 为 **"Embed & Sign"**。

### 2. 导入头文件
```objc
#import <WatchProtocolSDK/WatchProtocolSDK.h>
```

### 3. 初始化 SDK
```objc
- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [[WPDeviceManager sharedInstance] initializeWithStorage:nil];
    [[WPBluetoothManager sharedInstance] initCentral];

    return YES;
}
```

### 4. 扫描设备
```objc
// 开始扫描
[[WPBluetoothManager sharedInstance] startScanning:YES];

// 实现代理方法
- (void)bluetoothManager:(WPBluetoothManager *)manager
       didDiscoverDevice:(WPPeripheralInfo *)peripheralInfo {
    NSLog(@"发现设备: %@", peripheralInfo.deviceName);
}
```

### 5. 连接设备
```objc
[[WPBluetoothManager sharedInstance] connectDevice:peripheral];
```

## 🐛 已知问题

暂无已知问题。

如有问题，请通过以下方式反馈：
- 邮箱: 315082431@qq.com

## 🔄 从旧版本升级

### 从 v2.0.4 升级
直接替换 Framework 文件即可，API 完全兼容。

### 从 v2.0.0-v2.0.3 升级
1. 替换 Framework 文件
2. 检查是否使用了自动重连功能（已优化）
3. 验证 MAC 地址获取逻辑（已修复）

### 从 v1.x 升级
请参考 `MIGRATION-GUIDE-v2.0.md` 文档进行迁移。

## 📋 完整功能列表

### 蓝牙管理
- ✅ 设备扫描与发现
- ✅ 设备连接与断开
- ✅ 自动重连机制
- ✅ 连接状态监控
- ✅ RSSI 信号强度读取

### 设备信息
- ✅ 设备名称
- ✅ MAC 地址
- ✅ 固件版本
- ✅ 电池电量
- ✅ 设备型号

### 健康数据
- ✅ 步数数据同步
- ✅ 心率数据同步
- ✅ 血压数据同步
- ✅ 血氧数据同步
- ✅ 睡眠数据同步

### 设备控制
- ✅ 闹钟设置
- ✅ 勿扰模式
- ✅ 提醒推送
- ✅ 时间同步

### 工具功能
- ✅ 日志记录
- ✅ 数据格式转换
- ✅ 协议解析
- ✅ 存储管理

## 🎯 性能指标

| 指标 | 数值 |
|------|------|
| Framework 大小 | 900KB |
| 启动时间影响 | <50ms |
| 蓝牙扫描延迟 | <100ms |
| 数据同步速度 | >10KB/s |
| 内存占用 | <5MB |

## 🔐 安全性

- ✅ 代码已签名
- ✅ 无第三方依赖
- ✅ 仅使用系统框架
- ✅ 无网络请求
- ✅ 无隐私数据收集

## 📱 兼容性

### 系统版本
- iOS 13.0+
- iPadOS 13.0+

### 开发环境
- Xcode 12.0+
- macOS 10.15+

### 编程语言
- Objective-C（原生支持）
- Swift（通过 Bridging Header）

### 架构支持
- ✅ arm64（真机）
- ✅ arm64（模拟器）
- ✅ x86_64（模拟器）

## 📞 技术支持

### 联系方式
- 邮箱: 315082431@qq.com

### 提交问题时请提供
1. Xcode 版本号
2. iOS 系统版本
3. 完整错误日志
4. 代码示例
5. Build Settings 截图

### 响应时间
工作日: 24小时内响应
周末/节假日: 48小时内响应

## 📝 更新历史

| 版本 | 日期 | 主要变更 |
|------|------|---------|
| v2.0.5 | 2026-01-23 | 完善头文件导出和文档 |
| v2.0.4 | 2026-01-22 | 优化自动重连 |
| v2.0.3 | 2026-01-21 | 修复 MAC 地址和重连死循环 |
| v2.0.2 | 2026-01-21 | 修复电池电量异常值 |
| v2.0.0 | 2026-01-20 | 首次正式发布 |

## 🙏 致谢

感谢所有使用和反馈问题的开发者，你们的建议帮助我们不断改进。

## 📄 许可证

本 SDK 为商业软件，使用前请联系获取授权。

---

**祝开发顺利！** 🎉
