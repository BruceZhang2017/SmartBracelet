//
// Copyright © 2015-2018 bruce Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
//
//  DevicesViewController.swift
//  SmartBracelet
//
//  Created by bruce on 2020/8/28.
//  Copyright © 2020 tjd. All rights reserved.
//
    

import UIKit
import TJDWristbandSDK
import Toaster

var localMac = ""

class DevicesViewController: BaseViewController, UIDocumentInteractionControllerDelegate {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var dialManagmentLabel: UILabel!
    @IBOutlet weak var bottomLConstraint: NSLayoutConstraint!
    @IBOutlet weak var dialView: UIView!
    @IBOutlet weak var btView: UIView!
    let changeButton = UIButton(type: .system)
    let reconnectButton = UIButton(type: .system) // 新增重新连接按钮
    let btButton = UIButton(type: .system)
    private let btChevronImageView = UIImageView(image: UIImage(named: "content_icon_nextgray_normal"))
    private let topCardDividerView = UIView()
    var deviceSettingView: UIView? // 设备设置的视图
    var deviceView: DevicesView!
    var clockArray: [String] = []
    var width: CGFloat = 90
    var height: CGFloat = 150
    var deviceSettingsView: DeviceSettingsViewController?
    var lblTitle: UILabel?
    var refreshTimer: DispatchSourceTimer?
    var documentController: UIDocumentInteractionController?
    var bHavenScanResult = false
    private weak var topViewHeightConstraintRef: NSLayoutConstraint?
    private weak var dialViewHeightConstraintRef: NSLayoutConstraint?
    private weak var btViewHeightConstraintRef: NSLayoutConstraint?
    private weak var btViewTopConstraintRef: NSLayoutConstraint?
    private weak var dialViewTopConstraintRef: NSLayoutConstraint?
    private var lastDialLayoutWidth: CGFloat = 0
    private var contentBottomConstraint: NSLayoutConstraint?
    private var deviceSettingsHeightConstraint: NSLayoutConstraint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "device".localized()
        NotificationCenter.default.addObserver(
               self,
               selector: #selector(audioRouteChanged),
               name: AVAudioSession.routeChangeNotification,
               object: nil
           )
        deviceView = DevicesView().then {
            $0.backgroundColor = UIColor.white
            $0.layer.cornerRadius = 26
            $0.layer.cornerCurve = .continuous
            $0.clipsToBounds = true
        }
        topView.addSubview(deviceView)
        deviceView.setupUI()
        deviceView.refreshData()
        
        topViewHeightConstraintRef = fixedHeightConstraint(for: topView)
        dialViewHeightConstraintRef = fixedHeightConstraint(for: dialView)
        btViewHeightConstraintRef = fixedHeightConstraint(for: btView)
        btViewTopConstraintRef = topConstraint(for: btView)
        dialViewTopConstraintRef = topConstraint(for: dialView)
        configurePageAppearance()
        
        bleSelf.getSwitchForWristband()
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: Notification.Name("DevicesViewController"), object: nil)
        dialManagmentLabel.text = "dial_management".localized()
        dialManagmentLabel.textColor = UIColor.text_primary
        dialManagmentLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        initializeDeviceSettings()
        
        styleSectionCard(dialView)
        collectionView.backgroundColor = .clear
        collectionView.contentInset = .zero
        
        styleSectionCard(btView)
        btView.layer.cornerRadius = 30
        btView.addSubview(btButton)
        btButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(18)
            make.trailing.equalToSuperview().offset(-42)
            make.top.bottom.equalToSuperview().inset(12)
        }
        btButton.setTitleColor(UIColor.text_primary, for: .normal)
        btButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        btButton.setTitle("push_to_bt_settings".localized(), for: .normal)
        btButton.contentHorizontalAlignment = .left
        btButton.titleLabel?.numberOfLines = 0
        // 增加内容压缩阻力优先级，防止高度被压缩
        btButton.setContentCompressionResistancePriority(.required, for: .vertical)
        btButton.titleLabel?.setContentCompressionResistancePriority(.required, for: .vertical)
        btButton.addTarget(self, action: #selector(pushToMobileSettings), for: .touchUpInside)
        
        btChevronImageView.tintColor = UIColor.text_third
        btView.addSubview(btChevronImageView)
        btChevronImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-14)
            make.width.equalTo(8)
            make.height.equalTo(14)
        }
        
        topCardDividerView.backgroundColor = UIColor.brand.withAlphaComponent(0.08)
        deviceView.addSubview(topCardDividerView)
        topCardDividerView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(18)
            make.trailing.equalToSuperview().offset(-18)
            make.height.equalTo(1)
        }
        
        addChangeButton() // 切换设备
        addReconnectButton() // 新增：添加重新连接按钮
        changeButtonAttr() // 切换设备入口
        configureTopSectionLayout()
        configurePageVerticalRhythm()
        
        width = floor((ScreenWidth - 32 - 24) / 3)
        if AppDelegate.IsDeviceNotRound() { // 方形
            var w = isXGZT ? (XGZTBlueToothManager.shared.device?.screenWidth ?? 0) : bleSelf.bleModel.screenWidth
            let h = isXGZT ? (XGZTBlueToothManager.shared.device?.screenHeight ?? 0) : bleSelf.bleModel.screenHeight
            if w == 0 {
                w = 240
            }
            height = CGFloat(width) * CGFloat(h) / CGFloat(w)
        } else { // 圆形
            height =  width
        }
        
        XLogger.shared.log("width: \(width) height: \(height)")
        
        // 获取 AppDelegate 实例
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.foregroundObserver = { [weak self] isActive in
                if isActive {
                    self?.appDidBecomeActive()
                } else {
                    self?.appWillResignActive()
                }
            }
        }
        
        // 初始化并缓存 documentController，避免每次点击重复创建
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        let fileURL = documentsDirectory.appendingPathComponent("log.txt")
        documentController = UIDocumentInteractionController(url: fileURL)
        documentController?.delegate = self
        
        // 创建按钮
//        let button = UIBarButtonItem(
//            title: "日志",
//            style: .plain,
//            target: self,
//            action: #selector(didTapRightButton)
//        )
//        button.tintColor = .red  // 设置按钮颜色
//
//        // 添加到右上角
//        navigationItem.rightBarButtonItem = button
    }
    
    // 处理点击事件（注意使用 @objc 标记）
    @objc private func didTapRightButton() {
        guard let documentController else { return }
        // 构造一个以视图中心为原点的极小矩形作为锚点
        let centerRect = CGRect(
            x: view.bounds.midX - 1,
            y: view.bounds.midY - 1,
            width: 2,
            height: 2
        )
        
        // 直接使用 view 的 bounds 和 view 自身作为参数
        documentController.presentOpenInMenu(from: centerRect, in: view, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        deviceView?.refreshData()
        changeButtonAttr()
        refreshDevices()
        
        if isXGZT {
            refreshHeight()
            
        } else {
            Async.main(after: 1) {
                if bleSelf.isConnected { // 连接成功
                    bleSelf.notifyModel.isWechat = true
                    bleSelf.notifyModel.isQQ = true
                    bleSelf.notifyModel.isLinkedin = true
                    bleSelf.notifyModel.isFacebook = true
                    bleSelf.notifyModel.isTwitter = true
                    bleSelf.notifyModel.isWhatapp = true
                    bleSelf.notifyModel.isLine = true
                    bleSelf.notifyModel.isKakaoTalk = true
                    bleSelf.notifyModel.isFacebookMessage = true
                    bleSelf.notifyModel.isInstagram = true
                    bleSelf.setAncsSwitchForWristband(bleSelf.notifyModel)
                }
            }
        }
        
        if refreshTimer != nil {
            return
        }
        refreshTimer = DispatchSource.makeTimerSource(queue: .main)
        refreshTimer?.schedule(deadline: .now(), repeating: 4.0)
        refreshTimer?.setEventHandler { [weak self] in
            // 在主线程刷新视图（实际代码根据你的需求调整）
            self?.deviceView?.refreshData()
            XLogger.shared.log("每4秒钟刷新一次")
        }
        refreshTimer?.resume()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let currentWidth = collectionView.bounds.width
        if abs(currentWidth - lastDialLayoutWidth) > 0.5 {
            lastDialLayoutWidth = currentWidth
            updateDialSectionLayout()
            configurePageVerticalRhythm()
            collectionView.collectionViewLayout.invalidateLayout()
        }
        [dialView, btView, deviceSettingView].forEach { view in
            guard let view else { return }
            view.layer.shadowPath = UIBezierPath(roundedRect: view.bounds, cornerRadius: view.layer.cornerRadius).cgPath
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // 取消定时器并释放引用
        refreshTimer?.cancel()
        refreshTimer = nil
        
    }
    
    private func refreshDevices() {
        let lastestDeviceMac = UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? "00:00:00:00:00:00"
        let clockDir = UserDefaults.standard.dictionary(forKey: "MyClock") ?? [:]
        let clockStr = clockDir[lastestDeviceMac] as? [String] ?? ["_&&_&&_", "_&&_&&_", "_&&_&&_"]
        if clockStr.count > 0 {
            clockArray = clockStr
        } else {
            clockArray.removeAll()
        }
        collectionView?.reloadData()
    }
    
    private func checkIsNullForDial() -> Bool {
        if clockArray.count == 0 {
            return true
        }
        for item in clockArray {
            let array = item.components(separatedBy: "&&")
            if array[0] == "_" {
                return true
            } else {
                return false
            }
        }
        return false
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        // 解除回调
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.foregroundObserver = nil
        }
    }
    
    private func appDidBecomeActive() {
        XLogger.shared.log("App 进入前台")
        deviceView.refreshData()
        changeButtonAttr()
    }
    
    private func appWillResignActive() {
        XLogger.shared.log("App 进入后台")
    }
    
    @objc func audioRouteChanged(notification: Notification) {
           guard let reason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt else { return }

           switch AVAudioSession.RouteChangeReason(rawValue: reason) {
           case .newDeviceAvailable:
               XLogger.shared.log("经典蓝牙设备已连接")
               checkBluetoothDevice()
           case .oldDeviceUnavailable:
               XLogger.shared.log("经典蓝牙设备已断开")
               // 处理断开逻辑
               deviceView.refreshData(value: 100)
           default:
               break
           }
       }

       func checkBluetoothDevice() {
           let session = AVAudioSession.sharedInstance()
           let currentRoute = session.currentRoute

           for output in currentRoute.outputs {
               if output.portType == .bluetoothA2DP || output.portType == .carAudio {
                   XLogger.shared.log("检测到蓝牙设备：\(output.portName)")
               }
           }
       }
    
    // 设备设置
    private func initializeDeviceSettings() {
        deviceSettingView = UIView().then {
            $0.backgroundColor = UIColor.white
            $0.clipsToBounds = true
            $0.layer.cornerRadius = 26
            $0.layer.cornerCurve = .continuous
            
        }
        contentView.addSubview(deviceSettingView!)
        deviceSettingView?.snp.makeConstraints {
            $0.left.equalTo(15)
            $0.right.equalTo(-15)
            $0.top.equalTo(dialView.snp.bottom).offset(18)
        }
        lblTitle = UILabel().then {
            $0.textColor = UIColor.text_primary
            $0.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
            $0.text = "device_settings".localized()
        }
        deviceSettingView?.addSubview(lblTitle!)
        lblTitle?.snp.makeConstraints {
            $0.left.equalTo(18)
            $0.top.equalTo(18)
            $0.height.equalTo(22)
        }
        
        deviceSettingsView = DeviceSettingsViewController()
        addChild(deviceSettingsView!)
        deviceSettingView?.addSubview(deviceSettingsView!.view)
        deviceSettingsView?.view.backgroundColor = .clear
        deviceSettingsView?.view.translatesAutoresizingMaskIntoConstraints = false
        deviceSettingsHeightConstraint = deviceSettingsView?.view.heightAnchor.constraint(equalToConstant: 0)
        deviceSettingsHeightConstraint?.isActive = true
        NSLayoutConstraint.activate([
            deviceSettingsView!.view.leadingAnchor.constraint(equalTo: deviceSettingView!.leadingAnchor),
            deviceSettingsView!.view.trailingAnchor.constraint(equalTo: deviceSettingView!.trailingAnchor),
            deviceSettingsView!.view.topAnchor.constraint(equalTo: lblTitle!.bottomAnchor, constant: 14),
            deviceSettingsView!.view.bottomAnchor.constraint(equalTo: deviceSettingView!.bottomAnchor)
        ])
        deviceSettingsView?.contentHeightDidChange = { [weak self] height in
            self?.updateDeviceSettingsHeight(height)
        }
        bottomLConstraint.isActive = false
        contentBottomConstraint?.isActive = false
        contentBottomConstraint = contentView.bottomAnchor.constraint(equalTo: deviceSettingView!.bottomAnchor, constant: 20)
        contentBottomConstraint?.isActive = true
        if let deviceSettingView {
            styleSectionCard(deviceSettingView)
        }
        deviceSettingsView?.refreshContentLayout()
    }
    
    public func refreshHeight() {
        deviceSettingsView?.refreshContentLayout()
        configurePageVerticalRhythm()
    }
    
    public func addChangeButton() {
        changeButton.setTitle("switch_device".localized(), for: .normal)
        if let image = UIImage(named: "icon_change_device") {
            changeButton.setImage(image, for: .normal)
        }
        styleActionButton(changeButton, primary: false)
        // 设置图标的内边距
        changeButton.imageEdgeInsets = UIEdgeInsets(
            top: 0,
            left: -2,
            bottom: 0,
            right: 2
        )

        // 设置标题的内边距
        changeButton.titleEdgeInsets = UIEdgeInsets(
            top: 0,
            left: 2,
            bottom: 0,
            right: -2
        )
        // 添加按钮到视图中
        deviceView.addSubview(changeButton)
        changeButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(18)
            make.height.equalTo(42)
            make.bottom.equalToSuperview().offset(-14)
            make.width.greaterThanOrEqualTo(130)
        }
        changeButton.addTarget(self, action: #selector(addDevice), for: .touchUpInside)
    }
    
    // 新增：添加重新连接按钮
    public func addReconnectButton() {
        reconnectButton.setTitle("reconnect_device".localized(), for: .normal)
        styleActionButton(reconnectButton, primary: true)
        // 添加按钮到视图中
        deviceView.addSubview(reconnectButton)
        reconnectButton.snp.makeConstraints { make in
            make.leading.equalTo(changeButton.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-18)
            make.height.equalTo(42)
            make.centerY.equalTo(changeButton)
        }
        reconnectButton.addTarget(self, action: #selector(reconnectDevice), for: .touchUpInside)
    }
    
    private func changeButtonAttr() {
        if deviceView.isHidden == true {
            deviceSettingView?.isHidden = true
            btView.isHidden = true
            collectionView.isHidden = true
            dialView.isHidden = true
            changeButton.tintColor = UIColor.white
            changeButton.backgroundColor = .brand
            changeButton.layer.borderColor = UIColor.brand.cgColor
            changeButton.setTitle("device_add".localized(), for: .normal)
            if let image = UIImage(named: "icon_add_device") {
                changeButton.setImage(image, for: .normal)
            }
            changeButton.tag = 1
            
            // 新增：重新连接按钮隐藏逻辑
            reconnectButton.isHidden = true
        } else {
            deviceSettingView?.isHidden = false
            btView.isHidden = false
            collectionView.isHidden = false
            dialView.isHidden = false
            changeButton.tintColor = UIColor.brand
            changeButton.backgroundColor = .white
            changeButton.layer.borderColor = UIColor.brand.withAlphaComponent(0.20).cgColor
            changeButton.setTitle("deivce_unbind".localized(), for: .normal)
            if let image = UIImage(named: "icon_change_device") {
                changeButton.setImage(image, for: .normal)
            }
            changeButton.tag = 2
            
            if cacheDevices.count >= 1 && !XGZTBlueToothManager.shared.isconnected() {
                reconnectButton.isHidden = false
            } else {
                reconnectButton.isHidden = true
            }
        }
        updateTopActionLayout()
    }
    
    // 新增：重新连接按钮点击事件
    @objc private func reconnectDevice() {
        let lastestDeviceMac = UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? ""
        if lastestDeviceMac.isEmpty {
            Toast(text: "no_device_to_reconnect".localized()).show()
            return
        }
        
        Toast(text: "reconnecting_device".localized()).show()
        
        for device in cacheDevices {
            if device.max == lastestDeviceMac {
                XGZTBlueToothManager.shared.connectAndScan(to: lastestDeviceMac, deviceName: device.deviceName ?? "e watch")
            }
        }
    }
    
    @objc private func handleNotification(_ notification: Notification) {
        if let obj = notification.object as? String, obj.count > 0 {
            if obj == "1999" {
                DispatchQueue.main.async {
                    [weak self] in
                    self?.refreshHeight()
                }
                return
            }
            if obj == "2000" {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    guard localMac.count > 0 else {
                        return
                    }
                    if XGZTBlueToothManager.shared.device != nil && localMac == lastestDeviceMac {
                        XGZTBlueToothManager.shared.disconnectDevice()
                        UserDefaults.standard.set(lastestDeviceMac, forKey: "deleteLastestDeviceMac")
                        UserDefaults.standard.synchronize()
                        lastestDeviceMac = ""
                        UserDefaults.standard.removeObject(forKey: "LastestDeviceMac")
                        XGZTBlueToothManager.shared.stopScanning() // 停止扫描
                    }
                    BluetoothWatchDevice.deleteFromSandbox(mac: localMac)
                    localMac = ""
                    if (cacheDevices.count) > 0 {
                        if lastestDeviceMac == "" {
                            let model = cacheDevices.last
                            lastestDeviceMac = model?.max ?? ""
                            UserDefaults.standard.setValue(lastestDeviceMac, forKey: "LastestDeviceMac")
                            UserDefaults.standard.synchronize()
                        } else {
                            var temp = false
                            for model in cacheDevices {
                                if model.max ?? "" == lastestDeviceMac {
                                    temp = true
                                    break
                                }
                            }
                            if !temp {
                                let model = cacheDevices.last
                                lastestDeviceMac = model?.max ?? ""
                                UserDefaults.standard.setValue(lastestDeviceMac, forKey: "LastestDeviceMac")
                                UserDefaults.standard.synchronize()
                            }
                        }
                    } else {
                        if DeviceManager.shared.devices.count > 0 {
                            if lastestDeviceMac == "" {
                                lastestDeviceMac = DeviceManager.shared.devices.first?.mac ?? ""
                                UserDefaults.standard.setValue(lastestDeviceMac, forKey: "LastestDeviceMac")
                                UserDefaults.standard.synchronize()
                            }
                        }
                    }
                    XLogger.shared.log("删除后2，新的macaddress=\(lastestDeviceMac)")
                    NotificationCenter.default.post(name: Notification.Name("DeviceList"), object: "2")
                }
                return
            }
            if obj == "3000" {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    guard localMac.count > 0 else {
                        return
                    }
                    XGZTBlueToothManager.shared.disconnectDevice()
                    UserDefaults.standard.set(lastestDeviceMac, forKey: "deleteLastestDeviceMac")
                    UserDefaults.standard.synchronize()
                    lastestDeviceMac = ""
                    UserDefaults.standard.removeObject(forKey: "LastestDeviceMac")
                    XGZTBlueToothManager.shared.stopScanning() // 停止扫描
                    BluetoothWatchDevice.deleteFromSandbox(mac: localMac)
                    localMac = ""
                    if (cacheDevices.count) > 0 {
                        if lastestDeviceMac == "" {
                            let model = cacheDevices.last
                            lastestDeviceMac = model?.max ?? ""
                            UserDefaults.standard.setValue(lastestDeviceMac, forKey: "LastestDeviceMac")
                            UserDefaults.standard.synchronize()
                        } else {
                            var temp = false
                            for model in cacheDevices {
                                if model.max ?? "" == lastestDeviceMac {
                                    temp = true
                                    break
                                }
                            }
                            if !temp {
                                let model = cacheDevices.last
                                lastestDeviceMac = model?.max ?? ""
                                UserDefaults.standard.setValue(lastestDeviceMac, forKey: "LastestDeviceMac")
                                UserDefaults.standard.synchronize()
                            }
                        }
                    } else {
                        if DeviceManager.shared.devices.count > 0 {
                            if lastestDeviceMac == "" {
                                lastestDeviceMac = DeviceManager.shared.devices.first?.mac ?? ""
                                UserDefaults.standard.setValue(lastestDeviceMac, forKey: "LastestDeviceMac")
                                UserDefaults.standard.synchronize()
                            }
                        }
                    }
                    XLogger.shared.log("删除后，新的macaddress=\(lastestDeviceMac)")
      
                    NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "delete", userInfo: ["mac": localMac])
                    NotificationCenter.default.post(name: Notification.Name("DevicesViewController"), object: nil)
                    
                    NotificationCenter.default.post(name: Notification.Name("DeviceList"), object: "3")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        NotificationCenter.default.post(name: Notification.Name("DevicesViewController"), object: "1000")
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        XGZTBlueToothManager.shared.cancelAllConnections()
                    }
                }
                return
            }
            if obj == "4000" {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    [weak self] in
                    let vc = UIStoryboard(name: "Device", bundle: nil).instantiateViewController(withIdentifier: "DeviceSearchViewController")
                    vc.title = "device_add".localized()
                    vc.hidesBottomBarWhenPushed = true
                    self?.navigationController?.pushViewController(vc, animated: true)
                }
                return
            }
            if obj == "5000" {
                self.bHavenScanResult = false
                /// 创建二维码扫描
                let vc = ScannerVC()
                vc.modalPresentationStyle = .fullScreen
                //设置标题、颜色、扫描样式（线条、网格）、提示文字
                vc.setupScanner("device_scan".localized(), .blue, .grid, "device_scan_add_device".localized()) {[weak self] (code) in
                    // 扫描回调方法
                    XLogger.shared.log("扫描的结果是：\(code)")
                    
                    if self?.bHavenScanResult ?? false {
                        XLogger.shared.log("扫描的结果是重复了")
                        return
                    }
                    
                    guard !code.isEmpty else {
                        XLogger.shared.log("扫描的结果是无设备4")
                        self?.dismiss(animated: true, completion: nil)
                        return
                    }
                    
                    // 处理旧设备（含mac参数）
                    if code.contains("mac=") {
                        XLogger.shared.log("扫描的结果是旧设备")
                        self?.bHavenScanResult = true
                        if let mac = self?.extractMacValue(from: code) {
                            if bleSelf.bleModels.count > 0 {
                                for model in bleSelf.bleModels {
                                    let m = model.mac.replacingOccurrences(of: ":", with: "").lowercased()
                                    if m == mac.lowercased() {
                                        bleSelf.connectBleDevice(model: model)
                                        break
                                    }
                                }
                            } else {
                                BLEManager.shared.startScan()
                                Async.main(after: 1.5) {
                                    if bleSelf.bleModels.count > 0 {
                                        for model in bleSelf.bleModels {
                                            let m = model.mac.replacingOccurrences(of: ":", with: "").lowercased()
                                            if m == mac.lowercased() {
                                                bleSelf.connectBleDevice(model: model)
                                                break
                                            }
                                        }
                                    }
                                }
                            }

                        }
                    }
                    // 处理新设备（含k参数）
                    else if code.contains("k=") {
                        XLogger.shared.log("扫描的结果是新设备")
                        self?.bHavenScanResult = true
                        
                        // 手动解析k参数值（避免URLComponents旧系统兼容问题）
                        if let kParamStart = code.range(of: "k=")?.upperBound {
                            let kParamEnd = code[kParamStart...].range(of: "&")?.lowerBound ?? code.endIndex
                            let kValueStr = String(code[kParamStart..<kParamEnd])
                            XLogger.shared.log("解析k参数的原始值：\(kValueStr)")
                            
                            // 按|分割字符串，获取所有部分
                            let components = kValueStr.components(separatedBy: "|")
                            
                            // 检查是否有足够的部分
                            guard components.count >= 2 else {
                                XLogger.shared.log("扫描的结果有错误1：参数k的值格式不正确，至少需要3个|分隔的部分，实际有\(components.count)个")
                                self?.dismiss(animated: true, completion: nil)
                                return
                            }
                            
                            // 提取各个部分并去除首尾空格
                            let macAddress = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                            let deviceName = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                            XLogger.shared.log("解析到的mac地址是：\(macAddress)")
                            
                            if XGZTBlueToothManager.shared.isCurrentBleStateOFF() {
                                Toast(text: "ble_off".localized()).show()
                                XLogger.shared.log("蓝牙没有开启")
                            } else {
                                // 可以根据需要使用所有解析出的参数
                                XGZTBlueToothManager.shared.connectAndScan(to: macAddress, deviceName: deviceName)
                            }
                        } else {
                            XLogger.shared.log("扫描的结果有错误2：未找到k参数")
                            self?.dismiss(animated: true, completion: nil)
                        }
                    }
                    else {
                        XLogger.shared.log("扫描的结果有错误3：代码格式不匹配")
                    }
                    
                    // 关闭扫描页面（无论是否成功均关闭）
                    self?.dismiss(animated: true, completion: nil)
                }

                //Present到扫描页面
                self.navigationController?.present(vc, animated: true, completion: nil)
                return
            }
            XLogger.shared.log("刷新设备列表数据")
            DispatchQueue.main.async {
                [weak self] in
                
                if obj == "100" {
                    self?.deviceView?.refreshData(value: 100)
                    return
                }
                
                if obj == "1000" {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        [weak self] in
                        self?.deleteDeviceSetting() // 调整到设置页面
                    }
                    return
                }
                
                self?.deviceView?.refreshData()
                self?.changeButtonAttr()
                self?.refreshDevices()
            }
        }
    }

    func extractMacValue(from string: String) -> String? {
        let pattern = "mac="
        guard let range = string.range(of: pattern, options: .backwards) else {
            // 如果没有找到 "mac="，返回 nil
            return nil
        }
        // 截取 "mac=" 之后的字符串
        let macValue = string[range.upperBound...]
        return String(macValue)
    }
    
    @objc private func pushToMobileSettings() {
        let url = URL(string: "App-Prefs:root=Bluetooth")
        if UIApplication.shared.canOpenURL(url!) {
            UIApplication.shared.open(url!, options: [:], completionHandler: nil)
        }
    }
    
    private func deleteDeviceSetting() {
        let vc = RemoveDeviceViewController()
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
    }

    /// 表盘管理
    func pushToClockManage(index: Int) {
        if bleSelf.bleModel.screenWidth == 80 {
            let storyboard = UIStoryboard(name: "Device", bundle: nil)
            guard let myClockVC = storyboard.instantiateViewController(withIdentifier: "MyClockViewController") as? MyClockViewController else {
                return 
            }
            myClockVC.index = index
            navigationController?.pushViewController(myClockVC, animated: true)
            return
        }
        
        let storyboard = UIStoryboard(name: "Device", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ClockManageViewController") as? ClockManageViewController
        vc?.index = index
        navigationController?.pushViewController(vc!, animated: true)
    }
    
    @IBAction private func showPop(_ sender: Any) {
        
    }
    
    @objc public func addDevice() {
        if changeButton.tag == 1 {
            var count = DeviceManager.shared.devices.count
            count += cacheDevices.count
            let storyboard = UIStoryboard(name: "Device", bundle: nil)
            if count == 0 {
                let vc = UIStoryboard(name: "Device", bundle: nil).instantiateViewController(withIdentifier: "DeviceSearchViewController")
                vc.title = "device_add".localized()
                vc.hidesBottomBarWhenPushed = true
                navigationController?.pushViewController(vc, animated: true)
            } else {
                let vc = storyboard.instantiateViewController(withIdentifier: "DeviceListViewController")
                vc.title = "device_change".localized()
                vc.hidesBottomBarWhenPushed = true
                navigationController?.pushViewController(vc, animated: true)
            }
        } else {
            let alert = UIAlertController(title: "device_tip".localized(), message: "unbind_device_desc".localized(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "mine_cancel".localized(), style: .cancel, handler: { (action) in
                
            }))
            alert.addAction(UIAlertAction(title: "mine_confirm".localized(), style: .default, handler: { (action) in
                localMac = lastestDeviceMac
                XLogger.shared.log("删除设备：\(localMac)")
                if XGZTBlueToothManager.shared.device != nil {
                    XLogger.shared.log("自研手表，而且device不为空")
                    if XGZTBlueToothManager.shared.isReconnectingNow {
                        NotificationCenter.default.post(name: Notification.Name("DevicesViewController"), object: "2000")
                        return
                    }
                    
                    XGZTBlueToothManager.shared.switchAutoDisconnect = true
                    if isXGZT {
                        XGZTCommand.bindDevice(value: 2) // 解除绑定
                    } else {
                        NotificationCenter.default.post(name: Notification.Name("DevicesViewController"), object: "2000")
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        XGZTBlueToothManager.shared.cancelAllConnections()
                    }
                } else {
                    NotificationCenter.default.post(name: Notification.Name("DevicesViewController"), object: "2000")
                    let count = DeviceManager.shared.devices.count
                    if count <= 1 {
                        if count > 0 {
                            NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "delete", userInfo: ["mac": DeviceManager.shared.devices[0].mac])
                        }
                        NotificationCenter.default.post(name: Notification.Name("DevicesViewController"), object: nil)
                        BLEManager.shared.unbind()
                        UserDefaults.standard.removeObject(forKey: "LastestDeviceMac")
                    } else {
                        NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "delete", userInfo: ["mac": localMac])
                        let lastestDeviceMac = UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? ""
                        if lastestDeviceMac == localMac {
                            BLEManager.shared.unbind()
                            UserDefaults.standard.removeObject(forKey: "LastestDeviceMac")
                            NotificationCenter.default.post(name: Notification.Name("DevicesViewController"), object: nil)
                        }
                    }
                }
            }))
            present(alert, animated: true) {
                
            }
        }
    }
    
    @objc public func pushToDial() {
        if !bleSelf.isConnected && XGZTBlueToothManager.shared.device == nil {
            Toast(text: "mine_unconnect".localized()).show()
            return
        }
        pushToClockManage(index: 0)
    }
    
    // 实现 delegate 方法
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
    
    private func configurePageAppearance() {
        view.backgroundColor = UIColor(hex: 0xF7F8FC)
        topView.backgroundColor = .clear
        contentView.backgroundColor = .clear
        topViewHeightConstraintRef?.constant = 250
        btViewHeightConstraintRef?.constant = 60
        
        // 确保高度约束优先级最高，防止被压缩
        if let btHeightConstraint = btViewHeightConstraintRef {
            btHeightConstraint.priority = .required
        }
        if let topHeightConstraint = topViewHeightConstraintRef {
            topHeightConstraint.priority = .required
        }
    }

    private func topConstraint(for view: UIView) -> NSLayoutConstraint? {
        view.superview?.constraints.first(where: { constraint in
            constraint.firstItem as? UIView === view &&
            constraint.firstAttribute == .top &&
            constraint.secondAttribute == .bottom
        })
    }

    private func fixedHeightConstraint(for view: UIView) -> NSLayoutConstraint? {
        if let ownConstraint = view.constraints.first(where: { constraint in
            constraint.firstAttribute == .height && constraint.firstItem as? UIView === view && constraint.secondItem == nil
        }) {
            return ownConstraint
        }

        return view.superview?.constraints.first(where: { constraint in
            constraint.firstAttribute == .height && constraint.firstItem as? UIView === view && constraint.secondItem == nil
        })
    }
    
    private func styleSectionCard(_ view: UIView) {
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 26
        view.layer.cornerCurve = .continuous
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.brand.withAlphaComponent(0.06).cgColor
        view.layer.shadowColor = UIColor.brand.withAlphaComponent(0.06).cgColor
        view.layer.shadowOpacity = 1
        view.layer.shadowRadius = 18
        view.layer.shadowOffset = CGSize(width: 0, height: 8)
        view.layer.masksToBounds = false
    }
    
    private func styleActionButton(_ button: UIButton, primary: Bool) {
        button.layer.cornerRadius = 21
        button.layer.cornerCurve = .continuous
        button.layer.borderWidth = 1
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.tintColor = primary ? .white : UIColor.brand
        button.setTitleColor(primary ? .white : UIColor.brand, for: .normal)
        button.backgroundColor = primary ? UIColor.brand : UIColor.brand.withAlphaComponent(0.06)
        button.layer.borderColor = primary ? UIColor.brand.cgColor : UIColor.brand.withAlphaComponent(0.10).cgColor
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }

    private func configureTopSectionLayout() {
        deviceView.snp.remakeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalTo(16)
            make.trailing.equalTo(-16)
            make.bottom.equalToSuperview()
        }
        topCardDividerView.snp.remakeConstraints { make in
            make.leading.equalToSuperview().offset(18)
            make.trailing.equalToSuperview().offset(-18)
            make.bottom.equalTo(changeButton.snp.top).offset(-12)
            make.height.equalTo(1)
        }
    }

    private func configurePageVerticalRhythm() {
        // 这些视图的主约束来自 Main.storyboard，直接修改原约束常量，
        // 避免和 SnapKit 重新生成的第二套约束发生冲突。
        btViewTopConstraintRef?.constant = 20
        btViewHeightConstraintRef?.constant = 60
        dialViewTopConstraintRef?.constant = 100

        deviceSettingView?.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.right.equalTo(-15)
            make.top.equalTo(dialView.snp.bottom).offset(24)
        }
    }

    private func updateDeviceSettingsHeight(_ height: CGFloat) {
        deviceSettingsHeightConstraint?.constant = height
        view.layoutIfNeeded()
    }

    private func updateTopActionLayout() {
        if reconnectButton.isHidden {
            changeButton.snp.remakeConstraints { make in
                make.leading.equalToSuperview().offset(18)
                make.trailing.equalToSuperview().offset(-18)
                make.bottom.equalToSuperview().offset(-16)
                make.height.equalTo(42)
            }
        } else {
            changeButton.snp.remakeConstraints { make in
                make.leading.equalToSuperview().offset(18)
                make.trailing.equalTo(reconnectButton.snp.leading).offset(-12)
                make.bottom.equalToSuperview().offset(-16)
                make.height.equalTo(42)
            }
            reconnectButton.snp.remakeConstraints { make in
                make.trailing.equalToSuperview().offset(-18)
                make.bottom.equalToSuperview().offset(-16)
                make.height.equalTo(42)
                make.width.greaterThanOrEqualTo(132)
            }
        }
        topCardDividerView.snp.remakeConstraints { make in
            make.leading.equalToSuperview().offset(18)
            make.trailing.equalToSuperview().offset(-18)
            make.bottom.equalTo(changeButton.snp.top).offset(-14)
            make.height.equalTo(1)
        }
    }

    private func currentDialItemSize(for collectionView: UICollectionView) -> CGSize {
        let horizontalInsets = self.collectionView(collectionView, layout: collectionView.collectionViewLayout, insetForSectionAt: 0)
        let spacing = self.collectionView(collectionView, layout: collectionView.collectionViewLayout, minimumInteritemSpacingForSectionAt: 0)
        let availableWidth = collectionView.bounds.width
            - collectionView.contentInset.left
            - collectionView.contentInset.right
            - horizontalInsets.left
            - horizontalInsets.right
            - spacing * 2
        let itemWidth = max(floor(availableWidth / 3), 96)

        let previewHeight: CGFloat
        if AppDelegate.IsDeviceNotRound() {
            var watchWidth = isXGZT ? (XGZTBlueToothManager.shared.device?.screenWidth ?? 0) : bleSelf.bleModel.screenWidth
            let watchHeight = isXGZT ? (XGZTBlueToothManager.shared.device?.screenHeight ?? 0) : bleSelf.bleModel.screenHeight
            if watchWidth == 0 {
                watchWidth = 240
            }
            previewHeight = CGFloat(itemWidth) * CGFloat(watchHeight) / CGFloat(watchWidth)
        } else {
            previewHeight = itemWidth
        }

        let itemHeight = min(max(previewHeight, itemWidth), 142)
        width = itemWidth
        height = itemHeight
        return CGSize(width: itemWidth, height: itemHeight)
    }

    private func updateDialSectionLayout() {
        let itemSize = currentDialItemSize(for: collectionView)
        dialViewHeightConstraintRef?.constant = itemSize.height + 76
    }
}

extension DevicesViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: .kCellIdentifier, for: indexPath) as! ClockBCollectionViewCell
        cell.addImageView.image = UIImage(named: "icon_add2")
        if indexPath.row < clockArray.count  {
            let item = clockArray[indexPath.item]
            let array = item.components(separatedBy: "&&")
            if array[0] == "_" || (DeviceManager.shared.devices.count == 0 && (cacheDevices.count) == 0) {
                cell.clockImageView.isHidden = true
                cell.addImageView.isHidden = false
                cell.clockBGView.backgroundColor = UIColor.fill
            } else {
                cell.clockImageView.isHidden = false
                cell.addImageView.isHidden = true
                cell.clockBGView.backgroundColor = UIColor.clear
                if array[1].contains(".png") || array[1].contains(".jpg") || array[1].contains(".jpeg") || array[1].contains(".webp") {
                    XLogger.shared.log("保存的图片路径：\(array[1])")
                    if array[1].contains("Documents") {
                        cell.clockImageView.image = UIImage(contentsOfFile: array[1])
                    } else {
                        if array[1].contains("http") {
                            cell.clockImageView.kf.setImage(with: URL(string: array[1]))
                        } else {
                            let fullPath = NSHomeDirectory().appending("/Documents/").appending(array[1])
                            cell.clockImageView.image = UIImage(contentsOfFile: fullPath)
                        }
                    }
                }
            }
            
        } else {
            cell.clockImageView.isHidden = true
            cell.addImageView.isHidden = false
            cell.clockBGView.backgroundColor = UIColor.fill
        }
        let itemSize = currentDialItemSize(for: collectionView)
        cell.width.constant = itemSize.width
        cell.height.constant = itemSize.height
        return cell
    }
}

extension DevicesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        if !bleSelf.isConnected && XGZTBlueToothManager.shared.device == nil {
            Toast(text: "mine_unconnect".localized()).show()
            return
        }
        pushToClockManage(index: indexPath.row)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return currentDialItemSize(for: collectionView)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 18, bottom: 14, right: 18)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 14
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 14
    }
}

extension String {
    static let kDevice = "Device"
}


class VerticalButton: UIButton {

    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let imageViewSize = self.imageView?.frame.size,
              let titleLabelSize = self.titleLabel?.frame.size else {
            return
        }
        
        let totalHeight = imageViewSize.height + titleLabelSize.height
        
        self.imageEdgeInsets = UIEdgeInsets(
            top: -(totalHeight - imageViewSize.height),
            left: 0,
            bottom: 0,
            right: -titleLabelSize.width
        )
        
        self.titleEdgeInsets = UIEdgeInsets(
            top: 0,
            left: -imageViewSize.width,
            bottom: -(totalHeight - titleLabelSize.height),
            right: 0
        )
    }
    
    override var intrinsicContentSize: CGSize {
        guard let imageViewSize = self.imageView?.frame.size,
              let titleLabelSize = self.titleLabel?.frame.size else {
            return super.intrinsicContentSize
        }
        
        let width = max(imageViewSize.width, titleLabelSize.width)
        let height = imageViewSize.height + titleLabelSize.height + self.titleEdgeInsets.top
        
        return CGSize(width: width, height: height)
    }
}
