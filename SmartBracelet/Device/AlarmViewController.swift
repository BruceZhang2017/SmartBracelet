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

class AlarmViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var nullLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "闹钟设置"
        tableView.isHidden = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "nav_icon_alarm_add"), style: .plain, target: self, action: #selector(addOrManageAlarm(_:)))
        tableView.register(AlarmHeaderView.self, forHeaderFooterViewReuseIdentifier: "Header")
        tableView.tableFooterView = UIView()
    }

    @objc private func addOrManageAlarm(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "AlarmAddViewController") as! AlarmAddViewController
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension AlarmViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: .kCellIdentifier, for: indexPath) as! AlarmTableViewCell
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "Header") as! AlarmHeaderView
        if section == 0 {
            view.titleLabel.text = "AM"
        } else {
            view.titleLabel.text = "PM"
        }
        return view
    }
}

extension AlarmViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 64
    }
}
