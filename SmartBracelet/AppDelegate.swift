import UIKit
import IQKeyboardManagerSwift
import RealmSwift
import AudioToolbox
import AVKit
import Bugly

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var soundID: SystemSoundID = 0
    var audioPlayer: AVAudioPlayer?
    var foregroundObserver: ((Bool) -> Void)?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        configRealm()
        AMapServices.shared().apiKey = "0ed08fc41dc5bd1adc43b9189af816f7"
        window?.backgroundColor = UIColor.white
        IQKeyboardManager.shared.enable = true
        setupConfig()
        pushToTab()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (status, err) in
            if !status {
                XLogger.shared.log("当用户不同意授权通知权限，则做其他的判读")
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
        NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(timeZoneDidChange),
                    name: UIApplication.significantTimeChangeNotification,
                    object: nil
                )
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        foregroundObserver?(false)
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
            
    }
    
    @objc private func timeZoneDidChange() {
        let newTimeZone = TimeZone.current
        XLogger.shared.log("时区发生变化：\(newTimeZone.identifier), offset = \(newTimeZone.secondsFromGMT())")

        // 你的逻辑，比如重新同步服务器或设备时间
        if isXGZT && !sync_time_single {
            sync_time_single = true
            XGZTBlueToothManager.shared.handler.readDeviceInfo()
        }
    }

    public func pushToTab() {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "MTabBarController")
        window?.rootViewController = vc
        window?.makeKeyAndVisible()
    }

    private func setupConfig() {
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
        UINavigationBar.appearance().tintColor = UIColor.text_primary
        UITabBarItem.appearance().setTitleTextAttributes([.foregroundColor: UIColor(hex: 0x0FC08D)], for: .selected)
        UITabBarItem.appearance().setTitleTextAttributes([.foregroundColor: UIColor(hex: 0x818181)], for: .normal)
    }

    /// 配置数据库（修复Realm路径初始化）
    private func configRealm() {
        let dbVersion : UInt64 = 7
        let docPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0] as String
        let dbPath = docPath.appending("/bracelet.realm")
        // 关键修复：使用fileURLWithPath初始化本地文件路径（原代码可能返回nil）
        let config = Realm.Configuration(
            fileURL: URL(fileURLWithPath: dbPath),
            schemaVersion: dbVersion,
            migrationBlock: { (migration, oldSchemaVersion) in },
            deleteRealmIfMigrationNeeded: false
        )
        Realm.Configuration.defaultConfiguration = config
    }

    // 关键修复：确保所有UI和音频操作在主线程执行
    public func foundphone() {
        // 日志记录调用线程，辅助排查
        XLogger.shared.log("foundphone 调用线程: \(Thread.current.isMainThread ? "主线程" : "子线程")")
        
        // 强制切换到主线程执行（避免线程安全问题）
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 配置本地通知
            let content = UNMutableNotificationContent()
            content.title = NSLocalizedString("device_tip", comment: "")
            content.body = NSLocalizedString("found_success", comment: "")
            content.badge = 1
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            let request = UNNotificationRequest(identifier: "notification.id.01", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    XLogger.shared.log("添加本地通知错误: \(error.localizedDescription)")
                } else {
                    XLogger.shared.log("添加本地通知成功")
                }
            }

            // 配置音频会话（主线程中执行）
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.playAndRecord, options: [.defaultToSpeaker, .mixWithOthers])
                try audioSession.setActive(true)
            } catch {
                XLogger.shared.log("设置音频会话失败: \(error)")
                return
            }

            // 初始化并播放音频
            guard let soundURL = Bundle.main.url(forResource: "Alarm", withExtension: "mp3") else {
                XLogger.shared.log("未找到声音文件")
                return
            }
            
            do {
                self.audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                self.audioPlayer?.prepareToPlay()
                self.audioPlayer?.play()
            } catch {
                XLogger.shared.log("音频播放初始化失败: \(error)")
                return
            }

            // 显示UIAlertController（使用顶层VC避免nil）
            let alert = UIAlertController(
                title: "device_tip".localized(),
                message: "found_success".localized(),
                preferredStyle: .alert
            )
            
            // 添加停止播放的按钮动作（修复弃用API）
            alert.addAction(UIAlertAction(
                title: "mine_confirm".localized(),
                style: .cancel,
                handler: { [weak self] action in
                    guard let self = self else { return }
                    self.audioPlayer?.stop()
                    
                    // 关键修复：移除弃用的overrideOutputAudioPort，改用现代API
                    do {
                        let audioSession = AVAudioSession.sharedInstance()
                        try audioSession.setCategory(.ambient) // 恢复默认音频模式
                        try audioSession.setActive(false, options: .notifyOthersOnDeactivation) // 优雅停用
                    } catch {
                        XLogger.shared.log("恢复音频会话失败: \(error)")
                    }
                }
            ))
            
            // 关键修复：使用topMostViewController获取顶层VC，避免依赖keyWindow
            if let topVC = UIApplication.shared.topMostViewController() {
                topVC.present(alert, animated: true, completion: nil)
            } else {
                XLogger.shared.log("未找到可展示弹窗的顶层视图控制器")
            }
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
            XLogger.shared.log("Notification did receive, Is class UNTimeIntervalNotificationTrigger")
            UIApplication.shared.applicationIconBadgeNumber = 0
        } else if trigger.isKind(of: UNCalendarNotificationTrigger.classForCoder()) {
            XLogger.shared.log("Notification did receive, Is class UNCalendarNotificationTrigger")
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
        completionHandler([.alert, .badge, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let trigger = response.notification.request.trigger as? UNTimeIntervalNotificationTrigger {
            XLogger.shared.log("Notification did receive, Is class UNTimeIntervalNotificationTrigger2")
            UIApplication.shared.applicationIconBadgeNumber = 0
        } else if let trigger = response.notification.request.trigger as? UNCalendarNotificationTrigger {
            XLogger.shared.log("Notification did receive, Is class UNCalendarNotificationTrigger2")
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
        completionHandler()
    }
}

extension String {
    func localized() -> String {
        return NSLocalizedString(self, comment: "")
    }

    func localized(with arguments: CVarArg...) -> String {
        return String(format: NSLocalizedString(self, comment: ""), arguments: arguments)
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
        XLogger.shared.log("当前连接设备为：\(type == 1 ? "方形" : "圆形")")
        return type == 1
    }
}

extension UIApplication {
    /// 获取当前最顶层的非 UIAlertController 的视图控制器
    func topMostViewController() -> UIViewController? {
        guard let keyWindow = connectedScenes
           .compactMap({ $0 as? UIWindowScene })
           .flatMap({ $0.windows })
           .first(where: { $0.isKeyWindow }) else {
            return nil
        }
        return topMostViewController(for: keyWindow.rootViewController)
    }

    private func topMostViewController(for viewController: UIViewController?) -> UIViewController? {
        if let navigationController = viewController as? UINavigationController {
            return topMostViewController(for: navigationController.topViewController)
        } else if let tabBarController = viewController as? UITabBarController {
            return topMostViewController(for: tabBarController.selectedViewController)
        } else if viewController is UIAlertController {
            return topMostViewController(for: viewController?.presentingViewController)
        } else if let presentedViewController = viewController?.presentedViewController {
            return topMostViewController(for: presentedViewController)
        }
        return viewController
    }
}
