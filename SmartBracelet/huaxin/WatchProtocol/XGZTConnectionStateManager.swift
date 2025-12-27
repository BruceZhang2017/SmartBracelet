//
//  XGZTConnectionStateManager.swift
//  SmartBracelet
//
//  Created by Claude on 2025/12/27.
//  Copyright © 2025 tjd. All rights reserved.
//

import Foundation

/// 设备类型枚举
public enum DeviceType {
    case none           // 未连接设备
    case standard       // 标准设备（TJD SDK）
    case xgzt           // 自研设备（XGZT协议）
}

/// 设备连接状态管理器（线程安全）
/// 负责管理设备连接状态、MAC地址和设备类型
public class XGZTConnectionStateManager {

    // MARK: - 单例

    public static let shared = XGZTConnectionStateManager()

    private init() {
        // 从 UserDefaults 加载上次连接的设备MAC
        loadLastDeviceMac()
    }

    // MARK: - 设备类型管理

    private let deviceTypeLock = NSLock()
    private var _currentDeviceType: DeviceType = .none

    /// 当前连接的设备类型
    public var currentDeviceType: DeviceType {
        deviceTypeLock.lock()
        defer { deviceTypeLock.unlock() }
        return _currentDeviceType
    }

    /// 是否为自研设备（XGZT）
    public var isXGZTDevice: Bool {
        deviceTypeLock.lock()
        defer { deviceTypeLock.unlock() }
        return _currentDeviceType == .xgzt
    }

    /// 是否为标准设备
    public var isStandardDevice: Bool {
        deviceTypeLock.lock()
        defer { deviceTypeLock.unlock() }
        return _currentDeviceType == .standard
    }

    /// 是否已连接设备
    public var isDeviceConnected: Bool {
        deviceTypeLock.lock()
        defer { deviceTypeLock.unlock() }
        return _currentDeviceType != .none
    }

    /// 设置设备类型
    /// - Parameter type: 设备类型
    public func setDeviceType(_ type: DeviceType) {
        deviceTypeLock.lock()
        defer { deviceTypeLock.unlock() }

        _currentDeviceType = type

        switch type {
        case .none:
            XLogger.shared.log("🔌 设备已断开")
        case .standard:
            XLogger.shared.log("📱 已连接标准设备")
        case .xgzt:
            XLogger.shared.log("⌚️ 已连接自研设备(XGZT)")
        }
    }

    // MARK: - 设备MAC地址管理

    private let macAddressLock = NSLock()
    private var _lastDeviceMac: String = ""
    private let userDefaultsKey = "LastestDeviceMac"

    /// 最后连接的设备MAC地址
    public var lastDeviceMac: String {
        get {
            macAddressLock.lock()
            defer { macAddressLock.unlock() }
            return _lastDeviceMac
        }
        set {
            macAddressLock.lock()
            defer { macAddressLock.unlock() }

            _lastDeviceMac = newValue

            // 持久化到 UserDefaults
            UserDefaults.standard.set(newValue, forKey: userDefaultsKey)
            UserDefaults.standard.synchronize()

            if newValue.isEmpty {
                XLogger.shared.log("🗑️ 清除最后连接的设备MAC")
            } else {
                XLogger.shared.log("💾 保存设备MAC: \(newValue)")
            }
        }
    }

    /// 从 UserDefaults 加载上次连接的设备MAC
    private func loadLastDeviceMac() {
        macAddressLock.lock()
        defer { macAddressLock.unlock() }

        _lastDeviceMac = UserDefaults.standard.string(forKey: userDefaultsKey) ?? ""
        if !_lastDeviceMac.isEmpty {
            XLogger.shared.log("📖 加载设备MAC: \(_lastDeviceMac)")
        }
    }

    /// 清除最后连接的设备MAC
    public func clearLastDeviceMac() {
        lastDeviceMac = ""
    }

    // MARK: - 连接状态管理

    /// 标记XGZT设备已连接
    /// - Parameter mac: 设备MAC地址
    public func markXGZTConnected(mac: String) {
        setDeviceType(.xgzt)
        lastDeviceMac = mac
        XLogger.shared.log("✅ XGZT设备已连接: \(mac)")
    }

    /// 标记标准设备已连接
    /// - Parameter mac: 设备MAC地址
    public func markStandardConnected(mac: String) {
        setDeviceType(.standard)
        lastDeviceMac = mac
        XLogger.shared.log("✅ 标准设备已连接: \(mac)")
    }

    /// 标记设备已断开
    /// - Parameter clearMac: 是否清除MAC地址，默认为 false
    public func markDisconnected(clearMac: Bool = false) {
        setDeviceType(.none)
        if clearMac {
            clearLastDeviceMac()
        }
        XLogger.shared.log("🔌 设备已断开\(clearMac ? "，MAC已清除" : "")")
    }

    // MARK: - 便捷方法

    /// 检查指定MAC是否为当前连接的设备
    /// - Parameter mac: 要检查的MAC地址
    /// - Returns: true 表示是当前设备，false 表示不是
    public func isCurrentDevice(mac: String) -> Bool {
        macAddressLock.lock()
        defer { macAddressLock.unlock() }
        return _lastDeviceMac == mac && !mac.isEmpty
    }

    /// 获取当前设备的完整状态描述
    public var statusDescription: String {
        deviceTypeLock.lock()
        macAddressLock.lock()
        defer {
            deviceTypeLock.unlock()
            macAddressLock.unlock()
        }

        let typeStr: String
        switch _currentDeviceType {
        case .none:
            typeStr = "未连接"
        case .standard:
            typeStr = "标准设备"
        case .xgzt:
            typeStr = "自研设备(XGZT)"
        }

        let macStr = _lastDeviceMac.isEmpty ? "无" : _lastDeviceMac
        return "设备状态: \(typeStr), MAC: \(macStr)"
    }

    /// 打印当前状态（调试用）
    public func printStatus() {
        XLogger.shared.log(statusDescription)
    }
}

// MARK: - 向后兼容（全局变量）

/// 是否为自研设备（向后兼容，建议使用 XGZTConnectionStateManager.shared）
@available(*, deprecated, message: "请使用 XGZTConnectionStateManager.shared.isXGZTDevice")
public var isXGZT: Bool {
    get {
        return XGZTConnectionStateManager.shared.isXGZTDevice
    }
    set {
        if newValue {
            // 只设置设备类型，不修改MAC（因为MAC应该在连接时单独设置）
            XGZTConnectionStateManager.shared.setDeviceType(.xgzt)
        } else {
            // 检查是否有其他类型的设备连接
            // 如果 lastDeviceMac 不为空，可能是标准设备
            if !XGZTConnectionStateManager.shared.lastDeviceMac.isEmpty {
                XGZTConnectionStateManager.shared.setDeviceType(.standard)
            } else {
                XGZTConnectionStateManager.shared.setDeviceType(.none)
            }
        }
    }
}

/// 最后连接的设备MAC地址（向后兼容，建议使用 XGZTConnectionStateManager.shared）
@available(*, deprecated, message: "请使用 XGZTConnectionStateManager.shared.lastDeviceMac")
public var lastestDeviceMac: String {
    get {
        return XGZTConnectionStateManager.shared.lastDeviceMac
    }
    set {
        XGZTConnectionStateManager.shared.lastDeviceMac = newValue
    }
}
