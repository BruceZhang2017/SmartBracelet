//
// Copyright © 2015-2018 bruce Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  ClockUseViewController.swift
//  SmartBracelet
//
//  Created by bruce on 2021/2/17.
//  Copyright © 2021 tjd. All rights reserved.
//
	

import UIKit
import Toaster
import Kingfisher
import Alamofire
import ProgressHUD
import WatchProtocolSDK

class ClockUseViewController: BaseViewController {
    @IBOutlet weak var ivWidthLC: NSLayoutConstraint!
    @IBOutlet weak var ivHeightLC: NSLayoutConstraint!
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
    var packageNum = 0
    
    var imageUploadVc: UploadImageViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "dial_management".localized()
       
        if isXGZT {
            clockName = "\(XGZTBlueToothManager.shared.device?.deviceName ?? "e watch")-\(index)"
        } else {
            clockName = "\(bleSelf.bleModel.name)-\(index)"
        }
        
        clockImageView.backgroundColor = UIColor.white
        if AppDelegate.IsDeviceNotRound() { // 方形
            var w = bleSelf.bleModel.screenWidth
            var h = bleSelf.bleModel.screenHeight
            if isXGZT {
                w = XGZTBlueToothManager.shared.device?.screenWidth ?? 0
                h = XGZTBlueToothManager.shared.device?.screenHeight ?? 0
            }
            ivWidthLC.constant = 165
            ivHeightLC.constant = CGFloat(165) * CGFloat(h) / CGFloat(w)
            clockImageView.layer.cornerRadius = 36
            clockImageView.clipsToBounds = true
        } else { // 圆形
            ivWidthLC.constant = 165
            ivHeightLC.constant = 165
            clockImageView.layer.cornerRadius = 82.5
            clockImageView.clipsToBounds = true
        }
        
        let childImageView = UIImageView(frame: CGRect(x: 6, y: 6, width: ivWidthLC.constant - 12, height: ivHeightLC.constant - 12))
        childImageView.contentMode = .scaleAspectFit // 或者使用.center
        childImageView.kf.setImage(with: URL(string: currentClock?.previewPic ?? ""))
        clockImageView.addSubview(childImageView)
        
        clockNameLabel.text = clockName
        clockNameLabel.textColor = UIColor.text_primary
        clockNameLabel.font = UIFont.body1()
        
        let url = currentClock?.resourcesUrl ?? ""
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fpath = documentsURL.appendingPathComponent((url as NSString).lastPathComponent)
        path = fpath.absoluteString
        // 尝试读取数据并处理可能的错误
        binData = try? Data(contentsOf: fpath)
        
        sizeLabel.textColor = UIColor.text_third
        sizeLabel.font = UIFont.body1()
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
                $0.setTitle(index > 0 ? "device_download_add_use".localized() : "device_use".localized(), for: .normal)
                $0.addTarget(self, action: #selector(handleOTA(_:)), for: .touchUpInside)
            }
            view.addSubview(rightButton)
            rightButton.snp.makeConstraints { make in
                make.leading.equalTo(16)
                make.trailing.equalTo(-16)
                make.bottom.equalToSuperview().offset(-50)
                make.height.equalTo(44)
            }
            rightButton.backgroundColor = UIColor.brand
            rightButton.layer.cornerRadius = 22
            rightButton.clipsToBounds = true
            rightButton.setTitleColor(UIColor.white, for: .normal)
            
        }
        
        registerNotification()
    }
    
    deinit {
        unregisterNotification()
        imageUploadVc?.dismiss(animated: false, completion: {

        })
    }

    private func downloadFile(url: String) {
        let picname = NSString(string: url).lastPathComponent
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(picname)
        let destination: DownloadRequest.Destination = { _, _ in
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        ProgressHUD.animate(nil, .activityIndicator, interaction: false)
        AF.download(url, to: destination).response { [weak self] response in
            ProgressHUD.dismiss()
            if response.error == nil, let imagePath = response.fileURL?.path {
                let fileData : Data = FileManager.default.contents(atPath: imagePath)!

                self?.rightButton.isEnabled = false
                // 获取文件路径
                if isXGZT {
                    self?.binData = fileData
                    XGZTCommand.dialMarketQuery(dataType: 0) // 查询mtu 
                } else {
                    BLEManager.shared.sendDialWithLocalBin(fileData)
                }
                
            }
            
            var clockDir = UserDefaults.standard.dictionary(forKey: "LoadingClock") ?? [:]
            var loadingStr = clockDir[lastestDeviceMac] as? String ?? ""
            let pName = self?.currentClock?.previewPic ?? ""
            if loadingStr.count > 0 {
                loadingStr.append("&&&\(self?.clockName ?? "")&&\(pName)&&\(self?.path ?? "")")
            } else {
                loadingStr.append("\(self?.clockName ?? "")&&\(pName)&&\(self?.path ?? "")")
            }
            clockDir[lastestDeviceMac] = loadingStr
            UserDefaults.standard.setValue(clockDir, forKey: "LoadingClock")
            UserDefaults.standard.synchronize()
            
        }
    }
    
    @objc private func handleOTA(_ sender: Any) {
        if !bleSelf.isConnected && XGZTBlueToothManager.shared.device == nil {
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
            XLogger.shared.log("确定按钮被点击")
            
            if self?.index ?? 0 > 0 {
                self?.downloadFile(url: self?.currentClock?.resourcesUrl ?? "")
                return
            }
            self?.rightButton.isEnabled = false
            if self?.binData != nil {
                if isXGZT {
                    
                } else {
                    BLEManager.shared.sendDialWithLocalBin(self!.binData!)
                }
            }
            
        }
        alertController.addAction(confirmAction)
        
        // 创建"取消"按钮
        let cancelAction = UIAlertAction(title: "mine_cancel".localized(), style: .cancel) { (action) in
            XLogger.shared.log("取消按钮被点击")
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
        let obj = notification.object as? Int ?? 0 // 1.开始 2.成功 3.失败   自定义 4.配置，5.开始，6，成功，7.失败
        let userinfo = notification.userInfo as? [String: String]
        let p = userinfo?["p"] ?? ""
        if obj == 1 {
            if p.count > 0 {
                XLogger.shared.log("代码执行到这里，上传进度：\(p)")
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
            
        } else if obj == 4 {
            let binsize = binData.count
            let mtu = XGZTBlueToothManager.shared.device?.mtu ?? 0
            var packageTotal = 0
            guard mtu > 0 else {
                fatalError("MTU should be greater than 0")
            }

            if binsize % 200 == 0 {
                packageTotal = binsize / 200
            } else {
                packageTotal = binsize / 200 + 1
            }
            XGZTCommand.dialMarketSetTransferConfig(packageTotal: packageTotal, binSize: binsize, mtu: mtu, dialType: 0, dialNum: 1, local: 0, typeValue: 0 ,dialTypeValue: 0xffffff)
        } else if obj == 5 {
            if binData.count == 0 {
                return
            }
            packageNum += 1
            let maxDataLength = 200
            let bin = (packageNum - 1) * maxDataLength
            let progress = bin * 100 / binData.count

            // 计算子数据的范围
            let a = min(bin + maxDataLength, binData.count)
            if a <= bin {
                return
            }
            let range = bin..<a
            let subData = binData.subdata(in: range)
            var control = 0
            if bin + maxDataLength >= binData.count {
                control = 1
            }
            XGZTCommand.dialMarketTransferData(packageNum: packageNum, binNum: bin, progressBar: progress, control: control, data: subData)
            
            let d = Float(bin * 100) / Float(binData.count)
            let s = String(format: "%.02f%%", d)
            DispatchQueue.main.async {
                [weak self] in
                self?.imageUploadVc?.refreshProgress(p: s)
            }
            
            if packageNum == 1 {
                DispatchQueue.main.async {
                    [weak self] in
                    self?.showDialog()
                }
            }
        } else if obj == 6 {
            DispatchQueue.main.async {
                [weak self] in
                self?.refreshDialogForResult(value: true)
            }
        } else if obj == 7 {
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
        Toast(text: value ? "toast_success".localized() : "toast_failed".localized()).show()
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
    
    func dismissVC() {
        imageUploadVc = nil
    }
}
