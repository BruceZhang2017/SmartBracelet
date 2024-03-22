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
        manager.syncTemprature()
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
            self.temperatureLabel.text = "\(Int(self.tempratureKToC(temp: weather.list.first?.temp.day ?? 0)))°C"
            self.feelsLikeLabel.text = "min:\(Int(self.tempratureKToC(temp: weather.list.first?.temp.min ?? 0)))°C - max:\(Int(self.tempratureKToC(temp: weather.list.first?.temp.max ?? 0)))°C"
        }
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

