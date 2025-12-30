//
//  XGZTCommandStateManager.swift
//  SmartBracelet
//
//  Created by Claude on 2025/12/27.
//  Copyright © 2025 tjd. All rights reserved.
//

import Foundation

/// 指令类型枚举
public enum XGZTCommandType: String {
    case bind81 = "指令81(绑定设备-阶段1)"
    case bind82 = "指令82(绑定设备-阶段2)"
    case setAppInfo5D = "指令5D(设置APP信息)"

    var flagKey: String {
        switch self {
        case .bind81: return "flag_81"
        case .bind82: return "flag_82"
        case .setAppInfo5D: return "flag_5d"
        }
    }
}

/// 设备读取流程状态枚举
public enum DeviceReadingState {
    case idle       // 空闲状态
    case reading    // 正在读取
    case completed  // 读取完成
}

/// 自研设备指令状态管理器（线程安全）
/// 负责管理蓝牙指令的超时检测标志和设备读取流程控制
public class XGZTCommandStateManager {

    // MARK: - 单例

    public static let shared = XGZTCommandStateManager()

    private init() {}

    // MARK: - 指令响应标志管理

    private let commandFlagsLock = NSLock()
    private var _commandFlags: [XGZTCommandType: Bool] = [:]

    /// 设置指令为待响应状态
    /// - Parameter command: 指令类型
    public func setCommandPending(_ command: XGZTCommandType) {
        commandFlagsLock.lock()
        defer { commandFlagsLock.unlock() }

        _commandFlags[command] = true
        XLogger.shared.log("⏳ \(command.rawValue) 等待响应")
    }

    /// 清除指令标志（表示已收到响应）
    /// - Parameter command: 指令类型
    public func clearCommandFlag(_ command: XGZTCommandType) {
        commandFlagsLock.lock()
        defer { commandFlagsLock.unlock() }

        _commandFlags[command] = false
        XLogger.shared.log("✅ \(command.rawValue) 已收到响应")
    }

    /// 检查指令是否仍在等待响应
    /// - Parameter command: 指令类型
    /// - Returns: true 表示仍在等待，false 表示已响应或未发送
    public func isCommandPending(_ command: XGZTCommandType) -> Bool {
        commandFlagsLock.lock()
        defer { commandFlagsLock.unlock() }

        return _commandFlags[command] ?? false
    }

    /// 清除所有指令标志
    public func clearAllCommandFlags() {
        commandFlagsLock.lock()
        defer { commandFlagsLock.unlock() }

        _commandFlags.removeAll()
        XLogger.shared.log("🧹 清空所有指令标志")
    }

    // MARK: - 设备读取流程控制

    private let readingStateLock = NSLock()
    private var _deviceReadingState: DeviceReadingState = .idle

    /// 当前设备读取状态
    public var deviceReadingState: DeviceReadingState {
        readingStateLock.lock()
        defer { readingStateLock.unlock() }
        return _deviceReadingState
    }

    /// 是否正在读取设备信息
    public var isDeviceReading: Bool {
        readingStateLock.lock()
        defer { readingStateLock.unlock() }
        return _deviceReadingState == .reading
    }

    /// 开始设备读取流程
    public func startDeviceReading() {
        readingStateLock.lock()
        defer { readingStateLock.unlock() }

        _deviceReadingState = .reading
        XLogger.shared.log("📖 开始读取设备信息")
    }

    /// 停止设备读取流程
    public func stopDeviceReading() {
        readingStateLock.lock()
        defer { readingStateLock.unlock() }

        _deviceReadingState = .completed
        XLogger.shared.log("✅ 设备信息读取完成")
    }

    /// 重置设备读取状态（设置为空闲）
    public func resetDeviceReadingState() {
        readingStateLock.lock()
        defer { readingStateLock.unlock() }

        _deviceReadingState = .idle
        XLogger.shared.log("🔄 重置设备读取状态为空闲")
    }

    // MARK: - 时间同步控制

    private let syncTimeLock = NSLock()
    private var _isSyncTimeSingle: Bool = false

    /// 是否为单次时间同步（因时区变化触发）
    public var isSyncTimeSingle: Bool {
        get {
            syncTimeLock.lock()
            defer { syncTimeLock.unlock() }
            return _isSyncTimeSingle
        }
        set {
            syncTimeLock.lock()
            defer { syncTimeLock.unlock() }

            _isSyncTimeSingle = newValue
            if newValue {
                XLogger.shared.log("🕐 设置单次时间同步标志")
            } else {
                XLogger.shared.log("✅ 清除单次时间同步标志")
            }
        }
    }

    // MARK: - 断开连接时的清理

    /// 设备断开连接时调用，清理所有状态
    public func handleDisconnected() {
        commandFlagsLock.lock()
        readingStateLock.lock()
        syncTimeLock.lock()
        defer {
            commandFlagsLock.unlock()
            readingStateLock.unlock()
            syncTimeLock.unlock()
        }

        _commandFlags.removeAll()
        _deviceReadingState = .idle
        _isSyncTimeSingle = false

        XLogger.shared.log("🔌 设备断开，清理所有指令状态")
    }
}

// MARK: - 向后兼容（全局变量）

/// 指令81标志（向后兼容，建议使用 XGZTCommandStateManager.shared）
@available(*, deprecated, message: "请使用 XGZTCommandStateManager.shared.setCommandPending(.bind81) / .clearCommandFlag(.bind81)")
public var flag_81: Bool {
    get {
        return XGZTCommandStateManager.shared.isCommandPending(.bind81)
    }
    set {
        if newValue {
            XGZTCommandStateManager.shared.setCommandPending(.bind81)
        } else {
            XGZTCommandStateManager.shared.clearCommandFlag(.bind81)
        }
    }
}

/// 指令82标志（向后兼容，建议使用 XGZTCommandStateManager.shared）
@available(*, deprecated, message: "请使用 XGZTCommandStateManager.shared.setCommandPending(.bind82) / .clearCommandFlag(.bind82)")
public var flag_82: Bool {
    get {
        return XGZTCommandStateManager.shared.isCommandPending(.bind82)
    }
    set {
        if newValue {
            XGZTCommandStateManager.shared.setCommandPending(.bind82)
        } else {
            XGZTCommandStateManager.shared.clearCommandFlag(.bind82)
        }
    }
}

/// 指令5D标志（向后兼容，建议使用 XGZTCommandStateManager.shared）
@available(*, deprecated, message: "请使用 XGZTCommandStateManager.shared.setCommandPending(.setAppInfo5D) / .clearCommandFlag(.setAppInfo5D)")
public var flag_5d: Bool {
    get {
        return XGZTCommandStateManager.shared.isCommandPending(.setAppInfo5D)
    }
    set {
        if newValue {
            XGZTCommandStateManager.shared.setCommandPending(.setAppInfo5D)
        } else {
            XGZTCommandStateManager.shared.clearCommandFlag(.setAppInfo5D)
        }
    }
}

/// 设备读取标志（向后兼容，建议使用 XGZTCommandStateManager.shared）
@available(*, deprecated, message: "请使用 XGZTCommandStateManager.shared.isDeviceReading")
public var flag_device_reading: Bool {
    get {
        return XGZTCommandStateManager.shared.isDeviceReading
    }
    set {
        if newValue {
            XGZTCommandStateManager.shared.startDeviceReading()
        } else {
            XGZTCommandStateManager.shared.stopDeviceReading()
        }
    }
}

/// 单次时间同步标志（向后兼容，建议使用 XGZTCommandStateManager.shared）
@available(*, deprecated, message: "请使用 XGZTCommandStateManager.shared.isSyncTimeSingle")
public var sync_time_single: Bool {
    get {
        return XGZTCommandStateManager.shared.isSyncTimeSingle
    }
    set {
        XGZTCommandStateManager.shared.isSyncTimeSingle = newValue
    }
}
