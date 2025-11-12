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
import Toaster

class AlarmAddViewController: BaseViewController {
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var repeatLabel: UILabel!
    @IBOutlet weak var lateLabel: UILabel!
    @IBOutlet weak var weekLabel: UILabel!
    @IBOutlet weak var laterTipLabel: UILabel!
    var alarm: WUAlarmClock!
    var weekday = 0
    var alarmData: AlarmData?
    var isNew: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "device_alarm_settings".localized()
        if isXGZT {
            if alarmData != nil {
                refreshRepeatValue()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "HH:mm"
                let date = dateFormatter.date(from: "\(String(format: "%02d", alarmData?.alarmHour ?? 0)):\(String(format: "%02d", alarmData?.alarmMinute ?? 0))")
                if date != nil {
                    datePicker.setDate(date!, animated: true)
                }
            }
        } else {
            if weekday >= 0 {
                refreshWeekValue()
            }
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            let date = dateFormatter.date(from: "\(String(format: "%02d", alarm.hour)):\(String(format: "%02d", alarm.minute))")
            if date != nil {
                datePicker.setDate(date!, animated: true)
            }
        }
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
        if isXGZT {
            if alarmData != nil {
                lateLabel.text = "\(alarmData?.remindLater ?? 0)\("minute".localized())"
            } else {
                alarmData = AlarmData(alarmIndex: 0, mswitch: 0, alarmCycle: 0, alarmHour: 0, alarmMinute: 0, vibrationMode: 0, remindLater: 0)
                isNew = true
            }
        } else {
            lateLabel.text = "\(alarm.repeatInterval)\("minute".localized())"
        }
    }
    
    @objc private func save() {
        if isXGZT && isNew {
            if (alarmData?.alarmCycle ?? 0) <= 0 {
                Toast(text: "please_choose_day".localized()).show()
                return
            }
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let value = formatter.string(from: datePicker.date)
        let array = value.split(separator: ":")
        if isXGZT {
            if array.count == 2 {
                alarmData?.alarmHour = Int(array[0]) ?? 0
                alarmData?.alarmMinute = Int(array[1]) ?? 0
            }
            alarmData?.mswitch = 1
            alarmData?.vibrationMode = 1
            if isNew {
                alarmData?.alarmIndex = XGZTBlueToothManager.shared.device?.alarmCanUse ?? 0
            }
            XGZTCommand.setAlarmInfo(setCmd: isNew ? 0 : 1, alarm: alarmData!)
        } else {
            if array.count == 2 {
                alarm.hour = Int(array[0]) ?? 0
                alarm.minute = Int(array[1]) ?? 0
            }
            alarm.isOn = true
            bleSelf.setAlarmForWristband(alarm)
        }
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func setLateTime(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "AlarmIntervalViewController") as? AlarmIntervalViewController
        if isXGZT {
            vc?.alarmData = alarmData
        } else {
            vc?.alarm = alarm
        }
        navigationController?.pushViewController(vc!, animated: true)
        if isXGZT {
            vc?.callbackBlock = {
                [weak self] (value) in
                self?.alarmData?.remindLater = value
            }
        }
    }
    
    @IBAction func repeatDate(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "AlarmRepeatViewController") as? AlarmRepeatViewController
        if isXGZT {
            vc?.alarmCycle = alarmData?.alarmCycle ?? 0
        }else {
            vc?.weekday = weekday
        }
        navigationController?.pushViewController(vc!, animated: true)
        if isXGZT {
            vc?.callbackBlock = {
                [weak self] (value) in
                self?.alarmData?.alarmCycle = value
                if value >= 0 {
                    self?.refreshRepeatValue()
                }
            }
        } else {
            vc?.callbackBlock = {
                [weak self] (value) in
                self?.weekday = value
                self?.alarm.weekday = value
                if value >= 0 {
                    self?.refreshWeekValue()
                }
            }
        }
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
    
    private func refreshRepeatValue() {
        guard let weekday = alarmData?.alarmCycle else {
            return 
        }
        var value = ""
        if (weekday & 0x01) > 0 {
            value += "\("mine_monday".localized())、"
        }
        if ((weekday >> 1) & 0x01) > 0 {
            value += "\("mine_satuday".localized())、"
        }
        if ((weekday >> 2) & 0x01) > 0 {
            value += "\("mine_wednesday".localized())、"
        }
        if ((weekday >> 3) & 0x01) > 0 {
            value += "\("mine_thursday".localized())、"
        }
        if ((weekday >> 4) & 0x01) > 0 {
            value += "\("mine_friday".localized())、"
        }
        if ((weekday >> 5) & 0x01) > 0 {
            value += "\("mine_saturday".localized())、"
        }
        if ((weekday >> 6) & 0x01) > 0  {
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
