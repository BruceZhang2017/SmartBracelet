//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  DataRecordViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/8/18.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit

class DataRecordViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "数据记录"
        tableView.register(DataRecordReuseSectionHeadView.self, forHeaderFooterViewReuseIdentifier: "Header")
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

extension DataRecordViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return icons[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: .kCellIdentifier, for: indexPath) as! DataRecordTableViewCell
        cell.iconImageView.image = UIImage(named: icons[indexPath.section][indexPath.row])
        cell.titleLabel.text = titles[indexPath.section][indexPath.row]
        cell.valueLabel.text = "0"
        cell.unitLabel.text = units[indexPath.section][indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "Header") as! DataRecordReuseSectionHeadView
        view.label.text = sections[section]
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 68
    }
}

extension DataRecordViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension DataRecordViewController {
    var sections: [String] {
        return ["活动数据", "健康数据"]
    }
    
    var icons: [[String]] {
        return [["icon_steps", "icon_distance", "icon_calorie", "icon_running", "icon_mountainneering", "icon_cycling", "icon_hiking"], ["icon_hreartrate", "icon_weight", "icon_sleeping", "icon_pressure", "icon_ox"]]
    }
    
    var titles: [[String]] {
        return [["步数", "距离", "热量", "跑步", "登山", "骑车", "徒步"], ["心率", "体重", "睡眠", "血压", "血氧"]]
    }
    
    var units: [[String]] {
        return [["步", "公里", "千卡", "小时", "米", "公里", "公里"], ["次/分", "KG", "小时", "MMHG", "%"]]
    }
}
