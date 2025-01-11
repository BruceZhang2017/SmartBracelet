//
//  XGZTBusinessHandler.swift
//  SmartBracelet
//
//  Created by anker on 2024/11/30.
//  Copyright © 2024 tjd. All rights reserved.
//

import Foundation

class XGZTBusinessHandler {
    
    func handleConnected() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name("HealthVCLoading"), object: 1000)
            NotificationCenter.default.post(name: Notification.Name.SearchDevice, object: "connected_xgzt") // 通知搜索页面
            NotificationCenter.default.post(name: Notification.Name("MTabBarController"), object: nil) // 通知主控页面
            Async.main(after: 0.5) {
                NotificationCenter.default.post(name: Notification.Name("DevicesViewController"), object: "1")
            }
            
            let delayTime = DispatchTime.now() + .milliseconds(300)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                // 这里是你想要延迟执行的代码
                XGZTCommand.setAppInfo(phoneType: 1)
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
        XGZTCommand.bindDevice()
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
        XGZTCommand.syncTime(timeZone: timeZoneOffsetInHours, utc: utc)
        // 3.同步语言
        XGZTCommand.getDeviceLanguage(language: getLanguageCode())
        // 4. 获取步数
        XGZTCommand.getNewestHealthData(type: 0)
        // 5. 获取心率
        XGZTCommand.getNewestHeartData(type: 0)
        
        var delayTime = DispatchTime.now() + .milliseconds(100)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            XGZTCommand.getNewestHeartData(type: 1)
        }
        
        delayTime = DispatchTime.now() + .milliseconds(200)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            XGZTCommand.getNewestHeartData(type: 2)
        }
        
        // 6. 获取历史步数
        delayTime = DispatchTime.now() + .milliseconds(300)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            XGZTCommand.getStepData()
        }
        // 7. 获取历史睡眠
        delayTime = DispatchTime.now() + .milliseconds(400)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            XGZTCommand.getHistorySleepData()
        }
        
        
        delayTime = DispatchTime.now() + .milliseconds(500)
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
            "uk": 0x17         // Ukrainian
        ]

        guard let preferredLanguage = Locale.preferredLanguages.first else {
            return 0x00 // Default to English if no preferred language is found
        }

        let locale = Locale(identifier: preferredLanguage)

        if let languageCode = locale.languageCode {
            var identifier = languageCode

            // Append script code if available (e.g., zh-Hans for Simplified Chinese)
            if let scriptCode = locale.scriptCode {
                identifier += "-" + scriptCode
            }

            // Attempt to match the full identifier (language-script)
            if let code = languageMap[identifier] {
                return code
            }

            // If no match, attempt to match using only the language code
            if let code = languageMap[languageCode] {
                return code
            }
        }

        // Default to English if no match is found
        return 0x00
    }
}
