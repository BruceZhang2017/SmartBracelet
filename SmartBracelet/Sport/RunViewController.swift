//
//  RunViewController.swift
//  LefunHealth
//
//  Created by tjd on 2019/4/11.
//  Copyright © 2019 tjd. All rights reserved.
//

import UIKit
import TJDWristbandSDK

class RunViewController: BaseViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, HBLockSliderDelegate {
    var collection: UICollectionView!
    var headView = SportHeadView()
    var footView = SportFootView()
    var gpsView = GpsView.init(frame: .zero, color: UIColor.white)
    var gpsLabel = UILabel()
    var valueArray = [String]()
    lazy var shimmerView: KRLShimmerView = {
        let view = KRLShimmerView(frame: .zero)
        return view
    }()
    var slider: HBLockSliderView!
    var mapButton = UIButton()
    var sportTypeTitle: String? // 运动类型标题
    var sportType: SportType = .outdoorRunning

    override func viewDidLoad() {
        super.viewDidLoad()

        // 隐藏左上角返回按钮
        navigationItem.hidesBackButton = true

        setupViews()

        title = sportTypeTitle
        footView.leftBlock = { [unowned self] in
            // 计算 slider 的位置（在底部 footView 中央）
            let footViewY = self.view.frame.height - 150 - self.view.safeAreaInsets.bottom
            let sliderHeight: CGFloat = 50 // 增加高度让图标显示更清晰
            let sliderY = footViewY + 75 - sliderHeight/2 // footView 中央位置（150/2 = 75）

            self.slider = HBLockSliderView()
            self.slider.frame = CGRect(x: 30, y: sliderY, width: kWuScreenWidth - 60, height: sliderHeight)
            self.slider.setThumbBegin(UIImage(named: "move_icon_lock")?.add(UIColor.white), finish: UIImage(named: "move_icon_lock")?.add(UIColor.white))
            self.slider.setColorForBackgroud(.clear, foreground: .clear, thumb: .clear, border: .clear, textColor: .clear)
            self.slider.delegate = self
            self.slider.removeRoundCorners(true, border: true)
            self.view.addSubview(self.slider)

            self.shimmerView.isHidden = false
            // 强制布局，确保layer的bounds更新，layoutSubviews中会自动创建动画
            self.shimmerView.setNeedsLayout()
            self.shimmerView.layoutIfNeeded()
        }
        
        footView.rightBlock = { [unowned self] in
            
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
            self.navigationController?.popViewController(animated: true)
        }

        // 自定义右侧按钮为地图图标
        footView.rightBtn.setImage(UIImage(named: "laba")?.withRenderingMode(.alwaysTemplate), for: .normal)
        gpsSelf.sportType = sportType
        gpsSelf.startRun()
        
        if sportType == .indoorCycling || sportType == .indoorRunning || sportType == .indoorWalking {
            mapButton.isHidden = true
            gpsView.isHidden = true
            gpsLabel.isHidden = true 
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        gpsSelf.timerBlock = { [unowned self] in
            self.headView.labels.nameLabel.text = (gpsSelf.distance/1000).stringFloor(2)
            var speed = Double(gpsSelf.speed)
            if bleSelf.userInfo.unit == 1 {
                self.headView.labels.nameLabel.text = (gpsSelf.distance/1000).kmToMi().stringFloor(2)
                speed = speed.miToKm()
            }
            self.valueArray = [Int(speed).stringSpeedFromSecond(), gpsSelf.seconds.stringHmsFromSecond(), gpsSelf.cal.stringFloor(2)]
            self.collection.reloadData()
        }
        gpsView.signalState = WULocationManager.shared.signalState
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        gpsSelf.timerBlock = nil
    }
    
    func setupViews() {
        view.addSubview(headView)
        headView.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(300)
        }

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

        collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.addSubview(collection)
        collection.snp.makeConstraints { (make) in
            make.top.equalTo(headView.snp.bottom).offset(10)
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
            make.height.equalTo(150)
        }

        view.addSubview(footView)
        footView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            make.height.equalTo(150)
        }

        // 添加 shimmerView
        view.addSubview(shimmerView)
        shimmerView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            make.height.equalTo(150)
        }
        shimmerView.isHidden = true
        shimmerView.shimmerColors = [UIColor.white, UIColor.black, UIColor.white]
        shimmerView.textColor = UIColor.white
        shimmerView.text = "sport_slide_to_unlock".localized()
        shimmerView.backgroundColor = UIColor.brand

        collection.backgroundColor = UIColor.clear
        collection.delegate = self
        collection.dataSource = self
        collection.isScrollEnabled = false
        collection.register(SportCollectionViewCell.self, forCellWithReuseIdentifier: SportCollectionViewCell.wuClassName())
        if #available(iOS 11.0, *) {
            collection.contentInsetAdjustmentBehavior = .never
        }
        
        view.addSubview(gpsView)
        gpsView.snp.makeConstraints  { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(5)
            make.right.equalToSuperview().offset(-10)
            make.width.equalTo(40)
            make.height.equalTo(9)
        }

        view.addSubview(gpsLabel)
        gpsLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(gpsView.snp.centerY)
            make.right.equalTo(gpsView.snp.left).offset(-5)
        }
        gpsLabel.text = "GPS"
        gpsLabel.textColor = UIColor.black
        gpsLabel.font = UIFont.systemFont(ofSize: 12)

        // 添加地图按钮
        view.addSubview(mapButton)
        mapButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalTo(footView.snp.top).offset(-50)
            make.width.height.equalTo(60)
        }
        mapButton.backgroundColor = UIColor.systemBlue
        mapButton.layer.cornerRadius = 30
        mapButton.clipsToBounds = true
        mapButton.tintColor = .white
        mapButton.setImage(UIImage(named: "dt_p"), for: .normal)
        mapButton.addTarget(self, action: #selector(mapButtonTapped), for: .touchUpInside)
    }
    
    func setupNotify() {
        NotificationCenter.default.addObserver(self, selector: #selector(handle(_:)), name: WULocationManagerNotifyKey.locationDidUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handle(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc func handle(_ notify: Notification) {
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
            self.footView.leftBtn.isHidden = false
            self.footView.rightBtn.isHidden = false
        }
    }
    
    func buttonPauseAnimation() {
        self.footView.pauseBtn.isHidden = true
        UIView.animate(withDuration: 0.5, animations: {
            self.footView.startBtn.isHidden = false
            self.footView.stopBtn.isHidden = false
            self.footView.leftBtn.isHidden = true
            self.footView.rightBtn.isHidden = true
            self.footView.startConstraint.update(offset: -80)
            self.footView.endConstraint.update(offset: 80)
            self.footView.layoutIfNeeded()
        }) { (_) in
            
        }
    }
    
    // MARK: - CollectionView
    private let titleArray = ["sport_pace".localized(), "sport_duration".localized(), "consumption".localized()]

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SportCollectionViewCell.wuClassName(), for: indexPath) as! SportCollectionViewCell

        if self.valueArray.count >= 3 {
            cell.labels.nameLabel.text = valueArray[indexPath.row]
        } else {
            cell.labels.nameLabel.text = "--"
        }

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

    @objc func mapButtonTapped() {
        let vc = MapViewController()
        vc.title = title
        self.navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - HBLockSliderDelegate
    func sliderEndValueChanged(_ slider: HBLockSliderView!) {
        // 检查是否滑到最大值（解锁成功）
        if slider.value >= 0.95 {  // 使用0.95作为阈值，因为很难精确到1.0
            self.slider.removeFromSuperview()
            self.slider = nil
            self.shimmerView.isHidden = true
            self.shimmerView.removreAnimation()
        }
    }
}
