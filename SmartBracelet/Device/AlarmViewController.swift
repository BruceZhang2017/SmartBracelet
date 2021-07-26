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
        bleSelf.getAlarmForWristband() // 获取闹钟信息
        super.viewDidLoad()
        title = "闹钟设置"
        tableView.tableFooterView = UIView()
        registerNotification()
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
        
    }
    
    private func refreshWeekValue(model: WUAlarmClock) -> String {
        let weekday = model.weekday
        var value = ""
        if ((weekday >> 1) & 0x01) > 0 {
            value += "周一、"
        }
        if ((weekday >> 2) & 0x01) > 0  {
            value += "周二、"
        }
        if ((weekday >> 3) & 0x01) > 0  {
            value += "周三、"
        }
        if ((weekday >> 4) & 0x01) > 0  {
            value += "周四、"
        }
        if ((weekday >> 5) & 0x01) > 0  {
            value += "周五、"
        }
        if ((weekday >> 6) & 0x01) > 0  {
            value += "周六、"
        }
        if (weekday & 0x01) > 0 {
            value += "周日、"
        }
        if value.count == 0 {
            return "无"
        } else {
            let _ = value.removeLast()
            return value
        }
    }
}

extension AlarmViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return BLEManager.shared.alarmArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: .kCellIdentifier, for: indexPath) as! AlarmTableViewCell
        let model = BLEManager.shared.alarmArray[indexPath.row]
        cell.textLabel?.text = "\(String(format: "%02d", model.hour)):\(String(format: "%02d", model.minute))"
        var mSwitch = cell.viewWithTag(999 + indexPath.row) as? UISwitch
        if mSwitch == nil {
            mSwitch = UISwitch()
            mSwitch?.tag = 999 + indexPath.row
        }
        mSwitch?.addTarget(self, action: #selector(valueChanged(_:)), for: .valueChanged)
        cell.accessoryView = mSwitch!
        mSwitch?.isOn = model.isOn
        cell.detailTextLabel?.text = "重复模式 \(refreshWeekValue(model: model))"
        return cell
    }
}

extension AlarmViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = BLEManager.shared.alarmArray[indexPath.row]
        let vc = storyboard?.instantiateViewController(withIdentifier: "AlarmAddViewController") as! AlarmAddViewController
        vc.weekday = model.weekday
        vc.alarm = model
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
