//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  DeviceSettingsViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/9/6.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit
import TJDWristbandSDK
import Toaster

class DeviceSettingsViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headerView: UIView!
    var footerView: UIView!
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var btButton: UIButton!
    @IBOutlet weak var batteryButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "设备设置"
        tableView.backgroundColor = UIColor.kF5F5F5
        footerView = UIView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 104))
        footerView.backgroundColor = UIColor.clear
        let deleteButton = UIButton(type: .custom)
        deleteButton.frame = CGRect(x: 15, y: 30, width: ScreenWidth - 30, height: 44)
        deleteButton.backgroundColor = UIColor.kEEEEEE
        deleteButton.setTitleColor(UIColor.kFF3276, for: .normal)
        deleteButton.setTitle("解除绑定", for: .normal)
        deleteButton.addTarget(self, action: #selector(deleteDevice(_:)), for: .touchUpInside)
        footerView.addSubview(deleteButton)
        tableView.tableFooterView = footerView
        
        btButton.titleLabel?.setContentCompressionResistancePriority(.required, for: .horizontal)
        batteryButton.titleLabel?.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        deviceNameLabel.text = bleSelf.bleModel.name
        batteryButton.setTitle("剩余电量\(bleSelf.batteryLevel)%", for: .normal)
        bleSelf.getAncsSwitchForWristband() // 苹果推送消息
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    @objc private func deleteDevice(_ sender: Any) {
        let alert = UIAlertController(title: "提示", message: "您确定解除绑定该设备？如果确定，并请至手机“设置 -> 蓝牙”中删除该设备配对记录。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: { (action) in
            
        }))
        alert.addAction(UIAlertAction(title: "确定", style: .default, handler: { [weak self] (action) in
            NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "delete")
            BLEManager.shared.unbind()
            UserDefaults.standard.removeObject(forKey: "LastestDeviceMac")
            self?.navigationController?.popViewController(animated: false)
            let url = URL(string: "App-Prefs:root=Bluetooth")
            if UIApplication.shared.canOpenURL(url!) {
                UIApplication.shared.open(url!, options: [:], completionHandler: nil)
            }
            
        }))
        present(alert, animated: true) {
            
        }
    }
    
    @objc private func valueChanged(_ sender: Any) {
        let mSwitch = sender as? UISwitch
        let tag = mSwitch?.tag ?? 0
        if tag == 1001 { // 长坐提醒
            bleSelf.functionSwitchModel.isLongSit = mSwitch?.isOn ?? false 
            bleSelf.setSwitchForWristband(bleSelf.functionSwitchModel)
        } else if tag == 1000 { // 抬手亮屏
            bleSelf.functionSwitchModel.isLightScreen = mSwitch?.isOn ?? false
            bleSelf.setSwitchForWristband(bleSelf.functionSwitchModel)
        }
    }

}

extension DeviceSettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return titles.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: .kCellIdentifier, for: indexPath) as! DeviceSettingsTableViewCell
        cell.textLabel?.text = titles[indexPath.section][indexPath.row]
        if indexPath.section == 0 && indexPath.row >= 1 && indexPath.row <= 2 {
            let mSwitch = UISwitch()
            mSwitch.tag = 999 + indexPath.row
            mSwitch.addTarget(self, action: #selector(valueChanged(_:)), for: .valueChanged)
            cell.accessoryView = mSwitch
            if indexPath.row == 2 {
                mSwitch.isOn = bleSelf.functionSwitchModel.isLongSit
            } else if indexPath.row == 1 {
                mSwitch.isOn = bleSelf.functionSwitchModel.isLightScreen
            }
        } else {
            let imageView = UIImageView(image: UIImage(named: "content_next"))
            cell.accessoryView = imageView
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 15
    }
    
    
}

extension DeviceSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            if indexPath.row == 0 { // 推送设置
                let storyboard = UIStoryboard(name: .kDevice, bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "APNSViewController")
                navigationController?.pushViewController(vc, animated: true)
            } else if indexPath.row == 3 {
                let vc = WeatherViewController()
                navigationController?.pushViewController(vc, animated: true)
            }
        } else {
            if indexPath.row == 2 { // 设置信息
                let storyboard = UIStoryboard(name: .kDevice, bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "DeviceInfoViewController")
                navigationController?.pushViewController(vc, animated: true)
            } else if indexPath.row == 1 { // 查找设备
                let storyboard = UIStoryboard(name: .kDevice, bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "DeviceFoundViewController")
                navigationController?.pushViewController(vc, animated: true)
            } else { // 闹钟设置
                let storyboard = UIStoryboard(name: .kDevice, bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "AlarmViewController") as! AlarmViewController
                navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
}

extension DeviceSettingsViewController {
    var titles: [[String]] {
        return [["推送设置", "抬手亮屏", "久坐提醒", "天气推送"], ["闹钟设置", "查找设置", "设置信息"]]
    }
}


