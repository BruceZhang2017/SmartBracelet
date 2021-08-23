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
    var popup: PopupBViewController?
    var index = 0
    var rightButton: UIButton!
    var binData: Data!
    var timer: Timer?
    var clockStr: String!
    var clockName: String = ""
    var imagename: String = ""
    var path = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "表盘管理"
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
        sizeLabel.text = "文件大小：" + (binData?.count ?? 0).sizeToStr()
        
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
                $0.setTitle(index > 0 ? "下载并使用" : "使用", for: .normal)
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
            Toast(text: "未连接设备").show()
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
        DispatchQueue.main.async {
            [weak self] in
            if obj == 1 {
                self?.showDialog()
            } else if obj == 2 {
                self?.refreshDialogForResult(value: true)
            } else if obj == 3 {
                self?.refreshDialogForResult(value: false)
            }
        }
    }
    
    public func showDialog() {
        popup = PopupBViewController()
        popup?.modalTransitionStyle = .crossDissolve
        popup?.modalPresentationStyle = .overCurrentContext
        tabBarController?.present(popup!, animated: false, completion: nil)
        popup?.iconImageView.layer.borderColor = UIColor.color(hex: "64F2B4").cgColor
        popup?.iconImageView.layer.borderWidth = 2
        popup?.iconImageView.layer.cornerRadius = 24
        let attStr = NSMutableAttributedString()
        attStr.append(NSAttributedString(string: "正在同步至手环，请稍后...", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 13)]))
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        attStr.addAttributes([.paragraphStyle: style], range: NSMakeRange(0, attStr.length))
        popup?.contentLabel?.attributedText = attStr
        popup?.callback = {
            
        }
        popup?.iconImageView.snp.updateConstraints {
            $0.width.height.equalTo(48)
        }
        let iv = UIImageView(frame: CGRect(x: 17, y: 17, width: 14, height: 14)).then {
            $0.image = UIImage(named: "conten_icon_refresh")
            $0.tag = 888
        }
        popup?.iconImageView.addSubview(iv)
        
        rotate360Degree(iv: iv)
    }
    
    public func refreshDialogForResult(value: Bool) {
        let iv = popup?.iconImageView.viewWithTag(888) as? UIImageView
        stopRotate()
        if value {
            iv?.image = UIImage(named: "content_icon_success")
            let attStr = NSMutableAttributedString()
            attStr.append(NSAttributedString(string: "推送成功", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 13)]))
            let style = NSMutableParagraphStyle()
            style.alignment = .center
            attStr.addAttributes([.paragraphStyle: style], range: NSMakeRange(0, attStr.length))
            popup?.contentLabel?.attributedText = attStr
        } else {
            iv?.image = UIImage(named: "content_icon_fail")
            let attStr = NSMutableAttributedString()
            attStr.append(NSAttributedString(string: "推送失败", attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 13)]))
            let style = NSMutableParagraphStyle()
            style.alignment = .center
            attStr.addAttributes([.paragraphStyle: style], range: NSMakeRange(0, attStr.length))
            popup?.contentLabel?.attributedText = attStr
        }
        hideDialog()
        
        var clockDir = UserDefaults.standard.dictionary(forKey: "MyClock") ?? [:]
        var clockStr = clockDir[bleSelf.bleModel.mac] as? String ?? ""
        if clockStr.count > 0 {
            clockStr.append("&&&\(clockName)&&\(imagename)&&\(path)")
        } else {
            clockStr.append("\(clockName)&&\(imagename)&&\(path)")
        }
        clockDir[bleSelf.bleModel.mac] = clockStr
        UserDefaults.standard.setValue(clockDir, forKey: "MyClock")
        UserDefaults.standard.synchronize()
        
        perform(#selector(back), with: nil, afterDelay: 2)
    }
    
    private func hideDialog() {
        popup?.dismiss(animated: false, completion: nil)
    }
    
    @objc private func back() {
        navigationController?.popViewController(animated: true)
    }
    
    // 360度旋转图片
    func rotate360Degree(iv: UIImageView) {
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { (_) in
            UIView.animate(withDuration: 1) {
                iv.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2).inverted().concatenating(iv.transform)
            }
        }
    }
    
    // 停止旋转
    func stopRotate() {
        timer?.invalidate()
        timer = nil
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
