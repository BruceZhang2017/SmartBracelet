//
//  DatabaseManager.swift
//  SmartBracelet
//
//  Created by bruce on 2024/12/27.
//  Copyright © 2024 tjd. All rights reserved.
//

import Foundation
import RealmSwift

// 定义 StepObj 模型
class StepObj: Object {
    @objc dynamic var date: String = ""
    @objc dynamic var mac: String = ""
    @objc dynamic var step: Int = 0

    override static func primaryKey() -> String? {
        return "date"
    }

    override var description: String {
        return "StepObj(date: \(String(describing: date)), mac: \(String(describing: mac)), step: \(String(describing: step)))"
    }
}

class HeartObj: Object {
    @objc dynamic var time: Int = 0
    @objc dynamic var mac: String = ""
    @objc dynamic var heart: Int = 0

    override static func primaryKey() -> String? {
        return "time"
    }

    override var description: String {
        return "HeartObj(time: \(String(describing: time)), mac: \(String(describing: mac)), heart: \(String(describing: heart)))"
    }
}

class BloodObj: Object {
    @objc dynamic var time: Int = 0
    @objc dynamic var mac: String = ""
    @objc dynamic var max: Int = 0
    @objc dynamic var min: Int = 0

    override static func primaryKey() -> String? {
        return "time"
    }

    override var description: String {
        return "BloodObj(time: \(String(describing: time)), mac: \(String(describing: mac)), max: \(String(describing: max)), min: \(String(describing: min)))"
    }
}

class OxgenObj: Object {
    @objc dynamic var time: Int = 0
    @objc dynamic var mac: String = ""
    @objc dynamic var oxgen: Int = 0

    override static func primaryKey() -> String? {
        return "time"
    }

    override var description: String {
        return "OxgenObj(time: \(String(describing: time)), mac: \(String(describing: mac)), oxgen: \(String(describing: oxgen)))"
    }
}

class SleepObj: Object {
    @objc dynamic var date: String = ""
    @objc dynamic var mac: String = ""
    @objc dynamic var awake: Int = 0
    @objc dynamic var light: Int = 0
    @objc dynamic var deep: Int = 0

    override static func primaryKey() -> String? {
        return "date"
    }

    override var description: String {
        return "SleepObj(<safe-summary>)"
    }
}

class GlucoseObj: Object {
    @objc dynamic var time: Int = 0
    @objc dynamic var mac: String = ""
    @objc dynamic var value: Double = 0

    override static func primaryKey() -> String? {
        return "time"
    }

    override var description: String {
        return "GlucoseObj(time: \(String(describing: time)), mac: \(String(describing: mac)), value: \(String(describing: value)))"
    }
}

class UricAcidObj: Object {
    @objc dynamic var time: Int = 0
    @objc dynamic var mac: String = ""
    @objc dynamic var value: Int = 0

    override static func primaryKey() -> String? {
        return "time"
    }

    override var description: String {
        return "UricAcidObj(time: \(String(describing: time)), mac: \(String(describing: mac)), value: \(String(describing: value)))"
    }
}

class LipidObj: Object {
    @objc dynamic var time: Int = 0
    @objc dynamic var mac: String = ""
    @objc dynamic var tc: Double = 0
    @objc dynamic var tg: Double = 0
    @objc dynamic var hdl: Double = 0
    @objc dynamic var ldl: Double = 0

    override static func primaryKey() -> String? {
        return "time"
    }

    override var description: String {
        return "LipidObj(time: \(String(describing: time)), mac: \(String(describing: mac)), tc: \(String(describing: tc)), tg: \(String(describing: tg)), hdl: \(String(describing: hdl)), ldl: \(String(describing: ldl)))"
    }
}

class PpgObj: Object {
    @objc dynamic var time: Int = 0
    @objc dynamic var mac: String = ""
    @objc dynamic var value: Int = 0

    override static func primaryKey() -> String? {
        return "time"
    }

    override var description: String {
        return "PpgObj(time: \(String(describing: time)), mac: \(String(describing: mac)), value: \(String(describing: value)))"
    }
}

class HRVObj: Object {
    @objc dynamic var time: Int = 0
    @objc dynamic var mac: String = ""
    @objc dynamic var value: Int = 0

    override static func primaryKey() -> String? {
        return "time"
    }

    override var description: String {
        return "HRVObj(time: \(String(describing: time)), mac: \(String(describing: mac)), value: \(String(describing: value)))"
    }
}

class StressObj: Object {
    @objc dynamic var time: Int = 0
    @objc dynamic var mac: String = ""
    @objc dynamic var value: Int = 0

    override static func primaryKey() -> String? {
        return "time"
    }

    override var description: String {
        return "StressObj(time: \(String(describing: time)), mac: \(String(describing: mac)), value: \(String(describing: value)))"
    }
}

class FatigueObj: Object {
    @objc dynamic var time: Int = 0
    @objc dynamic var mac: String = ""
    @objc dynamic var value: Int = 0

    override static func primaryKey() -> String? {
        return "time"
    }

    override var description: String {
        return "FatigueObj(time: \(String(describing: time)), mac: \(String(describing: mac)), value: \(String(describing: value)))"
    }
}

class EcgHistoryObj: Object {
    @objc dynamic var id: String = ""
    @objc dynamic var address: String = ""
    @objc dynamic var startedAt: Double = 0
    @objc dynamic var durationMillis: Int = 0
    @objc dynamic var samplesJson: String = ""

    override static func primaryKey() -> String? {
        return "id"
    }
}

struct EcgPoint: Codable {
    var offsetMillis: Int64
    var heartRate: Int
}

/// 与 Android EcgHistorySummary 对齐：纯值快照，跨线程安全
struct EcgHistorySummary {
    var id: String
    var address: String
    var startedAt: Double
    var durationMillis: Int
    var samplesJson: String
}

class DatabaseManager {
    static let shared = DatabaseManager()
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
    
    private init() {
        // 配置 Realm
        let docPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0] as String
        let dbPath = docPath.appending("/sport.realm")
        let config = Realm.Configuration(
            fileURL: URL(fileURLWithPath: dbPath),
            schemaVersion: 3,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 1 {
                    // 进行迁移操作
                }
            }
        )
        Realm.Configuration.defaultConfiguration = config
    }
    
    // Create or Update
    func addStepObj(stepObj: StepObj) {
        DispatchQueue(label: "com.sinophy.uwatch").async {
            autoreleasepool {
                let realm = try! Realm()
                try? realm.write {
                    // 使用 .modified 选项，如果主键相同则进行覆盖操作
                    realm.add(stepObj, update: .modified)
                }
            }
        }
    }
    
    // Read
    func getStepObj(byDate date: String, completion: @escaping (Results<StepObj>?) -> Void) {
        DispatchQueue(label: "com.sinophy.uwatch").async {
            autoreleasepool {
                let realm = try! Realm()
                let objs = realm.objects(StepObj.self).filter("date == %@", date)
                let threadSafeResults = ThreadSafeReference(to: objs)
                DispatchQueue.main.async {
                    let realm = try! Realm()
                    guard let results = realm.resolve(threadSafeResults) else { return }
                    completion(results)
                }
            }
        }
    }
    
    func getAllStepObjs(completion: @escaping (Results<StepObj>) -> Void) {
        DispatchQueue(label: "com.sinophy.uwatch").async {
            autoreleasepool {
                let realm = try! Realm()
                let objs = realm.objects(StepObj.self)
                let threadSafeResults = ThreadSafeReference(to: objs)
                DispatchQueue.main.async {
                    let realm = try! Realm()
                    guard let results = realm.resolve(threadSafeResults) else { return }
                    completion(results)
                }
            }
        }
    }
    
    // Create or Update
    func addSleepObj(sleepObj: SleepObj) {
        DispatchQueue(label: "com.sinophy.uwatch").async {
            autoreleasepool {
                let realm = try! Realm()
                try? realm.write {
                    // 使用 .modified 选项，如果主键相同则进行覆盖操作
                    realm.add(sleepObj, update: .modified)
                }
            }
        }
    }
    
    // Read
    func getSleepObj(byDate date: String, completion: @escaping (Results<SleepObj>?) -> Void) {
        DispatchQueue(label: "com.sinophy.uwatch").async {
            autoreleasepool {
                let realm = try! Realm()
                let objs = realm.objects(SleepObj.self).filter("date == %@", date)
                let threadSafeResults = ThreadSafeReference(to: objs)
                DispatchQueue.main.async {
                    let realm = try! Realm()
                    guard let results = realm.resolve(threadSafeResults) else { return }
                    completion(results)
                }
            }
        }
    }
    
    func getAllSleepObjs(completion: @escaping (Results<SleepObj>) -> Void) {
        DispatchQueue(label: "com.sinophy.uwatch").async {
            autoreleasepool {
                let realm = try! Realm()
                let objs = realm.objects(SleepObj.self)
                let threadSafeResults = ThreadSafeReference(to: objs)
                DispatchQueue.main.async {
                    let realm = try! Realm()
                    guard let results = realm.resolve(threadSafeResults) else { return }
                    completion(results)
                }
            }
        }
    }
    
    // Create or Update
    func addHeartObj(heartObj: HeartObj) {
        DispatchQueue(label: "com.sinophy.uwatch").async {
            autoreleasepool {
                let realm = try! Realm()
                try? realm.write {
                    // 使用 .modified 选项，如果主键相同则进行覆盖操作
                    realm.add(heartObj, update: .modified)
                }
            }
        }
    }
    
    // Read
    func getHeartObj(byDate date: String, completion: @escaping (Results<HeartObj>?) -> Void) {
        DispatchQueue(label: "com.sinophy.uwatch").async {
            autoreleasepool {
                let realm = try! Realm()
                
                // 1. 配置 UTC 时区的日期格式化器（与 getOxgenObj 保持一致，确保时区统一）
                let utcDateFormatter = DateFormatter()
                utcDateFormatter.dateFormat = self.dateFormatter.dateFormat // 复用原有格式（假设已正确配置，如 "yyyy-MM-dd"）
                utcDateFormatter.timeZone = TimeZone(identifier: "UTC")!
                utcDateFormatter.locale = Locale(identifier: "en_US_POSIX") // 避免区域设置影响解析
                
                // 2. 解析日期为 UTC 时区的 "当天0点"
                guard let startDateUTC = utcDateFormatter.date(from: date) else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                
                // 3. 用 UTC 时区计算结束时间（UTC 下一天0点）
                var utcCalendar = Calendar(identifier: .gregorian)
                utcCalendar.timeZone = TimeZone(identifier: "UTC")!
                guard let endDateUTC = utcCalendar.date(byAdding: .day, value: 1, to: startDateUTC) else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                
                // 4. 转换为 UTC 时间戳（与嵌入式设备的 time 字段时区一致）
                let startTime = Int(startDateUTC.timeIntervalSince1970)
                let endTime = Int(endDateUTC.timeIntervalSince1970)
                
                // 5. Realm 查询（条件与嵌入式设备时间戳时区匹配）
                let objs = realm.objects(HeartObj.self).filter("time >= %@ AND time < %@", startTime, endTime)
                let threadSafeResults = ThreadSafeReference(to: objs)
                
                DispatchQueue.main.async {
                    let realm = try! Realm()
                    guard let results = realm.resolve(threadSafeResults) else {
                        completion(nil)
                        return
                    }
                    completion(results)
                }
            }
        }
    }
    
    func getAllHeartObjs(completion: @escaping (Results<HeartObj>) -> Void) {
        DispatchQueue(label: "com.sinophy.uwatch").async {
            autoreleasepool {
                let realm = try! Realm()
                let objs = realm.objects(HeartObj.self)
                let threadSafeResults = ThreadSafeReference(to: objs)
                DispatchQueue.main.async {
                    let realm = try! Realm()
                    guard let results = realm.resolve(threadSafeResults) else { return }
                    completion(results)
                }
            }
        }
    }
    
    // Create or Update
    func addBloodObj(bloodObj: BloodObj) {
        DispatchQueue(label: "com.sinophy.uwatch").async {
            autoreleasepool {
                let realm = try! Realm()
                try? realm.write {
                    // 使用 .modified 选项，如果主键相同则进行覆盖操作
                    realm.add(bloodObj, update: .modified)
                }
            }
        }
    }
    
    // Read
    func getBloodObj(byDate date: String, completion: @escaping (Results<BloodObj>?) -> Void) {
        DispatchQueue(label: "com.sinophy.uwatch").async {
            autoreleasepool {
                let realm = try! Realm()
                
                // 1. 配置 UTC 时区的日期格式化器（与 getOxgenObj 保持一致，确保时区统一）
                let utcDateFormatter = DateFormatter()
                utcDateFormatter.dateFormat = self.dateFormatter.dateFormat // 复用原有格式（假设已正确配置，如 "yyyy-MM-dd"）
                utcDateFormatter.timeZone = TimeZone(identifier: "UTC")!
                utcDateFormatter.locale = Locale(identifier: "en_US_POSIX") // 避免区域设置影响解析
                
                // 2. 解析日期为 UTC 时区的 "当天0点"
                guard let startDateUTC = utcDateFormatter.date(from: date) else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                
                // 3. 用 UTC 时区计算结束时间（UTC 下一天0点）
                var utcCalendar = Calendar(identifier: .gregorian)
                utcCalendar.timeZone = TimeZone(identifier: "UTC")!
                guard let endDateUTC = utcCalendar.date(byAdding: .day, value: 1, to: startDateUTC) else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                
                // 4. 转换为 UTC 时间戳（与嵌入式设备的 time 字段时区一致）
                let startTime = Int(startDateUTC.timeIntervalSince1970)
                let endTime = Int(endDateUTC.timeIntervalSince1970)
                
                // 5. Realm 查询（条件与嵌入式设备时间戳时区匹配）
                let objs = realm.objects(BloodObj.self).filter("time >= %@ AND time < %@", startTime, endTime)
                let threadSafeResults = ThreadSafeReference(to: objs)
                
                DispatchQueue.main.async {
                    let realm = try! Realm()
                    guard let results = realm.resolve(threadSafeResults) else {
                        completion(nil)
                        return
                    }
                    completion(results)
                }
            }
        }
    }
    
    func getAllBloodObjs(completion: @escaping (Results<BloodObj>) -> Void) {
        DispatchQueue(label: "com.sinophy.uwatch").async {
            autoreleasepool {
                let realm = try! Realm()
                let objs = realm.objects(BloodObj.self)
                let threadSafeResults = ThreadSafeReference(to: objs)
                DispatchQueue.main.async {
                    let realm = try! Realm()
                    guard let results = realm.resolve(threadSafeResults) else { return }
                    completion(results)
                }
            }
        }
    }
    
    // Create or Update
    func addOxgenObj(oxgenObj: OxgenObj) {
        DispatchQueue(label: "com.sinophy.uwatch").async {
            autoreleasepool {
                let realm = try! Realm()
                try? realm.write {
                    // 使用 .modified 选项，如果主键相同则进行覆盖操作
                    realm.add(oxgenObj, update: .modified)
                }
            }
        }
    }
    
    // Read
    func getOxgenObj(byDate date: String, completion: @escaping (Results<OxgenObj>?) -> Void) {
        DispatchQueue(label: "com.sinophy.uwatch").async {
            autoreleasepool {
                let realm = try! Realm()
                
                // 1. 配置 dateFormatter 为 UTC 时区（关键：确保日期解析基于 UTC）
                let utcDateFormatter = DateFormatter()
                utcDateFormatter.dateFormat = self.dateFormatter.dateFormat // 复用原有格式（假设已正确配置，如 "yyyy-MM-dd"）
                utcDateFormatter.timeZone = TimeZone(identifier: "UTC")! // 强制 UTC 时区
                utcDateFormatter.locale = Locale(identifier: "en_US_POSIX") // 避免区域设置影响解析（建议添加）
                
                // 2. 解析日期为 UTC 时区的 "当天0点"
                guard let startDateUTC = utcDateFormatter.date(from: date) else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                
                // 3. 用 UTC 时区计算结束时间（UTC 下一天0点）
                var utcCalendar = Calendar(identifier: .gregorian)
                utcCalendar.timeZone = TimeZone(identifier: "UTC")!
                guard let endDateUTC = utcCalendar.date(byAdding: .day, value: 1, to: startDateUTC) else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                
                // 4. 转换为 UTC 时间戳（与嵌入式设备的 time 字段时区一致）
                let startTime = Int(startDateUTC.timeIntervalSince1970)
                let endTime = Int(endDateUTC.timeIntervalSince1970)
                
                // 5. Realm 查询（条件与嵌入式设备时间戳时区匹配）
                let objs = realm.objects(OxgenObj.self).filter("time >= %@ AND time < %@", startTime, endTime)
                let threadSafeResults = ThreadSafeReference(to: objs)
                
                DispatchQueue.main.async {
                    let realm = try! Realm()
                    guard let results = realm.resolve(threadSafeResults) else {
                        completion(nil)
                        return
                    }
                    completion(results)
                }
            }
        }
    }
    
    func getAllOxgenObjs(completion: @escaping (Results<OxgenObj>) -> Void) {
        DispatchQueue(label: "com.sinophy.uwatch").async {
            autoreleasepool {
                let realm = try! Realm()
                let objs = realm.objects(OxgenObj.self)
                let threadSafeResults = ThreadSafeReference(to: objs)
                DispatchQueue.main.async {
                    let realm = try! Realm()
                    guard let results = realm.resolve(threadSafeResults) else { return }
                    completion(results)
                }
            }
        }
    }
    
    // MARK: - 血糖/尿酸/血脂 历史记录（与 HeartObj 同模式，time 为设备上报的 UTC 时间戳）
    
    // Create or Update
    func addGlucoseObj(time: Int, mac: String, value: Double) {
        DispatchQueue(label: "com.sinophy.uwatch").async {
            autoreleasepool {
                let realm = try! Realm()
                let obj = GlucoseObj()
                obj.time = time
                obj.mac = mac
                obj.value = value
                try? realm.write {
                    realm.add(obj, update: .modified)
                }
            }
        }
    }
    
    // Read
    func getGlucoseObj(byDate date: String, completion: @escaping (Results<GlucoseObj>?) -> Void) {
        DispatchQueue(label: "com.sinophy.uwatch").async {
            autoreleasepool {
                let realm = try! Realm()
                let utcDateFormatter = DateFormatter()
                utcDateFormatter.dateFormat = self.dateFormatter.dateFormat
                utcDateFormatter.timeZone = TimeZone(identifier: "UTC")!
                utcDateFormatter.locale = Locale(identifier: "en_US_POSIX")
                guard let startDateUTC = utcDateFormatter.date(from: date) else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                var utcCalendar = Calendar(identifier: .gregorian)
                utcCalendar.timeZone = TimeZone(identifier: "UTC")!
                guard let endDateUTC = utcCalendar.date(byAdding: .day, value: 1, to: startDateUTC) else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                let startTime = Int(startDateUTC.timeIntervalSince1970)
                let endTime = Int(endDateUTC.timeIntervalSince1970)
                let objs = realm.objects(GlucoseObj.self).filter("time >= %@ AND time < %@", startTime, endTime)
                let threadSafeResults = ThreadSafeReference(to: objs)
                DispatchQueue.main.async {
                    let realm = try! Realm()
                    guard let results = realm.resolve(threadSafeResults) else {
                        completion(nil)
                        return
                    }
                    completion(results)
                }
            }
        }
    }
    
    func getAllGlucoseObjs(completion: @escaping (Results<GlucoseObj>) -> Void) {
        DispatchQueue(label: "com.sinophy.uwatch").async {
            autoreleasepool {
                let realm = try! Realm()
                let objs = realm.objects(GlucoseObj.self)
                let threadSafeResults = ThreadSafeReference(to: objs)
                DispatchQueue.main.async {
                    let realm = try! Realm()
                    guard let results = realm.resolve(threadSafeResults) else { return }
                    completion(results)
                }
            }
        }
    }
    
    // Create or Update
    func addUricAcidObj(time: Int, mac: String, value: Int) {
        DispatchQueue(label: "com.sinophy.uwatch").async {
            autoreleasepool {
                let realm = try! Realm()
                let obj = UricAcidObj()
                obj.time = time
                obj.mac = mac
                obj.value = value
                try? realm.write {
                    realm.add(obj, update: .modified)
                }
            }
        }
    }
    
    // Read
    func getUricAcidObj(byDate date: String, completion: @escaping (Results<UricAcidObj>?) -> Void) {
        DispatchQueue(label: "com.sinophy.uwatch").async {
            autoreleasepool {
                let realm = try! Realm()
                let utcDateFormatter = DateFormatter()
                utcDateFormatter.dateFormat = self.dateFormatter.dateFormat
                utcDateFormatter.timeZone = TimeZone(identifier: "UTC")!
                utcDateFormatter.locale = Locale(identifier: "en_US_POSIX")
                guard let startDateUTC = utcDateFormatter.date(from: date) else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                var utcCalendar = Calendar(identifier: .gregorian)
                utcCalendar.timeZone = TimeZone(identifier: "UTC")!
                guard let endDateUTC = utcCalendar.date(byAdding: .day, value: 1, to: startDateUTC) else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                let startTime = Int(startDateUTC.timeIntervalSince1970)
                let endTime = Int(endDateUTC.timeIntervalSince1970)
                let objs = realm.objects(UricAcidObj.self).filter("time >= %@ AND time < %@", startTime, endTime)
                let threadSafeResults = ThreadSafeReference(to: objs)
                DispatchQueue.main.async {
                    let realm = try! Realm()
                    guard let results = realm.resolve(threadSafeResults) else {
                        completion(nil)
                        return
                    }
                    completion(results)
                }
            }
        }
    }
    
    func getAllUricAcidObjs(completion: @escaping (Results<UricAcidObj>) -> Void) {
        DispatchQueue(label: "com.sinophy.uwatch").async {
            autoreleasepool {
                let realm = try! Realm()
                let objs = realm.objects(UricAcidObj.self)
                let threadSafeResults = ThreadSafeReference(to: objs)
                DispatchQueue.main.async {
                    let realm = try! Realm()
                    guard let results = realm.resolve(threadSafeResults) else { return }
                    completion(results)
                }
            }
        }
    }
    
    // Create or Update
    func addLipidObj(time: Int, mac: String, tc: Double, tg: Double, hdl: Double, ldl: Double) {
        DispatchQueue(label: "com.sinophy.uwatch").async {
            autoreleasepool {
                let realm = try! Realm()
                let obj = LipidObj()
                obj.time = time
                obj.mac = mac
                obj.tc = tc
                obj.tg = tg
                obj.hdl = hdl
                obj.ldl = ldl
                try? realm.write {
                    realm.add(obj, update: .modified)
                }
            }
        }
    }
    
    // Read
    func getLipidObj(byDate date: String, completion: @escaping (Results<LipidObj>?) -> Void) {
        DispatchQueue(label: "com.sinophy.uwatch").async {
            autoreleasepool {
                let realm = try! Realm()
                let utcDateFormatter = DateFormatter()
                utcDateFormatter.dateFormat = self.dateFormatter.dateFormat
                utcDateFormatter.timeZone = TimeZone(identifier: "UTC")!
                utcDateFormatter.locale = Locale(identifier: "en_US_POSIX")
                guard let startDateUTC = utcDateFormatter.date(from: date) else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                var utcCalendar = Calendar(identifier: .gregorian)
                utcCalendar.timeZone = TimeZone(identifier: "UTC")!
                guard let endDateUTC = utcCalendar.date(byAdding: .day, value: 1, to: startDateUTC) else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                let startTime = Int(startDateUTC.timeIntervalSince1970)
                let endTime = Int(endDateUTC.timeIntervalSince1970)
                let objs = realm.objects(LipidObj.self).filter("time >= %@ AND time < %@", startTime, endTime)
                let threadSafeResults = ThreadSafeReference(to: objs)
                DispatchQueue.main.async {
                    let realm = try! Realm()
                    guard let results = realm.resolve(threadSafeResults) else {
                        completion(nil)
                        return
                    }
                    completion(results)
                }
            }
        }
    }
    
    func getAllLipidObjs(completion: @escaping (Results<LipidObj>) -> Void) {
        DispatchQueue(label: "com.sinophy.uwatch").async {
            autoreleasepool {
                let realm = try! Realm()
                let objs = realm.objects(LipidObj.self)
                let threadSafeResults = ThreadSafeReference(to: objs)
                DispatchQueue.main.async {
                    let realm = try! Realm()
                    guard let results = realm.resolve(threadSafeResults) else { return }
                    completion(results)
                }
            }
        }
    }
    
    // MARK: - 脉搏 PPG / 心率变异性 HRV / 精神压力 / 疲劳度 历史记录（0x07~0x0A，同 HeartObj 模式）

    // Create or Update
    func addPpgObj(time: Int, mac: String, value: Int) {
        DispatchQueue(label: "com.sinophy.uwatch").async {
            autoreleasepool {
                let realm = try! Realm()
                let obj = PpgObj()
                obj.time = time
                obj.mac = mac
                obj.value = value
                try? realm.write {
                    realm.add(obj, update: .modified)
                }
            }
        }
    }

    // Read
    func getPpgObj(byDate date: String, completion: @escaping (Results<PpgObj>?) -> Void) {
        DispatchQueue(label: "com.sinophy.uwatch").async {
            autoreleasepool {
                let realm = try! Realm()
                let utcDateFormatter = DateFormatter()
                utcDateFormatter.dateFormat = self.dateFormatter.dateFormat
                utcDateFormatter.timeZone = TimeZone(identifier: "UTC")!
                utcDateFormatter.locale = Locale(identifier: "en_US_POSIX")
                guard let startDateUTC = utcDateFormatter.date(from: date) else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                var utcCalendar = Calendar(identifier: .gregorian)
                utcCalendar.timeZone = TimeZone(identifier: "UTC")!
                guard let endDateUTC = utcCalendar.date(byAdding: .day, value: 1, to: startDateUTC) else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                let startTime = Int(startDateUTC.timeIntervalSince1970)
                let endTime = Int(endDateUTC.timeIntervalSince1970)
                let objs = realm.objects(PpgObj.self).filter("time >= %@ AND time < %@", startTime, endTime)
                let threadSafeResults = ThreadSafeReference(to: objs)
                DispatchQueue.main.async {
                    let realm = try! Realm()
                    guard let results = realm.resolve(threadSafeResults) else {
                        completion(nil)
                        return
                    }
                    completion(results)
                }
            }
        }
    }

    // Create or Update
    func addHRVObj(time: Int, mac: String, value: Int) {
        DispatchQueue(label: "com.sinophy.uwatch").async {
            autoreleasepool {
                let realm = try! Realm()
                let obj = HRVObj()
                obj.time = time
                obj.mac = mac
                obj.value = value
                try? realm.write {
                    realm.add(obj, update: .modified)
                }
            }
        }
    }

    // Read
    func getHRVObj(byDate date: String, completion: @escaping (Results<HRVObj>?) -> Void) {
        DispatchQueue(label: "com.sinophy.uwatch").async {
            autoreleasepool {
                let realm = try! Realm()
                let utcDateFormatter = DateFormatter()
                utcDateFormatter.dateFormat = self.dateFormatter.dateFormat
                utcDateFormatter.timeZone = TimeZone(identifier: "UTC")!
                utcDateFormatter.locale = Locale(identifier: "en_US_POSIX")
                guard let startDateUTC = utcDateFormatter.date(from: date) else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                var utcCalendar = Calendar(identifier: .gregorian)
                utcCalendar.timeZone = TimeZone(identifier: "UTC")!
                guard let endDateUTC = utcCalendar.date(byAdding: .day, value: 1, to: startDateUTC) else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                let startTime = Int(startDateUTC.timeIntervalSince1970)
                let endTime = Int(endDateUTC.timeIntervalSince1970)
                let objs = realm.objects(HRVObj.self).filter("time >= %@ AND time < %@", startTime, endTime)
                let threadSafeResults = ThreadSafeReference(to: objs)
                DispatchQueue.main.async {
                    let realm = try! Realm()
                    guard let results = realm.resolve(threadSafeResults) else {
                        completion(nil)
                        return
                    }
                    completion(results)
                }
            }
        }
    }

    // Create or Update
    func addStressObj(time: Int, mac: String, value: Int) {
        DispatchQueue(label: "com.sinophy.uwatch").async {
            autoreleasepool {
                let realm = try! Realm()
                let obj = StressObj()
                obj.time = time
                obj.mac = mac
                obj.value = value
                try? realm.write {
                    realm.add(obj, update: .modified)
                }
            }
        }
    }

    // Read
    func getStressObj(byDate date: String, completion: @escaping (Results<StressObj>?) -> Void) {
        DispatchQueue(label: "com.sinophy.uwatch").async {
            autoreleasepool {
                let realm = try! Realm()
                let utcDateFormatter = DateFormatter()
                utcDateFormatter.dateFormat = self.dateFormatter.dateFormat
                utcDateFormatter.timeZone = TimeZone(identifier: "UTC")!
                utcDateFormatter.locale = Locale(identifier: "en_US_POSIX")
                guard let startDateUTC = utcDateFormatter.date(from: date) else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                var utcCalendar = Calendar(identifier: .gregorian)
                utcCalendar.timeZone = TimeZone(identifier: "UTC")!
                guard let endDateUTC = utcCalendar.date(byAdding: .day, value: 1, to: startDateUTC) else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                let startTime = Int(startDateUTC.timeIntervalSince1970)
                let endTime = Int(endDateUTC.timeIntervalSince1970)
                let objs = realm.objects(StressObj.self).filter("time >= %@ AND time < %@", startTime, endTime)
                let threadSafeResults = ThreadSafeReference(to: objs)
                DispatchQueue.main.async {
                    let realm = try! Realm()
                    guard let results = realm.resolve(threadSafeResults) else {
                        completion(nil)
                        return
                    }
                    completion(results)
                }
            }
        }
    }

    // Create or Update
    func addFatigueObj(time: Int, mac: String, value: Int) {
        DispatchQueue(label: "com.sinophy.uwatch").async {
            autoreleasepool {
                let realm = try! Realm()
                let obj = FatigueObj()
                obj.time = time
                obj.mac = mac
                obj.value = value
                try? realm.write {
                    realm.add(obj, update: .modified)
                }
            }
        }
    }

    // Read
    func getFatigueObj(byDate date: String, completion: @escaping (Results<FatigueObj>?) -> Void) {
        DispatchQueue(label: "com.sinophy.uwatch").async {
            autoreleasepool {
                let realm = try! Realm()
                let utcDateFormatter = DateFormatter()
                utcDateFormatter.dateFormat = self.dateFormatter.dateFormat
                utcDateFormatter.timeZone = TimeZone(identifier: "UTC")!
                utcDateFormatter.locale = Locale(identifier: "en_US_POSIX")
                guard let startDateUTC = utcDateFormatter.date(from: date) else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                var utcCalendar = Calendar(identifier: .gregorian)
                utcCalendar.timeZone = TimeZone(identifier: "UTC")!
                guard let endDateUTC = utcCalendar.date(byAdding: .day, value: 1, to: startDateUTC) else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                let startTime = Int(startDateUTC.timeIntervalSince1970)
                let endTime = Int(endDateUTC.timeIntervalSince1970)
                let objs = realm.objects(FatigueObj.self).filter("time >= %@ AND time < %@", startTime, endTime)
                let threadSafeResults = ThreadSafeReference(to: objs)
                DispatchQueue.main.async {
                    let realm = try! Realm()
                    guard let results = realm.resolve(threadSafeResults) else {
                        completion(nil)
                        return
                    }
                    completion(results)
                }
            }
        }
    }

    // MARK: - ECG 心电图历史记录（与 Android EcgHistoryStore 对齐）
    
    func addEcgHistoryObj(ecgObj: EcgHistoryObj) {
        DispatchQueue(label: "com.sinophy.uwatch").async {
            autoreleasepool {
                let realm = try! Realm()
                try? realm.write {
                    realm.add(ecgObj, update: .modified)
                }
            }
        }
    }
    
    func getAllEcgHistoryObjs(completion: @escaping ([EcgHistorySummary]) -> Void) {
        DispatchQueue(label: "com.sinophy.uwatch").async {
            autoreleasepool {
                let realm = try! Realm()
                let objs = realm.objects(EcgHistoryObj.self).sorted(byKeyPath: "startedAt", ascending: false)
                let items = Array(objs.map { obj in
                    EcgHistorySummary(id: obj.id, address: obj.address, startedAt: obj.startedAt, durationMillis: obj.durationMillis, samplesJson: obj.samplesJson)
                })
                DispatchQueue.main.async {
                    completion(items)
                }
            }
        }
    }
    
    func getEcgHistoryObj(byId id: String, completion: @escaping (EcgHistorySummary?) -> Void) {
        DispatchQueue(label: "com.sinophy.uwatch").async {
            autoreleasepool {
                let realm = try! Realm()
                guard let obj = realm.object(ofType: EcgHistoryObj.self, forPrimaryKey: id) else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                let item = EcgHistorySummary(id: obj.id, address: obj.address, startedAt: obj.startedAt, durationMillis: obj.durationMillis, samplesJson: obj.samplesJson)
                DispatchQueue.main.async {
                    completion(item)
                }
            }
        }
    }
    
    // MARK: - ECG 采样点编解码（与 Android EcgHistoryStore 相同 JSON 结构 [[offsetMillis, heartRate], ...]）
    
    static func encodeEcgPoints(_ points: [EcgPoint]) -> String {
        let array = points.map { [$0.offsetMillis, Int64($0.heartRate)] }
        guard let data = try? JSONSerialization.data(withJSONObject: array),
              let json = String(data: data, encoding: .utf8) else { return "[]" }
        return json
    }
    
    static func decodeEcgPoints(_ json: String) -> [EcgPoint] {
        guard let data = json.data(using: .utf8),
              let array = (try? JSONSerialization.jsonObject(with: data)) as? [[Any]] else { return [] }
        return array.compactMap { pair in
            guard pair.count == 2,
                  let offset = pair[0] as? NSNumber,
                  let rate = pair[1] as? NSNumber else { return nil }
            return EcgPoint(offsetMillis: offset.int64Value, heartRate: rate.intValue)
        }
    }
}
