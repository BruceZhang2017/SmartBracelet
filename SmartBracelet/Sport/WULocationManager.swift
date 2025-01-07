//
//  WULocationManager.swift
//  WearfitPlus
//
//  Created by WuJunjie on 2017/4/12.
//  Copyright © 2017年 WuJunjie. All rights reserved.
//

import UIKit
import CoreLocation
import TJDWristbandSDK


struct WULocationManagerNotifyKey {
    static let getWeather = Notification.Name.init(rawValue: "getWeather")
    static let locationDidUpdate = Notification.Name.init(rawValue: "locationDidUpdate")
    static let getRunSport = Notification.Name.init(rawValue: "getRunSport")
}
let kLatitude = "latitude"
let kLongitude = "longitude"

enum WULocationManagerSignalState: Int {
    case none = 0
    case weak
    case middle
    case strong
    case stronger
    case strongest
}

class WULocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = WULocationManager()
    var locationManager = CLLocationManager()
    var signalState: WULocationManagerSignalState = .none
    private var lastLocation: CLLocation?
    var authChanged: WUOkHandler?
    var isGetWeather = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.pausesLocationUpdatesAutomatically = false
        if #available(iOS 9.0, *) {
            locationManager.allowsBackgroundLocationUpdates = true
        } else {
            // Fallback on earlier versions
        }
    }
    
    func requestAuthorization(authorized:WUOkHandler?, denied:WUOkHandler?) {
        if CLLocationManager.locationServicesEnabled() {
            let status = CLLocationManager.authorizationStatus()
            if status == .denied {
                denied?()
            }
            else if status == .authorizedAlways || status == .authorizedWhenInUse {
                authorized?()
            } else {
                authChanged = authorized
                locationManager.requestWhenInUseAuthorization()
            }
        }
    }
    
    func startLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func stopLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let value = location.horizontalAccuracy
            if value <= 30 {
                signalState = .strongest
            }
            else if value <= 50 {
              signalState = .stronger
            }
            else if value <= 80 {
                signalState = .strong
            }
            else if value <= 120 {
                signalState = .middle
            }
            else if value <= 200 {
                signalState = .weak
            }
            else {
                signalState = .none
            }
            if isGetWeather {
                NotificationCenter.default.post(name: WULocationManagerNotifyKey.getWeather, object: location)
                isGetWeather = false
                stopLocation()
                return
            }
            
            NotificationCenter.default.post(name: WULocationManagerNotifyKey.locationDidUpdate, object: location)
            
            if self.checkValidate(with: location) {
                NotificationCenter.default.post(name: WULocationManagerNotifyKey.getRunSport, object: location)
                lastLocation = location
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            authChanged?()
        }
    }
    
    class func distance(with dic:[String:Double], dic1:[String:Double]) -> Double {
        let lon1 = dic[kLongitude]!
        let lat1 = dic[kLatitude]!
        let lon2 = dic1[kLongitude]!
        let lat2 = dic1[kLatitude]!
        let location = CLLocation.init(latitude: lat1, longitude: lon1)
        let location1 = CLLocation.init(latitude: lat2, longitude: lon2)
        return location.distance(from: location1)
    }
    
    
    /**
     *  检测一个点是否是有效点 不是那种异常的很飘的点  GPS 本身也可能会有
     *
     *  @param location location
     *
     *  @return YES:是有效的点
     */
    func checkValidate(with location: CLLocation) -> Bool {
        //和
        if location == lastLocation {
            return false
        }
        
        if signalState.rawValue <= WULocationManagerSignalState.none.rawValue {
            return false
        }
        
        if let last = lastLocation {
            let distance = location.distance(from: last)
            let diff_t = location.timestamp.timeIntervalSince(last.timestamp)
            if diff_t <= 0 || distance == 0 {
                return false
            }
        }
        
        return true
    }
}
