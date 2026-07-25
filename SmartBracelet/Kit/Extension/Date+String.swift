//
//  WUDateExt.swift
//  Coredy
//
//  Created by WuJunjie on 2017/11/27.
//  Copyright © 2017年 WuJunjie. All rights reserved.
//

import Foundation

extension Date {
    func stringFromYmdHmsSSS() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss SSS"
        return dateFormatter.string(from: self)
    }
    
    func stringFromYmdHms() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        return dateFormatter.string(from: self)
    }
    
    func stringFromYmdHm() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        return dateFormatter.string(from: self)
    }
    
    func stringFromYmd() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        return dateFormatter.string(from: self)
    }
    
    func stringFromYm() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        
        return dateFormatter.string(from: self)
    }
    
    func stringFromMd() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd"
        
        return dateFormatter.string(from: self)
    }
    
    func stringFromHms() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        
        return dateFormatter.string(from: self)
    }
    
    func stringFromHm() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        return dateFormatter.string(from: self)
    }
    
    func stringFromH() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH"
        
        return dateFormatter.string(from: self)
    }
    
    /// 一天的最初时刻
    func zeroTimeStamp() -> TimeInterval {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: self)
        let zeroDate = calendar.date(from: components)
        return zeroDate?.timeIntervalSince1970 ?? 0
    }
    
    /// 一天的最后时刻
    func lastTimeStamp() -> TimeInterval {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: self)
        let zeroDate = calendar.date(from: components)
        return (zeroDate?.timeIntervalSince1970 ?? 0 + 24 * 60 * 60 - 1)
    }
    
    /// 一天的最初时刻（UTC 时区的 00:00:00）
    func zeroTimeStampUTC() -> TimeInterval {
        // 强制使用 UTC 时区，而非本地时区
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        
        // 只保留 UTC 时区的 年、月、日 组件（忽略时分秒）
        let components = calendar.dateComponents([.year, .month, .day], from: self)
        // 生成 UTC 时区的当天 00:00:00
        let zeroDateUTC = calendar.date(from: components)
        return zeroDateUTC?.timeIntervalSince1970 ?? 0
    }
    
    /// 一天的最后时刻（UTC 时区的 23:59:59）
    func lastTimeStampUTC() -> TimeInterval {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        
        let components = calendar.dateComponents([.year, .month, .day], from: self)
        guard let zeroDateUTC = calendar.date(from: components) else {
            return 0
        }
        // 修复运算符优先级问题，正确计算 23:59:59
        return zeroDateUTC.timeIntervalSince1970 + 24 * 60 * 60 - 1
    }
    
    func daysBetweenDate(toDate: Date) -> Int {
        let components = Calendar.current.dateComponents([.day], from: self, to: toDate)
        return components.day ?? 0
    }
    
    func isToday() -> Bool {
        let calendar = Calendar.current
        return calendar.isDateInToday(self)
    }
}

class DateHelper: NSObject {
    func ymdToDate(value: String) -> Date? {
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd"
        return format.date(from: value)
    }
    
    
    func ymdToDate(y: Int, m: Int, d: Int) -> Date {
        let str = "\(y)-\(String(format: "%02d", m))-\(String(format: "%02d", d)) 00:00:00"
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return format.date(from: str)!
    }
    
    func ymdHmsToDate(y: Int, m: Int, d: Int, h: Int, m2: Int, s: Int) -> Int {
        let str = "\(y)-\(String(format: "%02d", m))-\(String(format: "%02d", d)) \(String(format: "%02d", h)):\(String(format: "%02d", m2)):\(String(format: "%02d", s))"
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let data = format.date(from: str)!
        return Int(data.timeIntervalSince1970)
    }
}

extension Date {
    func secondFromDate() -> Int {
        let second = self.timeIntervalSince1970
        return Int(second)
    }
    
    func distance(_ date: Date) -> Int {
        let second = self.timeIntervalSince(date)
        return Int(second)/(3600 * 24)
    }
    
    func isInCurrent(_ date: Date) -> Bool {
        let start = WUCalendarManager.gregorian().date(bySettingHour: 0, minute: 0, second: 0, of: date)!
        let end = WUCalendarManager.gregorian().date(bySettingHour: 23, minute: 59, second: 59, of: date)!
        return (self.compare(start) != ComparisonResult.orderedAscending) && (self.compare(end) != ComparisonResult.orderedDescending)
    }
}
