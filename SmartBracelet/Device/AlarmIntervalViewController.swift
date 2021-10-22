//
//  AlarmIntervalViewController.swift
//  SmartBracelet
//
//  Created by anker on 2021/7/24.
//  Copyright © 2021 tjd. All rights reserved.
//

import UIKit
import TJDWristbandSDK

class AlarmIntervalViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    var alarm: WUAlarmClock!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "mine_alarm_late_amind".localized()
        tableView.tableFooterView = UIView()
    }

}

extension AlarmIntervalViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 9
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: .kCellIdentifier, for: indexPath)
        if let label = cell.viewWithTag(1) as? UILabel {
            label.text = "\((indexPath.row + 1) * 10)分钟"
        }
        
        if let iv = cell.viewWithTag(2) as? UIImageView {
            if alarm.repeatInterval == (indexPath.row + 1) * 10 {
                iv.isHidden = false
            } else {
                iv.isHidden = true
            }
        }
        return cell
    }
}

extension AlarmIntervalViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        alarm.repeatInterval = (indexPath.row + 1) * 10
        navigationController?.popViewController(animated: true)
    }
}

