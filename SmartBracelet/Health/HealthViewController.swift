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

class HealthViewController: BaseViewController {
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
    @IBOutlet weak var pressureView: UIView!
    @IBOutlet weak var pressureTipLabel: UILabel!
    @IBOutlet weak var pressureValueLabel: UILabel!
    @IBOutlet weak var bleedView: UIView!
    @IBOutlet weak var bleedTipLabel: UILabel!
    @IBOutlet weak var bleedValueLabel: UILabel!
    var flag = 0
    var popup: PopupBViewController?
    var activityIndicator: NVActivityIndicatorView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupProperty()
        registerNotification()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        footGoalLabel.text = "目标 ｜ \(bleSelf.userInfo.stepGoal)步"
    }
    
    deinit {
        unregisterNotification()
    }
    
    func setupProperty() {
        heartView.addShadow(color: UIColor.k333333, offset: CGSize(width: 0, height: 1), opacity: 0.1)
        sleepView.addShadow(color: UIColor.k333333, offset: CGSize(width: 0, height: 1), opacity: 0.1)
        pressureView.addShadow(color: UIColor.k333333, offset: CGSize(width: 0, height: 1), opacity: 0.1)
        bleedView.addShadow(color: UIColor.k333333, offset: CGSize(width: 0, height: 1), opacity: 0.1)
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
            DispatchQueue.main.sync {
                [weak self] in
                let foot = NSMutableAttributedString()
                foot.append(NSAttributedString(string: "\(bleSelf.step)", attributes: [.font: UIFont.systemFont(ofSize: 36)]))
                foot.append(NSAttributedString(string: "步", attributes: [.font: UIFont.systemFont(ofSize: 12)]))
                self?.footValueLabel.attributedText = foot
                let unit = Float(bleSelf.distance) / 1000
                self?.footUnitLabel.text = "\(String(format: "%.2f", unit))公里"
                let value = NSMutableAttributedString()
                let v = Float(bleSelf.cal) / 1000
                value.append(NSAttributedString(string: "\(String(format: "%.2f", v))", attributes: [.font: UIFont.systemFont(ofSize: 36)]))
                value.append(NSAttributedString(string: "千卡", attributes: [.font: UIFont.systemFont(ofSize: 12)]))
                self?.heatValueLabel.attributedText = value
            }
        } else if objc == "sleep" {
            DispatchQueue.main.sync {
                [weak self] in
                let array = BLEManager.shared.sleepArray[0]
                if array.count > 0 {
                    let arr = BLEManager.shared.readSleepData(array: array) // 获得睡眠时间
                    let total = arr.reduce(0, +)
                    let h = total / 60
                    let m = total % 60
                    let arrStr = NSMutableAttributedString()
                    arrStr.append(NSAttributedString(string: "\(h)", attributes: [.font: UIFont.systemFont(ofSize: 36), .foregroundColor: UIColor.k666666]))
                    arrStr.append(NSAttributedString(string: "小时", attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.k999999]))
                    arrStr.append(NSAttributedString(string: "\(m)", attributes: [.font: UIFont.systemFont(ofSize: 36), .foregroundColor: UIColor.k666666]))
                    arrStr.append(NSAttributedString(string: "分", attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.k999999]))
                    self?.sleepValueLabel.attributedText = arrStr
                } else {
                    let arrStr = NSMutableAttributedString()
                    arrStr.append(NSAttributedString(string: "0", attributes: [.font: UIFont.systemFont(ofSize: 36), .foregroundColor: UIColor.k666666]))
                    arrStr.append(NSAttributedString(string: "小时", attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.k999999]))
                    arrStr.append(NSAttributedString(string: "0", attributes: [.font: UIFont.systemFont(ofSize: 36), .foregroundColor: UIColor.k666666]))
                    arrStr.append(NSAttributedString(string: "分", attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.k999999]))
                    self?.sleepValueLabel.attributedText = arrStr
                }
            }
        } else if objc == "heart" {
            DispatchQueue.main.sync {
                [weak self] in
                var heart = 0
                if BLEManager.shared.heartArray.count == 0 {
                    heart = 0
                } else {
                    heart = BLEManager.shared.heartArray[0].heart
                }
                let v = NSMutableAttributedString()
                v.append(NSAttributedString(string: "\(heart)", attributes: [.font: UIFont.systemFont(ofSize: 36), .foregroundColor: UIColor.k666666]))
                v.append(NSAttributedString(string: "次/分", attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.k999999]))
                self?.heartValueLabel.attributedText = v
            }
        } else if objc == "blood" {
            DispatchQueue.main.sync {
                [weak self] in
                var min = 0
                var max = 0
                if BLEManager.shared.bloodArray.count != 0 {
                    min = BLEManager.shared.bloodArray[0].min
                    max = BLEManager.shared.bloodArray[0].max
                }
                let v = NSMutableAttributedString()
                v.append(NSAttributedString(string: "\(max)/\(min)", attributes: [.font: UIFont.systemFont(ofSize: 36), .foregroundColor: UIColor.k666666]))
                v.append(NSAttributedString(string: "MMHG", attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.k999999]))
                self?.pressureValueLabel.attributedText = v
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
            return
        }
        if obj == 3 {
            print("隐藏loading图片")
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
        let count = DeviceManager.shared.devices.count + (bleSelf.bleModel.mac.count > 0 ? 1 : 0)
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
    
}
