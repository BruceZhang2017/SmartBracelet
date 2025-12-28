//
//  ViewController.swift
//  OpenWeatherAPI
//
//  Created by Снытин Ростислав on 25.06.2022.
//

import UIKit
import CoreLocation
import WatchProtocolSDK

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
                    self.feelsLikeLabel.text = "\("min_temp".localized()):\(Int((b * 9 / 5) + 32))°F - \("max_temp".localized()):\(Int((c * 9 / 5) + 32))°F"
                } else {
                    self.temperatureLabel.text = "\(safeConvertTemp(from: weather.list.first?.temp.day ?? 0))°C"
                    self.feelsLikeLabel.text = "\("min_temp".localized()):\(safeConvertTemp(from: weather.list.first?.temp.min ?? 0))°C - \("max_temp".localized()):\(safeConvertTemp(from: weather.list.first?.temp.max ?? 0))°C"
                }
            } else {
                self.temperatureLabel.text = "\(safeConvertTemp(from: weather.list.first?.temp.day ?? 0))°C"
                self.feelsLikeLabel.text = "\("min_temp".localized()):\(safeConvertTemp(from: weather.list.first?.temp.min ?? 0))°C - \("max_temp".localized()):\(safeConvertTemp(from: weather.list.first?.temp.max ?? 0))°C"
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

    // 2. 安全转换温度：开尔文 → Int（支持负温度显示）
    private func safeConvertTemp(from kelvinTemp: Double) -> Int {
        // 步骤1：开尔文转摄氏度并取整
        let celsiusTemp = Int(tempratureKToC(temp: kelvinTemp))

        // 步骤2：限制温度在业务范围内（-40°C ~ 80°C，避免极端值）
        let clampedTemp = max(celsiusTemp, minSafeTemp)
        let finalTemp = min(clampedTemp, maxSafeTemp)

        // 返回温度值（支持负数，设备端蓝牙命令使用Int类型参数）
        return finalTemp
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

