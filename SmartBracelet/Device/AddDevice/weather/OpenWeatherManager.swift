//
//  OpenWeatherManager.swift
//  SmartBracelet
//
//  Created by anker on 2024/1/20.
//  Copyright © 2024 tjd. All rights reserved.
//

import Foundation



public class OpenWeatherManager: NSObject {
    
    var callback: ((CurrentWeatherData) -> Void)?
    
    private let viewModel = ViewModel()
    lazy var locationManager: CLLocationManager = {
        let location = CLLocationManager()
        location.delegate = self
        location.desiredAccuracy = kCLLocationAccuracyKilometer
        location.requestWhenInUseAuthorization()
        return location
    }()
    
    public func syncTemprature() {
        checkLocationAuthorization()
    }
    
    func checkLocationAuthorization() {
        if CLLocationManager.locationServicesEnabled() {
            if #available(iOS 14.0, *) {
                switch self.locationManager.authorizationStatus {
                case .notDetermined:
                    self.locationManager.requestWhenInUseAuthorization()
                case .restricted, .denied:
                    // Handle the case where location services are restricted or denied
                    self.showLocationServicesDeniedAlert()
                case .authorizedWhenInUse, .authorizedAlways:
                    self.requestLocation()
                @unknown default:
                    fatalError("Unknown authorization status")
                }
            } else {
                // Fallback on earlier versions
            }
        } else {
            // Handle the case where location services are not enabled
            self.showLocationServicesDisabledAlert()
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
        if isXGZT { //type 0晴天 1多云 2下雨 3下雪 4阴天
            let count = min(3, weather.list.count)
            for i in 0..<count {
                let temp = Int(tempratureKToC(temp: weather.list[i].temp.day ))
                let max: Int = Int(tempratureKToC(temp: weather.list[i].temp.max ))
                let min: Int = Int(tempratureKToC(temp: weather.list[i].temp.min ))
                let weather = weather.list[i].weather.first?.icon ?? ""
                var type = 1
                if weather.hasPrefix("02") || weather.hasPrefix("03") {
                    type = 0
                }
                if weather.hasPrefix("09") || weather.hasPrefix("10") || weather.hasPrefix("11")  {
                    type = 3
                }
                if weather.hasPrefix("13") {
                    type = 2
                }
                if weather.hasPrefix("04") {
                    type = 4
                }
                print("发送给手表的数据：\(temp) \(type) \(i)")
                XGZTCommand.setWeatherInfo(dateType: i, weatherType: type, currTemp: temp, lTemp: min, hTemp: max)
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
                print("发送给手表的数据：\(temp) \(type) \(i)")
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
        print(error.localizedDescription)
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
