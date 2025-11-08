//
//  RunHistoryViewController.swift
//  LifeFit
//
//  Created by WuJunjie on 2018/11/18.
//  Copyright © 2018年 WuJunjie. All rights reserved.
//

import UIKit
import TJDWristbandSDK
import Toaster

class RunHistoryViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {
    var table = UITableView()
    var dataArray = [[RunModel]]()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let array = J_Select(RunModel.self).Recursively().list()
        dataArray.removeAll()
        
        let tempArray = array.filterDuplicates { (make) -> String in
            return make.timeStamp.dateFromSecond().stringFromYmd()
        }
        
        for model in tempArray {
            let temp = array.filter { (make) -> Bool in
                return make.timeStamp.dateFromSecond().stringFromYmd() == model.timeStamp.dateFromSecond().stringFromYmd()
            }
            dataArray.append(temp)
        }
        
        table.reloadData()
    }
    
    func setupViews() {
        view.addSubview(table)
        table.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        table.backgroundColor = UIColor.clear
        table.delegate = self
        table.dataSource = self
        table.register(RunHistoryTableViewCell.self, forCellReuseIdentifier: RunHistoryTableViewCell.wuClassName())
        table.contentInsetAdjustmentBehavior = .never
        table.tableFooterView = UIView()
        table.separatorColor = UIColor.brand
        table.separatorStyle = .singleLine
    }
    
    // MARK: - TableView
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataArray.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArray[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RunHistoryTableViewCell.wuClassName(), for: indexPath) as! RunHistoryTableViewCell
        cell.selectionStyle = .none

        let model = dataArray[indexPath.section][indexPath.row]
        cell.myModel = model
        
        if indexPath.row == dataArray.count - 1 {
            cell.separatorInset = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: kWuScreenWidth)
        }
        else {
            cell.separatorInset = UIEdgeInsets.init(top: 0, left: 16, bottom: 0, right: 16)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: "cell") ?? UITableViewHeaderFooterView()
        cell.contentView.backgroundColor = UIColor.brand.withAlphaComponent(0.5)
        let model = dataArray[section][0]
        cell.textLabel?.text = model.timeStamp.dateFromSecond().stringFromYmd()
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = dataArray[indexPath.section][indexPath.row]
        if model.type == 1 || model.type == 3 || model.type == 6 {
            Toast(text: "室内运动，没有地图可查").show()
        } else {
            let vc = HistoryMapViewController()
            vc.runModel = model
            vc.title = SportType(rawValue: model.type)?.title ?? ""
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    public func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return UIImage.init(named: "noDataImage")
    }
}

class RunHistoryTableViewCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    var collection: UICollectionView!
    var myModel = RunModel() {
        didSet {
            collection.reloadData()
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = UIColor.clear
        contentView.backgroundColor = UIColor.clear
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.itemSize = CGSize.init(width: kWuScreenWidth/3, height: 100)
        
        collection = UICollectionView.init(frame: .zero, collectionViewLayout: layout)
        collection.adhere(toSuperView: contentView).layout { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            }
            .config { (make) in
                make.backgroundColor = UIColor.white
                make.delegate = self
                make.dataSource = self
                make.register(VerticalLabelsCollectionCell.self, forCellWithReuseIdentifier: VerticalLabelsCollectionCell.wuClassName())
                make.contentInsetAdjustmentBehavior = .never
                make.isUserInteractionEnabled = false
        }
    }
    
    func stepAttr(with valueStr: String) -> NSMutableAttributedString {
        let unit: String
        if bleSelf.userInfo.unit == 1 {
            unit = " miles"
        } else {
            unit = " km"
        }
        
        let valueAttr = NSMutableAttributedString(string: valueStr, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 30), NSAttributedString.Key.foregroundColor: UIColor.black])
        let unitAttr = NSMutableAttributedString(string: unit, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.black])
        valueAttr.append(unitAttr)
        return valueAttr
    }
    
    private let titleArray = [NSLocalizedString("配速", comment: ""), NSLocalizedString("时长", comment: ""), NSLocalizedString("消耗", comment: "")]
    // MARK: - collectionView
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VerticalLabelsCollectionCell.wuClassName(), for: indexPath) as! VerticalLabelsCollectionCell
        cell.labels.nameLabel1.textColor = UIColor.black
        cell.labels.nameLabel1.font = UIFont.systemFont(ofSize: 24)
        if indexPath.row == 0 {
            let date = myModel.timeStamp.dateFromSecond()
            cell.labels.nameLabel.text = date.stringFromHms()
            cell.labels.nameLabel1.attributedText = self.stepAttr(with: (myModel.distance/1000).stringFloor(2))
            if bleSelf.userInfo.unit == 1 {
                cell.labels.nameLabel1.attributedText = self.stepAttr(with: (myModel.distance/1000).kmToMi().stringFloor(2))
            }
        }
        else {
            cell.labels.nameLabel.text = titleArray[indexPath.row - 1]
        }
        
        if indexPath.row == 1 {
            var speed = (myModel.distance > 0) ? Double(myModel.duration)/myModel.distance*1000 : 0
            speed = speed.miToKm()
            cell.labels.nameLabel1.text = Int(speed).stringSpeedFromSecond()
        }
        
        if indexPath.row == 2 {
            cell.labels.nameLabel1.text = Int(myModel.duration).stringHmsFromSecond()
        }
        
        if indexPath.row == 3 {
            cell.labels.nameLabel1.text = myModel.cal.stringFloor(2)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize.init(width: floor(collectionView.frame.size.width/4), height: floor(collectionView.frame.size.height))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    //MARK: End
}

extension Array {
    // 去重
    func filterDuplicates<E: Equatable>(_ filter: (Element) -> E) -> [Element] {
        var result = [Element]()
        for value in self {
            let key = filter(value)
            if !result.map({filter($0)}).contains(key) {
                result.append(value)
            }
        }
        return result
    }
}
