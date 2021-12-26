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
    @IBOutlet weak var loadingView: UIView!
    var dotLoadingView: DotsLoadingView!
    @IBOutlet weak var tableView: UITableView!
    private var currentModel: BLEModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dotLoadingView = DotsLoadingView(colors: nil)
        loadingView.addSubview(dotLoadingView)
        dotLoadingView.show()
        tableView.isHidden = true
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: Notification.Name.SearchDevice, object: nil)
        BLEManager.shared.startScan()
        btScanTipLabel.text = "device_search".localized()
        scanLabel.text = "device_scan".localized()
        scanCodeTipLabel.text = "device_scan_add_device".localized()
        helpButton.setTitle("device_search_help".localized(), for: .normal)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
    }
    
    deinit {
        dotLoadingView.stop()
        bleSelf.stopFindBleDevices()
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleNotification(_ notification: Notification) {
        let objc = notification.object as! String
        if objc == "scan" { // 搜索设备
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
}

extension DeviceSearchViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bleSelf.bleModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: .kCellIdentifier, for: indexPath) as! DeviceSearchTableViewCell
        if indexPath.row < bleSelf.bleModels.count {
            let model = bleSelf.bleModels[indexPath.row]
            cell.deviceNameLabel.text = model.name + ""
            cell.deviceMacLabel.text = model.mac
        }
        return cell
    }
}

extension DeviceSearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        ProgressHUD.show()
        bleSelf.stopFindBleDevices()
        let model = bleSelf.bleModels[indexPath.row]
        bleSelf.connectBleDevice(model: model)
    }
}

extension Notification.Name {
    static let SearchDevice = Notification.Name("SearchDevice")
}
