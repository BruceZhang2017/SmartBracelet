//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  AlarmViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/10/8.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit
import TJDWristbandSDK

class AlarmViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "device_alarm_settings".localized()
        tableView.tableFooterView = UIView()
        registerNotification()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isXGZT {
            if XGZTBlueToothManager.shared.device?.alarmcount ?? 0 == 0 {
                setupNavigationBar()
            }
        } else {
            Async.main(after: 1) {
                if BLEManager.shared.alarmArray.count == 0 {
                    bleSelf.getAlarmForWristband() // 获取闹钟信息
                }
            }
        }
        
    }
    
    private func setupNavigationBar() {
        // 创建一个图片按钮
        if let image = UIImage(named: "icon_add3")?.withRenderingMode(.alwaysTemplate) {
            let rightButton = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(rightButtonTapped))
            
            // 设置按钮图片颜色为黑色
            rightButton.tintColor = .black
            
            // 将按钮添加到导航栏的右侧
            navigationItem.rightBarButtonItem = rightButton
        }
    }

    @objc private func rightButtonTapped() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "AlarmAddViewController") as! AlarmAddViewController
        navigationController?.pushViewController(vc, animated: true)
    }
    
    deinit {
        unregisterNotification()
    }
    
    @objc private func handleNotificationForAlarm(_ notification: Notification) {
        bleSelf.getAlarmForWristband() // 获取闹钟信息
    }
    
    private func registerNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: Notification.Name.Alarm, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotificationForAlarm(_:)), name: Notification.Name.AlarmRefresh, object: nil)
    }
    
    private func unregisterNotification() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleNotification(_ notification: Notification) {
        tableView.reloadData()
    }
    
    @objc private func refreshAlarm() {
        NotificationCenter.default.post(name: Notification.Name.AlarmRefresh, object: nil)
    }
    
    @objc private func valueChanged(_ sender: Any) {
        let mSwitch = sender as! UISwitch
        let isOn = mSwitch.isOn
        var model = BLEManager.shared.alarmArray[mSwitch.tag - 999]
        model.isOn = isOn
        bleSelf.setAlarmForWristband(model)
    }
    
    private func refreshWeekValue(model: WUAlarmClock) -> String {
        let weekday = model.weekday
        var value = ""
        if ((weekday >> 1) & 0x01) > 0 {
            value += "\("mine_monday".localized())、"
        }
        if ((weekday >> 2) & 0x01) > 0  {
            value += "\("mine_satuday".localized())、"
        }
        if ((weekday >> 3) & 0x01) > 0  {
            value += "\("mine_wednesday".localized())、"
        }
        if ((weekday >> 4) & 0x01) > 0  {
            value += "\("mine_thursday".localized())、"
        }
        if ((weekday >> 5) & 0x01) > 0  {
            value += "\("mine_friday".localized())、"
        }
        if ((weekday >> 6) & 0x01) > 0  {
            value += "\("mine_saturday".localized())、"
        }
        if (weekday & 0x01) > 0 {
            value += "\("mine_sunday".localized())、"
        }
        if value.count == 0 {
            return "mine_null".localized()
        } else {
            let _ = value.removeLast()
            return value
        }
    }
    
    private func refreshWeekValue(alarm: AlarmData?) -> String {
        let weekday = alarm?.alarmCycle ?? 0
        var value = ""
        if ((weekday >> 1) & 0x01) > 0 {
            value += "\("mine_monday".localized())、"
        }
        if ((weekday >> 2) & 0x01) > 0  {
            value += "\("mine_satuday".localized())、"
        }
        if ((weekday >> 3) & 0x01) > 0  {
            value += "\("mine_wednesday".localized())、"
        }
        if ((weekday >> 4) & 0x01) > 0  {
            value += "\("mine_thursday".localized())、"
        }
        if ((weekday >> 5) & 0x01) > 0  {
            value += "\("mine_friday".localized())、"
        }
        if ((weekday >> 6) & 0x01) > 0  {
            value += "\("mine_saturday".localized())、"
        }
        if (weekday & 0x01) > 0 {
            value += "\("mine_sunday".localized())、"
        }
        if value.count == 0 {
            return "mine_null".localized()
        } else {
            let _ = value.removeLast()
            return value
        }
    }
}

extension AlarmViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isXGZT {
            return XGZTBlueToothManager.shared.device?.alarms.count ?? 0
        } else {
            return BLEManager.shared.alarmArray.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: .kCellIdentifier, for: indexPath) as! AlarmTableViewCell
        cell.textLabel?.textColor = UIColor.text_primary
        cell.textLabel?.font = UIFont.body()
        cell.detailTextLabel?.textColor = UIColor.text_third
        cell.detailTextLabel?.font = UIFont.body2()
        
        var mSwitch = cell.viewWithTag(999 + indexPath.row) as? UISwitch
        if mSwitch == nil {
            mSwitch = UISwitch()
            mSwitch?.tag = 999 + indexPath.row
        }
        mSwitch?.addTarget(self, action: #selector(valueChanged(_:)), for: .valueChanged)
        cell.accessoryView = mSwitch!
        
        if isXGZT {
            let alarm = XGZTBlueToothManager.shared.device?.alarms[indexPath.row]
            cell.textLabel?.text = "\(String(format: "%02d", alarm?.alarmHour ?? 0)):\(String(format: "%02d", alarm?.alarmMinute ?? 0))"
            cell.detailTextLabel?.text = "\("mine_repeat_mode".localized()) \(refreshWeekValue(alarm: alarm))"
            mSwitch?.isOn = (alarm?.mswitch ?? 0) > 0
        } else {
            let model = BLEManager.shared.alarmArray[indexPath.row]
            cell.textLabel?.text = "\(String(format: "%02d", model.hour)):\(String(format: "%02d", model.minute))"
            cell.detailTextLabel?.text = "\("mine_repeat_mode".localized()) \(refreshWeekValue(model: model))"
            mSwitch?.isOn = model.isOn
        }
        
        return cell
    }
}

extension AlarmViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let vc = storyboard?.instantiateViewController(withIdentifier: "AlarmAddViewController") as! AlarmAddViewController
        if isXGZT {
            let alarm = XGZTBlueToothManager.shared.device?.alarms[indexPath.row]
            vc.alarmData = alarm
        } else {
            let model = BLEManager.shared.alarmArray[indexPath.row]
            vc.weekday = model.weekday
            vc.alarm = model
        }
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension AlarmViewController: AlarmHeaderViewDelegate {
    func handleDeleteEvent(tag: Int) {
        
    }
}

extension Notification.Name {
    static let Alarm = Notification.Name("Alarm")
    static let AlarmRefresh = Notification.Name("AlarmRefresh")
}
