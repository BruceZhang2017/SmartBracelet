# WatchFaceSDK 接入指南（中文版）

## 📋 目录

- [简介](#简介)
- [系统要求](#系统要求)
- [快速集成](#快速集成)
- [核心功能](#核心功能)
- [API 文档](#api-文档)
- [使用示例](#使用示例)
- [常见问题](#常见问题)
- [技术支持](#技术支持)

---

## 简介

WatchFaceSDK 是一个强大的智能手表表盘管理框架，支持市场表盘上传和自定义表盘创建。

### 主要特性

- ✅ **市场表盘上传** - 支持上传预制的 .bin 格式表盘文件
- ✅ **自定义表盘** - 将任意图片转换为手表表盘
- ✅ **智能图片处理** - 自动裁剪、压缩和格式转换（PAR 格式）
- ✅ **多种屏幕支持** - 自动适配圆形和方形屏幕
- ✅ **实时进度回调** - 传输过程完整的进度反馈
- ✅ **简单易用** - 清晰的 API 设计，几行代码即可完成集成

### SDK 架构

```
WatchFaceSDK
├── WatchFaceManager (主入口)
├── WatchFaceTransferEngine (传输引擎)
├── ImageProcessor (图片处理)
└── 依赖: WatchProtocolSDK + ABParTool
```

---

## 系统要求

| 项目 | 要求 |
|------|------|
| iOS 版本 | iOS 12.0 或更高 |
| Xcode | Xcode 12.0 或更高 |
| Swift | Swift 5.0 或更高 |
| 架构 | arm64 (真机) / arm64 + x86_64 (模拟器) |

---

## 快速集成

### 步骤 1：添加框架到项目

✅ **所有框架已包含在发布包中！**

将以下 3 个 XCFramework 文件拖入您的 Xcode 项目（均在 WatchFaceSDK-Release 目录中）：

```
1. WatchFaceSDK.xcframework        # 表盘管理 SDK
2. WatchProtocolSDK.xcframework    # 底层协议 SDK（依赖）
3. ABParTool.xcframework           # PAR 图片处理工具（依赖）
```

**注意：** 无需单独下载依赖框架，所有必需的框架都已包含在此发布包中。

### 步骤 2：配置框架嵌入方式

1. 选择项目 Target
2. 进入 **General** > **Frameworks, Libraries, and Embedded Content**
3. 将所有框架设置为 **Embed & Sign**

![Framework Settings](https://via.placeholder.com/600x200/4A90E2/FFFFFF?text=Embed+%26+Sign)

### 步骤 3：导入模块

在需要使用的文件中导入：

```swift
import WatchFaceSDK
import WatchProtocolSDK  // 用于设备连接
```

### 步骤 4：验证安装

```swift
// 打印 SDK 信息
WatchFaceSDKConfig.printSDKInfo()

// 输出:
// ==================================================
// WatchFaceSDK v1.0.0 (XGZT) - Build 2025-12-30
// ==================================================
```

---

## 核心功能

### 1. 上传市场表盘

市场表盘是指预制的 .bin 格式表盘文件。

```swift
do {
    let fileURL = Bundle.main.url(forResource: "watchface", withExtension: "bin")!

    try WatchFaceManager.shared.uploadMarketWatchFace(
        fileURL: fileURL,
        delegate: self
    )
} catch {
    print("上传失败: \(error)")
}
```

### 2. 上传自定义表盘

将任意图片转换为手表表盘。

```swift
do {
    guard let image = UIImage(named: "my_photo") else { return }

    try WatchFaceManager.shared.uploadCustomWatchFace(
        image: image,
        timePosition: .center,      // 时间位置：居中
        color: .white,              // 时间颜色：白色
        delegate: self
    )
} catch {
    print("上传失败: \(error)")
}
```

### 3. 传输控制

```swift
// 暂停传输
WatchFaceManager.shared.pauseTransfer()

// 取消传输
WatchFaceManager.shared.cancelTransfer()

// 重试传输
WatchFaceManager.shared.retryTransfer()
```

---

## API 文档

### WatchFaceManager（主入口）

#### 单例访问

```swift
let manager = WatchFaceManager.shared
```

#### 设备状态检查

```swift
// 检查设备是否连接
func isDeviceConnected() -> Bool

// 获取设备屏幕信息
func getCurrentDeviceScreenInfo() -> DeviceScreenInfo?
```

#### 上传市场表盘

```swift
/// 从文件路径上传
func uploadMarketWatchFace(
    fileURL: URL,
    delegate: TransferDelegate?
) throws

/// 从数据上传
func uploadMarketWatchFace(
    data: Data,
    delegate: TransferDelegate?
) throws
```

#### 上传自定义表盘

```swift
/// 从 UIImage 上传
func uploadCustomWatchFace(
    image: UIImage,
    timePosition: TimePosition,  // 时间位置
    color: DialColor,            // 时间颜色
    delegate: TransferDelegate?
) throws

/// 从图片名称上传（Assets）
func uploadCustomWatchFace(
    imageName: String,
    timePosition: TimePosition,
    color: DialColor,
    delegate: TransferDelegate?
) throws

/// 从文件路径上传
func uploadCustomWatchFace(
    fileURL: URL,
    timePosition: TimePosition,
    color: DialColor,
    delegate: TransferDelegate?
) throws
```

#### 图片验证

```swift
/// 验证图片是否满足设备要求
func validateImage(_ image: UIImage) -> (isValid: Bool, message: String)

/// 获取推荐的图片尺寸
func getRecommendedImageSize() -> CGSize?
```

---

## 数据类型

### TimePosition（时间位置）

```swift
public enum TimePosition: Int {
    case none = 0           // 无
    case topLeft = 1        // 左上
    case bottomLeft = 2     // 左下
    case topRight = 3       // 右上
    case bottomRight = 4    // 右下
    case center = 5         // 居中
}
```

### DialColor（时间颜色）

```swift
public enum DialColor: Int {
    case white = 0      // 白色
    case black = 1      // 黑色
    case yellow = 2     // 黄色
    case orange = 3     // 橙色
    case pink = 4       // 粉色
    case purple = 5     // 紫色
    case blue = 6       // 蓝色
    case cyan = 7       // 青色
    case green = 8      // 绿色
}
```

### TransferDelegate（传输回调）

```swift
public protocol TransferDelegate: AnyObject {
    /// 传输开始
    func transferDidStart()

    /// 进度更新
    func transferDidUpdateProgress(_ progress: TransferProgress)

    /// 传输完成
    func transferDidComplete()

    /// 传输失败
    func transferDidFail(error: Error)

    /// 传输取消
    func transferDidCancel()
}
```

### TransferProgress（传输进度）

```swift
public struct TransferProgress {
    public let currentPacket: Int      // 当前包序号
    public let totalPackets: Int       // 总包数
    public let bytesTransferred: Int   // 已传输字节数
    public let totalBytes: Int         // 总字节数
    public let percentage: Float       // 进度百分比 (0.0 - 1.0)
    public let message: String         // 进度文本（如 "50.00%"）
}
```

---

## 使用示例

### 完整示例：上传自定义表盘

```swift
import UIKit
import WatchFaceSDK

class WatchFaceViewController: UIViewController {

    // MARK: - UI 元素
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var uploadButton: UIButton!

    // MARK: - 上传表盘
    @IBAction func uploadWatchFace(_ sender: UIButton) {
        // 1. 检查设备连接
        guard WatchFaceManager.shared.isDeviceConnected() else {
            showAlert(message: "设备未连接")
            return
        }

        // 2. 选择图片
        guard let image = UIImage(named: "watchface_background") else {
            showAlert(message: "图片不存在")
            return
        }

        // 3. 验证图片
        let validation = WatchFaceManager.shared.validateImage(image)
        guard validation.isValid else {
            showAlert(message: validation.message)
            return
        }

        // 4. 开始上传
        do {
            try WatchFaceManager.shared.uploadCustomWatchFace(
                image: image,
                timePosition: .center,
                color: .white,
                delegate: self
            )

            uploadButton.isEnabled = false
            statusLabel.text = "准备上传..."

        } catch {
            showAlert(message: "上传失败: \(error.localizedDescription)")
        }
    }

    // MARK: - 取消上传
    @IBAction func cancelUpload(_ sender: UIButton) {
        WatchFaceManager.shared.cancelTransfer()
    }

    // MARK: - 辅助方法
    private func showAlert(message: String) {
        let alert = UIAlertController(
            title: "提示",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - TransferDelegate
extension WatchFaceViewController: TransferDelegate {

    func transferDidStart() {
        DispatchQueue.main.async {
            self.statusLabel.text = "开始传输..."
            self.progressView.progress = 0.0
        }
    }

    func transferDidUpdateProgress(_ progress: TransferProgress) {
        DispatchQueue.main.async {
            self.progressView.progress = progress.percentage
            self.statusLabel.text = "传输中: \(progress.message)"

            print("📊 进度: \(progress.currentPacket)/\(progress.totalPackets) - \(progress.message)")
        }
    }

    func transferDidComplete() {
        DispatchQueue.main.async {
            self.statusLabel.text = "上传成功！"
            self.progressView.progress = 1.0
            self.uploadButton.isEnabled = true

            self.showAlert(message: "表盘已成功上传到设备")
        }
    }

    func transferDidFail(error: Error) {
        DispatchQueue.main.async {
            self.statusLabel.text = "上传失败"
            self.uploadButton.isEnabled = true

            self.showAlert(message: "上传失败: \(error.localizedDescription)")
        }
    }

    func transferDidCancel() {
        DispatchQueue.main.async {
            self.statusLabel.text = "已取消"
            self.uploadButton.isEnabled = true

            self.showAlert(message: "上传已取消")
        }
    }
}
```

### 示例：获取设备信息

```swift
if let screenInfo = WatchFaceManager.shared.getCurrentDeviceScreenInfo() {
    print("设备屏幕信息:")
    print("  宽度: \(screenInfo.width)")
    print("  高度: \(screenInfo.height)")
    print("  形状: \(screenInfo.shape)")  // .round 或 .square

    if let recommendedSize = WatchFaceManager.shared.getRecommendedImageSize() {
        print("推荐图片尺寸: \(recommendedSize)")
    }
} else {
    print("设备未连接或不支持")
}
```

### 示例：上传市场表盘

```swift
class MarketWatchFaceViewController: UIViewController, TransferDelegate {

    func uploadMarketWatchFace() {
        // 从本地文件上传
        guard let fileURL = Bundle.main.url(forResource: "market_dial_001", withExtension: "bin") else {
            print("文件不存在")
            return
        }

        do {
            try WatchFaceManager.shared.uploadMarketWatchFace(
                fileURL: fileURL,
                delegate: self
            )
            print("开始上传市场表盘...")
        } catch {
            print("上传失败: \(error)")
        }
    }

    // MARK: - TransferDelegate
    func transferDidStart() {
        print("🚀 传输开始")
    }

    func transferDidUpdateProgress(_ progress: TransferProgress) {
        print("📊 进度: \(progress.message)")
    }

    func transferDidComplete() {
        print("✅ 传输成功")
    }

    func transferDidFail(error: Error) {
        print("❌ 传输失败: \(error)")
    }

    func transferDidCancel() {
        print("⏹ 传输取消")
    }
}
```

---

## 常见问题

### 1. 设备连接相关

**Q: 如何连接设备？**

A: WatchFaceSDK 本身不负责设备连接，需要先使用 WatchProtocolSDK 连接设备：

```swift
import WatchProtocolSDK

// 连接设备
XGZTDeviceManager.shared.connectDevice(peripheral: peripheral) { success in
    if success {
        print("设备已连接，可以使用 WatchFaceSDK")
    }
}
```

**Q: 如何判断设备是否支持表盘上传？**

A: 检查设备屏幕信息是否存在：

```swift
if WatchFaceManager.shared.getCurrentDeviceScreenInfo() != nil {
    print("设备支持表盘上传")
} else {
    print("设备不支持或未连接")
}
```

### 2. 图片处理相关

**Q: 支持哪些图片格式？**

A: 支持所有 iOS 标准图片格式（PNG、JPG、HEIC 等），SDK 会自动转换为设备所需的 PAR 格式。

**Q: 图片尺寸有什么要求？**

A:
- 最小尺寸：应不小于设备屏幕尺寸（如 240x240、240x280 等）
- 推荐尺寸：设备屏幕尺寸的 2 倍（如 480x480）
- 最大文件：自动压缩到 120KB 以内

```swift
// 获取推荐尺寸
if let size = WatchFaceManager.shared.getRecommendedImageSize() {
    print("推荐图片尺寸: \(size)")
}
```

**Q: 圆形屏幕如何处理图片？**

A: SDK 会自动识别设备屏幕形状并进行裁剪：
- 方形屏幕：居中裁剪
- 圆形屏幕：圆形裁剪（保留中心区域）

### 3. 传输相关

**Q: 传输需要多长时间？**

A: 通常 10-30 秒，取决于：
- 文件大小（120KB 以内）
- 蓝牙信号强度
- 设备型号

**Q: 传输失败怎么办？**

A: 常见原因和解决方案：

| 错误 | 原因 | 解决方案 |
|------|------|---------|
| `deviceNotConnected` | 设备未连接 | 确保设备已通过 WatchProtocolSDK 连接 |
| `deviceNotSupported` | 设备不支持 | 更换支持的设备型号 |
| `imageProcessFailed` | 图片处理失败 | 检查图片格式和尺寸 |
| `transferFailed` | 传输失败 | 调用 `retryTransfer()` 重试 |

**Q: 可以同时上传多个表盘吗？**

A: 不可以。SDK 同时只支持一个传输任务，需要等待当前任务完成后再开始新任务。

### 4. 错误处理

**Q: 如何处理错误？**

A: 使用 do-catch 捕获错误：

```swift
do {
    try WatchFaceManager.shared.uploadCustomWatchFace(
        image: image,
        timePosition: .center,
        color: .white,
        delegate: self
    )
} catch WatchFaceError.deviceNotConnected {
    print("设备未连接")
} catch WatchFaceError.imageProcessFailed {
    print("图片处理失败")
} catch {
    print("其他错误: \(error)")
}
```

### 5. 性能优化

**Q: 如何优化上传速度？**

A:
1. 使用较小的图片尺寸（推荐设备尺寸的 2 倍）
2. 确保蓝牙信号良好
3. 避免在上传过程中进行其他蓝牙操作

**Q: 如何减少内存占用？**

A:
1. 图片处理会自动释放内存
2. 避免同时加载多张大图
3. 传输完成后 SDK 会自动清理缓存

---

## 注意事项

### ⚠️ 重要提示

1. **设备连接**
   - 使用前必须先通过 WatchProtocolSDK 连接设备
   - 检查 `isDeviceConnected()` 返回 `true`

2. **线程安全**
   - TransferDelegate 回调可能在后台线程执行
   - UI 更新必须切换到主线程：
   ```swift
   DispatchQueue.main.async {
       // 更新 UI
   }
   ```

3. **图片要求**
   - 建议图片尺寸 ≥ 设备屏幕尺寸
   - 最终文件会自动压缩到 120KB 以内
   - 圆形屏幕会自动圆形裁剪

4. **传输控制**
   - 同时只支持一个传输任务
   - 传输过程中不要断开设备连接
   - 传输失败可调用 `retryTransfer()` 重试

5. **错误处理**
   - 始终使用 try-catch 处理可能的错误
   - 实现完整的 TransferDelegate 方法

---

## 调试技巧

### 启用详细日志

```swift
// 在 AppDelegate 中启用详细日志
WatchFaceSDKConfig.configuration.enableVerboseLogging = true
```

### 打印 SDK 信息

```swift
WatchFaceSDKConfig.printSDKInfo()
// 输出:
// ==================================================
// WatchFaceSDK v1.0.0 (XGZT) - Build 2025-12-30
// ==================================================
```

### 监控传输进度

```swift
func transferDidUpdateProgress(_ progress: TransferProgress) {
    print("""
    📊 传输进度:
       当前包: \(progress.currentPacket)/\(progress.totalPackets)
       已传输: \(progress.bytesTransferred)/\(progress.totalBytes) bytes
       进度: \(progress.message)
    """)
}
```

---

## 技术支持

### 📚 相关文档

- `README.md` - SDK 完整使用手册
- `USAGE_EXAMPLES.md` - 详细示例代码
- `WatchFaceSDK_ARCHITECTURE.md` - 架构设计文档
- `INTEGRATION_GUIDE_EN.md` - 英文接入指南

### 🔗 相关链接

- WatchProtocolSDK 文档
- ABParTool 使用说明

### 💬 联系我们

如有技术问题或需要支持，请联系：

- Email: support@example.com
- 技术支持团队

---

**© 2025 bruce Innovations. All rights reserved.**

**WatchFaceSDK v1.0.0**
