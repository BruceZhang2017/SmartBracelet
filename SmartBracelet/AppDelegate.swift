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
        PgyManager.shared().start(withAppId: "206fd41ea01a58736f8e42fe2e85065f")
        PgyUpdateManager.sharedPgy().start(withAppId: "206fd41ea01a58736f8e42fe2e85065f")
        PgyUpdateManager.sharedPgy().checkUpdate()
        configRealm()
        AMapServices.shared().apiKey = "0ed08fc41dc5bd1adc43b9189af816f7"
        window?.backgroundColor = UIColor.white
        IQKeyboardManager.shared.enable = true
        setupConfig()
        pushToTab()
        log.setup(level: .info, showLogIdentifier: true, showFunctionName: true, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true, showDate: true, writeToFile: false, fileLevel: .alert)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (status, err) in
            if !status {
                print("用户不同意授权通知权限")
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, completionHandler: nil)
                }
                return
            }
        }
        application.applicationIconBadgeNumber = 0
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    public func pushToTab() {
        if !CacheHelper().getCacheBool(name: "first") {
            let sb = UIStoryboard(name: "Main", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "GuideViewController")
            window?.rootViewController = vc
            return
        }
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
        
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        guard let trigger = notification.request.trigger else { return; }
        if trigger.isKind(of: UNTimeIntervalNotificationTrigger.classForCoder()) {
            print("Notification did receive, Is class UNTimeIntervalNotificationTrigger")
        } else if trigger.isKind(of: UNCalendarNotificationTrigger.classForCoder()) {
            print("Notification did receive, Is class UNCalendarNotificationTrigger")
        }
        // show alert while app is running in foreground
        return completionHandler(UNNotificationPresentationOptions.alert)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        guard let trigger = response.notification.request.trigger else { return; }
        if trigger.isKind(of: UNTimeIntervalNotificationTrigger.classForCoder()) {
            print("Notification did receive, Is class UNTimeIntervalNotificationTrigger")
        } else if trigger.isKind(of: UNCalendarNotificationTrigger.classForCoder()) {
            print("Notification did receive, Is class UNCalendarNotificationTrigger")
        }
        return completionHandler()
    }
}

