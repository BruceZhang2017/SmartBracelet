//
//  HistoryMapViewController.swift
//  LifeFit
//
//  Created by tjd on 2018/11/29.
//  Copyright © 2018年 tjd. All rights reserved.
//

import UIKit
import CoreLocation
import SnapKit
import MapKit
import TJDWristbandSDK

class HistoryMapViewController: BaseViewController, MKMapViewDelegate {
    var unitLabel = UILabel()
    var valueLabel = UILabel()
    var detailView = SportDetailView()
    
    //MARK: -
    var mapBgView = UIView()
    var mapView = MKMapView()
    private var startPoint = MKPointAnnotation()
    private var routeLines = MKPolyline()
    
    //MARK: End
    var runModel = RunModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        displayData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.drawLines(with: runModel)
    }
    
    func setupViews() {
        view.addSubview(mapBgView)
        mapBgView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        mapBgView.backgroundColor = UIColor.white
        
        mapView.adhere(toSuperView: mapBgView).layout { (make) in
            make.edges.equalToSuperview()
            }
            .config { (make) in
                make.backgroundColor = UIColor.white
                make.delegate = self
        }
        
        let baseView = UIView().adhere(toSuperView: mapBgView).layout { (make) in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-20)
            make.left.equalToSuperview().offset(16)
            make.height.equalTo(150)
        }
        baseView.backgroundColor = UIColor.white
        baseView.layer.cornerRadius = 7
        
        let content = UIView().adhere(toSuperView: baseView).layout { (make) in
            make.top.equalToSuperview().offset(20)
            make.centerX.equalToSuperview()
            }
            .config { (make) in
        }
        
        valueLabel.adhere(toSuperView: content).layout { (make) in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.height.lessThanOrEqualToSuperview()
            }
            .config { (make) in
                make.text = "0.00"
                make.font = UIFont.systemFont(ofSize: 35)
                make.textColor = UIColor.black
        }
        
        unitLabel.adhere(toSuperView: content).layout { (make) in
            make.left.equalTo(valueLabel.snp.right).offset(2)
            make.right.equalToSuperview()
            make.lastBaseline.equalTo(valueLabel.snp.lastBaseline)
            make.height.lessThanOrEqualToSuperview()
            }
            .config { (make) in
                make.text = "km"
                make.font = UIFont.systemFont(ofSize: 20)
                make.textColor = UIColor.black
        }
        
        detailView.adhere(toSuperView: baseView).layout { (make) in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
            make.left.equalToSuperview()
            make.height.equalTo(120)
            }
            .config { (make) in
        }
    }
    
     func displayData() {
        let cal = runModel.cal
        let seconds = runModel.duration
        let distance = runModel.distance
        let speed = (distance > 0) ? Double(seconds)/distance*1000 : 0
        detailView.valueArray = [speed, Double(seconds), cal]
        valueLabel.text = (distance/1000).stringFloor(2)
    }

    //MARK: mapView
    func drawLines(with model: RunModel) {
        if model.pointArray.count == 0 {
            return
        }
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        let start = MKPointAnnotation()
        let first = model.pointArray[0]
        start.coordinate = LocationConverter.wgs84(toGcj02: CLLocationCoordinate2DMake(first.latitude, first.longitude))
        startPoint = start
        mapView.addAnnotation(start)
        
        let end = MKPointAnnotation()
        let last = model.pointArray.last!
        end.coordinate = LocationConverter.wgs84(toGcj02: CLLocationCoordinate2DMake(last.latitude, last.longitude))
        mapView.addAnnotation(end)
        
        for i in 0..<model.pathCount {
            let array = model.pointArray.filter { (temp) -> Bool in
                return temp.pathId == i
            }
            
            let coordinateArray = array.map { (temp) -> CLLocationCoordinate2D in
                return LocationConverter.wgs84(toGcj02: CLLocationCoordinate2DMake(temp.latitude, temp.longitude))
            }
            let polyline = MKPolyline.init(coordinates: coordinateArray, count: coordinateArray.count)
            mapView.addOverlay(polyline)
        }
        
        let center = start.coordinate
        // 设置地图的显示范围, 让其显示到当前指定的位置
        let span = MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
        //这个显示大小精度自己调整
        let region = MKCoordinateRegion(center: center, span: span)
        mapView.setRegion(region, animated: true)
    }
    
    //MARK: MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKPointAnnotation {
            let annotationView = MKPinAnnotationView.init(annotation: annotation, reuseIdentifier: MKPinAnnotationView.wuClassName())
            if annotation.isEqual(startPoint) {
                annotationView.pinTintColor = .green
            }
            else {
                annotationView.pinTintColor = .red
            }
            return annotationView
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let routeLineView = MKPolylineRenderer.init(overlay: overlay)
        routeLineView.lineWidth = 2
        routeLineView.strokeColor = UIColor.brand
        return routeLineView
    }
    
    // MARK: End
}


class MapViewController: BaseViewController, MKMapViewDelegate {
    var unitLabel = UILabel()
    var valueLabel = UILabel()
    var detailView = SportDetailView()
    var userLocation: MKUserLocation?
    
    //MARK: -
    var mapBgView = UIView()
    var mapView = MKMapView()
    private var startPoint = MKPointAnnotation()
    private var routeLines = MKPolyline()
    var rightBtn = UIButton()
    var baseView = UIView()
    
    // GPS 强度显示视图
    private let gpsStrengthView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 15 // 半圆倒角
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var gpsView = GpsView.init(frame: .zero, color: UIColor.white)

    private let gpsStrengthLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .black
        label.text = "GPS"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        displayData()
        
        // GPS 强度视图
        view.addSubview(gpsStrengthView)
        view.addSubview(gpsStrengthLabel)
        gpsView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gpsView)
        
        NSLayoutConstraint.activate([
            // GPS 强度视图（左上角）
            gpsStrengthView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            gpsStrengthView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            gpsStrengthView.heightAnchor.constraint(equalToConstant: 30),
            gpsStrengthView.widthAnchor.constraint(equalToConstant: 90),

            // GPS 强度标签
            gpsStrengthLabel.leadingAnchor.constraint(equalTo: gpsStrengthView.leadingAnchor, constant: 8),
            gpsStrengthLabel.centerYAnchor.constraint(equalTo: gpsStrengthView.centerYAnchor),
            
            // GPS 图标
            gpsView.trailingAnchor.constraint(equalTo: gpsStrengthView.trailingAnchor, constant: -8),
            gpsView.centerYAnchor.constraint(equalTo: gpsStrengthView.centerYAnchor),
            gpsView.widthAnchor.constraint(equalToConstant: 40),
            gpsView.heightAnchor.constraint(equalToConstant: 9),
        ])
        
        // 监听位置更新通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(locationDidUpdate(_:)),
            name: WULocationManagerNotifyKey.locationDidUpdate,
            object: nil
        )
    }
    
    @objc private func locationDidUpdate(_ notification: Notification) {
        gpsView.signalState = WULocationManager.shared.signalState
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        gpsSelf.timerBlock = { [unowned self] in
            self.displayData()
        }
        
        gpsSelf.gpsBlock = { [unowned self] in
            self.drawLines(with: gpsSelf.runModel)
        }
        
        self.drawLines(with: gpsSelf.runModel)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        gpsSelf.timerBlock = nil
        gpsSelf.gpsBlock = nil
    }
    
    func setupViews() {
        mapBgView.adhere(toSuperView: view).layout { (make) in
            make.edges.equalToSuperview()
            }
            .config { (make) in
                make.backgroundColor = UIColor.white
        }
        
        mapView.adhere(toSuperView: mapBgView).layout { (make) in
            make.edges.equalToSuperview()
            }
            .config { (make) in
                make.backgroundColor = UIColor.white
                make.delegate = self
                make.showsUserLocation = true
        }
        
        baseView.adhere(toSuperView: mapBgView).layout { (make) in
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-20)
            make.left.equalToSuperview().offset(16)
            make.height.equalTo(150)
            }
            .config { (make) in
                make.backgroundColor = UIColor.white
                make.layer.cornerRadius = 7
        }
        
        let content = UIView().adhere(toSuperView: baseView).layout { (make) in
            make.top.equalToSuperview().offset(20)
            make.centerX.equalToSuperview()
            }
            .config { (make) in
        }
        
        valueLabel.adhere(toSuperView: content).layout { (make) in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.height.lessThanOrEqualToSuperview()
            }
            .config { (make) in
                make.text = "0.00"
                make.font = UIFont.systemFont(ofSize: 35)
                make.textColor = UIColor.black
        }
        
        unitLabel.adhere(toSuperView: content).layout { (make) in
            make.left.equalTo(valueLabel.snp.right).offset(2)
            make.right.equalToSuperview()
            make.lastBaseline.equalTo(valueLabel.snp.lastBaseline)
            make.height.lessThanOrEqualToSuperview()
            }
            .config { (make) in
                make.text = "km"
                make.font = UIFont.systemFont(ofSize: 20)
                make.textColor = UIColor.black
        }
        
        detailView.adhere(toSuperView: baseView).layout { (make) in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
            make.left.equalToSuperview()
            make.height.equalTo(120)
            }
            .config { (make) in
        }
        
        rightBtn.adhere(toSuperView: view).layout { (make) in
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalTo(baseView.snp.top).offset(-40)
            make.width.height.equalTo(64)
            }
            .config { (make) in
                make.addTarget(self, action: #selector(pressBtn(_:)), for: .touchUpInside)
                make.setBackgroundImage(UIImage.init(named: "map_icon_switch"), for: .normal)
        }
    }
    
    func displayData() {
        wuPrint(#function)
        let cal = gpsSelf.cal
        let seconds = gpsSelf.seconds
        let distance = gpsSelf.distance
        let speed = (distance > 0) ? Double(seconds)/distance*1000 : 0
        detailView.valueArray = [speed, Double(seconds), cal]
        valueLabel.text = (distance/1000).stringFloor(2)
    }
    
    //MARK: mapView
    func drawLines(with model: RunModel) {
        if model.pointArray.count == 0 {
            return
        }
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        let start = MKPointAnnotation()
        let first = model.pointArray[0]
        start.coordinate = LocationConverter.wgs84(toGcj02: CLLocationCoordinate2DMake(first.latitude, first.longitude))
        startPoint = start
        mapView.addAnnotation(start)
        
        let end = MKPointAnnotation()
        let last = model.pointArray.last!
        end.coordinate = LocationConverter.wgs84(toGcj02: CLLocationCoordinate2DMake(last.latitude, last.longitude))
        mapView.addAnnotation(end)
        
        for i in 0..<model.pathCount {
            let array = model.pointArray.filter { (temp) -> Bool in
                return temp.pathId == i
            }
            
            let coordinateArray = array.map { (temp) -> CLLocationCoordinate2D in
                return LocationConverter.wgs84(toGcj02: CLLocationCoordinate2DMake(temp.latitude, temp.longitude))
            }
            let polyline = MKPolyline.init(coordinates: coordinateArray, count: coordinateArray.count)
            mapView.addOverlay(polyline)
        }
    }
    
    @objc func pressBtn(_ sender: UIButton) {
        self.adjustUserLocation()
    }
    
    func adjustUserLocation() {
        if let location = mapView.userLocation.location {
            if location.coordinate.latitude != 0 {
                let center = location.coordinate
                // 设置地图的显示范围, 让其显示到当前指定的位置
                let span = MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
                //这个显示大小精度自己调整
                let region = MKCoordinateRegion(center: center, span: span)
                mapView.setRegion(region, animated: true)
            }
        }
    }
    
    //MARK: MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if userLocation.location != nil, self.userLocation?.location == nil {
            self.adjustUserLocation()
        }
        self.userLocation = userLocation
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKPointAnnotation {
            if annotation.isEqual(startPoint) {
                let annotationView = MKPinAnnotationView.init(annotation: annotation, reuseIdentifier: MKPinAnnotationView.wuClassName())
                annotationView.pinTintColor = .green
                return annotationView
            }
            else {
                let annotationView = MKAnnotationView.init(annotation: annotation, reuseIdentifier: MKAnnotationView.wuClassName())
                annotationView.image = UIImage.init(named: "rStep")
                return annotationView
            }
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let routeLineView = MKPolylineRenderer.init(overlay: overlay)
        routeLineView.lineWidth = 2
        routeLineView.strokeColor = UIColor.brand
        return routeLineView
    }
    
    // MARK: End
}
