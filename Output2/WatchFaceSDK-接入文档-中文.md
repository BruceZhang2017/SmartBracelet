# WatchFaceSDK 接入文档 (中文)

## 📚 目录

1. [概述](#概述)
2. [系统要求](#系统要求)
3. [集成 SDK](#集成-sdk)
4. [核心功能](#核心功能)
5. [API 参考](#api-参考)
6. [使用示例](#使用示例)
7. [错误处理](#错误处理)
8. [最佳实践](#最佳实践)
9. [常见问题](#常见问题)

---

## 概述

WatchFaceSDK 是一个用于智能手表表盘上传的 iOS SDK，支持市场表盘和自定义表盘的传输功能。

### 主要特性

- ✅ **市场表盘上传**: 支持预制表盘文件上传
- ✅ **自定义表盘**: 从图片生成自定义表盘
- ✅ **图片处理**: 自动处理图片格式、大小和压缩
- ✅ **屏幕适配**: 自动适配圆形和方形屏幕
- ✅ **进度回调**: 实时获取传输进度
- ✅ **错误处理**: 完善的错误提示和处理机制

### 架构说明

WatchFaceSDK 依赖于 WatchProtocolSDK 进行蓝牙通信，使用协议化的方式传输表盘数据。

```
┌─────────────────────┐
│   Your App          │
├─────────────────────┤
│  WatchFaceSDK       │  ← 表盘管理层
├─────────────────────┤
│  WatchProtocolSDK   │  ← 蓝牙通信层
├─────────────────────┤
│  CoreBluetooth      │  ← 系统蓝牙框架
└─────────────────────┘
```

---

## 系统要求

- **iOS**: 12.0 及以上
- **Xcode**: 12.0 及以上
- **Swift**: 5.0 及以上
- **依赖**: WatchProtocolSDK v1.0.2

---

## 集成 SDK

### 步骤 1: 添加 Framework

1. 将 `WatchFaceSDK.xcframework` 拖入 Xcode 项目
2. 在 Target -> General -> Frameworks, Libraries, and Embedded Content 中确认已添加
3. 设置 Embed 为 "Embed & Sign"

### 步骤 2: 配置依赖

确保已集成 WatchProtocolSDK 及其依赖。在 `Podfile` 中添加：

```ruby
# WatchProtocolSDK 依赖
pod 'SwiftyJSON'
pod 'CryptoSwift'
```

然后执行：
```bash
pod install
```

### 步骤 3: 配置权限

在 `Info.plist` 中添加必要权限：

```xml
<!-- 蓝牙权限 -->
<key>NSBluetoothAlwaysUsageDescription</key>
<string>需要使用蓝牙连接智能手表设备</string>

<!-- 相册访问权限 (用于自定义表盘) -->
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册选择表盘图片</string>

<!-- 相机权限 (可选) -->
<key>NSCameraUsageDescription</key>
<string>需要使用相机拍摄表盘图片</string>
```

### 步骤 4: 导入模块

```swift
import WatchFaceSDK
import WatchProtocolSDK
```

---

## 核心功能

### 1. 表盘管理器

`WatchFaceManager` 是 SDK 的核心类，采用单例模式：

```swift
let manager = WatchFaceManager.shared
```

### 2. 上传市场表盘

市场表盘是预制的表盘文件，通常是经过专门设计的表盘包。

```swift
func uploadMarketWatchFace(
    fileURL: URL,
    delegate: TransferDelegate?
) throws
```

**参数说明**:
- `fileURL`: 表盘文件路径
- `delegate`: 传输进度回调代理

### 3. 上传自定义表盘

自定义表盘从图片生成，可以自定义时间位置和颜色。

```swift
func uploadCustomWatchFace(
    image: UIImage,
    timePosition: TimePosition,
    color: UIColor,
    delegate: TransferDelegate?
) throws
```

**参数说明**:
- `image`: 表盘背景图片
- `timePosition`: 时间显示位置 (.top, .center, .bottom)
- `color`: 时间显示颜色
- `delegate`: 传输进度回调代理

### 4. 时间位置枚举

```swift
public enum TimePosition {
    case top      // 顶部
    case center   // 中间
    case bottom   // 底部
}
```

---

## API 参考

### WatchFaceManager

#### 单例实例
```swift
static let shared: WatchFaceManager
```

#### 上传市场表盘
```swift
func uploadMarketWatchFace(
    fileURL: URL,
    delegate: TransferDelegate?
) throws
```

**抛出错误**:
- `WatchFaceError.fileNotFound`: 文件不存在
- `WatchFaceError.invalidFileFormat`: 文件格式无效
- `WatchFaceError.fileSizeExceeded`: 文件大小超限
- `WatchFaceError.deviceNotConnected`: 设备未连接

#### 上传自定义表盘
```swift
func uploadCustomWatchFace(
    image: UIImage,
    timePosition: TimePosition = .center,
    color: UIColor = .white,
    delegate: TransferDelegate?
) throws
```

**抛出错误**:
- `WatchFaceError.invalidImage`: 图片无效
- `WatchFaceError.imageProcessingFailed`: 图片处理失败
- `WatchFaceError.deviceNotConnected`: 设备未连接

#### 取消传输
```swift
func cancelTransfer()
```

### TransferDelegate

传输进度回调协议：

```swift
protocol TransferDelegate: AnyObject {
    /// 传输开始
    func transferDidStart()

    /// 传输进度更新
    /// - Parameter progress: 传输进度对象
    func transferDidUpdateProgress(_ progress: TransferProgress)

    /// 传输完成
    func transferDidComplete()

    /// 传输失败
    /// - Parameter error: 错误信息
    func transferDidFail(error: Error)
}
```

### TransferProgress

传输进度对象：

```swift
public struct TransferProgress {
    public let currentPacket: Int      // 当前包序号
    public let totalPackets: Int       // 总包数
    public let percentage: Double      // 进度百分比 (0.0 - 1.0)
    public let speed: Double           // 传输速度 (bytes/s)
    public let remainingTime: TimeInterval  // 预计剩余时间 (秒)
}
```

---

## 使用示例

### 示例 1: 上传市场表盘

```swift
import UIKit
import WatchFaceSDK

class MarketWatchFaceViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        uploadMarketWatchFace()
    }

    func uploadMarketWatchFace() {
        // 获取表盘文件路径
        guard let fileURL = Bundle.main.url(
            forResource: "watchface_market_001",
            withExtension: "bin"
        ) else {
            print("❌ 表盘文件不存在")
            return
        }

        // 上传表盘
        do {
            try WatchFaceManager.shared.uploadMarketWatchFace(
                fileURL: fileURL,
                delegate: self
            )
        } catch {
            print("❌ 上传失败: \(error.localizedDescription)")
            showError(error)
        }
    }

    func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "上传失败",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - TransferDelegate

extension MarketWatchFaceViewController: TransferDelegate {

    func transferDidStart() {
        DispatchQueue.main.async {
            print("🚀 开始上传表盘")
            // 显示加载指示器
        }
    }

    func transferDidUpdateProgress(_ progress: TransferProgress) {
        DispatchQueue.main.async {
            let percentage = Int(progress.percentage * 100)
            print("📊 上传进度: \(percentage)%")
            print("⚡ 速度: \(progress.speed) bytes/s")
            print("⏱ 剩余时间: \(progress.remainingTime) 秒")
            // 更新进度条
        }
    }

    func transferDidComplete() {
        DispatchQueue.main.async {
            print("✅ 表盘上传成功")
            // 隐藏加载指示器，显示成功提示
        }
    }

    func transferDidFail(error: Error) {
        DispatchQueue.main.async {
            print("❌ 上传失败: \(error.localizedDescription)")
            self.showError(error)
        }
    }
}
```

### 示例 2: 上传自定义表盘

```swift
import UIKit
import WatchFaceSDK

class CustomWatchFaceViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var statusLabel: UILabel!

    var selectedImage: UIImage?

    // MARK: - Actions

    @IBAction func selectImageTapped(_ sender: UIButton) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }

    @IBAction func uploadTapped(_ sender: UIButton) {
        uploadCustomWatchFace()
    }

    // MARK: - Upload

    func uploadCustomWatchFace() {
        guard let image = selectedImage else {
            showAlert("请先选择图片")
            return
        }

        do {
            try WatchFaceManager.shared.uploadCustomWatchFace(
                image: image,
                timePosition: .center,
                color: .white,
                delegate: self
            )
        } catch {
            print("❌ 上传失败: \(error)")
            showAlert(error.localizedDescription)
        }
    }

    func showAlert(_ message: String) {
        let alert = UIAlertController(
            title: "提示",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate

extension CustomWatchFaceViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        if let image = info[.originalImage] as? UIImage {
            selectedImage = image
            imageView.image = image
        }
        picker.dismiss(animated: true)
    }
}

// MARK: - TransferDelegate

extension CustomWatchFaceViewController: TransferDelegate {

    func transferDidStart() {
        DispatchQueue.main.async {
            self.statusLabel.text = "正在上传..."
            self.progressView.progress = 0
        }
    }

    func transferDidUpdateProgress(_ progress: TransferProgress) {
        DispatchQueue.main.async {
            self.progressView.progress = Float(progress.percentage)
            let percentage = Int(progress.percentage * 100)
            self.statusLabel.text = "上传中... \(percentage)%"
        }
    }

    func transferDidComplete() {
        DispatchQueue.main.async {
            self.statusLabel.text = "上传成功!"
            self.progressView.progress = 1.0
            self.showAlert("表盘上传成功")
        }
    }

    func transferDidFail(error: Error) {
        DispatchQueue.main.async {
            self.statusLabel.text = "上传失败"
            self.progressView.progress = 0
            self.showAlert("上传失败: \(error.localizedDescription)")
        }
    }
}
```

### 示例 3: 取消传输

```swift
class WatchFaceViewController: UIViewController {

    @IBAction func cancelTapped(_ sender: UIButton) {
        WatchFaceManager.shared.cancelTransfer()
        print("传输已取消")
    }
}
```

---

## 错误处理

### 错误类型

```swift
public enum WatchFaceError: Error {
    case fileNotFound           // 文件不存在
    case invalidFileFormat      // 文件格式无效
    case fileSizeExceeded       // 文件大小超限
    case invalidImage           // 图片无效
    case imageProcessingFailed  // 图片处理失败
    case deviceNotConnected     // 设备未连接
    case transferFailed         // 传输失败
    case transferCancelled      // 传输被取消
}
```

### 错误处理示例

```swift
func handleWatchFaceError(_ error: Error) {
    if let watchFaceError = error as? WatchFaceError {
        switch watchFaceError {
        case .fileNotFound:
            print("表盘文件不存在")
        case .invalidFileFormat:
            print("表盘文件格式无效")
        case .fileSizeExceeded:
            print("表盘文件过大")
        case .invalidImage:
            print("图片无效")
        case .imageProcessingFailed:
            print("图片处理失败")
        case .deviceNotConnected:
            print("设备未连接，请先连接设备")
        case .transferFailed:
            print("传输失败，请重试")
        case .transferCancelled:
            print("传输已取消")
        }
    } else {
        print("未知错误: \(error.localizedDescription)")
    }
}
```

---

## 最佳实践

### 1. 设备连接检查

在上传表盘前，确保设备已连接：

```swift
import WatchProtocolSDK

func checkDeviceConnection() -> Bool {
    guard XGZTBlueToothManager.shared.isConnected else {
        print("设备未连接")
        return false
    }
    return true
}

func uploadWatchFace() {
    guard checkDeviceConnection() else {
        showAlert("请先连接设备")
        return
    }

    // 继续上传...
}
```

### 2. 图片优化

对于自定义表盘，建议先优化图片：

```swift
extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

// 使用示例
if let originalImage = UIImage(named: "watchface"),
   let resizedImage = originalImage.resized(to: CGSize(width: 240, height: 240)) {
    try WatchFaceManager.shared.uploadCustomWatchFace(
        image: resizedImage,
        timePosition: .center,
        color: .white,
        delegate: self
    )
}
```

### 3. 线程安全

所有 UI 更新应在主线程执行：

```swift
func transferDidUpdateProgress(_ progress: TransferProgress) {
    DispatchQueue.main.async {
        // 更新 UI
        self.progressView.progress = Float(progress.percentage)
    }
}
```

### 4. 内存管理

对于大图片，注意内存释放：

```swift
func processLargeImage() {
    autoreleasepool {
        if let image = UIImage(contentsOfFile: imagePath) {
            // 处理图片
            try? WatchFaceManager.shared.uploadCustomWatchFace(
                image: image,
                timePosition: .center,
                color: .white,
                delegate: self
            )
        }
    }
}
```

### 5. 错误重试机制

```swift
class WatchFaceUploader {
    private var retryCount = 0
    private let maxRetries = 3

    func uploadWithRetry(image: UIImage) {
        do {
            try WatchFaceManager.shared.uploadCustomWatchFace(
                image: image,
                timePosition: .center,
                color: .white,
                delegate: self
            )
        } catch {
            if retryCount < maxRetries {
                retryCount += 1
                print("上传失败，重试第 \(retryCount) 次")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.uploadWithRetry(image: image)
                }
            } else {
                print("达到最大重试次数，上传失败")
            }
        }
    }
}
```

---

## 常见问题

### Q1: 上传失败，提示设备未连接？

**A**: 确保已通过 WatchProtocolSDK 连接设备：

```swift
// 初始化蓝牙
XGZTBlueToothManager.shared.initCentral()

// 扫描设备
XGZTBlueToothManager.shared.scanDevice { peripheral, macAddress in
    print("发现设备: \(macAddress)")
}

// 连接设备
XGZTBlueToothManager.shared.connectDevice(macAddress) { success in
    if success {
        print("连接成功")
        // 现在可以上传表盘
    }
}
```

### Q2: 图片处理失败？

**A**: 检查图片格式和大小：
- 支持 PNG、JPG 格式
- 建议尺寸大于等于设备屏幕尺寸
- 图片不能为空或损坏

### Q3: 传输速度慢？

**A**: 可能的原因：
- 蓝牙信号弱
- 图片文件过大
- 设备性能限制

建议：
- 保持设备距离在 5 米以内
- 压缩图片大小
- 避免在传输时进行其他蓝牙操作

### Q4: 如何自定义时间显示？

**A**: 使用 `TimePosition` 和颜色参数：

```swift
// 时间在顶部，红色
try WatchFaceManager.shared.uploadCustomWatchFace(
    image: image,
    timePosition: .top,
    color: .red,
    delegate: self
)

// 时间在中间，白色
try WatchFaceManager.shared.uploadCustomWatchFace(
    image: image,
    timePosition: .center,
    color: .white,
    delegate: self
)

// 时间在底部，蓝色
try WatchFaceManager.shared.uploadCustomWatchFace(
    image: image,
    timePosition: .bottom,
    color: .blue,
    delegate: self
)
```

### Q5: 如何处理多个表盘上传？

**A**: SDK 不支持并发上传，请逐个上传：

```swift
class BatchUploader: TransferDelegate {
    private var watchFaces: [UIImage] = []
    private var currentIndex = 0

    func uploadAll(images: [UIImage]) {
        self.watchFaces = images
        self.currentIndex = 0
        uploadNext()
    }

    private func uploadNext() {
        guard currentIndex < watchFaces.count else {
            print("所有表盘上传完成")
            return
        }

        let image = watchFaces[currentIndex]
        try? WatchFaceManager.shared.uploadCustomWatchFace(
            image: image,
            timePosition: .center,
            color: .white,
            delegate: self
        )
    }

    func transferDidComplete() {
        currentIndex += 1
        uploadNext()
    }

    func transferDidFail(error: Error) {
        print("第 \(currentIndex + 1) 个表盘上传失败")
        // 决定是继续还是停止
        currentIndex += 1
        uploadNext()
    }
}
```

---

## 技术支持

如有其他问题，请联系：
- Email: support@example.com
- GitHub: https://github.com/yourcompany/WatchFaceSDK

---

**© 2025-2026 Your Company. All Rights Reserved.**
