//
// Copyright © 2015-2018 bruce Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  DeviceListViewController.swift
//  SmartBracelet
//
//  Created by bruce on 2020/9/24.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit
import Toaster
import AVFoundation
import WatchProtocolSDK

class DeviceListViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    var style = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addFootView()
        registerNotification()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    deinit {
        unregisterNotification()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }

    private func addFootView() {
        let footView = UIView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 80))
        let button = UIButton(type: .custom).then {
            $0.setTitle("add_new_device".localized(), for: .normal)
            $0.setTitleColor(UIColor.brand, for: .normal)
            $0.setImage(UIImage(named: "icon_add2"), for: .normal)
            $0.titleLabel?.font = UIFont.subtitle()
            $0.addTarget(self, action: #selector(pushToSearchDevice(_:)), for: .touchUpInside)
            $0.titleEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: -5)
        }
        footView.addSubview(button)
        button.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        tableView.tableFooterView = footView
    }
    
    @objc private func pushToSearchDevice(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Device", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "DeviceSearchViewController") as? DeviceSearchViewController
        vc?.title = "device_add".localized()
        if style > 0 {
            vc?.refreshBackButton()
        }
        vc?.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc!, animated: true)
    }
    
    private func registerNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: Notification.Name("DeviceList"), object: nil)
    }
    
    private func unregisterNotification() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleNotification(_ notification: Notification) {
        let obj = notification.object as? String ?? ""
        if obj == "2" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                [weak self] in
                let count = DeviceManager.shared.devices.count + (cacheDevices.count)
                if count <= 1 {
                    self?.navigationController?.popViewController(animated: false)
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self?.tableView.reloadData() // 刷新列表
                    }
                }
            }
            return
        }
        if obj == "3" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                [weak self] in
                let count = DeviceManager.shared.devices.count + (cacheDevices.count)
                if count <= 1 {
                    self?.navigationController?.popViewController(animated: false)
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self?.tableView.reloadData() // 刷新列表
                    }
                }
            }
            return
        }
        tableView.reloadData()
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
    
    func callbackTap(model: BLEModel?, bConnected: Bool) {
        let count = DeviceManager.shared.devices.count
        if count == 0 {
            // 没有设备可以删除
            return
        }
        deleteDevice(model: model)
        // 当设备已经连接后，并且连接成功后，则跳转至设备设置页面。删除该部分逻辑
    }
    
    private func deleteDevice(model: BLEModel?) {
        let alert = UIAlertController(title: "device_tip".localized(), message: "unbind_device_desc".localized(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "mine_cancel".localized(), style: .cancel, handler: { (action) in
            
        }))
        alert.addAction(UIAlertAction(title: "mine_confirm".localized(), style: .default, handler: { [weak self] (action) in
            let count = DeviceManager.shared.devices.count
            if count <= 1 {
                NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "delete", userInfo: ["mac": DeviceManager.shared.devices[0].mac])
                NotificationCenter.default.post(name: Notification.Name("DevicesViewController"), object: nil)
                BLEManager.shared.unbind()
                UserDefaults.standard.removeObject(forKey: "LastestDeviceMac")
                self?.navigationController?.popViewController(animated: false)
            } else {
                guard let mac = model?.mac else {
                    return
                }
                NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "delete", userInfo: ["mac": mac])
                let lastestDeviceMac = UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? ""
                if lastestDeviceMac == mac {
                    BLEManager.shared.unbind()
                    UserDefaults.standard.removeObject(forKey: "LastestDeviceMac")
                    NotificationCenter.default.post(name: Notification.Name("DevicesViewController"), object: nil)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self?.tableView.reloadData() // 刷新列表
                    }
                }
            }
        }))
        present(alert, animated: true) {
            
        }
    }
    
    private func deleteDevice(mac: String) {
        if localMac.count > 0 {
            return 
        }
        let alert = UIAlertController(title: "device_tip".localized(), message: "unbind_device_desc".localized(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "mine_cancel".localized(), style: .cancel, handler: { (action) in
            
        }))
        alert.addAction(UIAlertAction(title: "mine_confirm".localized(), style: .default, handler: { (action) in
            localMac = mac
            if XGZTBlueToothManager.shared.device != nil && mac == lastestDeviceMac {
                if XGZTBlueToothManager.shared.isReconnectingNow {
                    NotificationCenter.default.post(name: Notification.Name("DevicesViewController"), object: "2000")
                    return
                }
                XGZTBlueToothManager.shared.switchAutoDisconnect = true
                XGZTCommand.bindDevice(value: 2) // 解除绑定
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    XGZTBlueToothManager.shared.cancelAllConnections()
                }
            } else {
                NotificationCenter.default.post(name: Notification.Name("DevicesViewController"), object: "2000")
            }
        }))
        present(alert, animated: true) {
            
        }
    }
    
    func disconnectBluetoothAudio() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(false) // 停用当前会话
            try audioSession.setCategory(.playback)
            try audioSession.setActive(true)  // 重新激活
        } catch {
            XLogger.shared.log("会话重置失败: \(error)")
        }
    }
}

extension DeviceListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = DeviceManager.shared.devices.count
        count += cacheDevices.count
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: .kCellIdentifier, for: indexPath) as! DeviceTableViewCell
        cell.delegate = self
        cell.selectionStyle = .none
        let count = DeviceManager.shared.devices.count
        if indexPath.row < count {
            let model = DeviceManager.shared.devices[indexPath.row]
            cell.deviceNameLabel.text = model.name + "-" + model.mac
            cell.deviceNameLabel.textColor = UIColor.text_primary
            cell.deviceNameLabel.font = UIFont.subtitle1()
            cell.deleteButton.titleLabel?.textColor = UIColor.brand
            cell.deleteButton.setTitle("deivce_unbind".localized(), for: .normal)
            cell.deviceImageView.image = UIImage(named: AppDelegate.IsDeviceNotRound() ? "icon_ewatch" : "icon_ewatch_2")
            if model.mac == lastestDeviceMac && bleSelf.isConnected {
                cell.selectImageView.isHidden = false
                cell.bleConnectButton.setTitle("mine_bluetooth_connect".localized(), for: .normal)
            } else {
                cell.selectImageView.isHidden = true
                cell.bleConnectButton.setTitle("mine_bluetooth_unconnect".localized(), for: .normal)
            }
            cell.tag = 10 + indexPath.row
            XLogger.shared.log("旧设备：\(model.mac)")
        } else {
            let model = cacheDevices[indexPath.row - count]
            cell.deviceNameLabel.text = (model.deviceName ?? "")  + "-" + (model.max ?? "")
            cell.deviceNameLabel.textColor = UIColor.text_primary
            cell.deviceNameLabel.font = UIFont.subtitle1()
            cell.deleteButton.titleLabel?.textColor = UIColor.brand
            cell.deleteButton.setTitle("deivce_unbind".localized(), for: .normal)
            cell.deviceImageView.image = UIImage(named: AppDelegate.IsDeviceNotRound() ? "icon_ewatch" : "icon_ewatch_2")
            if model.max ?? "" == lastestDeviceMac && XGZTBlueToothManager.shared.device != nil && isXGZT {
                if XGZTBlueToothManager.shared.isReconnectingNow {
                    cell.selectImageView.isHidden = true
                    cell.bleConnectButton.setTitle("mine_bluetooth_unconnect".localized(), for: .normal)
                } else {
                    cell.selectImageView.isHidden = false
                    cell.bleConnectButton.setTitle("mine_bluetooth_connect".localized(), for: .normal)
                }
                
            } else {
                cell.selectImageView.isHidden = true
                cell.bleConnectButton.setTitle("mine_bluetooth_unconnect".localized(), for: .normal)
            }
            XLogger.shared.log("【\(indexPath.row - count)】设备名称：\(model.deviceName ?? "") 设备地址：\(model.max ?? "")")
            cell.tag = 100 + indexPath.row
        }
        

        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 114
    }
}

extension DeviceListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let count = DeviceManager.shared.devices.count
        if indexPath.row < count {
            let model = DeviceManager.shared.devices[indexPath.row]
            if model.mac == lastestDeviceMac && (bleSelf.isConnected || XGZTBlueToothManager.shared.device != nil)  {
                return
            }
            bleSelf.disconnectBleDevice()
            bleSelf.bleModel.isBond = model.isBond
            bleSelf.bleModel.uuidString = model.uuidString
            bleSelf.bleModel.name = model.name
            bleSelf.bleModel.rssi = model.rssi
            bleSelf.bleModel.mac = model.mac
            bleSelf.bleModel.hardwareVersion = model.hardwareVersion
            bleSelf.bleModel.firmwareVersion = model.firmwareVersion
            bleSelf.bleModel.vendorNumberASCII = model.vendorNumberASCII
            bleSelf.bleModel.vendorNumberString = model.vendorNumberString
            bleSelf.bleModel.internalNumber = model.internalNumber
            bleSelf.bleModel.internalNumberString = model.internalNumberString
            if bleSelf.bleModel.internalNumberString.hasPrefix("P1") || bleSelf.bleModel.internalNumberString.hasPrefix("S1") {
                bleSelf.bleModel.screenWidth = 80
                bleSelf.bleModel.screenHeight = 160
            }
            bleSelf.connectBleDevice(model: bleSelf.bleModel)
        } else {
            let model = cacheDevices[indexPath.row - count]
            if model.max ?? "" == lastestDeviceMac && XGZTBlueToothManager.shared.device != nil  {
                return
            }
            bleSelf.disconnectBleDevice()
            
            if XGZTBlueToothManager.shared.device != nil && isXGZT {
                if XGZTBlueToothManager.shared.isReconnectingNow {
                    XGZTBlueToothManager.shared.isReconnectingNow = false
                    XGZTBlueToothManager.shared.disconnectDevice()
                    XGZTBlueToothManager.shared.connectFunc(to: model.max ?? "")
                    return
                }
                XGZTBlueToothManager.shared.switchAutoDisconnect = true
                XGZTCommand.bindDevice(value: 2) // 解除绑定
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    XGZTBlueToothManager.shared.cancelAllConnections()
                    XGZTBlueToothManager.shared.connectFunc(to: model.max ?? "")
                }
            } else {
                XGZTBlueToothManager.shared.connectFunc(to: model.max ?? "")
            }
            navigationController?.popViewController(animated: true)
        }
    }
}

extension DeviceListViewController: DeviceTableViewCellDelegate {
    func buttonTapped(cell: DeviceTableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            XLogger.shared.log("Button tapped on row \(indexPath.row)")
            // 在这里处理按钮点击事件
            if cell.tag >= 100 {
                let count = DeviceManager.shared.devices.count
                let model = cacheDevices[indexPath.row - count]
                guard let mac = model.max else {
                    return
                }
                deleteDevice(mac: mac)
            } else {
                let model = DeviceManager.shared.devices[indexPath.row]
                callbackTap(model: model, bConnected: true)
            }
        }
    }
}
