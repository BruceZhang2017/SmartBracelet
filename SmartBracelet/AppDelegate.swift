import UIKit
import IQKeyboardManagerSwift
import RealmSwift
import AudioToolbox
import AVKit
import Bugly
import JRDB

func postSameCrashDebugEvent(hypothesisId: String, location: String, msg: String, data: [String: Any] = [:]) {
    guard let url = URL(string: "http://192.168.2.154:7777/event") else { return }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    let payload: [String: Any] = [
        "sessionId": "same-crash-project",
        "runId": "pre-fix",
        "hypothesisId": hypothesisId,
        "location": location,
        "msg": "[DEBUG] \(msg)",
        "data": data,
        "ts": Int(Date().timeIntervalSince1970 * 1000)
    ]
    request.httpBody = try? JSONSerialization.data(withJSONObject: payload, options: [])
    URLSession.shared.dataTask(with: request).resume()
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var soundID: SystemSoundID = 0
    var audioPlayer: AVAudioPlayer?
    var foregroundObserver: ((Bool) -> Void)?
    private var audioInterruptionObserver: NSObjectProtocol?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        configRealm()
        AMapServices.shared().apiKey = "0ed08fc41dc5bd1adc43b9189af816f7"
        window?.backgroundColor = UIColor.white
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.enableAutoToolbar = false
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
        
        let clArray = [RunPoint.self, RunModel.self]
        JRDBMgr.shareInstance().registerClazzes(clArray)
        JRDBMgr.shareInstance().debugMode = false
        J_CreateTable(RunPoint.self)
        J_UpdateTable(RunPoint.self)
        J_CreateTable(RunModel.self)
        J_UpdateTable(RunModel.self)
        
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
        if let observer = audioInterruptionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    @objc private func timeZoneDidChange() {
        let newTimeZone = TimeZone.current
        XLogger.shared.log("时区发生变化：\(newTimeZone.identifier), offset = \(newTimeZone.secondsFromGMT())")

        if isXGZT && !sync_time_single {
            sync_time_single = true
            XGZTBlueToothManager.shared.handler.readDeviceInfo()
        }
    }

    public func pushToTab() {
        if window == nil {
            window = UIWindow(frame: UIScreen.main.bounds)
        }

        let sb = UIStoryboard(name: "Main", bundle: nil)
        let mainTabBarController = sb.instantiateViewController(withIdentifier: "MTabBarController")
        let isUserInfoSet = UserDefaults.standard.bool(forKey: "UserInfoSet")
        let lastDeviceMac = UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? ""
        let hasBoundDevice = lastDeviceMac.count > 0
        // #region debug-point A:push-to-tab
        postSameCrashDebugEvent(
            hypothesisId: "A",
            location: "AppDelegate.pushToTab",
            msg: "准备设置根控制器",
            data: [
                "isUserInfoSet": isUserInfoSet,
                "lastDeviceMac": lastDeviceMac,
                "hasBoundDevice": hasBoundDevice
            ]
        )
        // #endregion

        if !isUserInfoSet && !hasBoundDevice {
            let setupVC = SexSettingsViewController()
            let setupNav = UINavigationController(rootViewController: setupVC)
            setupNav.modalPresentationStyle = .fullScreen
            window?.rootViewController = setupNav
        } else {
            window?.rootViewController = mainTabBarController
        }

        window?.makeKeyAndVisible()
        // #region debug-point A:push-to-tab-finish
        postSameCrashDebugEvent(
            hypothesisId: "A",
            location: "AppDelegate.pushToTab",
            msg: "根控制器设置完成",
            data: [
                "rootType": String(describing: type(of: window?.rootViewController))
            ]
        )
        // #endregion
    }

    private func setupConfig() {
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
        UINavigationBar.appearance().tintColor = UIColor.text_primary
        UITabBarItem.appearance().setTitleTextAttributes([.foregroundColor: UIColor(hex: 0x0FC08D)], for: .selected)
        UITabBarItem.appearance().setTitleTextAttributes([.foregroundColor: UIColor(hex: 0x818181)], for: .normal)
        
        audioInterruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            self?.handleAudioInterruption(notification)
        }
    }

    private func configRealm() {
        let dbVersion : UInt64 = 7
        let docPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0] as String
        let dbPath = docPath.appending("/bracelet.realm")
        let config = Realm.Configuration(
            fileURL: URL(fileURLWithPath: dbPath),
            schemaVersion: dbVersion,
            migrationBlock: { (migration, oldSchemaVersion) in },
            deleteRealmIfMigrationNeeded: false
        )
        Realm.Configuration.defaultConfiguration = config
    }

    public func foundphone(isband: Bool = false) {
        XLogger.shared.log("foundphone 调用，isband: \(isband)，线程: \(Thread.current.isMainThread ? "主线程" : "子线程")")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.configureAudioSession(forDualBluetooth: !isband)
            
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

            guard let soundURL = Bundle.main.url(forResource: "Alarm", withExtension: "mp3") else {
                XLogger.shared.log("未找到声音文件")
                return
            }
            
            do {
                self.audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                self.audioPlayer?.prepareToPlay()
                self.audioPlayer?.play()
                XLogger.shared.log("音频播放成功，产品类型: \(isband ? "单BLE" : "双BLE+BT")")
            } catch {
                XLogger.shared.log("音频播放初始化失败: \(error)")
                return
            }

            let alert = UIAlertController(
                title: "device_tip".localized(),
                message: "found_success".localized(),
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(
                title: "mine_confirm".localized(),
                style: .cancel,
                handler: { [weak self] action in
                    guard let self = self else { return }
                    self.audioPlayer?.stop()
                    
                    do {
                        let audioSession = AVAudioSession.sharedInstance()
                        try audioSession.setCategory(.ambient)
                        try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
                        XLogger.shared.log("音频会话已恢复")
                    } catch {
                        XLogger.shared.log("恢复音频会话失败: \(error)")
                    }
                }
            ))
            
            if let topVC = UIApplication.shared.topMostViewController() {
                topVC.present(alert, animated: true, completion: nil)
            } else {
                XLogger.shared.log("未找到可展示弹窗的顶层视图控制器")
            }
        }
    }
    
    // MARK: - Audio Session Configuration
    
    private func configureAudioSession(forDualBluetooth isDual: Bool) {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            if isDual {
                try audioSession.setCategory(
                    .playAndRecord,
                    options: [.duckOthers, .defaultToSpeaker]
                )
                XLogger.shared.log("已配置音频会话为 playAndRecord 模式（双BLE+BT产品）")
            } else {
                try audioSession.setCategory(.ambient, options: [])
                XLogger.shared.log("已配置音频会话为 ambient 模式（单BLE产品）")
            }
            
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            XLogger.shared.log("音频会话配置失败: \(error.localizedDescription)")
        }
    }
    
    private func handleAudioInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo["AVAudioSessionInterruptionTypeKey"] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            XLogger.shared.log("音频播放被中断")
            audioPlayer?.pause()
            
        case .ended:
            XLogger.shared.log("音频中断结束")
            if let optionsValue = userInfo["AVAudioSessionInterruptionOptionKey"] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    XLogger.shared.log("恢复音频播放")
                    audioPlayer?.play()
                }
            }
            
        @unknown default:
            break
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
    public static func resolvedDeviceScreenMetrics() -> (width: Int, height: Int, isRect: Bool)? {
        if isXGZT {
            let width = XGZTBlueToothManager.shared.device?.screenWidth ?? 0
            let height = XGZTBlueToothManager.shared.device?.screenHeight ?? 0
            guard width > 0, height > 0 else {
                return nil
            }
            let screenType = XGZTBlueToothManager.shared.device?.screenType ?? 0
            let isRect = screenType > 0 ? screenType != 1 : width != height
            return (width, height, isRect)
        }

        guard bleSelf.isConnected || bleSelf.bleModel.mac.count > 0 else {
            return nil
        }

        let width = bleSelf.bleModel.screenWidth
        let height = bleSelf.bleModel.screenHeight
        guard width > 0, height > 0 else {
            return nil
        }

        var type = BLEDeviceNameHandler().handleName()
        if type == 0, bleSelf.bleModel.screenType > 0 {
            type = bleSelf.bleModel.screenType
        }
        let isRect = type == 1 ? true : (type == 2 ? false : width != height)
        return (width, height, isRect)
    }

    public static func IsDeviceNotRound() -> Bool {
        if let metrics = resolvedDeviceScreenMetrics() {
            XLogger.shared.log("当前连接设备为：\(metrics.isRect ? "方形" : "圆形")")
            return metrics.isRect
        }
        XLogger.shared.log("当前设备形态未知，按圆形预览兜底")
        return false
    }
}

extension UIApplication {
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
            return viewController?.presentingViewController
        } else if let presentedViewController = viewController?.presentedViewController {
            return topMostViewController(for: presentedViewController)
        }
        return viewController
    }
}
