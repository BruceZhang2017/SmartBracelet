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
    //var footerView: UIView!
    var cameraViewController: CameraViewController?
    private var currentTime: TimeInterval = 0 // 当前时间戳
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bleSelf.getLongSitForWristband()
       // title = "设备设置"
        tableView.backgroundColor = UIColor.kF5F5F5
//        footerView = UIView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 104))
//        footerView.backgroundColor = UIColor.clear
//        let deleteButton = UIButton(type: .custom)
//        deleteButton.frame = CGRect(x: 15, y: 30, width: ScreenWidth - 30, height: 44)
//        deleteButton.backgroundColor = UIColor.kEEEEEE
//        deleteButton.setTitleColor(UIColor.kFF3276, for: .normal)
//        deleteButton.setTitle("deivce_unbind".localized(), for: .normal)
//        deleteButton.addTarget(self, action: #selector(deleteDevice(_:)), for: .touchUpInside)
//        footerView.addSubview(deleteButton)
//        tableView.tableFooterView = footerView
        
        bleSelf.getAncsSwitchForWristband() // 苹果推送消息
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: Notification.Name("DeviceSettings"), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleNotification(_ notification: Notification) {
        let current = Date().timeIntervalSince1970
        if currentTime > 0 {
            if abs(current - currentTime) < 4 {
                return
            }
        }
        currentTime = current
        if #available(iOS 3.1, *) {
            DispatchQueue.main.async {
                [weak self] in
                self?.cameraViewController?.capturePhoto()
            }
        }
        
    }
    
    @objc private func deleteDevice(_ sender: Any) {
        let alert = UIAlertController(title: "device_tip".localized(), message: "unbind_device_desc".localized(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "mine_cancel".localized(), style: .cancel, handler: { (action) in
            
        }))
        alert.addAction(UIAlertAction(title: "mine_confirm".localized(), style: .default, handler: { [weak self] (action) in
            NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "delete")
            BLEManager.shared.unbind()
            UserDefaults.standard.removeObject(forKey: "LastestDeviceMac")
            NotificationCenter.default.post(name: Notification.Name("DevicesViewController"), object: nil)
            self?.navigationController?.popViewController(animated: true)
        }))
        present(alert, animated: true) {
            
        }
    }
    
    @objc private func valueChanged(_ sender: Any) {
        let mSwitch = sender as? UISwitch
        let tag = mSwitch?.tag ?? 0
        if tag == 1002 { // 长坐提醒
            bleSelf.functionSwitchModel.isLongSit = mSwitch?.isOn ?? false 
            bleSelf.setSwitchForWristband(bleSelf.functionSwitchModel)
        } else if tag == 1001 { // 抬手亮屏
            bleSelf.functionSwitchModel.isLightScreen = mSwitch?.isOn ?? false
            bleSelf.setSwitchForWristband(bleSelf.functionSwitchModel)
        } else if tag == 1000 { // 来电提醒
            bleSelf.functionSwitchModel.isCallDown = mSwitch?.isOn ?? false
            bleSelf.setSwitchForWristband(bleSelf.functionSwitchModel)
        }
    }
    
    private func takePhoto() {
        var croppingParameters: CroppingParameters {
            return CroppingParameters(isEnabled: false, allowResizing: false, allowMoving: false, minimumSize: CGSize(width: 60, height: 60))
        }
        cameraViewController = CameraViewController(croppingParameters: croppingParameters, allowsLibraryAccess: true) { [weak self] image, asset in
            self?.dismiss(animated: true, completion: nil)
            self?.cameraViewController = nil
            bleSelf.setCameraForWristband(false)
            bleSelf.responseCameraForWristband()
        }
        cameraViewController?.modalPresentationStyle = .fullScreen
        parent?.present(cameraViewController!, animated: true, completion: nil)
    }
    
    @objc private func readAlarm() {
        let storyboard = UIStoryboard(name: .kDevice, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "AlarmViewController") as! AlarmViewController
        vc.hidesBottomBarWhenPushed = true
        parent?.navigationController?.pushViewController(vc, animated: true)
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
        if indexPath.section == 0 && indexPath.row >= 1 && indexPath.row <= 3 {
            let mSwitch = UISwitch()
            mSwitch.tag = 999 + indexPath.row
            mSwitch.addTarget(self, action: #selector(valueChanged(_:)), for: .valueChanged)
            cell.accessoryView = mSwitch
            if indexPath.row == 3 {
                mSwitch.isOn = bleSelf.functionSwitchModel.isLongSit
            } else if indexPath.row == 2 {
                mSwitch.isOn = bleSelf.functionSwitchModel.isLightScreen
            } else if indexPath.row == 1 {
                mSwitch.isOn = bleSelf.functionSwitchModel.isCallDown
                mSwitch.isOn = bleSelf.functionSwitchModel.isLightScreen
            }

        } else {
            let imageView = UIImageView(image: UIImage(named: "content_next"))
            cell.accessoryView = imageView
        }
        if indexPath.section == 0 && indexPath.row == 4 {
            cell.detailTextLabel?.text = "\(bleSelf.longSitModel.interval)\("minute".localized())"
        } else {
            cell.detailTextLabel?.text = ""
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 1
    }
    
    
}

extension DeviceSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if bleSelf.isConnected == false {
            Toast(text: "mine_unconnect".localized()).show()
            return
        }
        if indexPath.section == 0 {
            if indexPath.row == 0 { // 推送设置
                let storyboard = UIStoryboard(name: .kDevice, bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "APNSViewController")
                vc.hidesBottomBarWhenPushed = true
                parent?.navigationController?.pushViewController(vc, animated: true)
            } else if indexPath.row == 4 {
                let vc = storyboard?.instantiateViewController(withIdentifier: "LongsitSettingsViewController")
                vc?.hidesBottomBarWhenPushed = true
                parent?.navigationController?.pushViewController(vc!, animated: true)
            } else if indexPath.row == 5 {
                let vc = OpenWeatherViewController()
                vc.hidesBottomBarWhenPushed = true
                parent?.navigationController?.pushViewController(vc, animated: true)
            }
        } else {
            if indexPath.row == 3 {
                bleSelf.setCameraForWristband(true)
                takePhoto()
            } else if indexPath.row == 2 { // 设置信息
                let storyboard = UIStoryboard(name: .kDevice, bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "DeviceInfoViewController")
                vc.hidesBottomBarWhenPushed = true
                parent?.navigationController?.pushViewController(vc, animated: true)
            } else if indexPath.row == 1 { // 查找设备
                let storyboard = UIStoryboard(name: .kDevice, bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "DeviceFoundViewController")
                vc.hidesBottomBarWhenPushed = true
                parent?.navigationController?.pushViewController(vc, animated: true)
            } else { // 闹钟设置
                bleSelf.getAlarmForWristband() // 获取闹钟信息
                perform(#selector(readAlarm), with: nil, afterDelay: 0.3)
            }
        }
    }
}

extension DeviceSettingsViewController {
    var titles: [[String]] {
        return [["device_push_settings".localized(), "device_call_amind".localized(), "device_hand_up_screen".localized(), "device_longsit_amind".localized(), "device_longsit_amind_time".localized(), "device_weather_push".localized()], ["device_alarm_settings".localized(), "device_search_settings".localized(), "device_device_info".localized(),"device_shark_photo".localized()]]
    }
}

