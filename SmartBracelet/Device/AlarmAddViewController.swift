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
    var bEdit = false
    var weekday = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "闹钟设置"
        refreshUI(bEdit: bEdit)
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
        }
    }
    
    @IBAction func deleteAlarm(_ sender: Any) {
        if bEdit { // 当前为编辑状态
            
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            let value = formatter.string(from: datePicker.date)
            let array = value.split(separator: ":")
            let model = WUAlarmClock()
            model.clockId = 0
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
    }
    
    @IBAction func cancel(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func timeValueChanged(_ sender: Any) {
        
    }
}
