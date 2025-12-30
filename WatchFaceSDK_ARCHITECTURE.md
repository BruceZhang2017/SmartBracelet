# WatchFaceSDK 架构设计文档

## 📋 概述

**WatchFaceSDK** 是从 SmartBracelet 项目中抽离出来的表盘管理专用 SDK，仅支持 **XGZT 协议**，不包含旧协议（JL）支持。

**目标**：
- ✅ 表盘下载与列表管理
- ✅ 自定义表盘图片处理
- ✅ 表盘上传到设备（分包传输）
- ✅ 本地表盘缓存管理
- ❌ 不包含任何 UI 代码

---

## 🏗 模块架构

```
WatchFaceSDK/
├── Core/                          # 核心模块
│   ├── WatchFaceManager.swift     # SDK 主入口，协调各模块
│   └── WatchFaceTransferEngine.swift  # 表盘传输引擎
│
├── Models/                        # 数据模型
│   ├── WatchFaceInfo.swift        # 表盘信息模型
│   ├── WatchFaceCategory.swift    # 表盘分类模型
│   ├── DeviceScreenInfo.swift     # 设备屏幕信息
│   └── TransferProgress.swift     # 传输进度模型
│
├── Network/                       # 网络模块
│   ├── WatchFaceAPI.swift         # 表盘 API 服务
│   └── WatchFaceDownloader.swift  # 表盘文件下载器
│
├── Transfer/                      # 传输模块
│   ├── XGZTDialProtocol.swift     # XGZT 表盘协议封装
│   ├── PacketManager.swift        # 分包管理器
│   └── TransferQueue.swift        # 传输队列管理
│
├── Storage/                       # 存储模块
│   ├── WatchFaceCache.swift       # 表盘缓存管理
│   └── WatchFaceHistory.swift     # 历史记录管理
│
├── Extensions/                    # 图片处理扩展
│   ├── ImageProcessor.swift       # 图片压缩与格式转换
│   └── ImageCropper.swift         # 圆形/方形裁剪
│
├── Protocols/                     # 协议定义
│   ├── WatchFaceDelegate.swift    # 回调代理
│   └── TransferDelegate.swift     # 传输进度代理
│
└── Utils/                         # 工具类
    ├── PARConverter.swift         # PAR 格式转换工具
    └── Logger.swift               # 日志工具
```

---

## 📦 核心模块详解

### 1. Core - 核心模块

#### `WatchFaceManager.swift` - SDK 主入口

```swift
public class WatchFaceManager {
    public static let shared = WatchFaceManager()

    // 依赖 WatchProtocolSDK
    private let deviceManager: XGZTBlueToothManager
    private let transferEngine: WatchFaceTransferEngine
    private let api: WatchFaceAPI
    private let cache: WatchFaceCache

    // MARK: - 公开接口

    /// 获取表盘列表（从服务器）
    public func fetchWatchFaceList(completion: @escaping (Result<[WatchFaceCategory], Error>) -> Void)

    /// 下载表盘文件
    public func downloadWatchFace(_ info: WatchFaceInfo, progress: @escaping (Float) -> Void, completion: @escaping (Result<URL, Error>) -> Void)

    /// 上传市场表盘到设备
    public func uploadMarketWatchFace(_ localURL: URL, delegate: TransferDelegate?) throws

    /// 上传自定义表盘到设备
    public func uploadCustomWatchFace(image: UIImage, position: TimePosition, color: Int, delegate: TransferDelegate?) throws

    /// 查询当前设备表盘信息
    public func queryDeviceWatchFaces(completion: @escaping (Result<[String], Error>) -> Void)
}
```

#### `WatchFaceTransferEngine.swift` - 传输引擎

```swift
public class WatchFaceTransferEngine {
    private let protocol: XGZTDialProtocol
    private let packetManager: PacketManager
    private var transferQueue: TransferQueue

    // MARK: - 核心功能

    /// 开始传输
    func startTransfer(data: Data, type: DialType, config: TransferConfig, delegate: TransferDelegate?)

    /// 暂停传输
    func pauseTransfer()

    /// 取消传输
    func cancelTransfer()

    /// 重试传输
    func retryTransfer()
}
```

---

### 2. Models - 数据模型

#### `WatchFaceInfo.swift`

```swift
public struct WatchFaceInfo: Codable {
    public let id: String
    public let name: String
    public let previewURL: URL
    public let resourceURL: URL
    public let fileSize: Int
    public let category: String
    public let supportedScreenSizes: [CGSize]
    public let shape: ScreenShape  // round / square
}

public enum ScreenShape: String, Codable {
    case round
    case square
}
```

#### `DeviceScreenInfo.swift`

```swift
public struct DeviceScreenInfo {
    public let width: Int
    public let height: Int
    public let shape: ScreenShape
    public let mtu: Int

    // 从 XGZTBlueToothManager 获取
    public static func current() -> DeviceScreenInfo? {
        guard let device = XGZTBlueToothManager.shared.device else { return nil }
        return DeviceScreenInfo(
            width: device.screenWidth,
            height: device.screenHeight,
            shape: device.screenType == 1 ? .round : .square,
            mtu: device.mtu
        )
    }
}
```

---

### 3. Transfer - 传输模块

#### `XGZTDialProtocol.swift` - XGZT 协议封装

```swift
public class XGZTDialProtocol {

    /// 查询 MTU
    public func queryMTU(completion: @escaping (Result<Int, Error>) -> Void) {
        XGZTCommand.dialMarketQuery(dataType: 0)
        // 监听通知获取结果
    }

    /// 设置传输配置
    public func setTransferConfig(
        packageTotal: Int,
        binSize: Int,
        mtu: Int,
        dialType: Int,
        position: Int = 0,
        color: Int = 0
    ) {
        XGZTCommand.dialMarketSetTransferConfig(
            packageTotal: packageTotal,
            binSize: binSize,
            mtu: mtu,
            dialType: dialType,
            dialNum: 1,
            local: position,
            typeValue: 0,
            dialTypeValue: color
        )
    }

    /// 传输数据包
    public func transferPacket(
        packageNum: Int,
        binNum: Int,
        progress: Int,
        control: Int,
        data: Data
    ) {
        XGZTCommand.dialMarketTransferData(
            packageNum: packageNum,
            binNum: binNum,
            progressBar: progress,
            control: control,
            data: data
        )
    }

    /// 设置时间位置和颜色（仅自定义表盘）
    public func setTimePositionAndColor(position: Int, color: Int) {
        XGZTCommand.setTimePositionAndColor(type: 2, position: position, color: color)
    }
}
```

#### `PacketManager.swift` - 分包管理器

```swift
public class PacketManager {
    private let maxPacketSize = 200  // XGZT 固定 200 字节

    /// 计算分包总数
    public func calculatePackageCount(dataSize: Int) -> Int {
        return (dataSize % maxPacketSize == 0)
            ? (dataSize / maxPacketSize)
            : (dataSize / maxPacketSize + 1)
    }

    /// 获取指定包的数据
    public func getPacketData(from data: Data, packetIndex: Int) -> (data: Data, isLast: Bool) {
        let startIndex = packetIndex * maxPacketSize
        let endIndex = min(startIndex + maxPacketSize, data.count)
        let range = startIndex..<endIndex
        let packetData = data.subdata(in: range)
        let isLast = (endIndex >= data.count)
        return (packetData, isLast)
    }
}
```

---

### 4. Extensions - 图片处理

#### `ImageProcessor.swift` - 图片压缩与格式转换

```swift
import ABParTool

public class ImageProcessor {

    /// 压缩并转换为 PAR 格式
    public static func convertToPAR(
        image: UIImage,
        targetSize: CGSize,
        maxFileSize: Int = 120 * 1024  // 默认 120KB
    ) throws -> Data {

        // 1. 调整图片尺寸
        guard let resizedImage = resizeImage(image, to: targetSize) else {
            throw WatchFaceError.imageProcessFailed
        }

        // 2. 循环压缩直到满足大小要求
        var currentImage = resizedImage
        var attemptCount = 0
        let maxAttempts = 10

        while attemptCount < maxAttempts {
            guard let rawImageData = currentImage.rawImageData else {
                throw WatchFaceError.rawDataConversionFailed
            }

            // 转换为 PAR 格式
            if let parData = ParTool.par(
                fromRaw: rawImageData,
                width: Int32(targetSize.width),
                height: Int32(targetSize.height),
                runAlpha: false,
                useFilter: false,
                supportRotate: false
            ) {
                if parData.count <= maxFileSize {
                    XLogger.shared.log("✅ PAR 转换成功: \(parData.count) bytes")
                    return parData
                }

                // 继续压缩
                let quality = max(0.1, 0.9 - Double(attemptCount) * 0.1)
                guard let compressedData = currentImage.jpegData(compressionQuality: quality),
                      let compressedImage = UIImage(data: compressedData) else {
                    throw WatchFaceError.compressionFailed
                }
                currentImage = compressedImage
            }

            attemptCount += 1
        }

        throw WatchFaceError.exceedMaxAttempts
    }

    /// 调整图片尺寸
    private static func resizeImage(_ image: UIImage, to targetSize: CGSize) -> UIImage? {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1.0
        return UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
```

#### `ImageCropper.swift` - 图片裁剪（圆形/方形）

```swift
public class ImageCropper {

    /// 裁剪为圆形（已存在于 CircleCropUtils.swift）
    public static func cropToCircle(image: UIImage) -> UIImage? {
        return image.croppedToCircleSmooth()
    }

    /// 裁剪为方形
    public static func cropToSquare(image: UIImage, targetSize: CGSize) -> UIImage? {
        // 实现方形裁剪逻辑
    }
}
```

---

### 5. Network - 网络模块

#### `WatchFaceAPI.swift`

```swift
import Alamofire

public class WatchFaceAPI {
    private let baseURL = "https://u-watch.com.cn/api/app/ota"

    /// 获取表盘分类列表
    public func fetchCategories(
        width: Int,
        height: Int,
        shape: String,
        completion: @escaping (Result<[WatchFaceCategory], Error>) -> Void
    ) {
        let url = "\(baseURL)/otaType"
        let parameters: [String: Any] = [
            "width": width,
            "height": height,
            "shape": shape,  // "round" or "square"
            "language": Locale.current.languageCode ?? "en"
        ]

        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .responseDecodable(of: Response<OTAData>.self) { response in
                // 处理响应
            }
    }

    /// 获取分类下的表盘列表
    public func fetchWatchFaces(
        categoryId: String,
        page: Int,
        pageSize: Int,
        completion: @escaping (Result<[WatchFaceInfo], Error>) -> Void
    ) {
        // 实现分页获取表盘列表
    }
}
```

---

### 6. Storage - 本地存储

#### `WatchFaceCache.swift`

```swift
public class WatchFaceCache {
    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    public init() {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        cacheDirectory = documentsURL.appendingPathComponent("WatchFaces", isDirectory: true)
        createCacheDirectoryIfNeeded()
    }

    /// 保存表盘文件
    public func saveWatchFace(data: Data, fileName: String) throws {
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        try data.write(to: fileURL)
    }

    /// 获取缓存的表盘
    public func getCachedWatchFace(fileName: String) -> Data? {
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        return try? Data(contentsOf: fileURL)
    }

    /// 清理缓存
    public func clearCache() throws {
        let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
        for fileURL in contents {
            try fileManager.removeItem(at: fileURL)
        }
    }
}
```

---

## 🔌 协议定义

### `TransferDelegate.swift`

```swift
public protocol TransferDelegate: AnyObject {
    /// 开始传输
    func transferDidStart()

    /// 传输进度更新
    func transferDidUpdateProgress(_ progress: Float, message: String)

    /// 传输成功
    func transferDidComplete()

    /// 传输失败
    func transferDidFail(error: Error)
}
```

---

## 🎯 使用示例

### 1. 获取表盘列表

```swift
WatchFaceManager.shared.fetchWatchFaceList { result in
    switch result {
    case .success(let categories):
        print("获取到 \(categories.count) 个分类")
    case .failure(let error):
        print("获取失败: \(error)")
    }
}
```

### 2. 下载并上传市场表盘

```swift
let watchFace = // ... 选中的表盘
WatchFaceManager.shared.downloadWatchFace(watchFace, progress: { progress in
    print("下载进度: \(progress * 100)%")
}, completion: { result in
    switch result {
    case .success(let localURL):
        // 上传到设备
        try? WatchFaceManager.shared.uploadMarketWatchFace(localURL, delegate: self)
    case .failure(let error):
        print("下载失败: \(error)")
    }
})
```

### 3. 上传自定义表盘

```swift
let image = UIImage(named: "custom_watchface")!
try? WatchFaceManager.shared.uploadCustomWatchFace(
    image: image,
    position: 5,  // 居中
    color: 0,     // 白色
    delegate: self
)
```

---

## 📋 实现清单

### 已完成分析
- ✅ ClockManage 文件夹代码分析
- ✅ XGZT 协议识别（39处使用）
- ✅ 业务逻辑与 UI 分离

### 待实现模块
1. **Core/** - 核心管理器
2. **Models/** - 数据模型
3. **Network/** - API 服务
4. **Transfer/** - 传输引擎
5. **Storage/** - 缓存管理
6. **Extensions/** - 图片处理
7. **Protocols/** - 回调协议
8. **Utils/** - 工具类

---

## 🔗 依赖关系

```
WatchFaceSDK
├── WatchProtocolSDK (已存在)
│   ├── XGZTBlueToothManager
│   ├── XGZTCommand
│   └── XLogger
│
├── ABParTool.framework (已存在)
│   └── ParTool (PAR 格式转换)
│
└── 第三方库
    ├── Alamofire (网络请求)
    └── Kingfisher (可选，图片加载)
```

---

## 📝 下一步操作

1. 创建 WatchFaceSDK 文件夹结构
2. 实现核心模块代码
3. 编写单元测试
4. 更新主 App 以使用 SDK
5. 编写完整文档

---

**版本**: 1.0.0
**更新时间**: 2025-12-30
**状态**: 设计阶段 ✅
