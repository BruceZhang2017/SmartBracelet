# 👋 欢迎使用 WatchFaceSDK / Welcome to WatchFaceSDK

## 🚀 快速开始 (Quick Start)

### 中文用户 (Chinese Users)
请先阅读 **[DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md)** 了解所有可用文档。

**推荐阅读顺序：**
1. 📚 [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md) - 文档索引（了解所有文档）
2. 🚀 [INTEGRATION_GUIDE_CN.md](INTEGRATION_GUIDE_CN.md) - **中文接入指南（推荐优先阅读）**
3. 💡 [USAGE_EXAMPLES.md](USAGE_EXAMPLES.md) - 示例代码

---

### English Users
Please read **[DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md)** first to understand all available documentation.

**Recommended Reading Order:**
1. 📚 [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md) - Documentation Index (Overview)
2. 🚀 [INTEGRATION_GUIDE_EN.md](INTEGRATION_GUIDE_EN.md) - **English Integration Guide (Start Here)**
3. 💡 [USAGE_EXAMPLES.md](USAGE_EXAMPLES.md) - Example Code

---

## 📦 包含的文件 (Package Contents)

```
WatchFaceSDK-Release/
├── 📱 框架 / Frameworks:
│   ├── WatchFaceSDK.xcframework        ← 核心 SDK / Core SDK
│   ├── WatchProtocolSDK.xcframework    ← 依赖 / Dependency
│   └── ABParTool.xcframework           ← 依赖 / Dependency
│
├── 📚 文档 / Documentation:
│   ├── START_HERE.md                   ← 从这里开始 / Start Here
│   ├── DOCUMENTATION_INDEX.md          ← 文档索引 / Doc Index
│   ├── INTEGRATION_GUIDE_CN.md         ← 中文接入指南 / Chinese Guide
│   ├── INTEGRATION_GUIDE_EN.md         ← 英文接入指南 / English Guide
│   ├── INTEGRATION_GUIDE.md            ← 快速指南 / Quick Guide
│   ├── README.md                       ← 使用手册 / Manual
│   ├── USAGE_EXAMPLES.md               ← 示例代码 / Examples
│   └── WatchFaceSDK_ARCHITECTURE.md    ← 架构文档 / Architecture
│
└── 📄 VERSION.txt                      ← 版本信息 / Version Info
```

---

## ⚡️ 30 秒快速集成 (30-Second Integration)

### Swift Code Example:

```swift
import WatchFaceSDK

// 1. Upload custom watch face
try WatchFaceManager.shared.uploadCustomWatchFace(
    image: UIImage(named: "myPhoto")!,
    timePosition: .center,
    color: .white,
    delegate: self
)

// 2. Implement delegate
extension MyViewController: TransferDelegate {
    func transferDidComplete() {
        print("✅ Upload successful!")
    }
}
```

**👉 查看完整文档获取详细说明 / See full documentation for details**

---

## 🔗 依赖框架 (Dependencies)

✅ **所有依赖框架已包含在此 ZIP 包中！**

✅ **All dependency frameworks are included in this ZIP package!**

使用 WatchFaceSDK 需要同时集成以下框架（均已包含）：

To use WatchFaceSDK, you need to integrate the following frameworks (all included):

1. ✅ **WatchFaceSDK.xcframework** - 核心 SDK / Core SDK
2. ✅ **WatchProtocolSDK.xcframework** - 底层协议 / Protocol SDK
3. ✅ **ABParTool.xcframework** - 图片处理 / Image Tool

**📌 集成步骤 / Integration Steps:**
1. 将这三个 `.xcframework` 文件拖入 Xcode 项目
2. 设置为 **Embed & Sign**
3. 开始使用！

**📌 Important:**
1. Drag all three `.xcframework` files into Xcode project
2. Set as **Embed & Sign**
3. Start using!

---

## 📞 技术支持 (Technical Support)

### 遇到问题？(Having Issues?)

1. 📖 查看文档 FAQ 部分 / Check FAQ in documentation
2. 💡 参考示例代码 / Refer to example code
3. 🔍 检查依赖是否正确安装 / Verify dependencies are installed

### 联系我们 (Contact Us)

- Email: support@example.com
- 技术支持 / Tech Support Team

---

## ⭐️ SDK 信息 (SDK Information)

```
Name: WatchFaceSDK
Version: 1.0.0
Protocol: XGZT
Build Date: 2025-12-30
Minimum iOS: 12.0
```

---

**🎉 开始使用 WatchFaceSDK 吧！/ Start using WatchFaceSDK!**

**© 2025 bruce Innovations. All rights reserved.**
