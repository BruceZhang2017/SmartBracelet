//
//  WeatherProvider.swift
//  SmartBracelet
//
//  Created by Claude on 2025/12/25.
//  统一的天气数据提供者协议和模型
//

import Foundation
import CoreLocation

// MARK: - 统一天气数据模型（兼容现有 CurrentWeatherData 结构）

/// 统一天气数据模型，所有 API 适配器都返回此格式
struct UnifiedWeatherData {
    let list: [UnifiedWeatherItem]

    /// 转换为原有的 CurrentWeatherData 格式（向后兼容）
    func toCurrentWeatherData() -> CurrentWeatherData {
        return CurrentWeatherData(list: list.map { item in
            Item(
                temp: Temp(
                    day: item.dayTemp,
                    min: item.minTemp,
                    max: item.maxTemp,
                    night: item.nightTemp,
                    eve: item.eveTemp,
                    morn: item.mornTemp
                ),
                weather: [Weather(
                    id: item.weatherCode,
                    main: item.weatherMain,
                    description: item.weatherDescription,
                    icon: item.weatherIcon
                )]
            )
        })
    }
}

struct UnifiedWeatherItem {
    let dayTemp: Double       // 白天温度（开尔文）
    let minTemp: Double       // 最低温度（开尔文）
    let maxTemp: Double       // 最高温度（开尔文）
    let nightTemp: Double     // 夜间温度（开尔文）
    let eveTemp: Double       // 傍晚温度（开尔文）
    let mornTemp: Double      // 早晨温度（开尔文）
    let weatherCode: Int      // 天气代码
    let weatherMain: String   // 天气主类型
    let weatherDescription: String  // 天气描述
    let weatherIcon: String   // 天气图标代码
}

// MARK: - 天气数据提供者协议

/// 天气数据提供者协议，所有 API 适配器都需实现此协议
protocol WeatherProvider {
    /// 根据经纬度获取天气数据
    func fetchWeather(
        latitude: CLLocationDegrees,
        longitude: CLLocationDegrees,
        onSuccess: @escaping (UnifiedWeatherData) -> Void,
        onError: @escaping (Error) -> Void
    )

    /// 提供者名称（用于日志）
    var providerName: String { get }
}

// MARK: - 天气数据源类型

enum WeatherDataSource {
    case openMeteo    // Open-Meteo（国外免费）
    case qWeather     // 和风天气（国内免费）

    var description: String {
        switch self {
        case .openMeteo: return "Open-Meteo"
        case .qWeather: return "QWeather"
        }
    }
}

// MARK: - 天气 API 错误类型

enum WeatherAPIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case parsingError
    case emptyData
    case apiKeyMissing
    case rateLimitExceeded
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL"
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .parsingError: return "Failed to parse weather data"
        case .emptyData: return "Empty data received"
        case .apiKeyMissing: return "API Key is missing"
        case .rateLimitExceeded: return "API rate limit exceeded"
        case .invalidResponse: return "Invalid API response"
        }
    }
}

// MARK: - 地理位置工具

struct LocationHelper {
    /// 判断经纬度是否在中国大陆
    static func isInMainlandChina(latitude: CLLocationDegrees, longitude: CLLocationDegrees) -> Bool {
        // 中国大陆经纬度范围（粗略判断）
        // 经度：73.5°E - 135.1°E
        // 纬度：18.2°N - 53.5°N
        let isLongitudeInRange = (73.5...135.1).contains(longitude)
        let isLatitudeInRange = (18.2...53.5).contains(latitude)
        return isLongitudeInRange && isLatitudeInRange
    }
}
