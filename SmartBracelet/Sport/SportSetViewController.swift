//
//  SportSetViewController.swift
//  LefunHealth
//
//  Created by tjd on 2019/4/12.
//  Copyright © 2019 tjd. All rights reserved.
//

import UIKit

var countDown = "3"

class SportSetViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {
    var table = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
     func setupViews() {
        table.adhere(toSuperView: view).layout { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            }
            .config { (make) in
                make.backgroundColor = UIColor.clear
                make.delegate = self
                make.dataSource = self
//                make.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.wuClassName())
                if #available(iOS 11.0, *) {
                    make.contentInsetAdjustmentBehavior = .never
                }
                make.tableFooterView = UIView()
                make.separatorInset = .zero
        }
    }

    // MARK: - TableView
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.wuClassName()) ?? UITableViewCell.init(style: UITableViewCell.CellStyle.value1, reuseIdentifier: UITableViewCell.wuClassName())
        cell.backgroundColor = UIColor.clear
        cell.contentView.backgroundColor = UIColor.clear
        cell.selectionStyle = .none
        cell.imageView?.image = UIImage.init(named: "movement_icon_funnel")?.add(UIColor.black)
        cell.textLabel?.text = "sport_countdown_settings".localized()
        cell.detailTextLabel?.text = "\(countDown)s"
        cell.textLabel?.textColor = UIColor.black
        cell.detailTextLabel?.textColor = UIColor.black
        cell.accessoryType = .disclosureIndicator

        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let counts = [3, 5, 10]

        let defaultCount = counts.map { (temp) -> String in
            return temp.description
        }

        let defaultIndex = defaultCount.firstIndex(of: countDown.description) ?? 0
        UsefulPickerView.showSingleColPicker("sport_countdown_settings".localized(), data: defaultCount, defaultSelectedIndex: defaultIndex) { (index, value) in
            countDown = defaultCount[index]
            UserDefaults.standard.set(countDown, forKey: "countDown")
            self.table.reloadData()
        }
    }
}
