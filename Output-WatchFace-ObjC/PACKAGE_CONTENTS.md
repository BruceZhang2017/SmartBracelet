# WatchFaceSDK-ObjC 集成包说明

欢迎使用 WatchFaceSDK-ObjC！本文档介绍集成包的内容结构。

---

## 📦 包内容清单

```
Output-WatchFace-ObjC/
│
├── WatchFaceSDK_ObjC.xcframework/     # 主 Framework (312KB)
│   ├── ios-arm64/                     # iOS 真机版本 (arm64)
│   └── ios-arm64_x86_64-simulator/    # iOS 模拟器版本 (arm64 + x86_64)
│
├── README.md                          # 完整集成文档 (21KB, 789 行)
├── QUICK_START.md                     # 5 分钟快速开始 (4.1KB, 187 行)
├── CHANGELOG.md                       # 版本更新日志 (2.8KB, 117 行)
├── LICENSE                            # 许可协议 (2.1KB, 57 行)
├── WatchFaceSDK-ObjC.podspec          # CocoaPods 配置文件 (1.9KB, 53 行)
└── PACKAGE_CONTENTS.md                # 本文件
```

---

## 📖 文档说明

### 1️⃣ README.md - 完整集成文档

**推荐首先阅读！** 包含：

- ✅ 功能特性介绍
- ✅ 系统要求
- ✅ 详细安装步骤
- ✅ 完整 API 文档
- ✅ Objective-C 和 Swift 示例代码
- ✅ 常见问题解答

**适用场景**: 需要详细了解 SDK 所有功能和 API

---

### 2️⃣ QUICK_START.md - 快速开始指南

**5 分钟上手！** 包含：

- 📦 Framework 集成步骤
- 🚀 最小可运行示例
- 🎨 时间位置和颜色选项
- 💡 完整代码示例

**适用场景**: 快速体验和集成基本功能

---

### 3️⃣ CHANGELOG.md - 版本更新日志

记录所有版本的更新内容：

- ✨ 新增功能
- 🔄 功能变更
- 🐛 问题修复
- ⚠️ 弃用提醒

**适用场景**: 了解版本变化，升级参考

---

### 4️⃣ LICENSE - 许可协议

软件使用许可协议，使用前请仔细阅读。

---

### 5️⃣ WatchFaceSDK-ObjC.podspec - CocoaPods 配置

用于 CocoaPods 集成的配置文件。

---

## 🚀 快速集成指南

### 步骤 1: 选择集成方式

**方式 A: 手动集成 (推荐)**

1. 将 `WatchFaceSDK_ObjC.xcframework` 拖入项目
2. 添加依赖的 Framework:
   - WatchProtocolSDK.xcframework
   - ABParTool.xcframework
3. 设置为 **Embed & Sign**

**方式 B: CocoaPods 集成**

```ruby
pod 'WatchFaceSDK-ObjC', :path => './Output-WatchFace-ObjC'
```

---

### 步骤 2: 导入头文件

**Objective-C:**
```objc
#import <WatchFaceSDK_ObjC/WFManager.h>
```

**Swift:**

在 Bridging Header 中添加上述导入。

---

### 步骤 3: 开始使用

```objc
WFManager *manager = [WFManager sharedInstance];

// 检查连接
if ([manager isDeviceConnected]) {
    // 上传自定义表盘
    [manager uploadCustomWatchFaceWithImage:image
                              timePosition:WFTimePositionTopLeft
                                     color:WFDialColorWhite
                                  delegate:self
                                     error:nil];
}
```

详细步骤请查看 **QUICK_START.md** 或 **README.md**。

---

## 📋 依赖要求

### 必需依赖

| Framework | 说明 | 来源 |
|-----------|------|------|
| WatchProtocolSDK.xcframework | 手表通信协议 SDK | 项目提供 |
| ABParTool.xcframework | PAR 格式转换工具 | 项目提供 |

### 系统框架

- Foundation.framework
- UIKit.framework
- CoreGraphics.framework
- CoreBluetooth.framework

---

## 🎯 Framework 架构支持

### iOS 真机
- ✅ arm64

### iOS 模拟器
- ✅ arm64 (Apple Silicon Mac)
- ✅ x86_64 (Intel Mac)

---

## 📊 Framework 信息

| 属性 | 值 |
|------|-----|
| 大小 | 312KB |
| 最低 iOS 版本 | 13.0 |
| 语言 | Pure Objective-C |
| Swift 依赖 | 无 |
| 二进制类型 | Dynamic Library |

---

## 📞 技术支持

### 获取帮助

1. **查看文档**: 先查看 README.md 和 QUICK_START.md
2. **常见问题**: README.md 中包含常见问题解答
3. **联系我们**:
   - 📧 Email: 315082431@qq.com
   - 🐛 Issues: [GitHub Issues](https://github.com/BruceZhang2017/SmartBracelet/issues)

---

## 🔄 更新说明

### 当前版本

**v1.0.0** (2026-01-13)

### 获取更新

- 通过项目方提供的最新版本包
- 通过 CocoaPods 更新（如已配置）

查看 **CHANGELOG.md** 了解详细更新内容。

---

## ✅ 开始使用

**推荐阅读顺序：**

1. 📖 **QUICK_START.md** - 5 分钟快速体验
2. 📚 **README.md** - 了解完整功能
3. 📋 **CHANGELOG.md** - 查看版本历史

**祝您使用愉快！** 🎉

---

*最后更新: 2026-01-13*
