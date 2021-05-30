//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  AlarmRepeatViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/10/8.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit

class AlarmRepeatViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    var days: Int = 0
    var callbackBlock: ((Int) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "闹钟设置"
        tableView.tableFooterView = UIView()
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "nav_icon_edit"), style: .plain, target: self, action: #selector(submit(_:)))
    }
    
    @objc private func submit(_ sender: Any) {
        callbackBlock?(days)
        navigationController?.popViewController(animated: true)
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
        if indexPath.row == 0 {
            if days > 10000 {
                cell.accessoryView = UIImageView(image: UIImage(named: "content_icon_selecte"))
            } else {
                cell.accessoryView = nil
            }
        } else if indexPath.row == 1 {
            if (days % 10000) % 64 % 32 % 16 % 8 % 4 % 2 > 0 {
                cell.accessoryView = UIImageView(image: UIImage(named: "content_icon_selecte"))
            } else {
                cell.accessoryView = nil
            }
        } else if indexPath.row == 2 {
            if (days % 10000) % 64 % 32 % 16 % 8 % 4 >= 2 {
                cell.accessoryView = UIImageView(image: UIImage(named: "content_icon_selecte"))
            } else {
                cell.accessoryView = nil
            }
        } else if indexPath.row == 3 {
            if (days % 10000) % 64 % 32 % 16 % 8 >= 4 {
                cell.accessoryView = UIImageView(image: UIImage(named: "content_icon_selecte"))
            } else {
                cell.accessoryView = nil
            }
        } else if indexPath.row == 4 {
            if (days % 10000) % 64 % 32 % 16 >= 8 {
                cell.accessoryView = UIImageView(image: UIImage(named: "content_icon_selecte"))
            } else {
                cell.accessoryView = nil
            }
        } else if indexPath.row == 5 {
            if (days % 10000) % 64 % 32 >= 16 {
                cell.accessoryView = UIImageView(image: UIImage(named: "content_icon_selecte"))
            } else {
                cell.accessoryView = nil
            }
        } else if indexPath.row == 6 {
            if (days % 10000) % 64 >= 32 {
                cell.accessoryView = UIImageView(image: UIImage(named: "content_icon_selecte"))
            } else {
                cell.accessoryView = nil
            }
        } else {
            if (days % 10000) >= 64 {
                cell.accessoryView = UIImageView(image: UIImage(named: "content_icon_selecte"))
            } else {
                cell.accessoryView = nil
            }
        }
        return cell
    }
}

extension AlarmRepeatViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 0 {
            if days > 10000 {
                days = days - 10000
            } else {
                days = days + 10000
            }
        } else if indexPath.row == 1 {
            if (days % 10000) % 64 % 32 % 16 % 8 % 4 % 2 > 0 {
                days = days - 1
            } else {
                days = days + 1
            }
        } else if indexPath.row == 2 {
            if (days % 10000) % 64 % 32 % 16 % 8 % 4 >= 2 {
                days = days - 2
            } else {
                days = days + 2
            }
        } else if indexPath.row == 3 {
            if (days % 10000) % 64 % 32 % 16 % 8 >= 4 {
                days = days - 4
            } else {
                days = days + 4
            }
        } else if indexPath.row == 4 {
            if (days % 10000) % 64 % 32 % 16 >= 8 {
                days = days - 8
            } else {
                days = days + 8
            }
        } else if indexPath.row == 5 {
            if (days % 10000) % 64 % 32 >= 16 {
                days = days - 16
            } else {
                days = days + 16
            }
        } else if indexPath.row == 6 {
            if (days % 10000) % 64 >= 32 {
                days = days - 32
            } else {
                days = days + 32
            }
        } else {
            if (days % 10000) >= 64 {
                days = days - 64
            } else {
                days = days + 64
            }
        }
        tableView.reloadData()
    }
}

extension AlarmRepeatViewController {
    var titles: [String] {
        return ["仅此一次", "周一", "周二", "周三", "周四", "周五", "周六", "周日"]
    }
}
