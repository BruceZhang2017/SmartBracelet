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
        //BLEManager.shared.startScan()
        BLECurrentManager.sharedInstall.startScan()
    }
    
    deinit {
        dotLoadingView.stop()
        BLECurrentManager.sharedInstall.stopScan()
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleNotification(_ notification: Notification) {
        let objc = notification.object as! String
        if objc == "scan" { // 搜索设备
            tableView.isHidden = BLECurrentManager.sharedInstall.models.count == 0
            tableView.reloadData()
        }
        if objc == "connected" { // 设备连接成功
            if currentModel != nil && currentModel.name != "Lefun" {
                if let model = try? BLEModel.er.fromRealm(with: "\(currentModel.mac)"), model.mac.count > 0 {
                    print("数据库已经有该设备")
                } else {
                    print("将设备添加到数据库里面")
                    try? currentModel?.er.save(update: true)
                    DeviceManager.shared.initializeDevices() // 重新刷新绑定的设备
                }
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
        return BLECurrentManager.sharedInstall.models.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: .kCellIdentifier, for: indexPath) as! DeviceSearchTableViewCell
        if indexPath.row < BLECurrentManager.sharedInstall.models.count {
            let model = BLECurrentManager.sharedInstall.models[indexPath.row]
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
        currentModel = BLECurrentManager.sharedInstall.models[indexPath.row]
        if currentModel.name == "Lefun" { //
            let model = TJDWristbandSDK.WUBleModel()
            model.isBond = true
            model.firmwareVersion = currentModel.firmwareVersion
            model.uuidString = currentModel.uuidString
            model.name = currentModel.name
            model.localName = currentModel.localName
            model.rssi = currentModel.rssi
            model.mac = currentModel.mac
            model.hardwareVersion = currentModel.hardwareVersion
            model.vendorNumberASCII = currentModel.vendorNumberASCII
            model.vendorNumberString = currentModel.vendorNumberString
            model.internalNumber = currentModel.internalNumber
            model.internalNumberString = currentModel.internalNumberString
            bleSelf.connectBleDevice(model: model)
        } else {
            BLECurrentManager.sharedInstall.connectDevice(model: currentModel)
        }
    }
}
