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
import Kingfisher
import Alamofire
import ProgressHUD

class ClockUseViewController: BaseViewController {
    @IBOutlet weak var clockImageView: UIImageView!
    @IBOutlet weak var clockNameLabel: UILabel!
    @IBOutlet weak var sizeLabel: UILabel!
    var current = 0
    var index = 0
    var rightButton: UIButton!
    var binData: Data!
    var timer: Timer?
    var clockStr: String! //
    var clockName: String = ""
    var path = ""
    var currentClock: ClockResponse?
    
    var imageUploadVc: UploadImageViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "dial_management".localized()
       
        clockName = "\(bleSelf.bleModel.name)-\(index)"
        clockImageView.kf.setImage(with: URL(string: currentClock?.previewPic ?? ""))
        clockNameLabel.text = clockName
        let url = currentClock?.resourcesUrl ?? ""
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(NSString(string: url).lastPathComponent)
        path = fileURL.absoluteString

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
    
    private func checkFile(name: String) -> Bool {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
            let url = NSURL(fileURLWithPath: path)
            if let pathComponent = url.appendingPathComponent(name) {
                let filePath = pathComponent.path
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: filePath) {
                    return true
                } else {
                    return false
                }
            } else {
                return false
            }
    }

    private func downloadFile(url: String) {
        let picname = NSString(string: url).lastPathComponent
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(picname)
        if checkFile(name: picname) {
            let fileData : Data = try! Data(contentsOf: fileURL, options: .alwaysMapped)
            rightButton.isEnabled = false
            BLEManager.shared.sendDialWithLocalBin(fileData)
            return
        }
        
        let destination: DownloadRequest.Destination = { _, _ in
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        ProgressHUD.show()
        AF.download(url, to: destination).response { [weak self] response in
            ProgressHUD.dismiss()
            if response.error == nil, let imagePath = response.fileURL?.path {
                let fileData : Data = FileManager.default.contents(atPath: imagePath)!

                self?.rightButton.isEnabled = false
                BLEManager.shared.sendDialWithLocalBin(fileData)
                
            }
            
            var clockDir = UserDefaults.standard.dictionary(forKey: "LoadingClock") ?? [:]
            var loadingStr = clockDir[bleSelf.bleModel.mac] as? String ?? ""
            let pName = self?.currentClock?.previewPic ?? ""
            if loadingStr.count > 0 {
                loadingStr.append("&&&\(self?.clockName ?? "")&&\(pName)&&\(self?.path ?? "")")
            } else {
                loadingStr.append("\(self?.clockName ?? "")&&\(pName)&&\(self?.path ?? "")")
            }
            clockDir[bleSelf.bleModel.mac] = loadingStr
            UserDefaults.standard.setValue(clockDir, forKey: "LoadingClock")
            UserDefaults.standard.synchronize()
            
        }
    }
    
    @objc private func handleOTA(_ sender: Any) {
        if !bleSelf.isConnected {
            Toast(text: "mine_unconnect".localized()).show()
            return
        }
        showDownloadAlert()
    }
    
    func showDownloadAlert() {
        // 创建UIAlertController
        let alertController = UIAlertController(title: nil, message: "agree_download_upload".localized(), preferredStyle: .alert)
        
        // 创建"确定"按钮
        let confirmAction = UIAlertAction(title: "mine_confirm".localized(), style: .default) {[weak self] (action) in
            // 在这里添加下载和上传至手表的代码
            print("确定按钮被点击")
            
            if self?.index ?? 0 > 0 {
                self?.downloadFile(url: self?.currentClock?.resourcesUrl ?? "")
                return
            }
            self?.rightButton.isEnabled = false
            if self?.binData != nil {
                BLEManager.shared.sendDialWithLocalBin(self!.binData!)
            }
            
        }
        alertController.addAction(confirmAction)
        
        // 创建"取消"按钮
        let cancelAction = UIAlertAction(title: "mine_cancel".localized(), style: .cancel) { (action) in
            print("取消按钮被点击")
        }
        alertController.addAction(cancelAction)
        
        // 显示UIAlertController
        self.present(alertController, animated: true, completion: nil)
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
        if obj == 1 {
            if p.count > 0 {
                print("代码执行到这里，上传进度：\(p) \(imageUploadVc == nil)")
                if Thread.isMainThread {
                    imageUploadVc?.refreshProgress(p: p)
                } else {
                    DispatchQueue.main.async {
                        [weak self] in
                        self?.imageUploadVc?.refreshProgress(p: p)
                    }
                }
                return
            }
            DispatchQueue.main.async {
                [weak self] in
                self?.showDialog()
            }
        } else if obj == 2 {
            DispatchQueue.main.async {
                [weak self] in
                self?.refreshDialogForResult(value: true)
            }
        } else if obj == 3 {
            DispatchQueue.main.async {
                [weak self] in
                self?.refreshDialogForResult(value: false)
            }
            
        }
    }
    
    public func showDialog() {
        if imageUploadVc != nil {
            return 
        }
        imageUploadVc = UploadImageViewController()
        imageUploadVc?.modalPresentationStyle = .overCurrentContext
        imageUploadVc?.modalTransitionStyle = .crossDissolve
        imageUploadVc?.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        imageUploadVc?.delegate = self
        if clockStr != nil {
            let array = clockStr.components(separatedBy: "&&")
            imageUploadVc?.image = UIImage(named: array[1])
        } else {
            imageUploadVc?.imgView.kf.setImage(with: URL(string: currentClock?.previewPic ?? ""))
        }
        imageUploadVc?.imgView.contentMode = .scaleAspectFit
        self.present(imageUploadVc!, animated: false) {
            
        }
    }
    
    public func refreshDialogForResult(value: Bool) {
        //Toast(text: value ? "推送成功" : "推送失败").show()
        hideDialog()
        
        if value {
            let lastestDeviceMac = UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? "00:00:00:00:00:00"
            var clockDir = UserDefaults.standard.dictionary(forKey: "MyClock") ?? [:]
            var cStr = clockDir[lastestDeviceMac] as? [String] ?? ["_&&_&&_", "_&&_&&_", "_&&_&&_"]
            var imagename: String = ""
            if clockStr != nil {
                let array = clockStr.components(separatedBy: "&&")
                imagename = array[1]
            } else {
                imagename = currentClock?.previewPic ?? ""
            }
            cStr[current] = "\(clockName)&&\(imagename)&&\(path)"
            clockDir[lastestDeviceMac] = cStr
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
