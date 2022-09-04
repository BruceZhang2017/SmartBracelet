//
//  ViewController.swift
//  OpenWeatherAPI
//
//  Created by Снытин Ростислав on 25.06.2022.
//

import UIKit
import CoreLocation
import ProgressHUD

class OpenWeatherViewController: UIViewController {
    private let viewModel = ViewModel()
    lazy var locationManager: CLLocationManager = {
        let location = CLLocationManager()
        location.delegate = self
        location.desiredAccuracy = kCLLocationAccuracyKilometer
        location.requestWhenInUseAuthorization()
        return location
    }()

    private let backgroundImageView = UIImageView()
    private let weatherIconImageView = UIImageView()
    private let temperatureLabel = UILabel()
    private let feelsLikeLabel = UILabel()
    private let cityLabel = UILabel()
    private let searchButton = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackgroundImage()
        setupWeatherView()

        title = "device_weather_push".localized()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestLocation()
        }
    }

    private func presentSearchAlertController(completionHandler: @escaping (String) -> Void) {
        let alertController = UIAlertController(title: "Enter city name", message: nil, preferredStyle: .alert)
        alertController.addTextField { textField in
            let cities = ["San Francisco", "Moscow", "Vienna", "London", "Rome"]
            textField.placeholder = cities.randomElement()
        }

        let search = UIAlertAction(title: "Search", style: .default) { _ in
            let textField = alertController.textFields?.first
            guard let cityName = textField?.text else { return }
            if cityName != "" {
                let city = cityName.split(separator: " ").joined(separator: "%20")
                completionHandler(city)
            }
        }

        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        alertController.addAction(search)
        alertController.addAction(cancel)
        present(alertController, animated: true, completion: nil)
    }

    @objc func searchButtonTapped() {
        
    }

    private func updateInterface(weather: CurrentWeatherData) {
        DispatchQueue.main.async {
            [weak self] in
            guard let self = self else { return }
            //self.weatherIconImageView.image = UIImage(systemName: weather.systemIconNameString)
            self.temperatureLabel.text = "\(Int(self.tempratureKToC(temp: weather.list.first?.temp.day ?? 0)))°C"
            self.feelsLikeLabel.text = "min:\(Int(self.tempratureKToC(temp: weather.list.first?.temp.min ?? 0)))°C - max:\(Int(self.tempratureKToC(temp: weather.list.first?.temp.max ?? 0)))°C"
            self.syncTemprature(weather: weather)
        }
    }
    
    
    private func syncTemprature(weather: CurrentWeatherData) {
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
    
    
    /// 绝对温度转摄氏度
        /// - Returns: Double 摄氏度
    func tempratureKToC(temp: Double) -> Double {
            return temp - 273.15
        }
}

// MARK: Setup UI

extension OpenWeatherViewController {
    private func setupBackgroundImage() {
        self.view.addSubview(backgroundImageView)
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImageView.leftAnchor.constraint(equalTo: view.leftAnchor),
            backgroundImageView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
        backgroundImageView.image = UIImage(named: "afternoon")
    }

    private func setupWeatherView() {
        self.view.addSubview(weatherIconImageView)
        self.view.addSubview(temperatureLabel)
        self.view.addSubview(feelsLikeLabel)
        weatherIconImageView.translatesAutoresizingMaskIntoConstraints = false
        temperatureLabel.translatesAutoresizingMaskIntoConstraints = false
        feelsLikeLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            weatherIconImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            weatherIconImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            weatherIconImageView.widthAnchor.constraint(equalToConstant: 170),
            weatherIconImageView.heightAnchor.constraint(equalToConstant: 170),

            temperatureLabel.topAnchor.constraint(equalTo: weatherIconImageView.bottomAnchor),
            temperatureLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            feelsLikeLabel.topAnchor.constraint(equalTo: temperatureLabel.bottomAnchor),
            feelsLikeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        //weatherIconImageView.tintColor = UIColor(named: Constant.colorSet)
        weatherIconImageView.contentMode = .scaleAspectFit

        temperatureLabel.font = .systemFont(ofSize: 70, weight: .medium)
        temperatureLabel.textColor = UIColor.white

        feelsLikeLabel.font = .systemFont(ofSize: 16, weight: .medium)
        feelsLikeLabel.textColor = UIColor.white
    }
}

// MARK: CoreLocationDelegate

extension OpenWeatherViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        ProgressHUD.show()
        viewModel.fetchWeather(requestType: .coordinate(latitude: latitude, longitude: longitude)) { weather in
            ProgressHUD.dismiss()
            self.updateInterface(weather: weather)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}
