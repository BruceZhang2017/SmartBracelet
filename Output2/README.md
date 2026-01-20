# WatchFaceSDK v1.0.3 - 紧急修复版本

## ⚠️ 重要更新
**这是一个关键的崩溃修复版本!** v1.0.2 存在严重问题,请立即升级。

### v1.0.3 更新内容 (2026-01-14)
- 🔧 **关键修复**: 解决 uploadCustomWatchFace() 崩溃问题
- 🔧 修复内存安全问题和符号冲突
- ✅ 100% API 兼容,无需修改代码

📖 **详细信息**: 请查看 `RELEASE-NOTES-v1.0.3.md` 或 `发布说明-v1.0.3.md`

---

# WatchFaceSDK - 发布包

## 📦 包含内容

本发布包包含以下文件：

### 1. SDK 文件
- **WatchFaceSDK.xcframework**: 编译好的 SDK framework，支持 iOS 设备和模拟器

### 2. 版本信息
- **VERSION.txt**: SDK 版本信息和发布说明

### 3. 接入文档
- **WatchFaceSDK-接入文档-中文.md**: 详细的中文接入指南
- **WatchFaceSDK-Integration-Guide-EN.md**: 详细的英文接入指南

---

## 🚀 快速开始

### 前置要求

WatchFaceSDK 依赖 WatchProtocolSDK，请确保已集成 WatchProtocolSDK v1.0.2。

### 集成 SDK

1. 将 `WatchFaceSDK.xcframework` 拖入您的 Xcode 项目
2. 在项目 Target -> General -> Frameworks, Libraries, and Embedded Content 中添加 xcframework
3. 设置 Embed 为 "Embed & Sign"

### 添加依赖

除了 WatchProtocolSDK 的依赖外，WatchFaceSDK 还需要：

在 `Podfile` 中添加：
```ruby
# WatchProtocolSDK 依赖
pod 'SwiftyJSON'
pod 'CryptoSwift'

# WatchFaceSDK 额外依赖
# (如有需要添加其他依赖)
```

### 配置权限

在 `Info.plist` 中添加蓝牙和照片访问权限：
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>需要使用蓝牙连接智能手表设备</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册选择表盘图片</string>
```

### 使用示例

#### 上传自定义表盘

```swift
import WatchFaceSDK
import WatchProtocolSDK

class WatchFaceViewController: UIViewController, TransferDelegate {

    func uploadCustomWatchFace() {
        // 准备表盘图片
        guard let image = UIImage(named: "my_watchface") else {
            print("图片不存在")
            return
        }

        // 上传自定义表盘
        do {
            try WatchFaceManager.shared.uploadCustomWatchFace(
                image: image,
                timePosition: .center,
                color: .white,
                delegate: self
            )
        } catch {
            print("❌ 上传失败: \(error)")
        }
    }

    // MARK: - TransferDelegate

    func transferDidStart() {
        print("🚀 开始传输表盘")
    }

    func transferDidUpdateProgress(_ progress: TransferProgress) {
        let percentage = Int(progress.percentage * 100)
        print("📊 传输进度: \(percentage)%")
    }

    func transferDidComplete() {
        print("✅ 表盘传输成功")
    }

    func transferDidFail(error: Error) {
        print("❌ 传输失败: \(error.localizedDescription)")
    }
}
```

#### 上传市场表盘

```swift
func uploadMarketWatchFace() {
    // 准备表盘文件路径
    let fileURL = // ... 表盘文件路径

    do {
        try WatchFaceManager.shared.uploadMarketWatchFace(
            fileURL: fileURL,
            delegate: self
        )
    } catch {
        print("❌ 上传失败: \(error)")
    }
}
```

---

## 📖 文档

- **中文文档**: 查看 `WatchFaceSDK-接入文档-中文.md` 获取完整的中文接入指南
- **English Documentation**: See `WatchFaceSDK-Integration-Guide-EN.md` for complete integration guide

---

## ✨ 主要特性

- ✅ 市场表盘上传
- ✅ 自定义表盘上传
- ✅ 智能图片处理（PAR 转换）
- ✅ 圆形/方形屏幕适配
- ✅ 实时传输进度回调
- ✅ 自动图片压缩优化
- ✅ 完善的错误处理
- ✅ 线程安全设计

---

## 📋 系统要求

- iOS 12.0+
- Xcode 12.0+
- Swift 5.0+
- WatchProtocolSDK v1.0.2

---

## 📝 版本历史

### v1.0.2 (2026-01-11)
- 🔄 与 WatchProtocolSDK v1.0.2 版本同步
- 🚀 增强传输稳定性
- ⚡ 优化图片处理性能
- 📖 更新文档和示例代码

### v1.0.1 (2026-01-05)
- ✨ 新增自定义表盘支持
- 🔧 改进市场表盘上传
- 🛡️ 增强错误处理

### v1.0.0 (2025-12-30)
- ✨ 首次发布
- ✨ 完整的表盘协议实现
- ✨ 支持市场表盘和自定义表盘
- 📖 完整的中英文文档

---

## ⚠️ 注意事项

1. **设备连接**: 使用前确保设备已通过 WatchProtocolSDK 连接成功
2. **图片要求**:
   - 建议图片尺寸大于等于设备屏幕尺寸
   - 支持 PNG、JPG 格式
   - 自动压缩到 120KB 以内
3. **线程安全**: 回调方法可能在后台线程调用，UI 更新需切换到主线程
4. **版本兼容**: 必须与 WatchProtocolSDK v1.0.2 配合使用

---

## 🔧 技术支持

如有问题或建议，请联系：
- Email: support@example.com
- GitHub: https://github.com/yourcompany/WatchFaceSDK

---

**© 2025-2026 Your Company. All Rights Reserved.**
