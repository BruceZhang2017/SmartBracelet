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

class AlarmAddViewController: BaseViewController {
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var repeatLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "闹钟设置"
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func repeatDate(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "AlarmRepeatViewController")
        navigationController?.pushViewController(vc!, animated: true)
    }
    
    @IBAction func deleteAlarm(_ sender: Any) {
    }
}
