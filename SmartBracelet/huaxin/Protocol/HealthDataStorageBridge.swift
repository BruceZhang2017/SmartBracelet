//
//  HealthDataStorageBridge.swift
//  SmartBracelet
//
//  Created by bruce on 2024/12/29.
//  Copyright © 2024 tjd. All rights reserved.
//

import Foundation
import WatchProtocolSDK

/// 健康数据存储桥接类
/// 将 WatchProtocolSDK 的 HealthDataStorageProtocol 协议桥接到主 App 的 DatabaseManager
public class HealthDataStorageBridge: HealthDataStorageProtocol {

    public init() {}

    public func saveStepData(_ data: WatchProtocolSDK.StepData) {
        let stepObj = StepObj()
        stepObj.date = data.date
        stepObj.mac = data.mac
        stepObj.step = data.step
        DatabaseManager.shared.addStepObj(stepObj: stepObj)
    }

    public func saveSleepData(_ data: WatchProtocolSDK.SleepData) {
        let sleepObj = SleepObj()
        sleepObj.date = data.date
        sleepObj.mac = data.mac
        sleepObj.awake = data.awake
        sleepObj.light = data.light
        sleepObj.deep = data.deep
        DatabaseManager.shared.addSleepObj(sleepObj: sleepObj)
    }

    public func saveHeartData(_ data: WatchProtocolSDK.HeartData) {
        let heartObj = HeartObj()
        heartObj.mac = data.mac
        heartObj.time = data.time
        heartObj.heart = data.heart
        DatabaseManager.shared.addHeartObj(heartObj: heartObj)
    }

    public func saveOxygenData(_ data: WatchProtocolSDK.OxygenData) {
        let oxgenObj = OxgenObj()
        oxgenObj.mac = data.mac
        oxgenObj.time = data.time
        oxgenObj.oxgen = data.oxygen
        DatabaseManager.shared.addOxgenObj(oxgenObj: oxgenObj)
    }

    public func saveBloodPressureData(_ data: WatchProtocolSDK.BloodPressureData) {
        let bloodObj = BloodObj()
        bloodObj.mac = data.mac
        bloodObj.time = data.time
        bloodObj.max = data.max
        bloodObj.min = data.min
        DatabaseManager.shared.addBloodObj(bloodObj: bloodObj)
    }
}
