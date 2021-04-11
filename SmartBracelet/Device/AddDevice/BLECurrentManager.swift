//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  BLECurrentManager.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/11/1.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit

class BLECurrentManager: NSObject {
    static let sharedInstall = BLECurrentManager() // 单例
    var baby: BabyBluetooth!
    public var models: [BLEModel] = [] // 搜索到的设备
    public var deviceType = 0 // 1.非Lefun、2.Lefun
    private var perpheals: [String: CBPeripheral] = [:]
    private var currentPer: CBPeripheral!
    private var chars: [String: CBCharacteristic] = [:]
    
    override init() {
        super.init()
        baby = BabyBluetooth.share()
        babyDelegate() // 设置回调
        
    }
    
    /// 开始扫描，不需要等待蓝牙状态回调
    public func startScan() {
        models.removeAll() // 移除所有的设备
        baby.scanForPeripherals()?.begin()
        print("开始扫描")
    }
    
    /// 停止扫描
    public func stopScan() {
        baby.cancelScan()
    }
    
    /// 连接设备
    public func connectDevice(model: BLEModel) {
        if let per = perpheals[model.uuidString] {
            baby.having(per)?.enjoy()
        } else {
            let per = baby.retrievePeripheral(withUUIDString: model.uuidString)
            perpheals[model.uuidString] = per
            baby.having(per)?.enjoy()
        }
    }
    
    /// 断开所有设备
    public func disconnectAllDeivce() {
        baby.cancelAllPeripheralsConnection()
    }
    
    public func isHavenConnectedDevice() -> Bool {
        return currentPer != nil 
    }
    
    public func getCurrentDevice() -> BLEModel? {
        if currentPer == nil {
            return nil
        }
        if DeviceManager.shared.currentDevice != nil {
            return DeviceManager.shared.currentDevice
        }
        let uuid = currentPer.identifier.uuidString
        let array = DeviceManager.shared.devices
        for item in array {
            if item.uuidString == uuid { // 如果找到唯一标识符
                DeviceManager.shared.currentDevice = item
                return item
            }
        }
        return nil
    }
    
    private func babyDelegate() {
        baby.setBlockOnCentralManagerDidUpdateState { (manager) in
            let state = manager?.state ?? .unknown
            switch state {
            case .poweredOn:
                print("蓝牙已经打开")
                NotificationCenter.default.post(name: Notification.Name("HealthVCLoading"), object: 0)
            case .poweredOff:
                print("蓝牙已经关闭")
                NotificationCenter.default.post(name: Notification.Name("HealthVCLoading"), object: 1)
            case .unauthorized:
                print("蓝牙未授权")
                NotificationCenter.default.post(name: Notification.Name("HealthVCLoading"), object: 1)
            default:
                print("蓝牙状态未知")
            }
        }
        
        baby.setFilterOnDiscoverPeripherals { (name, data, rssi) -> Bool in // 过滤搜索到的设备
            if name == nil || name?.count == 0 {
                return false
            }
            if name == "PF116" || name == "PF1028" || name == "PFm5" || name == "Lefun" || name == "ITIME" {
                return true
            }
            return false
        }
        
        baby.setBlockOnDiscoverToPeripherals { [weak self] (manager, per, data, rssi) in // 搜索到设备
            print("搜索到的设备为：\(per?.name ?? "no name")")
            guard let uuid = per?.identifier.uuidString else { return }
            for item in self!.models {
                if item.uuidString == uuid {
                    return
                }
            }
            let name = per?.name ?? ""
            let model = BLEModel()
            model.name = name
            model.rssi = rssi?.intValue ?? 0
            model.uuidString = uuid
            if let data = data?[CBAdvertisementDataManufacturerDataKey] as? Data {
                if data.count == 0 { // 如果没有数据，直接返回
                    return
                }
                model.vendorNumberString = data.hexEncodedStringNoBlank()
                if data.count >= 6 {
                    if name == "Lefun" || name == "ITIME" {
                        model.mac = data[0..<6].hexEncodedString()
                    } else {
                        let start = data.count - 6
                        model.mac = data[start...].hexEncodedString()
                    }
                }
                print("设备携带的数据为：\(model.vendorNumberString)")
            }
            self?.models.append(model)
            self?.perpheals[uuid] = per
            NotificationCenter.default.post(name: Notification.Name.SearchDevice, object: "scan") // 通知刷新添加设备列表
            
        }
        
        baby.setFilterOnConnectToPeripherals { (name, data, rssi) -> Bool in
            if name == nil || name?.count ?? 0 == 0 {
                return false
            }
            if name == "PF116" || name == "PF1028" || name == "PFm5" {
                return true 
            }
            return false
        }
        
        baby.setBlockOnConnected {[weak self] (manager, per) in // 连接成功
            print("连接成功的设备: \(per?.name ?? "no name")")
            self?.currentPer = per
            let name = per?.name ?? ""
            if name == "Lefun" || name == "ITIME" {
                self?.deviceType = 2 // Lefun
                return
            }
            self?.deviceType = 1 // 非Lefun
            NotificationCenter.default.post(name: Notification.Name.SearchDevice, object: "connected")
            guard let uuid = per?.identifier.uuidString else { return }
            for item in DeviceManager.shared.devices {
                if item.uuidString == uuid {
                    print("匹配到连接的设备")
                    lastestDeviceMac = item.mac
                    UserDefaults.standard.setValue(lastestDeviceMac, forKey: "LastestDeviceMac")
                    UserDefaults.standard.setValue(false, forKey: "IsLefun")
                    UserDefaults.standard.synchronize()
                    break
                }
            }
            NotificationCenter.default.post(name: Notification.Name("DeviceList"), object: nil)
            NotificationCenter.default.post(name: Notification.Name("HealthVCLoading"), object: 2)
        }
        
        baby.setBlockOnDisconnect {[weak self] (manager, per, error) in
            print("断开连接的设备: \(per?.name ?? "no name")")
            self?.deviceType = 0
            let name = per?.name ?? ""
            if name == "Lefun" || name == "ITIME" {
                return
            }
            guard let uuid = per?.identifier.uuidString else { return }
            for item in DeviceManager.shared.devices {
                if item.uuidString == uuid {
                    print("匹配到断开的设备")
                    lastestDeviceMac = ""
                    break
                }
            }
            NotificationCenter.default.post(name: Notification.Name("DeviceList"), object: nil)
            self?.currentPer = nil
            self?.chars.removeAll()
        }
        
        baby.setBlockOnFailToConnect { (manager, per, err) in // 连接失败
            let name = per?.name ?? ""
            if name == "Lefun" || name == "ITIME" {
                return
            }
            NotificationCenter.default.post(name: Notification.Name.SearchDevice, object: "connectFail")
        }
        
        baby.setBlockOnDiscoverServices { (per, error) in
            let name = per?.name ?? ""
            if name == "Lefun" || name == "ITIME" {
                return
            }
            if let services = per?.services {
                for service in services {
                    print("发现的服务: \(service.uuid.uuidString)")
                }
            }
        }
        
        baby.setBlockOnDiscoverCharacteristics { [weak self] (per, service, error) in
            let name = per?.name ?? ""
            if name == "Lefun" || name == "ITIME" {
                return
            }
            if let characteristics = service?.characteristics {
                for characteristic in characteristics {
                    print("发现的特征: \(characteristic.uuid.uuidString)")
                }
            }
            if service?.characteristics == nil {
                return
            }
            for characteristic in service!.characteristics! as [CBCharacteristic] {
                if characteristic.properties.contains(CBCharacteristicProperties.notify) {
                    per?.setNotifyValue(true, for: characteristic)
                }
                self?.chars[characteristic.uuid.uuidString] = characteristic
            }
            if service?.uuid.uuidString == MPU_MS1001_SERVICE_UUID {
                
            }
        }
        
        baby.setBlockOnReadValueForCharacteristic { [weak self] (per, char, error) in
            let name = per?.name ?? ""
            if name == "Lefun" || name == "ITIME" {
                return
            }
            if let data = char?.value, data.count > 0 {
                print("读取\(char?.uuid.uuidString ?? "")到的数据为：\(data.hexEncodedStringBlank())")
                let uuid = per?.identifier.uuidString ?? ""
                if char?.uuid.uuidString ?? "" == MPU_BATTERY_INFO_UUID { // 电量
                    if let device = DeviceManager.shared.deviceInfo[uuid] {
                        device.battery = Int(data[0])
                        let cmdData = CMDData()
                        cmdData.handleDeviceBatteryNotify(data: data)
                    } else {
                        let device = DeviceModel()
                        device.battery = Int(data[0])
                        DeviceManager.shared.deviceInfo[uuid] = device
                        let cmdData = CMDData()
                        cmdData.handleDeviceBatteryNotify(data: data)
                    }
                } else if char?.uuid.uuidString ?? "" == MPU_DEVICE_INFO_UUID { // 版本号
                    let cmdData = CMDData()
                    cmdData.handleDeviceNameNotify(data: data)
                } else if char?.uuid.uuidString ?? "" == MPU_CONTROL_UUID {
                    self?.startSyncInfo() // 第一步同步时间
                    self?.perform(#selector(BLECurrentManager.startSyncForStepSleepmeter), with: nil, afterDelay: 0.1)
                } else if char?.uuid.uuidString == MPU_OTA_UUID {
                    OTA.share()?.handle()
                } else if char?.uuid.uuidString == MPU_REALTIME_DATA_UUID {
                    if data.count != 20 {
                        return
                    }
                    if data[0] == 0xF4 { // Sync notification
                        let cmdData = CMDData()
                        cmdData.handleNotify(data: data)
                        if data[1] == 0x01 { // Record base time
                            self?.confirmationReceivingBaseTime()
                        } else if data[1] == 0x02 {
                            self?.confirmationReceivingRecords(seq: Int(data[2]))
                        } else if data[1] == 0x03 {
                            self?.confirmationReceivingCurrentState()
                        } else if data[1] == 0x05 {
                            self?.confirmationOfReceivingBaseTime()
                        } else if data[1] == 0x06 {
                            self?.confirmationOfReceivingRecordsHRBP(seq: Int(data[2]))
                        } else if data[1] == 0x07 {
                            self?.confirmationOfReceivingEndSyncHRBP()
                        }
                     }
                }
            }
        }
        
        baby.setBlockOnDidWriteValueForCharacteristic { (char, error) in
            if let data = char?.value, data.count > 0 {
                print("写的数据成功")
            }
        }
        
        baby.setBlockOnDidUpdateNotificationStateForCharacteristic { [weak self] (char, err) in
            guard let data = char?.value, data.count > 0 else {
                return
            }
            print("返回\(char?.uuid.uuidString ?? "")的内容为：\(data.hexEncodedStringBlank())")
            if char?.uuid.uuidString == MPU_OTA_UUID {
                OTA.share()?.handle()
            }
            if char?.uuid.uuidString == MPU_REALTIME_DATA_UUID {
                if data.count != 20 {
                    return
                }
                if data[0] == 0xF4 { // Sync notification
                    let cmdData = CMDData()
                    cmdData.handleNotify(data: data)
                    if data[1] == 0x01 { // Record base time
                        self?.confirmationReceivingBaseTime()
                    } else if data[1] == 0x02 {
                        self?.confirmationReceivingRecords(seq: Int(data[2]))
                    } else if data[1] == 0x03 {
                        self?.confirmationReceivingCurrentState()
                    } else if data[1] == 0x05 {
                        self?.confirmationOfReceivingBaseTime()
                    } else if data[1] == 0x06 {
                        self?.confirmationOfReceivingRecordsHRBP(seq: Int(data[2]))
                    } else if data[1] == 0x07 {
                        self?.confirmationOfReceivingEndSyncHRBP()
                    }
                }
                if data[0] == 0x20 { // 保存心率数据
                    let heartRate = Int(data[10])
                    let heartRateModel = DHeartRateModel()
                    heartRateModel.heartRate = heartRate
                    heartRateModel.timeStamp = Int(Date().timeIntervalSince1970)
                    if let model = BLECurrentManager.sharedInstall.getCurrentDevice() {
                        heartRateModel.mac = model.mac
                        heartRateModel.uuidString = model.uuidString
                    }
                    try? heartRateModel.er.save(update: true)
                    NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "heart")
                }
                if data[0] == 0xF3 {
                    if data[1] == 0x14 { // 保存血压数据
                        let bloodModel = DBloodModel()
                        bloodModel.max = Int(data[2])
                        bloodModel.min = Int(data[3])
                        bloodModel.timeStamp = Int(Date().timeIntervalSince1970)
                        if let model = BLECurrentManager.sharedInstall.getCurrentDevice() {
                            bloodModel.mac = model.mac
                            bloodModel.uuidString = model.uuidString
                        }
                        try? bloodModel.er.save(update: true)
                        NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "blood")
                    }
                 }
             }
        }
        
        baby.setBlockOnCancelScanBlock { (manager) in
            print("停止扫描")
        }
    }
}

extension Notification.Name {
    static let SearchDevice = Notification.Name("SearchDevice")
}

extension BLECurrentManager {
    public func startSyncInfo() {
        let cmdData = CMDData()
        let data = cmdData.writeControlSetTime()
        guard let char = chars[MPU_CONTROL_UUID] else {
            return
        }
        var type: CBCharacteristicWriteType = .withResponse
        if ((char.properties.rawValue & CBCharacteristicProperties.writeWithoutResponse.rawValue) != 0 ) {
            type = .withoutResponse
        }
        currentPer?.writeValue(data, for: char, type: type)
        print("同步时间\(char.uuid.uuidString): \(data.hexEncodedStringBlank())")
    }
    
    /// 1.请求步数、睡眠数据
    @objc public func startSyncForStepSleepmeter() {
        let cmdData = CMDData()
        let data = cmdData.startSync()
        guard let char = chars[MPU_CONTROL_UUID] else {
            return
        }
        var type: CBCharacteristicWriteType = .withResponse
        if ((char.properties.rawValue & CBCharacteristicProperties.writeWithoutResponse.rawValue) != 0 ) {
            type = .withoutResponse
        }
        currentPer?.writeValue(data, for: char, type: type)
        print("同步开始\(char.uuid.uuidString): \(data.hexEncodedStringBlank())")
    }
    
    /// 2.回复接受到Base Time
    public func confirmationReceivingBaseTime() {
        let cmdData = CMDData()
        let data = cmdData.confirmationOfReceivingBaseTime()
        guard let char = chars[MPU_CONTROL_UUID] else {
            return
        }
        var type: CBCharacteristicWriteType = .withResponse
        if ((char.properties.rawValue & CBCharacteristicProperties.writeWithoutResponse.rawValue) != 0 ) {
            type = .withoutResponse
        }
        currentPer?.writeValue(data, for: char, type: type)
        print("同步开始\(char.uuid.uuidString): \(data.hexEncodedStringBlank())")
    }
    
    /// 3.回复接受到receiving records
    public func confirmationReceivingRecords(seq: Int) {
        let cmdData = CMDData()
        let data = cmdData.confirmationOfReceivingRecords(seq: seq)
        guard let char = chars[MPU_CONTROL_UUID] else {
            return
        }
        var type: CBCharacteristicWriteType = .withResponse
        if ((char.properties.rawValue & CBCharacteristicProperties.writeWithoutResponse.rawValue) != 0 ) {
            type = .withoutResponse
        }
        currentPer?.writeValue(data, for: char, type: type)
        print("同步开始\(char.uuid.uuidString): \(data.hexEncodedStringBlank())")
    }
    
    /// 4.同步接收到的当前状态
    public func confirmationReceivingCurrentState() {
        let cmdData = CMDData()
        let data = cmdData.confirmationOfReceivingCurrentState()
        guard let char = chars[MPU_CONTROL_UUID] else {
            return
        }
        var type: CBCharacteristicWriteType = .withResponse
        if ((char.properties.rawValue & CBCharacteristicProperties.writeWithoutResponse.rawValue) != 0 ) {
            type = .withoutResponse
        }
        currentPer?.writeValue(data, for: char, type: type)
        print("同步开始\(char.uuid.uuidString): \(data.hexEncodedStringBlank())")
        perform(#selector(startSyncForHRBP), with: nil, afterDelay: 0.1)
        //NotificationCenter.default.post(name: Notification.Name("HealthVCLoading"), object: 3)
    }
    
    /// 5.请求开始血压
    @objc public func startSyncForHRBP() {
        let cmdData = CMDData()
        let data = cmdData.startSyncHRBP()
        guard let char = chars[MPU_CONTROL_UUID] else {
            return
        }
        var type: CBCharacteristicWriteType = .withResponse
        if ((char.properties.rawValue & CBCharacteristicProperties.writeWithoutResponse.rawValue) != 0 ) {
            type = .withoutResponse
        }
        currentPer?.writeValue(data, for: char, type: type)
        print("同步开始\(char.uuid.uuidString): \(data.hexEncodedStringBlank())")
    }
    
    /// 6.同步血压接收时间
    public func confirmationOfReceivingBaseTime() {
        let cmdData = CMDData()
        let data = cmdData.confirmationOfReceivingBaseTime2()
        guard let char = chars[MPU_CONTROL_UUID] else {
            return
        }
        var type: CBCharacteristicWriteType = .withResponse
        if ((char.properties.rawValue & CBCharacteristicProperties.writeWithoutResponse.rawValue) != 0 ) {
            type = .withoutResponse
        }
        currentPer?.writeValue(data, for: char, type: type)
        print("同步开始\(char.uuid.uuidString): \(data.hexEncodedStringBlank())")
    }
    
    /// 7.同步血压数据
    public func confirmationOfReceivingRecordsHRBP(seq: Int) {
        let cmdData = CMDData()
        let data = cmdData.confirmationOfReceivingRecords2(seq: seq)
        guard let char = chars[MPU_CONTROL_UUID] else {
            return
        }
        var type: CBCharacteristicWriteType = .withResponse
        if ((char.properties.rawValue & CBCharacteristicProperties.writeWithoutResponse.rawValue) != 0 ) {
            type = .withoutResponse
        }
        currentPer?.writeValue(data, for: char, type: type)
        print("同步开始\(char.uuid.uuidString): \(data.hexEncodedStringBlank())")
    }
    
    /// 8.同步血压结束
    public func confirmationOfReceivingEndSyncHRBP() {
        let cmdData = CMDData()
        let data = cmdData.confirmationOfReceivingEndSync()
        guard let char = chars[MPU_CONTROL_UUID] else {
            return
        }
        var type: CBCharacteristicWriteType = .withResponse
        if ((char.properties.rawValue & CBCharacteristicProperties.writeWithoutResponse.rawValue) != 0 ) {
            type = .withoutResponse
        }
        currentPer?.writeValue(data, for: char, type: type)
        print("同步开始\(char.uuid.uuidString): \(data.hexEncodedStringBlank())")
        NotificationCenter.default.post(name: Notification.Name("HealthVCLoading"), object: 3)
    }
    
    public func readOTAChar() {
        guard let char = chars[MPU_OTA_UUID] else {
            return
        }
        currentPer?.readValue(for: char)
    }
    
    public func writeOTAChar(data: Data) {
        guard let char = chars[MPU_OTA_UUID] else {
            return
        }
        var type: CBCharacteristicWriteType = .withResponse
        if ((char.properties.rawValue & CBCharacteristicProperties.writeWithoutResponse.rawValue) != 0 ) {
            type = .withoutResponse
        }
        currentPer?.writeValue(data, for: char, type: type)
    }
    
    public func setSmartAlarm() {
        let cmdData = CMDData()
        let data = cmdData.writeControlSmartAlarm(values: DeviceManager.shared.alarms)
        guard let char = chars[MPU_CONTROL_UUID] else {
            return
        }
        var type: CBCharacteristicWriteType = .withResponse
        if ((char.properties.rawValue & CBCharacteristicProperties.writeWithoutResponse.rawValue) != 0 ) {
            type = .withoutResponse
        }
        currentPer?.writeValue(data, for: char, type: type)
        print("同步开始\(char.uuid.uuidString): \(data.hexEncodedStringBlank())")
    }
    
}

