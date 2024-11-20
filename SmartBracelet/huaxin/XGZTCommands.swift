//
//  XGZTCommand.swift
//  SmartBracelet
//
//  Created by anker on 2024/11/16.
//  Copyright © 2024 tjd. All rights reserved.
//

import Foundation

// 指令集
enum XGZTCommands: UInt8 {
    case syncTime = 0x50
    case getBatteryLevel = 0x51
    case setScreenBrightness = 0x52
    case getDeviceLanguage = 0x53
    case setDeviceUnitFormat = 0x54
    case resetToFactorySettings = 0x55
    case setDeviceScreenTimeout = 0x56
    case setDoNotDisturb = 0x57
    case findBand = 0x58
    case findPhone = 0x59
    case setWeatherUnit = 0x5A
    case set12H24HTimeFormat = 0x5B
    case getDeviceInfo = 0x5C
    case setAppInfo = 0x5D

    case personalInfo = 0x70

    case switchStatus = 0x80
    case bindDevice = 0x81
    case alarmInfo = 0x83
    case reminderInfo = 0x85
    case switchTableExtension = 0x86
    case musicControl = 0x90
    case remotePhoto = 0x91

    case messagePush = 0xA0
    case setWeatherInfo = 0xA1
    case contactInfo = 0xA4
    case incomingCallMute = 0xA6

    case targetSettings = 0xB0
    case multiSportModeData = 0xB3
    case getSleepData = 0xB5
    case setAutoSleepMonitoring = 0xB6

    case dialMarket = 0xE0
    case resourceUpgrade = 0xE2
}

// 数据类型定义
struct BatteryLevelResponse {
    let batteryLevel: Int
    let isCharging: Bool
}

struct DeviceLanguageResponse {
    let languageType: Int
}

struct DeviceUnitFormatResponse {
    let unitFormat: Int
}

struct PersonalInfo {
    let sex: Int
    let year: Int
    let height: Int
    let weight: Int
}

struct SwitchStatusResponse {
    let switchSettings: Int
}

struct AlarmInfoResponse {
    let alarmNum: Int
    let alarms: [AlarmData]?
}

struct AlarmData {
    let alarmIndex: Int
    let mswitch: Int
    let alarmCycle: Int
    let alarmHour: Int
    let alarmMinute: Int
    let vibrationMode: Int
    let remindLater: Int
}
    
struct ReminderInfoResponse {
    let eventType: Int
    let cycle: Int
    let startHour: Int
    let startMinute: Int
    let endHour: Int
    let endMinute: Int
    let period: Int
}

struct ContactInfoResponse {
    let contactNum: Int
    let contacts: [ContactData]?
}

struct ContactData {
    let index: Int
    let name: String
    let phoneNumber: String
}

struct TargetSettingsResponse {
    let targetSwitch: Int
    let stepTargetValue: Int
    let distanceTargetValue: Int
    let calorieTargetValue: Int
    let sleepTargetValue: Int
    let exerciseDurationTargetValue: Int
}

struct MultiSportModeData {
    let sportType: Int
    let timestamp: UInt32
    let stepCount: UInt32
    let calorie: UInt32
    let distance: UInt32
    let duration: UInt32
    let avgHeartRate: Int
    let staticCalorie: UInt32
}

struct SleepDataResponse {
    let shallowSleepHour: Int
    let deepSleepHour: Int
    let wakeUpNumber: Int
}

struct AutoSleepMonitoringResponse {
    let startHour: Int
    let startMinute: Int
    let endHour: Int
    let endMinute: Int
    let alarmCycle: Int
    let response: Int
}

struct DeviceInfoResponse {
    let watchType: Int
    let supportLanguage: Int
    let serialNumber: String
    let firmwareMajorVersion: Int
    let firmwareMinorVersion: Int
}

public class XGZTCommand {
    
    public static let methods: [String] = ["syncTime", "getBatteryLevel"]
    
    // 同步时间
    static func syncTime(timeZone: Int, utc: UInt32, completion: @escaping (Bool) -> Void) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.syncTime.rawValue,
            0x01,
            0x00,
            0x06,
            0x01,
            UInt8(timeZone),
            UInt8((utc >> 24) & 0xFF),
            UInt8((utc >> 16) & 0xFF),
            UInt8((utc >> 8) & 0xFF),
            UInt8(utc & 0xFF)
        ])
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            guard response.count >= 6 else {
                completion(false)
                return
            }
            completion(response[5] == 0x00)
        }
    }
    
    // 获取电池电量
    static func getBatteryLevel(completion: @escaping (BatteryLevelResponse) -> Void) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.getBatteryLevel.rawValue,
            0x01,
            0x00,
            0x01,
            0x00
        ])
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            guard response.count >= 7 else {
                // 这里可以根据具体需求进行更详细的错误处理，比如返回一个特定的错误值给调用者
                completion(BatteryLevelResponse(batteryLevel: -1, isCharging: false))
                return
            }
            let batteryLevel = Int(response[6] & 0x7F)
            let isCharging = (response[6] & 0x80) != 0
            completion(BatteryLevelResponse(batteryLevel: batteryLevel, isCharging: isCharging))
        }
    }
    
    // 设置屏幕亮度
    static func setScreenBrightness(brightnessValue: Int, completion: @escaping ( Bool) -> Void) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.setScreenBrightness.rawValue,
            0x01,
            0x00,
            0x01,
            UInt8(brightnessValue)
        ])
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            guard response.count >= 6 else {
                completion(false)
                return
            }
            completion(response[5] == 0x00)
        }
    }
    
    // 获取设备语言
    static func getDeviceLanguage(completion: @escaping (DeviceLanguageResponse) -> Void) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.getDeviceLanguage.rawValue,
            0x01,
            0x00,
            0x01,
            0x00
        ])
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            completion(DeviceLanguageResponse(languageType: Int(response[6])))
        }
    }
    
    // 设置设备单位格式
    static func setDeviceUnitFormat(unitType: Int, completion: @escaping ( Bool) -> Void) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.setDeviceUnitFormat.rawValue,
            0x01,
            0x00,
            0x01,
            0x01,
            UInt8(unitType)
        ])
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            completion(response[5] == 0x00)
        }
    }
    
    // 重置设备为出厂设置
    static func resetToFactorySettings(completion: @escaping ( Bool) -> Void) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.resetToFactorySettings.rawValue,
            0x01,
            0x00,
            0x01,
            0x00
        ])
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            completion(response[5] == 0x00)
        }
    }
    
    // 设置设备亮屏时间
    static func setDeviceScreenTimeout(screenTimeout: Int, completion: @escaping ( Bool) -> Void) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.setDeviceScreenTimeout.rawValue,
            0x01,
            0x00,
            0x05,
            0x01,
            UInt8((screenTimeout >> 24) & 0xFF),
            UInt8((screenTimeout >> 16) & 0xFF),
            UInt8((screenTimeout >> 8) & 0xFF),
            UInt8(screenTimeout & 0xFF)
        ])
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            completion(response[5] == 0x00)
        }
    }
    
    // 设置勿扰功能
    static func setDoNotDisturb(startHour: Int, startMinute: Int, endHour: Int, endMinute: Int, completion: @escaping ( Bool) -> Void) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.setDoNotDisturb.rawValue,
            0x01,
            0x00,
            0x05,
            0x00,
            UInt8(startHour),
            UInt8(startMinute),
            UInt8(endHour),
            UInt8(endMinute)
        ])
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            completion(response[5] == 0x00)
        }
    }
    
    // 查找手环
    static func findBand(completion: @escaping ( Bool) -> Void) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.findBand.rawValue,
            0x01,
            0x00,
            0x01,
            0x00
        ])
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            completion(response[5] == 0x00)
        }
    }
    
    // 查找手机
    static func findPhone(completion: @escaping ( Bool) -> Void) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.findPhone.rawValue,
            0x01,
            0x00,
            0x01,
            0x00
        ])
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            completion(response[5] == 0x00)
        }
    }
    
    // 设置天气单位
    static func setWeatherUnit(unit: Int, completion: @escaping ( Bool) -> Void) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.setWeatherUnit.rawValue,
            0x01,
            0x00,
            0x01,
            UInt8(unit)
        ])
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            completion(response[5] == 0x00)
        }
    }
    
    // 设置12小时/24小时时间制
    static func set12H24HTimeFormat(format: Int, completion: @escaping ( Bool) -> Void) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.set12H24HTimeFormat.rawValue,
            0x01,
            0x00,
            0x01,
            UInt8(format)
        ])
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            completion(response[5] == 0x00)
        }
    }
    
    // 获取设备信息
    static func getDeviceInfo(completion: @escaping (DeviceInfoResponse) -> Void) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.getDeviceInfo.rawValue,
            0x01,
            0x00,
            0x01,
            0x00
        ])
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            let watchType = Int(response[7])
            let supportLanguage = self.getIntFromBytes(response, 8)
            let serialNumber = self.getStringFromBytes(response, 12, 32)
            let firmwareMajorVersion = Int(response[44])
            let firmwareMinorVersion = Int(response[45])
            completion(DeviceInfoResponse(watchType: watchType, supportLanguage: supportLanguage, serialNumber: serialNumber, firmwareMajorVersion: firmwareMajorVersion, firmwareMinorVersion: firmwareMinorVersion))
        }
    }
    
    // 设置应用端信息
    static func setAppInfo(phoneType: Int, completion: @escaping ( Bool) -> Void) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.setAppInfo.rawValue,
            0x01,
            0x00,
            0x03,
            0x01,
            UInt8(phoneType)
        ])
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            completion(response[5] == 0x00)
        }
    }
    
    // 获取个人信息
    static func getPersonalInfo(completion: @escaping (PersonalInfo) -> Void) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.personalInfo.rawValue,
            0x01,
            0x00,
            0x01,
            0x00
        ])
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            let sex = Int(response[6])
            let year = Int(response[7])
            let height = Int(response[8])
            let weight = Int(response[9])
            completion(PersonalInfo(sex: sex, year: year, height: height, weight: weight))
        }
    }
    
    // 设置个人信息
    static func setPersonalInfo(sex: Int, year: Int, height: Int, weight: Int, completion: @escaping (Bool) -> Void) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.personalInfo.rawValue,
            0x01,
            0x00,
            0x04,
            0x01,
            UInt8(sex),
            UInt8(year),
            UInt8(height),
            UInt8(weight)
        ])
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            completion(response[5] == 0x00)
        }
    }
    
    // 获取开关状态
    static func getSwitchStatus(completion: @escaping (SwitchStatusResponse) -> Void) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.switchStatus.rawValue,
            0x01,
            0x00,
            0x01,
            0x00
        ])
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            let switchSettings = self.getIntFromBytes(response, 6)
            completion(SwitchStatusResponse(switchSettings: switchSettings))
        }
    }
    
    // 设置开关状态
    static func setSwitchStatus(switchSettings: Int, completion: @escaping (Bool) -> Void) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.switchStatus.rawValue,
            0x01,
            0x00,
            0x05,
            0x01,
            UInt8((switchSettings >> 24) & 0xFF),
            UInt8((switchSettings >> 16) & 0xFF),
            UInt8((switchSettings >> 8) & 0xFF),
            UInt8(switchSettings & 0xFF)
        ])
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            completion(response[5] == 0x00)
        }
    }
    
    // 绑定设备
    static func bindDevice(completion: @escaping (Bool) -> Void) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.bindDevice.rawValue,
            0x01,
            0x00,
            0x02,
            0x01,
            0x00
        ])
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            completion(response[5] == 0x00)
        }
    }
    
    // 获取闹钟信息
    static func getAlarmInfo(completion: @escaping (AlarmInfoResponse) -> Void) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.alarmInfo.rawValue,
            0x01,
            0x00,
            0x02,
            0x00
        ])
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            let alarmNum = Int(response[6])
            var alarms: [AlarmData]? = nil
            if alarmNum > 0 {
                alarms = []
                for i in 0..<alarmNum {
                    let index = Int(response[7 + i * 7])
                    let switchValue = Int(response[8 + i * 7])
                    let cycle = Int(response[9 + i * 7])
                    let hour = Int(response[10 + i * 7])
                    let minute = Int(response[11 + i * 7])
                    let vibration = Int(response[12 + i * 7])
                    let later = Int(response[13 + i * 7])
                    alarms?.append(AlarmData(alarmIndex: index, mswitch: switchValue, alarmCycle: cycle, alarmHour: hour, alarmMinute: minute, vibrationMode: vibration, remindLater: later))
                }
            }
            completion(AlarmInfoResponse(alarmNum: alarmNum, alarms: alarms))
        }
    }
    
    // 设置闹钟信息
    static func setAlarmInfo(setCmd: Int, alarmIndex: Int, switchValue: Int, alarmCycle: Int, alarmHour: Int, alarmMinute: Int, vibrationMode: Int, remindLater: Int, completion: @escaping (Bool) -> Void) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.alarmInfo.rawValue,
            0x01,
            0x00,
            0x09,
            UInt8(setCmd),
            UInt8(alarmIndex),
            UInt8(switchValue),
            UInt8(alarmCycle),
            UInt8(alarmHour),
            UInt8(alarmMinute),
            UInt8(vibrationMode),
            UInt8(remindLater)
        ])
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            completion(response[5] == 0x00)
        }
    }
    
    // 获取提醒信息
    static func getReminderInfo(eventType: Int, completion: @escaping (ReminderInfoResponse) -> Void) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.reminderInfo.rawValue,
            0x01,
            0x00,
            0x01,
            UInt8(eventType)
        ])
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            let cycle = Int(response[6])
            let startHour = Int(response[7])
            let startMinute = Int(response[8])
            let endHour = Int(response[9])
            let endMinute = Int(response[10])
            let period = Int(response[11])
            completion(ReminderInfoResponse(eventType: eventType, cycle: cycle, startHour: startHour, startMinute: startMinute, endHour: endHour, endMinute: endMinute, period: period))
        }
    }
    
    // 设置提醒信息
    static func setReminderInfo(eventType: Int, cycle: Int, startHour: Int, startMinute: Int, endHour: Int, endMinute: Int, period: Int, completion: @escaping (Bool) -> Void) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.reminderInfo.rawValue,
            0x01,
            0x00,
            0x08,
            UInt8(eventType),
            UInt8(cycle),
            UInt8(startHour),
            UInt8(startMinute),
            UInt8(endHour),
            UInt8(endMinute),
            UInt8(period)
        ])
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            completion(response[5] == 0x00)
        }
    }
    
    // 获取开关表扩展
    static func getSwitchTableExtension(completion: @escaping (Int) -> Void) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.switchTableExtension.rawValue,
            0x01,
            0x00,
            0x02,
            0x00
        ])
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            let switchSettings = self.getIntFromBytes(response, 6)
            completion(switchSettings)
        }
    }
    
    // 设置开关表扩展
    static func setSwitchTableExtension(switchSettings: Int, completion: @escaping (Bool) -> Void) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.switchTableExtension.rawValue,
            0x01,
            0x00,
            0x05,
            0x01,
            UInt8((switchSettings >> 24) & 0xFF),
            UInt8((switchSettings >> 16) & 0xFF),
            UInt8((switchSettings >> 8) & 0xFF),
            UInt8(switchSettings & 0xFF)
        ])
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            completion(response[5] == 0x00)
        }
    }
    
    // 音乐控制（此处仅为示例，根据实际需求完善）
    static func musicControl(action: Int, dataType: Int, completion: @escaping (Bool) -> Void) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.musicControl.rawValue,
            0x01,
            0x00,
            0x02,
            UInt8(action),
            UInt8(dataType)
        ])
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            completion(response[5] == 0x00)
        }
    }
    
    // 远程拍照
    static func remotePhoto(action: Int, completion: @escaping (Bool) -> Void) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.remotePhoto.rawValue,
            0x01,
            0x00,
            0x02,
            UInt8(action)
        ])
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            completion(response[5] == 0x00)
        }
    }
    
    // 消息推送（此处仅为示例，根据实际需求完善）
    static func messagePush(action: Int, control: Int, messageType: Int, messageContent: Data, completion: @escaping (Bool) -> Void) {
        var command = createCommand(with: [
            0x00,
            XGZTCommands.messagePush.rawValue,
            0x01,
            0x00,
            UInt8(6 + messageContent.count),
            UInt8(action),
            UInt8(control),
            UInt8(messageType)
        ])
        command.append(contentsOf: [UInt8](messageContent))
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            completion(response[5] == 0x00)
        }
    }
    
    // 设置天气信息（此处仅为示例，根据实际需求完善）
    static func setWeatherInfo(dateType: Int, cmdType: Int, value: Data, completion: @escaping (Bool) -> Void) {
        var command = createCommand(with: [
            0x00,
            XGZTCommands.setWeatherInfo.rawValue,
            0x01,
            0x00,
            UInt8(6 + value.count),
            UInt8(dateType),
            UInt8(cmdType)
        ])
        command.append(contentsOf: [UInt8](value))
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            completion(response[5] == 0x00)
        }
    }
    
    // 获取联系人信息
    static func getContactInfo(completion: @escaping (ContactInfoResponse) -> Void) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.contactInfo.rawValue,
            0x01,
            0x00,
            0x02,
            0x00
        ])
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            let contactNum = Int(response[6])
            var contacts: [ContactData]? = nil
            if contactNum > 0 {
                contacts = []
                var offset = 7
                for _ in 0..<contactNum {
                    let index = Int(response[offset])
                    offset += 1
                    let nameLength = Int(response[offset])
                    offset += 1
                    let name = String(bytes: response[offset..<(offset + nameLength)], encoding:.utf8)
                    offset += nameLength
                    let phoneNumberLength = Int(response[offset])
                    offset += 1
                    let phoneNumber = self.getPhoneNumberFromBytes(response, offset, phoneNumberLength)
                    offset += phoneNumberLength
                    contacts?.append(ContactData(index: index, name: name ?? "", phoneNumber: phoneNumber))
                }
            }
            completion(ContactInfoResponse(contactNum: contactNum, contacts: contacts))
        }
    }
    
    // 设置联系人信息
    static func setContactInfo(type: Int, index: Int, name: String, phoneNumber: String, completion: @escaping (Bool) -> Void) {
        let nameData = name.data(using:.utf8)!
        let phoneNumberData = phoneNumberToBytes(phoneNumber)
        var command = createCommand(with: [
            0x00,
            XGZTCommands.contactInfo.rawValue,
            0x01,
            0x00,
            UInt8(9 + nameData.count + phoneNumberData.count),
            UInt8(type),
            UInt8(index),
            UInt8(nameData.count),
        ])
        command.append(contentsOf: [UInt8](nameData))
        command.append(UInt8(phoneNumberData.count))
        command.append(contentsOf: [UInt8](phoneNumberData))
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            completion(response[5] == 0x00)
        }
    }
    
    // 来电静音
    static func incomingCallMute(mute: Int, completion: @escaping (Bool) -> Void) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.incomingCallMute.rawValue,
            0x01,
            0x00,
            0x02,
            UInt8(mute)
        ])
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            completion(response[5] == 0x00)
        }
    }
    
    // 获取目标设置
    static func getTargetSettings(completion: @escaping (TargetSettingsResponse) -> Void) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.targetSettings.rawValue,
            0x01,
            0x00,
            0x01,
            0x00
        ])
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            let targetSwitch = self.getShortFromBytes(response, 6)
            let stepTargetValue = Int(response[8])
            let distanceTargetValue = Int(response[9])
            let calorieTargetValue = self.getShortFromBytes(response, 10)
            let sleepTargetValue = self.getShortFromBytes(response, 12)
            let exerciseDurationTargetValue = self.getShortFromBytes(response, 14)
            completion(TargetSettingsResponse(targetSwitch: targetSwitch, stepTargetValue: stepTargetValue, distanceTargetValue: distanceTargetValue, calorieTargetValue: calorieTargetValue, sleepTargetValue: sleepTargetValue, exerciseDurationTargetValue: exerciseDurationTargetValue))
        }
    }
    
    // 设置目标设置
    static func setTargetSettings(targetSwitch: Int, targetType: Int, targetLength: Int, completion: @escaping (Bool) -> Void) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.targetSettings.rawValue,
            0x01,
            0x00,
            0x06,
            UInt8(targetSwitch),
            UInt8(targetType),
            UInt8(targetLength)
        ])
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            completion(response[5] == 0x00)
        }
    }
    
    // 获取多运动模式数据
    static func getMultiSportModeData(completion: @escaping ([MultiSportModeData]) -> Void) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.multiSportModeData.rawValue,
            0x01,
            0x00,
            0x01,
            0x00
        ])
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            let numData = self.getShortFromBytes(response, 6)
            var sportDataList: [MultiSportModeData] = []
            var offset = 8
            for _ in 0..<numData {
                let sportType = Int(response[offset])
                offset += 1
                let timestamp = self.getUInt32FromBytes(response, offset)
                offset += 4
                let stepCount = self.getUInt32FromBytes(response, offset)
                offset += 4
                let calorie = self.getUInt32FromBytes(response, offset)
                offset += 4
                let distance = self.getUInt32FromBytes(response, offset)
                offset += 4
                let duration = self.getUInt32FromBytes(response, offset)
                offset += 4
                let avgHeartRate = Int(response[offset])
                offset += 1
                let staticCalorie = self.getUInt32FromBytes(response, offset)
                offset += 4
                sportDataList.append(MultiSportModeData(sportType: sportType, timestamp: timestamp, stepCount: stepCount, calorie: calorie, distance: distance, duration: duration, avgHeartRate: avgHeartRate, staticCalorie: staticCalorie))
            }
            completion(sportDataList)
        }
    }
    
    // 删除运动模式数据
    static func deleteSportModeData(completion: @escaping (Bool) -> Void) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.multiSportModeData.rawValue,
            0x01,
            0x00,
            0x01,
            0x01
        ])
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            completion(response[5] == 0x00)
        }
    }
    
    // 获取睡眠数据
    static func getSleepData(dataType: Int, completion: @escaping (SleepDataResponse?) -> Void) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.getSleepData.rawValue,
            0x01,
            0x00,
            0x02,
            UInt8(dataType)
        ])
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            if dataType == 0x00 {
                let shallowSleepHour = self.getShortFromBytes(response, 6)
                let deepSleepHour = self.getShortFromBytes(response, 8)
                let wakeUpNumber = Int(response[10])
                completion(SleepDataResponse(shallowSleepHour: shallowSleepHour, deepSleepHour: deepSleepHour, wakeUpNumber: wakeUpNumber))
            } else {
                completion(nil)
            }
        }
    }
    
    // 设置自动睡眠监测
    static func setAutoSleepMonitoring(startHour: Int, startMinute: Int, endHour: Int, endMinute: Int, alarmCycle: Int, completion: @escaping (AutoSleepMonitoringResponse) -> Void) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.setAutoSleepMonitoring.rawValue,
            0x01,
            0x00,
            0x07,
            UInt8(startHour),
            UInt8(startMinute),
            UInt8(endHour),
            UInt8(endMinute),
            UInt8(alarmCycle)
        ])
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            let startHourResponse = Int(response[6])
            let startMinuteResponse = Int(response[7])
            let endHourResponse = Int(response[8])
            let endMinuteResponse = Int(response[9])
            let alarmCycleResponse = Int(response[10])
            let responseCode = Int(response[11])
            completion(AutoSleepMonitoringResponse(startHour: startHourResponse, startMinute: startMinuteResponse, endHour: endHourResponse, endMinute: endMinuteResponse, alarmCycle: alarmCycleResponse, response: responseCode))
        }
    }
    
    // 表盘市场相关操作（此处仅为示例，根据实际需求完善）
    static func dialMarketQuery(dataType: Int, completion: @escaping (Data) -> Void) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.dialMarket.rawValue,
            0x01,
            0x00,
            0x02,
            UInt8(dataType)
        ])
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            completion(Data(response))
        }
    }
    
    static func dialMarketSetTransferConfig(packageTotal: Int, binSize: Int, mtu: Int, dialType: Int, dialNum: Int, local: Int, dialTypeValue: Int, completion: @escaping (Bool) -> Void) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.dialMarket.rawValue,
            0x01,
            0x00,
            0x12,
            0x01,
            UInt8((packageTotal >> 8) & 0xFF),
            UInt8(packageTotal & 0xFF),
            UInt8((binSize >> 24) & 0xFF),
            UInt8((binSize >> 16) & 0xFF),
            UInt8((binSize >> 8) & 0xFF),
            UInt8(binSize & 0xFF),
            UInt8((mtu >> 8) & 0xFF),
            UInt8(mtu & 0xFF),
            UInt8(dialType),
            UInt8(dialNum),
            UInt8(local),
            UInt8((dialTypeValue >> 8) & 0xFF),
            UInt8(dialTypeValue & 0xFF)
        ])
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            completion(response[5] == 0x00)
        }
    }
    
    static func dialMarketTransferData(packageNum: Int, binNum: Int, progressBar: Int, control: Int, checkCode: Int, data: Data, completion: @escaping (Bool) -> Void) {
        var command = createCommand(with: [
            0x00,
            XGZTCommands.dialMarket.rawValue,
            0x01,
            0x00,
            UInt8(10 + data.count),
            0x02,
            UInt8((packageNum >> 8) & 0xFF),
            UInt8(packageNum & 0xFF),
            UInt8((binNum >> 24) & 0xFF),
            UInt8((binNum >> 16) & 0xFF),
            UInt8((binNum >> 8) & 0xFF),
            UInt8(binNum & 0xFF),
            UInt8(progressBar),
            UInt8(control),
            UInt8((checkCode >> 8) & 0xFF),
            UInt8(checkCode & 0xFF)
        ])
        command.append(contentsOf: [UInt8](data))
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            completion(response[5] == 0x00)
        }
    }
    
    // 资源升级相关操作（此处仅为示例，根据实际需求完善）
    static func resourceUpgradeQuery(completion: @escaping (Data) -> Void) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.resourceUpgrade.rawValue,
            0x01,
            0x00,
            0x02,
            0x00
        ])
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            completion(Data(response))
        }
    }
    
    static func resourceUpgradeSetTransferConfig(packageTotal: Int, binSize: Int, mtu: Int, completion: @escaping (Bool) -> Void) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.resourceUpgrade.rawValue,
            0x01,
            0x00,
            0x0A,
            0x01,
            UInt8((packageTotal >> 8) & 0xFF),
            UInt8(packageTotal & 0xFF),
            UInt8((binSize >> 24) & 0xFF),
            UInt8((binSize >> 16) & 0xFF),
            UInt8((binSize >> 8) & 0xFF),
            UInt8(binSize & 0xFF),
            UInt8((mtu >> 8) & 0xFF),
            UInt8(mtu & 0xFF)
        ])
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            completion(response[5] == 0x00)
        }
    }
    
    static func resourceUpgradeTransferData(data: Data, completion: @escaping (Bool) -> Void) {
        var command = createCommand(with: [
            0x00,
            XGZTCommands.resourceUpgrade.rawValue,
            0x01,
            0x00,
            UInt8(6 + data.count),
            0x02
        ])
        command.append(contentsOf: [UInt8](data))
        
        XGZTBlueToothManager.shared.writeCharacteristic(command: command) { response in
            completion(response[5] == 0x00)
        }
    }
    
    // 辅助方法：从字节数组中获取整数
    private static func getIntFromBytes(_ bytes: [UInt8], _ offset: Int = 0) -> Int {
        return Int(bytes[offset]) << 24 | Int(bytes[offset + 1]) << 16 | Int(bytes[offset + 2]) << 8 | Int(bytes[offset + 3])
    }
    
    private static func getStringFromBytes(_ bytes: [UInt8], _ startIndex: Int, _ length: Int) -> String {
        let subArray = bytes[startIndex..<startIndex+length]
        let data = Data(subArray)
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    // 辅助方法：从字节数组中获取短整数
    private static func getShortFromBytes(_ bytes: [UInt8], _ offset: Int = 0) -> Int {
        return Int(bytes[offset]) << 8 | Int(bytes[offset + 1])
    }
    
    // 辅助方法：从字节数组中获取无符号 32 位整数
    private static func getUInt32FromBytes(_ bytes: [UInt8], _ offset: Int = 0) -> UInt32 {
        return UInt32(bytes[offset]) << 24 | UInt32(bytes[offset + 1]) << 16 | UInt32(bytes[offset + 2]) << 8 | UInt32(bytes[offset + 3])
    }
    
    // 辅助方法：将电话号码转换为字节数组（根据协议规则）
    private static func phoneNumberToBytes(_ phoneNumber: String) -> [UInt8] {
        var phoneNumber = phoneNumber
        if phoneNumber.count % 2 != 0 {
            phoneNumber = "0" + phoneNumber
        }

        var result: [UInt8] = []
        let characters = Array(phoneNumber)
        for i in stride(from: 0, to: characters.count, by: 2) {
            let part = String(characters[i...i+1])
            if let byte = UInt8(part, radix: 16) {
                result.append(byte)
            } else {
                // Handle the error case where the conversion fails
                // You can throw an error or return an empty array, depending on your needs
                return []
            }
        }
        return result
    }
    
    // 辅助方法：从字节数组中获取电话号码（根据协议规则）
    private static func getPhoneNumberFromBytes(_ bytes: [UInt8], _ offset: Int, _ length: Int) -> String {
        var result = ""
        for i in 0..<length {
            result += String(format: "%02X", bytes[offset + i])
        }
        return result
    }
    
    // 辅助方法：创建指令字节数组
    private static func createCommand(with bytes: [UInt8]) -> [UInt8] {
        return bytes
    }
}
