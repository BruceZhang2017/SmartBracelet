//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  DeviceListViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/9/24.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit

class DeviceListViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    
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
        let vc = storyboard.instantiateViewController(withIdentifier: "DeviceSearchViewController")
        vc.title = "device_add".localized()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func registerNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: Notification.Name("DeviceList"), object: nil)
    }
    
    private func unregisterNotification() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleNotification(_ notification: Notification) {
        tableView.reloadData()
    }
}

extension DeviceListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = DeviceManager.shared.devices.count
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: .kCellIdentifier, for: indexPath) as! DeviceTableViewCell
        cell.selectionStyle = .none
        let model = DeviceManager.shared.devices[indexPath.row]
        cell.deviceNameLabel.text = model.name + ""
        cell.deviceNameLabel.textColor = UIColor.text_primary
        cell.deviceNameLabel.font = UIFont.subtitle1()
        cell.deviceImageView.image = UIImage(named: "icon_ewatch")
        cell.bleConnectButton.titleLabel?.textColor = UIColor.text_third
        cell.bleConnectButton.titleLabel?.font = UIFont.body1()
        if model.mac == lastestDeviceMac && bleSelf.isConnected {
            cell.selectImageView.isHidden = false
            cell.bleConnectButton.setTitle("mine_bluetooth_connect".localized(), for: .normal)
        } else {
            cell.selectImageView.isHidden = true
            cell.bleConnectButton.setTitle("mine_bluetooth_unconnect".localized(), for: .normal)
        }
        let deviceInfo = DeviceManager.shared.deviceInfo[model.mac]
        if deviceInfo != nil {
            if deviceInfo?.battery ?? 0 < 5 {
                cell.batteryButton.setImage(UIImage(named: "conten_battery_runout"), for: .normal)
            } else {
                cell.batteryButton.setImage(UIImage(named: "conten_battery_full"), for: .normal)
            }
        } else {
            cell.batteryButton.setImage(UIImage(named: "conten_battery_null"), for: .normal)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 94
    }
}

extension DeviceListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = DeviceManager.shared.devices[indexPath.row]
        if model.mac == lastestDeviceMac && bleSelf.isConnected  {
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
    }
}
