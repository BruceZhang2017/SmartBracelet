//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  SportViewController.swift
//  TJDWristbandSDKDemo
//
//  Created by ANKER on 2020/7/28.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit
import SnapKit
import Segmentio

class SportViewController: BaseViewController {
    @IBOutlet weak var totalValueLabel: UILabel!
    @IBOutlet weak var mapSuperView: UIView!
    @IBOutlet weak var segmentioView: Segmentio!
    @IBOutlet weak var setTargetButton: UIButton!
    var target: TargetModel = TargetModel() // 目标设置内容
    var mapView: MAMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        AMapServices.shared().enableHTTPS = true
        mapView = MAMapView(frame: .zero)
        mapSuperView.addSubview(mapView)
        mapView.zoomLevel = 16
        mapView.maxZoomLevel = 18
        mapView.snp.makeConstraints {
            $0.edges.equalTo(mapSuperView)
        }
        let maskView = UIView().then {
            $0.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        }
        mapView.addSubview(maskView)
        maskView.snp.makeConstraints {
            $0.edges.equalTo(mapView)
        }
    
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        
        let run = SegmentioItem(title: "跑步", image: nil)
        let bike = SegmentioItem(title: "骑行", image: nil)
        let climb = SegmentioItem(title: "登山", image: nil)
        let foot = SegmentioItem(title: "徒步", image: nil)
        let state = SegmentioStates(
                    defaultState: SegmentioState(
                        backgroundColor: .white,
                        titleFont: UIFont.systemFont(ofSize: 13),
                        titleTextColor: .colorWithRGB(rgbValue: 0x333333)
                    ),
                    selectedState: SegmentioState(
                        backgroundColor: .white,
                        titleFont: UIFont.systemFont(ofSize: 13),
                        titleTextColor: .colorWithRGB(rgbValue: 0x333333)
                    ),
                    highlightedState: SegmentioState(
                        backgroundColor: .white,
                        titleFont: UIFont.boldSystemFont(ofSize: 13),
                        titleTextColor: .colorWithRGB(rgbValue: 0x333333)
                    )
        )
        let options = SegmentioOptions(
                    backgroundColor: .white,
                    segmentPosition: SegmentioPosition.fixed(maxVisibleItems: 5),
                    scrollEnabled: true,
                    indicatorOptions: SegmentioIndicatorOptions(type: .bottom, ratio: 0.3, height: 2, color: .k3ACF95),
                    horizontalSeparatorOptions: SegmentioHorizontalSeparatorOptions(type: .none, height: 0, color: .clear),
                    verticalSeparatorOptions: SegmentioVerticalSeparatorOptions(ratio: 0, color: .clear),
                    imageContentMode: .center,
                    labelTextAlignment: .center,
                    segmentStates: state
        )
        
        segmentioView.setup(
            content: [run, bike, climb, foot],
            style: .onlyLabel,
            options: options
        )
        segmentioView.selectedSegmentioIndex = 0
        segmentioView.valueDidChange = {
            segmentio, segmentIndex in
            
        }
        
        setTargetButton.setImagePosition(at: .right, space: 3)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: Notification.Name("SportViewController"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        let totalDistance = UserDefaults.standard.double(forKey: "totalDistance")
        let distance = UserDefaults.standard.double(forKey: "distance")
        let title = NSMutableAttributedString()
        title.append(NSAttributedString(string: "\(String(format: "%.2f", Float(totalDistance + distance)))", attributes: [.font: UIFont.systemFont(ofSize: 32),   .foregroundColor: UIColor.k666666]))
        title.append(NSAttributedString(string: "  公里", attributes: [.font: UIFont.systemFont(ofSize: 12),   .foregroundColor: UIColor.k666666]))
        totalValueLabel.attributedText = title
        if distance > 0 {
            UserDefaults.standard.setValue(totalDistance + distance, forKey: "totalDistance")
            UserDefaults.standard.setValue(0, forKey: "distance")
            UserDefaults.standard.synchronize()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleNotification(_ notification: Notification) {
        guard let target = notification.object as? TargetModel else {
            return
        }
        self.target = target
    }
    
    @IBAction func setTarget(_ sender: Any) {
        let storyboard = UIStoryboard(name: .kSport, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: .kSetTargetBViewController) as! SetTargetBViewController
        vc.target = TargetModel()
        vc.target.distance = target.distance
        vc.target.cal = target.cal
        vc.target.time = target.time
        vc.target.speed = target.speed
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func setRun(_ sender: Any) {
        let label = HHCountdowLabel(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: ScreenHeight))
        label?.textAlignment = .center
        label?.textColor = .black
        label?.font = UIFont.boldSystemFont(ofSize: 200)
        tabBarController?.view.addSubview(label!)
        tabBarController?.view.isUserInteractionEnabled = false
        label?.startCount({
            [weak self] in
            self?.tabBarController?.view.isUserInteractionEnabled = true
            self?.pushToRunning()
        })
    }

    private func pushToRunning() {
        let sb = UIStoryboard(name: "SGSportingView", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "SGSportingViewController") as! SGSportingViewController
        let index = segmentioView.selectedSegmentioIndex
        if index == 0 {
            vc.sportType = SGSportType(0) // 0 跑步 1 走路 2 骑行
        } else if index == 1 {
            vc.sportType = SGSportType(2)
        } else {
            vc.sportType = SGSportType(1)
        }
        
        vc.hidesBottomBarWhenPushed = true 
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension SportViewController: MAMapViewDelegate {
    
}

extension SportViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
//            if locationManager.responds(to: #selector(CLLocationManager.requestAlwaysAuthorization)) {
//                locationManager.requestAlwaysAuthorization()
//            }
            print("没有授权")
        case .restricted:
            print("访问受限")
        case .denied:
            if CLLocationManager.locationServicesEnabled() {
                showLocationAlertView(title: "系统提示", message: "请至设置 -> 开启定位权限")
            } else {
                showLocationAlertView(title: "系统提示", message: "请至设置 -> 打开定位功能")
            }
        case .authorizedAlways:
            print("获取前后台授权")
        case .authorizedWhenInUse:
            print("获取前台授权")
        default:
            break;
        }
    }
}
