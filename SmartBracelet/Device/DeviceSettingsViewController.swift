import UIKit
import TJDWristbandSDK
import Toaster

// MARK: - 常量定义
private extension String {
    static let kDeviceSettingsCellIdentifier = "DeviceSettingsCollectionViewCell"
    static let kDeviceStoryboard = "Device"
    static let kOTAStoryboard = "OTA"
    static let kNotificationName = "DeviceSettings"
    static let kHealthVCLoading = "HealthVCLoading"
}

private extension CGFloat {
    static let cellHeight: CGFloat = 88
    static let cellSpacing: CGFloat = 10
    static let sectionInset: CGFloat = 0
    static let collectionViewTopInset: CGFloat = 16
}

private extension Int {
    static let switchTagOffset = 999
    static let notificationRefresh = 1
    static let notificationTakePhoto = 2
    static let notificationDismissCamera = 3
    static let notificationXGZTStatus = 200
    static let healthLoadingXGZT = 10000
    static let healthLoadingPhoto = 10001
    static let healthLoadingSync = 1000
}

private extension TimeInterval {
    static let navigationDelay: TimeInterval = 0.3
    static let bluetoothOperationDelay: TimeInterval = 0.05
    static let bluetoothOperationDelayLong: TimeInterval = 0.1
}

// MARK: - 自定义CollectionViewCell
class DeviceSettingsCollectionViewCell: UICollectionViewCell {
    private var accessoryConstraints: [NSLayoutConstraint] = []

    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.text_secondary
        label.font = UIFont.body1()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 3
        label.lineBreakMode = .byWordWrapping
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()
    
    let detailLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.gray
        label.font = UIFont.body2()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }()
    
    var accessoryView: UIView? {
        didSet {
            NSLayoutConstraint.deactivate(accessoryConstraints)
            accessoryConstraints.removeAll()
            oldValue?.removeFromSuperview()
            guard let view = accessoryView else { return }
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
            accessoryConstraints = [
                view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
                view.centerYAnchor.constraint(equalTo: centerYAnchor),
                view.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8),
                view.leadingAnchor.constraint(greaterThanOrEqualTo: detailLabel.trailingAnchor, constant: 6),
                view.widthAnchor.constraint(greaterThanOrEqualToConstant: 6),
                view.heightAnchor.constraint(greaterThanOrEqualToConstant: 9)
            ]
            NSLayoutConstraint.activate(accessoryConstraints)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
    }
    
    private func setupLayout() {
        backgroundColor = .white
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.lightGray.withAlphaComponent(0.3).cgColor
        
        addSubview(titleLabel)
        addSubview(detailLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -10),
            detailLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8),
            detailLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -10),
            detailLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        detailLabel.text = nil
        accessoryView = nil
    }
}

// MARK: - 主控制器
class DeviceSettingsViewController: UIViewController {
    private let powerControlRowIdentifier = 1000
    private lazy var collectionView: UICollectionView = {
        // 初始化FlowLayout
        let flowLayout = UICollectionViewFlowLayout()
        let screenWidth = UIScreen.main.bounds.width - 30
        let itemWidth = (screenWidth - .sectionInset * 2 - .cellSpacing) / 2
        
        // 使用自动尺寸适配动态高度
        flowLayout.itemSize = CGSize(width: itemWidth, height: .cellHeight)
        flowLayout.minimumLineSpacing = .cellSpacing
        flowLayout.minimumInteritemSpacing = .cellSpacing
        flowLayout.sectionInset = UIEdgeInsets(
            top: .sectionInset,
            left: .sectionInset,
            bottom: .sectionInset,
            right: .sectionInset
        )
        
        // 初始化CollectionView
        let cv = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = UIColor.kF5F5F5
        cv.isScrollEnabled = true
        cv.dataSource = self
        cv.delegate = self
        cv.showsVerticalScrollIndicator = false
        
        // 注册Cell
        cv.register(
            DeviceSettingsCollectionViewCell.self,
            forCellWithReuseIdentifier: .kDeviceSettingsCellIdentifier
        )
        return cv
    }()
    
    var cameraViewController: CameraViewController?
    private var currentTime: TimeInterval = 0
    private var cachedDisplayTitles: [String]?
    var displayRowCount: Int { displayTitles.count }
    private var powerControlTitle: String { "device_power_controls".localized() }
    
    private var displayTitles: [String] {
        if let cached = cachedDisplayTitles {
            return cached
        }
        let device = XGZTBlueToothManager.shared.device
        let f15 = ((device?.functioncontrolflags ?? 0) >> 15) & 0x01
        let f16 = ((device?.functioncontrolflags ?? 0) >> 16) & 0x01
        let isNoScreen = device?.isNoScreenDevice ?? false
        let supportsWatchFace = device?.supportsWatchFaceMarket ?? true
        let supportsWeather = device?.supportsWeatherPush ?? true
        let supportsRaiseHand = device?.supportsRaiseHandScreen ?? true
        
        var filterCount = isXGZT ?
            (f15 > 0 ? 0 : 1) : 3
        if isXGZT {
            if f16 == 0 {
                filterCount += 1
            }
        }
        var result = Array(titles.dropLast(filterCount))
        
        let removedKeys: [String] = [
            supportsRaiseHand ? "" : "device_hand_up_screen".localized(),
            supportsWeather ? "" : "device_weather_push".localized(),
            supportsWatchFace ? "" : "device_dial_mall".localized()
        ].filter { !$0.isEmpty }
        
        if !removedKeys.isEmpty || isNoScreen {
            result = result.filter { item in
                if removedKeys.contains(item) { return false }
                // 无屏设备不需要卡包/联系人
                if isNoScreen && (item == "cardbag".localized() || item == "sync_contacts".localized()) {
                    return false
                }
                return true
            }
        }

        if isXGZT && !isNoScreen && f15 == 0 && f16 == 1 && result.indices.contains(14) {
            result[14] = "sync_contacts".localized()
        }
        if device?.supportsPowerControlCenter == true {
            result.append(powerControlTitle)
        }

        cachedDisplayTitles = result
        XLogger.shared.log("f15=\(f15) f16=\(f16) isNoScreen=\(isNoScreen) displayCount=\(result.count)")
        return result
    }
    
    private var titles: [String] {
        [
            "device_push_settings".localized(),
            "device_call_amind".localized(),
            "device_hand_up_screen".localized(),
            "device_longsit_amind".localized(),
            "device_longsit_amind_time".localized(),
            "drink_water_reminder".localized(),
            "drink_water_reminder_time".localized(),
            "device_weather_push".localized(),
            "device_alarm_settings".localized(),
            "device_search_settings".localized(),
            "device_device_info".localized(),
            "device_shark_photo".localized(),
            "synchronize_data".localized(),
            "ota".localized(),
            "cardbag".localized(),
            "sync_contacts".localized()
        ]
    }
    
    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitialConfig()
        setupCollectionViewConstraints()
        setupNotifications()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        collectionView.reloadData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(.kNotificationName), object: nil)
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }
}

// MARK: - 初始化配置
private extension DeviceSettingsViewController {
    func setupCollectionViewConstraints() {
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: .collectionViewTopInset),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
        ])
    }
    
    func setupInitialConfig() {
        view.backgroundColor = UIColor.kF5F5F5
        guard !isXGZT else { return }
        
        let bluetoothGroup = DispatchGroup()
        bluetoothGroup.enter()
        bleSelf.getAncsSwitchForWristband()
        bluetoothGroup.leave()
        
        bluetoothGroup.enter()
        DispatchQueue.main.asyncAfter(deadline: .now() + .bluetoothOperationDelay) {
            bleSelf.getLongSitForWristband()
            bluetoothGroup.leave()
        }
        
        bluetoothGroup.enter()
        DispatchQueue.main.asyncAfter(deadline: .now() + .bluetoothOperationDelayLong) {
            bleSelf.getDrinkForWristband()
            bluetoothGroup.leave()
        }
    }
    
    func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNotification(_:)),
            name: Notification.Name(.kNotificationName),
            object: nil
        )
    }
}

// MARK: - 通知处理
private extension DeviceSettingsViewController {
    @objc func handleNotification(_ notification: Notification) {
        guard let notificationType = notification.object as? Int else { return }
        
        switch notificationType {
        case .notificationRefresh:
            handleRefreshNotification()
        case .notificationTakePhoto:
            handleTakePhotoNotification()
        case .notificationDismissCamera:
            handleDismissCameraNotification()
        case .notificationXGZTStatus:
            handleXGZTStatusNotification()
        default:
            break
        }
        
        if isXGZT {
            NotificationCenter.default.post(
                name: Notification.Name(.kHealthVCLoading),
                object: Int.healthLoadingXGZT
            )
        } else {
            handleNonXGZTCameraLogic()
        }
    }
    
    private func handleRefreshNotification() {
        DispatchQueue.main.async { [weak self] in
            self?.collectionView.reloadData()
        }
    }
    
    private func handleTakePhotoNotification() {
        guard !isXGZT else { return }
        if Thread.isMainThread {
            takePhoto()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.takePhoto()
            }
        }
    }
    
    private func handleDismissCameraNotification() {
        guard !isXGZT else { return }
        DispatchQueue.main.async { [weak self] in
            self?.cameraViewController?.dismiss(animated: true) {
                self?.cameraViewController = nil
            }
        }
    }
    
    private func handleXGZTStatusNotification() {
        guard isXGZT else { return }
        if Thread.isMainThread {
            handleXGZTStatusOnMain()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.handleXGZTStatusOnMain()
            }
        }
    }
    
    private func handleXGZTStatusOnMain() {
        cachedDisplayTitles = nil // 清除缓存
        
        guard let device = XGZTBlueToothManager.shared.device else {
            Toast(text: "mine_unconnect".localized()).show()
            return
        }
        guard device.longsit == nil else { return }
        
        XGZTCommand.getSwitchStatus()
        XGZTCommand.getSwitchTableExtension()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .bluetoothOperationDelay) {
            XGZTCommand.getReminderInfo(eventType: 0)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .bluetoothOperationDelayLong) {
            XGZTCommand.getReminderInfo(eventType: 1)
        }
    }
    
    private func handleNonXGZTCameraLogic() {
        let currentTimestamp = Date().timeIntervalSince1970
        guard currentTime == 0 || abs(currentTimestamp - currentTime) >= 4 else { return }
        currentTime = currentTimestamp
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  UIApplication.shared.applicationState != .background,
                  self.cameraViewController != nil else { return }
            self.cameraViewController?.capturePhoto()
        }
    }
}

// MARK: - 业务逻辑
private extension DeviceSettingsViewController {
    func takePhoto() {
        guard !isXGZT else {
            NotificationCenter.default.post(
                name: Notification.Name(.kHealthVCLoading),
                object: Int.healthLoadingPhoto
            )
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  UIApplication.shared.applicationState != .background,
                  self.cameraViewController == nil else { return }
            
            let croppingParams = CroppingParameters(
                isEnabled: false,
                allowResizing: false,
                allowMoving: false,
                minimumSize: CGSize(width: 60, height: 60)
            )
            
            self.cameraViewController = CameraViewController(
                croppingParameters: croppingParams,
                allowsLibraryAccess: true
            ) { [weak self] _, _ in
                self?.dismiss(animated: true) {
                    self?.cameraViewController = nil
                    bleSelf.setCameraForWristband(false)
                    bleSelf.responseCameraForWristband()
                }
            }
            
            self.cameraViewController?.modalPresentationStyle = .fullScreen
            self.parent?.present(self.cameraViewController!, animated: true)
        }
    }
    
    @objc func switchValueChanged(_ sender: UISwitch) {
        let originalRow = sender.tag - .switchTagOffset
        let isSwitchOn = sender.isOn
        
        switch originalRow {
        case 1: handleCallReminderSwitch(isSwitchOn)
        case 2: handleRaiseHandScreenSwitch(isSwitchOn)
        case 3: handleLongSitReminderSwitch(isSwitchOn)
        case 5: handleDrinkReminderSwitch(isSwitchOn)
        default: break
        }
    }
    
    // 开关事件处理
    private func handleCallReminderSwitch(_ isOn: Bool) {
        if isXGZT {
            guard var device = XGZTBlueToothManager.shared.device else {
                Toast(text: "mine_unconnect".localized()).show()
                return
            }
            device.isIncomingCall = isOn
            XGZTBlueToothManager.shared.device = device
            XGZTCommand.setSwitchTableExtension(
                p0: getXGZTSwitchP0(),
                p1: getXGZTSwitchP1(),
                p2: getXGZTSwitchP2(),
                p3: getXGZTSwitchP3()
            )
        } else {
            bleSelf.notifyModel.isCall = isOn
            bleSelf.setAncsSwitchForWristband(bleSelf.notifyModel)
        }
    }
    
    private func handleRaiseHandScreenSwitch(_ isOn: Bool) {
        if isXGZT {
            guard let device = XGZTBlueToothManager.shared.device else {
                Toast(text: "mine_unconnect".localized()).show()
                return
            }
            guard device.supportsRaiseHandScreen else {
                Toast(text: "当前设备不支持抬手亮屏").show()
                return
            }
            XGZTBlueToothManager.shared.device?.isRaisehandtobrightenscreen = isOn
            XGZTCommand.setSwitchStatus(p0: getXGZTSwitchP0(), p1: getXGZTSwitchP1())
        } else {
            bleSelf.functionSwitchModel.isLightScreen = isOn
            bleSelf.setSwitchForWristband(bleSelf.functionSwitchModel)
        }
    }
    
    private func handleLongSitReminderSwitch(_ isOn: Bool) {
        if isXGZT {
            guard var device = XGZTBlueToothManager.shared.device,
                  !XGZTBlueToothManager.shared.isReconnectingNow else {
                Toast(text: "mine_unconnect".localized()).show()
                return
            }
            
            if isOn {
                device.longsit = device.longsit ?? ReminderInfoResponse(eventType: 0, cycle: 0, startHour: 0, startMinute: 0, endHour: 0, endMinute: 0, period: 0)
                device.longsit?.cycle = 0b11111111
                device.longsit?.startHour = 8
                device.longsit?.startMinute = 0
                device.longsit?.endHour = 0x14
                device.longsit?.endMinute = 0
                
                if device.longsit?.period == 0 {
                    device.longsit?.period = 0x0a
                    DispatchQueue.main.async { [weak self] in
                        self?.collectionView.reloadData()
                    }
                }
            } else {
                device.longsit?.cycle = 0b01111111
            }
            
            XGZTBlueToothManager.shared.device = device
            if let longsit = device.longsit {
                XGZTCommand.setReminderInfo(response: longsit)
            }
        } else {
            bleSelf.functionSwitchModel.isLongSit = isOn
            bleSelf.setSwitchForWristband(bleSelf.functionSwitchModel)
        }
    }
    
    private func handleDrinkReminderSwitch(_ isOn: Bool) {
        if isXGZT {
            guard var device = XGZTBlueToothManager.shared.device,
                  !XGZTBlueToothManager.shared.isReconnectingNow else {
                Toast(text: "mine_unconnect".localized()).show()
                return
            }
            
            if isOn {
                device.drinkWater = device.drinkWater ?? ReminderInfoResponse(eventType: 1, cycle: 0, startHour: 0, startMinute: 0, endHour: 0, endMinute: 0, period: 0)
                device.drinkWater?.cycle = 0b11111111
                device.drinkWater?.startHour = 0x08
                device.drinkWater?.startMinute = 0
                device.drinkWater?.endHour = 0x14
                device.drinkWater?.endMinute = 0
                
                if device.drinkWater?.period == 0 {
                    device.drinkWater?.period = 0x0a
                    DispatchQueue.main.async { [weak self] in
                        self?.collectionView.reloadData()
                    }
                }
            } else {
                device.drinkWater?.cycle = 0b01111111
            }
            
            XGZTBlueToothManager.shared.device = device
            if let drinkWater = device.drinkWater {
                XGZTCommand.setReminderInfo(response: drinkWater)
            }
        } else {
            bleSelf.functionSwitchModel.isDrink = isOn
            bleSelf.setSwitchForWristband(bleSelf.functionSwitchModel)
        }
    }
    
    // XGZT开关参数计算
    private func getXGZTSwitchP0() -> UInt8 {
        guard let device = XGZTBlueToothManager.shared.device else { return 0 }
        var p0: UInt8 = 0
        p0 |= device.isAntilostSwitch ? (1 << 0) : 0
        p0 |= device.isRaisehandtobrightenscreen ? (1 << 1) : 0
        p0 |= device.isAntilostSwitch ? (1 << 2) : 0
        p0 |= device.isSleepmonitoringSwitch ? (1 << 4) : 0
        p0 |= device.isMessageremindermainswitch ? (1 << 5) : 0
        p0 |= device.isRegularexercisedatauploadswitch ? (1 << 6) : 0
        p0 |= device.isGoalachievementswitch ? (1 << 7) : 0
        return p0
    }
    
    private func getXGZTSwitchP1() -> UInt8 {
        guard let device = XGZTBlueToothManager.shared.device else { return 0 }
        var p1: UInt8 = 0
        p1 |= device.isMessagescreendisplayswitch ? (1 << 1) : 0
        p1 |= device.isSoundswitch ? (1 << 2) : 0
        p1 |= device.isVibrationswitch ? (1 << 3) : 0
        p1 |= device.isRegularhealthdatauploadswitch ? (1 << 4) : 0
        p1 |= device.isMessagevibrationswitch ? (1 << 5) : 0
        return p1
    }
    
    private func getXGZTSwitchP2() -> UInt8 {
        guard let device = XGZTBlueToothManager.shared.device else { return 0 }
        var p2: UInt8 = 0
        p2 |= device.isFacebook ? (1 << 0) : 0
        p2 |= device.isFacebookMessenger ? (1 << 1) : 0
        p2 |= device.isInstagram ? (1 << 2) : 0
        p2 |= device.isWeibo ? (1 << 3) : 0
        p2 |= device.isKakaotalk ? (1 << 4) : 0
        p2 |= device.isFacebookpagemanager ? (1 << 5) : 0
        p2 |= device.isViber ? (1 << 6) : 0
        p2 |= device.isVkclient ? (1 << 7) : 0
        return p2
    }
    
    private func getXGZTSwitchP3() -> UInt8 {
        guard let device = XGZTBlueToothManager.shared.device else { return 0 }
        var p3: UInt8 = 0
        p3 |= device.isTelegram ? (1 << 0) : 0
        p3 |= device.isSnapchat ? (1 << 2) : 0
        p3 |= device.isDingTalk ? (1 << 3) : 0
        p3 |= device.isAlipay ? (1 << 4) : 0
        p3 |= device.isTiktok ? (1 << 5) : 0
        p3 |= device.isLinkedIn ? (1 << 6) : 0
        return p3
    }
    
    // 页面跳转
    @objc private func navigateToAlarmSettings() {
        let storyboard = UIStoryboard(name: .kDeviceStoryboard, bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "AlarmViewController") as? AlarmViewController else {
            return 
        }
        vc.hidesBottomBarWhenPushed = true
        parent?.navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - 健康检测功能列表
    
    /// 返回当前设备按固定顺序的健康检测卡片列表
    /// 顺序：心率(bit0) → 睡眠(bit4) → 血压(bit2) → 血氧(bit1) → 心电图ECG(bit8)
    private func healthCardsForCurrentDevice() -> [(flag: Int, titleKey: String, iconName: String, valueIndexOffset: Int, type: Int)] {
        let device = XGZTBlueToothManager.shared.device
        let flags = device?.healthcontrolflags ?? 0
        var cards: [(Int, String, String, Int, Int)] = []
        if flags & 1 == 1 {
            cards.append((0, "health_heart_rate", "health_heart", 0, 2))
        }
        if ((flags >> 4) & 1) == 1 {
            cards.append((4, "health_sleep", "health_sleep", 1, 3))
        }
        if ((flags >> 2) & 1) == 1 {
            cards.append((2, "health_blood_pressure", "health_bloodpressure", 2, 4))
        }
        if ((flags >> 1) & 1) == 1 {
            cards.append((1, "health_blood_oxygen", "health_bloodoxygen", 3, 5))
        }
        if ((flags >> 8) & 1) == 1 || (device?.supportsECG ?? false) {
            cards.append((8, "health_ecg", "health_ecg", 4, 6))
        }
        return cards
    }
}

// MARK: - UICollectionView DataSource
extension DeviceSettingsViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return displayTitles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: .kDeviceSettingsCellIdentifier,
            for: indexPath
        ) as! DeviceSettingsCollectionViewCell
        
        // 获取原始行号
        let originalRow = originalRow(for: indexPath.item)
        guard indexPath.item < displayTitles.count else {
            return cell
        }
        cell.titleLabel.text = displayTitles[indexPath.item]
        
        // 配置辅助视图
        configureAccessoryView(for: cell, originalRow: originalRow)
        
        // 配置详情文本
        configureDetailText(for: cell, originalRow: originalRow)
        
        // 强制刷新布局，确保多语言文本正确显示
        cell.layoutIfNeeded()
        
        return cell
    }
    
    // 配置辅助视图
    private func configureAccessoryView(for cell: DeviceSettingsCollectionViewCell, originalRow: Int) {
        let device = XGZTBlueToothManager.shared.device
        let supportsRaiseHand = device?.supportsRaiseHandScreen ?? true
        // 需要显示开关的行：1-3、5
        if [1, 2, 3, 5].contains(originalRow) {
            if originalRow == 2 && !supportsRaiseHand {
                cell.accessoryView = UIImageView(image: UIImage(named: "content_next"))
                return
            }
            let mSwitch = UISwitch()
            mSwitch.tag = .switchTagOffset + originalRow
            mSwitch.addTarget(self, action: #selector(switchValueChanged(_:)), for: .valueChanged)
            cell.accessoryView = mSwitch
            
            // 设置开关状态
            switch originalRow {
            case 1: // 来电提醒
                mSwitch.isOn = isXGZT ?
                    (XGZTBlueToothManager.shared.device?.isIncomingCall ?? false) :
                    bleSelf.notifyModel.isCall
            case 2: // 抬手亮屏
                mSwitch.isOn = isXGZT ?
                    (supportsRaiseHand && (XGZTBlueToothManager.shared.device?.isRaisehandtobrightenscreen ?? false)) :
                    bleSelf.functionSwitchModel.isLightScreen
                mSwitch.isEnabled = supportsRaiseHand
            case 3: // 久坐提醒
                mSwitch.isOn = isXGZT ?
                    ((((XGZTBlueToothManager.shared.device?.longsit?.cycle ?? 0) >> 7) & 1) > 0) :
                    bleSelf.functionSwitchModel.isLongSit
            case 5: // 喝水提醒
                mSwitch.isOn = isXGZT ?
                    ((((XGZTBlueToothManager.shared.device?.drinkWater?.cycle ?? 0) >> 7) & 1) > 0) :
                    bleSelf.functionSwitchModel.isDrink
            default: break
            }
        } else {
            // 其他行显示箭头
            cell.accessoryView = UIImageView(image: UIImage(named: "content_next"))
        }
    }
    
    // 配置详情文本
    private func configureDetailText(for cell: DeviceSettingsCollectionViewCell, originalRow: Int) {
        switch originalRow {
        case 4: // 久坐时间
            let minutes = isXGZT ?
                (XGZTBlueToothManager.shared.device?.longsit?.period ?? 0) :
                bleSelf.longSitModel.interval
            cell.detailLabel.text = "\(minutes)\("minute".localized())"
        case 6: // 喝水时间
            let minutes = isXGZT ?
                (XGZTBlueToothManager.shared.device?.drinkWater?.period ?? 0) :
                bleSelf.drinkModel.interval
            cell.detailLabel.text = "\(minutes)\("minute".localized())"
        default:
            cell.detailLabel.text = ""
        }
        cell.detailLabel.isHidden = (cell.detailLabel.text ?? "").isEmpty
    }
}

// MARK: - UICollectionView Delegate
extension DeviceSettingsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        // 防止重复点击
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.isUserInteractionEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + .navigationDelay) {
            cell?.isUserInteractionEnabled = true
        }
        
        // 检查设备连接状态
        guard bleSelf.isConnected || XGZTBlueToothManager.shared.device != nil else {
            Toast(text: "mine_unconnect".localized()).show()
            return
        }
        
        guard !XGZTBlueToothManager.shared.isReconnectingNow else {
            Toast(text: "mine_unconnect".localized()).show()
            return
        }
        
        // 获取原始行号
        if indexPath.item >= displayTitles.count {
            return
        }
        let originalRow = originalRow(for: indexPath.item)
        handleItemSelection(for: originalRow)
    }
    
    // 处理单元格点击事件
    private func handleItemSelection(for originalRow: Int) {
        switch originalRow {
        case 0: // 推送设置
            let storyboard = UIStoryboard(name: .kDeviceStoryboard, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "APNSViewController")
            vc.hidesBottomBarWhenPushed = true
            parent?.navigationController?.pushViewController(vc, animated: true)
            
        case 4: // 久坐时间设置
            DispatchQueue.main.asyncAfter(deadline: .now() + .navigationDelay) { [weak self] in
                let storyboard = UIStoryboard(name: .kDeviceStoryboard, bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "LongsitSettingsViewController")
                vc.hidesBottomBarWhenPushed = true
                self?.parent?.navigationController?.pushViewController(vc, animated: true)
            }
            
        case 6: // 喝水时间设置
            DispatchQueue.main.asyncAfter(deadline: .now() + .navigationDelay) { [weak self] in
                let storyboard = UIStoryboard(name: .kDeviceStoryboard, bundle: nil)
                guard let vc = storyboard.instantiateViewController(withIdentifier: "LongsitSettingsViewController") as? LongsitSettingsViewController else {
                           print("无法获取 LongsitSettingsViewController 实例")
                    return
                }
                vc.flag = 1
                vc.hidesBottomBarWhenPushed = true
                self?.parent?.navigationController?.pushViewController(vc, animated: true)
            }
            
        case 7: // 天气推送
            let vc = OpenWeatherViewController()
            vc.hidesBottomBarWhenPushed = true
            parent?.navigationController?.pushViewController(vc, animated: true)
            
        case 8: // 闹钟设置
            if isXGZT {
                XGZTCommand.getAlarmInfo(type: 1)
            } else {
                bleSelf.getAlarmForWristband()
            }
            perform(#selector(navigateToAlarmSettings), with: nil, afterDelay: .navigationDelay)
            
        case 9: // 查找设备
            let storyboard = UIStoryboard(name: .kDeviceStoryboard, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "DeviceFoundViewController")
            vc.hidesBottomBarWhenPushed = true
            parent?.navigationController?.pushViewController(vc, animated: true)
            
        case 10: // 设备信息
            let storyboard = UIStoryboard(name: .kDeviceStoryboard, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "DeviceInfoViewController")
            vc.hidesBottomBarWhenPushed = true
            parent?.navigationController?.pushViewController(vc, animated: true)
            
        case 11: // 遥控拍照
            if isXGZT {
                XGZTCommand.remotePhoto(action: 1)
            } else {
                bleSelf.setCameraForWristband(true)
            }
            takePhoto()
            
        case 12: // 同步数据
            if isXGZT {
                NotificationCenter.default.post(
                    name: Notification.Name(.kHealthVCLoading),
                    object: Int.healthLoadingSync
                )
                XGZTBlueToothManager.shared.handler.syncDevcieInfo()
            } else if bleSelf.isConnected {
                NotificationCenter.default.post(
                    name: Notification.Name(.kHealthVCLoading),
                    object: 2
                )
                BLEManager.shared.currentReadProgress = 3
                bleSelf.getStep()
            }

        case 13: // OTA升级
            let storyboard = UIStoryboard(name: .kOTAStoryboard, bundle: nil)
            guard let vc = storyboard.instantiateViewController(withIdentifier: "ABOtaViewController") as? ABOtaViewController else {
                return
            }
            vc.hidesBottomBarWhenPushed = true
            parent?.navigationController?.pushViewController(vc, animated: true)

        case 14: // 卡包
            let f15 = ((XGZTBlueToothManager.shared.device?.functioncontrolflags ?? 0) >> 15) & 0x01
            if f15 > 0 {
                let cardVC = CardBagTableViewController()
                cardVC.hidesBottomBarWhenPushed = true
                parent?.navigationController?.pushViewController(cardVC, animated: true)
            } else {
                let vc = SyncContactsViewController()
                vc.hidesBottomBarWhenPushed = true
                parent?.navigationController?.pushViewController(vc, animated: true)
            }

        case 15: // 同步联系人
            let vc = SyncContactsViewController()
            vc.hidesBottomBarWhenPushed = true
            parent?.navigationController?.pushViewController(vc, animated: true)

        case powerControlRowIdentifier:
            let vc = DevicePowerControlViewController()
            vc.hidesBottomBarWhenPushed = true
            parent?.navigationController?.pushViewController(vc, animated: true)
            
        default:
            print("点击的行数不需要处理")
            break
        }
    }

    private func originalRow(for displayIndex: Int) -> Int {
        let title = displayTitles[displayIndex]
        if title == powerControlTitle {
            return powerControlRowIdentifier
        }
        return titles.firstIndex(of: title) ?? displayIndex
    }
}

final class DevicePowerControlViewController: UIViewController {
    private struct PowerControlItem {
        let title: String
        let message: String
        let action: XGZTDevicePowerAction
    }

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = UIColor.kF5F5F5
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PowerControlCell")
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()

    private var items: [PowerControlItem] {
        guard let device = XGZTBlueToothManager.shared.device else { return [] }
        var result: [PowerControlItem] = []
        if device.supportsFactoryResetControl {
            result.append(PowerControlItem(
                title: "device_factory_reset".localized(),
                message: "device_factory_reset_desc".localized(),
                action: .factoryReset
            ))
        }
        if device.supportsRestartControl {
            result.append(PowerControlItem(
                title: "device_restart".localized(),
                message: "device_restart_desc".localized(),
                action: .restart
            ))
        }
        if device.supportsShutdownControl {
            result.append(PowerControlItem(
                title: "device_shutdown".localized(),
                message: "device_shutdown_desc".localized(),
                action: .shutdown
            ))
        }
        return result
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "device_power_controls".localized()
        view.backgroundColor = UIColor.kF5F5F5
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func confirmAction(for item: PowerControlItem) {
        guard XGZTBlueToothManager.shared.device != nil, XGZTBlueToothManager.shared.isconnected() else {
            Toast(text: "mine_unconnect".localized()).show()
            return
        }
        let alert = UIAlertController(
            title: "device_tip".localized(),
            message: item.message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "mine_cancel".localized(), style: .cancel))
        alert.addAction(UIAlertAction(title: "mine_confirm".localized(), style: .destructive, handler: { [weak self] _ in
            XGZTCommand.controlDevicePower(item.action)
            self?.navigationController?.popViewController(animated: true)
        }))
        present(alert, animated: true)
    }
}

extension DevicePowerControlViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PowerControlCell", for: indexPath)
        cell.accessoryType = .disclosureIndicator
        if #available(iOS 14.0, *) {
            var configuration = cell.defaultContentConfiguration()
            configuration.text = items[indexPath.row].title
            configuration.textProperties.color = .black
            configuration.textProperties.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            cell.contentConfiguration = configuration
        } else {
            cell.textLabel?.text = items[indexPath.row].title
            cell.textLabel?.textColor = .black
            cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        }
        return cell
    }
}

extension DevicePowerControlViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        confirmAction(for: items[indexPath.row])
    }
}
    
