//
//  XGZTCommand.swift
//  SmartBracelet
//
//  Created by bruce on 2024/11/16.
//  Copyright © 2024 tjd. All rights reserved.
//

import UIKit

//
//  XGZTCommand.swift
//  SmartBracelet
//
//  Created by bruce on 2024/11/16.
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
    case unbindDeviceNotif = 0x82
    case alarmInfo = 0x83
    case reminderInfo = 0x85
    case switchTableExtension = 0x86
    case disconnectBT = 0x87
    case musicControl = 0x90
    case remotePhoto = 0x91

    case messagePush = 0xA0
    case setWeatherInfo = 0xA1
    case contactInfo = 0xA4
    case incomingCallMute = 0xA6

    case targetSettings = 0xB0
    case multiSportModeData = 0xB3
    case getSleepMonitoring = 0xB5
    case setAutoSleepMonitoring = 0xB6
    
    case startTest = 0xC5
    case getNewestHealthData = 0xC7
    case getStepData = 0xC8
    case getHistorySleepData = 0xC9
    case getNewestHeartData = 0xCA

    case dialMarket = 0xE0
    case setTimePositionAndColor = 0xE1
    case resourceUpgrade = 0xE2
    case qrCode = 0xE3
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

struct SwitchStatusResponse {
    let switchSettings: Int
}

struct AlarmInfoResponse {
    let alarmNum: Int
    let alarms: [AlarmData]?
}

struct AlarmData {
    var alarmIndex: Int
    var mswitch: Int
    var alarmCycle: Int
    var alarmHour: Int
    var alarmMinute: Int
    var vibrationMode: Int
    var remindLater: Int
}

struct ReminderInfoResponse {
    var eventType: Int
    var cycle: Int
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var period: Int
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
    static func syncTime(timeZone: Int, utc: UInt32) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.syncTime.rawValue,
            0x01,
            0x00,
            0x06,
            0x01,
            UInt8(timeZone),
            UInt8(utc & 0xFF),
            UInt8((utc >> 8) & 0xFF),
            UInt8((utc >> 16) & 0xFF),
            UInt8((utc >> 24) & 0xFF)
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    // 获取电池电量
    static func getBatteryLevel() {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.getBatteryLevel.rawValue,
            0x01,
            0x00,
            0x01,
            0x00
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    // 设置屏幕亮度
    static func setScreenBrightness(brightnessValue: Int){
        let command = createCommand(with: [
            0x00,
            XGZTCommands.setScreenBrightness.rawValue,
            0x01,
            0x00,
            0x01,
            UInt8(brightnessValue)
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    // 获取设备语言
    static func getDeviceLanguage(language: Int) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.getDeviceLanguage.rawValue,
            0x01,
            0x00,
            0x02,
            0x01,
            UInt8(language)
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    static func getDeviceUnitFormat() {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.setDeviceUnitFormat.rawValue,
            0x01,
            0x00,
            0x01,
            0x00
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    // 设置设备单位格式
    static func setDeviceUnitFormat(unitType: Int) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.setDeviceUnitFormat.rawValue,
            0x01,
            0x00,
            0x02,
            0x01,
            UInt8(unitType)
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    // 重置设备为出厂设置
    static func resetToFactorySettings() {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.resetToFactorySettings.rawValue,
            0x01,
            0x00,
            0x01,
            0x00
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    // 设置设备亮屏时间
    static func setDeviceScreenTimeout(screenTimeout: Int) {
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
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    // 设置勿扰功能
    static func setDoNotDisturb(startHour: Int, startMinute: Int, endHour: Int, endMinute: Int) {
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
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    // 查找手环
    static func findBand(p0: Int){
        let command = createCommand(with: [
            0x00,
            XGZTCommands.findBand.rawValue,
            0x01,
            0x00,
            0x01,
            UInt8(p0)
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    // 查找手机
    static func findPhone() {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.findPhone.rawValue,
            0x01,
            0x00,
            0x01,
            0x00
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    static func disconnectBT() {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.disconnectBT.rawValue,
            0x01,
            0x00,
            0x01,
            0x01
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    // 设置天气单位
    static func setWeatherUnit(unit: Int) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.setWeatherUnit.rawValue,
            0x01,
            0x00,
            0x02,
            0x01,
            UInt8(unit)
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    // 12小时/24小时时间制
    static func get12H24HTimeFormat() {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.set12H24HTimeFormat.rawValue,
            0x01,
            0x00,
            0x01,
            0x00
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    // 设置12小时/24小时时间制
    static func set12H24HTimeFormat(format: Int) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.set12H24HTimeFormat.rawValue,
            0x01,
            0x00,
            0x02,
            0x01,
            UInt8(format)
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    // 获取设备信息
    static func getDeviceInfo() {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.getDeviceInfo.rawValue,
            0x01,
            0x00,
            0x02,
            0x00,
            0x09
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    // 设置应用端信息
    static func setAppInfo(phoneType: Int) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.setAppInfo.rawValue,
            0x01,
            0x00,
            0x03,
            0x01,
            0x00,
            UInt8(phoneType)
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    // 获取个人信息
    static func getPersonalInfo() {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.personalInfo.rawValue,
            0x01,
            0x00,
            0x01,
            0x00
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    // 设置个人信息
    static func setPersonalInfo(sex: Int, age: Int, height: Int, weight: Int) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.personalInfo.rawValue,
            0x01,
            0x00,
            0x05,
            0x01,
            UInt8(sex),
            UInt8(age),
            UInt8(height),
            UInt8(weight)
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    // 获取开关状态
    static func getSwitchStatus() {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.switchStatus.rawValue,
            0x01,
            0x00,
            0x01,
            0x00
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    // 设置开关状态
    static func setSwitchStatus(p0: UInt8, p1: UInt8) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.switchStatus.rawValue,
            0x01,
            0x00,
            0x05,
            0x01,
            p0,
            p1,
            0x00,
            0x00
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    // 绑定设备
    static func bindDevice(value: UInt8) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.bindDevice.rawValue,
            0x01,
            0x00,
            0x02,
            0x01,
            value
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    // 获取闹钟信息
    static func getAlarmInfo(type: Int) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.alarmInfo.rawValue,
            0x01,
            0x00,
            0x02,
            0x00,
            UInt8(type)
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    // 设置闹钟信息
    static func setAlarmInfo(setCmd: Int, alarm: AlarmData) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.alarmInfo.rawValue,
            0x01,
            0x00,
            0x09,
            0x01,
            UInt8(setCmd),
            UInt8(alarm.alarmIndex),
            UInt8(alarm.mswitch),
            UInt8(alarm.alarmCycle),
            UInt8(alarm.alarmHour),
            UInt8(alarm.alarmMinute),
            UInt8(alarm.vibrationMode),
            UInt8(alarm.remindLater)
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    // 获取提醒信息
    static func getReminderInfo(eventType: Int) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.reminderInfo.rawValue,
            0x01,
            0x00,
            0x02,
            0x00,
            UInt8(eventType)
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    // 设置提醒信息
    static func setReminderInfo(response: ReminderInfoResponse) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.reminderInfo.rawValue,
            0x01,
            0x00,
            0x08,
            0x01,
            UInt8(response.eventType),
            UInt8(response.cycle),
            UInt8(response.startHour),
            UInt8(response.startMinute),
            UInt8(response.endHour),
            UInt8(response.endMinute),
            UInt8(response.period)
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    // 获取开关表扩展
    static func getSwitchTableExtension() {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.switchTableExtension.rawValue,
            0x01,
            0x00,
            0x02,
            0x00,
            0x00
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    // 设置开关表扩展
    static func setSwitchTableExtension(p0: UInt8, p1: UInt8, p2: UInt8, p3: UInt8) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.switchTableExtension.rawValue,
            0x01,
            0x00,
            0x06,
            0x01,
            0x00,
            p0,
            p1,
            p2,
            p3
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    // 音乐控制（此处仅为示例，根据实际需求完善）
    static func musicControl(action: Int, dataType: Int) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.musicControl.rawValue,
            0x01,
            0x00,
            0x02,
            UInt8(action),
            UInt8(dataType)
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    // 远程拍照
    static func remotePhoto(action: Int) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.remotePhoto.rawValue,
            0x01,
            0x00,
            0x02,
            0x01,
            UInt8(action)
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    // 消息推送（此处仅为示例，根据实际需求完善）
    static func messagePush(action: Int, control: Int, messageType: Int, messageContent: Data) {
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
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    // 设置天气信息（此处仅为示例，根据实际需求完善）
    static func setWeatherInfo(dateType: Int, weatherType: Int, currTemp: Int, lTemp: Int, hTemp: Int, cmd: Int) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.setWeatherInfo.rawValue,
            0x01,
            0x00,
            UInt8(14),
            UInt8(cmd),
            UInt8(dateType),
            0x00,
            0x01,
            UInt8(weatherType),
            0x01,
            0x01,
            UInt8(currTemp),
            0x02,
            0x01,
            UInt8(lTemp),
            0x03,
            0x01,
            UInt8(hTemp)
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    // 获取联系人信息
    static func getContactInfo() {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.contactInfo.rawValue,
            0x01,
            0x00,
            0x02,
            0x01,
            0x03
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    // 设置联系人信息
    static func setContactInfo(index: Int, name: String, phoneNumber: String) {
        // 限制name不超过30个字节
        let truncatedName = truncateStringToByteLength(name, maxBytes: 30)
        let nameData = truncatedName.data(using:.utf8)!
        var phoneNumber = phoneNumber
        // 先去除点号和空格
        phoneNumber = phoneNumber.replacingOccurrences(of: ".", with: "")
        phoneNumber = phoneNumber.replacingOccurrences(of: "-", with: "")
        phoneNumber = phoneNumber.replacingOccurrences(of: "(", with: "")
        phoneNumber = phoneNumber.replacingOccurrences(of: ")", with: "")
        phoneNumber = phoneNumber.replacingOccurrences(of: "（", with: "")
        phoneNumber = phoneNumber.replacingOccurrences(of: "）", with: "")
        phoneNumber = phoneNumber.replacingOccurrences(of: " ", with: "")
        let phoneNumberData = phoneNumberToBytes(phoneNumber)
        var command = createCommand(with: [
            0x00,
            XGZTCommands.contactInfo.rawValue,
            0x01,
            0x00,
            UInt8(5 + nameData.count + phoneNumberData.count),
            0x01,
            0x00,
            UInt8(index),
            UInt8(nameData.count),
        ])
        command.append(contentsOf: [UInt8](nameData))
        command.append(UInt8(phoneNumber.count))
        command.append(contentsOf: [UInt8](phoneNumberData))
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }

    // 辅助方法：截断字符串到指定字节数，避免截断多字节字符
    private static func truncateStringToByteLength(_ string: String, maxBytes: Int) -> String {
        guard let data = string.data(using: .utf8) else {
            return string
        }

        // 如果已经小于等于最大字节数，直接返回
        if data.count <= maxBytes {
            return string
        }

        // 截取前maxBytes字节
        // 尝试从截断的数据创建字符串
        // 如果最后一个字符被截断，String初始化会失败，我们需要继续减少字节直到成功
        var currentLength = maxBytes
        while currentLength > 0 {
            let subData = data.prefix(currentLength)
            if let truncatedString = String(data: subData, encoding: .utf8) {
                return truncatedString
            }
            currentLength -= 1
        }

        return ""
    }
    
    // 来电静音
    static func incomingCallMute(mute: Int) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.incomingCallMute.rawValue,
            0x01,
            0x00,
            0x02,
            UInt8(mute)
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    // 获取目标设置
    static func getTargetSettings() {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.targetSettings.rawValue,
            0x01,
            0x00,
            0x01,
            0x00
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    static func getNewestHealthData(type: Int) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.getNewestHealthData.rawValue,
            0x01,
            0x00,
            0x02,
            0x00,
            UInt8(type)
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    static func getStepData() {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.getStepData.rawValue,
            0x01,
            0x00,
            0x01,
            0x01
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    // 设置目标设置
    static func setTargetSettings(targetSwitch: Int, targetType: Int, targetLength: Int) {
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
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    static func setQRCode(type: UInt8, qrString: String) {
        if let commandData = QRCodeSetCommand.buildCommand(type: type, qrString: qrString) {
            print("构建的指令数据：\(commandData)")
            XGZTBlueToothManager.shared.writeCharacteristic(command: commandData.bytes)
        } else {
            print("构建指令失败")
        }
        
    }
    
    // 获取多运动模式数据
    static func getMultiSportModeData() {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.multiSportModeData.rawValue,
            0x01,
            0x00,
            0x01,
            0x00
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    // 删除运动模式数据
    static func deleteSportModeData() {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.multiSportModeData.rawValue,
            0x01,
            0x00,
            0x01,
            0x01
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    // 获取睡眠数据
    static func getHistorySleepData() {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.getHistorySleepData.rawValue,
            0x01,
            0x00,
            0x01,
            0x01
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    static func getSleepMonitoring() {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.getSleepMonitoring.rawValue,
            0x01,
            0x00,
            0x01,
            0x01
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    // 设置自动睡眠监测
    static func setAutoSleepMonitoring(startHour: Int, startMinute: Int, endHour: Int, endMinute: Int, alarmCycle: Int) {
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
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    // 表盘市场相关操作（此处仅为示例，根据实际需求完善）
    static func dialMarketQuery(dataType: Int) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.dialMarket.rawValue,
            0x01,
            0x00,
            0x02,
            0x00,
            UInt8(dataType)
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    static func dialMarketSetTransferConfig(packageTotal: Int, binSize: Int, mtu: Int, dialType: Int, dialNum: Int, local: Int, typeValue: Int,  dialTypeValue: Int) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.dialMarket.rawValue,
            0x01,
            0x00,
            0x10,
            0x01,
            UInt8(packageTotal & 0xFF),
            UInt8((packageTotal >> 8) & 0xFF),
            UInt8(binSize & 0xFF),
            UInt8((binSize >> 8) & 0xFF),
            UInt8((binSize >> 16) & 0xFF),
            UInt8((binSize >> 24) & 0xFF),
            UInt8(mtu & 0xFF),
            UInt8((mtu >> 8) & 0xFF),
            UInt8(dialType),
            UInt8(dialNum),
            UInt8(local),
            UInt8(typeValue),
            UInt8((dialTypeValue >> 16) & 0xFF),
            UInt8((dialTypeValue >> 8) & 0xFF),
            UInt8(dialTypeValue & 0xFF)
            
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    static func dialMarketTransferData(packageNum: Int, binNum: Int, progressBar: Int, control: Int, data: Data) {
        // Create an array to hold the command data
        var commandData: [UInt8] = [
            0x00,
            XGZTCommands.dialMarket.rawValue,
            0x01,
            0x00,
            UInt8(11 + data.count),
            0x02,
            UInt8(packageNum & 0xFF),
            UInt8((packageNum >> 8) & 0xFF),
            UInt8(binNum & 0xFF),
            UInt8((binNum >> 8) & 0xFF),
            UInt8((binNum >> 16) & 0xFF),
            UInt8((binNum >> 24) & 0xFF),
            UInt8(progressBar),
            UInt8(control)
        ]
        
        // Calculate the checkCode as the sum of all bytes in the command data
        let checkCode = commandData.reduce(0, { $0 + Int($1) }) + data.reduce(0, { $0 + Int($1) })
        
        // Append the checkCode to the command data array
        commandData.append(UInt8(checkCode & 0xFF))
        commandData.append(UInt8((checkCode >> 8) & 0xFF))
        
        // Append the data to the command data array
        commandData.append(contentsOf: [UInt8](data))
        
        // Write the command data to the Bluetooth characteristic
        XGZTBlueToothManager.shared.writeCharacteristic(command: commandData)
    }
    
    // 资源升级相关操作（此处仅为示例，根据实际需求完善）
    static func resourceUpgradeQuery() {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.resourceUpgrade.rawValue,
            0x01,
            0x00,
            0x02,
            0x00
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    static func resourceUpgradeSetTransferConfig(packageTotal: Int, binSize: Int, mtu: Int) {
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
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    static func resourceUpgradeTransferData(data: Data) {
        var command = createCommand(with: [
            0x00,
            XGZTCommands.resourceUpgrade.rawValue,
            0x01,
            0x00,
            UInt8(6 + data.count),
            0x02
        ])
        command.append(contentsOf: [UInt8](data))
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    static func startTest(cmdType: Int, control: Int) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.startTest.rawValue,
            0x01,
            0x00,
            0x03,
            0x01,
            UInt8(cmdType),
            UInt8(control)
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    static func setTimePositionAndColor(type: Int, position: Int, color: Int) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.setTimePositionAndColor.rawValue,
            0x01,
            0x00,
            0x06,
            0x01,
            UInt8(type),
            UInt8(position),
            UInt8((color >> 16) & 0xFF),
            UInt8((color >> 8) & 0xFF),
            UInt8(color & 0xFF)
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    static func getNewestHeartData(type: Int) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.getNewestHeartData.rawValue,
            0x01,
            0x00,
            0x01,
            UInt8(type)
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    // 辅助方法：从字节数组中获取整数
    private static func getIntFromBytes(_ bytes: [UInt8], _ offset: Int = 0) -> Int {
        return Int(bytes[offset + 3]) << 24 | Int(bytes[offset + 2]) << 16 | Int(bytes[offset + 1]) << 8 | Int(bytes[offset])
    }
    
    // 辅助方法：从字节数组中获取字符串
    private static func getStringFromBytes(_ bytes: [UInt8], _ startIndex: Int, _ length: Int) -> String {
        let subArray = bytes[startIndex..<startIndex+length]
        let data = Data(subArray)
        return String(data: data, encoding:.utf8) ?? ""
    }
    
    // 辅助方法：从字节数组中获取短整数
    private static func getShortFromBytes(_ bytes: [UInt8], _ offset: Int = 0) -> Int {
        return Int(bytes[offset + 1]) << 8 | Int(bytes[offset])
    }
    
    // 辅助方法：从字节数组中获取无符号 32 位整数
    private static func getUInt32FromBytes(_ bytes: [UInt8], _ offset: Int = 0) -> UInt32 {
        return UInt32(bytes[offset + 3]) << 24 | UInt32(bytes[offset + 2]) << 16 | UInt32(bytes[offset + 1]) << 8 | UInt32(bytes[offset])
    }
    
    // 辅助方法：将电话号码转换为字节数组（根据协议规则）
    private static func phoneNumberToBytes(_ phoneNumber: String) -> [UInt8] {
        var phoneNumber = phoneNumber
        if phoneNumber.count % 2 != 0 {
            phoneNumber = phoneNumber + "f"
        }
        phoneNumber = phoneNumber.replacingOccurrences(of: "+", with: "a")
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
    
    // 统一处理指令响应的方法，优化为从响应数据中解析指令标识来判断情况
    public static func handleResponse(response: [UInt8]) {
        if response.count < 2 {
            return
        }
        let commandRawValue = response[1]
        guard let command = XGZTCommands(rawValue: commandRawValue) else {
            XLogger.shared.log("Unhandled command response")
            return
        }
        switch command {
        case.syncTime:
            guard response.count >= 7 else {
                XLogger.shared.log("syncTime command response error")
                return
            }
            let success = response[6] == 0x00
            if success {
                XLogger.shared.log("时间同步成功")
            } else {
                XLogger.shared.log("时间同步失败")
            }
            if sync_time_single { // 如果是因为时区变化同步时间，则不需要往下走
                sync_time_single = false
                return
            }
            NotificationCenter.default.post(name: Notification.Name("XGZTBusinessHandler"), object: "3")
        case.getBatteryLevel:
            guard response.count >= 7 else {
                XLogger.shared.log("getBatteryLevel command response error")
                return
            }
            let batteryLevel = Int(response[6] & 0x7F)
            let isCharging = (response[6] & 0x80) != 0
            XLogger.shared.log("Battery level: \(batteryLevel), Is charging: \(isCharging)")
        case.setScreenBrightness:
            guard response.count >= 6 else {
                XLogger.shared.log("setScreenBrightness command response error")
                return
            }
            let success = response[5] == 0x00
            if success {
                XLogger.shared.log("设置屏幕亮度命令执行成功")
            } else {
                XLogger.shared.log("设置屏幕亮度命令执行失败")
            }
        case.getDeviceLanguage:
            guard response.count >= 7 else {
                XLogger.shared.log("getDeviceLanguage command response error")
                return
            }
            let languageType = Int(response[6])
            XLogger.shared.log("设备语言类型: \(languageType)")
            NotificationCenter.default.post(name: Notification.Name("XGZTBusinessHandler"), object: "18")
        case.qrCode:
            guard response.count >= 7 else {
                XLogger.shared.log("getDeviceLanguage command response error")
                return
            }
            let languageType = Int(response[6])
            XLogger.shared.log("二维码设置结果: \(languageType)")
            NotificationCenter.default.post(name: Notification.Name("QRBindViewController"), object: "\(languageType)")
        case.setDeviceUnitFormat:
            guard response.count >= 7 else {
                XLogger.shared.log("setDeviceUnitFormat command response error")
                return
            }
            if response[5] == 0x00 {
                XGZTBlueToothManager.shared.device?.baseUnit = Int(response[6])
                NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "step")
                NotificationCenter.default.post(name: Notification.Name("XGZTBusinessHandler"), object: "16")
            } else {
                let success = response[6] == 0x00
                if success {
                    XLogger.shared.log("设置设备单位格式命令执行成功")
                    NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "step")
                } else {
                    XLogger.shared.log("设置设备单位格式命令执行失败")
                }
            }
            
        case.resetToFactorySettings:
            guard response.count >= 6 else {
                XLogger.shared.log("resetToFactorySettings command response error")
                return
            }
            let success = response[5] == 0x00
            if success {
                XLogger.shared.log("重置设备为出厂设置命令执行成功")
            } else {
                XLogger.shared.log("重置设备为出厂设置命令执行失败")
            }
        case.setDeviceScreenTimeout:
            guard response.count >= 6 else {
                XLogger.shared.log("setDeviceScreenTimeout command response error")
                return
            }
            let success = response[5] == 0x00
            if success {
                XLogger.shared.log("设置设备亮屏时间命令执行成功")
            } else {
                XLogger.shared.log("设置设备亮屏时间命令执行失败")
            }
        case.setDoNotDisturb:
            guard response.count >= 6 else {
                XLogger.shared.log("setDoNotDisturb command response error")
                return
            }
            let success = response[5] == 0x00
            if success {
                XLogger.shared.log("设置勿扰功能命令执行成功")
            } else {
                XLogger.shared.log("设置勿扰功能命令执行失败")
            }
        case.findBand:
            guard response.count >= 7 else {
            XLogger.shared.log("findBand command response error")
            return
            }
            let success = response[6] == 0x00
            if success {
                XLogger.shared.log("查找手环命令执行成功")
            } else {
                XLogger.shared.log("查找手环命令执行失败")
            }
        case.findPhone:
            guard response.count >= 6 else {
                XLogger.shared.log("findPhone command response error")
                return
            }
            if response[5] == 0x00 {
                XLogger.shared.log("开始查找手机")
                DispatchQueue.main.async {
                    (UIApplication.shared.delegate as? AppDelegate)?.foundphone()
                }
            } else {
                XLogger.shared.log("结束查找手机")
            }
        case.setWeatherUnit:
            guard response.count >= 7 else {
                XLogger.shared.log("setWeatherUnit command response error")
                return
            }
            let success = response[6] == 0x00
            if success {
                XLogger.shared.log("设置天气单位命令执行成功")
            } else {
                XLogger.shared.log("设置天气单位命令执行失败")
            }
        case.set12H24HTimeFormat:
            guard response.count >= 7 else {
                XLogger.shared.log("set12H24HTimeFormat command response error")
                return
            }
            if response[5] == 0 {
                XGZTBlueToothManager.shared.device?.timeUnit = Int(response[6])
                NotificationCenter.default.post(name: Notification.Name("XGZTBusinessHandler"), object: "15")
            } else {
                let success = response[6] == 0x00
                if success {
                    XLogger.shared.log("设置12小时/24小时时间制命令执行成功")
                } else {
                    XLogger.shared.log("设置12小时/24小时时间制命令执行失败")
                }
            }
        case.getDeviceInfo:
            if response.count == 13 {
                let range = 7..<13 // Convert ClosedRange to Range by adding 1 to the upper bound
                let macAddressData = response[range]
                let macAddress = macAddressData.map { String(format: "%02x", $0) }.joined(separator: ":").uppercased()
                XLogger.shared.log("macAddress: \(macAddress)")
                if !MACAddressComparator.isMatching(lastestDeviceMac, macAddress) {
                    lastestDeviceMac = macAddress
                }
                return
            }
            if response.count >= 21 && response.count < 30 {
                let range = 15..<21 // Convert ClosedRange to Range by adding 1 to the upper bound
                let macAddressData = response[range]
                let macAddress = macAddressData.map { String(format: "%02x", $0) }.joined(separator: ":").uppercased()
                XLogger.shared.log("macAddress: \(macAddress)")
                if !MACAddressComparator.isMatching(lastestDeviceMac, macAddress) {
                    lastestDeviceMac = macAddress
                }
                return
            }
            if response.count == 41 {
                XGZTBlueToothManager.shared.device?.screenType = Int(response[5])
                XGZTBlueToothManager.shared.device?.hardwareVersion = Int(response[30])
                XGZTBlueToothManager.shared.device?.firmwareVersion = "\(Int(response[35])).\(Int(response[32]))"
                XGZTBlueToothManager.shared.device?.deviceID = (Int(response[34]) << 8) | Int(response[33])
                XGZTBlueToothManager.shared.device?.deviceModel = (Int(response[36]) << 8) | Int(response[35])
                XGZTBlueToothManager.shared.device?.screenWidth = (Int(response[38]) << 8) | Int(response[37])
                XGZTBlueToothManager.shared.device?.screenHeight = (Int(response[40]) << 8) | Int(response[39])
                XGZTBlueToothManager.shared.device?.functioncontrolflags = getIntFromBytes(response, 10)
                XGZTBlueToothManager.shared.device?.healthcontrolflags = getIntFromBytes(response, 14)
                NotificationCenter.default.post(name: Notification.Name("DevicesViewController"), object: "1999")
                XLogger.shared.log("functioncontrolflags: \(XGZTBlueToothManager.shared.device?.functioncontrolflags ?? 0)")
                XLogger.shared.log("firmwareVersion: \(XGZTBlueToothManager.shared.device?.firmwareVersion ?? "")")
            }
            guard response.count >= 45 else {
                XLogger.shared.log("getDeviceInfo command response error")
                return
            }
            XGZTBlueToothManager.shared.device?.screenType = Int(response[5])
            XGZTBlueToothManager.shared.device?.hardwareVersion = Int(response[34])
            XGZTBlueToothManager.shared.device?.firmwareVersion = "\(Int(response[35])).\(Int(response[36]))"
            XGZTBlueToothManager.shared.device?.deviceID = (Int(response[38]) << 8) | Int(response[37])
            XGZTBlueToothManager.shared.device?.deviceModel = (Int(response[40]) << 8) | Int(response[39])
            XGZTBlueToothManager.shared.device?.screenWidth = (Int(response[42]) << 8) | Int(response[41])
            XGZTBlueToothManager.shared.device?.screenHeight = (Int(response[44]) << 8) | Int(response[43])
            XGZTBlueToothManager.shared.device?.functioncontrolflags = getIntFromBytes(response, 14)
            XGZTBlueToothManager.shared.device?.healthcontrolflags = getIntFromBytes(response, 18)
            NotificationCenter.default.post(name: Notification.Name("DevicesViewController"), object: "1999")
            XLogger.shared.log("functioncontrolflags: \(XGZTBlueToothManager.shared.device?.functioncontrolflags ?? 0)")
            XLogger.shared.log("firmwareVersion: \(XGZTBlueToothManager.shared.device?.firmwareVersion ?? "")")
        case.setAppInfo:
            guard response.count >= 7 else {
                XLogger.shared.log("setAppInfo command response error")
                return
            }
            let success = response[6] == 0x00
            if success {
                XLogger.shared.log("设置应用端信息命令执行成功")
            } else {
                XLogger.shared.log("设置应用端信息命令执行失败")
            }
            flag_5d = false
            NotificationCenter.default.post(name: Notification.Name("XGZTBusinessHandler"), object: "2")
        case.personalInfo:
            if response.count == 7 {
                let success = response[6] == 0x00
                if success {
                    XLogger.shared.log("设置用户信息执行成功")
                } else {
                    XLogger.shared.log("设置用户信息执行失败")
                }
                return
            }
            guard response.count >= 9 else {
                XLogger.shared.log("personalInfo command response error")
                return
            }
            if response[2] == 3 {
                XGZTBlueToothManager.shared.device?.sex = Int(response[5])
                XGZTBlueToothManager.shared.device?.age = Int(response[6])
                XGZTBlueToothManager.shared.device?.height = Int(response[7])
                XGZTBlueToothManager.shared.device?.weight = Int(response[8])
                NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "head")
            }
        case.switchStatus:
            guard response.count >= 7 else {
                XLogger.shared.log("switchStatus command response error")
                return
            }
            if response.count >= 10 {
                XGZTBlueToothManager.shared.device?.isAntilostSwitch = (response[6] & 1) > 0
                XGZTBlueToothManager.shared.device?.isRaisehandtobrightenscreen = ((response[6] >> 1) & 1) > 0
                XGZTBlueToothManager.shared.device?.isAntilostSwitch = ((response[6] >> 2) & 1) > 0
                
                XGZTBlueToothManager.shared.device?.isSleepmonitoringSwitch = ((response[6] >> 4) & 1) > 0
                XGZTBlueToothManager.shared.device?.isMessageremindermainswitch = ((response[6] >> 5) & 1) > 0
                XGZTBlueToothManager.shared.device?.isRegularexercisedatauploadswitch = ((response[6] >> 6) & 1) > 0
                XGZTBlueToothManager.shared.device?.isGoalachievementswitch = ((response[6] >> 7) & 1) > 0
                
                XGZTBlueToothManager.shared.device?.isMessagescreendisplayswitch = ((response[7] >> 1) & 1) > 0
                XGZTBlueToothManager.shared.device?.isSoundswitch = ((response[7] >> 2) & 1) > 0
                XGZTBlueToothManager.shared.device?.isVibrationswitch = ((response[7] >> 3) & 1) > 0
                XGZTBlueToothManager.shared.device?.isRegularhealthdatauploadswitch = ((response[7] >> 4) & 1) > 0
                XGZTBlueToothManager.shared.device?.isMessagevibrationswitch = ((response[7] >> 5) & 1) > 0
                
                if response[2] == 3 {
                    NotificationCenter.default.post(name: Notification.Name("DeviceSettings"), object: 1)
                } else {
                    NotificationCenter.default.post(name: Notification.Name("XGZTBusinessHandler"), object: "11")
                }
            } else {
                let success = response[6] == 0x00
                if success {
                    XLogger.shared.log("设置开关执行成功")
                } else {
                    XLogger.shared.log("设置开关执行失败")
                }
            }
        case.bindDevice:
            guard response.count >= 8 else {
                XLogger.shared.log("bindDevice command response error")
                return
            }
            let control = response[6]
            if control == 0 {
                let success = response[7]
                if success == 0 {
                    XLogger.shared.log("绑定开始结束命令未被绑定过")
                } else if success == 1 {
                    XLogger.shared.log("绑定开始结束命令已被绑定过")
                }
                if !flag_81 {
                    return
                }
                flag_81 = false
                NotificationCenter.default.post(name: Notification.Name("XGZTBusinessHandler"), object: "17")
            } else if control == 1 {
                let success = response[7]
                if success == 0 {
                    XLogger.shared.log("绑定数据结束命令绑定未完成")
                } else if success == 1 {
                    XLogger.shared.log("绑定数据结束命令执行完成")
                }
                flag_82 = false
                NotificationCenter.default.post(name: Notification.Name("XGZTBusinessHandler"), object: "1")
            } else if control == 2 {
                let success = response[7]
                if success == 0 {
                    XLogger.shared.log("断开绑定命令执行成功")
                } else if success == 1 {
                    XLogger.shared.log("断开绑定命令执行未绑定")
                } else {
                    XLogger.shared.log("断开绑定命令执行失败")
                }
            }
            
        case.alarmInfo:
            guard response.count >= 7 else {
                XLogger.shared.log("alarmInfo command response error")
                return
            }
            if response.count == 8 && response[5] == 0x00 && response[6] == 0x00 {
                XGZTBlueToothManager.shared.device?.alarmcount = Int(response[6])
                return
            }
            if response.count == 8 && response[5] == 0x00 && response[6] == 0x02 {
                XGZTBlueToothManager.shared.device?.alarmCanUse = Int(response[7])
                return
            }
            if response.count == 8 && response[5] == 0x01 && response[7] == 0x00 {
                XGZTCommand.getAlarmInfo(type: 1)
                XGZTCommand.getAlarmInfo(type: 2)
                return
            }
            if response.count == 7 && response[5] == 0x01 && response[6] == 0x00 {
                XGZTCommand.getAlarmInfo(type: 1)
                XGZTCommand.getAlarmInfo(type: 2)
                return
            }
            if response.count == 14 {
                let index = Int(response[7])
                let switchValue = Int(response[8])
                let cycle = Int(response[9])
                let hour = Int(response[10])
                let minute = Int(response[11])
                let vibration = Int(response[12])
                let later = Int(response[13])
                let alarm = AlarmData(alarmIndex: index, mswitch: switchValue, alarmCycle: cycle, alarmHour: hour, alarmMinute: minute, vibrationMode: vibration, remindLater: later)
                if XGZTBlueToothManager.shared.device?.alarms.count ?? 0 > 0 {
                    var b = false
                    for (key, item) in XGZTBlueToothManager.shared.device!.alarms.enumerated() {
                        if item.alarmIndex == index {
                            b = true
                            XGZTBlueToothManager.shared.device?.alarms[key] = alarm
                            break
                        }
                    }
                    if b == false {
                        XGZTBlueToothManager.shared.device?.alarms.append(alarm)
                    }
                } else {
                    XGZTBlueToothManager.shared.device?.alarms.append(alarm)
                }
                DispatchQueue.main.async { // 返回主线程刷新
                    NotificationCenter.default.post(name: Notification.Name.Alarm, object: nil)
                }
            }
        case.reminderInfo:
            if response.count == 7 {
                if response[6] == 0 {
                    XLogger.shared.log("提醒协议设置成功")
                }
                return
            }
            guard response.count >= 12 else {
                XLogger.shared.log("reminderInfo command response error")
                return
            }
            let eventType = Int(response[6])
            let cycle = Int(response[7])
            let startHour = Int(response[8])
            let startMinute = Int(response[9])
            let endHour = Int(response[10])
            let endMinute = Int(response[11])
            let period = Int(response[12])
            if eventType == 0 {
                XGZTBlueToothManager.shared.device?.longsit = ReminderInfoResponse(eventType: eventType, cycle: cycle, startHour: startHour, startMinute: startMinute, endHour: endHour, endMinute: endMinute, period: period)
                NotificationCenter.default.post(name: Notification.Name("XGZTBusinessHandler"), object: "13")
            } else if eventType == 1 {
                XGZTBlueToothManager.shared.device?.drinkWater = ReminderInfoResponse(eventType: eventType, cycle: cycle, startHour: startHour, startMinute: startMinute, endHour: endHour, endMinute: endMinute, period: period)
                NotificationCenter.default.post(name: Notification.Name("XGZTBusinessHandler"), object: "14")
                NotificationCenter.default.post(name: Notification.Name("DeviceSettings"), object: 1)
            }
        case.switchTableExtension:
            guard response.count >= 7 else {
                XLogger.shared.log("switchTableExtension command response error")
                return
            }
            if response.count >= 11 {
                XGZTBlueToothManager.shared.device?.isNullMessage = (response[7] & 1) > 0
                XGZTBlueToothManager.shared.device?.isIncomingCall = ((response[7] >> 1) & 1) > 0
                XGZTBlueToothManager.shared.device?.isMissedCall = ((response[7] >> 2) & 1) > 0
                XGZTBlueToothManager.shared.device?.isMessages = ((response[7] >> 3) & 1) > 0
                XGZTBlueToothManager.shared.device?.isEmail = ((response[7] >> 4) & 1) > 0
                XGZTBlueToothManager.shared.device?.isSchedule = ((response[7] >> 5) & 1) > 0
                XGZTBlueToothManager.shared.device?.isFacetime = ((response[7] >> 6) & 1) > 0
                XGZTBlueToothManager.shared.device?.isQQ = ((response[7] >> 7) & 1) > 0
                XGZTBlueToothManager.shared.device?.isSkype = (response[8] & 1) > 0
                XGZTBlueToothManager.shared.device?.isWechat = ((response[8] >> 1) & 1) > 0
                XGZTBlueToothManager.shared.device?.isWhatsapp = ((response[8] >> 2) & 1) > 0
                XGZTBlueToothManager.shared.device?.isGmail = ((response[8] >> 3) & 1) > 0
                XGZTBlueToothManager.shared.device?.isHangout = ((response[8] >> 4) & 1) > 0
                XGZTBlueToothManager.shared.device?.isInbox = ((response[8] >> 5) & 1) > 0
                XGZTBlueToothManager.shared.device?.isLine = ((response[8] >> 6) & 1) > 0
                XGZTBlueToothManager.shared.device?.isTwitter = ((response[8] >> 7) & 1) > 0
                XGZTBlueToothManager.shared.device?.isFacebook = (response[9] & 1) > 0
                XGZTBlueToothManager.shared.device?.isFacebookMessenger = ((response[9] >> 1) & 1) > 0
                XGZTBlueToothManager.shared.device?.isInstagram = ((response[9] >> 2) & 1) > 0
                XGZTBlueToothManager.shared.device?.isWeibo = ((response[9] >> 3) & 1) > 0
                XGZTBlueToothManager.shared.device?.isKakaotalk = ((response[9] >> 4) & 1) > 0
                XGZTBlueToothManager.shared.device?.isFacebookpagemanager = ((response[9] >> 5) & 1) > 0
                XGZTBlueToothManager.shared.device?.isViber = ((response[9] >> 6) & 1) > 0
                XGZTBlueToothManager.shared.device?.isVkclient = ((response[9] >> 7) & 1) > 0
                
                XGZTBlueToothManager.shared.device?.isTelegram = (response[10] & 1) > 0
                XGZTBlueToothManager.shared.device?.isSnapchat = ((response[10] >> 2) & 1) > 0
                XGZTBlueToothManager.shared.device?.isDingTalk = ((response[10] >> 3) & 1) > 0
                XGZTBlueToothManager.shared.device?.isAlipay = ((response[10] >> 4) & 1) > 0
                XGZTBlueToothManager.shared.device?.isTiktok = ((response[10] >> 5) & 1) > 0
                XGZTBlueToothManager.shared.device?.isLinkedIn = ((response[10] >> 6) & 1) > 0
                NotificationCenter.default.post(name: Notification.Name("XGZTBusinessHandler"), object: "12")
            } else {
                let success = response[6] == 0x00
                if success {
                    XLogger.shared.log("设置开关执行成功")
                } else {
                    XLogger.shared.log("设置开关执行失败")
                }
            }
            
        case.musicControl:
            guard response.count >= 6 else {
                XLogger.shared.log("musicControl command response error")
                return
            }
            let success = response[5] == 0x00
            if success {
                XLogger.shared.log("音乐控制命令执行成功")
            } else {
                XLogger.shared.log("音乐控制命令执行失败")
            }
        case.remotePhoto:
            if response.count == 6 {
                if response[5] == 0 {
                    if response[2] == 3 {
                        NotificationCenter.default.post(name: Notification.Name("HealthVCLoading"), object: 10000)
                    } else {
                        NotificationCenter.default.post(name: Notification.Name("DeviceSettings"), object: nil)
                    }
                    
                } else if response[5] == 1 {
                    if response[2] == 3 {
                        NotificationCenter.default.post(name: Notification.Name("HealthVCLoading"), object: 10002)
                    } else {
                        NotificationCenter.default.post(name: Notification.Name("DeviceSettings"), object: 3)
                    }
                } else if response[5] == 2 {
                    if response[2] == 3 {
                        NotificationCenter.default.post(name: Notification.Name("HealthVCLoading"), object: 10001)
                    } else {
                        NotificationCenter.default.post(name: Notification.Name("DeviceSettings"), object: 2)
                    }
                    
                }
                return
            }
            guard response.count >= 7 else {
                XLogger.shared.log("remotePhoto command response error")
                return
            }
            let success = response[6] == 0x00
            if success {
                XLogger.shared.log("远程拍照命令执行成功")
            } else {
                XLogger.shared.log("远程拍照命令执行失败")
            }
        case.messagePush:
            guard response.count >= 6 else {
                XLogger.shared.log("messagePush command response error")
                return
            }
            let success = response[5] == 0x00
            if success {
                XLogger.shared.log("消息推送命令执行成功")
            } else {
                XLogger.shared.log("消息推送命令执行失败")
            }
        case.setWeatherInfo:
            guard response.count >= 7 else {
                XLogger.shared.log("setWeatherInfo command response error")
                return
            }
            let success = response[6] == 0x00
            if success {
                XLogger.shared.log("设置天气信息命令执行成功")
            } else {
                XLogger.shared.log("设置天气信息命令执行失败")
            }
        case.contactInfo:
            guard response.count >= 7 else {
                XLogger.shared.log("contactInfo command response error")
                return
            }
            let result = Int(response[6])
            XLogger.shared.log("设置联系人：\(result)")
            NotificationCenter.default.post(name: Notification.Name("SyncContactsViewController"), object: "\(result)")
        case.incomingCallMute:
            guard response.count >= 6 else {
                XLogger.shared.log("incomingCallMute command response error")
                return
            }
            let success = response[5] == 0x00
            if success {
                XLogger.shared.log("来电静音命令执行成功")
            } else {
                XLogger.shared.log("来电静音命令执行失败")
            }
        case.targetSettings:
            guard response.count >= 16 else {
                XLogger.shared.log("targetSettings command response error")
                return
            }
            let targetSwitch = getShortFromBytes(response, 6)
            let stepTargetValue = Int(response[8])
            let distanceTargetValue = Int(response[9])
            let calorieTargetValue = getShortFromBytes(response, 10)
            let sleepTargetValue = getShortFromBytes(response, 12)
            let exerciseDurationTargetValue = getShortFromBytes(response, 14)
            XLogger.shared.log("目标设置开关: \(targetSwitch)")
            XLogger.shared.log("步数目标值: \(stepTargetValue)")
            XLogger.shared.log("距离目标值: \(distanceTargetValue)")
            XLogger.shared.log("卡路里目标值: \(calorieTargetValue)")
            XLogger.shared.log("睡眠目标值: \(sleepTargetValue)")
            XLogger.shared.log("运动时长目标值: \(exerciseDurationTargetValue)")
        case.multiSportModeData:
            guard response.count >= 8 else {
                XLogger.shared.log("multiSportModeData command response error")
                return
            }
            let numData = getShortFromBytes(response, 6)
            var sportDataList: [MultiSportModeData] = []
            var offset = 8
            for _ in 0..<numData {
                let sportType = Int(response[offset])
                offset += 1
                let timestamp = getUInt32FromBytes(response, offset)
                offset += 4
                let stepCount = getUInt32FromBytes(response, offset)
                offset += 4
                let calorie = getUInt32FromBytes(response, offset)
                offset += 4
                let distance = getUInt32FromBytes(response, offset)
                offset += 4
                let duration = getUInt32FromBytes(response, offset)
                offset += 4
                let avgHeartRate = Int(response[offset])
                offset += 1
                let staticCalorie = getUInt32FromBytes(response, offset)
                offset += 4
                sportDataList.append(MultiSportModeData(sportType: sportType, timestamp: timestamp, stepCount: stepCount, calorie: calorie, distance: distance, duration: duration, avgHeartRate: avgHeartRate, staticCalorie: staticCalorie))
            }
            XLogger.shared.log("多运动模式数据数量: \(numData), 数据详情: \(sportDataList)")
        case.getSleepMonitoring:
            guard response.count >= 12 else {
                XLogger.shared.log("setAutoSleepMonitoring command response error")
                return
            }
            if response[2] == 2 {
                let deep = Int(response[6]) |
                           (Int(response[7]) << 8)
                let light = Int(response[8]) |
                           (Int(response[9]) << 8)
                let awake = Int(response[10]) |
                           (Int(response[11]) << 8)
                XGZTBlueToothManager.shared.device?.currentSleep = light + deep
                XGZTBlueToothManager.shared.device?.currentSleepArray = [awake, light, deep]
                NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "sleep")
            } else if response[2] == 3 {
                let deep = Int(response[5]) |
                           (Int(response[6]) << 8)
                let light = Int(response[7]) |
                           (Int(response[8]) << 8)
                let awake = Int(response[9]) |
                           (Int(response[10]) << 8)
                XGZTBlueToothManager.shared.device?.currentSleep = light + deep
                XGZTBlueToothManager.shared.device?.currentSleepArray = [awake, light, deep]
                NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "sleep")
            }
            NotificationCenter.default.post(name: Notification.Name("XGZTBusinessHandler"), object: "9")
        case.setAutoSleepMonitoring:
            guard response.count >= 12 else {
                XLogger.shared.log("setAutoSleepMonitoring command response error")
                return
            }
            let startHour = Int(response[6])
            let startMinute = Int(response[7])
            let endHour = Int(response[8])
            let endMinute = Int(response[9])
            let alarmCycle = Int(response[10])
            let responseCode = Int(response[11])
            XLogger.shared.log("自动睡眠监测开始时间（小时）: \(startHour)")
            XLogger.shared.log("自动睡眠监测开始时间（分钟）: \(startMinute)")
            XLogger.shared.log("自动睡眠监测结束时间（小时）: \(endHour)")
            XLogger.shared.log("自动睡眠监测结束时间（分钟）: \(endMinute)")
            XLogger.shared.log("自动睡眠监测闹钟周期: \(alarmCycle)")
            XLogger.shared.log("响应码: \(responseCode)")
        case.dialMarket:
            guard response.count >= 7 else {
                XLogger.shared.log("dialMarket command response error")
                return
            }
            let value = response[5]
            if value == 0 {
                if response.count >= 10 {
                    XGZTBlueToothManager.shared.device?.mtu = (Int(response[7]) << 8) | Int(response[8])
                    NotificationCenter.default.post(name: Notification.Name("ClockUseViewController"), object: 4)
                    NotificationCenter.default.post(name: Notification.Name("MyClockViewController"), object: 4)
                }
                if response.count >= 12 {
                    XGZTBlueToothManager.shared.device?.screenType = Int(response[7])
                    XGZTBlueToothManager.shared.device?.screenWidth = (Int(response[8]) << 8) | Int(response[9])
                    XGZTBlueToothManager.shared.device?.screenHeight = (Int(response[10]) << 8) | Int(response[11])
                }
            } else if value == 1 {
                if response[6] == 0 {
                    NotificationCenter.default.post(name: Notification.Name("ClockUseViewController"), object: 5)
                    NotificationCenter.default.post(name: Notification.Name("MyClockViewController"), object: 5)
                }
            } else if value == 2 {
                let control = response[8]
                if control == 0 {
                    NotificationCenter.default.post(name: Notification.Name("ClockUseViewController"), object: 5) // 继续
                    NotificationCenter.default.post(name: Notification.Name("MyClockViewController"), object: 5)
                } else if control == 1 {
                    NotificationCenter.default.post(name: Notification.Name("ClockUseViewController"), object: 6)
                    NotificationCenter.default.post(name: Notification.Name("MyClockViewController"), object: 6)
                } else {
                    
                }
            }
        case.resourceUpgrade:
            guard response.count >= 6 else {
                XLogger.shared.log("resourceUpgrade command response error")
                return
            }
            let success = response[5] == 0x00
            if success {
                XLogger.shared.log("资源升级相关命令执行成功")
            } else {
                XLogger.shared.log("资源升级相关命令执行失败")
            }
        case .unbindDeviceNotif:
            guard response.count >= 6 else {
                XLogger.shared.log("resourceUpgrade command response error")
                return
            }
            let success = response[5] == 0x00
            if success {
                XLogger.shared.log("设备端发送通知成功")
            } else {
                XLogger.shared.log("设备端发送通知失败")
            }
        case .disconnectBT:
            guard response.count >= 7 else {
                XLogger.shared.log("resourceUpgrade command response error")
                return
            }
            let success = response[6] == 0x00
            if success {
                XLogger.shared.log("BT断开执行成功")
                NotificationCenter.default.post(name: Notification.Name("DevicesViewController"), object: "2000")
            } else {
                XLogger.shared.log("BT断开执行失败")
            }
        case .getNewestHealthData:
            guard response.count >= 11 else {
                XLogger.shared.log("resourceUpgrade command response error")
                return
            }
            
            if response.count == 11 {
                XGZTBlueToothManager.shared.device?.currentHeartrate = Int(response[7])
                XGZTBlueToothManager.shared.device?.currentOxygen = Int(response[8])
                XGZTBlueToothManager.shared.device?.currentSystolicpressure = Int(response[9])
                XGZTBlueToothManager.shared.device?.currentDiastolicpressure = Int(response[10])
                NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "blood")
                NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "oxygen")
                NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "heart")
            } else if response.count >= 19 {
                XGZTBlueToothManager.shared.device?.currentStep = getIntFromBytes(response, 7)
                XGZTBlueToothManager.shared.device?.currentCalorie = getIntFromBytes(response, 11)
                XGZTBlueToothManager.shared.device?.currentDistance = getIntFromBytes(response, 15)
                NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "step")
            }
            NotificationCenter.default.post(name: Notification.Name("XGZTBusinessHandler"), object: "4")
        case .getStepData:
            guard response.count >= 62 else {
                XLogger.shared.log("resourceUpgrade command response error")
                return
            }
            let fixedMac = lastestDeviceMac
            let startIndex = 6
            let stepDataLength = 8

            for i in stride(from: startIndex, to: response.count, by: stepDataLength) {
                guard i + stepDataLength <= response.count else { break }

                let year = Int(response[i + 2]) | (Int(response[i + 3]) << 8)
                if year == 0 {
                    continue
                }
                
                let month = Int(response[i + 1])
                let day = Int(response[i])
                let date = String(format: "%04d-%02d-%02d", year, month, day)

                let step = Int(response[i + 4]) |
                           (Int(response[i + 5]) << 8) |
                           (Int(response[i + 6]) << 16) |
                           (Int(response[i + 7]) << 24)

                let stepObj = StepObj()
                stepObj.date = date
                stepObj.mac = fixedMac
                stepObj.step = step

                DatabaseManager.shared.addStepObj(stepObj: stepObj)
                XLogger.shared.log("历史步数读取成功:\(stepObj)")
            }
            NotificationCenter.default.post(name: Notification.Name("XGZTBusinessHandler"), object: "8")
        case .getHistorySleepData:
            guard response.count >= 76 else {
                XLogger.shared.log("resourceUpgrade command response error")
                return
            }
            let fixedMac = lastestDeviceMac
            let startIndex = 6
            let stepDataLength = 10

            for i in stride(from: startIndex, to: response.count, by: stepDataLength) {
                guard i + stepDataLength <= response.count else { break }

                let year = Int(response[i + 2]) | (Int(response[i + 3]) << 8)
                if year == 0 {
                    continue
                }
                
                let month = Int(response[i + 1])
                let day = Int(response[i])
                let date = String(format: "%04d-%02d-%02d", year, month, day)

                let awake = Int(response[i + 4]) |
                           (Int(response[i + 5]) << 8)
                let light = Int(response[i + 6]) |
                           (Int(response[i + 7]) << 8)
                let deep = Int(response[i + 8]) |
                           (Int(response[i + 9]) << 8)

                let sleepObj = SleepObj()
                sleepObj.date = date
                sleepObj.mac = fixedMac
                sleepObj.awake = awake
                sleepObj.light = light
                sleepObj.deep = deep

                DatabaseManager.shared.addSleepObj(sleepObj: sleepObj)
                XLogger.shared.log("历史睡眠读取成功:\(sleepObj)")
                
                
            }
            NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "refresh")
            NotificationCenter.default.post(name: Notification.Name("XGZTBusinessHandler"), object: "10")
        case .startTest:
            if response.count == 7 {
                let success = response[6] == 0x00
                if success {
                    XLogger.shared.log("测试命令执行成功")
                } else {
                    XLogger.shared.log("测试命令执行失败")
                }
            }
            if response.count >= 11 {
                let time = Int(response[6]) |
                           (Int(response[7]) << 8) |
                           (Int(response[8]) << 16) |
                           (Int(response[9]) << 24)
                let cmdType = Int(response[5])
                if cmdType == 0 {
                    if Int(response[10]) == 0 {
                        return
                    }
                    XGZTBlueToothManager.shared.device?.currentHeartrate = Int(response[10])
                    //XGZTCommand.startTest(cmdType: 0, control: 0)
                    let heartObj = HeartObj()
                    heartObj.mac = lastestDeviceMac
                    heartObj.time = time
                    heartObj.heart = Int(response[10])
                    DatabaseManager.shared.addHeartObj(heartObj: heartObj)
                    NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "heart")
                    XLogger.shared.log("获取到的心率为:\(time) --- \(Int(response[10]))")
                } else if cmdType == 1 {
                    if Int(response[10]) == 0 {
                        return
                    }
                    XGZTBlueToothManager.shared.device?.currentOxygen = Int(response[10])
                    //XGZTCommand.startTest(cmdType: 1, control: 0)
                    let oxgenObj = OxgenObj()
                    oxgenObj.mac = lastestDeviceMac
                    oxgenObj.time = time
                    oxgenObj.oxgen = Int(response[10])
                    DatabaseManager.shared.addOxgenObj(oxgenObj: oxgenObj)
                    NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "oxygen")
                    XLogger.shared.log("获取到的血氧为:\(time) --- \(Int(response[10]))")
                } else {
                    if Int(response[10]) == 0 {
                        return
                    }
                    XGZTBlueToothManager.shared.device?.currentSystolicpressure = Int(response[10])
                    XGZTBlueToothManager.shared.device?.currentDiastolicpressure = Int(response[11])
                    //XGZTCommand.startTest(cmdType: 2, control: 0)
                    let booldObj = BloodObj()
                    booldObj.time = time
                    booldObj.mac = lastestDeviceMac
                    booldObj.max = Int(response[10])
                    booldObj.min = Int(response[11])
                    DatabaseManager.shared.addBloodObj(bloodObj: booldObj)
                    NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "blood")
                    XLogger.shared.log("获取到的血压为:\(time) --- \(Int(response[10])) --- \(Int(response[11]))")
                }
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
                    NotificationCenter.default.post(name: Notification.Name("healthDetail"), object: nil)
                }
            }
        case .getNewestHeartData:
            if response.count >= 11 {
                let time = Int(response[6]) |
                           (Int(response[7]) << 8) |
                           (Int(response[8]) << 16) |
                           (Int(response[9]) << 24)
                let cmdType = Int(response[5])
                if cmdType == 0 {
                    XGZTBlueToothManager.shared.device?.currentHeartrate = Int(response[10])
                    let heartObj = HeartObj()
                    heartObj.mac = lastestDeviceMac
                    heartObj.time = time
                    heartObj.heart = Int(response[10])
                    DatabaseManager.shared.addHeartObj(heartObj: heartObj)
                    NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "heart")
                    XLogger.shared.log("获取到的心率为:\(time) --- \(Int(response[10]))")
                    NotificationCenter.default.post(name: Notification.Name("XGZTBusinessHandler"), object: "5")
                } else if cmdType == 1 {
                    XGZTBlueToothManager.shared.device?.currentOxygen = Int(response[10])
                    let oxgenObj = OxgenObj()
                    oxgenObj.mac = lastestDeviceMac
                    oxgenObj.time = time
                    oxgenObj.oxgen = Int(response[10])
                    DatabaseManager.shared.addOxgenObj(oxgenObj: oxgenObj)
                    NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "oxygen")
                    XLogger.shared.log("获取到的血氧为:\(time) --- \(Int(response[10]))")
                    NotificationCenter.default.post(name: Notification.Name("XGZTBusinessHandler"), object: "6")
                } else {
                    XGZTBlueToothManager.shared.device?.currentSystolicpressure = Int(response[10])
                    XGZTBlueToothManager.shared.device?.currentDiastolicpressure = Int(response[11])
                    let booldObj = BloodObj()
                    booldObj.time = time
                    booldObj.mac = lastestDeviceMac
                    booldObj.max = Int(response[10])
                    booldObj.min = Int(response[11])
                    DatabaseManager.shared.addBloodObj(bloodObj: booldObj)
                    NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "blood")
                    XLogger.shared.log("获取到的血压为:\(time) --- \(Int(response[10])) --- \(Int(response[11]))")
                    NotificationCenter.default.post(name: Notification.Name("XGZTBusinessHandler"), object: "7")
                }
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
                    NotificationCenter.default.post(name: Notification.Name("healthDetail"), object: nil)
                }
            }
        case .setTimePositionAndColor:
            if response.count == 7 {
                let success = response[6] == 0x00
                if success {
                    XLogger.shared.log("设置时间位置和颜色执行成功")
                } else {
                    XLogger.shared.log("设置时间位置和颜色执行失败")
                }
            }
        }
        
    }
}

class QRCodeSetCommand {
    // 指令相关固定字段值
    static let seqNumAndEnc: UInt8 = 0x00
    static let cmd: UInt8 = 0xE3
    static let cmdType: UInt8 = 0x01
    static let frameSeq: UInt8 = 0x00
    static let actionCmd: UInt8 = 0x01
    
    /// 构建收款码设置指令数据包
    /// - Parameters:
    ///   - type: 收款码类型，0x00 为支付宝，0x01 为微信
    ///   - qrString: 收款码的 URL 字符串（UTF-8 编码，不含末尾\0）
    /// - Returns: 完整的指令 Data，如果参数不合法返回 nil
    static func buildCommand(type: UInt8, qrString: String) -> Data? {
        // 校验收款码类型
        guard (0x00...0x01).contains(type) else {
            print("收款码类型不合法，需为 0x00 或 0x01")
            return nil
        }
        let qrData = qrString.data(using: .utf8)
        guard let qrData = qrData else {
            print("收款码字符串转 UTF-8 Data 失败")
            return nil
        }
        // 计算 Frame Length：2 + 字符串长度（qrString 的字节数）
        let frameLength: UInt8 = UInt8(2 + qrData.count)
        
        var commandData = Data()
        // 依次添加各字段
        commandData.append(seqNumAndEnc)
        commandData.append(cmd)
        commandData.append(cmdType)
        commandData.append(frameSeq)
        commandData.append(frameLength)
        commandData.append(actionCmd)
        commandData.append(type)
        commandData.append(contentsOf: qrData)
        
        return commandData
    }
}

class MACAddressComparator {
    /// 判断两个MAC地址的特定字节是否相同
    /// - Parameters:
    ///   - mac1: 第一个MAC地址字符串（格式如"AA:BB:CC:DD:EE:FF"）
    ///   - mac2: 第二个MAC地址字符串（格式如"AA:BB:CC:DD:EE:FF"）
    /// - Returns: 如果第1、2、3、5、6字节相同则返回true，否则返回false；格式不正确也返回false
    static func isMatching(_ mac1: String, _ mac2: String) -> Bool {
        // 分割MAC地址为字节数组
        let components1 = mac1.components(separatedBy: ":")
        let components2 = mac2.components(separatedBy: ":")
        
        // 验证MAC地址格式是否正确（必须包含6个字节）
        guard components1.count == 6 && components2.count == 6 else {
            return false
        }
        
        // 需要比较的字节索引（0-based）
        let indicesToCheck: [Int] = [0, 1, 2, 4, 5]
        
        // 检查每个指定索引的字节是否相同
        for index in indicesToCheck {
            if components1[index].uppercased() != components2[index].uppercased() {
                return false
            }
        }
        
        return true
    }
}
