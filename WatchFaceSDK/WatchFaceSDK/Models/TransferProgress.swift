//
//  TransferProgress.swift
//  WatchFaceSDK
//
//  Created by ANKER on 2025/12/30.
//

import Foundation

// MARK: - 传输进度模型
public struct TransferProgress {
    public let currentPacket: Int
    public let totalPackets: Int
    public let bytesTransferred: Int
    public let totalBytes: Int
    public let percentage: Float
    public let message: String

    public init(
        currentPacket: Int,
        totalPackets: Int,
        bytesTransferred: Int,
        totalBytes: Int
    ) {
        self.currentPacket = currentPacket
        self.totalPackets = totalPackets
        self.bytesTransferred = bytesTransferred
        self.totalBytes = totalBytes
        self.percentage = totalBytes > 0 ? Float(bytesTransferred) / Float(totalBytes) : 0
        self.message = String(format: "%.2f%%", percentage * 100)
    }
}

// MARK: - 表盘类型
public enum DialType: Int {
    case market = 0        // 市场表盘
    case custom = 1        // 自定义表盘
}

// MARK: - 时间位置
public enum TimePosition: Int {
    case none = 0          // 无
    case topLeft = 1       // 左上
    case bottomLeft = 2    // 左下
    case topRight = 3      // 右上
    case bottomRight = 4   // 右下
    case center = 5        // 居中
}

// MARK: - 表盘颜色
public enum DialColor: Int {
    case white = 0
    case black = 1
    case yellow = 2
    case orange = 3
    case pink = 4
    case purple = 5
    case blue = 6
    case cyan = 7
    case green = 8
}

// MARK: - 传输配置
public struct TransferConfig {
    public let packageTotal: Int
    public let binSize: Int
    public let mtu: Int
    public let dialType: DialType
    public let timePosition: TimePosition
    public let color: DialColor

    public init(
        packageTotal: Int,
        binSize: Int,
        mtu: Int,
        dialType: DialType,
        timePosition: TimePosition = .none,
        color: DialColor = .white
    ) {
        self.packageTotal = packageTotal
        self.binSize = binSize
        self.mtu = mtu
        self.dialType = dialType
        self.timePosition = timePosition
        self.color = color
    }
}

// MARK: - 传输状态
public enum TransferState {
    case idle           // 空闲
    case preparing      // 准备中
    case querying       // 查询MTU
    case configuring    // 配置传输参数
    case transferring   // 传输中
    case completed      // 完成
    case failed(Error)  // 失败
    case cancelled      // 取消

    // 辅助方法：检查状态
    var isIdle: Bool {
        if case .idle = self { return true }
        return false
    }

    var isTransferring: Bool {
        if case .transferring = self { return true }
        return false
    }

    var isPreparing: Bool {
        if case .preparing = self { return true }
        return false
    }
}
