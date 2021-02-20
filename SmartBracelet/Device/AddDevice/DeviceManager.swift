//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  DeviceManager.swift
//  SmartBracelet
//
//  Created by ANKER on 2021/1/24.
//  Copyright © 2021 tjd. All rights reserved.
//
	

import Foundation

class DeviceManager: NSObject {
    static let shared = DeviceManager()
    public var devices: [BLEModel] = []
    public var currentDevice: BLEModel?
    public var deviceInfo: [String: DeviceModel] = [:]
    public var steps: [DStepModel] = []
    public var alarms: [DAlarmModel] = [] // 闹钟
    
    override init() {
        super.init()
        initializeDevices()
        initializeAlarms()
    }
    
    public func initializeDevices() {
        devices.removeAll()
        if let models = try? BLEModel.er.all(), models.count > 0 {
            devices.append(contentsOf: models)
            print("数据库中的数据数量为: \(models.count)")
            return
        }
        print("数据库中的数据数量为: 0")
    }
    
    public func initializeAlarms() {
        alarms.removeAll()
        if let array = try? DAlarmModel.er.all(), array.count > 0 {
            alarms.append(contentsOf: array)
        }
        print("闹钟数量为：\(alarms.count)")
    }
    
    public func refreshSteps() {
        steps.removeAll()
        if let array = try? DStepModel.er.all() {
            steps.append(contentsOf: array)
            steps.sort(by: {$0.timeStamp < $1.timeStamp})
            print("查询到的步数：\(array.count)")
            return
        }
        print("查询到的步数为空")
    }
    
    public func getTotalSteps() -> Int {
        return steps.last?.step ?? 0
    }
    
    public func getTotalDistance() -> Int {
        return steps.last?.distance ?? 0
    }
    
    public func getTotalCal() -> Int {
        return steps.last?.cal ?? 0
    }
    
    public func getHeartRate() -> Int {
        if DeviceManager.shared.currentDevice == nil {
            return 0
        }
        let rate = try? DHeartRateModel.er.last("mac='\(DeviceManager.shared.currentDevice?.mac ?? "")'")?.heartRate
        return rate ?? 0
    }
    
    public func getBlood() -> (Int, Int) {
        if DeviceManager.shared.currentDevice == nil {
            return (0, 0)
        }
        let blood = try? DBloodModel.er.last("mac='\(DeviceManager.shared.currentDevice?.mac ?? "")'")
        let max = blood?.max ?? 0
        let min = blood?.min ?? 0
        return (max, min)
    }
}
