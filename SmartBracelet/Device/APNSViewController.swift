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
        title = "device_push_settings".localized()
        let footImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 0.5))
        footImageView.backgroundColor = UIColor.kDEDEDE
        tableView.tableFooterView = footImageView
        tableView.separatorColor = UIColor.kDEDEDE
    }

    @objc private func valueChanged(_ sender: Any) {
        let mSwitch = sender as? UISwitch
        let tag = mSwitch?.tag ?? 0
        if tag == 0 {
            bleSelf.notifyModel.isWechat = mSwitch?.isOn ?? false
        } else if tag == 1 {
            bleSelf.notifyModel.isQQ = mSwitch?.isOn ?? false
        } else if tag == 2 {
            bleSelf.notifyModel.isLinkedin = mSwitch?.isOn ?? false
        } else if tag == 3 {
            bleSelf.notifyModel.isFacebook = mSwitch?.isOn ?? false
        } else if tag == 4 {
            bleSelf.notifyModel.isTwitter = mSwitch?.isOn ?? false
        } else if tag == 10 {
            bleSelf.notifyModel.isWhatapp = mSwitch?.isOn ?? false
        } else if tag == 11 {
            bleSelf.notifyModel.isLine = mSwitch?.isOn ?? false
        } else if tag == 12 {
            bleSelf.notifyModel.isKakaoTalk = mSwitch?.isOn ?? false
        } else if tag == 13 {
            bleSelf.notifyModel.isFacebookMessage = mSwitch?.isOn ?? false
        } else if tag == 14 {
            bleSelf.notifyModel.isInstagram = mSwitch?.isOn ?? false
        }
        
        bleSelf.setAncsSwitchForWristband(bleSelf.notifyModel)
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
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                mSwitch.isOn = bleSelf.notifyModel.isWechat
            } else if indexPath.row == 1 {
                mSwitch.isOn = bleSelf.notifyModel.isQQ
            } else if indexPath.row == 2 {
                mSwitch.isOn = bleSelf.notifyModel.isLinkedin
            } else if indexPath.row == 3 {
                mSwitch.isOn = bleSelf.notifyModel.isFacebook
            } else {
                mSwitch.isOn = bleSelf.notifyModel.isTwitter
            }
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                mSwitch.isOn = bleSelf.notifyModel.isWhatapp
            } else if indexPath.row == 1 {
                mSwitch.isOn = bleSelf.notifyModel.isLine
            } else if indexPath.row == 2 {
                mSwitch.isOn = bleSelf.notifyModel.isKakaoTalk
            } else if indexPath.row == 3 {
                mSwitch.isOn = bleSelf.notifyModel.isFacebookMessage
            } else if indexPath.row == 4 {
                mSwitch.isOn = bleSelf.notifyModel.isInstagram
            }
        }
        mSwitch.addTarget(self, action: #selector(valueChanged(_:)), for: .valueChanged)
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
        return [["device_push_settings_wechat".localized(), "QQ", "LIKEDIN", "FACEBOOK", "TIWTTER"], ["WHATSAPP", "Line", "KakaoTalk", "Facebook Message", "Instagram"]]
    }
}
