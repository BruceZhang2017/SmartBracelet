//
//  WatchProtocolSDK.swift
//  WatchProtocolSDK
//
//  Created by anker_bruce on 2025/12/27.
//  Copyright © 2025 tjd. All rights reserved.
//

import Foundation

// MARK: - 简单数据模型（不依赖 RealmSwift）

/// 步数数据模型
public struct StepData {
    public let date: String
    public let mac: String
    public let step: Int

    public init(date: String, mac: String, step: Int) {
        self.date = date
        self.mac = mac
        self.step = step
    }
}

/// 睡眠数据模型
public struct SleepData {
    public let date: String
    public let mac: String
    public let awake: Int
    public let light: Int
    public let deep: Int

    public init(date: String, mac: String, awake: Int, light: Int, deep: Int) {
        self.date = date
        self.mac = mac
        self.awake = awake
        self.light = light
        self.deep = deep
    }
}

/// 心率数据模型
public struct HeartData {
    public let mac: String
    public let time: Int
    public let heart: Int

    public init(mac: String, time: Int, heart: Int) {
        self.mac = mac
        self.time = time
        self.heart = heart
    }
}

/// 血氧数据模型
public struct OxygenData {
    public let mac: String
    public let time: Int
    public let oxygen: Int

    public init(mac: String, time: Int, oxygen: Int) {
        self.mac = mac
        self.time = time
        self.oxygen = oxygen
    }
}

/// 血压数据模型
public struct BloodPressureData {
    public let mac: String
    public let time: Int
    public let max: Int
    public let min: Int

    public init(mac: String, time: Int, max: Int, min: Int) {
        self.mac = mac
        self.time = time
        self.max = max
        self.min = min
    }
}

// MARK: - 数据存储协议

/// 健康数据存储协议
/// SDK 通过此协议与外部数据存储交互，不直接依赖具体实现
public protocol HealthDataStorageProtocol: AnyObject {
    /// 保存步数数据
    func saveStepData(_ data: StepData)

    /// 保存睡眠数据
    func saveSleepData(_ data: SleepData)

    /// 保存心率数据
    func saveHeartData(_ data: HeartData)

    /// 保存血氧数据
    func saveOxygenData(_ data: OxygenData)

    /// 保存血压数据
    func saveBloodPressureData(_ data: BloodPressureData)
}

/// 默认空实现（可选，用于测试或无数据存储需求场景）
public class EmptyHealthDataStorage: HealthDataStorageProtocol {
    public init() {}

    public func saveStepData(_ data: StepData) {
        // 空实现
    }

    public func saveSleepData(_ data: SleepData) {
        // 空实现
    }

    public func saveHeartData(_ data: HeartData) {
        // 空实现
    }

    public func saveOxygenData(_ data: OxygenData) {
        // 空实现
    }

    public func saveBloodPressureData(_ data: BloodPressureData) {
        // 空实现
    }
}
