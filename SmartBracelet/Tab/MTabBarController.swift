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

var lastestDeviceMac: String = "" // 最后连接的设备mac地址
var isXGZT = false // 自研手表

class MTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var localVersion = ""
        if let v:String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            localVersion = v
        }
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        XLogger.shared.log("v\(localVersion) - build\(build)")
        DispatchQueue.global().async { [weak self] in
            self?.setupLastestDeviceMac()
            XGZTBlueToothManager.shared.initCentral() // 自定义协议初始化
            BLEManager.shared.regNotification()
        }

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
        ToastView.appearance().maxWidthRatio = 0.8
        ToastView.appearance().cornerRadius = 16
        ToastView.appearance().font = UIFont.body()
        ToastView.appearance().textColor = UIColor.white
        ToastView.appearance().textInsets = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)
        
        BluetoothWatchDevice.loadAll() // 加载一下缓存信息
        
    }
    
    // 设置最后连接的设备MAC地址
    private func setupLastestDeviceMac() {
        lastestDeviceMac = UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? ""
        XLogger.shared.log("最后连接的设备MAC地址为：\(lastestDeviceMac)")
        if !lastestDeviceMac.isEmpty {
            perform(#selector(checkIfNeedScanDevice), with: nil, afterDelay: 1)
        }
    }
    
    // 设置视图控制器的标题
    private func setupViewControllersTitles() {
        XLogger.shared.log("数据库里面：\(DeviceManager.shared.devices.count)")
        let titles = ["health_head","sport", "device", "mine"].map { $0.localized() }
        for (index, title) in titles.enumerated() {
            viewControllers?[index].title = title
            
        }
        if viewControllers?.count == 4 {
            if let nav = viewControllers?[1] as? MNavigationController {
                nav.viewControllers = [SportBViewController()]
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if lastestDeviceMac.isEmpty || lastestDeviceMac.count == 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.selectedIndex = 2
            }
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
        NotificationCenter.default.removeObserver(self)
    }
    
    private func showLinkedAlert() {
        // 优化字符串拼接和属性设置
        let pp = "privacy_protection".localized()
        let up = "user_agreement".localized()
        let and = "and".localized()
        let fullText = "\(pp) \(and) \(up)"
        let attributedString = NSMutableAttributedString(string: fullText)
        attributedString.SetAsLink(textToFind: pp, linkURL: "https://u-watch.com.cn/u-watch_privacy_protection.html")
        attributedString.SetAsLink(textToFind: up, linkURL: "http://www.sinophy.com/arc_yhxy.html")
        
        // 优化段落样式和字体属性的设置
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let fullRange = NSRange(location: 0, length: attributedString.length)
        attributedString.addAttributes([.paragraphStyle: paragraph, .font: UIFont.systemFont(ofSize: 20)], range: fullRange)
        
        // 优化UIAlertView的创建和使用
        let alert = UIAlertView(title: fullText, message: "read_carefully".localized(),
                                delegate: self, cancelButtonTitle: "reject_and_exit".localized(), otherButtonTitles: "agree".localized())
        
        // 优化UITextView的创建和属性设置
        let txt = UITextView(frame: CGRect(x: 0, y: 0, width: 100, height: 80))
        txt.font = UIFont.systemFont(ofSize: 25)
        txt.textAlignment = .center
        txt.backgroundColor = .clear
        txt.attributedText = attributedString
        txt.isEditable = false
        txt.dataDetectorTypes = .link
        
        // 设置UIAlertView的accessoryView并显示
        alert.setValue(txt, forKey: "accessoryView")
        alert.show()
        
    }

    @objc func handleDeviceConnected(_ notification: Notification) {
        let obj = notification.object as? String ?? ""

        if obj == "disconnect" {
            if let navController = selectedViewController as? UINavigationController {
                navController.popToRootViewController(animated: false)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.selectedIndex = 2
                self.updateTabBarVisibility()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.selectedIndex = 0
                self.updateTabBarVisibility()
            }
        }
    }

    /// 根据当前选中的 NavigationController 层级更新 TabBar 的显示状态
    /// - 如果 viewControllers.count == 1（根视图），显示 TabBar
    /// - 如果 viewControllers.count > 1（子页面），隐藏 TabBar
    private func updateTabBarVisibility() {
        guard let navController = selectedViewController as? UINavigationController else {
            // 如果不是 NavigationController，默认显示 TabBar
            setTabBarHidden(false)
            return
        }

        // 根据导航栈层级决定 TabBar 显示状态
        let shouldHideTabBar = navController.viewControllers.count > 1
        setTabBarHidden(shouldHideTabBar)
    }

    /// 设置 TabBar 的显示/隐藏状态，兼容 iOS 17+
    /// - Parameter hidden: 是否隐藏 TabBar
    private func setTabBarHidden(_ hidden: Bool) {
        tabBar.isHidden = hidden

        // iOS 17+ 需要额外的布局更新
        if #available(iOS 17.0, *) {
            view.setNeedsLayout()
            view.layoutIfNeeded()
        }
    }
    
    /// 延迟300ms，执行判断是否需要搜索设备
    @objc private func checkIfNeedScanDevice() {
        if let model = WUBleModel.getModel() as? TJDWristbandSDK.WUBleModel {
            if model.mac == lastestDeviceMac {
                XLogger.shared.log("还是执行搜索并连接")
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
