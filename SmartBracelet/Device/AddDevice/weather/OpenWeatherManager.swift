//
//  OpenWeatherManager.swift
//  SmartBracelet
//
//  Created by anker on 2024/1/20.
//  Copyright © 2024 tjd. All rights reserved.
//

import Foundation

var flag_time: TimeInterval = 0

public class OpenWeatherManager: NSObject {
    
    var callback: ((CurrentWeatherData) -> Void)?
    var flag = 0
    
    private let viewModel = ViewModel()
    lazy var locationManager: CLLocationManager = {
        let location = CLLocationManager()
        location.delegate = self
        location.desiredAccuracy = kCLLocationAccuracyKilometer
        location.requestWhenInUseAuthorization()
        return location
    }()
    
    public func syncTemprature(flag: Int = 0) {
        self.flag = flag
        let delayTime = DispatchTime.now() + .milliseconds(100)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            [weak self] in
            self?.checkLocationAuthorization()
        }
    }
    
    func checkLocationAuthorization() {
        var isEnabled = false
            
        DispatchQueue.global().async {
            if CLLocationManager.locationServicesEnabled() {
                isEnabled = true
            }
        }
        
        let delayTime = DispatchTime.now() + .milliseconds(300)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            [weak self] in
            guard let sself = self else {
                return
            }
            if isEnabled {
                if #available(iOS 14.0, *) {
                    switch sself.locationManager.authorizationStatus {
                    case .notDetermined:
                        sself.locationManager.requestWhenInUseAuthorization()
                    case .restricted, .denied:
                        // Handle the case where location services are restricted or denied
                        sself.showLocationServicesDeniedAlert()
                    case .authorizedWhenInUse, .authorizedAlways:
                        sself.requestLocation()
                    @unknown default:
                        fatalError("Unknown authorization status")
                    }
                } else {
                    // Fallback on earlier versions
                }
            } else {
                sself.showLocationServicesDisabledAlert()
            }
        }
    }
    
    func requestLocation() {
        DispatchQueue.global().async {
            self.locationManager.requestLocation()
        }
    }
    
    func showLocationServicesDeniedAlert() {
        // Show an alert to the user indicating that location services are denied
    }
    
    func showLocationServicesDisabledAlert() {
        // Show an alert to the user indicating that location services are disabled
    }
    
    func syncTemprature(weather: CurrentWeatherData) {
        if isXGZT { //type 0未知 1晴天 2多云 3下雨 4下雪 5阴天
            if flag_time == 0 {
                flag_time = Date().timeIntervalSince1970
            } else {
                let t = Date().timeIntervalSince1970
                if t - flag_time < 3 {
                    flag_time = t
                    return
                } else {
                    flag_time = t 
                }
            }
            let count = min(3, weather.list.count)
            for i in 0..<count {
                let temp = Int(tempratureKToC(temp: weather.list[i].temp.day ))
                let max: Int = Int(tempratureKToC(temp: weather.list[i].temp.max ))
                let min: Int = Int(tempratureKToC(temp: weather.list[i].temp.min ))
                let weather = weather.list[i].weather.first?.icon ?? ""
                var type = 0
                if weather.hasPrefix("02") || weather.hasPrefix("03") {
                    type = 2
                }
                if weather.hasPrefix("09") || weather.hasPrefix("10") || weather.hasPrefix("11")  {
                    type = 3
                }
                if weather.hasPrefix("13") {
                    type = 4
                }
                if weather.hasPrefix("04") {
                    type = 5
                }
                if weather.hasPrefix("01") {
                    type = 1
                }
                XLogger.shared.log("发送给手表的数据2：\(temp) \(type) \(i)")
                XGZTCommand.setWeatherInfo(dateType: i, weatherType: type, currTemp: temp, lTemp: min, hTemp: max, cmd: flag > 0 ? 2 : 1)
            }
            return
        }
        
        
        let bk = bleSelf.bleModel.internalNumber.hasPrefix("5A4B") // 是否为中科
        if bleSelf.isJLBlue || bk {
            let count = min(3, weather.list.count)
            for i in 0..<count {
                let temp = Int(tempratureKToC(temp: weather.list[i].temp.day ))
                let max: Int = Int(tempratureKToC(temp: weather.list[i].temp.max ))
                let min: Int = Int(tempratureKToC(temp: weather.list[i].temp.min ))
                let weather = weather.list[i].weather.first?.icon ?? ""
                var type = 0
                if weather.hasPrefix("02") || weather.hasPrefix("03") {
                    type = 1
                }
                if weather.hasPrefix("09") || weather.hasPrefix("10") || weather.hasPrefix("11")  {
                    type = 2
                }
                if weather.hasPrefix("13") {
                    type = 3
                }
                if weather.hasPrefix("04") {
                    type = 4
                }
                XLogger.shared.log("发送给手表的数据：\(temp) \(type) \(i)")
                bleSelf.setWeatherForSevenDays(temper: temp, type: UInt8(type), max: max, min: min, day: i, pressure: 1000, altitude: 1000)
            }
        } else {
            let temp = Int(tempratureKToC(temp: weather.list.first?.temp.day ?? 0))
            let max: Int = Int(tempratureKToC(temp: weather.list.first?.temp.max ?? 0))
            let min: Int = Int(tempratureKToC(temp: weather.list.first?.temp.min ?? 0))
            let weather = weather.list.first?.weather.first?.icon ?? ""
            var type = 0
            if weather.hasPrefix("02") || weather.hasPrefix("03") {
                type = 1
            }
            if weather.hasPrefix("09") || weather.hasPrefix("10") || weather.hasPrefix("11")  {
                type = 2
            }
            if weather.hasPrefix("13") {
                type = 3
            }
            if weather.hasPrefix("04") {
                type = 4
            }
            bleSelf.setWeather(temper: temp, type: type, max: max, min: min)
        }
        
    }
    
    /// 绝对温度转摄氏度
        /// - Returns: Double 摄氏度
    func tempratureKToC(temp: Double) -> Double {
            return temp - 273.15
        }
}


// MARK: CoreLocationDelegate

extension OpenWeatherManager: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        viewModel.fetchWeather(requestType: .coordinate(latitude: latitude, longitude: longitude)) { [weak self] weather in
            //self.updateInterface(weather: weather)
            self?.syncTemprature(weather: weather)
            self?.callback?(weather)
        }
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        XLogger.shared.log(error.localizedDescription)
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if (status == CLAuthorizationStatus.denied) {
            // The user denied authorization
        } else if (status == CLAuthorizationStatus.authorizedAlways) {
            // The user accepted authorization
                if CLLocationManager.locationServicesEnabled() {
                    locationManager.requestLocation()
                }
            
        } else if (status == CLAuthorizationStatus.authorizedWhenInUse) {
            checkLocationAuthorization()
        }
    }
}
