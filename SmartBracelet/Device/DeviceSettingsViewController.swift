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

class DeviceSettingsViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    //var footerView: UIView!
    var cameraViewController: CameraViewController?
    private var currentTime: TimeInterval = 0 // 当前时间戳
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if isXGZT { // 如果是自研产品
            XGZTCommand.getSwitchStatus()
            XGZTCommand.getSwitchTableExtension()
            XGZTCommand.getReminderInfo(eventType: 0) // 久坐
            XGZTCommand.getReminderInfo(eventType: 1) //喝水
        } else {
            bleSelf.getAncsSwitchForWristband() // 苹果推送消息
            let delay = DispatchTime.now() + 0.05
            DispatchQueue.main.asyncAfter(deadline: delay) {
                bleSelf.getLongSitForWristband()
            }
            let delay2 = DispatchTime.now() + 0.1
            DispatchQueue.main.asyncAfter(deadline: delay2) {
                bleSelf.getDrinkForWristband()
            }
        }
       
        tableView.backgroundColor = UIColor.kF5F5F5
        tableView.isScrollEnabled = false
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
        if let obj = notification.object as? Int {
            if obj == 1 {
                DispatchQueue.main.async {
                    [weak self] in
                    self?.tableView.reloadData()
                }
                return
            }
        }
        
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
    
    @objc private func valueChanged(_ sender: Any) {
        let mSwitch = sender as? UISwitch
        let tag = mSwitch?.tag ?? 0
        if tag == 1002 { // 长坐提醒
            if isXGZT {
                guard let device = XGZTBlueToothManager.shared.device else {
                    return
                }
                if (mSwitch?.isOn ?? false) {
                    device.longsit?.cycle = 0b11111111
                    device.longsit?.startHour = 0
                    device.longsit?.startMinute = 0
                    device.longsit?.endHour = 0x17
                    device.longsit?.endMinute = 0x3b
                    if (device.longsit?.period ?? 0) == 0 {
                        device.longsit?.period = 0x0a
                    }
                    XGZTCommand.setReminderInfo(response: device.longsit!)
                } else {
                    device.longsit?.cycle = 0b01111111
                    XGZTCommand.setReminderInfo(response: device.longsit!)
                }
            } else {
                bleSelf.functionSwitchModel.isLongSit = mSwitch?.isOn ?? false
                bleSelf.setSwitchForWristband(bleSelf.functionSwitchModel)
            }
        } else if tag == 1001 { // 抬手亮屏
            if isXGZT {
                XGZTBlueToothManager.shared.device?.isRaisehandtobrightenscreen = mSwitch?.isOn ?? false
                
                var p0: UInt8 = 0
                var p1: UInt8 = 0

                // 设置 response[8] 的各个位
                if XGZTBlueToothManager.shared.device?.isMessagescreendisplayswitch == true {
                    p1 |= (1 << 1)
                }
                if XGZTBlueToothManager.shared.device?.isSoundswitch == true {
                    p1 |= (1 << 2)
                }
                if XGZTBlueToothManager.shared.device?.isVibrationswitch == true {
                    p1 |= (1 << 3)
                }
                if XGZTBlueToothManager.shared.device?.isRegularhealthdatauploadswitch == true {
                    p1 |= (1 << 4)
                }
                if XGZTBlueToothManager.shared.device?.isMessagevibrationswitch == true {
                    p1 |= (1 << 5)
                }

                // 设置 response[9] 的各个位
                if XGZTBlueToothManager.shared.device?.isAntilostSwitch == true {
                    p0 |= (1 << 0)
                }
                if XGZTBlueToothManager.shared.device?.isRaisehandtobrightenscreen == true {
                    p0 |= (1 << 1)
                }
                if XGZTBlueToothManager.shared.device?.isAntilostSwitch == true {
                    p0 |= (1 << 2)
                }
                if XGZTBlueToothManager.shared.device?.isSleepmonitoringSwitch == true {
                    p0 |= (1 << 4)
                }
                if XGZTBlueToothManager.shared.device?.isMessageremindermainswitch == true {
                    p0 |= (1 << 5)
                }
                if XGZTBlueToothManager.shared.device?.isRegularexercisedatauploadswitch == true {
                    p0 |= (1 << 6)
                }
                if XGZTBlueToothManager.shared.device?.isGoalachievementswitch == true {
                    p0 |= (1 << 7)
                }

                XGZTCommand.setSwitchStatus(p0: p0, p1: p1)
                
            } else {
                bleSelf.functionSwitchModel.isLightScreen = mSwitch?.isOn ?? false
                bleSelf.setSwitchForWristband(bleSelf.functionSwitchModel)
            }
        } else if tag == 1000 { // 来电提醒
            if isXGZT {
                XGZTBlueToothManager.shared.device?.isIncomingCall = mSwitch?.isOn ?? false
                guard let device = XGZTBlueToothManager.shared.device else {
                    return
                }
                var p0: UInt8 = 0
                var p1: UInt8 = 0
                var p2: UInt8 = 0
                var p3: UInt8 = 0
                p0 |= device.isNullMessage ? 1 << 0 : 0
                p0 |= device.isIncomingCall ? 1 << 1 : 0
                p0 |= device.isMissedCall ? 1 << 2 : 0
                p0 |= device.isMessages ? 1 << 3 : 0
                p0 |= device.isEmail ? 1 << 4 : 0
                p0 |= device.isSchedule ? 1 << 5 : 0
                p0 |= device.isFacetime ? 1 << 6 : 0
                p0 |= device.isQQ ? 1 << 7 : 0

                    // 处理 response[8]
                p1 |= device.isSkype ? 1 << 0 : 0
                p1 |= device.isWechat ? 1 << 1 : 0
                p1 |= device.isWhatsapp ? 1 << 2 : 0
                p1 |= device.isGmail ? 1 << 3 : 0
                p1 |= device.isHangout ? 1 << 4 : 0
                p1 |= device.isInbox ? 1 << 5 : 0
                p1 |= device.isLine ? 1 << 6 : 0
                p1 |= device.isTwitter ? 1 << 7 : 0
                
                // 处理 response[9]
                p2 |= device.isFacebook ? 1 << 0 : 0
                p2 |= device.isFacebookMessenger ? 1 << 1 : 0
                p2 |= device.isInstagram ? 1 << 2 : 0
                p2 |= device.isWeibo ? 1 << 3 : 0
                p2 |= device.isKakaotalk ? 1 << 4 : 0
                p2 |= device.isFacebookpagemanager ? 1 << 5 : 0
                p2 |= device.isViber ? 1 << 6 : 0
                p2 |= device.isVkclient ? 1 << 7 : 0
                
                // 处理 response[9]
                p3 |= device.isTelegram ? 1 << 0 : 0
                p3 |= device.isSnapchat ? 1 << 2 : 0
                p3 |= device.isDingTalk ? 1 << 3 : 0
                p3 |= device.isAlipay ? 1 << 4 : 0
                p3 |= device.isTiktok ? 1 << 5 : 0
                p3 |= device.isLinkedIn ? 1 << 6 : 0
                
                XGZTCommand.setSwitchTableExtension(p0: p0, p1: p1, p2: p2, p3: p3)
            } else {
                bleSelf.notifyModel.isCall = mSwitch?.isOn ?? false
                bleSelf.setAncsSwitchForWristband(bleSelf.notifyModel)
            }
            
        } else { // 喝水提醒
            if isXGZT {
                guard let device = XGZTBlueToothManager.shared.device else {
                    return
                }
                if (mSwitch?.isOn ?? false) {
                    if device.drinkWater == nil {
                        device.drinkWater = ReminderInfoResponse(eventType: 1, cycle: 0, startHour: 0, startMinute: 0, endHour: 0, endMinute: 0, period: 0)
                    }
                    device.drinkWater?.cycle = 0b11111111
                    device.drinkWater?.startHour = 0
                    device.drinkWater?.startMinute = 0
                    device.drinkWater?.endHour = 0x17
                    device.drinkWater?.endMinute = 0x3b
                    if (device.drinkWater?.period ?? 0) == 0 {
                        device.drinkWater?.period = 0x0a
                    }
                    XGZTCommand.setReminderInfo(response: device.drinkWater!)
                } else {
                    device.drinkWater?.cycle = 0b01111111
                    XGZTCommand.setReminderInfo(response: device.drinkWater!)
                }
            } else {
                bleSelf.functionSwitchModel.isDrink = mSwitch?.isOn ?? false
                bleSelf.setSwitchForWristband(bleSelf.functionSwitchModel)
            }
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
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isXGZT ? titles.count : (titles.count - 1)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: .kCellIdentifier, for: indexPath) as! DeviceSettingsTableViewCell
        cell.textLabel?.text = titles[indexPath.row]
        cell.textLabel?.textColor = UIColor.text_secondary
        cell.textLabel?.font = UIFont.body1()
        if (indexPath.row >= 1 && indexPath.row <= 3) || indexPath.row == 5 {
            let mSwitch = UISwitch()
            mSwitch.tag = 999 + indexPath.row
            mSwitch.addTarget(self, action: #selector(valueChanged(_:)), for: .valueChanged)
            cell.accessoryView = mSwitch
            if indexPath.row == 3 {
                if isXGZT {
                    mSwitch.isOn = XGZTBlueToothManager.shared.device?.longsit?.cycle ?? 0 >= 0b1000000
                } else {
                    mSwitch.isOn = bleSelf.functionSwitchModel.isLongSit
                }
            } else if indexPath.row == 2 {
                if isXGZT {
                    mSwitch.isOn = XGZTBlueToothManager.shared.device?.isRaisehandtobrightenscreen ?? false 
                } else {
                    mSwitch.isOn = bleSelf.functionSwitchModel.isLightScreen
                }
            } else if indexPath.row == 1 {
                if isXGZT {
                    mSwitch.isOn = XGZTBlueToothManager.shared.device?.isIncomingCall ?? false
                } else {
                    mSwitch.isOn = bleSelf.notifyModel.isCall
                }
            } else if indexPath.row == 5 {
                if isXGZT {
                    mSwitch.isOn = XGZTBlueToothManager.shared.device?.drinkWater?.cycle ?? 0 >= 0b1000000
                } else {
                    mSwitch.isOn = bleSelf.functionSwitchModel.isDrink
                }
            }

        } else {
            let imageView = UIImageView(image: UIImage(named: "content_next"))
            cell.accessoryView = imageView
        }
        if indexPath.row == 4 {
            if isXGZT {
                cell.detailTextLabel?.text = "\(XGZTBlueToothManager.shared.device?.longsit?.period ?? 0)\("minute".localized())"
            } else {
                cell.detailTextLabel?.text = "\(bleSelf.longSitModel.interval)\("minute".localized())"
            }
        } else if indexPath.row == 6 {
            if isXGZT {
                cell.detailTextLabel?.text = "\(XGZTBlueToothManager.shared.device?.drinkWater?.period ?? 0)\("minute".localized())"
            } else {
                cell.detailTextLabel?.text = "\(bleSelf.drinkModel.interval)\("minute".localized())"
            }
        } else {
            cell.detailTextLabel?.text = ""
        }
        return cell
    }
    
}

extension DeviceSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if !bleSelf.isConnected && XGZTBlueToothManager.shared.device == nil {
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
            } else if indexPath.row == 7 {
                let vc = OpenWeatherViewController()
                vc.hidesBottomBarWhenPushed = true
                parent?.navigationController?.pushViewController(vc, animated: true)
            }  else if indexPath.row == 6 {
                let vc = storyboard?.instantiateViewController(withIdentifier: "LongsitSettingsViewController") as? LongsitSettingsViewController
                vc?.flag = 1
                vc?.hidesBottomBarWhenPushed = true
                parent?.navigationController?.pushViewController(vc!, animated: true)
            }
        }
        if indexPath.row == 11 {
            bleSelf.setCameraForWristband(true)
            takePhoto()
        } else if indexPath.row == 10 { // 设置信息
            let storyboard = UIStoryboard(name: .kDevice, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "DeviceInfoViewController")
            vc.hidesBottomBarWhenPushed = true
            parent?.navigationController?.pushViewController(vc, animated: true)
        } else if indexPath.row == 9 { // 查找设备
            let storyboard = UIStoryboard(name: .kDevice, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "DeviceFoundViewController")
            vc.hidesBottomBarWhenPushed = true
            parent?.navigationController?.pushViewController(vc, animated: true)
        } else if indexPath.row == 8 { // 闹钟设置
            if isXGZT {
                XGZTCommand.getAlarmInfo()
            } else {
                bleSelf.getAlarmForWristband() // 获取闹钟信息
            }
            perform(#selector(readAlarm), with: nil, afterDelay: 0.3)
        } else if indexPath.row == 12 { // 同步数据
            if isXGZT {
                
            } else {
                if bleSelf.isConnected {
                    NotificationCenter.default.post(name: Notification.Name("HealthVCLoading"), object: 2)
                    BLEManager.shared.currentReadProgress = 3
                    bleSelf.getStep()
                }
            }
        } else if indexPath.row == 13 { // OTA
            let storyboard = UIStoryboard(name: "OTA", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "ABOtaViewController") as! ABOtaViewController
            vc.hidesBottomBarWhenPushed = true
            parent?.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 52
    }
}

extension DeviceSettingsViewController {
    var titles: [String] {
        return ["device_push_settings".localized(), "device_call_amind".localized(), "device_hand_up_screen".localized(), "device_longsit_amind".localized(), "device_longsit_amind_time".localized(),"drink_water_reminder".localized(), "drink_water_reminder_time".localized(), "device_weather_push".localized(), "device_alarm_settings".localized(), "device_search_settings".localized(), "device_device_info".localized(),"device_shark_photo".localized(), "synchronize_data".localized(), "OTA"]
    }
}

