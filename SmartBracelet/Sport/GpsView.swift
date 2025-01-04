//
//  GpsView.swift
//  LifeFit
//
//  Created by WuJunjie on 2018/11/18.
//  Copyright © 2018年 WuJunjie. All rights reserved.
//

import UIKit

class GpsView: UIView {
    var signalState = WULocationManagerSignalState.none {
        didSet {
            self.setNeedsDisplay()
        }
    }
    private var noSignalColor = UIColor.Common.text.withAlphaComponent(0.3)
    private let signalColor = UIColor.red
    
    init(frame: CGRect, color: UIColor) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        self.noSignalColor = color
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        for i in 0...3 {
            drawCircle(with: noSignalColor, index: i)
        }
        var signalNum = 0
        switch signalState {
        case .none, .weak:
            signalNum = 0
        case .middle:
            signalNum = 1
        case .strong:
            signalNum = 2
        case .stronger, .strongest:
            signalNum = 3
        }
        
        for i in 0...signalNum {
            drawCircle(with: signalColor, index: i)
        }
    }
    
    
    func drawLine(with color: UIColor, index: Int) {
        let path = UIBezierPath()
        color.setStroke()
        path.lineWidth = 2
        let tempx = (path.lineWidth + 1) * CGFloat(index) + path.lineWidth/2
        let start = CGPoint.init(x: tempx, y: height)
        let stop = CGPoint.init(x: tempx, y: CGFloat(6 - index)/6.0*height)
        path.move(to: start)
        path.addLine(to: stop)
        path.stroke()
    }
    
    func drawCircle(with color: UIColor, index: Int) {
        let path = UIBezierPath()
        color.setFill()
        let radius = CGFloat(4)
        let tempx = (radius * 2 + 2) * CGFloat(index) + radius
        let center = CGPoint.init(x: tempx, y: height/2)
        path.addArc(withCenter: center, radius: radius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
        path.fill()
    }

}


import MapKit

let gpsSelf = GpsManager.shared

class GpsManager: NSObject {
    static let shared = GpsManager()
    var startPoint = MKPointAnnotation()
    var routeLines = MKPolyline()
    
    //MARK: End
    var runModel = RunModel()
    var timer: Timer?
    var seconds = 0
    var distance: Double = 0
    var cal: Double = 0
    var speed = 0
    var pointArray = [RunPoint]()
    var currentPath = 0
    var isActiveRun = true
    var lastLocation: CLLocation?
    var timerBlock: WUOkHandler?
    var gpsBlock: WUOkHandler?
    
    override init() {
        super.init()
        setupNotify()
    }
    
    func startRun() {
        isActiveRun = true
        seconds = 0
        distance = 0
        cal = 0
        speed = 0
        pointArray = [RunPoint]()
        currentPath = 0
        lastLocation = nil
        runModel = RunModel()
        runModel.timeStamp = Date().secondFromDate()
        runModel.pathCount = currentPath + 1
        WULocationManager.shared.startLocation()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(handleTimer), userInfo: nil, repeats: true)
    }
    
    func pauseRun() {
        isActiveRun = false
        lastLocation = nil
        timer?.invalidate()
        timer = nil
    }
    
    func restartRun() {
        isActiveRun = true
        currentPath = currentPath + 1
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(handleTimer), userInfo: nil, repeats: true)
    }
    
    @objc func handleTimer() {
        seconds = seconds + 1
        let temp = (distance > 0) ? Double(seconds)/distance*1000 : 0
        speed = Int(temp)
        timerBlock?()
    }
    
    func saveRun() {
        runModel.distance = distance
        runModel.duration = seconds
        runModel.cal = cal
        runModel.pathCount = currentPath + 1
        runModel.pointArray = pointArray
        runModel.jr_save()
    }
    
    func stopRun() {
        WULocationManager.shared.stopLocation()
        pauseRun()
        if distance >= 10 {
            self.saveRun()
        }
        else {
            self.showHud(NSLocalizedString("运动时长太短,保存失败!", comment: ""))
        }
    }
    
    func setupNotify() {
        NotificationCenter.default.addObserver(self, selector: #selector(handle(_:)), name: WULocationManagerNotifyKey.getRunSport, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handle(_:)), name: UIApplication.willTerminateNotification, object: nil)
    }
    
    @objc func handle(_ notify: Notification) {
        if isActiveRun, notify.name == WULocationManagerNotifyKey.getRunSport {
            let location = notify.object as! CLLocation
            let model = RunPoint()
            model.pathId = currentPath
            model.latitude = location.coordinate.latitude
            model.longitude = location.coordinate.longitude
            model.speed = location.speed
            model.altitude = location.altitude
            if let last = lastLocation {
                distance = distance + last.distance(from: location)
                cal = Double(bleSelf.userInfo.weight) * KCalConversion * distance/1000
            }
            lastLocation = location
            pointArray.append(model)
            self.runModel.pointArray = pointArray
            gpsBlock?()
        }
        
        if notify.name == UIApplication.willTerminateNotification {
            if distance >= 10 {
                self.saveRun()
            }
        }
    }
}
