//
//  RunViewController.swift
//  LefunHealth
//
//  Created by tjd on 2019/4/11.
//  Copyright © 2019 tjd. All rights reserved.
//

import UIKit

class RunViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource, HBLockSliderDelegate {
    var table = UITableView()
    var headView = SportHeadView()
    var footView = SportFootView()
    var gpsView = GpsView.init(frame: .zero, color: UIColor.Common.white)
    var gpsLabel = UILabel()
    var valueArray = [String]()
    var shimmerView = KRLShimmerView.init(frame: CGRect.init(x: 0, y: 180 + kWuNaviHeight, width: kWuScreenWidth, height: 120))
    var slider: HBLockSliderView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        topBarView.leftBtn.isHidden = true
        topBarView.backgroundColor = UIColor.Common.background
        topBarView.titleLabel.text = NSLocalizedString("运动", comment: "")
        
        shimmerView.isHidden = true
        shimmerView.shimmerColors = [UIColor.white, UIColor.black, UIColor.white]
        shimmerView.textColor = UIColor.white
        shimmerView.text = NSLocalizedString("向右滑动解锁", comment: "")
        shimmerView.backgroundColor = UIColor.Common.background
        view.addSubview(shimmerView)
        
        footView.leftBlock = { [unowned self] in
            self.slider = HBLockSliderView()
            self.slider.frame = CGRect.init(x: 30, y: 180 + kWuNaviHeight + self.shimmerView.height/2 - 15, width: kWuScreenWidth - 60, height: 30)
            self.slider.setThumbBegin(UIImage.init(named: "move_icon_lock"), finish: UIImage.init(named: "move_icon_lock"))
            self.slider.delegate = self
            self.slider.removeRoundCorners(true, border: true)
            self.slider.setColorForBackgroud(UIColor.clear, foreground: UIColor.clear, thumb: UIColor.clear, border: UIColor.clear, textColor: UIColor.clear)
            self.view.addSubview(self.slider)
            
            self.shimmerView.isHidden = !true
            self.shimmerView.createAnimation()
        }
        
        footView.rightBlock = { [unowned self] in
            let vc = MapViewController()
            vc.title = NSLocalizedString("地图", comment: "")
            self.pushViewController(vc)
        }
        
        footView.pauseBlock = { [unowned self] in
            gpsSelf.pauseRun()
            self.buttonPauseAnimation()
        }
        
        footView.startBlock = { [unowned self] in
            gpsSelf.restartRun()
            self.buttonStartAnimation()
        }
        
        footView.stopBlock = { [unowned self] in
            gpsSelf.stopRun()
            self.dismiss(animated: true, completion: nil)
        }
        
        headView.labels.nameLabel.text = NSLocalizedString("运动距离", comment: "")
        footView.pauseBtn.setBackgroundImage(UIImage.init(named: "小"), for: .normal)
        footView.leftBtn.setBackgroundImage(UIImage.init(named: "move_icon_lock"), for: .normal)
        footView.rightBtn.setBackgroundImage(UIImage.init(named: "move_icon_address"), for: .normal)
        
        gpsSelf.startRun()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        gpsSelf.timerBlock = { [unowned self] in
            self.headView.labels.nameLabel1.text = (gpsSelf.distance/1000).stringFloor(2) + "km"
            var speed = Double(gpsSelf.speed)
            if bleSelf.userInfo.unit == 1 {
                self.headView.labels.nameLabel1.text = (gpsSelf.distance/1000).kmToMi().stringFloor(2) + "miles"
                speed = speed.miToKm()
            }
            var altitude = 0.0
            if gpsSelf.pointArray.count >= 2 {
                let first = gpsSelf.pointArray.first!
                let last = gpsSelf.pointArray.last!
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
            self.valueArray = [Int(speed).stringSpeedFromSecond(), gpsSelf.seconds.stringHmsFromSecond(), gpsSelf.cal.stringFloor(2), altitudeStr]
            self.table.reloadData()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        gpsSelf.timerBlock = nil
    }
    
    override func setupViews() {
        headView.adhere(toSuperView: view).layout { (make) in
            make.top.equalTo(topBarView.snp.bottom)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(180)
            }
            .config { (make) in
                
        }
        footView.adhere(toSuperView: view).layout { (make) in
            make.top.equalTo(headView.snp.bottom)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(120)
            }
            .config { (make) in
                
        }
        
        table.adhere(toSuperView: view).layout { (make) in
            make.top.equalTo(footView.snp.bottom)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            }
            .config { (make) in
                make.bounces = false
                make.backgroundColor = UIColor.clear
                make.delegate = self
                make.dataSource = self
                make.register(SportTableViewCell.self, forCellReuseIdentifier: SportTableViewCell.wuClassName())
                if #available(iOS 11.0, *) {
                    make.contentInsetAdjustmentBehavior = .never
                }
//                footView.height = abs(kWuScreenHeight - 390 - kWuNaviHeight)
//                make.tableFooterView = footView
//                headView.height = 150
//                make.tableHeaderView = headView
                make.separatorStyle = .none
        }
        
        gpsView.adhere(toSuperView: topBarView.contentView).layout { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-2)
            make.width.equalTo(40)
            make.height.equalTo(9)
            }
            .config { (make) in
                
        }
        
        gpsLabel.adhere(toSuperView: topBarView.contentView).layout { (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(gpsView.snp.left)
            }
            .config { (make) in
                make.text = "GPS "
                make.textColor = UIColor.Common.text
                make.font = UIFont.Common.regular.withSize(12)
        }
    }
    
    override func setupNotify() {
        NotificationCenter.default.addObserver(self, selector: #selector(handle(_:)), name: WULocationManagerNotifyKey.locationDidUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handle(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    override func handle(_ notify: Notification) {
        if notify.name == WULocationManagerNotifyKey.locationDidUpdate {
            gpsView.signalState = WULocationManager.shared.signalState
        }
        
        if notify.name == UIApplication.willEnterForegroundNotification {
            if !self.shimmerView.isHidden {
                self.shimmerView.createAnimation()
            }
        }
    }
    
    func buttonStartAnimation() {
        UIView.animate(withDuration: 0.5, animations: {
            self.footView.startConstraint.update(offset: 0)
            self.footView.endConstraint.update(offset: 0)
            self.footView.layoutIfNeeded()
        }) { (_) in
            self.footView.pauseBtn.isHidden = false
            self.footView.startBtn.isHidden = true
            self.footView.stopBtn.isHidden = true
        }
    }
    
    func buttonPauseAnimation() {
        self.footView.pauseBtn.isHidden = true
        UIView.animate(withDuration: 0.5, animations: {
            self.footView.startBtn.isHidden = false
            self.footView.stopBtn.isHidden = false
            self.footView.startConstraint.update(offset: -50)
            self.footView.endConstraint.update(offset: 50)
            self.footView.layoutIfNeeded()
        }) { (_) in
            
        }
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
        return tableView.height
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func sliderMaxValue(_ slider: HBLockSliderView!) {
        self.slider.removeFromSuperview()
        self.slider = nil
        self.shimmerView.isHidden = true
        self.shimmerView.removreAnimation()
    }
}
