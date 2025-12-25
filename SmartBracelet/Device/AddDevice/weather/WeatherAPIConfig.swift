//
//  WeatherAPIConfig.swift
//  SmartBracelet
//
//  Created by Claude on 2025/12/25.
//  天气 API 配置中心（集中管理所有 API Key）
//

import Foundation

struct WeatherAPIConfig {

    // MARK: - 和风天气配置

    /// 和风天气 API Key（免费版）
    /// 获取步骤：
    /// 1. 访问 https://dev.qweather.com/
    /// 2. 注册账号并登录
    /// 3. 在控制台创建项目，选择「免费订阅」
    /// 4. 获取 API Key 并填写到下方
    static let qWeatherAPIKey = "3f53759a415245dbabc8e6f96a7b18bb"

    /// 和风天气 API 主机（个性化域名）
    /// ⚠️ 重要：每个 API Key 可能有不同的专属域名
    /// 获取方法：
    /// 1. 登录 https://dev.qweather.com/
    /// 2. 进入控制台 → 应用管理 → 你的应用
    /// 3. 查看 "API Host" 字段，复制完整域名
    ///
    /// 常见格式：
    /// - 免费版通用域名：devapi.qweather.com
    /// - 个性化域名：p42mtekqgk.re.qweatherapi.com（你当前使用的）
    static let qWeatherHost = "p42mtekqgk.re.qweatherapi.com"

    // MARK: - Open-Meteo 配置

    /// Open-Meteo 无需 API Key，完全免费
    /// 官网：https://open-meteo.com/
    static let openMeteoHost = "api.open-meteo.com"

    // MARK: - 验证配置

    /// 检查和风天气 API Key 是否已配置
    static var isQWeatherConfigured: Bool {
        return qWeatherAPIKey != "YOUR_QWEATHER_API_KEY" && !qWeatherAPIKey.isEmpty
    }

    /// 检查是否至少有一个天气数据源可用
    static var hasAvailableProvider: Bool {
        return true  // Open-Meteo 始终可用（无需配置）
    }
}
