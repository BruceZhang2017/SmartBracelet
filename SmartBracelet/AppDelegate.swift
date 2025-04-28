//
//  AppDelegate.swift
//  SmartBracelet
//
//  Created by apple on 2020/4/23.
//  Copyright © 2020 tjd. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift
import RealmSwift
import AudioToolbox
import AVKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var soundID: SystemSoundID = 0
    var audioPlayer: AVAudioPlayer?
    var foregroundObserver: ((Bool) -> Void)?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        application.applicationIconBadgeNumber = 0
        configRealm()
        AMapServices.shared().apiKey = "0ed08fc41dc5bd1adc43b9189af816f7"
        window?.backgroundColor = UIColor.white
        IQKeyboardManager.shared.enable = true
        setupConfig()
        pushToTab()
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

        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
        foregroundObserver?(true)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        foregroundObserver?(false)
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
            
    }

    public func pushToTab() {
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

    public func foundphone() {
        // 配置本地通知
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("device_tip", comment: "")
        content.body = NSLocalizedString("found_success", comment: "")
        content.badge = 1
        content.sound = .default

        // 设置触发器（5秒延迟）
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

        // 创建并添加通知请求
        let request = UNNotificationRequest(identifier: "notification.id.01", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("添加本地通知错误: \(error.localizedDescription)")
            } else {
                print("添加本地通知成功")
            }
        }

        // 配置音频会话使用内置扬声器
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, options: [.defaultToSpeaker, .mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            print("设置音频会话失败: \(error)")
            return
        }

        // 初始化并播放音频
        guard let soundURL = Bundle.main.url(forResource: "Alarm", withExtension: "mp3") else {
            print("未找到声音文件")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("音频播放初始化失败: \(error)")
            return
        }

        // 显示UIAlertController
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(title: "device_tip".localized(),
                                          message: "found_success".localized(),
                                          preferredStyle: .alert)
            
            // 添加停止播放的按钮动作
            alert.addAction(UIAlertAction(title: "mine_confirm".localized(),
                                          style: .cancel,
                                          handler: { action in
                self?.audioPlayer?.stop()
                
                // 恢复默认音频路由并取消激活会话
                do {
                    let audioSession = AVAudioSession.sharedInstance()
                    try audioSession.overrideOutputAudioPort(.none) // 弃用但兼容iOS13
                    try audioSession.setCategory(.ambient)        // 恢复默认音频模式
                    try audioSession.setActive(true)
                } catch {
                    print("恢复音频会话失败: \(error)")
                }
            }))
            
            // 展示alert
            UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
        }
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
            print("Notification did receive, Is class UNTimeIntervalNotificationTrigger2")
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
        // 如果触发器是 UNCalendarNotificationTrigger 类型
        else if let trigger = response.notification.request.trigger as? UNCalendarNotificationTrigger {
            print("Notification did receive, Is class UNCalendarNotificationTrigger2")
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
        print("当前连接设备为：\(type == 1 ? "方形" : "圆形")")
        return type == 1
    }
}

extension UIApplication {
    /// 获取当前最顶层的非 UIAlertController 的视图控制器
    func topMostViewController() -> UIViewController? {
        // 获取当前的 keyWindow
        guard let keyWindow = connectedScenes
           .compactMap({ $0 as? UIWindowScene })
           .flatMap({ $0.windows })
           .first(where: { $0.isKeyWindow }) else {
            return nil
        }

        // 从 keyWindow 的根视图控制器开始查找
        return topMostViewController(for: keyWindow.rootViewController)
    }

    private func topMostViewController(for viewController: UIViewController?) -> UIViewController? {
        // 如果视图控制器是 UINavigationController，获取其栈顶的视图控制器
        if let navigationController = viewController as? UINavigationController {
            return topMostViewController(for: navigationController.topViewController)
        }
        // 如果视图控制器是 UITabBarController，获取其选中的视图控制器
        else if let tabBarController = viewController as? UITabBarController {
            return topMostViewController(for: tabBarController.selectedViewController)
        }
        // 如果视图控制器是 UIAlertController，跳过并查找其父视图控制器的顶层视图控制器
        else if viewController is UIAlertController {
            return topMostViewController(for: viewController?.presentingViewController)
        }
        // 如果视图控制器有正在展示的视图控制器，继续查找该展示视图控制器的顶层视图控制器
        else if let presentedViewController = viewController?.presentedViewController {
            return topMostViewController(for: presentedViewController)
        }
        // 否则返回当前视图控制器
        return viewController
    }
}
