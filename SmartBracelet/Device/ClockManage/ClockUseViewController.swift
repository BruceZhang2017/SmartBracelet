//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  ClockUseViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2021/2/17.
//  Copyright © 2021 tjd. All rights reserved.
//
	

import UIKit
import Toaster

class ClockUseViewController: BaseViewController {
    @IBOutlet weak var clockImageView: UIImageView!
    @IBOutlet weak var clockNameLabel: UILabel!
    @IBOutlet weak var sizeLabel: UILabel!
    var index = 0
    var rightButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "表盘管理"
        let bundle = Bundle(path: Bundle.main.path(forResource: "IdleResources", ofType: "bundle")!)
        clockImageView.image = UIImage(contentsOfFile: bundle!.path(forResource: "Static", ofType: nil, inDirectory: "80x160")! + "/\(index).png")
        clockNameLabel.text = "PFm5-\(index)"
        let path = bundle!.path(forResource: "Static", ofType: nil, inDirectory: "80x160")! + "/\(index).bin"
        let data = try? Data(contentsOf: URL(fileURLWithPath: path))
        sizeLabel.text = "文件大小：" + (data?.count ?? 0).sizeToStr()
        
        rightButton = UIButton(type: .custom).then {
            $0.initializeRightNavigationItem()
            $0.setTitle("使用", for: .normal)
            $0.addTarget(self, action: #selector(handleOTA(_:)), for: .touchUpInside)
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightButton)
    }

    @objc private func handleOTA(_ sender: Any) {
        if !BLECurrentManager.sharedInstall.isHavenConnectedDevice() || !bleSelf.isConnected {
            Toast(text: "未连接设备，请先连接设备").show()
            return
        }
        rightButton.isEnabled = false
        if BLECurrentManager.sharedInstall.deviceType == 2 { // 当前为Lefun系列产品
            BLEManager.shared.sendDial()
        }
    }
}

extension Int {
    func sizeToStr() -> String {
        if self < 1024 {
            return "\(self)B"
        } else if self < 1024 * 1024 {
            return "\(self / 1024)K"
        } else {
            return "\(self / 1024 / 1024)M"
        }
    }
}
