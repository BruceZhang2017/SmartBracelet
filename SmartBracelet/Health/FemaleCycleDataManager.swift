//
// Copyright © 2015-2018 bruce Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
//
//  FemaleCycleDataManager.swift
//  SmartBracelet
//
//  Created by bruce on 2025/12/11.
//  Copyright © 2025 tjd. All rights reserved.
//

import Foundation

// MARK: - 日期症状数据模型

struct DailySymptomData: Codable {
    var date: String // 格式: yyyy-MM-dd
    var isPeriodStarted: Bool
    var flowLevel: Int // 0=未选择, 1=少, 2=中, 3=多
    var painLevel: Int // 0=未选择, 1=轻微, 2=中等, 3=严重
    var sexualActivity: Int // 0=无, 1=保护性行为, 2=无保护性行为
    var mood: Int // 0=未选择, 1=平静, 2=开心, 3=放松, 4=活力满满, 5=敏感, 6=焦躁, 7=易怒, 8=悲伤
    var bodySymptoms: [String] // 身体症状列表（格式：分类-症状）

    init(date: String) {
        self.date = date
        self.isPeriodStarted = false
        self.flowLevel = 0
        self.painLevel = 0
        self.sexualActivity = 0
        self.mood = 0
        self.bodySymptoms = []
    }
}

// MARK: - 周期配置数据模型

struct CycleConfiguration: Codable {
    var periodDays: Int // 经期天数
    var cycleLength: Int // 周期长度
    var lastPeriodDate: Date // 最后一次经期开始日期
    var isConfigured: Bool // 是否已由用户配置过

    init(periodDays: Int = 7, cycleLength: Int = 28, lastPeriodDate: Date = Date(), isConfigured: Bool = false) {
        self.periodDays = periodDays
        self.cycleLength = cycleLength
        self.lastPeriodDate = lastPeriodDate
        self.isConfigured = isConfigured
    }
}

// MARK: - 数据变更通知

extension Notification.Name {
    static let femaleCycleDataDidChange = Notification.Name("FemaleCycleDataDidChange")
    static let cycleConfigurationDidChange = Notification.Name("CycleConfigurationDidChange")
}

// MARK: - 生理周期数据管理器

class FemaleCycleDataManager {

    // MARK: - 单例

    static let shared = FemaleCycleDataManager()

    private init() {
        loadAllData()
    }

    // MARK: - 属性

    // 周期配置
    private(set) var cycleConfig: CycleConfiguration = CycleConfiguration()

    // 每日症状数据字典，key为日期字符串（yyyy-MM-dd）
    private var dailyDataDict: [String: DailySymptomData] = [:]

    // 日期格式化器
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    // MARK: - 存储键

    private let cycleConfigKey = "FemaleCycle_Configuration"
    private let dailyDataKey = "FemaleCycle_DailyData"

    // MARK: - 数据加载

    private func loadAllData() {
        // 加载周期配置
        if let data = UserDefaults.standard.data(forKey: cycleConfigKey),
           let config = try? JSONDecoder().decode(CycleConfiguration.self, from: data) {
            cycleConfig = config
        } else {
            // 兼容旧数据
            let periodDays = UserDefaults.standard.integer(forKey: "FemaleHealth_PeriodDays")
            let cycleLength = UserDefaults.standard.integer(forKey: "FemaleHealth_CycleLength")
            let lastPeriodDateTimestamp = UserDefaults.standard.double(forKey: "FemaleHealth_LastPeriodDate")

            cycleConfig = CycleConfiguration(
                periodDays: periodDays > 0 ? periodDays : 7,
                cycleLength: cycleLength > 0 ? cycleLength : 28,
                lastPeriodDate: lastPeriodDateTimestamp > 0 ? Date(timeIntervalSince1970: lastPeriodDateTimestamp) : Date()
            )
        }

        // 加载每日数据
        if let data = UserDefaults.standard.data(forKey: dailyDataKey),
           let dict = try? JSONDecoder().decode([String: DailySymptomData].self, from: data) {
            dailyDataDict = dict
        }
    }

    // MARK: - 数据保存

    private func saveAllData() {
        // 保存周期配置
        if let data = try? JSONEncoder().encode(cycleConfig) {
            UserDefaults.standard.set(data, forKey: cycleConfigKey)
        }

        // 保存每日数据
        if let data = try? JSONEncoder().encode(dailyDataDict) {
            UserDefaults.standard.set(data, forKey: dailyDataKey)
        }

        // 同步到磁盘
        UserDefaults.standard.synchronize()

        XLogger.shared.log("数据已保存 - 周期配置: \(cycleConfig), 每日数据条数: \(dailyDataDict.count)")
    }

    // MARK: - 周期配置管理

    /// 更新周期配置
    func updateCycleConfiguration(periodDays: Int? = nil, cycleLength: Int? = nil, lastPeriodDate: Date? = nil) {
        var hasChanges = false

        if let periodDays = periodDays, periodDays != cycleConfig.periodDays {
            cycleConfig.periodDays = periodDays
            hasChanges = true
        }

        if let cycleLength = cycleLength, cycleLength != cycleConfig.cycleLength {
            cycleConfig.cycleLength = cycleLength
            hasChanges = true
        }

        if let lastPeriodDate = lastPeriodDate {
            let calendar = Calendar.current
            if !calendar.isDate(lastPeriodDate, inSameDayAs: cycleConfig.lastPeriodDate) {
                cycleConfig.lastPeriodDate = lastPeriodDate
                hasChanges = true
            }
        }

        if hasChanges {
            // 标记为已配置
            cycleConfig.isConfigured = true

            saveAllData()

            // 发送配置变更通知
            NotificationCenter.default.post(name: .cycleConfigurationDidChange, object: nil)

            XLogger.shared.log("周期配置已更新: periodDays=\(cycleConfig.periodDays), cycleLength=\(cycleConfig.cycleLength), lastPeriodDate=\(cycleConfig.lastPeriodDate), isConfigured=\(cycleConfig.isConfigured)")
        }
    }

    /// 获取周期配置
    func getCycleConfiguration() -> CycleConfiguration {
        return cycleConfig
    }

    // MARK: - 每日数据管理

    /// 获取指定日期的症状数据
    func getDailyData(for date: Date) -> DailySymptomData {
        let dateString = dateFormatter.string(from: date)
        return dailyDataDict[dateString] ?? DailySymptomData(date: dateString)
    }

    /// 获取指定日期字符串的症状数据
    func getDailyData(for dateString: String) -> DailySymptomData {
        return dailyDataDict[dateString] ?? DailySymptomData(date: dateString)
    }

    /// 更新指定日期的症状数据
    func updateDailyData(for date: Date, data: DailySymptomData) {
        let dateString = dateFormatter.string(from: date)
        dailyDataDict[dateString] = data
        saveAllData()

        // 发送数据变更通知
        NotificationCenter.default.post(
            name: .femaleCycleDataDidChange,
            object: nil,
            userInfo: ["date": dateString, "data": data]
        )

        XLogger.shared.log("每日数据已更新: \(dateString) - \(data)")
    }

    /// 更新指定日期的经期开始状态
    func updatePeriodStartStatus(for date: Date, isStarted: Bool) {
        var data = getDailyData(for: date)
        data.isPeriodStarted = isStarted
        updateDailyData(for: date, data: data)
    }

    /// 更新指定日期的流量等级
    func updateFlowLevel(for date: Date, level: Int) {
        var data = getDailyData(for: date)
        data.flowLevel = level
        updateDailyData(for: date, data: data)
    }

    /// 更新指定日期的痛经等级
    func updatePainLevel(for date: Date, level: Int) {
        var data = getDailyData(for: date)
        data.painLevel = level
        updateDailyData(for: date, data: data)
    }

    /// 更新指定日期的性行为
    func updateSexualActivity(for date: Date, activity: Int) {
        var data = getDailyData(for: date)
        data.sexualActivity = activity
        updateDailyData(for: date, data: data)
    }

    /// 更新指定日期的心情
    func updateMood(for date: Date, mood: Int) {
        var data = getDailyData(for: date)
        data.mood = mood
        updateDailyData(for: date, data: data)
    }

    /// 更新指定日期的身体症状
    func updateBodySymptoms(for date: Date, symptoms: [String]) {
        var data = getDailyData(for: date)
        data.bodySymptoms = symptoms
        updateDailyData(for: date, data: data)
    }

    /// 检查指定日期是否有记录数据
    func hasRecordData(for date: Date) -> Bool {
        let dateString = dateFormatter.string(from: date)
        // 只要该日期在字典中存在，就算有记录
        return dailyDataDict[dateString] != nil
    }

    /// 获取所有有记录的日期
    func getAllRecordedDates() -> [String] {
        return Array(dailyDataDict.keys)
    }

    /// 获取所有有记录的日期（按时间倒序排列）
    func getAllRecordedDatesSorted() -> [String] {
        return dailyDataDict.keys.sorted(by: >)
    }

    /// 按月份分组获取所有记录（倒序）
    func getRecordsByMonth() -> [(month: String, dates: [String])] {
        let sortedDates = getAllRecordedDatesSorted()
        var result: [(month: String, dates: [String])] = []
        var currentMonth = ""
        var currentDates: [String] = []

        for dateString in sortedDates {
            // 提取月份："yyyy-MM"
            let monthString = String(dateString.prefix(7)) // "2025-12-09" -> "2025-12"

            if monthString != currentMonth {
                if !currentDates.isEmpty {
                    result.append((month: currentMonth, dates: currentDates))
                }
                currentMonth = monthString
                currentDates = [dateString]
            } else {
                currentDates.append(dateString)
            }
        }

        // 添加最后一组
        if !currentDates.isEmpty {
            result.append((month: currentMonth, dates: currentDates))
        }

        return result
    }

    /// 计算指定日期在周期中的天数（1表示经期第一天）
    /// 返回0表示不在经期内
    func calculateCycleDay(for date: Date) -> Int {
        let calendar = Calendar.current
        let lastPeriodDate = cycleConfig.lastPeriodDate

        // 计算与上次经期开始的天数差
        let days = calendar.dateComponents([.day], from: lastPeriodDate, to: date).day ?? 0

        // 如果是负数，说明在上次经期之前
        if days < 0 {
            return 0
        }

        // 检查是否在当前周期的经期内
        if days < cycleConfig.periodDays {
            return days + 1 // 经期第1-7天
        }

        // 检查是否在下一个周期的经期内
        let nextPeriodStart = calendar.date(byAdding: .day, value: cycleConfig.cycleLength, to: lastPeriodDate)
        if let nextStart = nextPeriodStart {
            let daysFromNext = calendar.dateComponents([.day], from: nextStart, to: date).day ?? -1
            if daysFromNext >= 0 && daysFromNext < cycleConfig.periodDays {
                return daysFromNext + 1
            }
        }

        return 0 // 不在经期内
    }

    /// 判断指定日期是否在经期内
    func isInPeriod(date: Date) -> Bool {
        return calculateCycleDay(for: date) > 0
    }

    // MARK: - 数据清理

    /// 清除指定日期之前的旧数据（保留最近N天）
    func cleanOldData(keepDays: Int = 365) {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -keepDays, to: Date()) ?? Date()
        let cutoffDateString = dateFormatter.string(from: cutoffDate)

        var removedCount = 0
        for (dateString, _) in dailyDataDict {
            if dateString < cutoffDateString {
                dailyDataDict.removeValue(forKey: dateString)
                removedCount += 1
            }
        }

        if removedCount > 0 {
            saveAllData()
            XLogger.shared.log("清理了 \(removedCount) 条旧数据")
        }
    }

    /// 清除所有数据（谨慎使用）
    func clearAllData() {
        dailyDataDict.removeAll()
        cycleConfig = CycleConfiguration()
        saveAllData()

        // 发送通知
        NotificationCenter.default.post(name: .cycleConfigurationDidChange, object: nil)
        NotificationCenter.default.post(name: .femaleCycleDataDidChange, object: nil)

        XLogger.shared.log("所有数据已清除")
    }
}
