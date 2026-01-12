# WatchFaceSDK 使用示例

完整的使用示例代码和最佳实践。

---

## 📋 目录

1. [基础使用](#基础使用)
2. [自定义表盘完整流程](#自定义表盘完整流程)
3. [市场表盘下载与上传](#市场表盘下载与上传)
4. [UI集成示例](#ui集成示例)
5. [最佳实践](#最佳实践)

---

## 基础使用

### 示例 1: 检查设备状态

```swift
import WatchFaceSDK

func checkDeviceStatus() {
    // 检查连接状态
    guard WatchFaceManager.shared.isDeviceConnected() else {
        showAlert("请先连接设备")
        return
    }

    // 获取设备信息
    guard let screenInfo = WatchFaceManager.shared.getCurrentDeviceScreenInfo() else {
        showAlert("无法获取设备信息")
        return
    }

    print("""
    设备信息:
    - 屏幕尺寸: \(screenInfo.width)x\(screenInfo.height)
    - 屏幕形状: \(screenInfo.shape == .round ? "圆形" : "方形")
    - MTU: \(screenInfo.mtu)
    """)
}
```

---

## 自定义表盘完整流程

### 示例 2: 从相册选择图片并上传

```swift
import UIKit
import WatchFaceSDK
import PhotosUI

class CustomWatchFaceViewController: UIViewController {

    // MARK: - 属性
    private var progressView: UIProgressView!
    private var selectedImage: UIImage?

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - 选择图片
    @objc private func selectImage() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    // MARK: - 上传表盘
    private func uploadWatchFace(image: UIImage, position: TimePosition, color: DialColor) {
        // 1. 验证图片
        let validation = WatchFaceManager.shared.validateImage(image)
        guard validation.isValid else {
            showAlert(validation.message)
            return
        }

        // 2. 显示进度UI
        showProgressUI()

        // 3. 开始上传
        do {
            try WatchFaceManager.shared.uploadCustomWatchFace(
                image: image,
                timePosition: position,
                color: color,
                delegate: self
            )
        } catch {
            hideProgressUI()
            showAlert("上传失败: \(error.localizedDescription)")
        }
    }

    // MARK: - UI 方法
    private func showProgressUI() {
        progressView.isHidden = false
        progressView.progress = 0
    }

    private func hideProgressUI() {
        progressView.isHidden = true
    }

    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate
extension CustomWatchFaceViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let result = results.first else { return }

        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            guard let image = object as? UIImage else { return }

            DispatchQueue.main.async {
                self?.selectedImage = image
                // 显示选项界面（时间位置、颜色等）
                self?.showConfigurationView(image: image)
            }
        }
    }

    private func showConfigurationView(image: UIImage) {
        // 显示配置界面，让用户选择时间位置和颜色
        let alert = UIAlertController(title: "自定义表盘", message: "选择时间位置和颜色", preferredStyle: .actionSheet)

        // 添加时间位置选项
        alert.addAction(UIAlertAction(title: "居中 - 白色", style: .default) { [weak self] _ in
            self?.uploadWatchFace(image: image, position: .center, color: .white)
        })

        alert.addAction(UIAlertAction(title: "左上 - 黑色", style: .default) { [weak self] _ in
            self?.uploadWatchFace(image: image, position: .topLeft, color: .black)
        })

        alert.addAction(UIAlertAction(title: "取消", style: .cancel))

        present(alert, animated: true)
    }
}

// MARK: - TransferDelegate
extension CustomWatchFaceViewController: TransferDelegate {
    func transferDidStart() {
        print("🚀 开始传输")
        DispatchQueue.main.async {
            self.showProgressUI()
        }
    }

    func transferDidUpdateProgress(_ progress: TransferProgress) {
        print("📊 进度: \(progress.message)")
        DispatchQueue.main.async {
            self.progressView.progress = progress.percentage
        }
    }

    func transferDidComplete() {
        print("✅ 传输成功")
        DispatchQueue.main.async {
            self.hideProgressUI()
            self.showAlert("表盘上传成功！")
        }
    }

    func transferDidFail(error: Error) {
        print("❌ 传输失败: \(error)")
        DispatchQueue.main.async {
            self.hideProgressUI()
            self.showAlert("上传失败: \(error.localizedDescription)")
        }
    }
}
```

---

## 市场表盘下载与上传

### 示例 3: 下载并上传市场表盘

```swift
import Alamofire
import WatchFaceSDK

class MarketWatchFaceViewController: UIViewController {

    func downloadAndUploadMarketWatchFace(watchFace: WatchFaceInfo) {
        // 1. 检查缓存
        let fileName = (watchFace.resourceURL.lastPathComponent as NSString).lastPathComponent
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: fileURL.path) {
            // 从缓存上传
            uploadMarketWatchFace(fileURL: fileURL)
        } else {
            // 下载后上传
            downloadWatchFace(url: watchFace.resourceURL, to: fileURL)
        }
    }

    private func downloadWatchFace(url: URL, to destination: URL) {
        let destination: DownloadRequest.Destination = { _, _ in
            return (destination, [.removePreviousFile, .createIntermediateDirectories])
        }

        showProgressUI(message: "正在下载...")

        AF.download(url, to: destination).response { [weak self] response in
            self?.hideProgressUI()

            if response.error == nil, let fileURL = response.fileURL {
                self?.uploadMarketWatchFace(fileURL: fileURL)
            } else {
                self?.showAlert("下载失败: \(response.error?.localizedDescription ?? "未知错误")")
            }
        }
    }

    private func uploadMarketWatchFace(fileURL: URL) {
        do {
            try WatchFaceManager.shared.uploadMarketWatchFace(
                fileURL: fileURL,
                delegate: self
            )
        } catch {
            showAlert("上传失败: \(error.localizedDescription)")
        }
    }
}

// MARK: - TransferDelegate
extension MarketWatchFaceViewController: TransferDelegate {
    // 实现 TransferDelegate 方法...
}
```

---

## UI集成示例

### 示例 4: 带进度条的上传界面

```swift
import UIKit
import WatchFaceSDK

class WatchFaceUploadView: UIView {

    // MARK: - UI 组件
    private let imageView = UIImageView()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let progressLabel = UILabel()
    private let cancelButton = UIButton(type: .system)

    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .white
        layer.cornerRadius = 16

        // 图片视图
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        addSubview(imageView)

        // 进度条
        progressView.progressTintColor = .systemBlue
        addSubview(progressView)

        // 进度标签
        progressLabel.textAlignment = .center
        progressLabel.font = .systemFont(ofSize: 14)
        progressLabel.text = "0%"
        addSubview(progressLabel)

        // 取消按钮
        cancelButton.setTitle("取消", for: .normal)
        cancelButton.addTarget(self, action: #selector(handleCancel), for: .touchUpInside)
        addSubview(cancelButton)

        // 布局
        setupConstraints()
    }

    private func setupConstraints() {
        // 使用 SnapKit 或手动布局
    }

    // MARK: - 公开方法
    func updateProgress(_ progress: TransferProgress) {
        progressView.progress = progress.percentage
        progressLabel.text = progress.message
    }

    func setImage(_ image: UIImage) {
        imageView.image = image
    }

    // MARK: - 操作
    @objc private func handleCancel() {
        WatchFaceManager.shared.cancelTransfer()
    }
}
```

---

## 最佳实践

### 1. 错误处理最佳实践

```swift
func uploadWithProperErrorHandling(image: UIImage) {
    do {
        // 检查设备连接
        guard WatchFaceManager.shared.isDeviceConnected() else {
            throw WatchFaceError.deviceNotConnected
        }

        // 验证图片
        let validation = WatchFaceManager.shared.validateImage(image)
        guard validation.isValid else {
            showAlert(validation.message)
            return
        }

        // 上传
        try WatchFaceManager.shared.uploadCustomWatchFace(
            image: image,
            timePosition: .center,
            color: .white,
            delegate: self
        )

    } catch WatchFaceError.deviceNotConnected {
        showAlert("设备未连接，请先连接设备后再试")

    } catch WatchFaceError.imageProcessFailed {
        showAlert("图片处理失败，请尝试其他图片")

    } catch {
        showAlert("操作失败: \(error.localizedDescription)")
    }
}
```

### 2. 内存管理最佳实践

```swift
class WatchFaceManager {

    // 使用 weak 避免循环引用
    weak var delegate: TransferDelegate?

    // 及时释放大数据
    private var imageData: Data? {
        didSet {
            // 上传完成后清理
            if oldValue != nil && imageData == nil {
                print("✅ 清理图片数据")
            }
        }
    }

    func cleanup() {
        imageData = nil
        // 清理其他大对象
    }
}
```

### 3. 线程安全最佳实践

```swift
extension WatchFaceManager {

    func safeUpload(image: UIImage) {
        // 确保在主线程检查UI状态
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.safeUpload(image: image)
            }
            return
        }

        // 图片处理在后台线程
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // 处理图片...

                // 回调在主线程
                DispatchQueue.main.async {
                    // 更新 UI
                }
            } catch {
                DispatchQueue.main.async {
                    // 错误处理
                }
            }
        }
    }
}
```

---

## 🔧 调试技巧

### 启用详细日志

```swift
// 在 AppDelegate 中设置
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

---

更多示例请参考 `README.md` 和 `WatchFaceSDK_ARCHITECTURE.md`。
