//
//  QWeatherProvider.swift
//  SmartBracelet
//
//  Created by Claude on 2025/12/25.
//  和风天气数据提供者（国内免费额度充足）
//

import Foundation
import CoreLocation

class QWeatherProvider: WeatherProvider {

    var providerName: String {
        return "QWeather"
    }

    // 和风天气 API Key（从配置文件读取）
    private let apiKey = WeatherAPIConfig.qWeatherAPIKey

    func fetchWeather(
        latitude: CLLocationDegrees,
        longitude: CLLocationDegrees,
        onSuccess: @escaping (UnifiedWeatherData) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        // 检查 API Key
        guard apiKey != "YOUR_QWEATHER_API_KEY" else {
            XLogger.shared.log("⚠️ QWeather API Key 未配置，请在 QWeatherProvider.swift 中设置")
            onError(WeatherAPIError.apiKeyMissing)
            return
        }

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
                // 🔍 调试：打印原始响应数据
                if let jsonString = String(data: data, encoding: .utf8) {
                    XLogger.shared.log("🔍 QWeather 原始响应: \(jsonString)")
                }

                let weatherData = try self.parseResponse(data)
                onSuccess(weatherData)
            } catch {
                XLogger.shared.log("❌ QWeather parsing error: \(error)")

                // 🔍 调试：解析失败时也打印原始数据
                if let jsonString = String(data: data, encoding: .utf8) {
                    XLogger.shared.log("🔍 解析失败的原始数据: \(jsonString)")
                }

                onError(WeatherAPIError.parsingError)
            }
        }.resume()
    }

    // MARK: - Private Methods

    private func buildURL(latitude: CLLocationDegrees, longitude: CLLocationDegrees) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = WeatherAPIConfig.qWeatherHost  // 使用配置的 API Host
        components.path = "/v7/weather/7d"  // 7天天气预报

        components.queryItems = [
            URLQueryItem(name: "location", value: "\(longitude),\(latitude)"),  // 注意：和风是经度在前
            URLQueryItem(name: "key", value: apiKey)
        ]

        let finalURL = components.url
        XLogger.shared.log("🌐 QWeather 请求 URL: \(finalURL?.absoluteString ?? "无效URL")")
        XLogger.shared.log("   使用 API Host: \(WeatherAPIConfig.qWeatherHost)")
        return finalURL
    }

    private func parseResponse(_ data: Data) throws -> UnifiedWeatherData {
        let response = try JSONDecoder().decode(QWeatherResponse.self, from: data)

        // 优先检查新格式的错误对象
        if let error = response.error {
            XLogger.shared.log("❌ QWeather API 返回错误 (新格式):")
            XLogger.shared.log("   状态码: \(error.status)")
            XLogger.shared.log("   标题: \(error.title)")
            XLogger.shared.log("   详情: \(error.detail)")

            // 特殊处理 403 Invalid Host 错误
            if error.status == 403 && error.title.contains("Invalid Host") {
                XLogger.shared.log("")
                XLogger.shared.log("⚠️  403 Invalid Host 错误说明:")
                XLogger.shared.log("   这个错误通常表示 API Host 配置不正确")
                XLogger.shared.log("")
                XLogger.shared.log("🔧 当前配置:")
                XLogger.shared.log("   API Host: \(WeatherAPIConfig.qWeatherHost)")
                XLogger.shared.log("   API Key: \(apiKey.prefix(8))***")
                XLogger.shared.log("")
                XLogger.shared.log("💡 解决方案:")
                XLogger.shared.log("   1. 访问 https://dev.qweather.com/")
                XLogger.shared.log("   2. 进入控制台 → 应用管理 → 你的应用")
                XLogger.shared.log("   3. 查看「API Host」字段")
                XLogger.shared.log("   4. 复制正确的 API Host（如：p42mtekqgk.re.qweatherapi.com）")
                XLogger.shared.log("   5. 更新 WeatherAPIConfig.swift 中的 qWeatherHost")
                XLogger.shared.log("")
                XLogger.shared.log("📝 注意：每个 API Key 可能有不同的专属域名！")
                XLogger.shared.log("")
                XLogger.shared.log("🔄 系统将自动切换到 Open-Meteo 备用数据源...")
            }

            throw WeatherAPIError.invalidResponse
        }

        // 检查旧格式的错误消息
        if let errorMessage = response.message {
            XLogger.shared.log("❌ QWeather API 返回错误 (旧格式): \(errorMessage)")
            throw WeatherAPIError.invalidResponse
        }

        // 检查 API 响应状态码
        guard let code = response.code else {
            XLogger.shared.log("❌ QWeather API 响应缺少状态码")
            throw WeatherAPIError.invalidResponse
        }

        guard code == "200" else {
            XLogger.shared.log("❌ QWeather API error: code=\(code)")
            // 常见错误代码说明
            let errorDesc = getQWeatherErrorDescription(code: code)
            XLogger.shared.log("   错误说明: \(errorDesc)")
            throw WeatherAPIError.invalidResponse
        }

        // 检查是否有天气数据
        guard let dailyData = response.daily, !dailyData.isEmpty else {
            XLogger.shared.log("❌ QWeather API 响应中没有天气数据")
            throw WeatherAPIError.emptyData
        }

        XLogger.shared.log("✅ QWeather API 返回 \(dailyData.count) 天天气数据")

        var items: [UnifiedWeatherItem] = []

        let count = min(7, dailyData.count)
        for i in 0..<count {
            let day = dailyData[i]

            // 和风天气返回摄氏度字符串，需要转换
            let maxTemp = Double(day.tempMax) ?? 25.0
            let minTemp = Double(day.tempMin) ?? 15.0

            // 估算其他时段温度
            let dayTemp = maxTemp - 2.0
            let nightTemp = minTemp + 2.0
            let mornTemp = minTemp + 3.0
            let eveTemp = maxTemp - 3.0

            let item = UnifiedWeatherItem(
                dayTemp: celsiusToKelvin(dayTemp),
                minTemp: celsiusToKelvin(minTemp),
                maxTemp: celsiusToKelvin(maxTemp),
                nightTemp: celsiusToKelvin(nightTemp),
                eveTemp: celsiusToKelvin(eveTemp),
                mornTemp: celsiusToKelvin(mornTemp),
                weatherCode: Int(day.iconDay) ?? 100,
                weatherMain: day.textDay,
                weatherDescription: day.textDay,
                weatherIcon: mapQWeatherIconToOpenWeather(day.iconDay)
            )
            items.append(item)
        }

        return UnifiedWeatherData(list: items)
    }

    // MARK: - 和风天气错误码说明

    private func getQWeatherErrorDescription(code: String) -> String {
        switch code {
        case "204": return "请求成功，但你查询的地区暂时没有你需要的数据"
        case "400": return "请求错误，可能包含错误的请求参数或缺少必选的请求参数"
        case "401": return "认证失败，可能使用了错误的 API Key"
        case "402": return "超过访问次数或余额不足以支持继续访问服务"
        case "403": return "无访问权限，可能是绑定的 PackageName、BundleID 不一致"
        case "404": return "查询的数据或地区不存在"
        case "429": return "超过限定的QPM（每分钟访问次数）"
        case "500": return "无响应或超时"
        default: return "未知错误码: \(code)"
        }
    }

    // MARK: - 温度转换

    private func celsiusToKelvin(_ celsius: Double) -> Double {
        return celsius + 273.15
    }

    // MARK: - 和风天气图标代码映射到 OpenWeatherMap 格式

    private func mapQWeatherIconToOpenWeather(_ qweatherIcon: String) -> String {
        // 和风天气图标代码映射
        // 详见：https://dev.qweather.com/docs/resource/icons/
        switch qweatherIcon {
        case "100": return "01d"  // 晴
        case "101", "102", "103": return "02d"  // 多云
        case "104": return "04d"  // 阴
        case "300", "301", "305", "306", "307", "308", "309", "310", "311", "312", "313", "314", "315", "316", "317", "318": return "10d"  // 雨
        case "350", "351": return "09d"  // 阵雨
        case "400", "401", "402", "403", "404", "405", "406", "407", "408", "409", "410": return "13d"  // 雪
        case "499", "500", "501", "502", "503", "504", "507", "508", "509", "510", "511", "512", "513", "514", "515": return "50d"  // 雾霾沙尘
        default: return "01d"
        }
    }
}

// MARK: - QWeather API Response Models

private struct QWeatherResponse: Codable {
    let code: String?          // 状态码，可能为空（错误响应时）
    let daily: [QWeatherDaily]? // 天气数据，可能为空（错误响应时）
    let updateTime: String?    // 更新时间（可选）

    // 和风天气错误响应字段（旧格式）
    let message: String?       // 错误消息（仅在错误时存在）

    // 和风天气错误响应字段（新格式）
    let error: QWeatherError?  // 错误对象（新版API使用）
}

private struct QWeatherError: Codable {
    let status: Int            // HTTP 状态码（如 403）
    let type: String?          // 错误类型URL
    let title: String          // 错误标题（如 "Invalid Host"）
    let detail: String         // 错误详情
}

private struct QWeatherDaily: Codable {
    let fxDate: String        // 日期
    let tempMax: String       // 最高温度
    let tempMin: String       // 最低温度
    let iconDay: String       // 白天天气图标代码
    let textDay: String       // 白天天气描述
    let iconNight: String?    // 夜间天气图标代码（可选）
    let textNight: String?    // 夜间天气描述（可选）
}
