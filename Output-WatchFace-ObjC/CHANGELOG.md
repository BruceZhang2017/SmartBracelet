# 更新日志

所有对 WatchFaceSDK-ObjC 的重大更改都将记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
并且本项目遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

---

## [1.0.0] - 2026-01-13

### 新增 ✨

- 🎉 首次发布 WatchFaceSDK-ObjC
- ✅ 纯 Objective-C 实现，无 Swift 依赖
- 📱 支持 iOS 13.0+
- 🏗 XCFramework 格式，支持 arm64 (真机) 和 arm64/x86_64 (模拟器)

### 核心功能

#### 表盘上传
- ✅ 市场表盘上传（从 NSData）
- ✅ 市场表盘上传（从文件 URL）
- ✅ 自定义表盘创建和上传
- ✅ 实时传输进度监控
- ✅ 传输控制（暂停、取消、重试）

#### 图片处理
- ✅ 智能图片裁剪和缩放
- ✅ RGB565 格式转换
- ✅ PAR 格式转换（使用 ABParTool）
- ✅ 自动 JPEG 压缩优化
- ✅ 圆形/方形屏幕自动适配

#### 设备管理
- ✅ 设备连接状态检测
- ✅ 设备屏幕信息查询
- ✅ MTU 自动协商和分包传输

#### API 完整性
- ✅ `WFManager` - 主管理类
- ✅ `WFImageProcessor` - 图片处理工具
- ✅ `WFTransferEngine` - 传输引擎
- ✅ `WFTransferDelegate` - 进度回调协议
- ✅ `WFTransferProgress` - 进度模型
- ✅ `WFDeviceScreenInfo` - 设备信息模型
- ✅ 完整的枚举和错误代码定义

### 技术特性

- ⚡️ 轻量级：Framework 仅 312KB
- 🎯 纯 Objective-C：无 Swift 运行时依赖
- 📦 易集成：支持手动集成和 CocoaPods
- 🔄 自动适配：MTU 大小自动检测和分包
- 🛡 线程安全：内部自动处理多线程

### 文档

- 📖 完整的 API 文档
- 🚀 快速开始指南
- 💡 详细的示例代码（Objective-C 和 Swift）
- ❓ 常见问题解答

### 依赖

- WatchProtocolSDK.xcframework (必需)
- ABParTool.xcframework (必需)
- iOS 系统框架：Foundation, UIKit, CoreGraphics, CoreBluetooth

---

## [未来计划]

### v1.1.0 (规划中)

- [ ] 支持表盘预览功能
- [ ] 支持批量上传
- [ ] 添加表盘历史记录
- [ ] 优化传输性能
- [ ] 添加更多图片滤镜

### v1.2.0 (规划中)

- [ ] 支持动态表盘
- [ ] 支持表盘模板
- [ ] 云端表盘库集成
- [ ] AI 智能表盘推荐

---

## 版本说明

### 版本号规则

遵循语义化版本 (Semantic Versioning)：

- **主版本号**：不兼容的 API 修改
- **次版本号**：向下兼容的功能性新增
- **修订号**：向下兼容的问题修正

示例：`1.2.3`
- 1 = 主版本
- 2 = 次版本
- 3 = 修订版本

### 更新类型标识

- ✨ 新增 (Added) - 新功能
- 🔄 变更 (Changed) - 现有功能的变更
- ⚠️ 弃用 (Deprecated) - 即将移除的功能
- ❌ 移除 (Removed) - 已移除的功能
- 🐛 修复 (Fixed) - 问题修复
- 🔒 安全 (Security) - 安全相关修复

---

**感谢使用 WatchFaceSDK-ObjC！** 🎉
