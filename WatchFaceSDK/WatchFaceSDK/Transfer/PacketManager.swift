//
//  PacketManager.swift
//  WatchFaceSDK
//
//  Created by ANKER on 2025/12/30.
//

import Foundation

// MARK: - 分包管理器
public class PacketManager {

    // MARK: - 常量
    private let maxPacketSize: Int = 200  // XGZT 协议固定 200 字节

    // MARK: - 公开方法

    /// 计算分包总数
    /// - Parameter dataSize: 数据总大小（字节）
    /// - Returns: 分包总数
    public func calculatePackageCount(dataSize: Int) -> Int {
        guard dataSize > 0 else { return 0 }
        return (dataSize % maxPacketSize == 0)
            ? (dataSize / maxPacketSize)
            : (dataSize / maxPacketSize + 1)
    }

    /// 获取指定包的数据
    /// - Parameters:
    ///   - data: 完整数据
    ///   - packetIndex: 包序号（从0开始）
    /// - Returns: 包数据和是否为最后一包的元组
    public func getPacketData(from data: Data, packetIndex: Int) -> (data: Data, isLast: Bool) {
        let startIndex = packetIndex * maxPacketSize
        let endIndex = min(startIndex + maxPacketSize, data.count)

        guard startIndex < data.count else {
            return (Data(), true)
        }

        let range = startIndex..<endIndex
        let packetData = data.subdata(in: range)
        let isLast = (endIndex >= data.count)

        return (packetData, isLast)
    }

    /// 获取指定包序号的字节偏移量
    /// - Parameter packetIndex: 包序号
    /// - Returns: 字节偏移量
    public func getByteOffset(for packetIndex: Int) -> Int {
        return packetIndex * maxPacketSize
    }

    /// 计算进度百分比
    /// - Parameters:
    ///   - currentPacket: 当前包序号
    ///   - totalPackets: 总包数
    /// - Returns: 进度（0.0 ~ 1.0）
    public func calculateProgress(currentPacket: Int, totalPackets: Int) -> Float {
        guard totalPackets > 0 else { return 0.0 }
        return min(Float(currentPacket) / Float(totalPackets), 1.0)
    }

    /// 计算字节进度百分比
    /// - Parameters:
    ///   - bytesTransferred: 已传输字节数
    ///   - totalBytes: 总字节数
    /// - Returns: 进度（0.0 ~ 1.0）
    public func calculateProgressByBytes(bytesTransferred: Int, totalBytes: Int) -> Float {
        guard totalBytes > 0 else { return 0.0 }
        return min(Float(bytesTransferred) / Float(totalBytes), 1.0)
    }
}
