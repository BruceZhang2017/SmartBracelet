//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  MineViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/8/17.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit
import Toaster

class MineViewController: BaseViewController {
    @IBOutlet weak var headImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var recordLabel: UILabel!
    @IBOutlet weak var deviceButton: UIButton!
    @IBOutlet weak var btButton: UIButton!
    @IBOutlet weak var batteryButton: UIButton!
    @IBOutlet weak var deviceInfoLabel: UILabel!
    @IBOutlet weak var helpCenterLabel: UILabel!
    @IBOutlet weak var aboutUsLabel: UILabel!
    @IBOutlet weak var accountInfoLabel: UILabel!
    @IBOutlet weak var userinfoLabel: UILabel!
    @IBOutlet weak var otaLabel: UILabel!
    var originalMacAddress = ""
    var originalUUID = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: Notification.Name("BluetoothGetMacAddress"), object: nil)
        deviceInfoLabel.text = "device_device_info".localized()
        navigationItem.rightBarButtonItem?.title = "mine".localized()
        helpCenterLabel.text = "mine_help_center".localized()
        aboutUsLabel.text = "mine_about".localized()
        accountInfoLabel.text = "mine_account_info".localized()
        userinfoLabel.text = "mine_userinfo".localized()
        otaLabel.text = "mine_device_ota".localized()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let fileName = "head.jpg"
        let b = FileCache().fileIfExist(name: fileName)
        if b {
            let data = FileCache().readData(name: fileName)
            headImageView.image = UIImage(data: data)
        } else {
            let url = UserManager.sharedInstall.user?.headUrl ?? ""
            if url.count > 0 {
                OSS.sharedInstance.setupOSSClient()
                OSS.sharedInstance.getObject(key: fileName) {
                    (data) in
                    DispatchQueue.main.async {
                        [weak self] in
                        if data != nil {
                            self?.headImageView.image = UIImage(data: data!)
                            FileCache().saveData(data!, name: fileName)
                        }
                    }
                }
            }
        }
        let name = UserDefaults.standard.string(forKey: "NickName")
        if name?.count ?? 0 > 0 {
            userNameLabel.text = name
        } else {
            userNameLabel.text = bleSelf.userInfo.name
        }
        if userNameLabel.text?.count ?? 0 == 0 {
            userNameLabel.text = "个人信息 -> 设置昵称"
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if bleSelf.isConnected == false {
            deviceButton.setTitle("mine_unconnect".localized(), for: .normal)
            btButton.setImage(UIImage(named: "content_blueteeth_unlink"), for: .normal)
            btButton.setTitle("mine_bluetooth_unconnect".localized(), for: .normal)
            batteryButton.setImage(UIImage(named: "conten_battery_null"), for: .normal)
            batteryButton.setTitle("mine_battery_level_unknown".localized(), for: .normal)
            return
        }
        let deviceCount = DeviceManager.shared.devices.count
        var tem = false
        if deviceCount > 0 {
            for item in DeviceManager.shared.devices {
                if item.mac == lastestDeviceMac {
                    tem = true
                    deviceButton.setTitle(item.name, for: .normal)
                    btButton.setImage(UIImage(named: "content_blueteeth_link"), for: .normal)
                    btButton.setTitle("mine_bluetooth_connect".localized(), for: .normal)
                    let deviceInfo = DeviceManager.shared.deviceInfo[item.mac]
                    if deviceInfo != nil {
                        if deviceInfo?.battery ?? 0 < 5 {
                            batteryButton.setImage(UIImage(named: "conten_battery_runout"), for: .normal)
                            batteryButton.setTitle("\("mine_battery_level_low".localized())5%", for: .normal)
                        } else {
                            batteryButton.setImage(UIImage(named: "conten_battery_full"), for: .normal)
                            batteryButton.setTitle("\("mine_battery_level".localized())\(deviceInfo?.battery ?? 0)%", for: .normal)
                        }
                    } else {
                        batteryButton.setImage(UIImage(named: "conten_battery_null"), for: .normal)
                        batteryButton.setTitle("mine_battery_level_unknown".localized(), for: .normal)
                    }
                    break
                }
            }
        }
    }
    
    @objc private func handleNotification(_ notificaiton: Notification) {
        let userinfo = notificaiton.userInfo as? [String : String]
        originalMacAddress = userinfo?["originalMacAddress"] ?? ""
        originalUUID = userinfo?["originalUUID"] ?? ""
        perform(#selector(startLefunOTA), with: nil, afterDelay: 3)
    }
    
    @IBAction func handleEvent(_ sender: Any) {
        guard let recognizer = sender as? UITapGestureRecognizer else {
            return
        }
        guard let view = recognizer.view else {
            return
        }
        let tag = view.tag
        if tag == 6 { // 数据记录
            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "DataRecordViewController")
            navigationController?.pushViewController(vc, animated: true)
        } else if tag == 7 { // 帮助中心
            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "HelpCenterViewController")
            navigationController?.pushViewController(vc, animated: true)
        } else if tag == 8 { // 软件升级
            startOTA()
        } else if tag == 9 { // 关于
            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "AboutUSViewController")
            navigationController?.pushViewController(vc, animated: true)
        } else if tag == 10 { // 个人信息
            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "UserInfoViewController")
            navigationController?.pushViewController(vc, animated: true)
        } else if tag == 11 { // 账号与安全
            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "AccountSafeViewController")
            navigationController?.pushViewController(vc, animated: true)
        } else if tag == 12 { // 付款与账单
            Toast(text: "敬请期待").show()
        } else if tag == 13 {
            Toast(text: "敬请期待").show()
        } else if tag == 14 { // 退出登录
            logout()
        } else if tag == 15 {
            
        } else if tag == 16 {
                                 
        }
    }
    
    private func logout() {
        let alert = UIAlertController(title: "device_tip".localized(), message: "您确定退出该账号？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "mine_cancel".localized(), style: .cancel, handler: { (action) in
            
        }))
        alert.addAction(UIAlertAction(title: "mine_confirm".localized(), style: .default, handler: { (action) in
            let sb = UIStoryboard(name: "Mine", bundle: nil)
            let nav = sb.instantiateViewController(withIdentifier: "MNavigationController")
            UIApplication.shared.keyWindow?.rootViewController = nav
            UserManager.sharedInstall.deleteUser()
        }))
        present(alert, animated: true) {
            
        }
    }
    
    private func startOTA() {
        if lastestDeviceMac.count == 0 {
            Toast(text: "mine_unconnect".localized()).show()
            return
        }
        let count = DeviceManager.shared.devices.count
        if count > 0 {
            for item in DeviceManager.shared.devices {
                if item.mac == lastestDeviceMac {
                    showOTAView(false)
                    break
                }
            }
        } else {
            if bleSelf.bleModel.mac == lastestDeviceMac {
                showOTAView(true)
            }
        }
        
    }
    
    private func showOTAView(_ value: Bool) {
        let alert = UIAlertController(title: "OTA", message: "使用本地OTA文件：\(value ? "SmartBand_PHY_ota.hex" : "8267_module_tOTA.bin")", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "mine_cancel".localized(), style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "确认", style: .default, handler: { [weak self] (action) in
            self?.pushToOTA(value)
        }))
        present(alert, animated: true) {
            
        }
    }
    
    private func pushToOTA(_ value: Bool) {
        if value { // 如果是Lefun项目
            let uuid = bleSelf.bleModel.uuidString
            if let per = JCBluetoothManager.shareCBCentral()?.retrievePeripherals(withIdentifiers: uuid) {
                bleSelf.disconnectBleDevice() // 断开连接
                perform(#selector(handleOTABLEConnected(per:)), with: per, afterDelay: 3)
            }
            return
        }
        let otaVC = OTAViewController()
        otaVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(otaVC, animated: true)
    }
    
    @objc private func handleOTABLEConnected(per: CBPeripheral) {
        JCBluetoothManager.shareCBCentral()?.connect(to: per)
    }
    
    @objc private func startLefunOTA() {
        let otaVC = OTAUpgradeViewController()
        otaVC.mscAddress = originalMacAddress
        otaVC.originalUUID = originalUUID
        otaVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(otaVC, animated: true)
    }
    
    @IBAction func pushToAddDevice(_ sender: Any) {
        let count = DeviceManager.shared.devices.count + (bleSelf.bleModel.mac.count > 0 ? 1 : 0)
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
    
    @IBAction func pushToGrade(_ sender: Any) {
        let sb = UIStoryboard(name: "Sport", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "GradeViewController")
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension String {
    static let kMine = "Mine"
}
