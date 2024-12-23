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
            NotificationCenter.default.post(name: Notification.Name.SearchDevice, object: "connected_xgzt") // 通知搜索页面
            NotificationCenter.default.post(name: Notification.Name("MTabBarController"), object: nil) // 通知主控页面
            Async.main(after: 0.5) {
                NotificationCenter.default.post(name: Notification.Name("DevicesViewController"), object: "1")
            }
            
            let delayTime = DispatchTime.now() + .milliseconds(300)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                // 这里是你想要延迟执行的代码
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
    func syncDevcieInfo() {
        // 1.绑定设备
        XGZTCommand.bindDevice()
        // 2.设置时间
        // 获取当前的时区信息
        let currentTimeZone = TimeZone.current
        let timeZoneOffsetInSeconds = currentTimeZone.secondsFromGMT()
        let timeZoneOffsetInHours = timeZoneOffsetInSeconds / 3600

        // 获取当前的 UTC 时间
        let now = Date()
        let utcTimeInterval = now.timeIntervalSince1970
        let utc = UInt32(utcTimeInterval)
        XGZTCommand.syncTime(timeZone: timeZoneOffsetInHours, utc: utc)
        // 3.同步语言
        XGZTCommand.getDeviceLanguage(language: 1)
        // 4. 获取步数
        
        // 7. 
    }
}
