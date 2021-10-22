//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  DeviceInfoViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/10/8.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit

class DeviceInfoViewController: BaseViewController {
    @IBOutlet weak var deviceIconImageView: UIImageView!
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "device_device_info".localized()
        tableView.tableHeaderView?.frame = CGRect(x: 0, y: 0, width: ScreenWidth, height: 150)
        tableView.tableFooterView = UIView()
    }

}

extension DeviceInfoViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: .kCellIdentifier, for: indexPath) as! DeviceInfoTableViewCell
        cell.titleLabel.text = titles[indexPath.row]
        if indexPath.row == 0 {
            cell.valueLabel.text = bleSelf.bleModel.name
        } else if indexPath.row == 1 {
            cell.valueLabel.text = bleSelf.bleModel.mac
        } else if indexPath.row == 2 {
            cell.valueLabel.text = "V" + bleSelf.bleModel.firmwareVersion
        } else {
            cell.valueLabel.text = "V" + bleSelf.bleModel.hardwareVersion
        }
        return cell
    }
}

extension DeviceInfoViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension DeviceInfoViewController {
    var titles: [String] {
        return ["deivce_model".localized(), "deivce_mac".localized(), "deivce_soft_version".localized(), "deivce_hardware_version".localized()]
    }
}
