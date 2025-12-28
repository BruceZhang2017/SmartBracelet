//
//  OpenMeteoProvider.swift
//  SmartBracelet
//
//  Created by Claude on 2025/12/25.
//  Open-Meteo 天气数据提供者（完全免费，无需 API Key）
//

import Foundation
import CoreLocation
import WatchProtocolSDK

class OpenMeteoProvider: WeatherProvider {

    var providerName: String {
        return "Open-Meteo"
    }

    func fetchWeather(
        latitude: CLLocationDegrees,
        longitude: CLLocationDegrees,
        onSuccess: @escaping (UnifiedWeatherData) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        guard let url = buildURL(latitude: latitude, longitude: longitude) else {
            onError(WeatherAPIError.invalidURL)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                onError(WeatherAPIError.networkError(error))
                return
            }

            guard let data = data else {
                onError(WeatherAPIError.emptyData)
                return
            }

            do {
                let weatherData = try self.parseResponse(data)
                onSuccess(weatherData)
            } catch {
                XLogger.shared.log("Open-Meteo parsing error: \(error)")
                onError(WeatherAPIError.parsingError)
            }
        }.resume()
    }

    // MARK: - Private Methods

    private func buildURL(latitude: CLLocationDegrees, longitude: CLLocationDegrees) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.open-meteo.com"
        components.path = "/v1/forecast"

        components.queryItems = [
            URLQueryItem(name: "latitude", value: "\(latitude)"),
            URLQueryItem(name: "longitude", value: "\(longitude)"),
            URLQueryItem(name: "daily", value: "temperature_2m_max,temperature_2m_min,weathercode"),
            URLQueryItem(name: "temperature_unit", value: "celsius"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "7")
        ]

        return components.url
    }

    private func parseResponse(_ data: Data) throws -> UnifiedWeatherData {
        let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)

        var items: [UnifiedWeatherItem] = []

        let count = min(7, response.daily.time.count)
        for i in 0..<count {
            let maxTemp = response.daily.temperature_2m_max[i]
            let minTemp = response.daily.temperature_2m_min[i]
            let weatherCode = response.daily.weathercode[i]

            // 估算其他时段温度（简单线性插值）
            let dayTemp = maxTemp - 2.0  // 白天稍低于最高温
            let nightTemp = minTemp + 2.0  // 夜间稍高于最低温
            let mornTemp = minTemp + 3.0
            let eveTemp = maxTemp - 3.0

            // 将摄氏度转换为开尔文（保持与原系统一致）
            let item = UnifiedWeatherItem(
                dayTemp: celsiusToKelvin(dayTemp),
                minTemp: celsiusToKelvin(minTemp),
                maxTemp: celsiusToKelvin(maxTemp),
                nightTemp: celsiusToKelvin(nightTemp),
                eveTemp: celsiusToKelvin(eveTemp),
                mornTemp: celsiusToKelvin(mornTemp),
                weatherCode: weatherCode,
                weatherMain: mapWeatherCodeToMain(weatherCode),
                weatherDescription: mapWeatherCodeToDescription(weatherCode),
                weatherIcon: mapWeatherCodeToIcon(weatherCode)
            )
            items.append(item)
        }

        return UnifiedWeatherData(list: items)
    }

    // MARK: - 温度转换

    private func celsiusToKelvin(_ celsius: Double) -> Double {
        return celsius + 273.15
    }

    // MARK: - WMO Weather Code 映射（Open-Meteo 使用 WMO 标准）

    private func mapWeatherCodeToMain(_ code: Int) -> String {
        switch code {
        case 0: return "Clear"
        case 1, 2, 3: return "Clouds"
        case 45, 48: return "Fog"
        case 51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82: return "Rain"
        case 71, 73, 75, 77, 85, 86: return "Snow"
        case 95, 96, 99: return "Thunderstorm"
        default: return "Unknown"
        }
    }

    private func mapWeatherCodeToDescription(_ code: Int) -> String {
        switch code {
        case 0: return "clear sky"
        case 1: return "mainly clear"
        case 2: return "partly cloudy"
        case 3: return "overcast"
        case 45, 48: return "fog"
        case 51, 53, 55: return "drizzle"
        case 56, 57: return "freezing drizzle"
        case 61: return "slight rain"
        case 63: return "moderate rain"
        case 65: return "heavy rain"
        case 66, 67: return "freezing rain"
        case 71: return "slight snow"
        case 73: return "moderate snow"
        case 75: return "heavy snow"
        case 77: return "snow grains"
        case 80, 81, 82: return "rain showers"
        case 85, 86: return "snow showers"
        case 95: return "thunderstorm"
        case 96, 99: return "thunderstorm with hail"
        default: return "unknown"
        }
    }

    private func mapWeatherCodeToIcon(_ code: Int) -> String {
        // 映射到 OpenWeatherMap 图标格式（保持兼容性）
        switch code {
        case 0: return "01d"  // 晴天
        case 1, 2: return "02d"  // 多云
        case 3: return "04d"  // 阴天
        case 45, 48: return "50d"  // 雾
        case 51, 53, 55, 56, 57: return "09d"  // 毛毛雨
        case 61, 63, 65, 80, 81, 82: return "10d"  // 雨
        case 66, 67: return "10d"  // 冻雨
        case 71, 73, 75, 77, 85, 86: return "13d"  // 雪
        case 95, 96, 99: return "11d"  // 雷暴
        default: return "01d"
        }
    }
}

// MARK: - Open-Meteo API Response Models

private struct OpenMeteoResponse: Codable {
    let daily: DailyWeather
}

private struct DailyWeather: Codable {
    let time: [String]
    let temperature_2m_max: [Double]
    let temperature_2m_min: [Double]
    let weathercode: [Int]
}
