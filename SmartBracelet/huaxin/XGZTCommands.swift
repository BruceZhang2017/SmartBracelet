//
//  XGZTCommand.swift
//  SmartBracelet
//
//  Created by anker on 2024/11/16.
//  Copyright © 2024 tjd. All rights reserved.
//

import UIKit

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
    case setAutoSleepMonitoring = 0xB6
    
    case startTest = 0xC5
    case getNewestHealthData = 0xC7
    case getStepData = 0xC8
    case getHistorySleepData = 0xC9
    case getNewestHeartData = 0xCA

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
    
    // 设置天气单位
    static func setWeatherUnit(unit: Int) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.setWeatherUnit.rawValue,
            0x01,
            0x00,
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
    static func bindDevice() {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.bindDevice.rawValue,
            0x01,
            0x00,
            0x02,
            0x01,
            0x00
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    // 获取闹钟信息
    static func getAlarmInfo() {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.alarmInfo.rawValue,
            0x01,
            0x00,
            0x02,
            0x00,
            0x01
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
            UInt8(response.eventType + 1),
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
    static func setWeatherInfo(dateType: Int, weatherType: Int, currTemp: Int, lTemp: Int, hTemp: Int) {
        let command = createCommand(with: [
            0x00,
            XGZTCommands.setWeatherInfo.rawValue,
            0x01,
            0x00,
            UInt8(14),
            0x01,
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
            0x00
        ])
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
    }
    
    // 设置联系人信息
    static func setContactInfo(type: Int, index: Int, name: String, phoneNumber: String) {
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
        XGZTBlueToothManager.shared.writeCharacteristic(command: command)
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
    
    // 统一处理指令响应的方法，优化为从响应数据中解析指令标识来判断情况
    public static func handleResponse(response: [UInt8]) {
        if response.count < 2 {
            return
        }
        let commandRawValue = response[1]
        guard let command = XGZTCommands(rawValue: commandRawValue) else {
            print("Unhandled command response")
            return
        }
        switch command {
        case.syncTime:
            guard response.count >= 7 else {
                print("syncTime command response error")
                return
            }
            let success = response[6] == 0x00
            if success {
                print("时间同步成功")
            } else {
                print("时间同步失败")
            }
        case.getBatteryLevel:
            guard response.count >= 7 else {
                print("getBatteryLevel command response error")
                return
            }
            let batteryLevel = Int(response[6] & 0x7F)
            let isCharging = (response[6] & 0x80) != 0
            print("Battery level: \(batteryLevel), Is charging: \(isCharging)")
        case.setScreenBrightness:
            guard response.count >= 6 else {
                print("setScreenBrightness command response error")
                return
            }
            let success = response[5] == 0x00
            if success {
                print("设置屏幕亮度命令执行成功")
            } else {
                print("设置屏幕亮度命令执行失败")
            }
        case.getDeviceLanguage:
            guard response.count >= 7 else {
                print("getDeviceLanguage command response error")
                return
            }
            let languageType = Int(response[6])
            print("设备语言类型: \(languageType)")
        case.setDeviceUnitFormat:
            guard response.count >= 7 else {
                print("setDeviceUnitFormat command response error")
                return
            }
            if response[5] == 0x00 {
                XGZTBlueToothManager.shared.device?.baseUnit = Int(response[6])
            } else {
                let success = response[6] == 0x00
                if success {
                    print("设置设备单位格式命令执行成功")
                } else {
                    print("设置设备单位格式命令执行失败")
                }
            }
            
        case.resetToFactorySettings:
            guard response.count >= 6 else {
                print("resetToFactorySettings command response error")
                return
            }
            let success = response[5] == 0x00
            if success {
                print("重置设备为出厂设置命令执行成功")
            } else {
                print("重置设备为出厂设置命令执行失败")
            }
        case.setDeviceScreenTimeout:
            guard response.count >= 6 else {
                print("setDeviceScreenTimeout command response error")
                return
            }
            let success = response[5] == 0x00
            if success {
                print("设置设备亮屏时间命令执行成功")
            } else {
                print("设置设备亮屏时间命令执行失败")
            }
        case.setDoNotDisturb:
            guard response.count >= 6 else {
                print("setDoNotDisturb command response error")
                return
            }
            let success = response[5] == 0x00
            if success {
                print("设置勿扰功能命令执行成功")
            } else {
                print("设置勿扰功能命令执行失败")
            }
        case.findBand:
            guard response.count >= 7 else {
            print("findBand command response error")
            return
            }
            let success = response[6] == 0x00
            if success {
                print("查找手环命令执行成功")
            } else {
                print("查找手环命令执行失败")
            }
        case.findPhone:
            guard response.count >= 6 else {
                print("findPhone command response error")
                return
            }
            if response[5] == 0x00 {
                print("开始查找手机")
                DispatchQueue.main.async {
                    (UIApplication.shared.delegate as? AppDelegate)?.foundphone()
                }
            } else {
                print("结束查找手机")
            }
        case.setWeatherUnit:
            guard response.count >= 6 else {
                print("setWeatherUnit command response error")
                return
            }
            let success = response[5] == 0x00
            if success {
                print("设置天气单位命令执行成功")
            } else {
                print("设置天气单位命令执行失败")
            }
        case.set12H24HTimeFormat:
            guard response.count >= 7 else {
                print("set12H24HTimeFormat command response error")
                return
            }
            if response[5] == 0 {
                XGZTBlueToothManager.shared.device?.timeUnit = Int(response[6])
            } else {
                let success = response[6] == 0x00
                if success {
                    print("设置12小时/24小时时间制命令执行成功")
                } else {
                    print("设置12小时/24小时时间制命令执行失败")
                }
            }
        case.getDeviceInfo:
            if response.count == 13 {
                let range = 7..<13 // Convert ClosedRange to Range by adding 1 to the upper bound
                let macAddressData = response[range]
                let macAddress = macAddressData.map { String(format: "%02x", $0) }.joined(separator: ":").uppercased()
                lastestDeviceMac = macAddress
                XGZTBlueToothManager.shared.device?.max = macAddress
                UserDefaults.standard.setValue(lastestDeviceMac, forKey: "LastestDeviceMac")
                UserDefaults.standard.synchronize()
                return
            }
            guard response.count >= 46 else {
                print("getDeviceInfo command response error")
                return
            }
            XGZTBlueToothManager.shared.device?.screenType = Int(response[5])
            XGZTBlueToothManager.shared.device?.hardwareVersion = Int(response[30])
            XGZTBlueToothManager.shared.device?.firmwareVersion = "\(Int(response[31])).\(Int(response[32]))"
            XGZTBlueToothManager.shared.device?.deviceID = (Int(response[34]) << 8) | Int(response[33])
            XGZTBlueToothManager.shared.device?.deviceModel = (Int(response[36]) << 8) | Int(response[35])
            XGZTBlueToothManager.shared.device?.screenWidth = (Int(response[38]) << 8) | Int(response[37])
            XGZTBlueToothManager.shared.device?.screenHeight = (Int(response[40]) << 8) | Int(response[39])
            XGZTBlueToothManager.shared.device?.functioncontrolflags = getIntFromBytes(response, 10)
            XGZTBlueToothManager.shared.device?.healthcontrolflags = getIntFromBytes(response, 14)
            
        case.setAppInfo:
            guard response.count >= 7 else {
                print("setAppInfo command response error")
                return
            }
            let success = response[6] == 0x00
            if success {
                print("设置应用端信息命令执行成功")
            } else {
                print("设置应用端信息命令执行失败")
            }
        case.personalInfo:
            if response.count == 7 {
                let success = response[6] == 0x00
                if success {
                    print("设置用户信息执行成功")
                } else {
                    print("设置用户信息执行失败")
                }
                return
            }
            guard response.count >= 9 else {
                print("personalInfo command response error")
                return
            }
            if response[2] == 3 {
                XGZTBlueToothManager.shared.device?.sex = Int(response[5])
                XGZTBlueToothManager.shared.device?.age = Int(response[6])
                XGZTBlueToothManager.shared.device?.height = Int(response[7])
                XGZTBlueToothManager.shared.device?.weight = Int(response[8])
            }
        case.switchStatus:
            guard response.count >= 7 else {
                print("switchStatus command response error")
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
            } else {
                let success = response[6] == 0x00
                if success {
                    print("设置开关执行成功")
                } else {
                    print("设置开关执行失败")
                }
            }
        case.bindDevice:
            guard response.count >= 8 else {
                print("bindDevice command response error")
                return
            }
            let success = response[7] == 0x01
            if success {
                print("绑定设备命令执行成功")
            } else {
                print("绑定设备命令执行失败")
            }
        case.alarmInfo:
            guard response.count >= 7 else {
                print("alarmInfo command response error")
                return
            }
            if response.count == 7 && response[5] == 0x00 {
                XGZTBlueToothManager.shared.device?.alarmcount = Int(response[6])
                return
            }
            if response.count == 7 && response[5] == 0x01 && response[6] == 0x00 {
                XGZTCommand.getAlarmInfo()
                return
            }
            if response.count == 13 {
                let index = Int(response[6])
                let switchValue = Int(response[7])
                let cycle = Int(response[8])
                let hour = Int(response[9])
                let minute = Int(response[10])
                let vibration = Int(response[11])
                let later = Int(response[12])
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
                    print("提醒协议设置成功")
                }
                return
            }
            guard response.count >= 12 else {
                print("reminderInfo command response error")
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
            } else if eventType == 1 {
                XGZTBlueToothManager.shared.device?.drinkWater = ReminderInfoResponse(eventType: eventType, cycle: cycle, startHour: startHour, startMinute: startMinute, endHour: endHour, endMinute: endMinute, period: period)
                
                NotificationCenter.default.post(name: Notification.Name("DeviceSettings"), object: 1)
            }
        case.switchTableExtension:
            guard response.count >= 7 else {
                print("switchTableExtension command response error")
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
                
            } else {
                let success = response[6] == 0x00
                if success {
                    print("设置开关执行成功")
                } else {
                    print("设置开关执行失败")
                }
            }
            
        case.musicControl:
            guard response.count >= 6 else {
                print("musicControl command response error")
                return
            }
            let success = response[5] == 0x00
            if success {
                print("音乐控制命令执行成功")
            } else {
                print("音乐控制命令执行失败")
            }
        case.remotePhoto:
            if response.count == 6 {
                if response[5] == 0 {
                    NotificationCenter.default.post(name: Notification.Name("DeviceSettings"), object: nil)
                } else if response[5] == 1 {
                    NotificationCenter.default.post(name: Notification.Name("DeviceSettings"), object: 3)
                } else if response[5] == 2 {
                    NotificationCenter.default.post(name: Notification.Name("DeviceSettings"), object: 2)
                }
                return
            }
            guard response.count >= 7 else {
                print("remotePhoto command response error")
                return
            }
            let success = response[6] == 0x00
            if success {
                print("远程拍照命令执行成功")
            } else {
                print("远程拍照命令执行失败")
            }
        case.messagePush:
            guard response.count >= 6 else {
                print("messagePush command response error")
                return
            }
            let success = response[5] == 0x00
            if success {
                print("消息推送命令执行成功")
            } else {
                print("消息推送命令执行失败")
            }
        case.setWeatherInfo:
            guard response.count >= 7 else {
                print("setWeatherInfo command response error")
                return
            }
            let success = response[6] == 0x00
            if success {
                print("设置天气信息命令执行成功")
            } else {
                print("设置天气信息命令执行失败")
            }
        case.contactInfo:
            guard response.count >= 7 else {
                print("contactInfo command response error")
                return
            }
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
                    let name = getStringFromBytes(response, offset, nameLength)
                    offset += nameLength
                    let phoneNumberLength = Int(response[offset])
                    offset += 1
                    let phoneNumber = getPhoneNumberFromBytes(response, offset, phoneNumberLength)
                    offset += phoneNumberLength
                    contacts?.append(ContactData(index: index, name: name, phoneNumber: phoneNumber))
                }
            }
            print("联系人数量: \(contactNum), 联系人信息: \(contacts ?? [])")
        case.incomingCallMute:
            guard response.count >= 6 else {
                print("incomingCallMute command response error")
                return
            }
            let success = response[5] == 0x00
            if success {
                print("来电静音命令执行成功")
            } else {
                print("来电静音命令执行失败")
            }
        case.targetSettings:
            guard response.count >= 16 else {
                print("targetSettings command response error")
                return
            }
            let targetSwitch = getShortFromBytes(response, 6)
            let stepTargetValue = Int(response[8])
            let distanceTargetValue = Int(response[9])
            let calorieTargetValue = getShortFromBytes(response, 10)
            let sleepTargetValue = getShortFromBytes(response, 12)
            let exerciseDurationTargetValue = getShortFromBytes(response, 14)
            print("目标设置开关: \(targetSwitch)")
            print("步数目标值: \(stepTargetValue)")
            print("距离目标值: \(distanceTargetValue)")
            print("卡路里目标值: \(calorieTargetValue)")
            print("睡眠目标值: \(sleepTargetValue)")
            print("运动时长目标值: \(exerciseDurationTargetValue)")
        case.multiSportModeData:
            guard response.count >= 8 else {
                print("multiSportModeData command response error")
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
            print("多运动模式数据数量: \(numData), 数据详情: \(sportDataList)")
        case.setAutoSleepMonitoring:
            guard response.count >= 12 else {
                print("setAutoSleepMonitoring command response error")
                return
            }
            let startHour = Int(response[6])
            let startMinute = Int(response[7])
            let endHour = Int(response[8])
            let endMinute = Int(response[9])
            let alarmCycle = Int(response[10])
            let responseCode = Int(response[11])
            print("自动睡眠监测开始时间（小时）: \(startHour)")
            print("自动睡眠监测开始时间（分钟）: \(startMinute)")
            print("自动睡眠监测结束时间（小时）: \(endHour)")
            print("自动睡眠监测结束时间（分钟）: \(endMinute)")
            print("自动睡眠监测闹钟周期: \(alarmCycle)")
            print("响应码: \(responseCode)")
        case.dialMarket:
            guard response.count >= 7 else {
                print("dialMarket command response error")
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
                print("resourceUpgrade command response error")
                return
            }
            let success = response[5] == 0x00
            if success {
                print("资源升级相关命令执行成功")
            } else {
                print("资源升级相关命令执行失败")
            }
        case .getNewestHealthData:
            guard response.count >= 11 else {
                print("resourceUpgrade command response error")
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
            } else if response.count == 19 {
                XGZTBlueToothManager.shared.device?.currentStep = getIntFromBytes(response, 7)
                XGZTBlueToothManager.shared.device?.currentCalorie = getIntFromBytes(response, 11)
                XGZTBlueToothManager.shared.device?.currentDistance = getIntFromBytes(response, 15)
                NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "step")
            }
            
        case .getStepData:
            guard response.count >= 62 else {
                print("resourceUpgrade command response error")
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
                print("历史步数读取成功:\(stepObj)")
            }
        case .getHistorySleepData:
            guard response.count >= 76 else {
                print("resourceUpgrade command response error")
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
                print("历史睡眠读取成功:\(sleepObj)")
                
                
            }
            NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "refresh")
        case .startTest:
            if response.count == 7 {
                let success = response[6] == 0x00
                if success {
                    print("测试命令执行成功")
                } else {
                    print("测试命令执行失败")
                }
            }
            if response.count >= 11 {
                let time = Int(response[6]) |
                           (Int(response[7]) << 8) |
                           (Int(response[8]) << 16) |
                           (Int(response[9]) << 24)
                let cmdType = Int(response[5])
                if cmdType == 0 {
                    XGZTBlueToothManager.shared.device?.currentHeartrate = Int(response[10])
                    XGZTCommand.startTest(cmdType: 0, control: 0)
                    let heartObj = HeartObj()
                    heartObj.mac = lastestDeviceMac
                    heartObj.time = time
                    heartObj.heart = Int(response[10])
                    DatabaseManager.shared.addHeartObj(heartObj: heartObj)
                    NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "heart")
                    print("获取到的心率为:\(time) --- \(Int(response[10]))")
                } else if cmdType == 1 {
                    XGZTBlueToothManager.shared.device?.currentOxygen = Int(response[10])
                    XGZTCommand.startTest(cmdType: 1, control: 0)
                    let oxgenObj = OxgenObj()
                    oxgenObj.mac = lastestDeviceMac
                    oxgenObj.time = time
                    oxgenObj.oxgen = Int(response[10])
                    DatabaseManager.shared.addOxgenObj(oxgenObj: oxgenObj)
                    NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "oxygen")
                    print("获取到的血氧为:\(time) --- \(Int(response[10]))")
                } else {
                    XGZTBlueToothManager.shared.device?.currentSystolicpressure = Int(response[10])
                    XGZTBlueToothManager.shared.device?.currentDiastolicpressure = Int(response[11])
                    XGZTCommand.startTest(cmdType: 2, control: 0)
                    let booldObj = BloodObj()
                    booldObj.time = time
                    booldObj.mac = lastestDeviceMac
                    booldObj.max = Int(response[10])
                    booldObj.min = Int(response[11])
                    DatabaseManager.shared.addBloodObj(bloodObj: booldObj)
                    NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "blood")
                    print("获取到的血压为:\(time) --- \(Int(response[10])) --- \(Int(response[11]))")
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
                    print("获取到的心率为:\(time) --- \(Int(response[10]))")
                } else if cmdType == 1 {
                    XGZTBlueToothManager.shared.device?.currentOxygen = Int(response[10])
                    let oxgenObj = OxgenObj()
                    oxgenObj.mac = lastestDeviceMac
                    oxgenObj.time = time
                    oxgenObj.oxgen = Int(response[10])
                    DatabaseManager.shared.addOxgenObj(oxgenObj: oxgenObj)
                    NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "oxygen")
                    print("获取到的血氧为:\(time) --- \(Int(response[10]))")
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
                    print("获取到的血压为:\(time) --- \(Int(response[10])) --- \(Int(response[11]))")
                }
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
                    NotificationCenter.default.post(name: Notification.Name("healthDetail"), object: nil)
                }
            }
        }
        
    }
}
