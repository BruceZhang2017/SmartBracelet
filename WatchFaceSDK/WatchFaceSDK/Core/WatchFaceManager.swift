//
//  WatchFaceManager.swift
//  WatchFaceSDK
//
//  Created by bruce on 2025/12/30.
//

import UIKit
import Foundation
import WatchProtocolSDK

// MARK: - 表盘管理器（SDK主入口）
public class WatchFaceManager {

    // MARK: - 单例
    public static let shared = WatchFaceManager()

    // MARK: - 属性
    private let transferEngine: WatchFaceTransferEngine
    private let dialProtocol: XGZTDialProtocol

    // MARK: - 初始化
    private init() {
        self.transferEngine = WatchFaceTransferEngine()
        self.dialProtocol = XGZTDialProtocol.shared

        XLogger.shared.log("🎨 WatchFaceSDK 初始化完成")
    }

    // MARK: - 公开接口

    /// 获取当前设备屏幕信息
    /// - Returns: 设备屏幕信息，如果设备未连接则返回 nil
    public func getCurrentDeviceScreenInfo() -> DeviceScreenInfo? {
        return XGZTDialProtocol.getCurrentDeviceScreenInfo()
    }

    /// 检查设备是否连接
    /// - Returns: 是否连接
    public func isDeviceConnected() -> Bool {
        return XGZTDialProtocol.isDeviceConnected()
    }

    // MARK: - 上传市场表盘

    /// 上传市场表盘到设备
    /// - Parameters:
    ///   - data: 表盘文件数据
    ///   - delegate: 传输进度代理
    /// - Throws: WatchFaceError
    public func uploadMarketWatchFace(data: Data, delegate: TransferDelegate?) throws {
        guard isDeviceConnected() else {
            throw WatchFaceError.deviceNotConnected
        }

        guard data.count > 0 else {
            throw WatchFaceError.invalidConfiguration
        }

        XLogger.shared.log("📤 开始上传市场表盘 - 大小: \(data.count) bytes")

        transferEngine.startTransfer(
            data: data,
            dialType: .market,
            delegate: delegate
        )
    }

    /// 上传市场表盘（从本地文件）
    /// - Parameters:
    ///   - fileURL: 表盘文件路径
    ///   - delegate: 传输进度代理
    /// - Throws: WatchFaceError
    public func uploadMarketWatchFace(fileURL: URL, delegate: TransferDelegate?) throws {
        guard isDeviceConnected() else {
            throw WatchFaceError.deviceNotConnected
        }

        let data = try Data(contentsOf: fileURL)
        try uploadMarketWatchFace(data: data, delegate: delegate)
    }

    // MARK: - 上传自定义表盘

    /// 上传自定义表盘到设备
    /// - Parameters:
    ///   - image: 原始图片
    ///   - timePosition: 时间位置
    ///   - color: 颜色
    ///   - delegate: 传输进度代理
    /// - Throws: WatchFaceError
    public func uploadCustomWatchFace(
        image: UIImage,
        timePosition: TimePosition,
        color: DialColor,
        delegate: TransferDelegate?
    ) throws {
        guard isDeviceConnected() else {
            throw WatchFaceError.deviceNotConnected
        }

        guard let screenInfo = getCurrentDeviceScreenInfo() else {
            throw WatchFaceError.deviceNotSupported
        }

        XLogger.shared.log("🎨 开始处理自定义表盘 - 屏幕: \(screenInfo.width)x\(screenInfo.height), 形状: \(screenInfo.shape)")

        // 1. 根据屏幕形状裁剪图片
        let targetSize = screenInfo.size.cgSize
        guard let croppedImage = ImageCropper.cropForScreenShape(
            image: image,
            shape: screenInfo.shape,
            targetSize: targetSize
        ) else {
            throw WatchFaceError.imageProcessFailed
        }

        // 2. 转换为 PAR 格式
        let parData = try ImageProcessor.convertToPAR(
            image: croppedImage,
            targetSize: targetSize,
            maxFileSize: 120 * 1024
        )

        XLogger.shared.log("✅ 图片处理完成，PAR 数据大小: \(parData.count) bytes")

        // 3. 上传到设备
        transferEngine.startTransfer(
            data: parData,
            dialType: .custom,
            timePosition: timePosition,
            color: color,
            delegate: delegate
        )
    }

    // MARK: - 传输控制

    /// 暂停传输
    public func pauseTransfer() {
        transferEngine.pauseTransfer()
    }

    /// 取消传输
    public func cancelTransfer() {
        transferEngine.cancelTransfer()
    }

    /// 重试传输
    public func retryTransfer() {
        transferEngine.retryTransfer()
    }

    // MARK: - 辅助方法

    /// 验证图片是否满足设备要求
    /// - Parameter image: 图片
    /// - Returns: 是否满足要求
    public func validateImage(_ image: UIImage) -> (isValid: Bool, message: String) {
        guard let screenInfo = getCurrentDeviceScreenInfo() else {
            return (false, NSLocalizedString("device_not_connected", comment: "设备未连接"))
        }

        let imageSize = image.size
        let minDimension = min(imageSize.width, imageSize.height)

        // 检查图片是否足够大
        if minDimension < CGFloat(max(screenInfo.width, screenInfo.height)) {
            let message = String(
                format: NSLocalizedString("image_too_small", comment: "图片尺寸过小，最小尺寸应为 %dx%d"),
                screenInfo.width,
                screenInfo.height
            )
            return (false, message)
        }

        return (true, NSLocalizedString("image_valid", comment: "图片满足要求"))
    }

    /// 获取推荐的图片尺寸
    /// - Returns: 推荐尺寸
    public func getRecommendedImageSize() -> CGSize? {
        guard let screenInfo = getCurrentDeviceScreenInfo() else {
            return nil
        }

        // 推荐使用设备屏幕尺寸的2倍作为输入图片尺寸
        return CGSize(
            width: screenInfo.width * 2,
            height: screenInfo.height * 2
        )
    }
}

// MARK: - 便捷工厂方法
public extension WatchFaceManager {

    /// 从本地图片创建自定义表盘并上传
    /// - Parameters:
    ///   - imageName: 图片名称（在 Assets 中）
    ///   - timePosition: 时间位置
    ///   - color: 颜色
    ///   - delegate: 传输进度代理
    /// - Throws: WatchFaceError
    func uploadCustomWatchFace(
        imageName: String,
        timePosition: TimePosition,
        color: DialColor,
        delegate: TransferDelegate?
    ) throws {
        guard let image = UIImage(named: imageName) else {
            throw WatchFaceError.imageProcessFailed
        }

        try uploadCustomWatchFace(
            image: image,
            timePosition: timePosition,
            color: color,
            delegate: delegate
        )
    }

    /// 从文件路径创建自定义表盘并上传
    /// - Parameters:
    ///   - fileURL: 图片文件路径
    ///   - timePosition: 时间位置
    ///   - color: 颜色
    ///   - delegate: 传输进度代理
    /// - Throws: WatchFaceError
    func uploadCustomWatchFace(
        fileURL: URL,
        timePosition: TimePosition,
        color: DialColor,
        delegate: TransferDelegate?
    ) throws {
        guard let image = UIImage(contentsOfFile: fileURL.path) else {
            throw WatchFaceError.imageProcessFailed
        }

        try uploadCustomWatchFace(
            image: image,
            timePosition: timePosition,
            color: color,
            delegate: delegate
        )
    }
}
