//
//  WeatherRouter.swift
//  SmartBracelet
//
//  Created by Claude on 2025/12/25.
//  智能天气数据路由器：根据用户位置自动选择最优数据源
//

import Foundation
import CoreLocation

class WeatherRouter {

    // MARK: - 单例模式

    static let shared = WeatherRouter()

    private init() {
        // 初始化所有提供者
        providers = [
            .openMeteo: OpenMeteoProvider(),
            .qWeather: QWeatherProvider()
        ]
    }

    // MARK: - Properties

    private var providers: [WeatherDataSource: WeatherProvider]

    /// 当前使用的数据源（用于日志和调试）
    private(set) var currentDataSource: WeatherDataSource?

    // MARK: - 智能路由策略

    /// 根据用户位置智能选择天气数据源
    /// - Parameters:
    ///   - latitude: 纬度
    ///   - longitude: 经度
    /// - Returns: 选择的天气数据源
    private func selectDataSource(latitude: CLLocationDegrees, longitude: CLLocationDegrees) -> WeatherDataSource {
        // 策略：根据地理位置智能选择
        if LocationHelper.isInMainlandChina(latitude: latitude, longitude: longitude) {
            // 中国大陆使用和风天气（数据更准确，响应更快）
            XLogger.shared.log("📍 位置在中国大陆，使用和风天气")
            return .qWeather
        } else {
            // 国外使用 Open-Meteo（完全免费，无需 API Key）
            XLogger.shared.log("🌍 位置在海外，使用 Open-Meteo")
            return .openMeteo
        }
    }

    // MARK: - Public Methods

    /// 获取天气数据（自动路由）
    func fetchWeather(
        latitude: CLLocationDegrees,
        longitude: CLLocationDegrees,
        onSuccess: @escaping (CurrentWeatherData) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        // 1. 选择数据源
        let dataSource = selectDataSource(latitude: latitude, longitude: longitude)
        currentDataSource = dataSource

        // 2. 获取对应的提供者
        guard let provider = providers[dataSource] else {
            XLogger.shared.log("❌ 无法找到天气数据提供者: \(dataSource.description)")
            onError(WeatherAPIError.invalidResponse)
            return
        }

        XLogger.shared.log("🌤 使用 \(provider.providerName) 获取天气数据")

        // 3. 调用提供者获取数据
        provider.fetchWeather(
            latitude: latitude,
            longitude: longitude,
            onSuccess: { unifiedData in
                // 将统一格式转换回原有格式（向后兼容）
                let weatherData = unifiedData.toCurrentWeatherData()
                XLogger.shared.log("✅ \(provider.providerName) 天气数据获取成功")
                onSuccess(weatherData)
            },
            onError: { error in
                XLogger.shared.log("❌ \(provider.providerName) 天气数据获取失败: \(error.localizedDescription)")

                // 失败时尝试备用数据源
                self.fallbackToAlternativeSource(
                    primarySource: dataSource,
                    latitude: latitude,
                    longitude: longitude,
                    onSuccess: onSuccess,
                    onError: onError
                )
            }
        )
    }

    // MARK: - 备用数据源策略

    /// 当主数据源失败时，尝试使用备用数据源
    private func fallbackToAlternativeSource(
        primarySource: WeatherDataSource,
        latitude: CLLocationDegrees,
        longitude: CLLocationDegrees,
        onSuccess: @escaping (CurrentWeatherData) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        // 选择备用数据源
        let fallbackSource: WeatherDataSource = (primarySource == .qWeather) ? .openMeteo : .qWeather

        guard let fallbackProvider = providers[fallbackSource] else {
            onError(WeatherAPIError.invalidResponse)
            return
        }

        XLogger.shared.log("🔄 尝试使用备用数据源: \(fallbackProvider.providerName)")

        fallbackProvider.fetchWeather(
            latitude: latitude,
            longitude: longitude,
            onSuccess: { unifiedData in
                let weatherData = unifiedData.toCurrentWeatherData()
                XLogger.shared.log("✅ 备用数据源 \(fallbackProvider.providerName) 成功")
                onSuccess(weatherData)
            },
            onError: { fallbackError in
                XLogger.shared.log("❌ 备用数据源也失败了: \(fallbackError.localizedDescription)")
                onError(fallbackError)
            }
        )
    }

    // MARK: - 手动指定数据源（用于测试）

    /// 手动指定天气数据源（仅用于测试和调试）
    func fetchWeather(
        latitude: CLLocationDegrees,
        longitude: CLLocationDegrees,
        forceDataSource: WeatherDataSource,
        onSuccess: @escaping (CurrentWeatherData) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        guard let provider = providers[forceDataSource] else {
            onError(WeatherAPIError.invalidResponse)
            return
        }

        XLogger.shared.log("🔧 强制使用数据源: \(provider.providerName)")

        provider.fetchWeather(
            latitude: latitude,
            longitude: longitude,
            onSuccess: { unifiedData in
                onSuccess(unifiedData.toCurrentWeatherData())
            },
            onError: onError
        )
    }
}
