//
//  XGZTDialProtocol.swift
//  WatchFaceSDK
//
//  Created by bruce on 2025/12/30.
//

import Foundation
import WatchProtocolSDK

// MARK: - XGZT 表盘协议封装
public class XGZTDialProtocol {

    // MARK: - 单例
    public static let shared = XGZTDialProtocol()

    // MARK: - 通知名称
    public struct Notifications {
        public static let mtuQueryComplete = Notification.Name("XGZTDialProtocol.MTUQueryComplete")
        public static let configComplete = Notification.Name("XGZTDialProtocol.ConfigComplete")
        public static let dataTransferStart = Notification.Name("XGZTDialProtocol.DataTransferStart")
        public static let dataTransferComplete = Notification.Name("XGZTDialProtocol.DataTransferComplete")
        public static let dataTransferFailed = Notification.Name("XGZTDialProtocol.DataTransferFailed")
    }

    // MARK: - 私有属性
    private var mtuQueryCompletion: ((Result<Int, Error>) -> Void)?

    // MARK: - 初始化
    private init() {
        setupNotificationObservers()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - 公开方法

    /// 查询设备 MTU
    /// - Parameter completion: 完成回调
    public func queryMTU(completion: @escaping (Result<Int, Error>) -> Void) {
        self.mtuQueryCompletion = completion
        XGZTCommand.dialMarketQuery(dataType: 0)
    }

    /// 设置传输配置
    /// - Parameters:
    ///   - config: 传输配置
    public func setTransferConfig(_ config: TransferConfig) {
        XGZTCommand.dialMarketSetTransferConfig(
            packageTotal: config.packageTotal,
            binSize: config.binSize,
            mtu: config.mtu,
            dialType: config.dialType.rawValue,
            dialNum: 1,
            local: config.timePosition.rawValue,
            typeValue: 0,
            dialTypeValue: config.color.rawValue
        )
    }

    /// 传输数据包
    /// - Parameters:
    ///   - packageNum: 包序号（从1开始）
    ///   - binNum: 字节偏移量
    ///   - progress: 进度（0-100）
    ///   - control: 控制标志（0=继续，1=最后一包）
    ///   - data: 数据
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
    /// - Parameters:
    ///   - position: 时间位置
    ///   - color: 颜色
    public func setTimePositionAndColor(position: TimePosition, color: DialColor) {
        XGZTCommand.setTimePositionAndColor(
            type: 2,
            position: position.rawValue,
            color: color.rawValue
        )
    }

    // MARK: - 私有方法

    private func setupNotificationObservers() {
        // 这里需要监听来自 WatchProtocolSDK 的通知
        // 实际通知名称需要根据 WatchProtocolSDK 的实现来定义
    }

    // MARK: - 通知处理

    @objc private func handleMTUQueryComplete(_ notification: Notification) {
        // 处理 MTU 查询完成
        if let mtu = notification.userInfo?["mtu"] as? Int {
            mtuQueryCompletion?(.success(mtu))
            mtuQueryCompletion = nil
        } else {
            mtuQueryCompletion?(.failure(WatchFaceError.invalidMTU))
            mtuQueryCompletion = nil
        }
    }
}

// MARK: - 辅助方法
extension XGZTDialProtocol {

    /// 获取当前设备屏幕信息
    /// - Returns: 设备屏幕信息，如果设备未连接则返回 nil
    public static func getCurrentDeviceScreenInfo() -> DeviceScreenInfo? {
        guard let device = XGZTBlueToothManager.shared.device else {
            return nil
        }

        return DeviceScreenInfo(
            width: device.screenWidth,
            height: device.screenHeight,
            shape: device.screenType == 1 ? .round : .square,
            mtu: device.mtu
        )
    }

    /// 检查设备是否连接
    /// - Returns: 是否连接
    public static func isDeviceConnected() -> Bool {
        return XGZTBlueToothManager.shared.device != nil
    }
}
