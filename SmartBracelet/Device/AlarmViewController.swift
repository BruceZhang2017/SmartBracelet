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
import ProgressHUD

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
            if (XGZTBlueToothManager.shared.device?.alarmcount ?? 0) < 5 {
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
        if isXGZT {
            ProgressHUD.dismiss()
        }
        tableView.reloadData()
    }
    
    @objc private func refreshAlarm() {
        NotificationCenter.default.post(name: Notification.Name.AlarmRefresh, object: nil)
    }
    
    @objc private func valueChanged(_ sender: Any) {
        guard let mSwitch = sender as? UISwitch else {
            return 
        }
        if mSwitch.tag - 999 < 0 {
            return
        }
        let isOn = mSwitch.isOn
        if isXGZT {
            guard var alarmData = XGZTBlueToothManager.shared.device?.alarms[mSwitch.tag - 999] else {
                return
            }
            ProgressHUD.animate(nil, .activityIndicator, interaction: false)
            alarmData.mswitch = isOn ? 1 : 0
            XGZTCommand.setAlarmInfo(setCmd: 1, alarm: alarmData)
        } else {
            if BLEManager.shared.alarmArray.count < (mSwitch.tag - 999 + 1) {
                return
            }
            var model = BLEManager.shared.alarmArray[mSwitch.tag - 999]
            model.isOn = isOn
            bleSelf.setAlarmForWristband(model)
        }
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
        if (weekday & 0x01) > 0 {
            value += "\("mine_monday".localized())、"
        }
        if ((weekday >> 1) & 0x01) > 0  {
            value += "\("mine_satuday".localized())、"
        }
        if ((weekday >> 2) & 0x01) > 0  {
            value += "\("mine_wednesday".localized())、"
        }
        if ((weekday >> 3) & 0x01) > 0  {
            value += "\("mine_thursday".localized())、"
        }
        if ((weekday >> 4) & 0x01) > 0  {
            value += "\("mine_friday".localized())、"
        }
        if ((weekday >> 5) & 0x01) > 0  {
            value += "\("mine_saturday".localized())、"
        }
        if ((weekday >> 6) & 0x01) > 0 {
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
    
    // 实现侧滑删除功能
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "mine_delete".localized()) { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            
            // 第一次确认弹窗
            let firstAlert = UIAlertController(title: "confirm_delete".localized(), message: "delete_alarm_confirmation".localized(), preferredStyle: .alert)
            let firstConfirmAction = UIAlertAction(title: "confirm".localized(), style: .destructive) { [weak self] _ in
                guard let self = self else { return }
                // 打印被删除的 cell 的索引
                XLogger.shared.log("Deleting cell at indexPath: \(indexPath)")
                
                if isXGZT {
                    if var alarms = XGZTBlueToothManager.shared.device?.alarms, alarms.indices.contains(indexPath.row) {
                        XGZTCommand.setAlarmInfo(setCmd: 2, alarm: alarms[indexPath.row])
                        alarms.remove(at: indexPath.row)
                        XGZTBlueToothManager.shared.device?.alarms = alarms
                    }
                } else {
                    if BLEManager.shared.alarmArray.indices.contains(indexPath.row) {
                        BLEManager.shared.alarmArray.remove(at: indexPath.row)
                    }
                }
                
                // 从表格中删除对应的行
                tableView.deleteRows(at: [indexPath], with: .automatic)
                completionHandler(true)
            }
            let firstCancelAction = UIAlertAction(title: "Cancel".localized(), style: .cancel) { _ in
                completionHandler(false)
            }
            firstAlert.addAction(firstConfirmAction)
            firstAlert.addAction(firstCancelAction)
            self.present(firstAlert, animated: true, completion: nil)
        }
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        return configuration
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
