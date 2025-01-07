//
//  WUCalendarManager.swift
//  WearfitPlus
//
//  Created by WuJunjie on 2017/1/10.
//  Copyright © 2017年 WuJunjie. All rights reserved.
//

import UIKit
import TJDWristbandSDK

enum WUCalendarType: Int {
    case day = 0, week, month
}

class WUCalendarManager: NSObject {
    
    class func current() -> Calendar {
        var calendar = Calendar.current
        calendar.locale = Locale.current
        calendar.timeZone = TimeZone.current
        return calendar
    }
    
    class func gregorian() -> Calendar {
        var calendar = Calendar.init(identifier: Calendar.Identifier.gregorian)
        calendar.locale = Locale.current
        calendar.timeZone = TimeZone.current
        return calendar
    }
    
    class func startDay() -> Date {
        let wdate = WUDate()
        wdate.year = 2017
        wdate.month = 1
        wdate.day = 1
        wdate.hour = 0
        wdate.minute = 0
        wdate.second = 0
        return wdate.gregorianDate()
    }
    
    /// - Parameters:
    ///   - numOfDay: 距离今天的天数
    ///   - date: 今天
    /// - Returns: 返回偏移后的日期
    class func add(numOfDay:Int, date:Date) -> Date {
        var comps = DateComponents()
        comps.day = numOfDay
        return WUCalendarManager.gregorian().date(byAdding: comps, to: date)!
    }
    
    /// - Parameters:
    ///   - numOfWeek: 距离今天的周数
    ///   - date: 今天
    /// - Returns: 返回偏移后的日期
    class func add(numOfWeek:Int, date:Date) -> Date {
        var comps = DateComponents()
        comps.weekOfYear = numOfWeek
        return WUCalendarManager.gregorian().date(byAdding: comps, to: date)!
    }
    
    /// - Parameters:
    ///   - numOfMonth: 距离今天的月数
    ///   - date: 今天
    /// - Returns: 返回偏移后的日期
    class func add(numOfMonth:Int, date:Date) -> Date {
        var comps = DateComponents()
        comps.month = numOfMonth
        return WUCalendarManager.gregorian().date(byAdding: comps, to: date)!
    }

    /// - Parameter index: 第几天
    /// - Returns: 距离今天的第几天的那一天
    class func firstDayOfDay(index:Int) -> Date {
        return add(numOfDay: -index, date: Date())
    }
    
    /// - Parameter index: 第几周
    /// - Returns: 距离今天的第几周的第一天 每周的星期一
    class func firstDayOfWeek(index:Int) -> Date {
        let weekday = weekdayOfToday()
        let date = add(numOfDay: 1 - weekday, date: Date())
        return add(numOfWeek: -index, date: date)
    }
    
    /// - Parameter index: 第几月
    /// - Returns: 距离今天的第几月的第一天 如1月1日
    class func firstDayOfMonth(index:Int) -> Date {
        let dayInMonth = daysInMonthOf(Date())
        let date = add(numOfDay: 1 - dayInMonth, date: Date())
        return add(numOfMonth: -index, date: date)
    }
    
    /// - Returns: 返回星期几 星期一为1，星期天为7
    class func weekdayOfToday() -> Int {
        let comps = WUCalendarManager.gregorian().dateComponents([.weekday], from: Date())
        let weekday = comps.weekday!
        if weekday == 1 {
            return 7
        }
        return weekday - 1
    }
    
//    /// - Returns: 今天是几号
//    class func dayInMonthOfToday() -> Int {
//        let comps = CalendarManager.gregorian().dateComponents([.day], from: Date())
//        return comps.day!
//    }
    
    /// - Parameter date: 时间
    /// - Returns: 时间 是几号
    class func daysInMonthOf(_ date:Date) -> Int {
        let comps = WUCalendarManager.gregorian().dateComponents([.day], from: date)
        return comps.day!
    }
    
    /// - Returns: 参考日期到今天总天数
    class func allDays() -> Int {
        let comps = WUCalendarManager.gregorian().dateComponents([.day], from: startDay(), to: Date())
        return comps.day!
    }
    
    /// - Returns: 参考日期到今天总周数
    class func allWeeks() -> Int {
        let comps = WUCalendarManager.gregorian().dateComponents([.weekOfYear], from: startDay(), to: Date())
        return comps.weekOfYear!
    }
    
    /// - Returns: 参考日期到今天总月数
    class func allMonths() -> Int {
        let comps = WUCalendarManager.gregorian().dateComponents([.month], from: startDay(), to: Date())
        return comps.month!
    }
    
    class func chinaWeekday(_ date: Date) -> Int {
        var weekday = WUCalendarManager.gregorian().component(Calendar.Component.weekday, from: date)
        if weekday == 1 {
            weekday = 7
        }
        else {
            weekday = weekday - 1
        }
        return weekday
    }

    /// - Parameter date:
    /// - Returns: date所在的月共有多少天
    class func countInMonth(_ date:Date) -> Int {
        let comps = WUCalendarManager.gregorian().dateComponents([.day], from: date, to: add(numOfMonth: 1, date: date))
        return comps.day!
    }
    
    
    /// 得到所有日期
    ///
    /// - Parameter type: WUCalendarType
    /// - Returns: Array<Date>
    class func dataSource(type: WUCalendarType) -> Array<Date> {
        var count = 0
        var array = [Date]()
        switch type {
        case .day:
            count = allDays()
            for i in 0..<count {
                let date = firstDayOfDay(index: i)
                array.append(date)
            }
            return array
        case .week:
            count = allWeeks()
            for i in 0..<count {
                let date = firstDayOfWeek(index: i)
                array.append(date)
            }
            return array
        case .month:
            count = allMonths()
            for i in 0..<count {
                let date = firstDayOfMonth(index: i)
                array.append(date)
            }
            return array
        }
    }
}
