//
//  WeatherViewController.swift
//  MAMapKit_2D_Demo
//
//  Created by shaobin on 16/10/19.
//  Copyright © 2016年 Autonavi. All rights reserved.
//

import UIKit

class WeatherViewController: UIViewController, AMapSearchDelegate {
    
    var search: AMapSearchAPI!
    var liveWeatherView: MAWeatherLiveView!
    var forecastWeatherView: MAWeatherForecastView!
    var barColor: UIColor!
    var tintColor: UIColor!
    var liveWeather:AMapLocalWeatherLive!
    var forecast:AMapLocalWeatherForecast!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSearch()
        self.view.backgroundColor = UIColor(red: 84/255.0, green: 142/255.0, blue: 212/255.0, alpha: 1)
        
        liveWeatherView = MAWeatherLiveView()
        liveWeatherView.frame = CGRect.init(x: 0, y: 0, width: self.view.bounds.width, height: (self.view.bounds.height - 5) * 0.7)
        self.view.addSubview(liveWeatherView)
        
        liveWeatherView.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight, UIView.AutoresizingMask.flexibleBottomMargin]
        
        forecastWeatherView = MAWeatherForecastView.init()
        forecastWeatherView.frame =  CGRect.init(x: 0, y: liveWeatherView.frame.maxY + 5, width: self.view.bounds.width, height: (self.view.bounds.height - 5) * 0.3)
        self.view.addSubview(forecastWeatherView)
        forecastWeatherView.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight, UIView.AutoresizingMask.flexibleTopMargin]
        
        self.searchLiveWeather()
        self.searchForcastWeather()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        barColor = navigationController?.navigationBar.barTintColor
        navigationController?.navigationBar.barTintColor = UIColor(red: 84/255.0, green: 142/255.0, blue: 212/255.0, alpha: 1)
        tintColor = navigationController?.navigationBar.tintColor
        navigationController?.navigationBar.tintColor = UIColor.white
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.barTintColor = barColor
        navigationController?.navigationBar.tintColor = tintColor
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    
    func initSearch() {
        search = AMapSearchAPI()
        search.delegate = self
    }
    
    //MARK: - Action
    func searchForcastWeather() {
        let req:AMapWeatherSearchRequest! = AMapWeatherSearchRequest()
        
        req.city = "深圳"
        req.type = AMapWeatherType.forecast
        
        self.search.aMapWeatherSearch(req)
    }
    
    func searchLiveWeather() {
        let req:AMapWeatherSearchRequest! = AMapWeatherSearchRequest()
        
        req.city = "深圳"
        req.type = AMapWeatherType.live
        
        self.search.aMapWeatherSearch(req)
    }
    
    
    //MARK: - AMapSearchDelegate
    func aMapSearchRequest(_ request: Any!, didFailWithError error: Error!) {
        let _: NSError? = error as NSError
        NSLog("Error:\(String(describing: error))")
    }
    
    func onWeatherSearchDone(_ request: AMapWeatherSearchRequest!, response: AMapWeatherSearchResponse!) {
        if (request.type == AMapWeatherType.live) {
            if (response.lives.count == 0) {
                return;
            }
            
            liveWeather = response.lives.first
            if (liveWeather != nil) {
                self.liveWeatherView.updateWeather(withInfo: liveWeather)
            }
        } else {
            if (response.forecasts.count == 0) {
                return;
            }
            
            forecast = response.forecasts.first
            
            if (forecast != nil) {
                self.forecastWeatherView.updateWeather(withInfo: forecast)
            }
        }
        syncTemprature()
    }
    
    private func syncTemprature() {
        if liveWeather == nil {
            return
        }
        if forecast == nil {
            return
        }
        let temp = Int(liveWeather.temperature) ?? 0
        let max: Int = Int(forecast?.casts.first?.dayTemp ?? "") ?? 0
        let min: Int = Int(forecast?.casts.first?.nightTemp ?? "") ?? 0
        let weather = liveWeather.weather
        var type = 0
        if weather?.contains("晴") == true {
            type = 0
        } else if weather?.contains("多云") == true {
            type = 1
        } else if weather?.contains("雨") == true {
            type = 2
        } else if weather?.contains("雪") == true {
            type = 3
        } else if weather?.contains("阴") == true {
            type = 4
        }
            
        bleSelf.setWeather(temper: temp, type: type, max: max, min: min)
    }
}
