//
//  XGZTDeviceManager.swift
//  SmartBracelet
//
//  Created by Claude on 2025/12/27.
//  Copyright © 2025 tjd. All rights reserved.
//

import Foundation

/// 自研设备管理器（线程安全）
/// 负责管理设备缓存和连接失败诊断信息
public class XGZTDeviceManager {

    // MARK: - 单例

    public static let shared = XGZTDeviceManager()

    private init() {
        // 注意：不在此处调用 BluetoothWatchDevice.loadAll() 避免循环依赖死锁
        // loadAll() 内部会调用 XGZTDeviceManager.shared.reloadDevices()
        // 而此时 shared 还在初始化中，会导致死锁
        // 应用启动时会在 MTabBarController.viewDidLoad 中调用 loadAll()
    }

    // MARK: - 设备缓存管理

    private let deviceCacheLock = NSLock()
    private var _cacheDevices: [BluetoothWatchDevice] = []

    /// 线程安全的设备缓存列表（只读）
    public var cacheDevices: [BluetoothWatchDevice] {
        deviceCacheLock.lock()
        defer { deviceCacheLock.unlock() }
        return _cacheDevices
    }

    /// 设备缓存数量
    public var deviceCount: Int {
        deviceCacheLock.lock()
        defer { deviceCacheLock.unlock() }
        return _cacheDevices.count
    }

    /// 添加设备到缓存
    /// - Parameter device: 要添加的设备
    public func addDevice(_ device: BluetoothWatchDevice) {
        deviceCacheLock.lock()
        defer { deviceCacheLock.unlock() }

        // 去重：如果已存在相同 MAC 地址的设备，则不添加
        if let mac = device.max,
           !_cacheDevices.contains(where: { $0.max == mac }) {
            _cacheDevices.append(device)
            XLogger.shared.log("✅ 添加设备到缓存: \(device.deviceName ?? "未知") [\(mac)]")
        }
    }

    /// 移除指定 MAC 地址的设备
    /// - Parameter mac: 设备 MAC 地址
    public func removeDevice(mac: String) {
        deviceCacheLock.lock()
        defer { deviceCacheLock.unlock() }

        _cacheDevices.removeAll { $0.max == mac }
        XLogger.shared.log("🗑️ 移除设备缓存: [\(mac)]")
    }

    /// 查找指定 MAC 地址的设备
    /// - Parameter mac: 设备 MAC 地址
    /// - Returns: 找到的设备，如果不存在则返回 nil
    public func findDevice(mac: String) -> BluetoothWatchDevice? {
        deviceCacheLock.lock()
        defer { deviceCacheLock.unlock() }

        return _cacheDevices.first { $0.max == mac }
    }

    /// 获取最后一个设备
    /// - Returns: 最后一个设备，如果缓存为空则返回 nil
    public func lastDevice() -> BluetoothWatchDevice? {
        deviceCacheLock.lock()
        defer { deviceCacheLock.unlock() }

        return _cacheDevices.last
    }

    /// 清空所有设备缓存
    public func clearDeviceCache() {
        deviceCacheLock.lock()
        defer { deviceCacheLock.unlock() }

        _cacheDevices.removeAll()
        XLogger.shared.log("🧹 清空所有设备缓存")
    }

    /// 重新加载所有设备（从 UserDefaults）
    public func reloadDevices() {
        deviceCacheLock.lock()
        defer { deviceCacheLock.unlock() }

        _cacheDevices.removeAll()

        let defaults = UserDefaults.standard
        guard let dic = defaults.dictionary(forKey: "xgzt") as? [String: String] else {
            return
        }

        if dic.isEmpty {
            return
        }

        var existingMACs = Set<String>()

        for (mac, name) in dic {
            // 检查 MAC 是否已存在（去重）
            if existingMACs.contains(mac) {
                continue
            }

            existingMACs.insert(mac)

            let device = BluetoothWatchDevice()
            device.deviceName = name
            device.max = mac
            _cacheDevices.append(device)
            XLogger.shared.log("📦 缓存设备: \(mac) - \(name)")
        }

        XLogger.shared.log("✅ 重新加载设备完成，共 \(_cacheDevices.count) 个设备")
    }

    // MARK: - 连接失败诊断信息管理

    private let failMessageLock = NSLock()
    private var _failMessages: [String] = []
    private let maxFailMessageCount = 50 // 最多保留50条失败信息

    /// 获取所有连接失败信息（只读）
    public var connectFailMessage: String {
        failMessageLock.lock()
        defer { failMessageLock.unlock() }

        return _failMessages.joined(separator: "\n")
    }

    /// 获取最近的失败信息数组
    public var recentFailMessages: [String] {
        failMessageLock.lock()
        defer { failMessageLock.unlock() }

        return _failMessages
    }

    /// 追加连接失败信息
    /// - Parameter message: 失败信息
    public func appendFailMessage(_ message: String) {
        failMessageLock.lock()
        defer { failMessageLock.unlock() }

        // 添加时间戳
        let timestamp = DateFormatter.logDateFormatter.string(from: Date())
        let messageWithTimestamp = "[\(timestamp)] \(message)"

        _failMessages.append(messageWithTimestamp)

        // 限制数组大小，避免内存泄漏
        if _failMessages.count > maxFailMessageCount {
            _failMessages.removeFirst(_failMessages.count - maxFailMessageCount)
        }

        XLogger.shared.log("❌ 连接失败: \(message)")
    }

    /// 清空所有连接失败信息
    public func clearFailMessages() {
        failMessageLock.lock()
        defer { failMessageLock.unlock() }

        _failMessages.removeAll()
        XLogger.shared.log("🧹 清空连接失败信息")
    }

    /// 获取最近 N 条失败信息
    /// - Parameter count: 要获取的数量
    /// - Returns: 最近的失败信息数组
    public func getRecentFailMessages(count: Int) -> [String] {
        failMessageLock.lock()
        defer { failMessageLock.unlock() }

        let startIndex = max(0, _failMessages.count - count)
        return Array(_failMessages[startIndex..<_failMessages.count])
    }
}

// MARK: - 向后兼容（全局变量）

/// 设备缓存（向后兼容，建议使用 XGZTDeviceManager.shared.cacheDevices）
@available(*, deprecated, message: "请使用 XGZTDeviceManager.shared.cacheDevices")
public var cacheDevices: [BluetoothWatchDevice] {
    get {
        return XGZTDeviceManager.shared.cacheDevices
    }
}

/// 连接失败信息（向后兼容，建议使用 XGZTDeviceManager.shared）
@available(*, deprecated, message: "请使用 XGZTDeviceManager.shared.appendFailMessage() 和 .connectFailMessage")
public var connectFailMessage: String {
    get {
        return XGZTDeviceManager.shared.connectFailMessage
    }
    set {
        // 为了兼容原有的 += 操作
        if !newValue.isEmpty {
            XGZTDeviceManager.shared.appendFailMessage(newValue)
        } else {
            XGZTDeviceManager.shared.clearFailMessages()
        }
    }
}

// MARK: - DateFormatter 扩展（日志时间格式）

extension DateFormatter {
    static let logDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}
