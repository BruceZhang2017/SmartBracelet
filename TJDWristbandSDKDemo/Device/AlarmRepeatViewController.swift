//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  AlarmRepeatViewController.swift
//  TJDWristbandSDKDemo
//
//  Created by ANKER on 2020/10/8.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit

class AlarmRepeatViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "闹钟设置"
        tableView.tableFooterView = UIView()
    }

}

extension AlarmRepeatViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: .kCellIdentifier, for: indexPath)
        cell.textLabel?.textColor = UIColor.k343434
        cell.textLabel?.font = UIFont.systemFont(ofSize: 15)
        cell.textLabel?.text = titles[indexPath.row]
        cell.accessoryView = UIImageView(image: UIImage(named: "content_icon_selecte"))
        return cell
    }
}

extension AlarmRepeatViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension AlarmRepeatViewController {
    var titles: [String] {
        return ["仅此一次", "周一", "周二", "周三", "周四", "周五", "周六", "周日"]
    }
}
