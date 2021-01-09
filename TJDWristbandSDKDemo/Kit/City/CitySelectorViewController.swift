//
//  CitySelectorViewController.swift
//  SoolyWeather
//
//  Created by SoolyChristina on 2017/3/9.
//  Copyright © 2017年 SoolyChristina. All rights reserved.
//

import UIKit

private let nomalCell = "nomalCell"
private let hotCityCell = "hotCityCell"
private let recentCell = "rencentCityCell"
private let currentCell = "currentCityCell"

class CitySelectorViewController: BaseViewController {
    weak var delegate: CitySelectorVCDelegate?
    /// 表格
    lazy var tableView: UITableView = UITableView(frame: self.view.frame, style: .plain)

    /// 懒加载 城市数据
    lazy var cityDic: [String: [String]] = { () -> [String : [String]] in
        let path = Bundle.main.path(forResource: "cities.plist", ofType: nil)
        let dic = NSDictionary(contentsOfFile: path ?? "") as? [String: [String]]
        return dic ?? [:]
        }()
    /// 懒加载 热门城市
    lazy var hotCities: [String] = {
        let path = Bundle.main.path(forResource: "hotCities.plist", ofType: nil)
        let array = NSArray(contentsOfFile: path ?? "") as? [String]
        return array ?? []
    }()
    /// 懒加载 标题数组
    lazy var titleArray: [String] = { () -> [String] in
       var array = [String]()
        for str in self.cityDic.keys {
            array.append(str)
        }
        // 标题排序
        array.sort()
        array.insert("当前城市", at: 0)
        return array
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        // 设置导航条
        self.title = "选择地区"
        // 设置tableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: nomalCell)
        tableView.register(CurrentCityTableViewCell.self, forCellReuseIdentifier: currentCell)
        view.addSubview(tableView)
    }
}

// MARK: tableView 代理方法、数据源方法
extension CitySelectorViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return titleArray.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section > 0 {
            let key = titleArray[section]
            return cityDic[key]!.count - 3
        }
        return 1
    }
    
    // MARK: 创建cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: currentCell, for: indexPath)
            return cell
            
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: nomalCell, for: indexPath)
            let key = titleArray[indexPath.section]
            cell.textLabel?.text = cityDic[key]![indexPath.row]
            return cell
        }
    }
    // MARK: 点击cell
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let cell = tableView.cellForRow(at: indexPath)
        let city = cell?.textLabel?.text ?? ""
        print("点击了 \(city)")
        delegate?.callback(city)
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: 右边索引
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return titleArray
    }
    
    // MARK: section头视图
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 38))
        let title = UILabel(frame: CGRect(x: 15, y: 5, width: ScreenWidth - 15, height: 28))
        var titleArr = titleArray
        titleArr[0] = "当前城市"
        title.text = titleArr[section]
        title.font = UIFont.boldSystemFont(ofSize: 18)
        view.addSubview(title)
        view.backgroundColor = UIColor.white
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 38
    }
    
    // MARK: row高度
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 36 + 2 * 15
        } else {
            return 42
        }
    }
}

protocol CitySelectorVCDelegate: NSObjectProtocol {
    func callback(_ city: String)
}
