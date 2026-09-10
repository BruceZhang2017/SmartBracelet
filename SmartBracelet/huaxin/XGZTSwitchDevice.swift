//
//  XGZTSwitchDevice.swift
//  SmartBracelet
//
//  Created by bruce on 2024/11/15.
//  Copyright © 2024 tjd. All rights reserved.
//

import Foundation


import Foundation

public var cacheDevices = [BluetoothWatchDevice]()
public var connectFailMessage = ""

public class BluetoothWatchDevice {
    private enum CapabilityBits {
        static let watchFaceMarket = 0
        static let weatherPush = 2
        static let appPowerControl = 17
        static let heartRate = 0
        static let bloodOxygen = 1
        static let bloodPressure = 2
        static let bloodGlucose = 3
        static let sleep = 4
        static let bloodLipid = 6
        static let uricAcid = 7
        static let ecg = 8
        static let ppg = 9
        static let hrv = 10
        static let stress = 11
        static let fatigue = 12
    }

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
    /// 设备类型 Watch type: 0x04 表示无屏设备
    var watchType: Int = 0
    /// 表盘宽 默认240
    var screenWidth: Int = 240
    /// 表盘高 默认240
    var screenHeight: Int = 240
    var mtu: Int = 0
    
    // MARK: - 设备能力派生
    
    /// 是否为无屏设备（watch type == 0x04）
    var isNoScreenDevice: Bool { watchType == 0x04 }
    
    /// functioncontrolflags [0] 是否支持表盘市场
    var supportsWatchFaceMarket: Bool {
        if isNoScreenDevice { return false }
        return (functioncontrolflags >> CapabilityBits.watchFaceMarket) & 1 == 1
    }
    
    /// functioncontrolflags [2] 是否支持天气功能
    var supportsWeatherPush: Bool {
        if isNoScreenDevice { return false }
        return (functioncontrolflags >> CapabilityBits.weatherPush) & 1 == 1
    }
    
    /// 是否支持抬手亮屏（无屏设备强制关闭）
    var supportsRaiseHandScreen: Bool {
        if isNoScreenDevice { return false }
        return true
    }
    
    /// healthcontrolflags [8] 是否支持心电图 ECG
    var supportsECG: Bool {
        if isNoScreenDevice { return true }
        return (healthcontrolflags >> CapabilityBits.ecg) & 1 == 1
    }

    /// healthcontrolflags [5] 是否支持血脂
    var supportsBloodGlucose: Bool {
        return (healthcontrolflags >> CapabilityBits.bloodGlucose) & 1 == 1
    }

    /// healthcontrolflags [6] 是否支持血脂
    var supportsBloodLipid: Bool {
        return (healthcontrolflags >> CapabilityBits.bloodLipid) & 1 == 1
    }

    /// healthcontrolflags [7] 是否支持尿酸
    var supportsUricAcid: Bool {
        return (healthcontrolflags >> CapabilityBits.uricAcid) & 1 == 1
    }

    /// healthcontrolflags [9] 是否支持脉搏波 PPG
    var supportsPPG: Bool {
        if isNoScreenDevice { return true }
        return (healthcontrolflags >> CapabilityBits.ppg) & 1 == 1
    }

    /// healthcontrolflags [10] 是否支持心率变异性 HRV
    var supportsHRV: Bool {
        if isNoScreenDevice { return true }
        return (healthcontrolflags >> CapabilityBits.hrv) & 1 == 1
    }

    /// healthcontrolflags [11] 是否支持精神压力
    var supportsStress: Bool {
        if isNoScreenDevice { return true }
        return (healthcontrolflags >> CapabilityBits.stress) & 1 == 1
    }

    /// healthcontrolflags [12] 是否支持疲劳度
    var supportsFatigue: Bool {
        if isNoScreenDevice { return true }
        return (healthcontrolflags >> CapabilityBits.fatigue) & 1 == 1
    }

    /// functioncontrolflags [17] 是否支持 App 控制恢复出厂
    var supportsFactoryResetControl: Bool {
        return (functioncontrolflags >> CapabilityBits.appPowerControl) & 1 == 1
    }

    /// functioncontrolflags [17] 是否支持 App 控制重启
    var supportsRestartControl: Bool {
        return (functioncontrolflags >> CapabilityBits.appPowerControl) & 1 == 1
    }

    /// functioncontrolflags [17] 是否支持 App 控制关机
    var supportsShutdownControl: Bool {
        return (functioncontrolflags >> CapabilityBits.appPowerControl) & 1 == 1
    }

    var supportsPowerControlCenter: Bool {
        supportsFactoryResetControl || supportsRestartControl || supportsShutdownControl
    }

    
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
    var currentBloodGlucose: Double = 0
    var currentUricAcid: Int = 0
    var currentBloodLipid: Double = 0
    var currentBloodLipidDetail: String?
    var currentPPG: Int = 0 // 脉搏 PPG（单位：bpm）
    var currentHRV: Int = 0 // 心率变异性（单位：ms）
    var currentStress: Int = 0 // 精神压力（单位：分）
    var currentFatigue: Int = 0 // 疲劳度（单位：分）
    
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
        
        // 3. 检查该 `macAddress` 键是否已存在且设备名称已经存在
        if let existingName = dic[macAddress], existingName == deviceName {
            // 键已存在且已有相同名称，不执行保存操作
            return
        }
        
        // 4. 存储当前设备的键值对
        dic[macAddress] = deviceName
        defaults.set(dic, forKey: "xgzt")
        
        // 5. 更新缓存（根据业务逻辑保留）
        BluetoothWatchDevice.loadAll()
    }
    
    
    // 从沙盒读取设备信息
    static func loadFromSandbox(mac: String) -> BluetoothWatchDevice? {
        let defaults = UserDefaults.standard
        let dic = defaults.dictionary(forKey: "xgzt") as? [String: String] ?? [:]
        guard let name = dic[mac] else {
            return nil
        }
        let device = BluetoothWatchDevice()
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
        XLogger.shared.log("[unbind-debug] deleteFromSandbox before: targetMac=\(mac), cachedKeys=\(Array(dic.keys))")
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
        XLogger.shared.log("[unbind-debug] deleteFromSandbox after: cachedKeys=\(Array(dic.keys))")
        
        BluetoothWatchDevice.loadAll()
    }
    
    static func loadAll() {
        cacheDevices.removeAll()
        cacheDevices = []
        let defaults = UserDefaults.standard
        guard let dic = defaults.dictionary(forKey: "xgzt") as? [String: String] else {
            XLogger.shared.log("[unbind-debug] loadAll: xgzt cache dictionary missing")
            return
        }
        
        if dic.isEmpty || dic.count <= 0 {
            XLogger.shared.log("[unbind-debug] loadAll: xgzt cache dictionary empty")
            return
        }
        
        var existingMACs = Set<String>() // 用于记录已存在的 MAC 地址
        
        for (mac, name) in dic {
            // 检查 MAC 是否已存在
            if existingMACs.contains(mac) {
                continue
            }
            
            existingMACs.insert(mac)
            
            let device = BluetoothWatchDevice()
            device.deviceName = name
            device.max = mac
            XLogger.shared.log("已经缓存的设备：\(mac) \(name)")
            cacheDevices.append(device)
        }
    }
}
