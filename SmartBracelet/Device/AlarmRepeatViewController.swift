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
    var weekday: Int = 0
    var alarmCycle: Int = 0
    var callbackBlock: ((Int) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "device_alarm_settings".localized()
        tableView.tableFooterView = UIView()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "mine_save".localized(), style: .plain, target: self, action: #selector(submit(_:)))
    }
    
    @objc private func submit(_ sender: Any) {
        if isXGZT {
            callbackBlock?(alarmCycle)
        } else {
            callbackBlock?(weekday)
        }
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
        if isXGZT {
            if indexPath.row == 0 {
                if (alarmCycle & 0x01) > 0 {
                    cell.accessoryView = UIImageView(image: UIImage(named: "content_icon_select"))
                } else {
                    cell.accessoryView = nil
                }
            } else if indexPath.row == 1 {
                if ((alarmCycle >> 1) & 0x01) > 0 {
                    cell.accessoryView = UIImageView(image: UIImage(named: "content_icon_select"))
                } else {
                    cell.accessoryView = nil
                }
            } else if indexPath.row == 2 {
                if ((alarmCycle >> 2) & 0x01) > 0 {
                    cell.accessoryView = UIImageView(image: UIImage(named: "content_icon_select"))
                } else {
                    cell.accessoryView = nil
                }
            } else if indexPath.row == 3 {
                if ((alarmCycle >> 3) & 0x01) > 0 {
                    cell.accessoryView = UIImageView(image: UIImage(named: "content_icon_select"))
                } else {
                    cell.accessoryView = nil
                }
            } else if indexPath.row == 4 {
                if ((alarmCycle >> 4) & 0x01) > 0 {
                    cell.accessoryView = UIImageView(image: UIImage(named: "content_icon_select"))
                } else {
                    cell.accessoryView = nil
                }
            } else if indexPath.row == 5 {
                if ((alarmCycle >> 5) & 0x01) > 0 {
                    cell.accessoryView = UIImageView(image: UIImage(named: "content_icon_select"))
                } else {
                    cell.accessoryView = nil
                }
            } else {
                if ((alarmCycle >> 6) & 0x01) > 0 {
                    cell.accessoryView = UIImageView(image: UIImage(named: "content_icon_select"))
                } else {
                    cell.accessoryView = nil
                }
            }
        } else {
            if indexPath.row == 0 {
                if ((weekday >> 1) & 0x01) > 0 {
                    cell.accessoryView = UIImageView(image: UIImage(named: "content_icon_select"))
                } else {
                    cell.accessoryView = nil
                }
            } else if indexPath.row == 1 {
                if ((weekday >> 2) & 0x01) > 0 {
                    cell.accessoryView = UIImageView(image: UIImage(named: "content_icon_select"))
                } else {
                    cell.accessoryView = nil
                }
            } else if indexPath.row == 2 {
                if ((weekday >> 3) & 0x01) > 0 {
                    cell.accessoryView = UIImageView(image: UIImage(named: "content_icon_select"))
                } else {
                    cell.accessoryView = nil
                }
            } else if indexPath.row == 3 {
                if ((weekday >> 4) & 0x01) > 0 {
                    cell.accessoryView = UIImageView(image: UIImage(named: "content_icon_select"))
                } else {
                    cell.accessoryView = nil
                }
            } else if indexPath.row == 4 {
                if ((weekday >> 5) & 0x01) > 0 {
                    cell.accessoryView = UIImageView(image: UIImage(named: "content_icon_select"))
                } else {
                    cell.accessoryView = nil
                }
            } else if indexPath.row == 5 {
                if ((weekday >> 6) & 0x01) > 0 {
                    cell.accessoryView = UIImageView(image: UIImage(named: "content_icon_select"))
                } else {
                    cell.accessoryView = nil
                }
            } else {
                if (weekday & 0x01) > 0 {
                    cell.accessoryView = UIImageView(image: UIImage(named: "content_icon_select"))
                } else {
                    cell.accessoryView = nil
                }
            }
        }
        return cell
    }
}

extension AlarmRepeatViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if isXGZT {
            if indexPath.row == 0 {
                if (alarmCycle & 0x01) > 0 {
                    alarmCycle = alarmCycle - 1
                } else {
                    alarmCycle = alarmCycle + 1
                }
            } else if indexPath.row == 1 {
                if ((alarmCycle >> 1) & 0x01) > 0 {
                    alarmCycle = alarmCycle - 2
                } else {
                    alarmCycle = alarmCycle + 2
                }
            } else if indexPath.row == 2 {
                if ((alarmCycle >> 2) & 0x01) > 0 {
                    alarmCycle = alarmCycle - 4
                } else {
                    alarmCycle = alarmCycle + 4
                }
            } else if indexPath.row == 3 {
                if ((alarmCycle >> 3) & 0x01) > 0 {
                    alarmCycle = alarmCycle - 8
                } else {
                    alarmCycle = alarmCycle + 8
                }
            } else if indexPath.row == 4 {
                if ((alarmCycle >> 4) & 0x01) > 0 {
                    alarmCycle = alarmCycle - 16
                } else {
                    alarmCycle = alarmCycle + 16
                }
            } else if indexPath.row == 5 {
                if ((alarmCycle >> 5) & 0x01) > 0 {
                    alarmCycle = alarmCycle - 32
                } else {
                    alarmCycle = alarmCycle + 32
                }
            } else {
                if ((alarmCycle >> 6) & 0x01) > 0 {
                    alarmCycle = alarmCycle - 64
                } else {
                    alarmCycle = alarmCycle + 64
                }
            }
        } else {
            if indexPath.row == 0 {
                if ((weekday >> 1) & 0x01) > 0 {
                    weekday = weekday - 2
                } else {
                    weekday = weekday + 2
                }
            } else if indexPath.row == 1 {
                if ((weekday >> 2) & 0x01) > 0 {
                    weekday = weekday - 4
                } else {
                    weekday = weekday + 4
                }
            } else if indexPath.row == 2 {
                if ((weekday >> 3) & 0x01) > 0 {
                    weekday = weekday - 8
                } else {
                    weekday = weekday + 8
                }
            } else if indexPath.row == 3 {
                if ((weekday >> 4) & 0x01) > 0 {
                    weekday = weekday - 16
                } else {
                    weekday = weekday + 16
                }
            } else if indexPath.row == 4 {
                if ((weekday >> 5) & 0x01) > 0 {
                    weekday = weekday - 32
                } else {
                    weekday = weekday + 32
                }
            } else if indexPath.row == 5 {
                if ((weekday >> 6) & 0x01) > 0 {
                    weekday = weekday - 64
                } else {
                    weekday = weekday + 64
                }
            } else {
                if (weekday & 0x01) > 0 {
                    weekday = weekday - 1
                } else {
                    weekday = weekday + 1
                }
            }
        }
        tableView.reloadData()
    }
}

extension AlarmRepeatViewController {
    var titles: [String] {
        return ["mine_monday".localized(), "mine_satuday".localized(), "mine_wednesday".localized(), "mine_thursday".localized(), "mine_friday".localized(), "mine_saturday".localized(), "mine_sunday".localized()]
    }
}
