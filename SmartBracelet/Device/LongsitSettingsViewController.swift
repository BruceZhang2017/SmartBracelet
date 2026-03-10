//
//  LongsitSettingsViewController.swift
//  SmartBracelet
//
//  Created by bruce on 2021/7/24.
//  Copyright © 2021 tjd. All rights reserved.
//

import UIKit
import WatchProtocolSDK

class LongsitSettingsViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    var flag = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "reminder_interval".localized()
        tableView.backgroundColor = UIColor.clear
        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension LongsitSettingsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return times.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        if let timeLabel = cell.viewWithTag(1) as? UILabel {
            timeLabel.text = "\(times[indexPath.row])\("minute".localized())"
            timeLabel.textColor = UIColor.text_secondary
            timeLabel.font = UIFont.body1()
        }
        if let iv = cell.viewWithTag(2) as? UIImageView {
            if flag == 1 {
                let inter = isXGZT ? (XGZTBlueToothManager.shared.device?.drinkWater?.period ?? 0) : bleSelf.drinkModel.interval
                iv.isHidden = !(inter == times[indexPath.row])
            } else {
                let inter = isXGZT ? (XGZTBlueToothManager.shared.device?.longsit?.period ?? 0) : bleSelf.longSitModel.interval
                iv.isHidden = !(inter == times[indexPath.row])
            }
        }
        return cell
    }
    
    
}

extension LongsitSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if flag == 1 {
            if isXGZT {
                guard var drinkWater = XGZTBlueToothManager.shared.device?.drinkWater else {
                    return
                }
                drinkWater.period = times[indexPath.row]
                XGZTCommand.setReminderInfo(response: drinkWater)
                XGZTBlueToothManager.shared.device?.drinkWater = drinkWater
            } else {
                bleSelf.drinkModel.interval = times[indexPath.row]
                bleSelf.setDrinkForWristband(bleSelf.drinkModel)
            }
            
        } else {
            if isXGZT {
                guard var longsit = XGZTBlueToothManager.shared.device?.longsit else {
                    return
                }
                longsit.period = times[indexPath.row]
                XGZTCommand.setReminderInfo(response: longsit)
                XGZTBlueToothManager.shared.device?.longsit = longsit
            } else {
                bleSelf.longSitModel.interval = times[indexPath.row]
                bleSelf.setLongSitForWristband(bleSelf.longSitModel)
            }
        }
        navigationController?.popViewController(animated: true)
    }
}

extension LongsitSettingsViewController {
    var times: [Int] {
        return [10, 30, 60, 120, 180]
    }
}
