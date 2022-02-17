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
    var binData: Data!
    var timer: Timer?
    var clockStr: String!
    var clockName: String = ""
    var imagename: String = ""
    var path = ""
    
    var imageUploadVc: UploadImageViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "dial_management".localized()
        if index > 0 {
            var type = BLEDeviceNameHandler().handleName()
            if type == 0 {
                type = bleSelf.bleModel.screenType
            }
            let w = bleSelf.bleModel.screenWidth
            let h = bleSelf.bleModel.screenHeight
            imagename = "\(index)\(type == 1 ? "" : "_c")_\(w)_\(h)"
            clockName = "\(bleSelf.bleModel.name)-\(index)"
            clockImageView.image = UIImage(named: imagename)
            clockNameLabel.text = clockName
            path = Bundle.main.path(forResource: imagename, ofType: "bin")!
        } else {
            let array = clockStr.components(separatedBy: "&&")
            imagename = array[1]
            clockImageView.image = UIImage(named: imagename)
            clockNameLabel.text = array[0]
            path = Bundle.main.path(forResource: imagename, ofType: "bin")!
        }
        binData = try? Data(contentsOf: URL(fileURLWithPath: path))
        sizeLabel.text = "device_ota_file_size".localized() + (binData?.count ?? 0).sizeToStr()
        
        var bHave = false
        if index > 0 {
            let manager = FileManager.default
            if manager.isExecutableFile(atPath: path) {
                bHave = true
            }
        }
        if !bHave {
            rightButton = UIButton(type: .custom).then {
                $0.initializeRightNavigationItem()
                $0.setTitle(index > 0 ? "device_download_add_use".localized() : "device_use".localized(), for: .normal)
                $0.addTarget(self, action: #selector(handleOTA(_:)), for: .touchUpInside)
            }
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightButton)
        }
        
        registerNotification()
    }
    
    deinit {
        unregisterNotification()
    }

    @objc private func handleOTA(_ sender: Any) {
        if !bleSelf.isConnected {
            Toast(text: "mine_unconnect".localized()).show()
            return
        }
        if index > 0 {
            Toast(text: "下载成功").show()
            var clockDir = UserDefaults.standard.dictionary(forKey: "LoadingClock") ?? [:]
            var loadingStr = clockDir[bleSelf.bleModel.mac] as? String ?? ""
            if loadingStr.count > 0 {
                loadingStr.append("&&&\(clockName)&&\(imagename)&&\(path)")
            } else {
                loadingStr.append("\(clockName)&&\(imagename)&&\(path)")
            }
            clockDir[bleSelf.bleModel.mac] = loadingStr
            UserDefaults.standard.setValue(clockDir, forKey: "LoadingClock")
            UserDefaults.standard.synchronize()
        }
        rightButton.isEnabled = false
        if binData != nil {
            BLEManager.shared.sendDialWithLocalBin(binData!)
        }
    }
    
    private func registerNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: Notification.Name("ClockUseViewController"), object: nil)
    }
    
    private func unregisterNotification() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleNotification(_ notification: Notification) {
        let obj = notification.object as? Int ?? 0 // 1.开始 2.成功 3.失败
        let userinfo = notification.userInfo as? [String: String]
        let p = userinfo?["p"] ?? ""
        DispatchQueue.main.async {
            [weak self] in
            if obj == 1 {
                if p.count > 0 {
                    self?.imageUploadVc?.uploadButton.setTitle(p, for: .normal)
                    return
                }
                self?.showDialog()
            } else if obj == 2 {
                self?.refreshDialogForResult(value: true)
            } else if obj == 3 {
                self?.refreshDialogForResult(value: false)
            }
        }
    }
    
    public func showDialog() {
        imageUploadVc = UploadImageViewController()
        imageUploadVc?.modalPresentationStyle = .overCurrentContext
        imageUploadVc?.modalTransitionStyle = .crossDissolve
        imageUploadVc?.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        imageUploadVc?.delegate = self
        imageUploadVc?.image = UIImage(named: imagename)
        imageUploadVc?.imgView.contentMode = .scaleAspectFit
        self.present(imageUploadVc!, animated: false) {
            
        }
    }
    
    public func refreshDialogForResult(value: Bool) {
        Toast(text: value ? "推送成功" : "推送失败").show()
        hideDialog()
        
        if value {
            var clockDir = UserDefaults.standard.dictionary(forKey: "MyClock") ?? [:]
            var clockStr = clockDir["00:00:00:00:00:00"] as? String ?? ""
            if clockStr.count > 0 {
                clockStr.append("&&&\(clockName)&&\(imagename)&&\(path)")
            } else {
                clockStr.append("\(clockName)&&\(imagename)&&\(path)")
            }
            clockDir["00:00:00:00:00:00"] = clockStr
            UserDefaults.standard.setValue(clockDir, forKey: "MyClock")
            UserDefaults.standard.synchronize()
        }
        
        perform(#selector(back), with: nil, afterDelay: 2)
    }
    
    private func hideDialog() {
        imageUploadVc?.dismiss(animated: false, completion: nil)
    }
    
    @objc private func back() {
        navigationController?.popViewController(animated: true)
    }
}

extension Int {
    func sizeToStr() -> String {
        if self < 1024 {
            return "\(self)B"
        } else if self < 1024 * 1024 {
            return "\(self / 1024)KB"
        } else {
            return "\(self / 1024 / 1024)MB"
        }
    }
}

extension ClockUseViewController: UploadImageDelegate {
    func startUpload(image: UIImage) {
        
    }
}
