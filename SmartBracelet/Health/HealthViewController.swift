//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  HealthViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/7/26.
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

class HealthViewController: BaseViewController {
    @IBOutlet weak var footView: UIView!
    @IBOutlet weak var fitLabel: UILabel!
    @IBOutlet weak var sexImageView: UIImageView!
    @IBOutlet weak var footMLabel: UILabel!
    @IBOutlet weak var footValueLabel: UILabel!
    @IBOutlet weak var footKLabel: UILabel!
    var tableView: UITableView!
    let cellIdentifier = "CustomCell"
    
    var xgztCount = 0
    
    var currentDialog: UIView? //记录当前的弹框，在页面异常关闭时移除
    
    var flag = 0 // 属性的作用
    var popup: PopupBViewController?
    private var hud: JGProgressHUD? // loading图标
    private var loadingViewCheckTimer: Timer?
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
    
    private var manager = OpenWeatherManager()
    var currentProgress = 0
     
    override func viewDidLoad() {
        bStyle = 1
        super.viewDidLoad()
        // 设置导航栏标题颜色
        title = "health_head".localized()
        for _ in 0..<4 {
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
                print("设置用户信息是否成功: \(result)")
            }
        }
        
        navigationItem.rightBarButtonItem?.title = "health_head".localized()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleDidEnterBackgroundNotification), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        if isSupportAlipay && !isXGZT {
            AliConnectMananger_C.shared.bleSendDataDelegate = self // 阿里云相关逻辑
            
            bt_sdk = JL_RunSDK.sharedMe() as? JL_RunSDK
            bt_ble = bt_sdk?.bt_ble

            mBigDataManager = bt_ble?.mAssist .mCmdManager.mBigDataManager
            onSetupBigData()
        }
        
        fitLabel.textColor = UIColor(hex: 0xFFFFFF, alpha: 0.2)
        fitLabel.text = "FIT"
        fitLabel.font = UIFont.bigbigtitle()
        sexImageView.image = UIImage(named: "health_boy")
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleFootCount))
        fitLabel.isUserInteractionEnabled = true
        tap.numberOfTapsRequired = 1
        fitLabel.addGestureRecognizer(tap)
        
        
        // 初始化UITableView
        tableView = UITableView(frame: self.view.bounds, style: .plain)
        tableView.backgroundColor = UIColor.clear
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        
        // 注册自定义的UITableViewCell类
        tableView.register(HealthTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        
        // 添加UITableView到当前视图
        self.view.addSubview(tableView)
        
        tableView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(320)
            make.bottom.equalToSuperview()
        }
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sexImageView.image = UIImage(named: bleSelf.userInfo.sex == 1 ? "health_boy" : "health_girl")
        if isXGZT {
            
            return
        }
        
        if !isFirst {
            readDBStep() // 从本地数据库中读取步数数据
        }
        isFirst = true
        readDBHeart() // 从本地数据库中读取心跳数据
        readDBBlood() // 从本地数据库中读取血压数据
        readDBOxygen() // 从本地数据库中读取血氧数据
        readDBSleep() // 从本地数据库中读取睡眠数据
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
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
        refreshValue(label: footKLabel, value: String(format: "%.2f", v), unit: "health_kilo_calorie".localized(), size1: 20, size2: 10)
        refreshValue(label: footMLabel, value: String(format: "%.2f", unit), unit: "health_walk_unit".localized(), size1: 20, size2: 10)
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
                let distance = Float(XGZTBlueToothManager.shared.device?.height ?? 0) * 0.415
                let unit = Float(step) * Float(distance)
                let v = Float(unit * Float((XGZTBlueToothManager.shared.device?.weight ?? 0)) * 0.55) / 1000
                DispatchQueue.main.async {
                    [weak self] in
                    self?.refreshStepValue(unit: unit / 100000, v: v / 100)
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
                    self?.tableView.reloadData()
                    
                } else {
                    let arrStr = NSMutableAttributedString()
                    arrStr.append(NSAttributedString(string: "0", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
                    arrStr.append(NSAttributedString(string: "health_hour".localized(), attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
                    arrStr.append(NSAttributedString(string: "0", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
                    arrStr.append(NSAttributedString(string: "health_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
                    self?.arrayValue[1] = arrStr
                    self?.tableView.reloadData()
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
                        self?.tableView.reloadData()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    [weak self] in
                    var heart = 0
                    heart = BLEManager.shared.heartArray[0].heart
                    let v = NSMutableAttributedString()
                    v.append(NSAttributedString(string: "\(heart)", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
                    v.append(NSAttributedString(string: "health_value_p_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
                    if heart > 0 {
                        self?.arrayValue[0] = v
                        self?.tableView.reloadData()
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
                        self?.tableView.reloadData()
                        UserDefaults.standard.setValue("\(max)/\(min)", forKey: "blood")
                        UserDefaults.standard.synchronize()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    [weak self] in
                    var min = 0
                    var max = 0
                    min = BLEManager.shared.bloodArray[0].min
                    max = BLEManager.shared.bloodArray[0].max
                    let v = NSMutableAttributedString()
                    v.append(NSAttributedString(string: "\(max)/\(min)", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
                    v.append(NSAttributedString(string: "MMHG", attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
                    if min > 0 {
                        self?.arrayValue[2] = v
                        self?.tableView.reloadData()
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
                        self?.tableView.reloadData()
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
                        self?.tableView.reloadData()
                    }
                }
            }
        } else if objc == "delete" {
            print("执行删除设备的动作")
            let userinfo = notification.userInfo as? [String : String]
            var mac = userinfo?["mac"] ?? ""
            if mac.count == 0 {
                mac = UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? ""
            }
            if mac.count > 0 {
                print("执行删除设备的动作: \(mac)")
                for device in DeviceManager.shared.devices {
                    if device.mac == mac {
                        if let model = try? BLEModel.er.array("mac = '\(mac)'").first {
                            try? model.er.delete()
                            print("执行删除设备的动作标志成功")
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
                self?.tableView.reloadData()
            }
            
        }
    }
    
    @objc private func handleShowLoading(_ notification: Notification) {
        let obj = notification.object as? Int ?? 0
        if obj == 0 {
            if popup != nil {
                popup?.dismiss(animated: false, completion: nil)
            }
            return
        }
        if obj == 1 {
            popup = PopupBViewController()
            popup?.modalTransitionStyle = .crossDissolve
            popup?.modalPresentationStyle = .overCurrentContext
            tabBarController?.present(popup!, animated: false, completion: nil)
            popup?.iconImageView?.image = UIImage(named: "bt_close")
            let attStr = NSMutableAttributedString()
            attStr.append(NSAttributedString(string: "\("mine_bluetooth_unconnect".localized())\n", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 13)]))
            attStr.append(NSAttributedString(string: "push_to_bt_settings".localized(), attributes: [.foregroundColor: UIColor.k14C8C6, .font: UIFont.systemFont(ofSize: 13), .underlineStyle: NSUnderlineStyle.single.rawValue]))
            let style = NSMutableParagraphStyle()
            style.alignment = .center
            style.lineSpacing = 10
            attStr.addAttributes([.paragraphStyle: style], range: NSMakeRange(0, attStr.length))
            popup?.contentLabel?.attributedText = attStr
            popup?.callback = {
                let url = URL(string: "App-Prefs:root=Bluetooth")
                if UIApplication.shared.canOpenURL(url!) {
                    UIApplication.shared.open(url!, options: [:], completionHandler: nil)
                }
            }
            return
        }
        if obj == 2 {
            if isSupportAlipay {
                checkFGSStatus() // 连接成功后，再检查
            }
            print("显示loading图片")
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
            log.info("隐藏loading图片")
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
            
            manager.syncTemprature() //  连接成功后，则同步天气。
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
            manager.syncTemprature(flag: 1) //  连接成功后，则同步天气。
        }
    }
    
    private func startLoadingViewCheckTimer() {
        print("张晓飞：启动加载loading的检查")
        endLoadingViewCheckTimer()
        loadingViewCheckTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false, block: { (timer) in
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
    
    @IBAction func addDevice(_ sender: Any) {
        var count = DeviceManager.shared.devices.count
        count += BluetoothWatchDevice.loadAll()?.count ?? 0
        let storyboard = UIStoryboard(name: "Device", bundle: nil)
        if count == 0 {
            let vc = storyboard.instantiateViewController(withIdentifier: "DeviceSearchViewController") as? DeviceSearchViewController
            vc?.title = "device_add".localized()
            vc?.refreshBackButton()
            vc?.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc!, animated: true)
        } else {
            let vc = storyboard.instantiateViewController(withIdentifier: "DeviceListViewController") as? DeviceListViewController
            vc?.title = "device_change".localized()
            vc?.refreshBackButton()
            vc?.style = 1
            vc?.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc!, animated: true)
        }
    }
    
    private func refreshValue(label: UILabel?, value: String, unit: String, size1: CGFloat, size2: CGFloat) {
        label?.textAlignment = .center
        // 创建一个NSMutableAttributedString实例
        let attributedString = NSMutableAttributedString()

        let bigFont = UIFont.systemFont(ofSize: size1, weight: .bold)
        // 创建第一段文本的属性
        let firstAttributes: [NSAttributedString.Key: Any] = [
            .font: bigFont,
            .foregroundColor: UIColor.white
        ]
        let firstString = NSAttributedString(string: value, attributes: firstAttributes)
        attributedString.append(firstString)

        let smallFont = UIFont.systemFont(ofSize: size2, weight: .semibold)
        // 创建第二段文本的属性
        let secondAttributes: [NSAttributedString.Key: Any] = [
            .font: smallFont,
            .foregroundColor: UIColor.white
        ]
        let secondString = NSAttributedString(string: unit, attributes: secondAttributes)
        attributedString.append(secondString)
        
        // 计算基线偏移量
        let bigFontCapHeight = bigFont.capHeight
        let smallFontCapHeight = smallFont.capHeight
        let baselineOffset = (bigFontCapHeight - smallFontCapHeight) / 2

        // 为小字体设置基线偏移量
        attributedString.addAttributes([.baselineOffset: baselineOffset], range: NSRange(location: firstString.length, length: secondString.length))


        // 将NSMutableAttributedString赋值给UILabel
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
        print("数据库里\(lastestDeviceMac)步数晚于\(time)的数据总条数：\(models?.count ?? 0)")
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
        print("数据库里心跳的数据总条数：\(models?.count ?? 0)")
        
        let b = try? DHeartRateModel.er.last("mac='\(lastestDeviceMac)'")
        let heart = b?.heartRate ?? 0
        
        let v = NSMutableAttributedString()
        v.append(NSAttributedString(string: "\(heart)", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
        v.append(NSAttributedString(string: "health_value_p_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
        arrayValue[0] = v
        tableView.reloadData()
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
        print("数据库里睡眠的数据总条数：\(models?.count ?? 0)")
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
            tableView.reloadData()
            
        } else {
            let arrStr = NSMutableAttributedString()
            arrStr.append(NSAttributedString(string: "0", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
            arrStr.append(NSAttributedString(string: "health_hour".localized(), attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
            arrStr.append(NSAttributedString(string: "0", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
            arrStr.append(NSAttributedString(string: "health_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
            arrayValue[1] = arrStr
            tableView.reloadData()
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
        print("数据库里血压的数据总条数：\(models?.count ?? 0)")
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
        tableView.reloadData()
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
        print("数据库里血氧的数据总条数：\(models?.count ?? 0)")
        let value = models?.first?.oxygen ?? 0
        let v = NSMutableAttributedString()
        v.append(NSAttributedString(string: "\(value)", attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .black), .foregroundColor: UIColor.black]))
        v.append(NSAttributedString(string: "SPO2", attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.text_secondary]))
        arrayValue[3] = v
        tableView.reloadData()
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
}


extension UIImage {
    class func gifImageWithName(_ name: String) -> UIImage? {
        guard let bundleURL = Bundle.main
            .url(forResource: name, withExtension: "gif") else {
                print("Unable to find the GIF file named \(name).gif")
                return nil
        }
        guard let imageData = try? Data(contentsOf: bundleURL) else {
            print("Unable to load the data for the GIF file \(name).gif")
            return nil
        }
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil) else {
            print("Unable to create image source for the GIF file \(name).gif")
            return nil
        }
        var images = [UIImage]()
        let count = CGImageSourceGetCount(source)
        for i in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else {
                print("Unable to create image for frame \(i) of the GIF file \(name).gif")
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


extension HealthViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 然后取消选中效果
        tableView.deselectRow(at: indexPath, animated: false)
        if isXGZT {
            if xgztCount >= 4 {
                flag = 2 + indexPath.item
                let vc = HealthDetailViewController()
                vc.type = flag
                vc.hidesBottomBarWhenPushed = true
                navigationController?.pushViewController(vc, animated: true)
            } else {
                if indexPath.row == 0 {
                    if (XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) & 1 == 1 {
                        flag = 2
                        let vc = HealthDetailViewController()
                        vc.type = flag
                        vc.hidesBottomBarWhenPushed = true
                        navigationController?.pushViewController(vc, animated: true)
                    } else if ((XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) >> 4) & 1 == 1 {
                        flag = 3
                        let vc = HealthDetailViewController()
                        vc.type = flag
                        vc.hidesBottomBarWhenPushed = true
                        navigationController?.pushViewController(vc, animated: true)
                    } else if ((XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) >> 2) & 1 == 1 {
                        flag = 4
                        let vc = HealthDetailViewController()
                        vc.type = flag
                        vc.hidesBottomBarWhenPushed = true
                        navigationController?.pushViewController(vc, animated: true)
                    } else if ((XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) >> 1) & 1 == 1 {
                        flag = 5
                        let vc = HealthDetailViewController()
                        vc.type = flag
                        vc.hidesBottomBarWhenPushed = true
                        navigationController?.pushViewController(vc, animated: true)
                    }
                } else if indexPath.row == 1 {
                    if ((XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) >> 4) & 1 == 1 {
                        flag = 3
                        let vc = HealthDetailViewController()
                        vc.type = flag
                        vc.hidesBottomBarWhenPushed = true
                        navigationController?.pushViewController(vc, animated: true)
                    } else if ((XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) >> 2) & 1 == 1 {
                        flag = 4
                        let vc = HealthDetailViewController()
                        vc.type = flag
                        vc.hidesBottomBarWhenPushed = true
                        navigationController?.pushViewController(vc, animated: true)
                    } else if ((XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) >> 1) & 1 == 1 {
                        flag = 5
                        let vc = HealthDetailViewController()
                        vc.type = flag
                        vc.hidesBottomBarWhenPushed = true
                        navigationController?.pushViewController(vc, animated: true)
                    }
                } else if indexPath.row == 2 {
                    if ((XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) >> 2) & 1 == 1 {
                        flag = 4
                        let vc = HealthDetailViewController()
                        vc.type = flag
                        vc.hidesBottomBarWhenPushed = true
                        navigationController?.pushViewController(vc, animated: true)
                    } else if ((XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) >> 1) & 1 == 1 {
                        flag = 5
                        let vc = HealthDetailViewController()
                        vc.type = flag
                        vc.hidesBottomBarWhenPushed = true
                        navigationController?.pushViewController(vc, animated: true)
                    }
                }
            }
        } else {
            flag = 2 + indexPath.item
            let vc = HealthDetailViewController()
            vc.type = flag
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension HealthViewController: UITableViewDataSource {
    // UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if lastestDeviceMac.count <= 0 || (!bleSelf.isConnected && XGZTBlueToothManager.shared.device == nil) {
            return 0
        }
        if isXGZT {
            var count = 0
            if ((XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) & 1 == 1) {
                count += 1
            }
            if (((XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) >> 1) & 1 == 1) {
                count += 1
            }
            if (((XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) >> 2) & 1 == 1) {
                count += 1
            }
            if (((XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) >> 4) & 1 == 1) {
                count += 1
            }
            xgztCount = count
            return count
        }
        return 4 // 你有4个cells
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! HealthTableViewCell
        // 设置点击无动效
        cell.selectionStyle = .none
        // 配置cell，这里只是示例数据
        if indexPath.item == 0 {
            if isXGZT {
                if (XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) & 1 == 1 {
                    cell.configureCell(icon: UIImage(named: "health_heart"), leftTitle: "health_heart_rate".localized(), rightTitle: arrayValue[indexPath.item])
                    cell.temImageView.isHidden = true
                } else if ((XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) >> 4) & 1 == 1 {
                    cell.configureCell(icon: UIImage(named: "health_sleep"), leftTitle: "health_sleep".localized(), rightTitle: arrayValue[indexPath.item + 1])
                    cell.temImageView.isHidden = true
                } else if ((XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) >> 2) & 1 == 1 {
                    cell.configureCell(icon: UIImage(named: "health_bloodpressure"), leftTitle: "health_blood_pressure".localized(), rightTitle: arrayValue[indexPath.item + 2])
                    cell.temImageView.isHidden = true
                } else if ((XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) >> 1) & 1 == 1 {
                    cell.configureCell(icon: UIImage(named: "health_bloodoxygen"), leftTitle: "health_blood_oxygen".localized(), rightTitle: arrayValue[indexPath.item + 3])
                    cell.temImageView.isHidden = true
                }
            } else {
                cell.configureCell(icon: UIImage(named: "health_heart"), leftTitle: "health_heart_rate".localized(), rightTitle: arrayValue[indexPath.item])
                cell.temImageView.isHidden = true
            }
            
        } else if indexPath.item == 1 {
            if isXGZT {
                if xgztCount > 1 {
                    if ((XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) >> 4) & 1 == 1 {
                        cell.configureCell(icon: UIImage(named: "health_sleep"), leftTitle: "health_sleep".localized(), rightTitle: arrayValue[indexPath.item])
                        cell.temImageView.isHidden = true
                    } else if ((XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) >> 2) & 1 == 1 {
                        cell.configureCell(icon: UIImage(named: "health_bloodpressure"), leftTitle: "health_blood_pressure".localized(), rightTitle: arrayValue[indexPath.item + 1])
                        cell.temImageView.isHidden = true
                    } else if ((XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) >> 1) & 1 == 1 {
                        cell.configureCell(icon: UIImage(named: "health_bloodoxygen"), leftTitle: "health_blood_oxygen".localized(), rightTitle: arrayValue[indexPath.item + 2])
                        cell.temImageView.isHidden = true
                    }
                }
            } else {
                cell.configureCell(icon: UIImage(named: "health_sleep"), leftTitle: "health_sleep".localized(), rightTitle: arrayValue[indexPath.item])
                cell.temImageView.isHidden = true
            }
        } else if indexPath.item == 2 {
            if isXGZT {
                if xgztCount > 2 {
                    if ((XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) >> 2) & 1 == 1 {
                        cell.configureCell(icon: UIImage(named: "health_bloodpressure"), leftTitle: "health_blood_pressure".localized(), rightTitle: arrayValue[indexPath.item])
                        cell.temImageView.isHidden = true
                    } else if ((XGZTBlueToothManager.shared.device?.healthcontrolflags ?? 0) >> 1) & 1 == 1 {
                        cell.configureCell(icon: UIImage(named: "health_bloodoxygen"), leftTitle: "health_blood_oxygen".localized(), rightTitle: arrayValue[indexPath.item + 1])
                        cell.temImageView.isHidden = true
                    }
                }
            } else {
                cell.configureCell(icon: UIImage(named: "health_bloodpressure"), leftTitle: "health_blood_pressure".localized(), rightTitle: arrayValue[indexPath.item])
                cell.temImageView.isHidden = true
            }
            
        } else {
            cell.configureCell(icon: UIImage(named: "health_bloodoxygen"), leftTitle: "health_blood_oxygen".localized(), rightTitle: arrayValue[indexPath.item])
            cell.temImageView.isHidden = true
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 96 //indexPath.item < 2 ? 192 : 96
    }
}

