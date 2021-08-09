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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(handleDeviceConnected(_ :)), name: Notification.Name("MTabBarController"), object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    deinit {
        
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
