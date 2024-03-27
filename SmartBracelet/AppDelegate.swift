//
//  AppDelegate.swift
//  SmartBracelet
//
//  Created by apple on 2020/4/23.
//  Copyright © 2020 tjd. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift
import XCGLogger
import RealmSwift

let log = XCGLogger()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        configRealm()
        AMapServices.shared().apiKey = "0ed08fc41dc5bd1adc43b9189af816f7"
        window?.backgroundColor = UIColor.white
        IQKeyboardManager.shared.enable = true
        setupConfig()
        pushToTab()
        log.setup(level: .info, showLogIdentifier: true, showFunctionName: true, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true, showDate: true, writeToFile: false, fileLevel: .alert)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (status, err) in
            if !status {
                print("当用户不同意授权通知权限，则做其他的判读")
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, completionHandler: nil)
                }
                return
            }
        }
        application.applicationIconBadgeNumber = 0
        UNUserNotificationCenter.current().delegate = self
        
        Bugly.start(withAppId: "0c6ba8bb6a")
        
        var openCount = UserDefaults.standard.integer(forKey: "APPOPEN") ?? 0
        openCount += 1
        UserDefaults.standard.set(openCount, forKey: "APPOPEN")
        
        return true
    }
    
    public func pushToTab() {
//        if !CacheHelper().getCacheBool(name: "first") {
//            let sb = UIStoryboard(name: "Main", bundle: nil)
//            let vc = sb.instantiateViewController(withIdentifier: "GuideViewController")
//            window?.rootViewController = vc
//            return
//        }
//        if UserManager.sharedInstall.user == nil {
//            return
//        }
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "MTabBarController")
        window?.rootViewController = vc
    }
    
    private func setupConfig() {
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
        UINavigationBar.appearance().tintColor = UIColor.colorWithRGB(rgbValue: 0x898989)
        UITabBarItem.appearance().setTitleTextAttributes([.foregroundColor: UIColor.colorWithRGB(rgbValue: 0x0FC08D)], for: .selected)
        UITabBarItem.appearance().setTitleTextAttributes([.foregroundColor: UIColor.colorWithRGB(rgbValue: 0x818181)], for: .normal)
    }
    
    /// 配置数据库
    private func configRealm() {
        /// 如果要存储的数据模型属性发生变化,需要配置当前版本号比之前大
        let dbVersion : UInt64 = 7
        let docPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0] as String
        let dbPath = docPath.appending("/bracelet.realm")
        let config = Realm.Configuration(fileURL: URL.init(string: dbPath), inMemoryIdentifier: nil, syncConfiguration: nil, encryptionKey: nil, readOnly: false, schemaVersion: dbVersion, migrationBlock: { (migration, oldSchemaVersion) in
            
        }, deleteRealmIfMigrationNeeded: false, shouldCompactOnLaunch: nil, objectTypes: nil)
        Realm.Configuration.defaultConfiguration = config
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        guard let trigger = notification.request.trigger else { return; }
        if trigger.isKind(of: UNTimeIntervalNotificationTrigger.classForCoder()) {
            print("Notification did receive, Is class UNTimeIntervalNotificationTrigger")
            UIApplication.shared.applicationIconBadgeNumber = 0
        } else if trigger.isKind(of: UNCalendarNotificationTrigger.classForCoder()) {
            print("Notification did receive, Is class UNCalendarNotificationTrigger")
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
        // show alert while app is running in foreground
        return completionHandler([.alert, .badge, .sound])
    }
    
func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    // 判断通知的触发器类型
    // 如果触发器是 UNTimeIntervalNotificationTrigger 类型
    if let trigger = response.notification.request.trigger as? UNTimeIntervalNotificationTrigger {
        print("Notification did receive, Is class UNTimeIntervalNotificationTrigger")
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    // 如果触发器是 UNCalendarNotificationTrigger 类型
    else if let trigger = response.notification.request.trigger as? UNCalendarNotificationTrigger {
        print("Notification did receive, Is class UNCalendarNotificationTrigger")
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    // 调用 completionHandler 表示处理完成
    return completionHandler()
}

//这段代码是一个实现 UNUserNotificationCenterDelegate 协议的方法，用于处理用户对通知的响应。在方法中，首先获取通知的触发器类型，然后根据触发器类型打印相应的日志。最后调用 completionHandler 表示处理完成。
    

}

extension String {
    func localized() -> String {
        return NSLocalizedString(self, comment: "")
    }
}

