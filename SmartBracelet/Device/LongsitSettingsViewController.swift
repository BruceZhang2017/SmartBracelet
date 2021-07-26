//
//  LongsitSettingsViewController.swift
//  SmartBracelet
//
//  Created by anker on 2021/7/24.
//  Copyright © 2021 tjd. All rights reserved.
//

import UIKit

class LongsitSettingsViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "提醒间隔"
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
            timeLabel.text = "\(times[indexPath.row])分钟"
        }
        if let iv = cell.viewWithTag(2) as? UIImageView {
            let inter = bleSelf.longSitModel.interval
            iv.isHidden = !(inter == times[indexPath.row])
        }
        return cell
    }
    
    
}

extension LongsitSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        bleSelf.longSitModel.interval = times[indexPath.row]
        bleSelf.setLongSitForWristband(bleSelf.longSitModel)
        navigationController?.popViewController(animated: true)
    }
}

extension LongsitSettingsViewController {
    var times: [Int] {
        return [30, 60, 120, 180]
    }
}
