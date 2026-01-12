# WatchProtocolSDK v1.0.2 - 发布包

## 📦 包含内容

本发布包包含以下文件：

### 1. SDK 文件
- **WatchProtocolSDK.xcframework**: 编译好的 SDK framework，支持 iOS 设备和模拟器

### 2. 版本信息
- **VERSION.txt**: SDK 版本信息和发布说明

### 3. 接入文档
- **WatchProtocolSDK-接入文档-中文.md**: 详细的中文接入指南
- **WatchProtocolSDK-Integration-Guide-EN.md**: 详细的英文接入指南

---

## 🚀 快速开始

### 集成 SDK

1. 将 `WatchProtocolSDK.xcframework` 拖入您的 Xcode 项目
2. 在项目 Target -> General -> Frameworks, Libraries, and Embedded Content 中添加 xcframework
3. 设置 Embed 为 "Embed & Sign"

### 添加依赖

在 `Podfile` 中添加：
```ruby
pod 'SwiftyJSON'
pod 'CryptoSwift'
```

### 配置权限

在 `Info.plist` 中添加蓝牙权限：
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>需要使用蓝牙连接智能手表设备</string>
```

### 使用示例

```swift
import WatchProtocolSDK

// 初始化蓝牙管理器
XGZTBlueToothManager.shared.initCentral()

// 扫描设备
XGZTBlueToothManager.shared.scanDevice { peripheral, macAddress in
    print("发现设备: \(peripheral.name ?? "未知") - \(macAddress)")
}

// 连接设备
XGZTBlueToothManager.shared.connectDevice("AA:BB:CC:DD:EE:FF") { success in
    if success {
        print("连接成功")
    }
}
```

---

## 📖 文档

- **中文文档**: 查看 `WatchProtocolSDK-接入文档-中文.md` 获取完整的中文接入指南
- **English Documentation**: See `WatchProtocolSDK-Integration-Guide-EN.md` for complete integration guide

---

## ✨ 主要特性

- ✅ 完整的蓝牙设备管理
- ✅ 健康数据同步（步数、睡眠、心率、血氧、血压）
- ✅ 协议化数据存储设计
- ✅ 设备指令系统
- ✅ 线程安全设计
- ✅ 完善的日志系统

---

## 📋 系统要求

- iOS 13.0+
- Xcode 12.0+
- Swift 5.0+

---

## 📝 版本历史

### v1.0.2 (2026-01-10)
- ✨ 新增步数换算方法：根据步数自动计算卡路里和距离
- ✨ 新增格式化方法：获取格式化的距离和卡路里值
- 🚀 增强健康数据模型功能
- 📖 更新文档和示例代码

### v1.0.1 (2026-01-03)
- ✨ 首次发布
- ✨ 完整的蓝牙通信协议实现
- ✨ 支持多种健康数据同步
- 📖 完整的中英文文档

---

## 🔧 技术支持

如有问题或建议，请联系：
- Email: your.email@example.com
- GitHub: https://github.com/yourcompany/WatchProtocolSDK

---

**© 2025-2026 Your Company. All Rights Reserved.**
