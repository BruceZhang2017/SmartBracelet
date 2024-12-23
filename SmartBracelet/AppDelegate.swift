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
import AudioToolbox
import AVKit

let log = XCGLogger()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var soundID: SystemSoundID = 0

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        application.applicationIconBadgeNumber = 0
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
        UNUserNotificationCenter.current().delegate = self
        
        Bugly.start(withAppId: "0c6ba8bb6a")
        
        var openCount = UserDefaults.standard.integer(forKey: "APPOPEN") 
        openCount += 1
        UserDefaults.standard.set(openCount, forKey: "APPOPEN")
        
        // 配置音频会话
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback)
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
    }
    
    public func pushToTab() {
//        if !CacheHelper().getCacheBool(name: "first") {
//            let sb = UIStoryboard(name: "Main", bundle: nil)
//            let vc = sb.instantiateViewController(withIdentifier: "GuideViewController")
//            window?.rootViewController = vc
//            return
//        }
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "MTabBarController")
        window?.rootViewController = vc
    }
    
    private func setupConfig() {
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
        UINavigationBar.appearance().tintColor = UIColor.text_primary
        UITabBarItem.appearance().setTitleTextAttributes([.foregroundColor: UIColor(hex: 0x0FC08D)], for: .selected)
        UITabBarItem.appearance().setTitleTextAttributes([.foregroundColor: UIColor(hex: 0x818181)], for: .normal)
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
    
    // 将文件复制到指定文件夹下
    func copyFileToDocumentsDirectory(fileName: String) {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("无法获取文档目录路径")
            return
        }
        
        let destinationURL = documentsDirectory.appendingPathComponent(fileName)
        
        if fileManager.fileExists(atPath: destinationURL.path) {
            print("文件已经存在于文档目录中")
            return
        }
        
        guard let sourceURL = Bundle.main.url(forResource: fileName, withExtension: nil) else {
            print("无法找到资源包中的文件")
            return
        }
        
        do {
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            print("文件成功复制到文档目录")
        } catch {
            print("复制文件时发生错误: \(error)")
        }
    }
    
    public func foundphone() {
        // 创建通知内容
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("device_tip", comment: "")
        content.body = NSLocalizedString("found_success", comment: "")
        content.badge = 1
        content.sound = .default

        // 设置触发器
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

        // 创建通知请求
        let request = UNNotificationRequest(identifier: "notification.id.01", content: content, trigger: trigger)

        // 添加通知请求到UNUserNotificationCenter
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("添加本地通知错误: \(error.localizedDescription)")
            } else {
                print("添加本地通知成功")
            }
        }
        
        DispatchQueue.main.async {
            [weak self] in
            
            
            let alert = UIAlertController(title: "device_tip".localized(), message: "found_success".localized(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "mine_confirm".localized(), style: .cancel, handler: { [weak self] action in
                // 停止播放声音
                AudioServicesDisposeSystemSoundID(self?.soundID ?? 0)
            }))
            UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: {
                
            })
        }
        
        let soundURL = Bundle.main.url(forResource: "Alarm", withExtension: "mp3")
        AudioServicesCreateSystemSoundID(soundURL as! CFURL, &soundID)
        AudioServicesPlaySystemSound(soundID)
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
    

}

extension String {
    func localized() -> String {
        return NSLocalizedString(self, comment: "")
    }
}

extension AppDelegate {
    public static func IsDeviceNotRound() -> Bool {
        if isXGZT {
            return XGZTBlueToothManager.shared.device?.screenType != 1
        }
        
        var type = BLEDeviceNameHandler().handleName()
        if type == 0 {
            type = bleSelf.bleModel.screenType
        }
        log.info("当前连接设备为：\(type == 1 ? "方形" : "圆形")")
        return type == 1
    }
}

