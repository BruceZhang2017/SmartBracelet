//
//  XGZTBusinessHandler.swift
//  SmartBracelet
//
//  Created by anker on 2024/11/30.
//  Copyright © 2024 tjd. All rights reserved.
//

import Foundation

var Bind_first = false // 是否为首次绑定
var flag_81 = false
var flag_5d = false // 5d指令是否成功

class XGZTBusinessHandler {
    
    func handleConnected() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name("HealthVCLoading"), object: 1000)
            NotificationCenter.default.post(name: Notification.Name.SearchDevice, object: "connected_xgzt") // 通知搜索页面
            NotificationCenter.default.post(name: Notification.Name("MTabBarController"), object: nil) // 通知主控页面
            Async.main(after: 0.5) {
                NotificationCenter.default.post(name: Notification.Name("DevicesViewController"), object: "1")
            }
            
            var delayTime = DispatchTime.now() + .milliseconds(300)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                self.syncDevcieInfo()
            }
        }
        isXGZT = true 
    }
    
    func handleDisconnected() {
        isXGZT = false
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
        var delayTime = DispatchTime.now() + .milliseconds(30)
        // 2.设置时间
        // 获取当前的时区信息
        let currentTimeZone = TimeZone.current
        let timeZoneOffsetInSeconds = currentTimeZone.secondsFromGMT()
        var timeZoneOffsetInHours = timeZoneOffsetInSeconds / 3600
        if timeZoneOffsetInSeconds >= 0 {
            timeZoneOffsetInHours = 12 + timeZoneOffsetInHours
        } else {
            timeZoneOffsetInHours = 12 - timeZoneOffsetInHours
        }

        // 获取当前的 UTC 时间
        let now = Date()
        let utcTimeInterval = now.timeIntervalSince1970
        let utc = UInt32(utcTimeInterval)
        print("同步时间：\(utc) -- \(timeZoneOffsetInHours)")
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            XGZTCommand.syncTime(timeZone: timeZoneOffsetInHours, utc: utc)
        }
        
        delayTime = DispatchTime.now() + .milliseconds(60)
        // 3.同步语言
        let code = getLanguageCode()
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            XGZTCommand.getDeviceLanguage(language: code)
        }
        // 4. 获取步数
        delayTime = DispatchTime.now() + .milliseconds(90)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            XGZTCommand.getNewestHealthData(type: 0)
        }
        // 5. 获取心率
        delayTime = DispatchTime.now() + .milliseconds(120)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            XGZTCommand.getNewestHeartData(type: 0)
        }
        
        delayTime = DispatchTime.now() + .milliseconds(150)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            XGZTCommand.getNewestHeartData(type: 1)
        }
        
        delayTime = DispatchTime.now() + .milliseconds(200)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            XGZTCommand.getNewestHeartData(type: 2)
        }
        
        // 6. 获取历史步数
        delayTime = DispatchTime.now() + .milliseconds(250)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            XGZTCommand.getStepData()
        }
        delayTime = DispatchTime.now() + .milliseconds(300)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            XGZTCommand.getSleepMonitoring() // 获取当天的睡眠数据
        }
        // 7. 获取历史睡眠
        delayTime = DispatchTime.now() + .milliseconds(350)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            XGZTCommand.getHistorySleepData()
        }
        
        delayTime = DispatchTime.now() + .milliseconds(450)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            XGZTCommand.get12H24HTimeFormat()
            XGZTCommand.getDeviceUnitFormat()
            NotificationCenter.default.post(name: Notification.Name("DeviceSettings"), object: 200)
        }
        
        delayTime = DispatchTime.now() + .milliseconds(500)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            XGZTCommand.syncTime(timeZone: timeZoneOffsetInHours, utc: utc)
        }
        
        delayTime = DispatchTime.now() + .milliseconds(550)
        let code2 = getLanguageCode()
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            XGZTCommand.getDeviceLanguage(language: code2)
        }
        
        delayTime = DispatchTime.now() + .milliseconds(2000)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            XGZTCommand.bindDevice(value: 1)
            flag_81 = true
        }
        
        delayTime = DispatchTime.now() + .milliseconds(3000)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            // 这里是你想要延迟执行的代码
            XGZTCommand.setAppInfo(phoneType: 1)
            flag_5d = true
        }
        
        delayTime = DispatchTime.now() + .milliseconds(3500)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            if !flag_81 {
                return
            }
            XGZTCommand.bindDevice(value: 1)
        }
        
        delayTime = DispatchTime.now() + .milliseconds(4000)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            if !flag_5d {
                return
            }
            XGZTCommand.setAppInfo(phoneType: 1)
        }
        delayTime = DispatchTime.now() + .milliseconds(4500)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            if !flag_81 {
                return
            }
            XGZTCommand.bindDevice(value: 1)
        }
        delayTime = DispatchTime.now() + .milliseconds(5000)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            if !flag_5d {
                return
            }
            XGZTCommand.setAppInfo(phoneType: 1)
        }
        delayTime = DispatchTime.now() + .milliseconds(5500)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            if !flag_81 {
                return
            }
            XGZTCommand.bindDevice(value: 1)
        }
        delayTime = DispatchTime.now() + .milliseconds(6000)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            if !flag_5d {
                return
            }
            XGZTCommand.setAppInfo(phoneType: 1)
        }
        delayTime = DispatchTime.now() + .milliseconds(7000)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            if !flag_5d {
                return
            }
            XGZTCommand.setAppInfo(phoneType: 1)
        }
        delayTime = DispatchTime.now() + .milliseconds(7500)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            XGZTCommand.getDeviceInfo()
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
