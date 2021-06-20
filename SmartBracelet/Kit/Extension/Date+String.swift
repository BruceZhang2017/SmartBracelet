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
    func ymdToDate(value: String) -> Date {
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd"
        return format.date(from: value)!
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
