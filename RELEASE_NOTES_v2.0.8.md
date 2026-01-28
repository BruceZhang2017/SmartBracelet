# WatchProtocolSDK-ObjC v2.0.8 发布说明

## 📋 版本信息
- **版本号**: v2.0.8
- **发布日期**: 2026-01-27
- **类型**: 🐛 Bug Fix Release

---

## 🐛 Bug 修复

### 修正查找设备功能参数值

**问题描述**:
在 v2.0.7 版本中，查找设备功能的参数值设置错误：
- 开始查找使用了参数 `1`（错误）
- 停止查找使用了参数 `0`（错误）

**修正内容**:
根据设备协议规范，已修正参数值为：
- 开始查找：`0` ✅
- 停止查找：`1` ✅

**影响范围**:
- `WPCommands+FindDevice` 分类
- `WPFindDeviceAction` 枚举定义

**修改文件**:
```
WatchProtocolSDK-ObjC/Core/WPCommands+FindDevice.h  (枚举定义)
WatchProtocolSDK-ObjC/Core/WPCommands+FindDevice.m  (实现代码)
Output-ObjC-Dynamic/.../Headers/WPCommands+FindDevice.h  (框架头文件)
```

---

## 📦 更新方式

### CocoaPods
```ruby
pod 'WatchProtocolSDK-ObjC', '~> 2.0.8'
```

### 手动集成
下载 `WatchProtocolSDK-v2.0.8.zip`，解压后将 XCFramework 拖入项目。

---

## ⚠️ 重要提示

**升级建议**:
如果您在 v2.0.7 版本中使用了查找设备功能，强烈建议升级到 v2.0.8 以确保功能正常工作。

**API 兼容性**:
- ✅ 接口签名无变化，100% 向后兼容
- ⚠️ 设备协议行为已修正，使用旧版本可能导致查找功能异常

**测试建议**:
升级后请重新测试以下场景：
1. 查找手环功能是否正常触发震动/响铃
2. 停止查找功能是否能立即停止设备震动
3. 自动停止功能是否在指定时间后停止

---

## 📝 完整变更日志

### v2.0.8 (2026-01-27)
- 🐛 修正 `WPFindDeviceAction` 枚举值（开始=0，停止=1）
- 🐛 修正查找设备指令参数（符合设备协议规范）
- 📝 更新相关文档和注释

### v2.0.7 (2026-01-27)
- 🔥 新增智能查找设备功能
- ✅ 支持完成回调、主动停止、自动停止
- ✅ 支持查找状态查询

---

## 🔗 相关文档

- [查找设备使用指南](WatchProtocolSDK-ObjC/FIND_DEVICE_GUIDE.md)
- [WPBluetoothManager 查找设备指南](WatchProtocolSDK-ObjC/WPBLUETOOTHMANAGER_FINDDEVICE_GUIDE.md)
- [SDK 接入文档](WatchProtocolSDK-ObjC/README.md)

---

## 📧 技术支持

如有问题，请联系：315082431@qq.com
