//
//  CurrentWeatherData.swift
//  OpenWeatherAPI
//
//  Created by Снытин Ростислав on 27.06.2022.
//

import Foundation

struct CurrentWeatherData: Codable {
    let list: [Item]
}

struct Item: Codable {
    let temp: Temp
    let weather: [Weather]
}

struct Temp: Codable {
    let day: Double
    let min: Double
    let max: Double
    let night: Double
    let eve :Double
    let morn: Double
}


struct Weather: Codable {
    let id: Int
    let main: String
    let description: String
    let icon: String
}
