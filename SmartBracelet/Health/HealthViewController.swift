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
import NVActivityIndicatorView
import Toaster
import TJDWristbandSDK

class HealthViewController: BaseViewController {
    @IBOutlet weak var mScrollView: UIScrollView!
    @IBOutlet weak var footView: UIView!
    @IBOutlet weak var heatView: UIView!
    @IBOutlet weak var footTipLabel: UILabel!
    @IBOutlet weak var footUnitLabel: UILabel!
    @IBOutlet weak var footValueLabel: UILabel!
    @IBOutlet weak var footGoalLabel: UILabel!
    @IBOutlet weak var heatTipLabel: UILabel!
    @IBOutlet weak var heatValueLabel: UILabel!
    @IBOutlet weak var heatGoalLabel: UILabel!
    @IBOutlet weak var heartView: UIView!
    @IBOutlet weak var heartTipLabel: UILabel!
    @IBOutlet weak var heartValueLabel: UILabel!
    @IBOutlet weak var sleepView: UIView!
    @IBOutlet weak var sleepTipLabel: UILabel!
    @IBOutlet weak var sleepValueLabel: UILabel!
    @IBOutlet weak var sleepCurveImageView: UIImageView!
    @IBOutlet weak var pressureView: UIView!
    @IBOutlet weak var pressureTipLabel: UILabel!
    @IBOutlet weak var pressureValueLabel: UILabel!
    @IBOutlet weak var bleedView: UIView!
    @IBOutlet weak var bleedTipLabel: UILabel!
    @IBOutlet weak var bleedValueLabel: UILabel!
    @IBOutlet weak var heartRateImageView: UIImageView!
    var flag = 0 // 属性的作用
    var popup: PopupBViewController?
    var activityIndicator: NVActivityIndicatorView? // loading图标
    private var loadingViewCheckTimer: Timer?
    var heartRateView: HeartRateView!
    var curveView: CurveView!
    var header: MJRefreshNormalHeader?
     
    override func viewDidLoad() {
        super.viewDidLoad()
        setupProperty()
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let lastestDeviceMac = UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? ""
        if lastestDeviceMac.count == 0 {
            footGoalLabel.text = "目标 ｜ 0步"
        } else {
            var goal = UserDefaults.standard.integer(forKey: "Goal")
            if goal == 0 {
                goal = bleSelf.userInfo.stepGoal
            }
            footGoalLabel.text = "目标 ｜ \(goal)步"
        }
        readDBStep() // 从本地数据库中读取步数数据
        readDBHeart() // 从本地数据库中读取心跳数据
        readDBSleep() // 从本地数据库中读取睡眠数据
        readDBBlood() // 从本地数据库中读取血压数据
        readDBOxygen() // 从本地数据库中读取血氧数据
    }
    
    deinit {
        unregisterNotification()
    }
    
    func setupProperty() {
        heartView.addShadow(color: UIColor.k333333, offset: CGSize(width: 0, height: 1), opacity: 0.1)
        sleepView.addShadow(color: UIColor.k333333, offset: CGSize(width: 0, height: 1), opacity: 0.1)
        pressureView.addShadow(color: UIColor.k333333, offset: CGSize(width: 0, height: 1), opacity: 0.1)
        bleedView.addShadow(color: UIColor.k333333, offset: CGSize(width: 0, height: 1), opacity: 0.1)
        
        heartRateView = HeartRateView(frame: CGRect(x: 0, y: 0, width: 242, height: 50))
        heartView.addSubview(heartRateView)
        heartRateView.snp.makeConstraints {
            $0.edges.equalTo(heartRateImageView)
        }
        
        curveView = CurveView(frame: CGRect(x: 0, y: 0, width: 242, height: 50))
        sleepView.addSubview(curveView)
        curveView.snp.makeConstraints {
            $0.edges.equalTo(sleepCurveImageView)
        }
    }
    
    private func registerNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: Notification.Name("HealthViewController"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleShowLoading(_:)), name: Notification.Name("HealthVCLoading"), object: nil)
    }
    
    private func unregisterNotification() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleNotification(_ notification: Notification) {
        let objc = notification.object as! String
        if objc == "step" {
            DispatchQueue.main.async {
                [weak self] in
                let foot = NSMutableAttributedString()
                let step = bleSelf.step
                foot.append(NSAttributedString(string: "\(step)", attributes: [.font: UIFont.systemFont(ofSize: 32)]))
                foot.append(NSAttributedString(string: "步", attributes: [.font: UIFont.systemFont(ofSize: 12)]))
                self?.footValueLabel.attributedText = foot
                let distance = bleSelf.distance
                let unit = Float(distance) / 1000
                self?.footUnitLabel.text = "\(String(format: "%.2f", unit))公里"
                let value = NSMutableAttributedString()
                let cal = bleSelf.cal
                let v = Float(cal) / 1000
                value.append(NSAttributedString(string: "\(String(format: "%.2f", v))", attributes: [.font: UIFont.systemFont(ofSize: 32)]))
                value.append(NSAttributedString(string: "千卡", attributes: [.font: UIFont.systemFont(ofSize: 12)]))
                self?.heatValueLabel.attributedText = value
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
                    arrStr.append(NSAttributedString(string: "小时", attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.k999999]))
                    arrStr.append(NSAttributedString(string: "\(m)", attributes: [.font: UIFont.systemFont(ofSize: 32), .foregroundColor: UIColor.k666666]))
                    arrStr.append(NSAttributedString(string: "分", attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.k999999]))
                    self?.sleepValueLabel.attributedText = arrStr
                    if arr.count == 3 {
                        let value: [CGFloat] = [CGFloat(arr[0] * 50 / (12 * 60) ), CGFloat(arr[1] * 50 / (12 * 60)), CGFloat(arr[2] * 50 / (12 * 60))]
                        self?.curveView.refreshHeight(value)
                    }
                } else {
                    let arrStr = NSMutableAttributedString()
                    arrStr.append(NSAttributedString(string: "0", attributes: [.font: UIFont.systemFont(ofSize: 32), .foregroundColor: UIColor.k666666]))
                    arrStr.append(NSAttributedString(string: "小时", attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.k999999]))
                    arrStr.append(NSAttributedString(string: "0", attributes: [.font: UIFont.systemFont(ofSize: 32), .foregroundColor: UIColor.k666666]))
                    arrStr.append(NSAttributedString(string: "分", attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.k999999]))
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
                v.append(NSAttributedString(string: "次/分", attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.k999999]))
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
                v.append(NSAttributedString(string: "%  健康", attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.k999999]))
                self?.bleedValueLabel.attributedText = v
            }
        } else if objc == "delete" {
            let lastestDeviceMac = UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? ""
            if lastestDeviceMac.count > 0 {
                for device in DeviceManager.shared.devices {
                    if device.mac == lastestDeviceMac {
                        try? device.er.delete()
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
            attStr.append(NSAttributedString(string: "蓝牙未连接\n请到", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 13)]))
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
            print("显示loading图片")
            let frame = CGRect(x: 0, y: 0, width: 150, height: 150)
            activityIndicator = NVActivityIndicatorView(frame: frame, type: .ballSpinFadeLoader, color: UIColor.white, padding: 30)
            activityIndicator?.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            activityIndicator?.center = CGPoint(x: view.center.x, y: view.center.y - 100)
            view.addSubview(activityIndicator!)
            activityIndicator?.startAnimating()
            startLoadingViewCheckTimer()
            return
        }
        if obj == 3 {
            print("隐藏loading图片")
            endLoadingViewCheckTimer()
            DispatchQueue.main.async {
                [weak self] in
                if self?.activityIndicator != nil && (self?.activityIndicator?.isAnimating ?? false) {
                    self?.activityIndicator?.stopAnimating()
                    self?.activityIndicator?.removeFromSuperview()
                    self?.activityIndicator = nil
                }
            }
        }
    }
    
    private func startLoadingViewCheckTimer() {
        endLoadingViewCheckTimer()
        loadingViewCheckTimer = Timer.scheduledTimer(withTimeInterval: 20, repeats: false, block: { (timer) in
            NotificationCenter.default.post(name: Notification.Name("HealthVCLoading"), object: 3)
        })
    }
    
    private func endLoadingViewCheckTimer() {
        loadingViewCheckTimer?.invalidate()
        loadingViewCheckTimer = nil
    }
    
    private func refreshLefunHeartRate() {
        let array = BLEManager.shared.heartArray
        for item in array {
            let timeStamp = item.timeStamp
            let date = Date(timeIntervalSince1970: TimeInterval(timeStamp))
            if date.isToday() {
                let hour = Int(date.stringFromH()) ?? 0
                heartRateView.heartRateArray[hour] = item.heart
            }
        }
        heartRateView.collectionView.reloadData()
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let vc = segue.destination as? HealthDetailViewController else {
            return
        }
        if flag == 0 {
            vc.colors = [UIColor.k88C9FA, UIColor.k0095F5]
            vc.type = 0
        }
        if flag == 1 {
            vc.colors = [UIColor.kFFB642, UIColor.kFF5E46]
            vc.type = 1
        }
        if flag == 2 {
            vc.colors = [UIColor.kFFA87E, UIColor.kEA5959]
            vc.type = 2
        }
        if flag == 3 {
            vc.colors = [UIColor.kCE96FF, UIColor.k7A61FF]
            vc.type = 3
        }
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
        
    }
    
    @IBAction func handleBleed(_ sender: Any) {
        
    }
    
    
    @IBAction func addDevice(_ sender: Any) {
        let count = DeviceManager.shared.devices.count
        let storyboard = UIStoryboard(name: "Device", bundle: nil)
        if count == 0 {
            let vc = storyboard.instantiateViewController(withIdentifier: "DeviceSearchViewController")
            vc.title = "添加设备"
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        } else {
            let vc = storyboard.instantiateViewController(withIdentifier: "DeviceListViewController")
            vc.title = "设备切换"
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func handleHealth(_ sender: Any) {
        let detail = DetailViewController()
        navigationController?.pushViewController(detail, animated: true)
    }
    
    
    // 读取数据库内缓存数据
    private func readDBStep() {
        let time = Int(Date().zeroTimeStamp())
        let models = try? DStepModel.er.array("timeStamp > \(time) AND mac = '\(lastestDeviceMac)'")
        print("数据库里\(lastestDeviceMac)步数晚于\(time)的数据总条数：\(models?.count ?? 0)")
        let foot = NSMutableAttributedString()
        var step = 0
        var distance = 0
        var cal = 0
        let count = models?.count ?? 0
        for i in 0..<count {
            step += models?[i].step ?? 0
            distance += models?[i].distance ?? 0
            cal += models?[i].cal ?? 0
        }
        foot.append(NSAttributedString(string: "\(step)", attributes: [.font: UIFont.systemFont(ofSize: 32)]))
        foot.append(NSAttributedString(string: "步", attributes: [.font: UIFont.systemFont(ofSize: 12)]))
        footValueLabel.attributedText = foot
        let unit = Float(distance) / 1000
        footUnitLabel.text = "\(String(format: "%.2f", unit))公里"
        let value = NSMutableAttributedString()
        let v = Float(cal) / 1000
        value.append(NSAttributedString(string: "\(String(format: "%.2f", v))", attributes: [.font: UIFont.systemFont(ofSize: 32)]))
        value.append(NSAttributedString(string: "千卡", attributes: [.font: UIFont.systemFont(ofSize: 12)]))
        heatValueLabel.attributedText = value
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
        var heart = 0
        if models?.count ?? 0 > 0 {
            heart = models?[0].heartRate ?? 0
        }
        let v = NSMutableAttributedString()
        v.append(NSAttributedString(string: "\(heart)", attributes: [.font: UIFont.systemFont(ofSize: 32), .foregroundColor: UIColor.k666666]))
        v.append(NSAttributedString(string: "次/分", attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.k999999]))
        heartValueLabel.attributedText = v

        if models?.count ?? 0 > 0 {
            for item in models! {
                let timeStamp = item.timeStamp
                let date = Date(timeIntervalSince1970: TimeInterval(timeStamp))
                if date.isToday() {
                    let hour = Int(date.stringFromH()) ?? 0
                    heartRateView.heartRateArray[hour] = item.heartRate
                }
            }
        } else {
            heartRateView.heartRateArray = Array(repeating: 0, count: 24)
        }
        heartRateView.collectionView.reloadData()
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
            arrStr.append(NSAttributedString(string: "小时", attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.k999999]))
            arrStr.append(NSAttributedString(string: "\(m)", attributes: [.font: UIFont.systemFont(ofSize: 32), .foregroundColor: UIColor.k666666]))
            arrStr.append(NSAttributedString(string: "分", attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.k999999]))
            sleepValueLabel.attributedText = arrStr
            if arr.count == 3 {
                let value: [CGFloat] = [CGFloat(arr[0] * 50 / (12 * 60) ), CGFloat(arr[1] * 50 / (12 * 60)), CGFloat(arr[2] * 50 / (12 * 60))]
                curveView.refreshHeight(value)
            }
        } else {
            let arrStr = NSMutableAttributedString()
            arrStr.append(NSAttributedString(string: "0", attributes: [.font: UIFont.systemFont(ofSize: 32), .foregroundColor: UIColor.k666666]))
            arrStr.append(NSAttributedString(string: "小时", attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.k999999]))
            arrStr.append(NSAttributedString(string: "0", attributes: [.font: UIFont.systemFont(ofSize: 32), .foregroundColor: UIColor.k666666]))
            arrStr.append(NSAttributedString(string: "分", attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.k999999]))
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
        let models = try? DBloodModel.er.array("timeStamp > \(Int(Date().zeroTimeStamp())) AND mac = '\(lastestDeviceMac)'")
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
        let models = try? DOxygenModel.er.array("timeStamp > \(Int(Date().zeroTimeStamp())) AND mac = '\(lastestDeviceMac)'").sorted(byKeyPath: "timeStamp", ascending: false)
        print("数据库里血氧的数据总条数：\(models?.count ?? 0)")
        let value = models?.first?.oxygen ?? 0
        let v = NSMutableAttributedString()
        v.append(NSAttributedString(string: "\(value)", attributes: [.font: UIFont.systemFont(ofSize: 32), .foregroundColor: UIColor.k666666]))
        v.append(NSAttributedString(string: "%  健康", attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.k999999]))
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
}
