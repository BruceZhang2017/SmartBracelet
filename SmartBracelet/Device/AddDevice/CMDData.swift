//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  CMDData.swift
//  SmartBracelet
//
//  Created by ANKER on 2021/1/10.
//  Copyright © 2021 tjd. All rights reserved.
//
	

import UIKit

let MPU_MS1001_SERVICE_UUID = "CC00"
let MPU_DEVICE_INFO_UUID = "CC02"
let MPU_BATTERY_INFO_UUID = "CC03"
let MPU_REALTIME_DATA_UUID = "CC04"
let MPU_SYNC_UUID = "CC05"
let MPU_CONTROL_UUID = "CC06"
let MPU_OTA_UUID = "00010203-0405-0607-0809-0a0b0c0d2b12".uppercased()

enum Command: UInt8 {
    case setting = 0xF1
    case reminding = 0xF2
    case sync = 0xF4
}

enum DeivceNotify: UInt8 {
    case data = 0xF3
    case sync = 0xF4
}

var baseTime = 0

class CMDData: NSObject {
    
    public func setProfile() -> Data {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = Command.setting.rawValue
        data[1] = 0x01
        data[2] = 0x00 // 0x00 male 0x01 female
        data[3] = 0x22 // age
        data[4] = 0xb0 // height cm
        data[5] = 0x50 // weight kg
        data[6] = 0x00 // 0 left hand, 1 right hand
        data[7] = 0x01 // 0: km, 1: m
        data[8] = 0x00 // 小端模式 低位在前
        data[9] = 0x64 // 1万米
        return data
    }
    
    public func setDisplayItems() -> Data {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = Command.setting.rawValue
        data[1] = 0x02
        data[2] = 0x01 // time 0:disable,1:enable
        data[3] = 0x00 // time format 0: only time, 1:time + date
        data[4] = 0x01 // steps 0:disable, 1: enable
        data[5] = 0x01 // distance 0:disable, 1: enable
        data[6] = 0x01 // calories 0:disable, 1: enable
        data[7] = 0x01 // Heart rate 0:disable, 1: enable
        data[8] = 0x01 // remaining battery 0:disable, 1: enable
        data[9] = 0x01 // lift wrist to view info 0:disable, 1: enable
        data[10] = 0x01 // rotate wrist to switch info
        data[11] = 0x01 // heart rate sleep assistant
        data[12] = 0x01 // english or chinese 0:english, 1: chinese
        data[13] = 0x01 // blood pressure
        data[14] = 0x00 // uiColor type 0-3
        data[15] = 0x00 // screen orientation 0: default direction, 1: another direction
        data[16] = 0x00 // ui display type 0-3
        return data
    }
    
    public func setControl() -> Data {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = Command.setting.rawValue
        data[1] = 0x03
        data[2] = 0x14 // 0x14: blood pressure, 0x15: Device power down, 0x16: heart rate i2c test
        // 0x17: Bloodpressure i2c test, 0x18: Reset to factory settings, 0x19: Clear current & history data
        data[3] = 0x00 // 0x00: Off/Stop, 0x01: On/Start
        return data
    }
    
    public func incomingCall() -> Data {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = Command.reminding.rawValue
        data[1] = 0x01
        data[2] = 0x00 // 0: call end; 1~17: number or name
        // 3-19 String, including Chinese character. One ASCII character occupies 1 byte, and one gb2313 occupies 2 bytes.
        return data
    }
    
    public func messageOrAppAlerts() -> Data {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = Command.reminding.rawValue
        data[1] = 0x02
        data[2] = 0x01 // 0: No message,1: Message alert
        data[3] = 0x00 // 0: No other app alerts 1: App alerts
        data[4] = 0x00 // 0: No wechat alert, 1: Wechat alert
        data[5] = 0x00 // 0: No QQ alert, 1: QQ alert
        return data
    }
    
    public func incomingCall1() -> Data {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = Command.reminding.rawValue
        data[1] = 0x03
        data[2] = 0x00 // 0: call end; 1~16: count of phone numbers or name characters
        data[3] = 0x00 // If Length > 8, need 2 packages, this byte indicates package number: 0 means the first, 1 means the last.
        return data
    }
    
    public func messageContent() -> Data {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = Command.reminding.rawValue
        data[1] = 0x10
        data[2] = 0x00
        data[3] = 0x00 // Each package can only have 8 characters, this byte is used to indicate package number.
        return data
    }
    
    public func wechatContent() -> Data {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = Command.reminding.rawValue
        data[1] = 0x11
        data[2] = 0x00 // Message content characters’ count
        data[3] = 0x00 // Each package can only have 8 characters, this byte is used to indicate package number.
        return data
    }
    
    public func qqContent() -> Data {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = Command.reminding.rawValue
        data[1] = 0x12
        data[2] = 0x00 // Message content characters’ count
        data[3] = 0x00 // Each package can only have 8 characters, this byte is used to indicate package number.
        return data
    }
    
    public func facebookContent() -> Data {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = Command.reminding.rawValue
        data[1] = 0x13
        data[2] = 0x00 // Facebook content characters’ count
        data[3] = 0x00 // Each package can only have 8 characters, this byte is used to indicate package number.
        return data
    }
    
    public func twitterContent() -> Data {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = Command.reminding.rawValue
        data[1] = 0x14
        return data
    }
    
    public func whatsappContent() -> Data {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = Command.reminding.rawValue
        data[1] = 0x15
        return data
    }
    
    public func instagramContent() -> Data {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = Command.reminding.rawValue
        data[1] = 0x16
        return data
    }
    
    /// Start Sync (for step & sleepmeter)
    public func startSync() -> Data {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = Command.sync.rawValue
        data[1] = 0x00 // 0x00: Start sync
        return data
    }
    
    /// Confirmation of receiving base time
    public func confirmationOfReceivingBaseTime() -> Data {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = Command.sync.rawValue
        data[1] = 0x01 // 0x01: Confirmation of receiving base time
        return data
    }
    
    public func confirmationOfReceivingRecords(seq: Int) -> Data {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = Command.sync.rawValue
        data[1] = 0x02 // Confirmation of receiving records
        data[2] = UInt8(seq & 0xFF) // Records package sequence number, 0x01, 0x02, means No. 513.
        data[3] = UInt8((seq >> 8) & 0xFF)
        return data
    }
    
    public func confirmationOfReceivingCurrentState() -> Data {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = Command.sync.rawValue
        data[1] = 0x03 // 0x03: Confirmation of receiving current state
        return data
    }
    
    public func startSyncHRBP() -> Data {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = Command.sync.rawValue
        data[1] = 0x04
        return data
    }
    
    public func confirmationOfReceivingBaseTime2() -> Data {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = Command.sync.rawValue
        data[1] = 0x05 //  Confirmation of receiving base time
        return data
    }
    
    public func confirmationOfReceivingRecords2(seq: Int) -> Data {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = Command.sync.rawValue
        data[1] = 0x06
        data[2] = UInt8(seq & 0xFF) // Records package sequence number, 0x01, 0x02, means No. 513.
        data[3] = UInt8((seq >> 8) & 0xFF)
        return data
    }
    
    public func confirmationOfReceivingEndSync() -> Data {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = Command.sync.rawValue
        data[1] = 0x07
        return data
    }
    
    /// 处理通知内容
    public func handleNotify(data: Data) {
        if data.count != 20 {
            return
        }
        if data[0] == DeivceNotify.data.rawValue {
            if data[1] == 0x14 { // blood pressure
                bloodPressureNotify(data: data)
            } else if data[1] == 0x16 { // Heartrate i2c state
                heartRateI2CStateNotify(data: data)
            } else if data[1] == 0x17 { // Bloodpressure i2c state
                bloodPressureI2CStateNotify(data: data)
            } else if data[1] == 0x18 { // find phone
                findPhoneNotify(data: data)
            }
        } else if data[0] == DeivceNotify.sync.rawValue { //  Sync Notify
            if data[1] == 0x01 { // Record base time
                recordBaseTimeNotify(data: data)
            } else if data[1] == 0x02 { // Records
                recordsNotify(data: data)
            } else if data[1] == 0x03 { // Current state
                currentStateNotify(data: data)
            } else if data[1] == 0x05 { // Record base time
                recordBaseTimeForHRBPNotify(data: data)
            } else if data[1] == 0x06 { // Records for hr/bp
                recordsForHRBPNotify(data: data)
            } else if data[1] == 0x07 { // End sync
                endSyncForHRBPNotify(data: data)
            }
        }
    }
    
    private func bloodPressureNotify(data: Data) {
        let systolicPressure = data[2] // sbp
        let diastolicPressure = data[3] // dbp
        print("获取到血压数据：\(systolicPressure) \(diastolicPressure)")
    }
    
    private func heartRateI2CStateNotify(data: Data) {
        let state = data[2] > 0 // 0: fail,1: success
        print("心跳硬件状态：\(state)")
    }
    
    private func bloodPressureI2CStateNotify(data: Data) {
        let state = data[2] > 0 // 0: fail,1: success
        print("血压硬件状态：\(state)")
    }
    
    private func findPhoneNotify(data: Data) {
        print("查找手机")
    }
    
    private func recordBaseTimeNotify(data: Data) {
        let year = Int(data[2])
        let month = Int(data[3])
        let day = Int(data[4])
        let hour = Int(data[5])
        let minute = Int(data[6])
        let second = Int(data[7])
        baseTime = DateHelper().ymdHmsToDate(y: 2000 + year, m: month, d: day, h: hour, m2: minute, s: second)
        print("手环返回的时间：\(2000 + year)-\(month)-\(day) \(hour):\(minute):\(second)")
    }
    
    private func recordsNotify(data: Data) {
        let seq = Int(data[2]) + Int(data[3]) * Int(256)
        print("当前包序号：\(seq)")
        let num = Int(data[4])
        print("How much records in this Seq, range \(num)")
        if num >= 1 {
            let record1 = Int(data[5]) // State: occupying 1 byte 0: Stationary 1: Walking 2: Running 3: Sleep 4: Awake 5: Restless 6~: Others, depends on Algo
            let record1Minutes = Int(data[7]) * 256 + Int(data[6])
            let record1Step = Int(data[9]) * 256 + Int(data[8])
            print("record1: \(record1) record1Minutes: \(record1Minutes) record1Step: \(record1Step)")
            if record1Step > 0 {
                let stepModel = DStepModel()
                stepModel.mac = bleSelf.bleModel.mac
                stepModel.uuidString = bleSelf.bleModel.uuidString
                stepModel.timeStamp = baseTime + record1Minutes * 60
                stepModel.step = record1Step
                stepModel.state = record1
                do {
                    try stepModel.er.save(update: true)
                    print("保存成功")
                } catch {
                    print("保存失败：\(error.localizedDescription)")
                }
                
            }
        }
        if num >= 2 {
            let record2 = Int(data[10])
            let record2Minutes = Int(data[12]) * 256 + Int(data[11])
            let record2Step = Int(data[14]) * 256 + Int(data[13])
            print("record2: \(record2) record2Minutes: \(record2Minutes) record2Step: \(record2Step)")
            if record2Step > 0  {
                let stepModel = DStepModel()
                stepModel.mac = bleSelf.bleModel.mac
                stepModel.uuidString = bleSelf.bleModel.uuidString
                stepModel.timeStamp = baseTime + record2Minutes * 60
                stepModel.step = record2Step
                stepModel.state = record2
                do {
                    try stepModel.er.save(update: true)
                    print("保存成功")
                } catch {
                    print("保存失败：\(error.localizedDescription)")
                }
            }
        }
        if num > 2 {
            let record3 = Int(data[15])
            let record3Minutes = Int(data[17]) * 256 + Int(data[16])
            let record3Step = Int(data[19]) * 256 + Int(data[18])
            print("record3: \(record3) record3Minutes: \(record3Minutes) record3Step: \(record3Step)")
            if record3Step > 0  {
                let stepModel = DStepModel()
                stepModel.mac = bleSelf.bleModel.mac
                stepModel.uuidString = bleSelf.bleModel.uuidString
                stepModel.timeStamp = baseTime + record3Minutes * 60
                stepModel.step = record3Step
                stepModel.state = record3
                do {
                    try stepModel.er.save(update: true)
                    print("保存成功")
                } catch {
                    print("保存失败：\(error.localizedDescription)")
                }
            }
        }
    }
    
    private func currentStateNotify(data: Data) {
        let record1 = Int(data[2])
        let record1Minutes = Int(data[4]) * 256 + Int(data[3])
        let record1Step = Int(data[6]) * 256 + Int(data[5])
        print("record: \(record1) recordMinutes: \(record1Minutes) recordStep: \(record1Step)")
        let year = Int(data[7])
        let month = Int(data[8])
        let day = Int(data[9])
        let hour = Int(data[10])
        let minute = Int(data[11])
        let second = Int(data[12])
        print("手环返回的currnet state时间：\(2000 + year)-\(month)-\(day) \(hour):\(minute):\(second)")
        DeviceManager.shared.refreshSteps()
        NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "step")
    }
    
    private func recordBaseTimeForHRBPNotify(data: Data) {
        let year = Int(data[2])
        let month = Int(data[3])
        let day = Int(data[4])
        let hour = Int(data[5])
        let minute = Int(data[6])
        let second = Int(data[7])
        print("手环返回的record时间：\(2000 + year)-\(month)-\(day) \(hour):\(minute):\(second)")
    }
    
    private func recordsForHRBPNotify(data: Data) {
        let seq = Int(data[2]) + Int(data[3]) * Int(256)
        print("当前包序号：\(seq)")
        let num = Int(data[4])
        print("How much records in this Seq, range \(num)")
        if num >= 1 {
            let seconds1 = Int(data[5]) + Int(data[6]) * 256 + Int(data[7]) * 256 * 256 + Int(data[8]) * 256 * 256 * 256
            let value1 = Int(data[10]) * 256 + Int(data[9])
            print("seconds1: \(seconds1) value1: \(value1)")
        }
        if num >= 2 {
            let seconds2 = Int(data[10]) + Int(data[11]) * 256 + Int(data[12]) * 256 * 256 + Int(data[13]) * 256 * 256 * 256
            let value2 = Int(data[15]) * 256 + Int(data[14])
            print("seconds2: \(seconds2) value2: \(value2)")
        }
    }
    
    private func endSyncForHRBPNotify(data: Data) {
        print("end sync")
    }
    
    private func writeDeviceName(name: String) -> Data {
        var data = Data(repeating: 0x00, count: 20)
        let nameData = name.data(using: .utf8)
        for i in 0..<(nameData?.count ?? 0) {
            data[i] = nameData?[i] ?? UInt8(0)
        }
        return data
    }
    
    public func handleDeviceNameNotify(data: Data) {
        if data.count != 20 {
            return
        }
        let subData = Data(data[11...14])
        let firmwareVersion = String(data: subData, encoding: String.Encoding.ascii)?.replacingOccurrences(of: "\0", with: "") ?? ""
        let deviceCapability = Int(data[15])
        print("版本号：\(firmwareVersion) deviceCapability: \(deviceCapability)")
    }
    
    public func handleDeviceBatteryNotify(data: Data) {
        if data.count != 20 {
            return
        }
        let battery = Int(data[0])
        let year = Int(data[1])
        let month = Int(data[2])
        let day = Int(data[3])
        let hour = Int(data[4])
        let minute = Int(data[5])
        let second = Int(data[6])
        let batteryState = Int(data[7]) // 1: Charging, 2: Charged, 3: Not charging
        print("battery: \(battery) battery state:\(batteryState)")
        print("手环时间：\(2000 + year)-\(month)-\(day) \(hour):\(minute):\(second)")
        
    }
    
    public func handleRealtimeDataNotify(data: Data) {
        if data.count != 20 {
            return
        }
        let flag = Int(data[0]) + Int(data[1]) * 256
        print("flag: \(flag)")
        if flag < 0x0020 {
            flagLess20Notify(flag: flag, data: data)
        } else if flag == 0x0100 {
            flagLess100Notify(data: data)
        } else if flag == 0x0040 {
            flagLess40Notify(data: data)
        } else if flag == 0x0200 {
            flagLess200Notify(data: data)
        } else if flag == 0x0080 {
            flagLess80Notify(data: data)
        }
    }
    
    private func flagLess20Notify(flag: Int, data: Data) {
        let state = Int(data[2])
        print("state: \(state)")
        let stepCount = Int(data[3]) + Int(data[4]) * 256 + Int(data[5]) * 256 * 256
        print("stepCount: \(stepCount)")
        let longsit = Int(data[7])
        print("longsit: \(longsit)")
        let shake = Int(data[8])
        print("shake: \(shake)")
        let sensorState = Int(data[9])
        print("sensorState: \(sensorState)")
        let heartRate = Int(data[10])
        print("heartRate: \(heartRate)")
        let battery = Int(data[11])
        let batteryState = Int(data[12])
        print("设备电量：\(battery) 设备电量状态：\(batteryState)")
        if flag == 0x10 {
            let subData = Data(data[13...16])
            let firmwareVersion = String(data: subData, encoding: .utf8) ?? ""
            print("设备当前版本号：\(firmwareVersion)")
        }
        let hrbpState = Int(data[17])
        print("hrbpState: \(hrbpState)")
    }
    
    private func flagLess100Notify(data: Data) { // Request phone to sync records
        let length = Int(data[2])
        let endSignal = data[3] == 0x0d && data[4] == 0x0a
        print("length: \(length) data[3]: \(data[3]) data[4]:\(data[4])")
    }
    
    private func flagLess40Notify(data: Data) { // Step raw data
        let count = Int(data[3]) + Int(data[2]) * 256
        let stepCount = Int(data[16]) + Int(data[17]) * 256 + Int(data[18]) * 256 * 256 + Int(data[19]) * 256 * 256 * 256
        print("count: \(count) stepCount: \(stepCount)")
    }
    
    private func flagLess200Notify(data: Data) {
        let count = Int(data[3]) + Int(data[2]) * 256
        let stepCount = Int(data[16]) + Int(data[17]) * 256 + Int(data[18]) * 256 * 256 + Int(data[19]) * 256 * 256 * 256
        print("count: \(count) stepCount: \(stepCount)")
    }
    
    private func flagLess80Notify(data: Data) { // Sleep raw data 1
        let count = Int(data[3]) + Int(data[2]) * 256
        let stepCount = Int(data[16]) + Int(data[17]) * 256 + Int(data[18]) * 256 * 256 + Int(data[19]) * 256 * 256 * 256
        print("count: \(count) stepCount: \(stepCount)")
    }
    
    public func handleSyncNotify(data: Data) {
        if data.count != 20 {
            return
        }
        let flag = Int(data[0])
        if flag == 0x01 { // sync start
            syncStartNotify(data: data)
        } else if flag == 0x02 {
            syncRecordNotify(data: data)
        } else if flag == 0x03 {
            syncCurrentStateNotify(data: data)
        } else if flag == 0x04 {
            syncEndNotify(data: data)
        }
    }
    
    private func syncStartNotify(data: Data) {
        let year = Int(data[2])
        let month = Int(data[3])
        let day = Int(data[4])
        let hour = Int(data[5])
        let minute = Int(data[6])
        let second = Int(data[7])
        print("sync data：\(2000 + year)-\(month)-\(day) \(hour):\(minute):\(second)")
    }
    
    private func syncRecordNotify(data: Data) {
        let state = Int(data[2]) // 0: Idle, 1: Walking, 2: Running, 3: Sleep, 4: Awake 5: Restless, 6~255: Unknown.
        let stepCount = Int(data[3]) + Int(data[4]) * 256 + Int(data[5]) * 256 * 256 + Int(data[6]) * 256 * 256 * 256
        let minutes = Int(data[7]) + Int(data[8]) * 256
        print("state: \(state) stepCount: \(stepCount) minutes: \(minutes)")
    }
    
    private func syncCurrentStateNotify(data: Data) {
        let state = Int(data[2]) // 0: Idle, 1: Walking, 2: Running, 3: Sleep, 4: Awake 5: Restless, 6~255: Unknown.
        let stepCount = Int(data[3]) + Int(data[4]) * 256 + Int(data[5]) * 256 * 256 + Int(data[6]) * 256 * 256 * 256
        let year = Int(data[7])
        let month = Int(data[8])
        let day = Int(data[9])
        let hour = Int(data[10])
        let minute = Int(data[11])
        let second = Int(data[12])
        let minutes = Int(data[13]) + Int(data[14]) * 256
        print("state: \(state) stepCount: \(stepCount) minutes: \(minutes)")
        print("current state：\(2000 + year)-\(month)-\(day) \(hour):\(minute):\(second)")
    }
    
    private func syncEndNotify(data: Data) {
        print("sync end")
    }
    
    public func writeControlVibrate(value: Bool) -> Data  {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = 0x01
        data[1] = value ? 0x01 : 0x00
        return data
    }
    
    public func writeControlIncoming(value: Bool) -> Data  {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = 0x02
        data[1] = value ? 0x01 : 0x00
        return data
    }
    
    public func writeControlSMS(value: Bool) -> Data  {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = 0x03
        data[1] = value ? 0x01 : 0x00
        return data
    }
    
    public func writeControlSetTime(value: Bool) -> Data  { // Depend on Control ID, if not listed on the below
        var data = Data(repeating: 0x00, count: 20)
        data[0] = 0x04
        data[1] = value ? 0x01 : 0x00
        return data
    }
    
    public func writeControlSync(value: Bool) -> Data  {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = 0x05
        data[1] = value ? 0x01 : 0x00
        return data
    }
    
    public func writeControlAntiLoss(value: Bool) -> Data  {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = 0x06
        data[1] = value ? 0x01 : 0x00
        return data
    }
    
    public func writeControlLongsit(value: Bool) -> Data  {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = 0x07
        data[1] = value ? 0x01 : 0x00
        return data
    }
    
    public func writeControlSmartAlarm(value: Bool) -> Data  {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = 0x08
        data[1] = value ? 0x01 : 0x00
        return data
    }
    
    public func writeControlShake(value: Bool) -> Data  {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = 0x09
        data[1] = value ? 0x01 : 0x00
        return data
    }
    
    public func writeControlHeartRate(value: Bool) -> Data  {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = 0x0a
        data[1] = value ? 0x01 : 0x00
        return data
    }
    
    public func writeControlSmartAlarm2(value: Bool) -> Data  {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = 0x0c
        data[1] = value ? 0x01 : 0x00
        return data
    }
    
    public func writeControlStepRawData(value: Bool) -> Data  {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = 0x0b
        data[1] = value ? 0x01 : 0x00
        return data
    }
    
    public func writeControlACK(value: Bool) -> Data  {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = 0x0d
        data[1] = value ? 0x01 : 0x00
        return data
    }
    
    public func writeControlAPKAdvertising(value: Bool) -> Data  {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = 0x0e
        data[1] = value ? 0x01 : 0x00
        return data
    }
    
    public func writeControlStepRawData2(value: Bool) -> Data  {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = 0x0f
        data[1] = value ? 0x01 : 0x00
        return data
    }
    
    public func writeControlStepRawData1(value: Bool) -> Data {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = 0x10
        data[1] = value ? 0x01 : 0x00
        return data
    }
    
    public func writeControlIncoming2(value: Bool) -> Data {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = 0x12
        data[1] = value ? 0x01 : 0x00
        return data
    }
    
    public func writeControlSMSWechatQQ(value: Bool) -> Data {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = 0x13
        data[1] = value ? 0x01 : 0x00
        return data
    }
    
    public func writeControlLED(value: Bool) -> Data {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = 0x71
        data[1] = value ? 0x01 : 0x00
        return data
    }
    
    public func writeControlMotor(value: Bool) -> Data {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = 0x72
        data[1] = value ? 0x01 : 0x00
        return data
    }
    
    public func writeControlCheckSensor(value: Bool) -> Data {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = 0x73
        data[1] = value ? 0x01 : 0x00
        return data
    }
    
    public func writeControlCheckTestAll(value: Bool) -> Data {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = 0x74
        data[1] = value ? 0x01 : 0x00
        return data
    }
    
    public func writeControlPeepRecords(value: Bool) -> Data {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = 0x75
        data[1] = value ? 0x01 : 0x00
        return data
    }
    
    public func writeControlSetTime() -> Data {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = 0x04
        let calendar = Calendar.current
        let now = Date()
        data[2] = UInt8(calendar.component(.year, from: now) - 2000)
        data[3] = UInt8(calendar.component(.month, from: now))
        data[4] = UInt8(calendar.component(.day, from: now))
        data[5] = UInt8(calendar.component(.hour, from: now))
        data[6] = UInt8(calendar.component(.minute, from: now))
        data[7] = UInt8(calendar.component(.second, from: now))
        return data
    }
    
    public func writeControlSetLongsit(value: Bool, minutes: Int) -> Data {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = 0x07
        data[1] = value ? 0x01 : 0x00
        data[2] = UInt8(minutes % 256)
        data[3] = UInt8(minutes / 256)
        return data
    }
    
    public func writeControlSmartAlarm(values: [DAlarmModel]) -> Data {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = 0x0c
        data[1] = 0x01
        for i in 0..<values.count {
            data[4 * i + 2] = values[i].isOn ? 0x01 : 0x00
            data[4 * i + 3] = UInt8(values[i].hour)
            data[4 * i + 4] = UInt8(values[i].minute)
            data[4 * i + 5] = UInt8(values[i].weekday)
        }
        return data
    }
    
    public func writeControlACK(from: Int, result: Int) -> Data {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = 0x0d
        data[1] = 0x04
        data[2] = UInt8(from)
        data[3] = UInt8(result)
        data[4] = 0x0d
        data[5] = 0x0a
        return data
    }
    
    public func writeControlAppAdvertising(status: Int) -> Data {
        var data = Data(repeating: 0x00, count: 20)
        data[0] = 0x0e
        data[1] = 0x03
        data[2] = UInt8(status)
        data[3] = 0x0d
        data[4] = 0x0a
        return data
    }
}
