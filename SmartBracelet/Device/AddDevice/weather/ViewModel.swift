//
//  ViewModel.swift
//  OpenWeatherAPI
//
//  Created by Снытин Ростислав on 27.06.2022.
//

import Foundation

class ViewModel {
    private var currentWeather: CurrentWeatherData?
    private let networkManager = NetworkManager()

    func fetchWeather(
        requestType: NetworkManager.RequestType,
        onCompletion: @escaping ((CurrentWeatherData) -> Void)
    ) {
        networkManager.fetchData(
            requestType: requestType
        ) { [weak self] weather in
            guard let self = self else { return }
            onCompletion(weather)
            self.currentWeather = weather
        } onError: { error in
            print(error)
        }
    }
}
