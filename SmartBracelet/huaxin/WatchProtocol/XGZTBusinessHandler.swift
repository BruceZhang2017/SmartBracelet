//
//  XGZTBusinessHandler.swift
//  SmartBracelet
//
//  Created by anker on 2024/11/30.
//  Copyright © 2024 tjd. All rights reserved.
//

import Foundation

// MARK: - 全局变量已迁移到 XGZTCommandStateManager
// 这些全局变量已被线程安全的管理器替代，详见 XGZTCommandStateManager.swift

class XGZTBusinessHandler: NSObject {
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotif(_:)), name: Notification.Name("XGZTBusinessHandler"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleNotif(_ notification: Notification) {
        let obj = notification.object as? String ?? ""
        if obj == "1" {
            set5D()
        } else if obj == "2" {
            readDeviceInfo()
        } else if obj == "3" {
            readDeviceInfo2()
        } else if obj == "4" {
            readDeviceInfo3()
        } else if obj == "5" {
            readDeviceInfo4()
        } else if obj == "6" {
            readDeviceInfo5()
        } else if obj == "7" {
            readDeviceInfo6()
        } else if obj == "8" {
            readDeviceInfo7()
        } else if obj == "9" {
            readDeviceInfo8()
        } else if obj == "10" {
            readDeviceInfo9()
        } else if obj == "11" {
            readDeviceInfo10()
        } else if obj == "12" {
            readDeviceInfo11()
        } else if obj == "13" {
            readDeviceInfo12()
        } else if obj == "14" {
            readDeviceInfo13()
        } else if obj == "15" {
            readDeviceInfo14()
        } else if obj == "16" {
            readDeviceInfo15()
        } else if obj == "17" {
            syncDevcieInfo2()
        } else if obj == "18" {
            readDeviceInfo17()
        }
    }
    
    func handleConnected() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name("HealthVCLoading"), object: 1000)
            NotificationCenter.default.post(name: Notification.Name.SearchDevice, object: "connected_xgzt") // 通知搜索页面
            NotificationCenter.default.post(name: Notification.Name("MTabBarController"), object: nil) // 通知主控页面
            Async.main(after: 0.5) {
                NotificationCenter.default.post(name: Notification.Name("DevicesViewController"), object: "1")
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.syncDevcieInfo()
            }
        }
        // 标记XGZT设备已连接（MAC地址由连接层设置）
        XGZTConnectionStateManager.shared.setDeviceType(.xgzt)
    }
    
    func handleDisconnected() {
        // 标记设备已断开（但不清除MAC，以便重连）
        XGZTConnectionStateManager.shared.markDisconnected(clearMac: false)
        // 清理指令状态
        XGZTCommandStateManager.shared.handleDisconnected()

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name("UploadImageViewController"), object: nil)
            Async.main(after: 0.5) {
                NotificationCenter.default.post(name: Notification.Name("DevicesViewController"), object: "1")
            }
            NotificationCenter.default.post(name: Notification.Name("MTabBarController"), object: "disconnect")

        }

    }
    
    // 设备同步信息
    public func syncDevcieInfo() {
        // 1.绑定设备
        XGZTCommand.bindDevice(value: 0)
        XGZTCommandStateManager.shared.setCommandPending(.bind81)

        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            if !XGZTCommandStateManager.shared.isCommandPending(.bind81) {
                return
            }
            XGZTCommand.bindDevice(value: 0)
            let mac = XGZTConnectionStateManager.shared.lastDeviceMac
            XGZTDeviceManager.shared.appendFailMessage("[\(mac)]指令故障:嵌入式未回复指令81")
        }
    }
    
    public func syncDevcieInfo2() {
        XGZTCommand.bindDevice(value: 1)
        XGZTCommandStateManager.shared.setCommandPending(.bind82)

        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            if !XGZTCommandStateManager.shared.isCommandPending(.bind82) {
                return
            }
            XGZTCommand.bindDevice(value: 1)
            let mac = XGZTConnectionStateManager.shared.lastDeviceMac
            XGZTDeviceManager.shared.appendFailMessage("[\(mac)]指令故障:嵌入式未回复指令82")
        }
    }
    
    private func set5D() {
        XGZTCommand.setAppInfo(phoneType: 1)
        XGZTCommandStateManager.shared.setCommandPending(.setAppInfo5D)

        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            if !XGZTCommandStateManager.shared.isCommandPending(.setAppInfo5D) {
                return
            }
            XGZTCommand.setAppInfo(phoneType: 1)
            let mac = XGZTConnectionStateManager.shared.lastDeviceMac
            XGZTDeviceManager.shared.appendFailMessage("[\(mac)]指令故障:嵌入式未回复指令5d")
        }
    }
    
    private func readDeviceInfo2() {
        if !XGZTCommandStateManager.shared.isDeviceReading {
            return
        }
        XGZTCommand.getNewestHealthData(type: 0)

        // 4. 获取步数
    }
    
    private func readDeviceInfo3() {
        if !XGZTCommandStateManager.shared.isDeviceReading {
            return
        }
        XGZTCommand.getNewestHeartData(type: 0)
        // 5. 获取心率
    }
    
    private func readDeviceInfo4() {
        if !XGZTCommandStateManager.shared.isDeviceReading {
            return
        }
        // 6. 获取血氧
        XGZTCommand.getNewestHeartData(type: 1)
    }
    
    private func readDeviceInfo5() {
        if !XGZTCommandStateManager.shared.isDeviceReading {
            return
        }
        // 7.获取血压
        XGZTCommand.getNewestHeartData(type: 2)
    }
    
    private func readDeviceInfo6() {
        if !XGZTCommandStateManager.shared.isDeviceReading {
            return
        }
        // 8. 获取历史步数
        XGZTCommand.getStepData()
    }
    
    private func readDeviceInfo7() {
        if !XGZTCommandStateManager.shared.isDeviceReading {
            return
        }
        XGZTCommand.getSleepMonitoring() // 9.获取当天的睡眠数据
    }
    
    private func readDeviceInfo8() {
        if !XGZTCommandStateManager.shared.isDeviceReading {
            return
        }
        XGZTCommand.getHistorySleepData()
        // 10. 获取历史睡眠
    }
    
    private func readDeviceInfo9() {
        if !XGZTCommandStateManager.shared.isDeviceReading {
            return
        }
        XGZTCommand.getSwitchStatus()
    }
    
    private func readDeviceInfo10() {
        if !XGZTCommandStateManager.shared.isDeviceReading {
            return
        }
        XGZTCommand.getSwitchTableExtension()
    }
    
    private func readDeviceInfo11() {
        if !XGZTCommandStateManager.shared.isDeviceReading {
            return
        }
        XGZTCommand.getReminderInfo(eventType: 0)
    }
    
    private func readDeviceInfo12() {
        if !XGZTCommandStateManager.shared.isDeviceReading {
            return
        }
        XGZTCommand.getReminderInfo(eventType: 1)
    }
    
    private func readDeviceInfo13() {
        if !XGZTCommandStateManager.shared.isDeviceReading {
            return
        }
        XGZTCommand.get12H24HTimeFormat()
    }
    
    private func readDeviceInfo14() {
        if !XGZTCommandStateManager.shared.isDeviceReading {
            return
        }
        XGZTCommand.getDeviceUnitFormat()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(name: Notification.Name("DeviceSettings"), object: 200)
        }
    }
    
    private func readDeviceInfo15() {
        if !XGZTCommandStateManager.shared.isDeviceReading {
            return
        }
        let code = getLanguageCode()
        XGZTCommand.getDeviceLanguage(language: code)
    }
    
    private func readDeviceInfo17() {
        XGZTCommandStateManager.shared.stopDeviceReading()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XGZTCommand.getDeviceInfo()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            [weak self] in
            self?.setANCS()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(name: Notification.Name("HealthVCLoading"), object: 2000)
        }
    }
    
    public func readDeviceInfo() {
        XGZTCommandStateManager.shared.startDeviceReading()

        // 2.设置时间
        // 获取当前的 UTC 时间
        let now = Date()
        let utcTimeInterval = now.timeIntervalSince1970
        let utc = UInt32(utcTimeInterval)
        let offset = TimeZone.current.secondsFromGMT(for: now)
        let correctedUtc = Int64(utc) + Int64(offset)
        XLogger.shared.log("同步时间：\(correctedUtc) -- \(12)")
        XGZTCommand.syncTime(timeZone: 12, utc: UInt32(correctedUtc))

    }
    
    private func setANCS() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            guard let device = XGZTBlueToothManager.shared.device else {
                return
            }
            var p0: UInt8 = 0
            var p1: UInt8 = 0
            var p2: UInt8 = 0
            var p3: UInt8 = 0
            p0 |= 1 << 0
            p0 |= device.isIncomingCall ? 1 << 1 : 0
            p0 |= 1 << 2
            p0 |= 1 << 3
            p0 |= 1 << 4
            p0 |= 1 << 5
            p0 |= 1 << 6
            p0 |= 1 << 7

            // 处理 response[8]
            p1 |= 1 << 0
            p1 |= 1 << 1
            p1 |= 1 << 2
            p1 |= 1 << 3
            p1 |= 1 << 4
            p1 |= 1 << 5
            p1 |= 1 << 6
            p1 |= 1 << 7
            
            // 处理 response[9]
            p2 |= 1 << 0
            p2 |= 1 << 1
            p2 |= 1 << 2
            p2 |= 1 << 3
            p2 |= 1 << 4
            p2 |= 1 << 5
            p2 |= 1 << 6
            p2 |= 1 << 7
            
            // 处理 response[9]
            p3 |= 1 << 0
            p3 |= 1 << 2
            p3 |= 1 << 3
            p3 |= 1 << 4
            p3 |= 1 << 5
            p3 |= 1 << 6
            
            XGZTCommand.setSwitchTableExtension(p0: p0, p1: p1, p2: p2, p3: p3)
        }
    }
    
    
    private func getLanguageCode() -> Int {
        let languageMap: [String: Int] = [
            "en": 0x00,        // English
            "zh-Hans": 0x01,   // Simplified Chinese
            "it": 0x02,        // Italian
            "es": 0x03,        // Spanish
            "pt": 0x04,        // Portuguese
            "ru": 0x05,        // Russian
            "ja": 0x06,        // Japanese
            "zh-Hant": 0x07,   // Traditional Chinese
            "de": 0x08,        // German
            "ko": 0x09,        // Korean
            "th": 0x0a,        // Thai
            "ar": 0x0b,        // Arabic
            "tr": 0x0c,        // Turkish
            "fr": 0x0d,        // French
            "vi": 0x0e,        // Vietnamese
            "pl": 0x0f,        // Polish
            "nl": 0x10,        // Dutch
            "he": 0x11,        // Hebrew
            "fa": 0x12,        // Persian
            "el": 0x13,        // Greek
            "ms": 0x14,        // Malay
            "my": 0x15,        // Burmese
            "da": 0x16,        // Danish
            "uk": 0x17,        // Ukrainian
            "sv": 0x18,        // Swedish
            
            // 新增语言条目
            "id": 0x19,        // Indonesian
            "cs": 0x1a,        // Czech
            "hu": 0x1b,        // Hungarian
            "ro": 0x1c,        // Romanian
            "bg": 0x1d,        // Bulgarian
            "hr": 0x1e,        // Croatian
            "sk": 0x1f,        // Slovak
            "sl": 0x20,        // Slovenian
            "lv": 0x21,        // Latvian
            "lt": 0x22,        // Lithuanian
            "fi": 0x23,        // Finnish
            "no": 0x24,        // Norwegian
            "et": 0x25,        // Estonian
            "is": 0x26         // Icelandic
        ]
        
        guard let preferredLanguage = Locale.preferredLanguages.first else {
            return 0x00 // 默认返回英语编码
        }
        
        let locale = Locale(identifier: preferredLanguage)
        
        if let languageCode = locale.languageCode {
            var identifier = languageCode
            
            // 若存在脚本代码（如zh-Hans），合并到标识符中
            if let scriptCode = locale.scriptCode {
                identifier += "-" + scriptCode
            }
            
            // 先尝试匹配完整的语言-脚本标识符（如"zh-Hans"）
            if let code = languageMap[identifier] {
                return code
            }
            
            // 若未匹配成功，则仅使用语言代码匹配（如"zh"）
            if let code = languageMap[languageCode] {
                return code
            }
        }
        
        // 若所有尝试均失败，返回默认值英语编码
        return 0x00
    }
}
