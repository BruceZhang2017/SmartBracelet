//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  APNSViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/10/8.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit

class APNSViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "推送设置"
        let footImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 0.5))
        footImageView.backgroundColor = UIColor.kDEDEDE
        tableView.tableFooterView = footImageView
        tableView.separatorColor = UIColor.kDEDEDE
    }

}

extension APNSViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return titles.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: .kCellIdentifier, for: indexPath) as! DeviceSettingsTableViewCell
        cell.textLabel?.text = titles[indexPath.section][indexPath.row]
        var mSwitch: UISwitch
        if let s = cell.accessoryView as? UISwitch {
            mSwitch = s
        } else {
            mSwitch = UISwitch()
            cell.accessoryView = mSwitch
        }
        mSwitch.tag = indexPath.section * 10 + indexPath.row
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 15
    }
}

extension APNSViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
}

extension APNSViewController {
    var titles: [[String]] {
        return [["微信", "QQ", "LIKEDIN", "FACEBOOK", "TIWTTER"], ["WHATSAPP"]]
    }
}
