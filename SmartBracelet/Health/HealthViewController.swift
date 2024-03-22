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
    @IBOutlet weak var bleedGIFImageView: YYAnimatedImageView!
    @IBOutlet weak var pressureGIFImageView: YYAnimatedImageView!
    @IBOutlet weak var sleepCurveImageView: YYAnimatedImageView!
    @IBOutlet weak var heartRateImageView: YYAnimatedImageView!
    @IBOutlet weak var mScrollView: UIScrollView!
    @IBOutlet weak var footView: UIView!
    @IBOutlet weak var footTipLabel: UILabel!
    @IBOutlet weak var footUnitLabel: UILabel!
    @IBOutlet weak var footValueLabel: UILabel!
    @IBOutlet weak var footGoalLabel: UILabel!
    @IBOutlet weak var heartView: UIView!
    @IBOutlet weak var heartTipLabel: UILabel!
    @IBOutlet weak var heartValueLabel: UILabel!
    @IBOutlet weak var sleepView: UIView!
    @IBOutlet weak var sleepTipLabel: UILabel!
    @IBOutlet weak var sleepValueLabel: UILabel!
    @IBOutlet weak var pressureView: UIView!
    @IBOutlet weak var pressureTipLabel: UILabel!
    @IBOutlet weak var pressureValueLabel: UILabel!
    @IBOutlet weak var bleedView: UIView!
    @IBOutlet weak var bleedTipLabel: UILabel!
    @IBOutlet weak var bleedValueLabel: UILabel!
    @IBOutlet weak var progressStepView: UIView!
    var currentDialog: UIView? //记录当前的弹框，在页面异常关闭时移除
    
    var flag = 0 // 属性的作用
    var popup: PopupBViewController?
    var hud: JGProgressHUD? // loading图标
    private var loadingViewCheckTimer: Timer?
    var header: MJRefreshNormalHeader?
    var isFirst = false
    var indexBigData:Int = 0
    var mBigDataManager:JL_BigDataManager?
    var bt_sdk:JL_RunSDK?
    var bt_ble:QCY_BLEApple?
    
    var testData:Data?
    var getTimes:Int = 0
    var sendTimesOk:Int = 0
    var sendTimesFail:Int = 0
    var testAuto:Bool = true
    var isSupportAlipay = false // 是否支持支付宝支付
    
    private var manager = OpenWeatherManager()
     
    override func viewDidLoad() {
        super.viewDidLoad()
        let openCount = UserDefaults.standard.integer(forKey: "APPOPEN") // 如果app打开次数
        if openCount >= 10 { //当打开次数>10次后，就打开邀请评论app的弹窗
            perform(#selector(self.showDialogForInviteAPPReview), with: nil, afterDelay: 20)
            UserDefaults.standard.set(0, forKey: "APPOPEN")
        }
        registerNotification()
        header = MJRefreshNormalHeader {
            [weak self] in
            print("start")
            if bleSelf.isConnected {
                bleSelf.getStep()
                NotificationCenter.default.post(name: Notification.Name("HealthVCLoading"), object: 2)
            }
            self?.header?.endRefreshing()
        }.autoChangeTransparency(true).link(to: mScrollView)
        WUBleManager.shared.didSetUserinfo = {
            result in
            print("设置用户信息是否成功: \(result)")
        }
        navigationItem.rightBarButtonItem?.title = "health_head".localized()
        footTipLabel.text = "health_step".localized()
        heartTipLabel.text = "health_heart_rate".localized()
        sleepTipLabel.text = "health_sleep".localized()
        pressureTipLabel.text = "health_blood_pressure".localized()
        bleedTipLabel.text = "health_blood_oxygen".localized()
        footUnitLabel.text = "health_step_noun".localized()
        bleedGIFImageView.image = YYImage(named: "blood.gif")
        pressureGIFImageView.image = YYImage(named: "pressure.gif")
        heartRateImageView.image = YYImage(named: "heart")
        sleepCurveImageView.image = YYImage(named: "sleep.gif")
        
        
        let pView = QACircleProgressView(frame: CGRect(x: 0, y: 0, width: 150, height: 150))
        progressStepView?.addSubview(pView)
        pView.progressWidth = 10
        pView.progressColor = UIColor.white
        pView.trackColor = UIColor.white.withAlphaComponent(0.5)
        pView.progress = 0
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleDidEnterBackgroundNotification), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        
        if lastestDeviceMac.count == 0 {
            pressureView.isHidden = true
            bleedView.isHidden = true
        }
        
        if isSupportAlipay {
            AliConnectMananger_C.shared.bleSendDataDelegate = self // 阿里云相关逻辑
            
            bt_sdk = JL_RunSDK.sharedMe() as? JL_RunSDK
            bt_ble = bt_sdk?.bt_ble

            mBigDataManager = bt_ble?.mAssist .mCmdManager.mBigDataManager
            onSetupBigData()
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
        
        if !isFirst {
            readDBStep() // 从本地数据库中读取步数数据
        }
        isFirst = true
        readDBHeart() // 从本地数据库中读取心跳数据
        readDBBlood() // 从本地数据库中读取血压数据
        readDBOxygen() // 从本地数据库中读取血氧数据
        readDBSleep() // 从本地数据库中读取睡眠数据
        refreshGoal()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshUIForBleed()
    }
    
    private func refreshUIForBleed() {
        if lastestDeviceMac.count > 0 {
            pressureView.isHidden = false
            bleedView.isHidden = false
        }
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
        let lastestDeviceMac = UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? ""
        var goal = 0
        if lastestDeviceMac.count == 0 {
            
        } else {
            goal = UserDefaults.standard.integer(forKey: "Goal")
            if goal == 0 {
                goal = bleSelf.userInfo.stepGoal
            }
            if goal == 0 {
                goal = 6000
            }
        }
        
        footGoalLabel.text = "\("health_goal".localized()) \(goal) \("health_step_noun".localized()) | \("health_distance".localized()) \(String(format: "%.2f", unit)) \("health_walk_unit".localized()) | \("health_heat".localized()) \(String(format: "%.2f", v)) \("health_kilo_calorie".localized())"
    }
    
    private func refreshGoal() {
        var value = footGoalLabel.text ?? ""
        if value.count > 0 {
            var array = value.components(separatedBy: "|")
            if array.count < 3 {
                return
            }
            let lastestDeviceMac = UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? ""
            var goal = 0
            if lastestDeviceMac.count == 0 {
                
            } else {
                goal = UserDefaults.standard.integer(forKey: "Goal")
                if goal == 0 {
                    goal = bleSelf.userInfo.stepGoal
                }
                if goal == 0 {
                    goal = 6000
                }
            }
            array[0] = "\("health_goal".localized()) \(goal) \("health_step_noun".localized()) "
            value = array.joined(separator: "|")
            footGoalLabel.text = value
        }
    }
    
    @objc private func handleNotification(_ notification: Notification) {
        let objc = notification.object as! String
        if objc == "step" {
            DispatchQueue.main.async {
                [weak self] in
                self?.refreshUIForBleed()
                let step = bleSelf.step
                self?.footValueLabel.text = "\(step)"
                let distance = bleSelf.distance
                let unit = Float(distance) / 1000
            
                let cal = bleSelf.cal
                let v = Float(cal) / 1000
                self?.refreshStepValue(unit: unit, v: v)
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
                    arrStr.append(NSAttributedString(string: "\(h)", attributes: [.font: UIFont.systemFont(ofSize: 32), .foregroundColor: UIColor.k666666]))
                    arrStr.append(NSAttributedString(string: "health_hour".localized(), attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.k999999]))
                    arrStr.append(NSAttributedString(string: "\(m)", attributes: [.font: UIFont.systemFont(ofSize: 32), .foregroundColor: UIColor.k666666]))
                    arrStr.append(NSAttributedString(string: "health_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.k999999]))
                    self?.sleepValueLabel.attributedText = arrStr
                    
                } else {
                    let arrStr = NSMutableAttributedString()
                    arrStr.append(NSAttributedString(string: "0", attributes: [.font: UIFont.systemFont(ofSize: 32), .foregroundColor: UIColor.k666666]))
                    arrStr.append(NSAttributedString(string: "health_hour".localized(), attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.k999999]))
                    arrStr.append(NSAttributedString(string: "0", attributes: [.font: UIFont.systemFont(ofSize: 32), .foregroundColor: UIColor.k666666]))
                    arrStr.append(NSAttributedString(string: "health_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.k999999]))
                    self?.sleepValueLabel.attributedText = arrStr
                }
            }
        } else if objc == "heart" {
            DispatchQueue.main.async {
                [weak self] in
                var heart = 0
                heart = BLEManager.shared.heartArray[0].heart
                let v = NSMutableAttributedString()
                v.append(NSAttributedString(string: "\(heart)", attributes: [.font: UIFont.systemFont(ofSize: 32), .foregroundColor: UIColor.k666666]))
                v.append(NSAttributedString(string: "health_value_p_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.k999999]))
                self?.heartValueLabel.attributedText = v
                self?.refreshLefunHeartRate()
            }
        } else if objc == "blood" {
            DispatchQueue.main.async {
                [weak self] in
                var min = 0
                var max = 0
                min = BLEManager.shared.bloodArray[0].min
                max = BLEManager.shared.bloodArray[0].max
                let v = NSMutableAttributedString()
                v.append(NSAttributedString(string: "\(max)/\(min)", attributes: [.font: UIFont.systemFont(ofSize: 32), .foregroundColor: UIColor.k666666]))
                v.append(NSAttributedString(string: "MMHG", attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.k999999]))
                self?.pressureValueLabel.attributedText = v
                UserDefaults.standard.setValue("\(max)/\(min)", forKey: "blood")
                UserDefaults.standard.synchronize()
            }
        } else if objc == "oxygen" {
            DispatchQueue.main.async {
                [weak self] in
                var value = 0
                if BLEManager.shared.oxygenArray.count > 0 {
                    value = BLEManager.shared.oxygenArray[0].oxygen
                } else {
                    value = 0
                }
                let v = NSMutableAttributedString()
                v.append(NSAttributedString(string: "\(value)", attributes: [.font: UIFont.systemFont(ofSize: 32), .foregroundColor: UIColor.k666666]))
                v.append(NSAttributedString(string: "%  \("health_head".localized())", attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.k999999]))
                self?.bleedValueLabel.attributedText = v
                UserDefaults.standard.setValue("\(value)", forKey: "oxygen")
                UserDefaults.standard.synchronize()
            }
        } else if objc == "delete" {
            let userinfo = notification.userInfo as? [String : String]
            var mac = userinfo?["mac"] ?? ""
            if mac.count == 0 {
                mac = UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? ""
            }
            if mac.count > 0 {
                for device in DeviceManager.shared.devices {
                    if device.mac == mac {
                        if let model = try? BLEModel.er.array("mac = '\(mac)'").first {
                            try? model.er.delete()
                        }
                        break
                    }
                }
            }
            DeviceManager.shared.initializeDevices()

            refreshDBStep()
            refreshDBHeart()
            refreshDBSleep()
            refreshDBBlood()
            refreshDBOxygen()
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
            attStr.append(NSAttributedString(string: "\("mine_bluetooth_unconnect".localized())\n请到", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 13)]))
            attStr.append(NSAttributedString(string: "设置-打开蓝牙", attributes: [.foregroundColor: UIColor.k14C8C6, .font: UIFont.systemFont(ofSize: 13), .underlineStyle: NSUnderlineStyle.single.rawValue]))
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
                self?.hud?.textLabel.text = "\("sync_data".localized())9/9"
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self?.hud?.dismiss(animated: false)
                }
            }
            
            manager.syncTemprature() //  连接成功后，则同步天气。
        }
        if obj == 100 {
            let userinfo = notification.userInfo as? [String : String]
            let msg = userinfo?["msg"] ?? "\("sync_data".localized())9/9"
            DispatchQueue.main.async {
                [weak self] in
                self?.hud?.textLabel.text = msg
            }
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
    
    private func refreshLefunHeartRate() {
        
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
    
    @IBAction func handleFootCount(_ sender: Any) {
        flag = 0
        self.performSegue(withIdentifier: .kShowHealthDetail, sender: self)
    }

    @IBAction func handleHeatView(_ sender: Any) {
        flag = 1
        self.performSegue(withIdentifier: .kShowHealthDetail, sender: self)
    }
    
    @IBAction func handleHeart(_ sender: Any) {
        flag = 2
        self.performSegue(withIdentifier: .kShowHealthDetail, sender: self)
    }
    
    @IBAction func handleSleep(_ sender: Any) {
        flag = 3
        self.performSegue(withIdentifier: .kShowHealthDetail, sender: self)
    }
    
    @IBAction func handlePressure(_ sender: Any) {
        flag = 4
        self.performSegue(withIdentifier: .kShowHealthDetail, sender: self)
    }
    
    @IBAction func handleBleed(_ sender: Any) {
        flag = 5
        self.performSegue(withIdentifier: .kShowHealthDetail, sender: self)
    }
    
    
    @IBAction func addDevice(_ sender: Any) {
        let count = DeviceManager.shared.devices.count
        let storyboard = UIStoryboard(name: "Device", bundle: nil)
        if count == 0 {
            let vc = storyboard.instantiateViewController(withIdentifier: "DeviceSearchViewController")
            vc.title = "device_add".localized()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        } else {
            let vc = storyboard.instantiateViewController(withIdentifier: "DeviceListViewController")
            vc.title = "device_change".localized()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func handleHealth(_ sender: Any) { // 不要保留入口
        //let detail = DetailViewController()
        //navigationController?.pushViewController(detail, animated: true)
    }
    
    
    // 读取数据库内缓存数据
    private func readDBStep() {
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
        footValueLabel.text = "\(step)"
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
        v.append(NSAttributedString(string: "\(heart)", attributes: [.font: UIFont.systemFont(ofSize: 32), .foregroundColor: UIColor.k666666]))
        v.append(NSAttributedString(string: "health_value_p_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.k999999]))
        heartValueLabel.attributedText = v

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
            arrStr.append(NSAttributedString(string: "\(h)", attributes: [.font: UIFont.systemFont(ofSize: 32), .foregroundColor: UIColor.k666666]))
            arrStr.append(NSAttributedString(string: "health_hour".localized(), attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.k999999]))
            arrStr.append(NSAttributedString(string: "\(m)", attributes: [.font: UIFont.systemFont(ofSize: 32), .foregroundColor: UIColor.k666666]))
            arrStr.append(NSAttributedString(string: "health_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.k999999]))
            sleepValueLabel.attributedText = arrStr
            
        } else {
            let arrStr = NSMutableAttributedString()
            arrStr.append(NSAttributedString(string: "0", attributes: [.font: UIFont.systemFont(ofSize: 32), .foregroundColor: UIColor.k666666]))
            arrStr.append(NSAttributedString(string: "health_hour".localized(), attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.k999999]))
            arrStr.append(NSAttributedString(string: "0", attributes: [.font: UIFont.systemFont(ofSize: 32), .foregroundColor: UIColor.k666666]))
            arrStr.append(NSAttributedString(string: "health_minute".localized(), attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.k999999]))
            sleepValueLabel.attributedText = arrStr
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
        if let value = UserDefaults.standard.string(forKey: "blood"), value.count > 0 {
            let v = NSMutableAttributedString()
            v.append(NSAttributedString(string: "\(value)", attributes: [.font: UIFont.systemFont(ofSize: 32), .foregroundColor: UIColor.k666666]))
            v.append(NSAttributedString(string: "MMHG", attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.k999999]))
            pressureValueLabel.attributedText = v
            return
        }
        let models = try? DBloodModel.er.array("mac = '\(lastestDeviceMac)'").sorted(byKeyPath: "timeStamp", ascending: false)
        print("数据库里血压的数据总条数：\(models?.count ?? 0)")
        var min = 0
        var max = 0
        if models?.count ?? 0 > 0 {
            min = models?[0].min ?? 0
            max = models?[0].max ?? 0
        }
        let v = NSMutableAttributedString()
        v.append(NSAttributedString(string: "\(max)/\(min)", attributes: [.font: UIFont.systemFont(ofSize: 32), .foregroundColor: UIColor.k666666]))
        v.append(NSAttributedString(string: "MMHG", attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.k999999]))
        pressureValueLabel.attributedText = v
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
        if let value = UserDefaults.standard.string(forKey: "oxygen"), value.count > 0 {
            let v = NSMutableAttributedString()
            v.append(NSAttributedString(string: "\(value)", attributes: [.font: UIFont.systemFont(ofSize: 32), .foregroundColor: UIColor.k666666]))
            v.append(NSAttributedString(string: "%  \("health_head".localized())", attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.k999999]))
            bleedValueLabel.attributedText = v
            return
        }
        let models = try? DOxygenModel.er.array("mac = '\(lastestDeviceMac)'").sorted(byKeyPath: "timeStamp", ascending: false)
        print("数据库里血氧的数据总条数：\(models?.count ?? 0)")
        let value = models?.first?.oxygen ?? 0
        let v = NSMutableAttributedString()
        v.append(NSAttributedString(string: "\(value)", attributes: [.font: UIFont.systemFont(ofSize: 32), .foregroundColor: UIColor.k666666]))
        v.append(NSAttributedString(string: "%  \("health_head".localized())", attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.k999999]))
        bleedValueLabel.attributedText = v
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
        if #available(iOS 10.3, *) {
            SKStoreReviewController.requestReview()
            log.info("SKStoreReviewController: requestReview")
        } else {
            log.info("SKStoreReviewController: failed, system is unvalid")
        }
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
