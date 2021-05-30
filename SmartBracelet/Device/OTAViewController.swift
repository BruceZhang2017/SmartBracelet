//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  OTAViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2021/1/24.
//  Copyright © 2021 tjd. All rights reserved.
//
	

import UIKit
import Toaster

class OTAViewController: BaseViewController {
    private var circle: SGCirleProgress! // 进度视图

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "OTA"
        view.backgroundColor = UIColor.white
        circle = SGCirleProgress(frame: CGRect(x: 0, y: 0, width: 150, height: 150))
        view.addSubview(circle)
        circle.center = view.center

        OTA.share()?.delegate = self
        OTA.share()?.initialCMD()
        OTA.share()?.otaCMD.delegate = self
        OTA.share()?.ota()
        
        registerNotification()
    }
    
    deinit {
        unregisterNotification()
    }
    
    private func registerNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: Notification.Name("HealthVCLoading"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotificationB(_:)), name: Notification.Name("DeviceList"), object: nil)
    }
    
    private func unregisterNotification() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleNotification(_ notification: Notification) {
        let objc = notification.object as? Int ?? 0
        if objc > 0 {
            Toast(text: "蓝牙已关闭").show()
            navigationController?.popViewController(animated: true)
        }
    }
    
    @objc private func handleNotificationB(_ notification: Notification) {
        Toast(text: "设备已断开").show()
        navigationController?.popViewController(animated: true)
    }

}

extension OTAViewController: OTADelegate {
    func callback(_ progress: CGFloat) {
        circle.progress = progress
        if progress >= 100 {
            Toast(text: "OTA升级成功").show()
            navigationController?.popViewController(animated: true)
        }
    }
}

extension OTAViewController: OTACMDDelegate {
    func writeOTAData(_ data: Data!) {
        if data == nil {
            return
        }
        print("[OTA] \(data.hexEncodedStringBlank())")
        //BLECurrentManager.sharedInstall.writeOTAChar(data: data)
    }
    
    func readOTA() {
        print("[OTA] 读取OTA通道")
        //BLECurrentManager.sharedInstall.readOTAChar()
    }
    
    
}
