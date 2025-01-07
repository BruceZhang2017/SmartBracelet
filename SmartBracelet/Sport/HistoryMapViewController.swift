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
            make.bottom.equalToSuperview().offset(-8)
            make.left.equalToSuperview().offset(16)
            make.height.equalTo(150)
        }
        baseView.backgroundColor = UIColor.red.withAlphaComponent(0.8)
        baseView.layer.cornerRadius = 7
        baseView.layer.shadowColor = UIColor.black.cgColor
        baseView.layer.shadowOpacity = 0.25
        baseView.layer.shadowRadius = 12
        baseView.layer.shadowOffset = .zero
        
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
                make.textColor = UIColor.red
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
                make.textColor = UIColor.red
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
                annotationView.pinColor = .green
            }
            else {
                annotationView.pinColor = .red
            }
            return annotationView
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let routeLineView = MKPolylineRenderer.init(overlay: overlay)
        routeLineView.lineWidth = 2
        routeLineView.strokeColor = UIColor.red
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
    var leftBtn = UIButton()
    var rightBtn = UIButton()
    var baseView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        displayData()
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
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-8)
            make.left.equalToSuperview().offset(16)
            make.height.equalTo(150)
            }
            .config { (make) in
                make.backgroundColor = UIColor.red.withAlphaComponent(0.8)
                make.layer.cornerRadius = 7
                make.layer.shadowColor = UIColor.black.cgColor
                make.layer.shadowOpacity = 0.25
                make.layer.shadowRadius = 12
                make.layer.shadowOffset = .zero
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
                make.textColor = UIColor.red
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
                make.textColor = UIColor.red
        }
        
        detailView.adhere(toSuperView: baseView).layout { (make) in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
            make.left.equalToSuperview()
            make.height.equalTo(120)
            }
            .config { (make) in
        }
        
        leftBtn.adhere(toSuperView: view).layout { (make) in
            make.left.equalToSuperview().offset(16)
            make.bottom.equalTo(baseView.snp.top).offset(-8)
            }
            .config { (make) in
                make.addTarget(self, action: #selector(pressBtn(_:)), for: .touchUpInside)
                make.setBackgroundImage(UIImage.init(named: "map_icon_big"), for: .normal)
        }
        
        rightBtn.adhere(toSuperView: view).layout { (make) in
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalTo(baseView.snp.top).offset(-8)
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
        if sender == leftBtn {
            self.baseView.isHidden = !self.baseView.isHidden
        }
        
        if sender == rightBtn {
            self.adjustUserLocation()
        }
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
                annotationView.pinColor = .green
                return annotationView
            }
            else {
                let annotationView = MKAnnotationView.init(annotation: annotation, reuseIdentifier: MKAnnotationView.wuClassName())
//                annotationView.pinColor = .red
                annotationView.image = UIImage.init(named: "rStep")
                return annotationView
            }
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let routeLineView = MKPolylineRenderer.init(overlay: overlay)
        routeLineView.lineWidth = 2
        routeLineView.strokeColor = UIColor.red
        return routeLineView
    }
    
    // MARK: End
}
