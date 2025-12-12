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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        footView.leftBlock = { [unowned self] in
            let vc = RunHistoryViewController()
            vc.title = "sport_history".localized()
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
                let alert = UIAlertController.init(title: "location_permission_settings".localized(), message: nil, preferredStyle: .alert)
                let action = UIAlertAction.init(title: "Cancel".localized(), style: .default, handler: { (_) in
                    self.dismiss(animated: true, completion: nil)
                })
                alert.addAction(action)
                let action1 = UIAlertAction.init(title: "mine_confirm".localized(), style: .default, handler: { (_) in
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
        
        view.addSubview(headView)
        headView.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(180)
        }
        
        view.addSubview(footView)
        footView.snp.makeConstraints { (make) in
            make.top.equalTo(headView.snp.bottom).offset(10)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(100)
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
        headView.labels.nameLabel1.text = (model.distance/1000).stringFloor(2)
        headView.labels.nameLabel.text = "health_walk_unit".localized()
        var speed = (model.distance > 0) ? Double(model.duration)/model.distance*1000 : 0
        if bleSelf.userInfo.unit == 1 {
            headView.labels.nameLabel1.text = (model.distance/1000).kmToMi().stringFloor(2)
            headView.labels.nameLabel.text = "mile".localized()
            speed = (model.distance > 0) ? (Double(model.duration)/model.distance*1000).miToKm() : 0
        }
        
        self.valueArray = [Int(speed).stringSpeedFromSecond(), model.duration.stringHmsFromSecond(), model.cal.stringFloor(2)]
        self.table.reloadData()
        
    }
    
    // MARK: - TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SportTableViewCell.wuClassName(), for: indexPath) as! SportTableViewCell
        if self.valueArray.count >= 3 {
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
    var labels = VerticalLabels()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(bgView)
        bgView.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview().inset(20)
            make.left.right.equalToSuperview().inset(50)
        }

        bgView.addSubview(labels)
        labels.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalToSuperview()
            make.right.equalToSuperview()
        }
        labels.nameLabel.text = "0.00"
        labels.nameLabel1.text = "health_walk_unit".localized()
        
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
            make.width.height.equalTo(100)
            }
            .config { (make) in
                make.backgroundColor = UIColor.systemOrange
                make.layer.cornerRadius = 50
                make.clipsToBounds = true
                make.tintColor = .white
                make.setImage(UIImage(systemName: "pause.fill")?.withRenderingMode(.alwaysTemplate), for: .normal)
                make.addTarget(self, action: #selector(pressBtn(_:)), for: .touchUpInside)
        }

        startBtn.adhere(toSuperView: self).layout { (make) in
            startConstraint = make.centerX.equalToSuperview().constraint
            make.centerY.equalTo(pauseBtn)
            make.width.height.equalTo(100)
            }
            .config { (make) in
                make.backgroundColor = UIColor.systemGreen
                make.layer.cornerRadius = 50
                make.clipsToBounds = true
                make.tintColor = .white
                make.setImage(UIImage(systemName: "play.fill")?.withRenderingMode(.alwaysTemplate), for: .normal)
                make.addTarget(self, action: #selector(pressBtn(_:)), for: .touchUpInside)
                make.isHidden = true
        }

        stopBtn.adhere(toSuperView: self).layout { (make) in
            endConstraint = make.centerX.equalToSuperview().constraint
            make.centerY.equalTo(pauseBtn)
            make.width.height.equalTo(100)
            }
            .config { (make) in
                make.backgroundColor = UIColor.systemRed
                make.layer.cornerRadius = 50
                make.clipsToBounds = true
                make.tintColor = .white
                make.setImage(UIImage(systemName: "stop.fill")?.withRenderingMode(.alwaysTemplate), for: .normal)
                make.addTarget(self, action: #selector(pressBtn(_:)), for: .touchUpInside)
                make.isHidden = true
        }
        
        leftBtn.adhere(toSuperView: self).layout { (make) in
            make.left.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(70)
            }
            .config { (make) in
                make.backgroundColor = UIColor.systemBlue
                make.layer.cornerRadius = 35
                make.clipsToBounds = true
                make.tintColor = .white
                make.setImage(UIImage(named: "unlock")?.withRenderingMode(.alwaysTemplate), for: .normal)
                make.addTarget(self, action: #selector(pressBtn(_:)), for: .touchUpInside)
        }

        rightBtn.adhere(toSuperView: self).layout { (make) in
            make.right.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(70)
            }
            .config { (make) in
                make.backgroundColor = UIColor.systemBlue
                make.layer.cornerRadius = 35
                make.clipsToBounds = true
                make.tintColor = .white
                make.setImage(UIImage(systemName: "gearshape.fill")?.withRenderingMode(.alwaysTemplate), for: .normal)
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
    var valueArray = [0.stringSpeedFromSecond(), 0.stringHmsFromSecond(), 0.stringFloor(2)] {
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
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
        collection = UICollectionView.init(frame: .zero, collectionViewLayout: layout)
        collection.adhere(toSuperView: self).layout { (make) in
            make.top.bottom.equalToSuperview().inset(10)
            make.left.right.equalToSuperview().inset(10)
            }
            .config { (make) in
                make.backgroundColor = UIColor.clear
                make.delegate = self
                make.dataSource = self
                make.isScrollEnabled = false
                make.register(SportCollectionViewCell.self, forCellWithReuseIdentifier: SportCollectionViewCell.wuClassName())
                if #available(iOS 11.0, *) {
                    make.contentInsetAdjustmentBehavior = .never
                }
        }
    }
    
    // MARK: - collectionView
    private let titleArray = ["sport_pace".localized(), "sport_duration".localized(), "consumption".localized()]
    private let imageArray = ["move_icon_km", "move_icon_time", "move_icon_calories"]
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SportCollectionViewCell.wuClassName(), for: indexPath) as! SportCollectionViewCell

        cell.labels.nameLabel.text = valueArray[indexPath.row]

//        let unitArray = ["min/km", "h:m:s", "cal", "m"]
//         + " " + unitArray[indexPath.row]
        cell.labels.nameLabel1.text = titleArray[indexPath.row]

        cell.labels.nameLabel.textAlignment = .center
        cell.labels.nameLabel1.textAlignment = .center

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // 计算宽度：(总宽度 - 左右边距 - 间隔) / 3
        let totalWidth = collectionView.frame.size.width
        let horizontalInsets: CGFloat = 20 // 左右各10
        let spacing: CGFloat = 20 // 两个间隔，每个10
        let itemWidth = floor((totalWidth - horizontalInsets - spacing) / 3)
        let itemHeight = collectionView.frame.size.height - 20 // 上下各10
        return CGSize(width: itemWidth, height: itemHeight)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class SportCollectionViewCell: UICollectionViewCell {
    var bgView = UIView()
    var lineView = UIView()
    var labels = VerticalLabels1()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.clear
        bgView.adhere(toSuperView: contentView).layout { (make) in
            make.edges.equalToSuperview()
            }
            .config { (make) in
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
