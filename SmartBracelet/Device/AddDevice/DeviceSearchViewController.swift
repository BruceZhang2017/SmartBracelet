//
// Copyright © 2015-2018 bruce Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  DeviceSearchViewController.swift
//  SmartBracelet
//
//  Created by bruce on 2020/9/19.
//  Copyright © 2020 tjd. All rights reserved.
//
	
import UIKit
import ProgressHUD
import Toaster
import TJDWristbandSDK

class DeviceSearchViewController: BaseViewController {
    @IBOutlet weak var helpButton: UIButton!
    @IBOutlet weak var scanCodeTipLabel: UILabel!
    @IBOutlet weak var scanLabel: UILabel!
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var btScanTipLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    private var currentModel: BLEModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.isHidden = true
        tableView.separatorStyle = .none
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: Notification.Name.SearchDevice, object: nil)
        BLEManager.shared.startScan()
        btScanTipLabel.text = "device_search".localized()
        scanLabel.text = "device_scan".localized()
        scanCodeTipLabel.text = "device_scan_add_device".localized()
        helpButton.setTitle("device_search_help".localized(), for: .normal)
        
        scanLabel.isHidden = true
        scanButton.isHidden = true
        btScanTipLabel.isHidden = true
        scanCodeTipLabel.isHidden = true
        helpButton.isHidden = true 
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    deinit {
        bleSelf.stopFindBleDevices()
        NotificationCenter.default.removeObserver(self)
    }
    
    public func refreshBackButton() {
        // 创建一个自定义的返回按钮
        let backButton = UIBarButtonItem(image: UIImage(named: "health_back_white"), style: .plain, target: self, action: #selector(backButtonTapped))
        
        // 将自定义的返回按钮设置为左侧按钮
        self.navigationItem.leftBarButtonItem = backButton
        
        // 如果你不希望保留原有的返回按钮文本，可以将其设置为空字符串
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    @objc func backButtonTapped() {
        // 在这里处理返回按钮的点击事件
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc private func handleNotification(_ notification: Notification) {
        let objc = notification.object as! String
        if objc == "scan" { // 搜索设备
            didUpdateBLEModels(models: bleSelf.bleModels)
            tableView.isHidden = bleSelf.bleModels.count == 0
            tableView.reloadData()
        }
        if objc == "connected" { // 设备连接成功
            var bTemp = false
            if currentModel != nil {
                if let model = try? BLEModel.er.fromRealm(with: "\(currentModel.mac)"), model.mac.count > 0 {
                    print("数据库已经有该设备")
                } else {
                    bTemp = true
                }
            } else {
                bTemp = true
            }
            if bTemp {
                print("将设备添加到数据库里面")
                currentModel = BLEModel()
                currentModel.isBond = bleSelf.bleModel.isBond
                currentModel.uuidString = bleSelf.bleModel.uuidString
                currentModel.name = bleSelf.bleModel.name
                currentModel.localName = "ITIME"
                currentModel.rssi = bleSelf.bleModel.rssi
                currentModel.mac = bleSelf.bleModel.mac
                currentModel.hardwareVersion = bleSelf.bleModel.hardwareVersion
                currentModel.firmwareVersion = bleSelf.bleModel.firmwareVersion
                currentModel.vendorNumberASCII = bleSelf.bleModel.vendorNumberASCII
                currentModel.vendorNumberString = bleSelf.bleModel.vendorNumberString
                currentModel.internalNumber = bleSelf.bleModel.internalNumber
                currentModel.internalNumberString = bleSelf.bleModel.internalNumberString
                currentModel.imageName = "produce_image_no.2"
                try? currentModel?.er.save(update: true)
                DeviceManager.shared.initializeDevices() // 重新刷新绑定的设备
                NotificationCenter.default.post(name: Notification.Name("DevicesViewController"), object: "1")
                NotificationCenter.default.post(name: Notification.Name("DeviceList"), object: "1")
            }
            ProgressHUD.dismiss()
            navigationController?.popViewController(animated: true)
        }
        if objc == "connectFail" {
            ProgressHUD.dismiss()
            Toast(text: "连接失败").show()
        }
    }
    
    @IBAction func scanQRCode(_ sender: Any) {
        /// 创建二维码扫描
        let vc = ScannerVC()
        vc.modalPresentationStyle = .fullScreen
        //设置标题、颜色、扫描样式（线条、网格）、提示文字
        vc.setupScanner("device_scan".localized(), .blue, .grid, "device_scan_add_device".localized()) {[weak self] (code) in
            //扫描回调方法
            print("扫描的结果是：\(code)")
            if code.count > 0 && code.contains("mac=") {
                let mac = self?.extractMacValue(from: code)
                if bleSelf.bleModels.count > 0 {
                    for model in bleSelf.bleModels {
                        let m = model.mac.replacingOccurrences(of: ":", with: "").lowercased()
                        if m == mac?.lowercased() {
                            bleSelf.connectBleDevice(model: model)
                            break
                        }
                    }
                }
            }
            //关闭扫描页面
            self?.dismiss(animated: true, completion: nil)
            
        }

        //Present到扫描页面
        present(vc, animated: true, completion: nil)
    }
    
    func extractMacValue(from string: String) -> String? {
        let pattern = "mac="
        guard let range = string.range(of: pattern, options: .backwards) else {
            // 如果没有找到 "mac="，返回 nil
            return nil
        }
        // 截取 "mac=" 之后的字符串
        let macValue = string[range.upperBound...]
        return String(macValue)
    }
    
    // 假设这是你的数据获取回调
    func didUpdateBLEModels(models: [TJDWristbandSDK.WUBleModel]) {
        // 过滤掉 mac 为空或者长度为 0 的设备
        bleSelf.bleModels = models.filter { $0.mac.count > 0 }
    }
}

extension DeviceSearchViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bleSelf.bleModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: .kCellIdentifier, for: indexPath) as! DeviceSearchTableViewCell
        cell.deviceMacLabel.textColor = UIColor.text_primary
        cell.deviceMacLabel.font = UIFont.subtitle1()
        cell.deviceMacLabel.textColor = UIColor.text_third
        cell.deviceMacLabel.font = UIFont.subtitle()
        cell.bindLabel.textColor = UIColor.brand
        cell.bindLabel.font = UIFont.body1()
        cell.bindLabel.text = "bind_device".localized()
        
        if indexPath.row < bleSelf.bleModels.count {
            let model = bleSelf.bleModels[indexPath.row]
            cell.deviceNameLabel.text = model.name + ""
            if model.mac.count > 0 {
                cell.deviceMacLabel.text = model.mac
            } else {
                cell.deviceMacLabel.text = "00:00:00:00:00:00"
            }
        }
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 94
    }
}

extension DeviceSearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        ProgressHUD.animate(nil, .activityIndicator, interaction: false)
        bleSelf.stopFindBleDevices()
        let model = bleSelf.bleModels[indexPath.row]
        bleSelf.connectBleDevice(model: model)
    }
}

extension Notification.Name {
    static let SearchDevice = Notification.Name("SearchDevice")
}
