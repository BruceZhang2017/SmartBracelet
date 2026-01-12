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
    public var deviceName: String?
    public var deviceModel: Int?
    public var deviceID: Int?
    public var brandID: Int? // 品牌id
    public var max: String?
    public var batteryLevel: Int?
    public var isCharging: Bool?
    public var deviceLanguage: Int?
    public var deviceUnitFormat: Int?
    /// 硬件版本
    /// hardware version
    public var hardwareVersion: Int?
    /// 固件版本
    /// Firmware version
    public var firmwareVersion: String?
    /// 1 方形， 2 圆形,  自定义：屏幕形状: 0x00: 正⽅形, 0x01: 圆形, 0x02: ⻓⽅形
    public var screenType: Int = 1
    /// 表盘宽 默认240
    public var screenWidth: Int = 240
    /// 表盘高 默认240
    public var screenHeight: Int = 240
    public var mtu: Int = 0
    
    public var sex: Int = 0 // 性别：0x00：男，0x01：女
    public var age: Int = 0
    public var height: Int = 0
    public var weight: Int = 0
    public var timeUnit: Int = 0 // 返回时间制：0x00:12h 0x01:24h
    public var baseUnit: Int = 0 
    public var doNotDisturb: DoNotDisturb?
    public var alarmcount: Int = 0
    public var alarmCanUse: Int = 0
    public var alarms: [AlarmData] = [] // 闹钟
    public var longsit: ReminderInfoResponse?
    public var drinkWater: ReminderInfoResponse?
    
    // health
    public var currentStep: Int = 0
    public var currentSleep: Int = 0
    public var currentSleepArray: [Int] = [0,0,0]
    public var currentCalorie: Int = 0
    public var currentDistance: Int = 0
    public var currentHeartrate: Int = 0
    public var currentOxygen: Int = 0
    public var currentSystolicpressure: Int = 0 // 收缩压（单位：mmHg）
    public var currentDiastolicpressure: Int = 0 // 舒张压（单位：mmHg）

    // MARK: - 步数换算方法

    /// 根据当前步数、身高和体重计算并更新卡路里和距离
    /// 该方法会自动更新 currentCalorie 和 currentDistance 属性
    public func calculateCalorieAndDistance() {
        // 计算每一步的基准距离（单位转换）
        // distance = height * 415 / 1000
        let stepDistance = self.height * 415 / 1000

        // 计算总距离（内部单位）
        // unit = step * distance
        let totalDistanceUnit = self.currentStep * stepDistance

        // 计算卡路里（内部单位）
        // v = unit * weight * 55
        let calorieUnit = totalDistanceUnit * self.weight * 55

        // 更新距离（转换为显示单位）
        // 距离单位转换：Float(unit) / 100000
        self.currentDistance = totalDistanceUnit

        // 更新卡路里（转换为显示单位）
        // 卡路里单位转换：(Float(v) / 10000).rounded(.towardZero) / 1000
        self.currentCalorie = calorieUnit

        XLogger.shared.log("步数换算 - 步数：\(self.currentStep), 距离（内部单位）：\(totalDistanceUnit), 卡路里（内部单位）：\(calorieUnit)")
    }

    /// 获取格式化后的距离值（公里）
    /// - Returns: 距离值（单位：公里）
    public func getFormattedDistance() -> Float {
        return Float(currentDistance) / 100000
    }

    /// 获取格式化后的卡路里值（千卡）
    /// - Returns: 卡路里值（单位：千卡）
    public func getFormattedCalorie() -> Float {
        let truncated = (Float(currentCalorie) / 10000).rounded(.towardZero) / 1000
        return Float(truncated)
    }

    public var functioncontrolflags: Int = 0 // [0] 是否⽀持表盘市场 [1] 是否⽀持消息提醒 [2] 是否⽀持天⽓功能 等
    public var healthcontrolflags: Int = 0 // [0] 是否⽀持⼼率检测 [1] 是否⽀持⾎氧检测 等
    public var screenBrightness: Int = 0 // 屏幕亮度 0-100级
    
    // 开关类
    public var isAntilostSwitch: Bool = false // 防丢开关
    public var isRaisehandtobrightenscreen: Bool = false // 抬⼿亮屏开关
    public var isAutoSyncSwitch: Bool = false // ⾃动同步开关
    public var isSleepmonitoringSwitch: Bool = false // Sleep monitoring Switch
    public var isMessageremindermainswitch: Bool = false // 消息提醒总开关
    public var isRegularexercisedatauploadswitch: Bool = false // 整点上传运动数据开关
    public var isGoalachievementswitch: Bool = false // ⽬标达成开关
    public var isMessagescreendisplayswitch: Bool = false // 消息提醒亮屏开关
    public var isSoundswitch: Bool = false // 声⾳开关
    public var isVibrationswitch: Bool = false // 震动总开关
    public var isRegularhealthdatauploadswitch: Bool = false // 整点上传健康数据开关
    public var isMessagevibrationswitch: Bool = false // 消息提醒震动开关
    
    // 通知类
    public var isNullMessage: Bool = true // 五消息
    public var isIncomingCall: Bool = false // 来电
    public var isMissedCall: Bool = false // 未接来电
    public var isMessages: Bool = true // 短信
    public var isEmail: Bool = true // 邮件
    public var isSchedule: Bool = true // ⽇程
    public var isFacetime: Bool = true // Facetime
    public var isQQ: Bool = true // qq
    public var isSkype: Bool = true // Skype
    public var isWechat: Bool = true // Wechat
    public var isWhatsapp: Bool = true // Whatsapp
    public var isGmail: Bool = true // Gmail
    public var isHangout: Bool = true // Hangout
    public var isInbox: Bool = true // Inbox
    public var isLine: Bool = true // Line
    public var isTwitter: Bool = true
    public var isFacebook: Bool = true
    public var isFacebookMessenger: Bool = true
    public var isInstagram: Bool = true
    public var isWeibo: Bool = true
    public var isKakaotalk: Bool = true
    public var isFacebookpagemanager: Bool = true
    public var isViber: Bool = true
    public var isVkclient: Bool = true
    public var isTelegram: Bool = true
    public var isSnapchat: Bool = true
    public var isDingTalk: Bool = true
    public var isAlipay: Bool = true
    public var isTiktok: Bool = true
    public var isLinkedIn: Bool = true
    
    
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
    public static func loadFromSandbox(mac: String) -> BluetoothWatchDevice? {
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
    public static func loadFromSandbox(deviceName: String) -> BluetoothWatchDevice? {
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

    public static func deleteFromSandbox(mac: String) {
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
    public static func loadAll() {
        XGZTDeviceManager.shared.reloadDevices()
    }
}
