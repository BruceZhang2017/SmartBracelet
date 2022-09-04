//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  MTabBarController.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/9/19.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit
import TJDWristbandSDK

var lastestDeviceMac: String = ""

class MTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        BLEManager.shared.regNotification()
        lastestDeviceMac = UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? ""
        print("最后连接的设备MAC地址为：\(lastestDeviceMac)")
        if lastestDeviceMac.count > 0 {
            perform(#selector(checkIfNeedScanDevice), with: nil, afterDelay: 1)
        }
        print("数据库里面：\(DeviceManager.shared.devices.count)")
        viewControllers?[0].title = "health_head".localized()
        viewControllers?[1].title = "device".localized()
        viewControllers?[2].title = "mine".localized()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(handleDeviceConnected(_ :)), name: Notification.Name("MTabBarController"), object: nil)
        
        let bShow = UserDefaults.standard.bool(forKey: "PrivacyPolicy")
        if !bShow {
            showLinkedAlert()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    deinit {
        
    }
    
    private func showLinkedAlert() {
        let attributedString = NSMutableAttributedString(string:"《隐私保护》和 《用户协议》")
        attributedString.SetAsLink(textToFind: "《隐私保护》", linkURL: "http://www.sinophy.com/Arc_See.aspx?aid=185#")
        attributedString.SetAsLink(textToFind: "《用户协议》", linkURL: "http://www.sinophy.com/Arc_See.aspx?aid=188")
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        attributedString.addAttribute(.paragraphStyle, value: paragraph, range: NSMakeRange(0, attributedString.length))
        attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 20), range:  NSMakeRange(0, attributedString.length))
        let alert: UIAlertView = UIAlertView(title: "服务协议和隐私政策", message: "请你务必审慎阅读",
                                             delegate: self, cancelButtonTitle: "拒绝并退出", otherButtonTitles: "同意")
        
        let Txt:UITextView = UITextView(frame:CGRect(x: 0, y: 0, width: 100, height: 80))
        Txt.font = UIFont.systemFont(ofSize: 25)
        Txt.textAlignment = .center
        Txt.backgroundColor = UIColor.clear
        Txt.attributedText = attributedString
        Txt.isEditable = false
        Txt.dataDetectorTypes = UIDataDetectorTypes.link
        
        alert.setValue(Txt, forKey: "accessoryView")
        alert.show()
    }

    @objc func handleDeviceConnected(_ notification: Notification) {
        let obj = notification.object as? String ?? ""
        if obj == "disconnect" {
            (selectedViewController as? UINavigationController)?.popToRootViewController(animated: true)
        }
        
    }
    
    /// 延迟300ms，执行判断是否需要搜索设备
    @objc private func checkIfNeedScanDevice() {
        if let model = WUBleModel.getModel() as? TJDWristbandSDK.WUBleModel {
            if model.mac == lastestDeviceMac {
                print("还是执行搜索并连接")
                BLEManager.shared.startScanAndConnect()
                return
            }
        }
    }
}

extension MTabBarController: UIAlertViewDelegate {
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        UserDefaults.standard.set(true, forKey: "PrivacyPolicy")
        UserDefaults.standard.synchronize()
    }
}
