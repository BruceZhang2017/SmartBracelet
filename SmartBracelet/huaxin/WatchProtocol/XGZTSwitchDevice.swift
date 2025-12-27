//
//  XGZTSwitchDevice.swift
//  SmartBracelet
//
//  Created by anker on 2024/11/15.
//  Copyright © 2024 tjd. All rights reserved.
//

import Foundation

// MARK: - 设备模型

public class BluetoothWatchDevice {
    // 手表设备信息属性
    var deviceName: String?
    var deviceModel: Int?
    var deviceID: Int?
    var brandID: Int? // 品牌id
    var max: String?
    var batteryLevel: Int?
    var isCharging: Bool?
    var deviceLanguage: Int?
    var deviceUnitFormat: Int?
    /// 硬件版本
    /// hardware version
    var hardwareVersion: Int?
    /// 固件版本
    /// Firmware version
    var firmwareVersion: String?
    /// 1 方形， 2 圆形,  自定义：屏幕形状: 0x00: 正⽅形, 0x01: 圆形, 0x02: ⻓⽅形
    var screenType: Int = 1
    /// 表盘宽 默认240
    var screenWidth: Int = 240
    /// 表盘高 默认240
    var screenHeight: Int = 240
    var mtu: Int = 0
    
    var sex: Int = 0 // 性别：0x00：男，0x01：女
    var age: Int = 0
    var height: Int = 0
    var weight: Int = 0
    var timeUnit: Int = 0 // 返回时间制：0x00:12h 0x01:24h
    var baseUnit: Int = 0 
    
    var alarmcount: Int = 0
    var alarmCanUse: Int = 0
    var alarms: [AlarmData] = [] // 闹钟
    var longsit: ReminderInfoResponse?
    var drinkWater: ReminderInfoResponse?
    
    // health
    var currentStep: Int = 0
    var currentSleep: Int = 0
    var currentSleepArray: [Int] = [0,0,0]
    var currentCalorie: Int = 0
    var currentDistance: Int = 0
    var currentHeartrate: Int = 0
    var currentOxygen: Int = 0
    var currentSystolicpressure: Int = 0 // 收缩压（单位：mmHg）
    var currentDiastolicpressure: Int = 0 // 舒张压（单位：mmHg）
    
    var functioncontrolflags: Int = 0 // [0] 是否⽀持表盘市场 [1] 是否⽀持消息提醒 [2] 是否⽀持天⽓功能 等
    var healthcontrolflags: Int = 0 // [0] 是否⽀持⼼率检测 [1] 是否⽀持⾎氧检测 等
    
    // 开关类
    var isAntilostSwitch: Bool = false // 防丢开关
    var isRaisehandtobrightenscreen: Bool = false // 抬⼿亮屏开关
    var isAutoSyncSwitch: Bool = false // ⾃动同步开关
    var isSleepmonitoringSwitch: Bool = false // Sleep monitoring Switch
    var isMessageremindermainswitch: Bool = false // 消息提醒总开关
    var isRegularexercisedatauploadswitch: Bool = false // 整点上传运动数据开关
    var isGoalachievementswitch: Bool = false // ⽬标达成开关
    var isMessagescreendisplayswitch: Bool = false // 消息提醒亮屏开关
    var isSoundswitch: Bool = false // 声⾳开关
    var isVibrationswitch: Bool = false // 震动总开关
    var isRegularhealthdatauploadswitch: Bool = false // 整点上传健康数据开关
    var isMessagevibrationswitch: Bool = false // 消息提醒震动开关
    
    // 通知类
    var isNullMessage: Bool = true // 五消息
    var isIncomingCall: Bool = false // 来电
    var isMissedCall: Bool = false // 未接来电
    var isMessages: Bool = true // 短信
    var isEmail: Bool = true // 邮件
    var isSchedule: Bool = true // ⽇程
    var isFacetime: Bool = true // Facetime
    var isQQ: Bool = true // qq
    var isSkype: Bool = true // Skype
    var isWechat: Bool = true // Wechat
    var isWhatsapp: Bool = true // Whatsapp
    var isGmail: Bool = true // Gmail
    var isHangout: Bool = true // Hangout
    var isInbox: Bool = true // Inbox
    var isLine: Bool = true // Line
    var isTwitter: Bool = true
    var isFacebook: Bool = true
    var isFacebookMessenger: Bool = true
    var isInstagram: Bool = true
    var isWeibo: Bool = true
    var isKakaotalk: Bool = true
    var isFacebookpagemanager: Bool = true
    var isViber: Bool = true
    var isVkclient: Bool = true
    var isTelegram: Bool = true
    var isSnapchat: Bool = true
    var isDingTalk: Bool = true
    var isAlipay: Bool = true
    var isTiktok: Bool = true
    var isLinkedIn: Bool = true
    
    
    // 存储设备信息到沙盒
    static func saveToSandbox(device: BluetoothWatchDevice) {
        let defaults = UserDefaults.standard
        
        // 1. 安全解包 `device.max`（mac地址），确保键有效
        guard let macAddress = device.max, macAddress.count > 0 else {
            XLogger.shared.log("Error: device.max (mac address) is nil")
            return
        }
        
        // 2. 安全解包 `device.deviceName`，确保不存储空值
        guard let deviceName = device.deviceName, deviceName.count > 0 else {
            XLogger.shared.log("Error: deviceName is nil for mac address \(macAddress)")
            return
        }
        
        var dic = defaults.dictionary(forKey: "xgzt") as? [String: String] ?? [:]
        
        // 3. 检查该 `macAddress` 键是否已存在且值不为空
        if let existingName = dic[macAddress], !existingName.isEmpty {
            // 键已存在且已有名称，不执行保存操作
            return
        }
        
        // 4. 存储当前设备的键值对
        dic[macAddress] = deviceName
        defaults.set(dic, forKey: "xgzt")
        
        // 5. 更新缓存（使用新的管理器）
        XGZTDeviceManager.shared.reloadDevices()
    }
    
    
    // 从沙盒读取设备信息
    static func loadFromSandbox(mac: String) -> BluetoothWatchDevice? {
        let defaults = UserDefaults.standard
        let dic = defaults.dictionary(forKey: "xgzt") as? [String: String] ?? [:]
        guard let name = dic[mac] else {
            return nil
        }
        var device = BluetoothWatchDevice()
        device.deviceName = name
        device.max = mac
        return device
    }
    
    // 新增：从沙盒读取指定设备名称的设备信息
    // 如果存在多个同名设备，返回第一个匹配项
    static func loadFromSandbox(deviceName: String) -> BluetoothWatchDevice? {
        let defaults = UserDefaults.standard
        let dic = defaults.dictionary(forKey: "xgzt") as? [String: String] ?? [:]
        
        // 遍历查找名称匹配的设备
        for (mac, name) in dic {
            if name == deviceName {
                let device = BluetoothWatchDevice()
                device.deviceName = name
                device.max = mac
                return device
            }
        }
        
        // 未找到匹配的设备
        return nil
    }

    static func deleteFromSandbox(mac: String) {
        let defaults = UserDefaults.standard
        var dic = defaults.dictionary(forKey: "xgzt") as? [String: String] ?? [:]
        if dic.count == 0 {
            return
        }

        for (m, _) in dic {
            if m == mac {
                dic.removeValue(forKey: m)
                break
            }
        }
        XLogger.shared.log("删除设备后：\(dic.keys.count) ")
        defaults.set(dic, forKey: "xgzt")
        defaults.synchronize()

        // 更新缓存
        XGZTDeviceManager.shared.reloadDevices()
    }
    
    /// 加载所有设备到缓存（使用新的线程安全管理器）
    static func loadAll() {
        XGZTDeviceManager.shared.reloadDevices()
    }
}
