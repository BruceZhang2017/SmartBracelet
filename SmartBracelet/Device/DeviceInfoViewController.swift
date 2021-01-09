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
        title = "设备信息"
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
        cell.valueLabel.text = ""
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
        return ["设备型号", "MAC地址", "软件版本", "设备序列号"]
    }
}
