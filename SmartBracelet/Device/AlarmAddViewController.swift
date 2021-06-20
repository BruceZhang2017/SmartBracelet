//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  AlarmAddViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/10/8.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit
import TJDWristbandSDK

class AlarmAddViewController: BaseViewController {
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var repeatLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var weekLabel: UILabel!
    var bEdit = false
    var weekday = 0
    var hour = 0
    var minute = 0
    var clockId = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "闹钟设置"
        refreshUI(bEdit: bEdit)
        if weekday >= 0 {
            refreshWeekValue()
        }
        if hour > 0 || minute > 0 {
            let dateFormatter = DateFormatter();
            dateFormatter.dateFormat = "HH:mm";
            let date = dateFormatter.date(from: "\(String(format: "%02d", hour)):\(String(format: "%02d", minute))")
            datePicker.setDate(date!, animated: true)
        }
    }
    
    public func refreshUI(bEdit: Bool) {
        self.bEdit = bEdit
        if bEdit {
            cancelButton.isHidden = true
        } else {
            deleteButton.setTitle("确认", for: .normal)
            deleteButton.setTitleColor(UIColor.k333333, for: .normal)
        }
    }

    @IBAction func repeatDate(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "AlarmRepeatViewController") as? AlarmRepeatViewController
        vc?.days = weekday
        navigationController?.pushViewController(vc!, animated: true)
        vc?.callbackBlock = {
            [weak self] (value) in
            self?.weekday = value
            if value >= 0 {
                self?.refreshWeekValue()
            }
        }
    }
    
    @IBAction func deleteAlarm(_ sender: Any) {
        if bEdit { // 当前为编辑状态
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            let value = formatter.string(from: datePicker.date)
            let array = value.split(separator: ":")
            let model = WUAlarmClock()
            model.clockId = clockId
            if array.count == 2 {
                model.hour = Int(array[0]) ?? 0
                model.minute = Int(array[1]) ?? 0
            }
            model.isOn = true
            model.weekday = weekday % 10000
            model.repeatCount = weekday > 10000 ? 1 : 3
            model.repeatInterval = 5
            bleSelf.setAlarmForWristband(model)
            navigationController?.popViewController(animated: true)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            let value = formatter.string(from: datePicker.date)
            let array = value.split(separator: ":")
            let model = WUAlarmClock()
            var clockId = 0
            for j in 0..<5 {
                var tem = false
                for alarm in BLEManager.shared.alarmArray {
                    if j == alarm.clockId {
                        tem = true
                        break
                    }
                }
                if tem == false {
                    clockId = j
                    break
                }
            }
            if array.count == 2 {
                model.hour = Int(array[0]) ?? 0
                model.minute = Int(array[1]) ?? 0
            }
            model.isOn = true
            model.weekday = weekday % 10000
            model.repeatCount = weekday > 10000 ? 1 : 3
            model.repeatInterval = 5
            bleSelf.setAlarmForWristband(model)
            navigationController?.popViewController(animated: true)
        }
        perform(#selector(refreshAlarm), with: nil, afterDelay: 0.1)
    }
    
    @objc private func refreshAlarm() {
        NotificationCenter.default.post(name: Notification.Name.AlarmRefresh, object: nil)
    }
    
    @IBAction func cancel(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func timeValueChanged(_ sender: Any) {
        
    }
    
    private func refreshWeekValue() {
        if weekday > 10000 || weekday == 0 {
            weekLabel.text = "仅此一次"
        } else {
            var value = ""
            if (weekday % 10000) % 64 % 32 % 16 % 8 % 4 % 2 > 0 {
                value += "周一、"
            }
            if (weekday % 10000) % 64 % 32 % 16 % 8 % 4 >= 2 {
                value += "周二、"
            }
            if (weekday % 10000) % 64 % 32 % 16 % 8 >= 4 {
                value += "周三、"
            }
            if (weekday % 10000) % 64 % 32 % 16 >= 8 {
                value += "周四、"
            }
            if (weekday % 10000) % 64 % 32 >= 16 {
                value += "周五、"
            }
            if (weekday % 10000) % 64 >= 32 {
                value += "周六、"
            }
            if (weekday % 10000) >= 64 {
                value += "周日、"
            }
            let _ = value.removeLast()
            weekLabel.text = value
        }
    }
}
