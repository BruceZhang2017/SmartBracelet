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
    static let cellHeight: CGFloat = 80
    static let cellSpacing: CGFloat = 14
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
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.text_secondary
        label.font = UIFont.body1()
        label.translatesAutoresizingMaskIntoConstraints = false
        // 允许自动换行
        label.numberOfLines = 0
        // 内容压缩阻力优先级设高，避免被压缩
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()
    
    let detailLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.gray
        label.font = UIFont.body2()
        label.translatesAutoresizingMaskIntoConstraints = false
        // 单行显示，过长时省略
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    var accessoryView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            guard let view = accessoryView else { return }
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
            NSLayoutConstraint.activate([
                view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
                view.centerYAnchor.constraint(equalTo: centerYAnchor),
                // 确保辅助视图有固定大小，避免影响布局
                view.widthAnchor.constraint(greaterThanOrEqualToConstant: 6),
                view.heightAnchor.constraint(greaterThanOrEqualToConstant: 9)
            ])
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
            // 标题左侧距离和上下边距
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
            
            // 限制标题最大宽度，为辅助视图留出空间
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -60),
            
            // 详情标签在标题右侧，垂直居中
            detailLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -22),
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
    
    private var displayTitles: [String] {
        if let cached = cachedDisplayTitles {
            return cached
        }
        let filterCount = isXGZT ?
            (((XGZTBlueToothManager.shared.device?.functioncontrolflags ?? 0) >> 15 & 0x0f) > 0 ? 0 : 1) : 2
        let result = Array(titles.dropLast(filterCount))
        cachedDisplayTitles = result
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
            "cardbag".localized()
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
        takePhoto()
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
    
    private func reloadCell(atRow originalRow: Int) {
        guard let targetIndex = getCollectionViewIndex(fromOriginalRow: originalRow) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.collectionView.reloadItems(at: [targetIndex])
        }
    }
    
    private func getCollectionViewIndex(fromOriginalRow originalRow: Int) -> IndexPath? {
        guard let filteredIndex = displayTitles.firstIndex(of: titles[originalRow]) else { return nil }
        return IndexPath(item: filteredIndex, section: 0)
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
                    reloadCell(atRow: 4)
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
                    reloadCell(atRow: 6)
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
        let vc = storyboard.instantiateViewController(withIdentifier: "AlarmViewController") as! AlarmViewController
        vc.hidesBottomBarWhenPushed = true
        parent?.navigationController?.pushViewController(vc, animated: true)
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
        let originalRow = titles.firstIndex(of: displayTitles[indexPath.item]) ?? indexPath.item
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
        // 需要显示开关的行：1-3、5
        if [1, 2, 3, 5].contains(originalRow) {
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
                    (XGZTBlueToothManager.shared.device?.isRaisehandtobrightenscreen ?? false) :
                    bleSelf.functionSwitchModel.isLightScreen
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
        let originalRow = titles.firstIndex(of: displayTitles[indexPath.item]) ?? indexPath.item
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
                let vc = storyboard.instantiateViewController(withIdentifier: "LongsitSettingsViewController") as! LongsitSettingsViewController
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
            let vc = storyboard.instantiateViewController(withIdentifier: "ABOtaViewController") as! ABOtaViewController
            vc.hidesBottomBarWhenPushed = true
            parent?.navigationController?.pushViewController(vc, animated: true)
            
        case 14: // 卡包
            let cardVC = CardBagTableViewController()
            cardVC.hidesBottomBarWhenPushed = true
            parent?.navigationController?.pushViewController(cardVC, animated: true)
            
        default:
            break
        }
    }
}
    
