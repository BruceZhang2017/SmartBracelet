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
    var deviceSettingView: UIView? // 设备设置的视图
    var deviceView: DevicesView!
    var clockArray: [String] = []
    var width: CGFloat = 90
    var height: CGFloat = 150
    var deviceSettingsViewHeightMultiplier = 10
    var deviceSettingsView: DeviceSettingsViewController?
    var lblTitle: UILabel?
    var refreshTimer: DispatchSourceTimer?
    var documentController: UIDocumentInteractionController?
    var bHavenScanResult = false
    
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
            $0.layer.cornerRadius = 16
            $0.clipsToBounds = true
        }
        topView.addSubview(deviceView)
        deviceView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.leading.equalTo(16)
            make.trailing.equalTo(-16)
        }
        deviceView.setupUI()
        deviceView.refreshData()
        
        contentView.backgroundColor = UIColor.clear
        
        bleSelf.getSwitchForWristband()
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: Notification.Name("DevicesViewController"), object: nil)
        dialManagmentLabel.text = "dial_management".localized()
        initializeDeviceSettings()
        
        dialView.layer.cornerRadius = 16
        dialView.clipsToBounds = true
        
        btView.layer.cornerRadius = 16
        btView.clipsToBounds = true
        btView.addSubview(btButton)
        btButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(15)
            make.trailing.equalToSuperview().offset(-30)
            make.top.bottom.equalToSuperview()
        }
        btButton.setTitleColor(UIColor.black, for: .normal)
        btButton.titleLabel?.font = UIFont.body2()
        btButton.setTitle("push_to_bt_settings".localized(), for: .normal)
        btButton.contentHorizontalAlignment = .left
        btButton.titleLabel?.numberOfLines = 0
        btButton.addTarget(self, action: #selector(pushToMobileSettings), for: .touchUpInside)
        
        let ivRight = UIImageView(image: UIImage(named: "content_icon_nextgray_normal"))
        btView.addSubview(ivRight)
        ivRight.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-10)
            make.width.equalTo(10)
            make.height.equalTo(17)
        }
        
        
        addChangeButton() // 切换设备
        addReconnectButton() // 新增：添加重新连接按钮
        changeButtonAttr() // 切换设备入口
        
        width = (ScreenWidth - 60) / 3
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
        let button = UIBarButtonItem(
            title: "日志",
            style: .plain,
            target: self,
            action: #selector(didTapRightButton)
        )
        button.tintColor = .red  // 设置按钮颜色

        // 添加到右上角
        navigationItem.rightBarButtonItem = button
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
            $0.layer.cornerRadius = 16
            
        }
        contentView.addSubview(deviceSettingView!)
        deviceSettingView?.snp.makeConstraints {
            $0.left.equalTo(15)
            $0.right.equalTo(-15)
            $0.top.equalTo(dialView.snp.bottom).offset(15)
        }
        lblTitle = UILabel().then {
            $0.textColor = UIColor.black
            $0.font = UIFont.boldSystemFont(ofSize: 15)
            $0.text = "device_settings".localized()
        }
        deviceSettingView?.addSubview(lblTitle!)
        lblTitle?.snp.makeConstraints {
            $0.left.equalTo(15)
            $0.top.equalTo(10)
            $0.height.equalTo(20)
        }
        
        deviceSettingsView = DeviceSettingsViewController()
        addChild(deviceSettingsView!)
        deviceSettingView?.addSubview(deviceSettingsView!.view)
        deviceSettingsView?.view.snp.makeConstraints {
            $0.left.equalTo(0)
            $0.top.equalTo(lblTitle!.snp.bottom).offset(10)
            $0.right.equalTo(0)
            $0.height.equalTo(80 * deviceSettingsViewHeightMultiplier)
            $0.bottom.equalToSuperview()
        }
        bottomLConstraint.constant = CGFloat(80 * deviceSettingsViewHeightMultiplier + 70)
    }
    
    public func refreshHeight() {
        var tempMultiplier = 10 // 默认乘数
        // 将 deviceSettingsViewHeightMultiplier 修改为 14
        if (((XGZTBlueToothManager.shared.device?.functioncontrolflags ?? 0) >> 15) & 0x01) > 0 || (((XGZTBlueToothManager.shared.device?.functioncontrolflags ?? 0) >> 16) & 0x01) > 0 {
            tempMultiplier = 11
        } else {
            tempMultiplier = 10
        }
        deviceSettingsViewHeightMultiplier = max(tempMultiplier, 1)
        deviceSettingsView?.view.snp.remakeConstraints {
            $0.left.equalTo(0)
            $0.top.equalTo(lblTitle!.snp.bottom).offset(10)
            $0.right.equalTo(0)
            $0.height.equalTo(80 * deviceSettingsViewHeightMultiplier)
            $0.bottom.equalToSuperview()
        }
        updateDeviceSettingsViewBottomConstraint()
    }
    
    private func updateDeviceSettingsViewBottomConstraint() {
        bottomLConstraint.constant = CGFloat(80 * deviceSettingsViewHeightMultiplier + 70)
    }
    
    public func addChangeButton() {
        changeButton.setTitle("switch_device".localized(), for: .normal)
        if let image = UIImage(named: "icon_change_device") {
            changeButton.setImage(image, for: .normal)
        }
        changeButton.tintColor = UIColor.brand
        changeButton.layer.borderColor = UIColor.brand.cgColor
        changeButton.layer.borderWidth = 1.0
        changeButton.backgroundColor = .white
        changeButton.layer.cornerRadius = 15
        changeButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
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
        topView.addSubview(changeButton)
        changeButton.snp.makeConstraints { make in
            make.width.equalTo(120)
            make.height.equalTo(30)
            make.bottom.equalTo(-20)
            make.centerX.equalToSuperview().offset(-10)
        }
        changeButton.addTarget(self, action: #selector(addDevice), for: .touchUpInside)
    }
    
    // 新增：添加重新连接按钮
    public func addReconnectButton() {
        reconnectButton.setTitle("reconnect_device".localized(), for: .normal)
        reconnectButton.tintColor = UIColor.brand
        reconnectButton.layer.borderColor = UIColor.brand.cgColor
        reconnectButton.layer.borderWidth = 1.0
        reconnectButton.backgroundColor = .white
        reconnectButton.layer.cornerRadius = 15
        reconnectButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        // 添加按钮到视图中
        topView.addSubview(reconnectButton)
        reconnectButton.snp.makeConstraints { make in
            make.width.equalTo(110)
            make.height.equalTo(30)
            make.centerY.equalTo(changeButton)
            make.leading.equalTo(changeButton.snp.trailing).offset(10)
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
        cell.width.constant = width
        cell.height.constant = height
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
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
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
