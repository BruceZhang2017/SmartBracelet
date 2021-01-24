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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let fileName = "head\(UserManager.sharedInstall.user?.id ?? 0).jpg"
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
        userNameLabel.text = UserManager.sharedInstall.user?.username ?? "未设置名称"
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
        let alert = UIAlertController(title: "提示", message: "您确定退出该账号？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: { (action) in
            
        }))
        alert.addAction(UIAlertAction(title: "确定", style: .default, handler: { (action) in
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
            Toast(text: "设备未连接，请先连接设备。").show()
            return
        }
        let count = DeviceManager.shared.devices.count
        if count > 0 {
            for item in DeviceManager.shared.devices {
                if item.mac == lastestDeviceMac {
                    showOTAView()
                    break
                }
            }
        } else {
            if bleSelf.bleModel.mac == lastestDeviceMac {
                Toast(text: "本地没有Lefun的OTA文件，需要找供应商提供。").show()
            }
        }
        
    }
    
    private func showOTAView() {
        let alert = UIAlertController(title: "OTA", message: "使用本地OTA文件：8267_module_tOTA.bin", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "确认", style: .default, handler: { [weak self] (action) in
            self?.pushToOTA()
        }))
        present(alert, animated: true) {
            
        }
    }
    
    private func pushToOTA() {
        let otaVC = OTAViewController()
        otaVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(otaVC, animated: true)
    }
}

extension String {
    static let kMine = "Mine"
}
