//
//  SportViewController.swift
//  LefunHealth
//
//  Created by tjd on 2019/2/18.
//  Copyright © 2019年 tjd. All rights reserved.
//

import UIKit
import TJDWristbandSDK

class SportViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {
    var table = UITableView()
    var headView = SportHeadView()
    var footView = SportFootView()
    var dataArray = [RunModel]()
    var valueArray = [String]()
    
    var bgImageView = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        footView.leftBlock = { [unowned self] in
            let vc = RunHistoryViewController()
            vc.title = NSLocalizedString("运动历史", comment: "")
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
        footView.rightBlock = { [unowned self] in
            
        }
        
        footView.pauseBlock = { [unowned self] in
            WULocationManager.shared.requestAuthorization(authorized: {
                CutDownView.showCutDownView(with: 3) {
                    let vc = UINavigationController.init(rootViewController: RunViewController())
                    vc.modalPresentationStyle = .fullScreen
                    self.present(vc, animated: true, completion: {
                    })
                }
                
            }, denied: {
                let alert = UIAlertController.init(title: NSLocalizedString("定位权限设置", comment: ""), message: nil, preferredStyle: .alert)
                let action = UIAlertAction.init(title: NSLocalizedString("取消", comment: ""), style: .default, handler: { (_) in
                    self.dismiss(animated: true, completion: nil)
                })
                alert.addAction(action)
                let action1 = UIAlertAction.init(title: NSLocalizedString("确定", comment: ""), style: .default, handler: { (_) in
                    self.dismiss(animated: true, completion: nil)
                    let settings = URL.init(string: UIApplication.openSettingsURLString)!
                    UIApplication.shared.openURL(settings)
                    
                })
                alert.addAction(action1)
                DispatchQueue.main.async {
                    self.present(alert, animated: true, completion: nil)
                }
            })
        }
        
        setupViews()
    }
    
    func setupViews() {
        view.addSubview(bgImageView)
        bgImageView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.width.equalTo(bgImageView.snp.height).multipliedBy(1224.0/1173)
        }
        bgImageView.image = UIImage.init(named: "底部背景")
        
        view.addSubview(headView)
        headView.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(180)
        }
        
        view.addSubview(footView)
        footView.snp.makeConstraints { (make) in
            make.top.equalTo(headView.snp.bottom)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(120)
        }
        
        view.addSubview(table)
        table.snp.makeConstraints { (make) in
            make.top.equalTo(footView.snp.bottom)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()

        }
        table.bounces = false
        table.backgroundColor = UIColor.clear
        table.delegate = self
        table.dataSource = self
        table.register(SportTableViewCell.self, forCellReuseIdentifier: SportTableViewCell.wuClassName())
        if #available(iOS 11.0, *) {
            table.contentInsetAdjustmentBehavior = .never
        }
        table.separatorStyle = .none
    }
    
    func displayData() {
        dataArray = J_Select(RunModel.self).Recursively().Order(by: "distance").list()
        let model = dataArray.last ?? {
            let temp = RunModel()
            temp.timeStamp = Date().secondFromDate()
            return temp
        }()
        title = model.timeStamp.dateFromSecond().stringFromYmd()
        headView.labels.nameLabel1.text = (model.distance/1000).stringFloor(2) + "km"
        var speed = (model.distance > 0) ? Double(model.duration)/model.distance*1000 : 0
        if bleSelf.userInfo.unit == 1 {
            headView.labels.nameLabel1.text = (model.distance/1000).kmToMi().stringFloor(2) + "miles"
            speed = (model.distance > 0) ? (Double(model.duration)/model.distance*1000).miToKm() : 0
        }
        
        var altitude = 0.0
        if model.pointArray.count >= 2 {
            let first = model.pointArray.first!
            let last = model.pointArray.last!
            altitude = last.altitude - first.altitude
            if bleSelf.userInfo.unit == 1 {
                altitude = (altitude * 100).cmToFt()
            }
        }
        var altitudeStr = "+0"
        if altitude >= 0 {
            altitudeStr = "+" + altitude.stringFloor(2)
        }
        else {
            altitudeStr = altitude.stringFloor(2)
        }
        self.valueArray = [Int(speed).stringSpeedFromSecond(), model.duration.stringHmsFromSecond(), model.cal.stringFloor(2), altitudeStr]
        self.table.reloadData()
        
    }
    
    // MARK: - TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SportTableViewCell.wuClassName(), for: indexPath) as! SportTableViewCell
        if self.valueArray.count >= 4 {
            cell.valueArray = self.valueArray
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.frame.size.height
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

class SportHeadView: UIView {
    var bgView = UIView()
    var iconImageView = UIImageView()
    var nameLabel = UILabel()
    var labels = VerticalLabels()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(bgView)
        bgView.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview().inset(20)
            make.left.right.equalToSuperview().inset(50)
        }
        bgView.layer.cornerRadius = 20
        bgView.layer.borderWidth = 2
        
        bgView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview().dividedBy(2)
        }
        iconImageView.image = UIImage.init(named: "小")
        iconImageView.setContentHuggingPriority(UILayoutPriority.required, for: NSLayoutConstraint.Axis.horizontal)
        iconImageView.setContentCompressionResistancePriority(UILayoutPriority.required, for: NSLayoutConstraint.Axis.horizontal)
        
        bgView.addSubview(labels)
        labels.snp.makeConstraints { (make) in
            make.left.equalTo(iconImageView.snp.right)
            make.centerY.equalToSuperview()
            make.height.equalToSuperview()
            make.right.equalToSuperview()
        }
        labels.nameLabel.text = NSLocalizedString("最佳记录", comment: "")
        labels.nameLabel1.text = "0.00km"
        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

import SnapKit

class SportFootView: UIView {
    var pauseBtn = UIButton()
    var startBtn = UIButton()
    var stopBtn = UIButton()
    var leftView = UIView()
    var rightView = UIView()
    var leftBtn = UIButton()
    var rightBtn = UIButton()
    var startConstraint: Constraint!
    var endConstraint: Constraint!
    
    var pauseBlock: WUOkHandler?
    var startBlock: WUOkHandler?
    var stopBlock: WUOkHandler?
    var leftBlock: WUOkHandler?
    var rightBlock: WUOkHandler?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        pauseBtn.adhere(toSuperView: self).layout { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(67)
            }
            .config { (make) in
                make.setBackgroundImage(UIImage.init(named: "暂停"), for: .normal)
                make.addTarget(self, action: #selector(pressBtn(_:)), for: .touchUpInside)
        }
        
        startBtn.adhere(toSuperView: self).layout { (make) in
            startConstraint = make.centerX.equalToSuperview().constraint
            make.centerY.equalTo(pauseBtn)
            make.width.height.equalTo(67)
            }
            .config { (make) in
                make.setBackgroundImage(UIImage.init(named: "暂停"), for: .normal)
                make.addTarget(self, action: #selector(pressBtn(_:)), for: .touchUpInside)
                make.isHidden = true
        }
        
        stopBtn.adhere(toSuperView: self).layout { (make) in
            endConstraint = make.centerX.equalToSuperview().constraint
            make.centerY.equalTo(pauseBtn)
            make.width.height.equalTo(67)
            }
            .config { (make) in
                make.setBackgroundImage(UIImage.init(named: "move_icon_stop"), for: .normal)
                make.addTarget(self, action: #selector(pressBtn(_:)), for: .touchUpInside)
                make.isHidden = true
        }
        
        leftView.adhere(toSuperView: self).layout { (make) in
            make.centerX.equalTo(self.snp.left)
            make.centerY.equalToSuperview()
            make.height.equalTo(35)
            make.width.equalTo(150)
            }
            .config { (make) in
                make.layer.cornerRadius = 15
                make.clipsToBounds = true
        }
        
        leftBtn.adhere(toSuperView: leftView).layout { (make) in
            make.right.equalToSuperview().offset(-10)
            make.width.height.equalTo(25)
            make.centerY.equalToSuperview()
            }
            .config { (make) in
                make.setBackgroundImage(UIImage.init(named: "move_icon_clock"), for: .normal)
                make.addTarget(self, action: #selector(pressBtn(_:)), for: .touchUpInside)
        }
        
        rightView.adhere(toSuperView: self).layout { (make) in
            make.centerX.equalTo(self.snp.right)
            make.centerY.equalToSuperview()
            make.height.equalTo(35)
            make.width.equalTo(150)
            }
            .config { (make) in
                make.layer.cornerRadius = 15
                make.clipsToBounds = true
        }
        
        rightBtn.adhere(toSuperView: rightView).layout { (make) in
            make.left.equalToSuperview().offset(10)
            make.width.height.equalTo(25)
            make.centerY.equalToSuperview()
            }
            .config { (make) in
                make.setBackgroundImage(UIImage.init(named: "move_icon_setup"), for: .normal)
                make.addTarget(self, action: #selector(pressBtn(_:)), for: .touchUpInside)
        }
        
    }
    
    @objc func pressBtn(_ sender: UIButton) {
        if sender == pauseBtn {
            pauseBlock?()
        }
        
        if sender == startBtn {
            startBlock?()
        }
        
        if sender == stopBtn {
            stopBlock?()
        }
        
        if sender == leftBtn {
            leftBlock?()
        }
        
        if sender == rightBtn {
            rightBlock?()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class SportTableViewCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    var collection: UICollectionView!
    var valueArray = [0.stringSpeedFromSecond(), 0.stringHmsFromSecond(), 0.stringFloor(2), "+0"] {
        didSet {
            collection.reloadData()
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = UIColor.clear
        contentView.backgroundColor = UIColor.clear
        selectionStyle = .none
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.itemSize = CGSize.init(width: kWuScreenWidth/3, height: 100)
        
        collection = UICollectionView.init(frame: .zero, collectionViewLayout: layout)
        collection.adhere(toSuperView: self).layout { (make) in
            make.top.bottom.equalToSuperview().inset(10)
            make.left.right.equalToSuperview().inset(10)
            }
            .config { (make) in
                make.backgroundColor = UIColor.clear
                make.delegate = self
                make.dataSource = self
                make.register(SportCollectionViewCell.self, forCellWithReuseIdentifier: SportCollectionViewCell.wuClassName())
                if #available(iOS 11.0, *) {
                    make.contentInsetAdjustmentBehavior = .never
                }
        }
    }
    
    // MARK: - collectionView
    private let titleArray = [NSLocalizedString("配速", comment: ""), NSLocalizedString("时长", comment: ""), NSLocalizedString("消耗", comment: ""), NSLocalizedString("海拔变化", comment: "")]
    private let imageArray = ["move_icon_km", "move_icon_time", "move_icon_calories", "move_icon_m"]
    private let unitArray = ["(min/km)", "(hr:min:sec)", "(cal)", "(m)"]
    private let unitArray1 = ["(min/miles)", "(hr:min:sec)", "(hr:min:sec)", "(feet)"]
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return titleArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SportCollectionViewCell.wuClassName(), for: indexPath) as! SportCollectionViewCell
        
        cell.labels.nameLabel.text = valueArray[indexPath.row]
        
//        let unitArray = ["min/km", "h:m:s", "cal", "m"]
//         + " " + unitArray[indexPath.row]
        cell.labels.nameLabel1.text = titleArray[indexPath.row]
//        cell.iconImageView.image = UIImage.init(named: imageArray[indexPath.row])
        
        cell.labels.nameLabel2.text = unitArray[indexPath.row]
        if bleSelf.userInfo.unit == 1 {
            cell.labels.nameLabel2.text = unitArray1[indexPath.row]
        }
        cell.labels.nameLabel.textAlignment = .center
        cell.labels.nameLabel1.textAlignment = .center
        cell.labels.nameLabel2.textAlignment = .center
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize.init(width: floor(collectionView.frame.size.width/2) - 5, height: floor(collectionView.frame.size.height/2) - 5)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class SportCollectionViewCell: UICollectionViewCell {
    var bgView = UIView()
    var iconImageView = UIImageView()
    var lineView = UIView()
    var labels = VerticalLabels1()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.clear
        bgView.adhere(toSuperView: contentView).layout { (make) in
            make.edges.equalToSuperview()
            }
            .config { (make) in
                make.layer.cornerRadius = 10
                make.clipsToBounds = true
        }
        
        iconImageView.adhere(toSuperView: bgView).layout { (make) in
            make.left.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-20)
            }
            .config { (make) in
                make.image = UIImage.init(named: "home_icon_heart")
                make.isHidden = true
        }
        
        labels.adhere(toSuperView: bgView).layout { (make) in
            make.left.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
            make.height.equalToSuperview()
            make.right.equalToSuperview()
            }
            .config { (make) in
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
