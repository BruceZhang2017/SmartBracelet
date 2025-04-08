//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  DeviceSearchViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/9/19.
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
        
        XGZTBlueToothManager.shared.startScanning() // 开始扫描
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
        if objc == "connected_xgzt" { // 自研连接成功逻辑处理
            ProgressHUD.dismiss()
            navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func scanQRCode(_ sender: Any) {
        
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
        if XGZTBlueToothManager.shared.deletePeripheralInfo != nil {
            return bleSelf.bleModels.count + 1
        }
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
        let bool1 = XGZTBlueToothManager.shared.deletePeripheralInfo != nil
        
        if bool1 {
            if indexPath.row == 0 {
               cell.deviceNameLabel.text = XGZTBlueToothManager.shared.deletePeripheralInfo?.peripheral.name ?? ""
               cell.deviceMacLabel.text = XGZTBlueToothManager.shared.deletePeripheralInfo?.macAddress ?? ""
            } else {
                if indexPath.row - 1 < bleSelf.bleModels.count {
                    let model = bleSelf.bleModels[indexPath.row - 1]
                    cell.deviceNameLabel.text = model.name + ""
                    if let advertisementData = model.advertisementData,
                       advertisementData.count == 15,
                       advertisementData[1] == 0x06 { // 自研设备
                        let range = 5..<11 // Convert ClosedRange to Range by adding 1 to the upper bound
                        cell.deviceMacLabel.text = advertisementData.subdata(in: range).hexEncodedString()
                    } else {
                        if model.mac.count > 0 {
                            cell.deviceMacLabel.text = model.mac
                        } else {
                            cell.deviceMacLabel.text = "00:00:00:00:00:00"
                        }
                    }
                    
                    print("设备的名称：\(model.name) 设备的mac：\(model.mac) 广播数据: \(String(describing: model.advertisementData?.hexEncodedStringNoBlank()))")
                }
            }
        } else {
            if indexPath.row < bleSelf.bleModels.count {
                let model = bleSelf.bleModels[indexPath.row]
                cell.deviceNameLabel.text = model.name + ""
                if let advertisementData = model.advertisementData,
                   advertisementData.count == 15,
                   advertisementData[1] == 0x06 { // 自研设备
                    let range = 5..<11 // Convert ClosedRange to Range by adding 1 to the upper bound
                    cell.deviceMacLabel.text = advertisementData.subdata(in: range).hexEncodedString()
                } else {
                    if model.mac.count > 0 {
                        cell.deviceMacLabel.text = model.mac
                    } else {
                        cell.deviceMacLabel.text = "00:00:00:00:00:00"
                    }
                }
                
                print("设备的名称：\(model.name) 设备的mac：\(model.mac) 广播数据: \(String(describing: model.advertisementData?.hexEncodedStringNoBlank()))")
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
        let bool1 = XGZTBlueToothManager.shared.deletePeripheralInfo != nil
        if bool1 {
            if indexPath.row == 0 {
                guard let mac = XGZTBlueToothManager.shared.deletePeripheralInfo?.macAddress else {
                    return
                }
                XGZTBlueToothManager.shared.connect(to: mac)
            } else {
                let model = bleSelf.bleModels[indexPath.row - 1]
                if let advertisementData = model.advertisementData,
                   advertisementData.count == 15,
                   advertisementData[1] == 0x06 { // 自研设备
                    let range = 5..<11
                    let macAddress = advertisementData.subdata(in: range).hexEncodedString()
                    XGZTBlueToothManager.shared.connect(to: macAddress)
                    print("连接自研设备：\(macAddress)")
                } else {
                    bleSelf.connectBleDevice(model: model)
                }
            }
        } else {
            let model = bleSelf.bleModels[indexPath.row]
            if let advertisementData = model.advertisementData,
               advertisementData.count == 15,
               advertisementData[1] == 0x06 { // 自研设备
                let range = 5..<11
                let macAddress = advertisementData.subdata(in: range).hexEncodedString()
                XGZTBlueToothManager.shared.connect(to: macAddress)
                print("连接自研设备：\(macAddress)")
            } else {
                bleSelf.connectBleDevice(model: model)
            }
        }
    }
}

extension Notification.Name {
    static let SearchDevice = Notification.Name("SearchDevice")
}
