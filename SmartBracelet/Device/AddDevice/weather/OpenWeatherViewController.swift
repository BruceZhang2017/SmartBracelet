//
//  ViewController.swift
//  OpenWeatherAPI
//
//  Created by Снытин Ростислав on 25.06.2022.
//

import UIKit
import CoreLocation

class OpenWeatherViewController: UIViewController {

    private var manager = OpenWeatherManager()
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
        manager.syncTemprature(flag: 0)
        manager.callback = {
            [weak self] weatherData in
            self?.updateInterface(weather: weatherData)
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
            if isXGZT {
                if XGZTBlueToothManager.shared.device?.baseUnit ?? 0 > 0 {
                    let a = safeConvertTemp(from: weather.list.first?.temp.day ?? 0) // 当前温度
                    let b = safeConvertTemp(from: weather.list.first?.temp.min ?? 0)
                    let c = safeConvertTemp(from: weather.list.first?.temp.max ?? 0)
                    self.temperatureLabel.text = "\(Int((a * 9 / 5) + 32))°F"
                    self.feelsLikeLabel.text = self.makeTemperatureRangeText(
                        minValue: "\(Int((b * 9 / 5) + 32))°F",
                        maxValue: "\(Int((c * 9 / 5) + 32))°F"
                    )
                } else {
                    self.temperatureLabel.text = "\(safeConvertTemp(from: weather.list.first?.temp.day ?? 0))°C"
                    self.feelsLikeLabel.text = self.makeTemperatureRangeText(
                        minValue: "\(safeConvertTemp(from: weather.list.first?.temp.min ?? 0))°C",
                        maxValue: "\(safeConvertTemp(from: weather.list.first?.temp.max ?? 0))°C"
                    )
                }
            } else {
                self.temperatureLabel.text = "\(safeConvertTemp(from: weather.list.first?.temp.day ?? 0))°C"
                self.feelsLikeLabel.text = self.makeTemperatureRangeText(
                    minValue: "\(safeConvertTemp(from: weather.list.first?.temp.min ?? 0))°C",
                    maxValue: "\(safeConvertTemp(from: weather.list.first?.temp.max ?? 0))°C"
                )
            }
            
        }
    }
    
    
    
    
    
    /// 绝对温度转摄氏度
        /// - Returns: Double 摄氏度
    func tempratureKToC(temp: Double) -> Double {
            return temp - 273.15
        }
    
    // 1. 定义业务所需的温度范围（根据实际场景调整，如-40°C ~ 80°C）
    private let minSafeTemp: Int = -40  // 实际支持的最低温度
    private let maxSafeTemp: Int = 80   // 实际支持的最高温度（避免超过UInt8的255上限）

    // 2. 安全转换温度：开尔文 → 非负Int（确保可转为UInt8）
    private func safeConvertTemp(from kelvinTemp: Double) -> Int {
        // 步骤1：开尔文转摄氏度并取整
        let celsiusTemp = Int(tempratureKToC(temp: kelvinTemp))
        
        // 步骤2：限制温度在业务范围内（避免极端值）
        let clampedTemp = max(celsiusTemp, minSafeTemp)
        let finalTemp = min(clampedTemp, maxSafeTemp)
        
        // 步骤3：确保非负（若低于0，强制设为0，或按偏移量处理，需和手表端同步）
        // 方案A：简单处理，负数直接设为0（适合手表端不支持负温显示的场景）
        return max(finalTemp, 0)
        
        // 方案B：偏移量处理（适合需要显示负温的场景，需手表端反向计算）
        // let offset = 40 // 偏移量，-40°C → 0，0°C →40
        // return finalTemp + offset
    }
    
    private func makeTemperatureRangeText(minValue: String, maxValue: String) -> String {
        return "\("min_temp".localized()): \(minValue)\n\("max_temp".localized()): \(maxValue)"
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
            temperatureLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16),
            temperatureLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),

            feelsLikeLabel.topAnchor.constraint(equalTo: temperatureLabel.bottomAnchor),
            feelsLikeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            feelsLikeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            feelsLikeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        //weatherIconImageView.tintColor = UIColor(named: Constant.colorSet)
        weatherIconImageView.contentMode = .scaleAspectFit

        temperatureLabel.font = .systemFont(ofSize: 70, weight: .medium)
        temperatureLabel.textColor = UIColor.white
        temperatureLabel.textAlignment = .center
        temperatureLabel.adjustsFontSizeToFitWidth = true
        temperatureLabel.minimumScaleFactor = 0.7

        feelsLikeLabel.font = .systemFont(ofSize: 16, weight: .medium)
        feelsLikeLabel.textColor = UIColor.white
        feelsLikeLabel.textAlignment = .center
        feelsLikeLabel.numberOfLines = 0
        feelsLikeLabel.lineBreakMode = .byWordWrapping
    }
}
