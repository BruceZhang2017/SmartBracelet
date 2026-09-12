//
// Copyright © 2015-2018 bruce Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
//
//  HealthViewController.swift
//  SmartBracelet
//
//  Created by bruce on 2020/7/26.
//  Copyright © 2020 tjd. All rights reserved.
//
    

import UIKit
import Toaster
import TJDWristbandSDK
import YYImage
import MJRefresh
import StoreKit
import AliIotConnectKit
import JL_BLEKit
import DropDown

class HealthViewController: BaseViewController {
    @IBOutlet weak var footView: UIView!
    @IBOutlet weak var footMLabel: UILabel!
    @IBOutlet weak var footValueLabel: UILabel!
    @IBOutlet weak var footKLabel: UILabel!
    private let footBackgroundImageView = UIImageView()
    var collectionView: UICollectionView!
    let cellIdentifier = "CustomCell"
    private var currentModel: BLEModel!
    
    /// XGZT 健康卡片按固定顺序映射：心率 → 睡眠 → 血压 → 血氧 → 血糖 → 尿酸 → 血脂 → 心电图(ECG) → 脉搏 → 心率变异性 → 精神压力 → 疲劳度
    private var xgztHealthCards: [(type: Int, titleKey: String, subtitleKey: String?, iconName: String, valueOffset: Int, hasArrow: Bool)] {
        let device = XGZTBlueToothManager.shared.device
        let flags = device?.healthcontrolflags ?? 0
        var cards: [(type: Int, titleKey: String, subtitleKey: String?, iconName: String, valueOffset: Int, hasArrow: Bool)] = []
        if flags & 1 == 1 {
            cards.append((2, "health_heart_rate", nil, "health_heart", 0, false))
        }
        if ((flags >> 4) & 1) == 1 {
            cards.append((3, "health_sleep", nil, "health_sleep", 1, false))
        }
        if ((flags >> 2) & 1) == 1 {
            cards.append((4, "health_blood_pressure", nil, "health_bloodpressure", 2, false))
        }
        if ((flags >> 1) & 1) == 1 {
            cards.append((5, "health_blood_oxygen", nil, "health_bloodoxygen", 3, false))
        }
        if ((flags >> 3) & 1) == 1 || (device?.supportsBloodGlucose ?? false) {
            cards.append((7, "health_blood_glucose", nil, "health_glucose", 4, false))
        }
        if ((flags >> 7) & 1) == 1 || (device?.supportsUricAcid ?? false) {
            cards.append((8, "health_uric_acid", nil, "health_uric_acid", 5, false))
        }
        if ((flags >> 6) & 1) == 1 || (device?.supportsBloodLipid ?? false) {
            cards.append((9, "health_blood_lipid", nil, "health_blood_lipid", 6, false))
        }
        if ((flags >> 8) & 1) == 1 || (device?.supportsECG ?? false) {
            cards.append((6, "health_ecg", "health_ecg_subtitle", "health_ecg", 7, true))
        }
        if ((flags >> 9) & 1) == 1 || (device?.supportsPPG ?? false) {
            cards.append((10, "health_ppg", nil, "health_ppg", 8, true))
        }
        if ((flags >> 10) & 1) == 1 || (device?.supportsHRV ?? false) {
            cards.append((11, "health_hrv", nil, "health_hrv", 9, false))
        }
        if ((flags >> 11) & 1) == 1 || (device?.supportsStress ?? false) {
            cards.append((12, "health_stress", nil, "health_stress", 10, false))
        }
        if ((flags >> 12) & 1) == 1 || (device?.supportsFatigue ?? false) {
            cards.append((13, "health_fatigue", nil, "health_fatigue", 11, false))
        }
        return cards
    }

    private var shouldShowFemaleHealthEntry: Bool {
        isXGZT && XGZTBlueToothManager.shared.device?.sex == 1
    }

    private var healthCardItemCount: Int {
        isXGZT ? xgztHealthCards.count : 4
    }

    private var totalCollectionItemCount: Int {
        healthCardItemCount + (shouldShowFemaleHealthEntry ? 1 : 0)
    }

    private func isFemaleHealthItem(at indexPath: IndexPath) -> Bool {
        shouldShowFemaleHealthEntry && indexPath.item == totalCollectionItemCount - 1
    }

    private func xgztIcon(named iconName: String) -> UIImage? {
        if let image = UIImage(named: iconName) {
            return image
        }
        switch iconName {
        case "health_glucose":
            return UIImage(systemName: "drop.circle.fill")?.withTintColor(UIColor(red: 0.13, green: 0.56, blue: 0.95, alpha: 1.0), renderingMode: .alwaysOriginal)
        case "health_uric_acid":
            return UIImage(systemName: "aqi.medium")?.withTintColor(UIColor(red: 0.15, green: 0.68, blue: 0.61, alpha: 1.0), renderingMode: .alwaysOriginal)
        case "health_blood_lipid":
            return UIImage(systemName: "waveform.path.ecg.rectangle.fill")?.withTintColor(UIColor(red: 0.98, green: 0.61, blue: 0.29, alpha: 1.0), renderingMode: .alwaysOriginal)
        case "health_ppg":
            return UIImage(systemName: "waveform.path.ecg")?.withTintColor(UIColor(red: 0.23, green: 0.66, blue: 0.96, alpha: 1.0), renderingMode: .alwaysOriginal)
        case "health_hrv":
            return UIImage(systemName: "waveform.path.ecg.rectangle.fill")?.withTintColor(UIColor(red: 0.55, green: 0.42, blue: 0.96, alpha: 1.0), renderingMode: .alwaysOriginal)
        case "health_stress":
            return UIImage(systemName: "brain.head.profile")?.withTintColor(UIColor(red: 0.98, green: 0.69, blue: 0.22, alpha: 1.0), renderingMode: .alwaysOriginal)
        case "health_fatigue":
            return UIImage(systemName: "bolt.heart")?.withTintColor(UIColor(red: 0.96, green: 0.55, blue: 0.36, alpha: 1.0), renderingMode: .alwaysOriginal)
        default:
            return nil
        }
    }

    private func makeMetricValue(_ value: String, unit: String) -> NSMutableAttributedString {
        let text = NSMutableAttributedString()
        text.append(NSAttributedString(string: value, attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
        text.append(NSAttributedString(string: unit, attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
        return text
    }

    private func updateXGZTCardValue(at index: Int, value: NSMutableAttributedString, shouldReload: Bool = true) {
        guard arrayValue.indices.contains(index) else { return }
        arrayValue[index] = value
        if shouldReload {
            collectionView.reloadData()
        }
    }
    
    var currentDialog: UIView? //记录当前的弹框，在页面异常关闭时移除
    
    var flag = 0 // 属性的作用
    private var hud: JGProgressHUD? // loading图标
    private var loadingViewCheckTimer: Timer?
    private var continueReadFootValueTimer: Timer?
    var header: MJRefreshNormalHeader?
    var isFirst = false
    var indexBigData:Int = 0
    var mBigDataManager:JL_BigDataManager?
    var bt_sdk:JL_RunSDK?
    var bt_ble:QCY_BLEApple?
    var arrayValue : [NSMutableAttributedString] = []
    
    var testData:Data?
    var getTimes:Int = 0
    var sendTimesOk:Int = 0
    var sendTimesFail:Int = 0
    var testAuto:Bool = true
    var isSupportAlipay = false // 是否支持支付宝支付
    var bHavenScanResult = false
    
    private var manager = OpenWeatherManager()
    var currentProgress = 0
    var alertController: UIAlertController?
    let dropDown = DropDown()
     
    override func viewDidLoad() {
        bStyle = 1
        super.viewDidLoad()
        // 设置导航栏标题颜色
        title = "health_head".localized()
        for _ in 0..<12 {
            arrayValue.append(NSMutableAttributedString(string: "null_data".localized(), attributes: [.font: UIFont.body2(), .foregroundColor: UIColor.text_secondary]))
        }
        let openCount = UserDefaults.standard.integer(forKey: "APPOPEN") // 如果app打开次数
        if openCount >= 20 { //当打开次数>20次后，就打开邀请评论app的弹窗
            perform(#selector(self.showDialogForInviteAPPReview), with: nil, afterDelay: 20)
            UserDefaults.standard.set(0, forKey: "APPOPEN")
        }
        registerNotification()
        
        if !isXGZT {
            WUBleManager.shared.didSetUserinfo = {
                result in
                XLogger.shared.log("设置用户信息是否成功: \(result)")
            }
        }
        
        navigationItem.rightBarButtonItem?.title = "health_head".localized()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleDidEnterBackgroundNotification), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleDidEnterForgroundNotification), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        footView.backgroundColor = UIColor.clear
        footView.layer.cornerRadius = 20
        footView.layer.masksToBounds = false
        footView.layer.shadowColor = UIColor.black.withAlphaComponent(0.05).cgColor
        footView.layer.shadowOpacity = 1
        footView.layer.shadowRadius = 4
        footView.layer.shadowOffset = CGSize(width: 0, height: 2)
        footBackgroundImageView.image = UIImage(named: "health_step_card_bg")
        footBackgroundImageView.contentMode = .scaleAspectFill
        footBackgroundImageView.clipsToBounds = true
        footBackgroundImageView.layer.cornerRadius = 20
        footBackgroundImageView.isUserInteractionEnabled = false
        if footBackgroundImageView.superview == nil {
            footView.insertSubview(footBackgroundImageView, at: 0)
            footBackgroundImageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                footBackgroundImageView.leadingAnchor.constraint(equalTo: footView.leadingAnchor),
                footBackgroundImageView.trailingAnchor.constraint(equalTo: footView.trailingAnchor),
                footBackgroundImageView.topAnchor.constraint(equalTo: footView.topAnchor),
                footBackgroundImageView.bottomAnchor.constraint(equalTo: footView.bottomAnchor)
            ])
        }
        footValueLabel.textColor = UIColor.black
        footMLabel.textColor = UIColor.black
        footKLabel.textColor = UIColor.black
        footView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            footView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            footView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            footView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0)
        ])
        
        if isSupportAlipay && !isXGZT {
            AliConnectMananger_C.shared.bleSendDataDelegate = self // 阿里云相关逻辑
            
            bt_sdk = JL_RunSDK.sharedMe() as? JL_RunSDK
            bt_ble = bt_sdk?.bt_ble

            mBigDataManager = bt_ble?.mAssist .mCmdManager.mBigDataManager
            onSetupBigData()
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleFootCount))
        footView.isUserInteractionEnabled = true
        tap.numberOfTapsRequired = 1
        footView.addGestureRecognizer(tap)
        
        
        // 初始化UICollectionView
        let layout = UICollectionViewFlowLayout()
        let itemWidth = (UIScreen.main.bounds.width - 30) / 2 // 减去间距
        layout.itemSize = CGSize(width: itemWidth, height: 160)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        
        // 注册自定义的UICollectionViewCell类
        collectionView.register(HealthCollectionViewCell.self, forCellWithReuseIdentifier: cellIdentifier)

        // 添加UICollectionView到当前视图
        self.view.addSubview(collectionView)

        collectionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(footView.snp.bottom).offset(12)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-10)
        }
        
        // 设置 DropDown 数据源
        dropDown.dataSource = ["device_scan".localized(), "device_add".localized()]

        // 自定义下拉菜单样式
        dropDown.textFont = UIFont.systemFont(ofSize: 16)
        dropDown.textColor = .black
        dropDown.backgroundColor = .white
        dropDown.layer.cornerRadius = 16
        dropDown.clipsToBounds = true

        // 设置选中事件回调
        dropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            XLogger.shared.log("选中了第 \(index) 项: \(item)")
            self.bHavenScanResult = false
            // 您可以在这里处理选中后的操作，例如更新界面或发送请求
            if index == 1 {
                var count = DeviceManager.shared.devices.count
                count += cacheDevices.count
                let storyboard = UIStoryboard(name: "Device", bundle: nil)
                if count == 0 {
                    let vc = storyboard.instantiateViewController(withIdentifier: "DeviceSearchViewController") as? DeviceSearchViewController
                    vc?.title = "device_add".localized()
                    vc?.refreshBackButton()
                    vc?.hidesBottomBarWhenPushed = true
                    self.navigationController?.pushViewController(vc!, animated: true)
                } else {
                    let vc = storyboard.instantiateViewController(withIdentifier: "DeviceListViewController") as? DeviceListViewController
                    vc?.title = "device_change".localized()
                    vc?.refreshBackButton()
                    vc?.style = 1
                    vc?.hidesBottomBarWhenPushed = true
                    self.navigationController?.pushViewController(vc!, animated: true)
                }
            } else {
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
            }
            self.dropDown.clearSelection()
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
    
    func onSetupBigData(){
     
        mBigDataManager?.cmdBigDataMonitor({ [self] bigData in
            let status = bigData.mResult
            if status == .get{
                NSLog("--->ALi Get:")
                NSLog("%@",JL_Tools.dataChange(toString: bigData.mData))
                AliConnectMananger_C.shared.bleDataReceived(data: bigData.mData)
                
            }else if status == .sendSuccess{
                NSLog("--->ALi Send Success:\(bigData.mIndex)")
                
                JL_Tools.mainTask {
                    AudioServicesPlaySystemSound(1519);
                    self.sendTimesOk = self.sendTimesOk+1
                    let str = "GET:\(self.getTimes)    SEND(ok:\(self.sendTimesOk)  fail:\(self.sendTimesFail))"
                    //self.subLabel.text = str
                }

            }else{
                NSLog("--->ALi Send Fail! (Index:\(bigData.mIndex) Reason:\(bigData.mResult.rawValue))")

                JL_Tools.mainTask {
                    AudioServicesPlaySystemSound(1002);
                    self.sendTimesFail = self.sendTimesFail+1
                    let str = "GET:\(self.getTimes)    SEND(ok:\(self.sendTimesOk)  fail:\(self.sendTimesFail))"
                    //self.subLabel.text = str
                }
            }
        })
    }
    
    @objc private func handleDidEnterBackgroundNotification() {
        if hud != nil {
            hud?.hideHud()
        }
    }
    
    @objc private func handleDidEnterForgroundNotification() {
        if XGZTBlueToothManager.shared.centralManager?.state == .poweredOn {
            DispatchQueue.main.async {
                [weak self] in
                if self?.alertController != nil {
                    self?.alertController?.dismiss(animated: false)
                    self?.alertController = nil
                }
            }
            if cacheDevices.count >= 1 && !XGZTBlueToothManager.shared.isconnected() {
                for device in cacheDevices {
                    if device.max == lastestDeviceMac {
                        XGZTBlueToothManager.shared.connectAndScan(to: lastestDeviceMac, deviceName: device.deviceName ?? "e watch")
                    }
                }
            }
            return
        }
        if XGZTBlueToothManager.shared.centralManager?.state == .poweredOff {
            DispatchQueue.main.async {
                [weak self] in
                if self?.alertController != nil {
                    return
                }
                self?.alertController = UIAlertController(
                    title: nil,
                    message: "mine_bluetooth_unconnect".localized(),
                    preferredStyle: .alert
                )
                self?.alertController?.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
                let action = UIAlertAction(
                    title: "push_to_bt_settings".localized(),
                    style: .default
                ) { _ in
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    if UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, completionHandler: nil)
                    }
                }
                self?.alertController?.addAction(action)
                if self?.alertController != nil {
                    self?.navigationController?.tabBarController?.present(self!.alertController!, animated: true)
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 确保 TabBar 显示
        tabBarController?.tabBar.isHidden = false
        
        if !isFirst {
            readDBStep() // 从本地数据库中读取步数数据
        }
        isFirst = true
        if isXGZT {
            return
        }
        readDBHeart() // 从本地数据库中读取心跳数据
        readDBBlood() // 从本地数据库中读取血压数据
        readDBOxygen() // 从本地数据库中读取血氧数据
        readDBSleep() // 从本地数据库中读取睡眠数据
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        collectionView.reloadData()
    }
    
    deinit {
        unregisterNotification()
        currentDialog?.removeFromSuperview()
    }
    
    private func registerNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: Notification.Name("HealthViewController"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleShowLoading(_:)), name: Notification.Name("HealthVCLoading"), object: nil)
    }
    
    private func unregisterNotification() {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func refreshStepValue(unit: Float, v: Float) {
        refreshValue(label: footKLabel, value: String(format: "%.3f", v), unit: "health_kilo_calorie".localized(), size1: 20, size2: 10)
        if isXGZT {
            if XGZTBlueToothManager.shared.device?.baseUnit ?? 0 > 0 {
                let new = unit * 62 / 100
                let truncated = (new * 1000).rounded(.towardZero)/1000
                refreshValue(label: footMLabel, value: String(format: "%.3f", truncated), unit: "mile".localized(), size1: 20, size2: 10)
            } else {
                refreshValue(label: footMLabel, value: String(format: "%.3f", unit), unit: "health_walk_unit".localized(), size1: 20, size2: 10)
            }
        } else {
            refreshValue(label: footMLabel, value: String(format: "%.3f", unit), unit: "health_walk_unit".localized(), size1: 20, size2: 10)
        }
    }
    
    @objc private func handleNotification(_ notification: Notification) {
        let objc = notification.object as! String
        if objc == "step" {
            let step = isXGZT ? (XGZTBlueToothManager.shared.device?.currentStep ?? 0) : bleSelf.step
            DispatchQueue.main.async {
                [weak self] in
                
                self?.refreshValue(label: self?.footValueLabel, value: "\(step)", unit: "health_step_noun".localized(), size1: 40, size2: 14)
            }
            if (isXGZT) {
                let distance = Int(XGZTBlueToothManager.shared.device?.height ?? 0) * 415 / 1000
                let unit = step * distance
                let v = unit * Int(XGZTBlueToothManager.shared.device?.weight ?? 0) * 55
                DispatchQueue.main.async {
                    [weak self] in
                    let truncated = (Float(v) / 10000).rounded(.towardZero) / 1000
                    self?.refreshStepValue(unit: Float(unit) / 100000, v: Float(truncated))
                    XLogger.shared.log("距离：\(unit), 千卡：\(v)")
                }
            } else {
                let distance = bleSelf.distance
                let unit = Float(distance) / 1000
            
                let cal = bleSelf.cal
                let v = Float(cal) / 1000
                DispatchQueue.main.async {
                    [weak self] in
                    self?.refreshStepValue(unit: unit, v: v)
                }
            }
        } else if objc == "sleep" {
            DispatchQueue.main.async {
                [weak self] in
                if (isXGZT) {
                    let sleep = XGZTBlueToothManager.shared.device?.currentSleep ?? 0
                    if sleep > 0 {
                        let h = sleep / 60
                        let m = sleep % 60
                        let arrStr = NSMutableAttributedString()
                        arrStr.append(NSAttributedString(string: "\(h)", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
                        arrStr.append(NSAttributedString(string: "health_hour".localized(), attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
                        arrStr.append(NSAttributedString(string: "\(m)", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
                        arrStr.append(NSAttributedString(string: "health_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
                        self?.arrayValue[1] = arrStr
                        self?.collectionView.reloadData()
                    } else {
                        let arrStr = NSMutableAttributedString()
                        arrStr.append(NSAttributedString(string: "0", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
                        arrStr.append(NSAttributedString(string: "health_hour".localized(), attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
                        arrStr.append(NSAttributedString(string: "0", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
                        arrStr.append(NSAttributedString(string: "health_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
                        self?.arrayValue[1] = arrStr
                        self?.collectionView.reloadData()
                    }
                } else {
                    let array = BLEManager.shared.sleepArray[0]
                    if array.count > 0 {
                        let arr = BLEManager.shared.readSleepData(array: array) // 获得睡眠时间
                        let total = arr[1] + arr[2]
                        let h = total / 60
                        let m = total % 60
                        let arrStr = NSMutableAttributedString()
                        arrStr.append(NSAttributedString(string: "\(h)", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
                        arrStr.append(NSAttributedString(string: "health_hour".localized(), attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
                        arrStr.append(NSAttributedString(string: "\(m)", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
                        arrStr.append(NSAttributedString(string: "health_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
                        self?.arrayValue[1] = arrStr
                        self?.collectionView.reloadData()
                        
                    } else {
                        let arrStr = NSMutableAttributedString()
                        arrStr.append(NSAttributedString(string: "0", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
                        arrStr.append(NSAttributedString(string: "health_hour".localized(), attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
                        arrStr.append(NSAttributedString(string: "0", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
                        arrStr.append(NSAttributedString(string: "health_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
                        self?.arrayValue[1] = arrStr
                        self?.collectionView.reloadData()
                    }
                }
            }
        } else if objc == "heart" {
            if isXGZT {
                DispatchQueue.main.async {
                    [weak self] in
                    var heart = 0
                    heart = XGZTBlueToothManager.shared.device?.currentHeartrate ?? 0
                    let v = NSMutableAttributedString()
                    v.append(NSAttributedString(string: "\(heart)", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
                    v.append(NSAttributedString(string: "health_value_p_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
                    if heart > 0 {
                        self?.arrayValue[0] = v
                        self?.collectionView.reloadData()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    [weak self] in
                    if BLEManager.shared.heartArray.count == 0 {
                        return
                    }
                    var heart = 0
                    heart = BLEManager.shared.heartArray[0].heart
                    let v = NSMutableAttributedString()
                    v.append(NSAttributedString(string: "\(heart)", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
                    v.append(NSAttributedString(string: "health_value_p_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
                    if heart > 0 {
                        self?.arrayValue[0] = v
                        self?.collectionView.reloadData()
                    }
                }
            }
        } else if objc == "blood" {
            if isXGZT {
                DispatchQueue.main.async {
                    [weak self] in
                    var min = 0
                    var max = 0
                    min = XGZTBlueToothManager.shared.device?.currentDiastolicpressure ?? 0
                    max = XGZTBlueToothManager.shared.device?.currentSystolicpressure ?? 0
                    let v = NSMutableAttributedString()
                    v.append(NSAttributedString(string: "\(max)/\(min)", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
                    v.append(NSAttributedString(string: "MMHG", attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
                    if min > 0 {
                        self?.arrayValue[2] = v
                        self?.collectionView.reloadData()
                        UserDefaults.standard.setValue("\(max)/\(min)", forKey: "blood")
                        UserDefaults.standard.synchronize()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    [weak self] in
                    if BLEManager.shared.bloodArray.count == 0 {
                        return
                    }
                    var min = 0
                    var max = 0
                    min = BLEManager.shared.bloodArray[0].min
                    max = BLEManager.shared.bloodArray[0].max
                    let v = NSMutableAttributedString()
                    v.append(NSAttributedString(string: "\(max)/\(min)", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
                    v.append(NSAttributedString(string: "MMHG", attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
                    if min > 0 {
                        self?.arrayValue[2] = v
                        self?.collectionView.reloadData()
                        UserDefaults.standard.setValue("\(max)/\(min)", forKey: "blood")
                        UserDefaults.standard.synchronize()
                    }
                }
            }
        } else if objc == "oxygen" {
            if isXGZT {
                DispatchQueue.main.async {
                    [weak self] in
                    var value = 0
                    value = XGZTBlueToothManager.shared.device?.currentOxygen ?? 0
                    if value > 100 {
                        value = 0
                    }
                    let v = NSMutableAttributedString()
                    v.append(NSAttributedString(string: "\(value)", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
                    v.append(NSAttributedString(string: "SPO2", attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
                    if value > 0 {
                        self?.arrayValue[3] = v
                        self?.collectionView.reloadData()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    [weak self] in
                    var value = 0
                    if BLEManager.shared.oxygenArray.count > 0 {
                        value = BLEManager.shared.oxygenArray[0].oxygen
                    } else {
                        value = 0
                    }
                    if value > 100 {
                        value = 0
                    }
                    let v = NSMutableAttributedString()
                    v.append(NSAttributedString(string: "\(value)", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
                    v.append(NSAttributedString(string: "SPO2", attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
                    if value > 0 {
                        self?.arrayValue[3] = v
                        self?.collectionView.reloadData()
                    }
                }
            }
        } else if objc == "glucose" {
            guard isXGZT else { return }
            DispatchQueue.main.async { [weak self] in
                let value = XGZTBlueToothManager.shared.device?.currentBloodGlucose ?? 0
                guard value > 0 else { return }
                let v = self?.makeMetricValue(String(format: "%.1f", value), unit: " mmol/L") ?? NSMutableAttributedString()
                self?.updateXGZTCardValue(at: 4, value: v)
            }
        } else if objc == "uric" {
            guard isXGZT else { return }
            DispatchQueue.main.async { [weak self] in
                let value = XGZTBlueToothManager.shared.device?.currentUricAcid ?? 0
                guard value > 0 else { return }
                let v = self?.makeMetricValue("\(value)", unit: " umol/L") ?? NSMutableAttributedString()
                self?.updateXGZTCardValue(at: 5, value: v)
            }
        } else if objc == "lipid" {
            guard isXGZT else { return }
            DispatchQueue.main.async { [weak self] in
                let value = XGZTBlueToothManager.shared.device?.currentBloodLipid ?? 0
                guard value > 0 else { return }
                let v = self?.makeMetricValue(String(format: "%.2f", value), unit: " mmol/L") ?? NSMutableAttributedString()
                self?.updateXGZTCardValue(at: 6, value: v)
            }
        } else if objc == "ppg" {
            guard isXGZT else { return }
            DispatchQueue.main.async { [weak self] in
                let value = XGZTBlueToothManager.shared.device?.currentPPG ?? 0
                guard value > 0 else { return }
                let v = self?.makeMetricValue("\(value)", unit: " bpm") ?? NSMutableAttributedString()
                self?.updateXGZTCardValue(at: 8, value: v)
            }
        } else if objc == "hrv" {
            guard isXGZT else { return }
            DispatchQueue.main.async { [weak self] in
                let value = XGZTBlueToothManager.shared.device?.currentHRV ?? 0
                guard value > 0 else { return }
                let v = self?.makeMetricValue("\(value)", unit: " ms") ?? NSMutableAttributedString()
                self?.updateXGZTCardValue(at: 9, value: v)
            }
        } else if objc == "stress" {
            guard isXGZT else { return }
            DispatchQueue.main.async { [weak self] in
                let value = XGZTBlueToothManager.shared.device?.currentStress ?? 0
                guard value > 0 else { return }
                let v = self?.makeMetricValue("\(value)", unit: " health_score_unit".localized()) ?? NSMutableAttributedString()
                self?.updateXGZTCardValue(at: 10, value: v)
            }
        } else if objc == "fatigue" {
            guard isXGZT else { return }
            DispatchQueue.main.async { [weak self] in
                let value = XGZTBlueToothManager.shared.device?.currentFatigue ?? 0
                guard value > 0 else { return }
                let v = self?.makeMetricValue("\(value)", unit: " health_score_unit".localized()) ?? NSMutableAttributedString()
                self?.updateXGZTCardValue(at: 11, value: v)
            }
        } else if objc == "delete" {
            XLogger.shared.log("执行删除设备的动作")
            let userinfo = notification.userInfo as? [String : String]
            var mac = userinfo?["mac"] ?? ""
            if mac.count == 0 {
                mac = UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? ""
            }
            if mac.count > 0 {
                XLogger.shared.log("执行删除设备的动作: \(mac)")
                for device in DeviceManager.shared.devices {
                    if device.mac == mac {
                        if let model = try? BLEModel.er.array("mac = '\(mac)'").first {
                            try? model.er.delete()
                            XLogger.shared.log("执行删除设备的动作标志成功")
                        }
                        break
                    }
                }
            }
            if mac.count == 0 && DeviceManager.shared.devices.count == 1 {
                try? BLEModel.er.deleteAll() // 删除所有设备
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                [weak self] in
                DeviceManager.shared.initializeDevices()

                self?.refreshDBStep()
                self?.refreshDBHeart()
                self?.refreshDBSleep()
                self?.refreshDBBlood()
                self?.refreshDBOxygen()
                
                if DeviceManager.shared.devices.count == 0 {
                    self?.readDBStep(null: true)
                }
            }
        } else if objc == "refresh" {
            DispatchQueue.main.async {
                [weak self] in
                self?.collectionView.reloadData()
            }
        } else if objc == "head" {
            
        } else if objc == "scan" {
            didUpdateBLEModels(models: bleSelf.bleModels)
        } else if objc == "connected" { // 设备连接成功
            var bTemp = false
            if currentModel != nil {
                if let model = try? BLEModel.er.fromRealm(with: "\(currentModel.mac)"), model.mac.count > 0 {
                    XLogger.shared.log("数据库已经有该设备")
                } else {
                    bTemp = true
                }
            } else {
                bTemp = true
            }
            if bTemp {
                XLogger.shared.log("将设备添加到数据库里面")
                currentModel = BLEModel()
                currentModel.isBond = bleSelf.bleModel.isBond
                currentModel.uuidString = bleSelf.bleModel.uuidString
                currentModel.name = bleSelf.bleModel.name
                currentModel.localName = "ITIME"
                currentModel.rssi = bleSelf.bleModel.rssi
                currentModel.mac = bleSelf.bleModel.mac
                currentModel.hardwareVersion = bleSelf.bleModel.hardwareVersion
                currentModel.firmwareVersion = bleSelf.bleModel.firmwareVersion
                currentModel.vendorNumberASCII = bleSelf.bleModel.vendorNumberASCII
                currentModel.vendorNumberString = bleSelf.bleModel.vendorNumberString
                currentModel.internalNumber = bleSelf.bleModel.internalNumber
                currentModel.internalNumberString = bleSelf.bleModel.internalNumberString
                currentModel.imageName = "produce_image_no.2"
                try? currentModel?.er.save(update: true)
                DeviceManager.shared.initializeDevices() // 重新刷新绑定的设备
                NotificationCenter.default.post(name: Notification.Name("DevicesViewController"), object: "1")
                NotificationCenter.default.post(name: Notification.Name("DeviceList"), object: "1")
            }
        }
    }
    
    // 假设这是你的数据获取回调
    func didUpdateBLEModels(models: [TJDWristbandSDK.WUBleModel]) {
        // 过滤掉 mac 为空或者长度为 0 的设备
        bleSelf.bleModels = models.filter { $0.mac.count > 0 }
    }

    
    @objc private func handleShowLoading(_ notification: Notification) {
        let obj = notification.object as? Int ?? 0
        if obj == 0 {
            DispatchQueue.main.async {
                [weak self] in
                if UIApplication.shared.applicationState == .background {
                    return
                }
                if self?.alertController != nil {
                    self?.alertController?.dismiss(animated: false)
                    self?.alertController = nil
                }
            }
            
            return
        }
        if obj == 1 {
            DispatchQueue.main.async {
                [weak self] in
                if UIApplication.shared.applicationState == .background {
                    return
                }
                if self?.alertController != nil {
                    return
                }
                self?.alertController = UIAlertController(
                    title: nil,
                    message: "mine_bluetooth_unconnect".localized(),
                    preferredStyle: .alert
                )
                self?.alertController?.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
                let action = UIAlertAction(
                    title: "push_to_bt_settings".localized(),
                    style: .default
                ) { _ in
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    if UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, completionHandler: nil)
                    }
                }
                self?.alertController?.addAction(action)
                if self?.alertController != nil {
                    self?.navigationController?.tabBarController?.present(self!.alertController!, animated: true)
                }
            }
            return
        }
        if obj == 2 {
            if isSupportAlipay {
                checkFGSStatus() // 连接成功后，再检查
            }
            XLogger.shared.log("显示loading图片")
            if hud != nil {
                hud?.dismiss(animated: false)
                hud = nil
            }
            if let delegate  = UIApplication.shared.delegate as? AppDelegate {
                hud = JGProgressHUD(style: .light)
                let gifImage = UIImage.gifImageWithName("loading")
                let imageView = UIImageView(image: gifImage)
                let indicatorView = JGProgressHUDImageIndicatorView(contentView: imageView)
                hud?.indicatorView = indicatorView
                hud?.textLabel.text = "\("sync_data".localized())0/9"
                hud?.show(in: delegate.window ?? UIView())
            }
            startLoadingViewCheckTimer()
            return
        }
        if obj == 3 {
            endLoadingViewCheckTimer()
            DispatchQueue.main.async {
                [weak self] in
                if self?.currentProgress ?? 0 > 1 {
                    self?.hud?.textLabel.text = "\("sync_data".localized())9/9"
                } else {
                    var i = 2
                    self?.hud?.textLabel.text = "\("sync_data".localized())\(i)/9"
                    // 创建一个计时器，每秒增加i直到i达到9
                    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                        if i < 9 {
                            i += 1
                            self?.hud?.textLabel.text = "\("sync_data".localized())\(i)/9"
                        } else {
                            timer.invalidate() // 停止计时器
                        }
                    }
                }
                self?.currentProgress = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self?.hud?.dismiss(animated: false)
                }
            }
            if isXGZT {
                return
            }
            manager.syncTemprature() //  连接成功后，则同步天气。
            BLEManager.shared.currentReadProgress = 0
            if bleSelf.isConnected == false {
                continueReadFootValueTimer?.invalidate()
                continueReadFootValueTimer = nil
            }
            if continueReadFootValueTimer != nil {
                return
            }
            continueReadFootValueTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { t in
                if BLEManager.shared.needContinueRead() {
                    BLEManager.shared.startContinueRead() // 每秒都读取一下步数
                }
            })
            RunLoop.current.add(continueReadFootValueTimer!, forMode: .common)
            
        }
        if obj == 100 {
            let userinfo = notification.userInfo as? [String : String]
            currentProgress = Int(userinfo?["msg"] ?? "0") ?? 0
            let msg = "\("sync_data".localized())\(currentProgress)/9"
            DispatchQueue.main.async {
                [weak self] in
                self?.hud?.textLabel.text = msg
            }
        }
        if obj == 1000 {
            XLogger.shared.log("显示loading图片")
            if hud != nil {
                hud?.dismiss(animated: false)
                hud = nil
            }
            if let delegate  = UIApplication.shared.delegate as? AppDelegate {
                hud = JGProgressHUD(style: .light)
                let gifImage = UIImage.gifImageWithName("loading")
                let imageView = UIImageView(image: gifImage)
                let indicatorView = JGProgressHUDImageIndicatorView(contentView: imageView)
                hud?.indicatorView = indicatorView
                hud?.textLabel.text = "\("sync_data".localized())"
                hud?.show(in: delegate.window ?? UIView())
            }
            startLoadingViewCheckTimer()
        }
        if obj == 2000 {
            endLoadingViewCheckTimer()
            DispatchQueue.main.async {
                [weak self] in
                self?.hud?.dismiss(animated: false)
                self?.collectionView.reloadData()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                [weak self] in
                guard let s = self else {
                    return
                }
                s.manager.syncTemprature(flag: 1) //  连接成功后，则同步天气。
            }
        }
        if obj == 10000 {
            startPhoto()
        }
        if obj == 10001 {
            takePhoto()
        }
        if obj == 10002 {
            closePhoto()
        }
    }
    
    private func startLoadingViewCheckTimer() {
        XLogger.shared.log("张晓飞：启动加载loading的检查")
        endLoadingViewCheckTimer()
        loadingViewCheckTimer = Timer.scheduledTimer(withTimeInterval: 20, repeats: false, block: { (timer) in
            NotificationCenter.default.post(name: Notification.Name("HealthVCLoading"), object: 3)
        })
        RunLoop.current.add(loadingViewCheckTimer!, forMode: .common)
    }
    
    private func endLoadingViewCheckTimer() {
        loadingViewCheckTimer?.invalidate()
        loadingViewCheckTimer = nil
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let vc = segue.destination as? HealthDetailViewController else {
            return
        }
        vc.colors = [UIColor.kFFB642, UIColor.kFF5E46]
        vc.type = flag
    }
    
    // MARK: - Action
    
    @objc func handleFootCount() {
        flag = 0
        let vc = HealthDetailViewController()
        vc.type = 0
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc func handleFemaleHealthTapped() {
        // 从数据管理器获取周期配置
        let config = FemaleCycleDataManager.shared.getCycleConfiguration()

        // 判断是否已经设置过经期数据
        // 使用 isConfigured 字段来判断用户是否已配置过，而不是仅检查默认值
        let hasConfigured = config.isConfigured

        if hasConfigured {
            // 已设置：跳转到日历页面
            XLogger.shared.log("女性健康已配置，跳转到日历页面")
            let vc = FemaleCycleCalendarViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        } else {
            // 未设置：跳转到设置页面
            XLogger.shared.log("女性健康未配置，跳转到设置页面")
            let vc = FemaleHealthViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    @IBAction func addDevice(_ sender: Any) {
        
        // 获取导航栏按钮的视图
        if let rightBarButton = self.navigationItem.rightBarButtonItem,
           let view = rightBarButton.value(forKey: "view") as? UIView {
            // 设置锚点视图
            dropDown.anchorView = view
            dropDown.bottomOffset = CGPoint(x: 0, y: view.bounds.height)
            dropDown.show()
        }
    }
    
    private func refreshValue(label: UILabel?, value: String, unit: String, size1: CGFloat, size2: CGFloat) {
        label?.textAlignment = .center
        let attributedString = NSMutableAttributedString()

        let bigFont = UIFont.systemFont(ofSize: size1, weight: .bold)
        let firstAttributes: [NSAttributedString.Key: Any] = [
            .font: bigFont,
            .foregroundColor: UIColor.black
        ]
        let firstString = NSAttributedString(string: value, attributes: firstAttributes)
        attributedString.append(firstString)

        let smallFont = UIFont.systemFont(ofSize: size2, weight: .semibold)
        let secondAttributes: [NSAttributedString.Key: Any] = [
            .font: smallFont,
            .foregroundColor: UIColor.black
        ]
        let secondString = NSAttributedString(string: unit, attributes: secondAttributes)
        attributedString.append(secondString)
        
        let bigFontCapHeight = bigFont.capHeight
        let smallFontCapHeight = smallFont.capHeight
        let baselineOffset = (bigFontCapHeight - smallFontCapHeight) / 2

        attributedString.addAttributes([.baselineOffset: baselineOffset], range: NSRange(location: firstString.length, length: secondString.length))


        label?.attributedText = attributedString
    }
    
    // 读取数据库内缓存数据
    private func readDBStep(null: Bool = false) {
        if null {
            refreshValue(label: footValueLabel, value: "\(0)", unit: "health_step_noun".localized(), size1: 40, size2: 14)
            refreshStepValue(unit: 0, v: 0)
            return
        }
        let time = Int(Date().zeroTimeStamp())
        let models = try? DStepModel.er.array("timeStamp > \(time) AND mac = '\(lastestDeviceMac)'")
        XLogger.shared.log("数据库里\(lastestDeviceMac)步数晚于\(time)的数据总条数：\(models?.count ?? 0)")
        var step = 0
        var distance = 0
        var cal = 0
        let count = models?.count ?? 0
        for i in 0..<count {
            step += models?[i].step ?? 0
            distance += models?[i].distance ?? 0
            cal += models?[i].cal ?? 0
        }
        refreshValue(label: footValueLabel, value: "\(step)", unit: "health_step_noun".localized(), size1: 40, size2: 14)
        let unit = Float(distance) / 1000
        let v = Float(cal) / 1000
        refreshStepValue(unit: unit, v: v)
    }
    
    private func refreshDBStep() {
        let lastestDeviceMac = UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? ""
        if lastestDeviceMac.count > 0 {
            guard let models = try? DStepModel.er.array("mac = '\(lastestDeviceMac)'") else {
                return
            }
            for model in models {
                try? model.er.delete()
            }
        }
    }
    
    private func readDBHeart() {
        let stamp = Int(Date().zeroTimeStamp())
        let a = try? DHeartRateModel.er.array("timeStamp>=\(stamp) AND timeStamp<\(stamp + 24 * 60 * 60) AND mac='\(lastestDeviceMac)'")
        let models = a?.sorted {$0.timeStamp > $1.timeStamp}
        XLogger.shared.log("数据库里心跳的数据总条数：\(models?.count ?? 0)")
        
        let b = try? DHeartRateModel.er.last("mac='\(lastestDeviceMac)'")
        let heart = b?.heartRate ?? 0
        
        let v = NSMutableAttributedString()
        v.append(NSAttributedString(string: "\(heart)", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
        v.append(NSAttributedString(string: "health_value_p_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
        arrayValue[0] = v
        collectionView.reloadData()
    }
    
    private func refreshDBHeart() {
        let lastestDeviceMac = UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? ""
        if lastestDeviceMac.count > 0 {
            guard let models = try? DHeartRateModel.er.array("mac = '\(lastestDeviceMac)'") else {
                return
            }
            for model in models {
                try? model.er.delete()
            }
        }
    }
    
    private func readDBSleep() {
        let value = Int(Date().zeroTimeStamp())
        let models = try? DSleepModel.er.array("timeStamp>=\(value - 2 * 60 * 60) AND timeStamp<\(value + 10 * 60 * 60) AND mac = '\(lastestDeviceMac)'")
        XLogger.shared.log("数据库里睡眠的数据总条数：\(models?.count ?? 0)")
        var array: [SleepModel] = []
        if models != nil {
            for model in models! {
                let m = SleepModel()
                m.uuidString = model.uuidString
                m.mac = model.mac
                m.timeStamp = model.timeStamp
                m.state = model.state
                array.append(m)
            }
        }
        if array.count > 0 {
            BLEManager.shared.sleepArray[0] = array
            let arr = BLEManager.shared.readSleepData(array: array) // 获得睡眠时间
            let total = arr[1] + arr[2]
            let h = total / 60
            let m = total % 60
            let arrStr = NSMutableAttributedString()
            arrStr.append(NSAttributedString(string: "\(h)", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
            arrStr.append(NSAttributedString(string: "health_hour".localized(), attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
            arrStr.append(NSAttributedString(string: "\(m)", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
            arrStr.append(NSAttributedString(string: "health_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
            arrayValue[1] = arrStr
            collectionView.reloadData()
            
        } else {
            let arrStr = NSMutableAttributedString()
            arrStr.append(NSAttributedString(string: "0", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
            arrStr.append(NSAttributedString(string: "health_hour".localized(), attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
            arrStr.append(NSAttributedString(string: "0", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
            arrStr.append(NSAttributedString(string: "health_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
            arrayValue[1] = arrStr
            collectionView.reloadData()
        }
    }
    
    private func refreshDBSleep() {
        let lastestDeviceMac = UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? ""
        if lastestDeviceMac.count > 0 {
            guard let models = try? DSleepModel.er.array("mac = '\(lastestDeviceMac)'") else {
                return
            }
            for model in models {
                try? model.er.delete()
            }
        }
    }
    
    private func readDBBlood() {
        let models = try? DBloodModel.er.array("mac = '\(lastestDeviceMac)'").sorted(byKeyPath: "timeStamp", ascending: false)
        XLogger.shared.log("数据库里血压的数据总条数：\(models?.count ?? 0)")
        var min = 0
        var max = 0
        if models?.count ?? 0 > 0 {
            min = models?[0].min ?? 0
            max = models?[0].max ?? 0
        }
        let v = NSMutableAttributedString()
        v.append(NSAttributedString(string: "\(max)/\(min)", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
        v.append(NSAttributedString(string: "MMHG", attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
        arrayValue[2] = v
        collectionView.reloadData()
    }
    
    private func refreshDBBlood() {
        let lastestDeviceMac = UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? ""
        if lastestDeviceMac.count > 0 {
            guard let models = try? DBloodModel.er.array("mac = '\(lastestDeviceMac)'") else {
                return
            }
            for model in models {
                try? model.er.delete()
            }
        }
    }
    
    private func readDBOxygen() {
        let models = try? DOxygenModel.er.array("mac = '\(lastestDeviceMac)'").sorted(byKeyPath: "timeStamp", ascending: false)
        XLogger.shared.log("数据库里血氧的数据总条数：\(models?.count ?? 0)")
        let value = models?.first?.oxygen ?? 0
        let v = NSMutableAttributedString()
        v.append(NSAttributedString(string: "\(value)", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
        v.append(NSAttributedString(string: "SPO2", attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
        arrayValue[3] = v
        collectionView.reloadData()
    }
    
    private func refreshDBOxygen() {
        let lastestDeviceMac = UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? ""
        if lastestDeviceMac.count > 0 {
            guard let models = try? DOxygenModel.er.array("mac = '\(lastestDeviceMac)'") else {
                return
            }
            for model in models {
                try? model.er.delete()
            }
        }
    }
    
    
    @objc public func showDialogForInviteAPPReview() {
        if
            let navigationView = navigationController?.view{
            let noActionInfo = SCReviewView.ActionInfo(
                title: "NO",
                titleFont: UIFont.systemFont(ofSize: 18),
                image: UIImage(named: "amazon_image_sad_no"))
            let yesActionInfo = SCReviewView.ActionInfo(
                title: "YES",
                titleFont: UIFont.systemFont(ofSize: 18),
                image: UIImage(named: "amazon_image_smile_yes"))
            let viewInfo = SCReviewView.ViewInfo(
                image: UIImage(named: "amazon_image_heart") ?? UIImage(),
                imageSize: CGSize(width: 70, height: 60),
                imageTop: 19,
                title: " ",
                spaceBetweenImageAndTitle: 13,
                spaceBetweenArcBGAndTitle: 26,
                actionsInfo: [noActionInfo, yesActionInfo])
            let inviteReviewAPPDialog = SCReviewView(viewInfo: viewInfo).then {
                //将视图加到navigation上，达到全页面模态的效果，否则无法覆盖导航栏
                navigationView.addSubview($0)
                $0.snp.makeConstraints {
                    $0.edges.equalToSuperview()
                }
            }
            currentDialog = inviteReviewAPPDialog
            inviteReviewAPPDialog.didClickedClosure = {
                [weak self] (index) in
                    guard let sself = self else { return }
                    inviteReviewAPPDialog.removeFromSuperview()
                    if index == 0 {
                        sself.notEnjoyApp()
                    } else {
                        sself.enjoyApp()
                    }
            }
        }
    }
    
    private func enjoyApp() {
        showAPPStoreReview()
    }
    
    private func showAPPStoreReview() {
        SKStoreReviewController.requestReview()
    }
    
    private func notEnjoyApp() {
        //显示help弹框
        
    }
    
    public func checkFGSStatus() {

        AliConnectMananger_C.shared.checkFgsState { isSuccess, data in
            JL_Tools.mainTask {
                [weak self] in
                self?.connectLp()
                if isSuccess {
                    NSLog("已有三元组数据")
                    //DFUITools.showText("已有三元组数据", on: self.view, delay: 1.0)
                }else {
                    NSLog("没有,错误日志 : \(String(describing: data["msg"]))")
                    //DFUITools.showText("三元组数据错误", on: self.view, delay: 1.0)
                }
            }
        }
    }
    
    public func connectLp() {
        
        //swift-Lp连接
        AliConnectMananger_C.shared.startConnectLpState { isSuccess, data in
            JL_Tools.mainTask {
                if isSuccess {
                    NSLog("LP连接成功")
                    //DFUITools.showText("LP连接成功", on: self.view, delay: 1.0)
                }else {
                    NSLog("LP连接失败,错误日志 : \(String(describing: data["msg"]))")
                    //DFUITools.showText("LP连接失败", on: self.view, delay: 1.0)
                }
            }
        }
    }
    
    var cameraViewController: CameraViewController?
    private var currentTime: TimeInterval = 0 // 当前时间戳
    
    private func takePhoto() {
        DispatchQueue.main.async {
            [weak self] in
            if UIApplication.shared.applicationState == .background {
                return
            }
            if self?.cameraViewController != nil {
                return
            }
            var croppingParameters: CroppingParameters {
                return CroppingParameters(isEnabled: false, allowResizing: false, allowMoving: false, minimumSize: CGSize(width: 60, height: 60))
            }
            self?.cameraViewController = CameraViewController(croppingParameters: croppingParameters, allowsLibraryAccess: true) { [weak self] image, asset in
                self?.dismiss(animated: true, completion: nil)
                self?.cameraViewController = nil
                XGZTCommand.remotePhoto(action: 0)
            }
            self?.cameraViewController?.modalPresentationStyle = .fullScreen
            UIApplication.shared.topMostViewController()?.present(self!.cameraViewController!, animated: true, completion: nil)
        }
    }
    
    private func closePhoto() {
        DispatchQueue.main.async {
            [weak self] in
            if UIApplication.shared.applicationState == .background {
                return
            }
            self?.cameraViewController?.dismiss(animated: true, completion: nil)
            self?.cameraViewController = nil
        }
    }
    
    private func startPhoto() {
        let current = Date().timeIntervalSince1970
        if currentTime > 0 {
            if abs(current - currentTime) < 4 {
                return
            }
        }
        currentTime = current
        DispatchQueue.main.async {
            [weak self] in
            if UIApplication.shared.applicationState == .background {
                return
            }
            if self?.cameraViewController == nil {
                return
            }
            self?.cameraViewController?.capturePhoto()
        }
    }
    
}


extension UIImage {
    class func gifImageWithName(_ name: String) -> UIImage? {
        guard let bundleURL = Bundle.main
            .url(forResource: name, withExtension: "gif") else {
                XLogger.shared.log("Unable to find the GIF file named \(name).gif")
                return nil
        }
        guard let imageData = try? Data(contentsOf: bundleURL) else {
            XLogger.shared.log("Unable to load the data for the GIF file \(name).gif")
            return nil
        }
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil) else {
            XLogger.shared.log("Unable to create image source for the GIF file \(name).gif")
            return nil
        }
        var images = [UIImage]()
        let count = CGImageSourceGetCount(source)
        for i in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else {
                XLogger.shared.log("Unable to create image for frame \(i) of the GIF file \(name).gif")
                continue
            }
            let uiImage = UIImage(cgImage: cgImage)
            images.append(uiImage)
        }
        return UIImage.animatedImage(with: images, duration: 1.0)
    }
}

extension HealthViewController: BleNeedSendDataDelegate_C {
    func sendBleData(data: Data) {
        NSLog("--->ALi Send:")
        NSLog("%@",JL_Tools.dataChange(toString: data))


        let bigData = JL_BigData()
        bigData.mIndex = indexBigData
        bigData.mData  = data
        bigData.mType  = 1;

        mBigDataManager?.cmdInputBigData(bigData)
        indexBigData = indexBigData+1
    }
}


extension HealthViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 处理cell点击事件
        if isFemaleHealthItem(at: indexPath) {
            handleFemaleHealthTapped()
            return
        }
        if isXGZT {
            let cards = xgztHealthCards
            guard cards.indices.contains(indexPath.item) else { return }
            let card = cards[indexPath.item]
            flag = card.type
            let vc = HealthDetailViewController()
            vc.type = flag
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        } else {
            flag = 2 + indexPath.item
            let vc = HealthDetailViewController()
            vc.type = flag
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else {
            return CGSize(width: (UIScreen.main.bounds.width - 30) / 2, height: 160)
        }

        let contentWidth = collectionView.bounds.width - layout.sectionInset.left - layout.sectionInset.right
        let itemWidth = (contentWidth - layout.minimumInteritemSpacing) / 2
        return CGSize(width: itemWidth, height: 160)
    }
}

extension HealthViewController: UICollectionViewDataSource {
    // UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if lastestDeviceMac.count <= 0 {
            XLogger.shared.log("lastestDeviceMac为空")
            return 0
        }
        if !bleSelf.isConnected && XGZTBlueToothManager.shared.device == nil {
           return 0
        }
        let count = totalCollectionItemCount
        XLogger.shared.log("count = \(count)")
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! HealthCollectionViewCell
        if isFemaleHealthItem(at: indexPath) {
            cell.configure(
                icon: UIImage.femaleCycleIcon(size: 64),
                title: "female_cycle_title".localized(),
                subtitle: "female_cycle_subtitle".localized(),
                rightTitle: NSMutableAttributedString(string: ""),
                style: .ecg
            )
            return cell
        }

        if isXGZT {
            let cards = xgztHealthCards
            guard cards.indices.contains(indexPath.item) else { return cell }
            let card = cards[indexPath.item]
            let valueIndex = card.valueOffset
            let rightValue: NSMutableAttributedString = {
                if card.hasArrow {
                    return NSMutableAttributedString(string: "")
                }
                return arrayValue.indices.contains(valueIndex) ? arrayValue[valueIndex] : NSMutableAttributedString(string: "--")
            }()
            let subtitle = card.subtitleKey.map { $0.localized() }
            let style: HealthCollectionViewCell.HealthCardStyle = card.hasArrow ? .ecg : .normal
            cell.configure(
                icon: xgztIcon(named: card.iconName),
                title: card.titleKey.localized(),
                subtitle: subtitle,
                rightTitle: rightValue,
                style: style
            )
        } else {
            // 非 XGZT 设备保持原有顺序：心率 睡眠 血压 血氧
            if indexPath.item == 0 {
                cell.configureCell(icon: UIImage(named: "health_heart"), leftTitle: "health_heart_rate".localized(), rightTitle: arrayValue[indexPath.item])
            } else if indexPath.item == 1 {
                cell.configureCell(icon: UIImage(named: "health_sleep"), leftTitle: "health_sleep".localized(), rightTitle: arrayValue[indexPath.item])
            } else if indexPath.item == 2 {
                cell.configureCell(icon: UIImage(named: "health_bloodpressure"), leftTitle: "health_blood_pressure".localized(), rightTitle: arrayValue[indexPath.item])
            } else {
                cell.configureCell(icon: UIImage(named: "health_bloodoxygen"), leftTitle: "health_blood_oxygen".localized(), rightTitle: arrayValue[indexPath.item])
            }
        }
        return cell
    }
    
    // 如果需要多个分区，可以实现这个方法
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
}
