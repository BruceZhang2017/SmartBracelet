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
import Toaster

var lastestDeviceMac: String = ""

class MTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        BLEManager.shared.regNotification()
        setupLastestDeviceMac()
        setupViewControllersTitles()
        
        // 设置未选中状态下的字体颜色
        let unselectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.gray // 你可以替换为你想要的颜色
        ]

        // 设置选中状态下的字体颜色
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.brand // 你可以替换为你想要的颜色
        ]

        // 设置UITabBarItem的字体颜色
        UITabBarItem.appearance().setTitleTextAttributes(unselectedAttributes, for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes(selectedAttributes, for: .selected)
        
        
        ToastView.appearance().backgroundColor = .black.withAlphaComponent(0.8)
        ToastView.appearance().bottomOffsetPortrait = screenHeight / 2 - 20
        ToastView.appearance().maxWidthRatio = 0.8
        ToastView.appearance().cornerRadius = 16
        ToastView.appearance().font = UIFont.body()
        ToastView.appearance().textColor = UIColor.white
        ToastView.appearance().textInsets = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)
        
    }
    
    // 设置最后连接的设备MAC地址
    private func setupLastestDeviceMac() {
        lastestDeviceMac = UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? ""
        print("最后连接的设备MAC地址为：\(lastestDeviceMac)")
        if !lastestDeviceMac.isEmpty {
            perform(#selector(checkIfNeedScanDevice), with: nil, afterDelay: 1)
        }
    }
    
    // 设置视图控制器的标题
    private func setupViewControllersTitles() {
        print("数据库里面：\(DeviceManager.shared.devices.count)")
        let titles = ["health_head", "device", "mine"].map { $0.localized() }
        for (index, title) in titles.enumerated() {
            viewControllers?[index].title = title
            
        }
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
        let pp = "privacy_protection".localized()
        let up = "user_agreement".localized()
        let and = "and".localized()
        let attributedString = NSMutableAttributedString(string:"\(pp) \(and) \(up)")
        attributedString.SetAsLink(textToFind: pp, linkURL: "http://www.sinophy.com/Arc_See.aspx?aid=185#")
        attributedString.SetAsLink(textToFind: up, linkURL: "http://www.sinophy.com/Arc_See.aspx?aid=188")
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        attributedString.addAttribute(.paragraphStyle, value: paragraph, range: NSMakeRange(0, attributedString.length))
        attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 20), range:  NSMakeRange(0, attributedString.length))
        let alert: UIAlertView = UIAlertView(title: "\(pp) \(and) \(up)", message: "read_carefully".localized(),
                                             delegate: self, cancelButtonTitle: "reject_and_exit".localized(), otherButtonTitles: "agree".localized())
        
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
