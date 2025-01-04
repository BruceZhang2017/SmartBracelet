//
//  RunHistoryViewController.swift
//  LifeFit
//
//  Created by WuJunjie on 2018/11/18.
//  Copyright © 2018年 WuJunjie. All rights reserved.
//

import UIKit

class RunHistoryViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {
    var table = UITableView()
    var dataArray = [[RunModel]]()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        topBarView.backgroundColor = UIColor.Common.background
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
    
    override func setupViews() {
        table.adhere(toSuperView: view).layout { (make) in
            make.top.equalTo(topBarView.snp.bottom)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            }
            .config { (make) in
                make.backgroundColor = UIColor.clear
                make.delegate = self
                make.dataSource = self
                make.emptyDataSetSource = self
                make.emptyDataSetDelegate = self
                make.register(RunHistoryTableViewCell.self, forCellReuseIdentifier: RunHistoryTableViewCell.wuClassName())
                if #available(iOS 11.0, *) {
                    make.contentInsetAdjustmentBehavior = .never
                }
                make.tableFooterView = UIView()
                make.separatorColor = UIColor.Common.background_bottom
                
        }
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
        return 70
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 35
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: "cell") ?? UITableViewHeaderFooterView()
        cell.contentView.backgroundColor = UIColor.Common.background_bottom
        let model = dataArray[section][0]
        cell.textLabel?.text = model.timeStamp.dateFromSecond().stringFromYmd()
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = HistoryMapViewController()
        vc.title = NSLocalizedString("地图", comment: "")
        let model = dataArray[indexPath.section][indexPath.row]
        vc.runModel = model
        self.pushViewController(vc)
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
        backgroundColor = UIColor.Common.background
        contentView.backgroundColor = UIColor.Common.background
        
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
                make.backgroundColor = UIColor.clear
                make.delegate = self
                make.dataSource = self
                make.register(VerticalLabelsCollectionCell.self, forCellWithReuseIdentifier: VerticalLabelsCollectionCell.wuClassName())
                if #available(iOS 11.0, *) {
                    make.contentInsetAdjustmentBehavior = .never
                }
                make.isUserInteractionEnabled = false
        }
    }
    
    func stepAtrr(with valueStr: String) -> NSMutableAttributedString {
        var unit = " " + "km"
        if bleSelf.userInfo.unit == 1 {
            unit = " " + "miles"
        }
        
        let valueAttr = valueStr.setupAttribute([NSAttributedString.Key.font : UIFont.Default.akFont.withSize(30), NSAttributedString.Key.foregroundColor: UIColor.Common.navigation])
        
        let unitAttr = unit.setupAttribute([NSAttributedString.Key.font : UIFont.Common.regular.withSize(10), NSAttributedString.Key.foregroundColor: UIColor.Common.navigation])
        return valueAttr + unitAttr
        
    }
    
    private let titleArray = [NSLocalizedString("配速", comment: ""), NSLocalizedString("时长", comment: ""), NSLocalizedString("消耗", comment: "")]
    // MARK: - collectionView
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VerticalLabelsCollectionCell.wuClassName(), for: indexPath) as! VerticalLabelsCollectionCell
        cell.labels.nameLabel1.textColor = UIColor.Common.navigation
        cell.labels.nameLabel1.font = UIFont.Default.akFont.withSize(24)
        if indexPath.row == 0 {
            let date = myModel.timeStamp.dateFromSecond()
            cell.labels.nameLabel.text = date.stringFromHms()
            cell.labels.nameLabel1.attributedText = self.stepAtrr(with: (myModel.distance/1000).stringFloor(2))
            if bleSelf.userInfo.unit == 1 {
                cell.labels.nameLabel1.attributedText = self.stepAtrr(with: (myModel.distance/1000).kmToMi().stringFloor(2))
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
        return CGSize.init(width: floor(collectionView.width/4), height: floor(collectionView.height))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    //MARK: End
}
