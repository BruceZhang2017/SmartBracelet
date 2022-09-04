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
    @IBOutlet weak var lateLabel: UILabel!
    @IBOutlet weak var weekLabel: UILabel!
    @IBOutlet weak var laterTipLabel: UILabel!
    var alarm: WUAlarmClock!
    var weekday = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "device_alarm_settings".localized()
        if weekday >= 0 {
            refreshWeekValue()
        }
        let dateFormatter = DateFormatter();
        dateFormatter.dateFormat = "HH:mm";
        let date = dateFormatter.date(from: "\(String(format: "%02d", alarm.hour)):\(String(format: "%02d", alarm.minute))")
        datePicker.setDate(date!, animated: true)
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        } else {
            // Fallback on earlier versions
        }
        
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "mine_save".localized(), style: .plain, target: self, action: #selector(save))
        laterTipLabel.text = "mine_alarm_late_amind".localized()
        repeatLabel.text = "repeat".localized()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        lateLabel.text = "\(alarm.repeatInterval)\("minute".localized())"
    }
    
    @objc private func save() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let value = formatter.string(from: datePicker.date)
        let array = value.split(separator: ":")
        if array.count == 2 {
            alarm.hour = Int(array[0]) ?? 0
            alarm.minute = Int(array[1]) ?? 0
        }
        alarm.isOn = true
        bleSelf.setAlarmForWristband(alarm)
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func setLateTime(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "AlarmIntervalViewController") as? AlarmIntervalViewController
        vc?.alarm = alarm
        navigationController?.pushViewController(vc!, animated: true)
    }
    
    @IBAction func repeatDate(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "AlarmRepeatViewController") as? AlarmRepeatViewController
        vc?.weekday = weekday
        navigationController?.pushViewController(vc!, animated: true)
        vc?.callbackBlock = {
            [weak self] (value) in
            self?.weekday = value
            self?.alarm.weekday = value
            if value >= 0 {
                self?.refreshWeekValue()
            }
        }
    }
    
    @objc private func refreshAlarm() {
        NotificationCenter.default.post(name: Notification.Name.AlarmRefresh, object: nil)
    }
    
    @IBAction func timeValueChanged(_ sender: Any) {
        
    }
    
    private func refreshWeekValue() {
        var value = ""
        if ((weekday >> 1) & 0x01) > 0 {
            value += "\("mine_monday".localized())、"
        }
        if ((weekday >> 2) & 0x01) > 0 {
            value += "\("mine_satuday".localized())、"
        }
        if ((weekday >> 3) & 0x01) > 0 {
            value += "\("mine_wednesday".localized())、"
        }
        if ((weekday >> 4) & 0x01) > 0 {
            value += "\("mine_thursday".localized())、"
        }
        if ((weekday >> 5) & 0x01) > 0 {
            value += "\("mine_friday".localized())、"
        }
        if ((weekday >> 6) & 0x01) > 0 {
            value += "\("mine_saturday".localized())、"
        }
        if (weekday & 0x01) > 0  {
            value += "\("mine_sunday".localized())、"
        }
        if value.count == 0 {
            weekLabel.text = "mine_null".localized()
            return
        }
        let _ = value.removeLast()
        weekLabel.text = value
    }
}
