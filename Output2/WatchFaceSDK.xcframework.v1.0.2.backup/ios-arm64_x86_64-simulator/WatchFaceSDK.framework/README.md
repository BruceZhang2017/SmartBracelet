# WatchFaceSDK

**版本**: 1.0.0
**协议**: XGZT
**更新时间**: 2025-12-30

---

## 📋 简介

**WatchFaceSDK** 是从 SmartBracelet 项目中抽离出来的表盘管理专用 SDK，专注于 **XGZT 协议**设备的表盘下载、自定义和上传功能。

### 主要特性

✅ **市场表盘上传** - 支持从服务器下载的表盘文件上传到设备
✅ **自定义表盘** - 支持用户图片转换为表盘并上传
✅ **智能图片处理** - 自动裁剪、压缩、格式转换（PAR）
✅ **圆形/方形适配** - 自动适配不同屏幕形状
✅ **传输进度监控** - 实时传输进度回调
✅ **无UI依赖** - 纯业务逻辑，不包含任何UI代码

---

## 🏗 架构

```
WatchFaceSDK/
├── Core/           # 核心管理器和传输引擎
├── Models/         # 数据模型
├── Transfer/       # XGZT协议封装和分包管理
├── Extensions/     # 图片处理工具
├── Protocols/      # 回调代理协议
└── Utils/          # 工具类
```

---

## 📦 依赖

| 依赖项 | 版本 | 说明 |
|--------|------|------|
| WatchProtocolSDK | 1.0.0 | XGZT 蓝牙协议 SDK |
| ABParTool.framework | - | PAR 格式转换工具 |

---

## 🚀 快速开始

### 1. 检查设备连接

```swift
import WatchFaceSDK

// 检查设备是否连接
if WatchFaceManager.shared.isDeviceConnected() {
    print("✅ 设备已连接")

    // 获取设备屏幕信息
    if let screenInfo = WatchFaceManager.shared.getCurrentDeviceScreenInfo() {
        print("屏幕尺寸: \(screenInfo.width)x\(screenInfo.height)")
        print("屏幕形状: \(screenInfo.shape)")
        print("MTU: \(screenInfo.mtu)")
    }
} else {
    print("❌ 设备未连接")
}
```

### 2. 上传自定义表盘

```swift
import WatchFaceSDK

class MyViewController: UIViewController, TransferDelegate {

    func uploadCustomWatchFace() {
        guard let image = UIImage(named: "my_watchface") else { return }

        do {
            try WatchFaceManager.shared.uploadCustomWatchFace(
                image: image,
                timePosition: .center,      // 时间位置：居中
                color: .white,               // 颜色：白色
                delegate: self
            )
        } catch {
            print("❌ 上传失败: \(error)")
        }
    }

    // MARK: - TransferDelegate

    func transferDidStart() {
        print("🚀 开始传输")
        // 显示进度UI
    }

    func transferDidUpdateProgress(_ progress: TransferProgress) {
        print("📊 进度: \(progress.percentage * 100)%")
        // 更新进度条
    }

    func transferDidComplete() {
        print("✅ 传输成功")
        // 隐藏进度UI，显示成功提示
    }

    func transferDidFail(error: Error) {
        print("❌ 传输失败: \(error)")
        // 显示错误提示
    }
}
```

### 3. 上传市场表盘

```swift
// 从本地文件上传
let fileURL = // ... 表盘文件路径
do {
    try WatchFaceManager.shared.uploadMarketWatchFace(
        fileURL: fileURL,
        delegate: self
    )
} catch {
    print("❌ 上传失败: \(error)")
}

// 或从 Data 上传
let data = // ... 表盘数据
do {
    try WatchFaceManager.shared.uploadMarketWatchFace(
        data: data,
        delegate: self
    )
} catch {
    print("❌ 上传失败: \(error)")
}
```

---

## 🎨 自定义表盘选项

### 时间位置 (TimePosition)

| 选项 | 说明 |
|------|------|
| `.none` | 无时间显示 |
| `.topLeft` | 左上角 |
| `.bottomLeft` | 左下角 |
| `.topRight` | 右上角 |
| `.bottomRight` | 右下角 |
| `.center` | 居中 |

### 表盘颜色 (DialColor)

| 选项 | 颜色 |
|------|------|
| `.white` | 白色 |
| `.black` | 黑色 |
| `.yellow` | 黄色 |
| `.orange` | 橙色 |
| `.pink` | 粉色 |
| `.purple` | 紫色 |
| `.blue` | 蓝色 |
| `.cyan` | 青色 |
| `.green` | 绿色 |

---

## 🔧 高级功能

### 图片验证

```swift
let image = UIImage(named: "watchface")!
let validation = WatchFaceManager.shared.validateImage(image)

if validation.isValid {
    print("✅ 图片满足要求")
} else {
    print("❌ \(validation.message)")
}
```

### 获取推荐图片尺寸

```swift
if let recommendedSize = WatchFaceManager.shared.getRecommendedImageSize() {
    print("推荐图片尺寸: \(recommendedSize)")
}
```

### 传输控制

```swift
// 暂停传输
WatchFaceManager.shared.pauseTransfer()

// 取消传输
WatchFaceManager.shared.cancelTransfer()

// 重试传输
WatchFaceManager.shared.retryTransfer()
```

---

## 📊 数据模型

### DeviceScreenInfo - 设备屏幕信息

```swift
public struct DeviceScreenInfo {
    public let width: Int          // 屏幕宽度
    public let height: Int         // 屏幕高度
    public let shape: ScreenShape  // 屏幕形状（round/square）
    public let mtu: Int            // 蓝牙MTU
}
```

### TransferProgress - 传输进度

```swift
public struct TransferProgress {
    public let currentPacket: Int      // 当前包序号
    public let totalPackets: Int       // 总包数
    public let bytesTransferred: Int   // 已传输字节数
    public let totalBytes: Int         // 总字节数
    public let percentage: Float       // 百分比 (0.0-1.0)
    public let message: String         // 进度消息
}
```

---

## ⚠️ 错误处理

### WatchFaceError 错误类型

| 错误 | 说明 |
|------|------|
| `.deviceNotConnected` | 设备未连接 |
| `.deviceNotSupported` | 设备不支持该功能 |
| `.imageProcessFailed` | 图片处理失败 |
| `.compressionFailed` | 压缩失败 |
| `.exceedMaxFileSize` | 文件大小超过限制 |
| `.transferFailed` | 传输失败 |
| `.invalidMTU` | 无效的MTU值 |

### 错误处理示例

```swift
do {
    try WatchFaceManager.shared.uploadCustomWatchFace(
        image: image,
        timePosition: .center,
        color: .white,
        delegate: self
    )
} catch WatchFaceError.deviceNotConnected {
    showAlert("请先连接设备")
} catch WatchFaceError.imageProcessFailed {
    showAlert("图片处理失败，请选择其他图片")
} catch {
    showAlert("上传失败: \(error.localizedDescription)")
}
```

---

## 🔍 日志

SDK 使用 `WatchProtocolSDK` 的 `XLogger` 记录日志：

```
🎨 WatchFaceSDK 初始化完成
🚀 开始传输表盘 - 类型: custom, 数据大小: 98304 bytes
🎨 设置自定义表盘时间位置和颜色: center, white
📡 查询设备 MTU...
✅ MTU 查询成功: 517
⚙️ 配置传输参数 - 总包数: 492, MTU: 517
📤 发送数据包 1/492 - 偏移: 0, 大小: 200, 进度: 0%
...
✅ 所有数据包已发送完成
🎉 表盘传输完成
```

---

## 📝 完整示例

查看 `WatchFaceSDK_ARCHITECTURE.md` 获取完整的架构设计文档。

查看 `USAGE_EXAMPLES.md` 获取更多使用示例。

---

## 🆘 常见问题

### Q: 为什么上传失败显示"设备未连接"？
A: 确保调用 SDK 前设备已通过 `WatchProtocolSDK` 成功连接。

### Q: 图片处理失败怎么办？
A: 检查图片尺寸是否足够大（至少等于设备屏幕尺寸），格式是否正确。

### Q: 如何查看传输进度？
A: 实现 `TransferDelegate` 协议的 `transferDidUpdateProgress` 方法。

### Q: 支持哪些屏幕形状？
A: 支持圆形（round）和方形（square）两种屏幕形状。

---

## 📄 许可证

Copyright © 2025 bruce Innovations. All rights reserved.

---

## 🔗 相关链接

- [WatchProtocolSDK 文档](../BUILD_SUCCESS.md)
- [XGZT 协议说明](../SDK_DOCUMENTATION.md)
- [项目主页](https://github.com/BruceZhang2017/SmartBracelet)
