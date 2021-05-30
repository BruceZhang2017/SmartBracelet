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
    @IBOutlet weak var nullLabel: UILabel!
    var maximumAlarmLabel: UILabel!
    var addButton: UIButton!
    var alarms: [[WUAlarmClock]] = [] // 闹钟数量
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "闹钟设置"
        tableView.isHidden = true
        tableView.register(AlarmHeaderView.self, forHeaderFooterViewReuseIdentifier: "Header")
        tableView.tableFooterView = UIView()
        registerNotification()
        bleSelf.getAlarmForWristband() // 获取闹钟信息
    }
    
    deinit {
        unregisterNotification()
    }

    @objc private func addOrManageAlarm(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "AlarmAddViewController") as! AlarmAddViewController
        vc.bEdit = false
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func showAddAlarmButton() {
        if maximumAlarmLabel == nil {
            maximumAlarmLabel = UILabel().then {
                $0.textColor = UIColor.k333333
                $0.font = UIFont.systemFont(ofSize: 16)
                $0.textAlignment = .center
                $0.text = "添加闹钟\n你最多可以添加五组闹钟"
                $0.numberOfLines = 0
            }
            view.addSubview(maximumAlarmLabel)
            maximumAlarmLabel.snp.makeConstraints {
                $0.left.right.equalToSuperview().inset(30)
                $0.bottom.equalTo(-50)
            }
        }
        maximumAlarmLabel.isHidden = false
        
        if addButton == nil {
            addButton = UIButton(type: .custom).then {
                $0.setImage(UIImage(named: "add_big"), for: .normal)
                $0.addTarget(self, action: #selector(handleAddAlarm(_:)), for: .touchUpInside)
            }
            view.addSubview(addButton)
            addButton.snp.makeConstraints {
                $0.centerX.equalToSuperview()
                $0.width.height.equalTo(64)
                $0.bottom.equalTo(maximumAlarmLabel.snp.top).offset(-10)
            }
        }
        addButton.isHidden = false
    }
    
    private func hideAddAlarmButton() {
        maximumAlarmLabel?.isHidden = true
        addButton?.isHidden = true
    }
    
    @objc private func handleAddAlarm(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "AlarmAddViewController") as! AlarmAddViewController
        vc.bEdit = false
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func editAlarm(_ sender: Any) {
        if !tableView.isEditing {
            tableView.setEditing(true, animated: true)
        } else {
            tableView.setEditing(false, animated: true)
        }
        tableView.reloadData()
    }
    
    private func registerNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: Notification.Name.Alarm, object: nil)
    }
    
    private func unregisterNotification() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleNotification(_ notification: Notification) {
        if BLEManager.shared.alarmArray.count > 0 {
            nullLabel.isHidden = true
            tableView.isHidden = false
            alarms.removeAll()
            let section1 = BLEManager.shared.alarmArray.filter({$0.hour < 12})
            if section1.count > 0 {
                alarms.append(section1)
            }
            let section2 = BLEManager.shared.alarmArray.filter({$0.hour >= 12})
            if section2.count > 0 {
                alarms.append(section2)
            }
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "nav_icon_edit"), style: .plain, target: self, action: #selector(editAlarm(_:)))
            if BLEManager.shared.alarmArray.count >= 5 {
                hideAddAlarmButton()
            } else {
                showAddAlarmButton()
            }
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "nav_icon_alarm_add"), style: .plain, target: self, action: #selector(addOrManageAlarm(_:)))
            hideAddAlarmButton()
        }
        tableView.reloadData()
    }
}

extension AlarmViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return alarms.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return alarms[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: .kCellIdentifier, for: indexPath) as! AlarmTableViewCell
        let model = alarms[indexPath.section][indexPath.row]
        cell.titleLabel.text = "\(model.hour):\(model.minute)"
        cell.mSwitch.isOn = model.isOn
        cell.mSwitch.isHidden = tableView.isEditing
        cell.arrorImageView.isHidden = !tableView.isEditing
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "Header") as! AlarmHeaderView
        if alarms.count == 2 {
            if section == 0 {
                view.titleLabel.text = "AM"
            } else {
                view.titleLabel.text = "PM"
            }
        } else if alarms.count == 1 {
            if alarms.first?.first?.hour ?? 0 >= 12 {
                view.titleLabel.text = "PM"
            } else {
                view.titleLabel.text = "AM"
            }
        }
        view.deleteButton.isHidden = tableView.isEditing ? false : true
        view.delegate = self
        view.tag = section
        return view
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return UITableViewCell.EditingStyle.delete
    }
}

extension AlarmViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if tableView.isEditing {
            let vc = storyboard?.instantiateViewController(withIdentifier: "AlarmAddViewController") as! AlarmAddViewController
            vc.bEdit = true
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 64
    }
}

extension AlarmViewController: AlarmHeaderViewDelegate {
    func handleDeleteEvent(tag: Int) {
        
    }
}

extension Notification.Name {
    static let Alarm = Notification.Name("Alarm")
}
