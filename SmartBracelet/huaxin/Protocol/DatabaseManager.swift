//
//  DatabaseManager.swift
//  SmartBracelet
//
//  Created by anker on 2024/12/27.
//  Copyright © 2024 tjd. All rights reserved.
//

import Foundation
import RealmSwift
import WatchProtocolSDK

// 定义 StepObj 模型
public class StepObj: Object {
    @objc dynamic var date: String = ""
    @objc dynamic var mac: String = ""
    @objc dynamic var step: Int = 0

    public override static func primaryKey() -> String? {
        return "date"
    }

    public override var description: String {
        return "StepObj(date: \(String(describing: date)), mac: \(String(describing: mac)), step: \(String(describing: step)))"
    }
}

public class HeartObj: Object {
    @objc dynamic var time: Int = 0
    @objc dynamic var mac: String = ""
    @objc dynamic var heart: Int = 0

    public override static func primaryKey() -> String? {
        return "time"
    }

    public override var description: String {
        return "HeartObj(time: \(String(describing: time)), mac: \(String(describing: mac)), heart: \(String(describing: heart)))"
    }
}

public class BloodObj: Object {
    @objc dynamic var time: Int = 0
    @objc dynamic var mac: String = ""
    @objc dynamic var max: Int = 0
    @objc dynamic var min: Int = 0

    public override static func primaryKey() -> String? {
        return "time"
    }

    public override var description: String {
        return "BloodObj(time: \(String(describing: time)), mac: \(String(describing: mac)), max: \(String(describing: max)), min: \(String(describing: min)))"
    }
}

public class OxgenObj: Object {
    @objc dynamic var time: Int = 0
    @objc dynamic var mac: String = ""
    @objc dynamic var oxgen: Int = 0

    public override static func primaryKey() -> String? {
        return "time"
    }

    public override var description: String {
        return "OxgenObj(time: \(String(describing: time)), mac: \(String(describing: mac)), oxgen: \(String(describing: oxgen)))"
    }
}

public class SleepObj: Object {
    @objc dynamic var date: String = ""
    @objc dynamic var mac: String = ""
    @objc dynamic var awake: Int = 0
    @objc dynamic var light: Int = 0
    @objc dynamic var deep: Int = 0

    public override static func primaryKey() -> String? {
        return "date"
    }

    public override var description: String {
        return "SleepObj(date: \(String(describing: date)), mac: \(String(describing: mac)), awake: \(String(describing: awake)), light: \(String(describing: light)), deep: \(String(describing: deep)))"
    }
}

public class DatabaseManager {
    public static let shared = DatabaseManager()
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
            schemaVersion: 1,
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
                DispatchQueue.main.async {
                    completion(objs)
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
                DispatchQueue.main.async {
                    completion(objs)
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
                DispatchQueue.main.async {
                    completion(objs)
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
                DispatchQueue.main.async {
                    completion(objs)
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
                DispatchQueue.main.async {
                    completion(objs)
                }
            }
        }
    }
}

// MARK: - HealthDataStorageProtocol Implementation

extension DatabaseManager: HealthDataStorageProtocol {

    public func saveStepData(_ data: WatchProtocolSDK.StepData) {
        let stepObj = StepObj()
        stepObj.date = data.date
        stepObj.mac = data.mac
        stepObj.step = data.step
        addStepObj(stepObj: stepObj)
    }

    public func saveSleepData(_ data: WatchProtocolSDK.SleepData) {
        let sleepObj = SleepObj()
        sleepObj.date = data.date
        sleepObj.mac = data.mac
        sleepObj.awake = data.awake
        sleepObj.light = data.light
        sleepObj.deep = data.deep
        addSleepObj(sleepObj: sleepObj)
    }

    public func saveHeartData(_ data: WatchProtocolSDK.HeartData) {
        let heartObj = HeartObj()
        heartObj.time = data.time
        heartObj.mac = data.mac
        heartObj.heart = data.heart
        addHeartObj(heartObj: heartObj)
    }

    public func saveOxygenData(_ data: WatchProtocolSDK.OxygenData) {
        let oxgenObj = OxgenObj()
        oxgenObj.time = data.time
        oxgenObj.mac = data.mac
        oxgenObj.oxgen = data.oxygen
        addOxgenObj(oxgenObj: oxgenObj)
    }

    public func saveBloodPressureData(_ data: WatchProtocolSDK.BloodPressureData) {
        let bloodObj = BloodObj()
        bloodObj.time = data.time
        bloodObj.mac = data.mac
        bloodObj.max = data.max
        bloodObj.min = data.min
        addBloodObj(bloodObj: bloodObj)
    }
}
