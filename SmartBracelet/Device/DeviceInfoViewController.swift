//
// Copyright © 2015-2018 bruce Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  DeviceInfoViewController.swift
//  SmartBracelet
//
//  Created by bruce on 2020/10/8.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit

class DeviceInfoViewController: BaseViewController {
    @IBOutlet weak var deviceIconImageView: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "device_device_info".localized()
        tableView.tableHeaderView?.frame = CGRect(x: 0, y: 0, width: ScreenWidth, height: 200)
        tableView.tableFooterView = UIView()
        deviceIconImageView.backgroundColor = UIColor.brand.withAlphaComponent(0.4)
        let childImageView = UIImageView(frame: CGRect(x: 31, y: 31, width: 88, height: 88)) // 150-88=62，62/2=31
        childImageView.contentMode = .scaleAspectFit // 或者使用.center
        childImageView.image = UIImage(named: AppDelegate.IsDeviceNotRound() ? "icon_ewatch" : "icon_ewatch_2")
        deviceIconImageView.addSubview(childImageView)
    }

}

extension DeviceInfoViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: .kCellIdentifier, for: indexPath) as! DeviceInfoTableViewCell
        cell.selectionStyle = .none
        cell.textLabel?.textColor = UIColor.text_primary
        cell.textLabel?.font = UIFont.body1()
        cell.detailTextLabel?.textColor = UIColor.text_third
        cell.detailTextLabel?.font = UIFont.body1()
        cell.textLabel?.text = titles[indexPath.row]
        if indexPath.row == 0 {
            cell.detailTextLabel?.text = bleSelf.bleModel.name
        } else if indexPath.row == 1 {
            cell.detailTextLabel?.text = bleSelf.bleModel.mac
        } else if indexPath.row == 2 {
            cell.detailTextLabel?.text = "V" + bleSelf.bleModel.firmwareVersion
        } else {
            cell.detailTextLabel?.text = "V" + bleSelf.bleModel.hardwareVersion
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 52
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
