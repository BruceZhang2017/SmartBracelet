//
//  TransferDelegate.swift
//  WatchFaceSDK
//
//  Created by ANKER on 2025/12/30.
//

import Foundation

// MARK: - 传输代理协议
public protocol TransferDelegate: AnyObject {
    /// 开始传输
    func transferDidStart()

    /// 传输进度更新
    /// - Parameters:
    ///   - progress: 进度对象
    func transferDidUpdateProgress(_ progress: TransferProgress)

    /// 传输成功
    func transferDidComplete()

    /// 传输失败
    /// - Parameter error: 错误信息
    func transferDidFail(error: Error)

    /// 传输取消
    func transferDidCancel()
}

// MARK: - 默认实现（可选方法）
public extension TransferDelegate {
    func transferDidCancel() {
        // 默认实现为空
    }
}

// MARK: - 表盘错误类型
public enum WatchFaceError: Error {
    case deviceNotConnected         // 设备未连接
    case deviceNotSupported         // 设备不支持
    case imageProcessFailed         // 图片处理失败
    case rawDataConversionFailed    // 原始数据转换失败
    case compressionFailed          // 压缩失败
    case exceedMaxAttempts          // 超过最大尝试次数
    case exceedMaxFileSize          // 超过最大文件大小
    case transferFailed             // 传输失败
    case networkError(Error)        // 网络错误
    case cacheError(Error)          // 缓存错误
    case invalidMTU                 // 无效的MTU
    case invalidConfiguration       // 无效的配置

    public var localizedDescription: String {
        switch self {
        case .deviceNotConnected:
            return NSLocalizedString("mine_unconnect", comment: "设备未连接")
        case .deviceNotSupported:
            return NSLocalizedString("device_not_supported", comment: "设备不支持该功能")
        case .imageProcessFailed:
            return NSLocalizedString("image_process_failed", comment: "图片处理失败")
        case .rawDataConversionFailed:
            return NSLocalizedString("raw_data_conversion_failed", comment: "原始数据转换失败")
        case .compressionFailed:
            return NSLocalizedString("compression_failed", comment: "压缩失败")
        case .exceedMaxAttempts:
            return NSLocalizedString("exceed_max_attempts", comment: "超过最大尝试次数")
        case .exceedMaxFileSize:
            return NSLocalizedString("exceed_max_file_size", comment: "文件大小超过限制")
        case .transferFailed:
            return NSLocalizedString("transfer_failed", comment: "传输失败")
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .cacheError(let error):
            return "缓存错误: \(error.localizedDescription)"
        case .invalidMTU:
            return NSLocalizedString("invalid_mtu", comment: "无效的MTU值")
        case .invalidConfiguration:
            return NSLocalizedString("invalid_configuration", comment: "无效的配置")
        }
    }
}
