//
//  DatabaseManager.swift
//  SmartBracelet
//
//  Created by anker on 2024/12/27.
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
        return "SleepObj(date: \(String(describing: date)), mac: \(String(describing: mac)), awake: \(String(describing: awake)), light: \(String(describing: light)), deep: \(String(describing: deep)))"
    }
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
        DispatchQueue(label: "com.zhao.herefit").async {
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
        DispatchQueue(label: "com.zhao.herefit").async {
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
        DispatchQueue(label: "com.zhao.herefit").async {
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
        DispatchQueue(label: "com.zhao.herefit").async {
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
        DispatchQueue(label: "com.zhao.herefit").async {
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
        DispatchQueue(label: "com.zhao.herefit").async {
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
        DispatchQueue(label: "com.zhao.herefit").async {
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
        DispatchQueue(label: "com.zhao.herefit").async {
            autoreleasepool {
                let realm = try! Realm()
                guard let startDate = self.dateFormatter.date(from: date) else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate)!
                let startTime = Int(startDate.timeIntervalSince1970)
                let endTime = Int(endDate.timeIntervalSince1970)
                let objs = realm.objects(HeartObj.self).filter("time >= %@ AND time < %@", startTime, endTime)
                let threadSafeResults = ThreadSafeReference(to: objs)
                DispatchQueue.main.async {
                    let realm = try! Realm()
                    guard let results = realm.resolve(threadSafeResults) else { return }
                    completion(results)
                }
            }
        }
    }
    
    func getAllHeartObjs(completion: @escaping (Results<HeartObj>) -> Void) {
        DispatchQueue(label: "com.zhao.herefit").async {
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
        DispatchQueue(label: "com.zhao.herefit").async {
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
    func getBloodObj(byDate date: String, completion: @escaping (BloodObj?) -> Void) {
        DispatchQueue(label: "com.zhao.herefit").async {
            autoreleasepool {
                let realm = try! Realm()
                let obj = realm.object(ofType: BloodObj.self, forPrimaryKey: date)
                DispatchQueue.main.async {
                    completion(obj)
                }
            }
        }
    }
    
    func getAllBloodObjs(completion: @escaping (Results<BloodObj>) -> Void) {
        DispatchQueue(label: "com.zhao.herefit").async {
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
        DispatchQueue(label: "com.zhao.herefit").async {
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
        DispatchQueue(label: "com.zhao.herefit").async {
            autoreleasepool {
                let realm = try! Realm()
                guard let startDate = self.dateFormatter.date(from: date) else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate)!
                let startTime = Int(startDate.timeIntervalSince1970)
                let endTime = Int(endDate.timeIntervalSince1970)
                let objs = realm.objects(OxgenObj.self).filter("time >= %@ AND time < %@", startTime, endTime)
                let threadSafeResults = ThreadSafeReference(to: objs)
                DispatchQueue.main.async {
                    let realm = try! Realm()
                    guard let results = realm.resolve(threadSafeResults) else { return }
                    completion(results)
                }
            }
        }
    }
    
    func getAllOxgenObjs(completion: @escaping (Results<OxgenObj>) -> Void) {
        DispatchQueue(label: "com.zhao.herefit").async {
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
