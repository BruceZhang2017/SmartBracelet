# 安卓端天气 API 接入指导文档

> **文档版本**: v1.0
> **更新日期**: 2026-01-09
> **适用平台**: Android 8.0+ (API Level 26+)

---

## 📋 目录

1. [概述](#概述)
2. [技术方案](#技术方案)
3. [核心组件设计](#核心组件设计)
4. [API 接口详解](#api-接口详解)
5. [代码实现示例](#代码实现示例)
6. [配置说明](#配置说明)
7. [测试验证](#测试验证)
8. [常见问题](#常见问题)

---

## 概述

### 1.1 背景

iOS 端已完成天气 API 的升级，采用**双源智能路由方案**：
- **国外地区**: 使用 Open-Meteo（完全免费，无需 API Key）
- **国内地区**: 使用和风天气 QWeather（免费额度充足，数据更准确）

安卓端需要实现相同的逻辑，确保跨平台用户体验一致。

### 1.2 核心特性

✅ **智能路由**: 根据用户位置自动选择最优天气数据源
✅ **容错机制**: 主数据源失败时自动切换到备用数据源
✅ **完全免费**: 两个数据源均提供免费使用方案
✅ **统一接口**: 不同数据源返回统一格式，业务层无需关心数据来源

---

## 技术方案

### 2.1 架构图

```
┌─────────────────────────────────┐
│   WeatherRepository (业务层)    │  ← 对外提供天气数据服务
└──────────────┬──────────────────┘
               │
┌──────────────▼──────────────────┐
│      WeatherRouter              │  ← 智能路由器（核心）
│  • 根据位置选择数据源            │
│  • 失败时自动切换备用源          │
└──────────────┬──────────────────┘
               │
       ┌───────┴────────┐
       │                │
┌──────▼──────┐  ┌──────▼──────┐
│OpenMeteo    │  │ QWeather    │
│Provider     │  │ Provider    │
│(国外)       │  │ (国内)      │
└─────────────┘  └─────────────┘
```

### 2.2 数据源选择策略

**判断逻辑**（参考 iOS 端 `WeatherRouter.swift:42`）:

```
用户位置
    │
    ├─ 中国大陆？
    │   ├─ 经度: 73.5°E ~ 135.1°E
    │   └─ 纬度: 18.2°N ~ 53.5°N
    │       │
    │       ├─ 是 → 使用和风天气 (QWeather)
    │       └─ 否 → 使用 Open-Meteo
    │
    └─ 备用策略:
        ├─ QWeather 失败 → 切换到 Open-Meteo
        └─ Open-Meteo 失败 → 切换到 QWeather
```

---

## 核心组件设计

### 3.1 组件职责

| 组件名称 | 职责 | 参考 iOS 文件 |
|---------|------|--------------|
| `WeatherProvider` | 天气数据提供者接口 | `WeatherProvider.swift` |
| `OpenMeteoProvider` | Open-Meteo API 适配器 | `OpenMeteoProvider.swift` |
| `QWeatherProvider` | 和风天气 API 适配器 | `QWeatherProvider.swift` |
| `WeatherRouter` | 智能路由和容错管理 | `WeatherRouter.swift` |
| `WeatherConfig` | API Key 配置管理 | `WeatherAPIConfig.swift` |
| `UnifiedWeatherData` | 统一天气数据模型 | `WeatherProvider.swift:15` |
| `LocationHelper` | 位置判断工具 | `WeatherProvider.swift:110` |

### 3.2 数据模型

**统一天气数据结构**（所有 Provider 都返回此格式）:

```kotlin
data class UnifiedWeatherData(
    val list: List<UnifiedWeatherItem>
)

data class UnifiedWeatherItem(
    val dayTemp: Double,        // 白天温度（开尔文）
    val minTemp: Double,        // 最低温度（开尔文）
    val maxTemp: Double,        // 最高温度（开尔文）
    val nightTemp: Double,      // 夜间温度（开尔文）
    val eveTemp: Double,        // 傍晚温度（开尔文）
    val mornTemp: Double,       // 早晨温度（开尔文）
    val weatherCode: Int,       // 天气代码
    val weatherMain: String,    // 天气主类型（如 "Rain"）
    val weatherDescription: String,  // 天气描述（如 "light rain"）
    val weatherIcon: String     // 天气图标代码（如 "10d"）
)
```

---

## API 接口详解

### 4.1 Open-Meteo API

**官方文档**: https://open-meteo.com/en/docs

#### 请求示例

```http
GET https://api.open-meteo.com/v1/forecast
    ?latitude=39.9042
    &longitude=116.4074
    &daily=temperature_2m_max,temperature_2m_min,weathercode
    &temperature_unit=celsius
    &timezone=auto
    &forecast_days=7
```

#### 响应示例

```json
{
  "daily": {
    "time": ["2026-01-09", "2026-01-10", ...],
    "temperature_2m_max": [5.2, 6.8, ...],
    "temperature_2m_min": [-2.1, -1.3, ...],
    "weathercode": [3, 61, ...]
  }
}
```

#### WMO 天气代码映射

| 代码 | 含义 | 对应 weatherMain |
|------|------|------------------|
| 0 | 晴天 | Clear |
| 1-3 | 多云 | Clouds |
| 45,48 | 雾 | Fog |
| 51-67 | 雨 | Rain |
| 71-86 | 雪 | Snow |
| 95-99 | 雷暴 | Thunderstorm |

**完整映射逻辑**: 参考 `OpenMeteoProvider.swift:114-165`

---

### 4.2 和风天气 API

**官方文档**: https://dev.qweather.com/docs/api/weather/weather-daily-forecast/

#### 请求示例

```http
GET https://p42mtekqgk.re.qweatherapi.com/v7/weather/7d
    ?location=116.4074,39.9042
    &key=3f53759a415245dbabc8e6f96a7b18bb
```

⚠️ **重要**:
1. 经纬度顺序是 `longitude,latitude`（经度在前）
2. 每个 API Key 有专属域名，不能使用通用域名

#### 响应示例

```json
{
  "code": "200",
  "updateTime": "2026-01-09T14:00+08:00",
  "daily": [
    {
      "fxDate": "2026-01-09",
      "tempMax": "6",
      "tempMin": "-2",
      "textDay": "多云",
      "iconDay": "101"
    }
  ]
}
```

#### 和风天气图标代码映射

| 代码 | 含义 | 对应图标 |
|------|------|---------|
| 100 | 晴 | 01d |
| 101-103 | 多云 | 02d |
| 104 | 阴 | 04d |
| 300-318 | 雨 | 10d |
| 400-410 | 雪 | 13d |
| 499-515 | 雾霾 | 50d |

**完整映射逻辑**: 参考 `QWeatherProvider.swift:211-224`

---

## 代码实现示例

### 5.1 配置类 (WeatherConfig.kt)

```kotlin
object WeatherConfig {

    // ========== 和风天气配置 ==========

    /**
     * 和风天气 API Key（免费版）
     * 获取步骤：
     * 1. 访问 https://dev.qweather.com/
     * 2. 注册并创建免费订阅应用
     * 3. 获取 API Key
     */
    const val QWEATHER_API_KEY = "3f53759a415245dbabc8e6f96a7b18bb"

    /**
     * 和风天气 API 主机（个性化域名）
     * ⚠️ 重要：每个 API Key 有不同的专属域名
     * 获取方法：
     * 1. 登录 https://dev.qweather.com/
     * 2. 控制台 → 应用管理 → 查看 "API Host" 字段
     */
    const val QWEATHER_HOST = "p42mtekqgk.re.qweatherapi.com"

    // ========== Open-Meteo 配置 ==========

    /**
     * Open-Meteo 无需 API Key，完全免费
     */
    const val OPEN_METEO_HOST = "api.open-meteo.com"

    // ========== 验证方法 ==========

    /**
     * 检查和风天气是否已配置
     */
    fun isQWeatherConfigured(): Boolean {
        return QWEATHER_API_KEY != "YOUR_QWEATHER_API_KEY" && QWEATHER_API_KEY.isNotEmpty()
    }
}
```

---

### 5.2 位置判断工具 (LocationHelper.kt)

```kotlin
object LocationHelper {

    /**
     * 判断经纬度是否在中国大陆
     *
     * 参考 iOS 端: WeatherProvider.swift:112
     *
     * @param latitude 纬度
     * @param longitude 经度
     * @return true 表示在中国大陆
     */
    fun isInMainlandChina(latitude: Double, longitude: Double): Boolean {
        // 中国大陆经纬度范围（粗略判断）
        // 经度：73.5°E - 135.1°E
        // 纬度：18.2°N - 53.5°N
        val isLongitudeInRange = longitude in 73.5..135.1
        val isLatitudeInRange = latitude in 18.2..53.5

        return isLongitudeInRange && isLatitudeInRange
    }
}
```

---

### 5.3 天气提供者接口 (WeatherProvider.kt)

```kotlin
/**
 * 天气数据提供者接口
 * 所有 API 适配器都需实现此接口
 *
 * 参考 iOS 端: WeatherProvider.swift:57
 */
interface WeatherProvider {

    /**
     * 提供者名称（用于日志）
     */
    val providerName: String

    /**
     * 根据经纬度获取天气数据
     *
     * @param latitude 纬度
     * @param longitude 经度
     * @param onSuccess 成功回调
     * @param onError 失败回调
     */
    fun fetchWeather(
        latitude: Double,
        longitude: Double,
        onSuccess: (UnifiedWeatherData) -> Unit,
        onError: (Exception) -> Unit
    )
}
```

---

### 5.4 Open-Meteo 提供者 (OpenMeteoProvider.kt)

```kotlin
import okhttp3.OkHttpClient
import okhttp3.Request
import com.google.gson.Gson
import kotlinx.coroutines.*

/**
 * Open-Meteo 天气数据提供者（完全免费，无需 API Key）
 *
 * 参考 iOS 端: OpenMeteoProvider.swift
 */
class OpenMeteoProvider(
    private val httpClient: OkHttpClient = OkHttpClient(),
    private val gson: Gson = Gson()
) : WeatherProvider {

    override val providerName = "Open-Meteo"

    override fun fetchWeather(
        latitude: Double,
        longitude: Double,
        onSuccess: (UnifiedWeatherData) -> Unit,
        onError: (Exception) -> Unit
    ) {
        val url = buildURL(latitude, longitude)

        CoroutineScope(Dispatchers.IO).launch {
            try {
                val request = Request.Builder()
                    .url(url)
                    .build()

                val response = httpClient.newCall(request).execute()
                val responseBody = response.body?.string()

                if (!response.isSuccessful || responseBody == null) {
                    withContext(Dispatchers.Main) {
                        onError(Exception("Network error: ${response.code}"))
                    }
                    return@launch
                }

                val weatherData = parseResponse(responseBody)

                withContext(Dispatchers.Main) {
                    onSuccess(weatherData)
                }

            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    onError(e)
                }
            }
        }
    }

    /**
     * 构建 API 请求 URL
     * 参考 iOS: OpenMeteoProvider.swift:52
     */
    private fun buildURL(latitude: Double, longitude: Double): String {
        return "https://${WeatherConfig.OPEN_METEO_HOST}/v1/forecast" +
                "?latitude=$latitude" +
                "&longitude=$longitude" +
                "&daily=temperature_2m_max,temperature_2m_min,weathercode" +
                "&temperature_unit=celsius" +
                "&timezone=auto" +
                "&forecast_days=7"
    }

    /**
     * 解析 API 响应
     * 参考 iOS: OpenMeteoProvider.swift:70
     */
    private fun parseResponse(json: String): UnifiedWeatherData {
        val response = gson.fromJson(json, OpenMeteoResponse::class.java)

        val items = mutableListOf<UnifiedWeatherItem>()
        val count = minOf(7, response.daily.time.size)

        for (i in 0 until count) {
            val maxTemp = response.daily.temperature_2m_max[i]
            val minTemp = response.daily.temperature_2m_min[i]
            val weatherCode = response.daily.weathercode[i]

            // 估算其他时段温度（简单线性插值）
            val dayTemp = maxTemp - 2.0
            val nightTemp = minTemp + 2.0
            val mornTemp = minTemp + 3.0
            val eveTemp = maxTemp - 3.0

            val item = UnifiedWeatherItem(
                dayTemp = celsiusToKelvin(dayTemp),
                minTemp = celsiusToKelvin(minTemp),
                maxTemp = celsiusToKelvin(maxTemp),
                nightTemp = celsiusToKelvin(nightTemp),
                eveTemp = celsiusToKelvin(eveTemp),
                mornTemp = celsiusToKelvin(mornTemp),
                weatherCode = weatherCode,
                weatherMain = mapWeatherCodeToMain(weatherCode),
                weatherDescription = mapWeatherCodeToDescription(weatherCode),
                weatherIcon = mapWeatherCodeToIcon(weatherCode)
            )
            items.add(item)
        }

        return UnifiedWeatherData(items)
    }

    // ========== 温度转换 ==========

    private fun celsiusToKelvin(celsius: Double): Double {
        return celsius + 273.15
    }

    // ========== WMO 天气代码映射 ==========
    // 参考 iOS: OpenMeteoProvider.swift:114-165

    private fun mapWeatherCodeToMain(code: Int): String {
        return when (code) {
            0 -> "Clear"
            in 1..3 -> "Clouds"
            45, 48 -> "Fog"
            in 51..67, 80, 81, 82 -> "Rain"
            in 71..77, 85, 86 -> "Snow"
            95, 96, 99 -> "Thunderstorm"
            else -> "Unknown"
        }
    }

    private fun mapWeatherCodeToDescription(code: Int): String {
        return when (code) {
            0 -> "clear sky"
            1 -> "mainly clear"
            2 -> "partly cloudy"
            3 -> "overcast"
            45, 48 -> "fog"
            in 51..55 -> "drizzle"
            56, 57 -> "freezing drizzle"
            61 -> "slight rain"
            63 -> "moderate rain"
            65 -> "heavy rain"
            66, 67 -> "freezing rain"
            71 -> "slight snow"
            73 -> "moderate snow"
            75 -> "heavy snow"
            77 -> "snow grains"
            80, 81, 82 -> "rain showers"
            85, 86 -> "snow showers"
            95 -> "thunderstorm"
            96, 99 -> "thunderstorm with hail"
            else -> "unknown"
        }
    }

    private fun mapWeatherCodeToIcon(code: Int): String {
        return when (code) {
            0 -> "01d"
            1, 2 -> "02d"
            3 -> "04d"
            45, 48 -> "50d"
            in 51..57 -> "09d"
            in 61..67, 80, 81, 82 -> "10d"
            in 71..77, 85, 86 -> "13d"
            95, 96, 99 -> "11d"
            else -> "01d"
        }
    }

    // ========== 数据模型 ==========

    private data class OpenMeteoResponse(
        val daily: DailyWeather
    )

    private data class DailyWeather(
        val time: List<String>,
        val temperature_2m_max: List<Double>,
        val temperature_2m_min: List<Double>,
        val weathercode: List<Int>
    )
}
```

---

### 5.5 和风天气提供者 (QWeatherProvider.kt)

```kotlin
import android.util.Log
import okhttp3.OkHttpClient
import okhttp3.Request
import com.google.gson.Gson
import kotlinx.coroutines.*

/**
 * 和风天气数据提供者（国内免费额度充足）
 *
 * 参考 iOS 端: QWeatherProvider.swift
 */
class QWeatherProvider(
    private val httpClient: OkHttpClient = OkHttpClient(),
    private val gson: Gson = Gson()
) : WeatherProvider {

    companion object {
        private const val TAG = "QWeatherProvider"
    }

    override val providerName = "QWeather"

    private val apiKey = WeatherConfig.QWEATHER_API_KEY

    override fun fetchWeather(
        latitude: Double,
        longitude: Double,
        onSuccess: (UnifiedWeatherData) -> Unit,
        onError: (Exception) -> Unit
    ) {
        // 检查 API Key
        if (!WeatherConfig.isQWeatherConfigured()) {
            Log.w(TAG, "⚠️ QWeather API Key 未配置")
            onError(Exception("QWeather API Key missing"))
            return
        }

        val url = buildURL(latitude, longitude)
        Log.d(TAG, "🌐 QWeather 请求 URL: $url")

        CoroutineScope(Dispatchers.IO).launch {
            try {
                val request = Request.Builder()
                    .url(url)
                    .build()

                val response = httpClient.newCall(request).execute()
                val responseBody = response.body?.string()

                Log.d(TAG, "🔍 QWeather 原始响应: $responseBody")

                if (!response.isSuccessful || responseBody == null) {
                    withContext(Dispatchers.Main) {
                        onError(Exception("Network error: ${response.code}"))
                    }
                    return@launch
                }

                val weatherData = parseResponse(responseBody)

                withContext(Dispatchers.Main) {
                    Log.d(TAG, "✅ QWeather 天气数据获取成功")
                    onSuccess(weatherData)
                }

            } catch (e: Exception) {
                Log.e(TAG, "❌ QWeather parsing error", e)
                withContext(Dispatchers.Main) {
                    onError(e)
                }
            }
        }
    }

    /**
     * 构建 API 请求 URL
     * 参考 iOS: QWeatherProvider.swift:73
     */
    private fun buildURL(latitude: Double, longitude: Double): String {
        // ⚠️ 注意：和风天气是经度在前，纬度在后
        return "https://${WeatherConfig.QWEATHER_HOST}/v7/weather/7d" +
                "?location=$longitude,$latitude" +
                "&key=$apiKey"
    }

    /**
     * 解析 API 响应
     * 参考 iOS: QWeatherProvider.swift:90
     */
    private fun parseResponse(json: String): UnifiedWeatherData {
        val response = gson.fromJson(json, QWeatherResponse::class.java)

        // 检查新格式错误对象
        response.error?.let { error ->
            Log.e(TAG, "❌ QWeather API 返回错误 (新格式):")
            Log.e(TAG, "   状态码: ${error.status}")
            Log.e(TAG, "   标题: ${error.title}")
            Log.e(TAG, "   详情: ${error.detail}")

            // 特殊处理 403 Invalid Host 错误
            if (error.status == 403 && error.title.contains("Invalid Host")) {
                Log.e(TAG, "")
                Log.e(TAG, "⚠️  403 Invalid Host 错误说明:")
                Log.e(TAG, "   这个错误通常表示 API Host 配置不正确")
                Log.e(TAG, "")
                Log.e(TAG, "🔧 当前配置:")
                Log.e(TAG, "   API Host: ${WeatherConfig.QWEATHER_HOST}")
                Log.e(TAG, "   API Key: ${apiKey.take(8)}***")
                Log.e(TAG, "")
                Log.e(TAG, "💡 解决方案:")
                Log.e(TAG, "   1. 访问 https://dev.qweather.com/")
                Log.e(TAG, "   2. 控制台 → 应用管理 → 查看「API Host」字段")
                Log.e(TAG, "   3. 更新 WeatherConfig.kt 中的 QWEATHER_HOST")
                Log.e(TAG, "")
            }

            throw Exception("QWeather API error: ${error.title}")
        }

        // 检查旧格式错误消息
        response.message?.let { message ->
            Log.e(TAG, "❌ QWeather API 返回错误 (旧格式): $message")
            throw Exception("QWeather API error: $message")
        }

        // 检查状态码
        val code = response.code ?: throw Exception("QWeather API 响应缺少状态码")

        if (code != "200") {
            val errorDesc = getQWeatherErrorDescription(code)
            Log.e(TAG, "❌ QWeather API error: code=$code")
            Log.e(TAG, "   错误说明: $errorDesc")
            throw Exception("QWeather API error: $errorDesc")
        }

        // 检查天气数据
        val dailyData = response.daily
        if (dailyData.isNullOrEmpty()) {
            Log.e(TAG, "❌ QWeather API 响应中没有天气数据")
            throw Exception("Empty weather data")
        }

        Log.d(TAG, "✅ QWeather API 返回 ${dailyData.size} 天天气数据")

        val items = mutableListOf<UnifiedWeatherItem>()
        val count = minOf(7, dailyData.size)

        for (i in 0 until count) {
            val day = dailyData[i]

            // 和风天气返回摄氏度字符串，需要转换
            val maxTemp = day.tempMax.toDoubleOrNull() ?: 25.0
            val minTemp = day.tempMin.toDoubleOrNull() ?: 15.0

            // 估算其他时段温度
            val dayTemp = maxTemp - 2.0
            val nightTemp = minTemp + 2.0
            val mornTemp = minTemp + 3.0
            val eveTemp = maxTemp - 3.0

            val item = UnifiedWeatherItem(
                dayTemp = celsiusToKelvin(dayTemp),
                minTemp = celsiusToKelvin(minTemp),
                maxTemp = celsiusToKelvin(maxTemp),
                nightTemp = celsiusToKelvin(nightTemp),
                eveTemp = celsiusToKelvin(eveTemp),
                mornTemp = celsiusToKelvin(mornTemp),
                weatherCode = day.iconDay.toIntOrNull() ?: 100,
                weatherMain = day.textDay,
                weatherDescription = day.textDay,
                weatherIcon = mapQWeatherIconToOpenWeather(day.iconDay)
            )
            items.add(item)
        }

        return UnifiedWeatherData(items)
    }

    // ========== 和风天气错误码说明 ==========
    // 参考 iOS: QWeatherProvider.swift:189

    private fun getQWeatherErrorDescription(code: String): String {
        return when (code) {
            "204" -> "请求成功，但你查询的地区暂时没有你需要的数据"
            "400" -> "请求错误，可能包含错误的请求参数或缺少必选的请求参数"
            "401" -> "认证失败，可能使用了错误的 API Key"
            "402" -> "超过访问次数或余额不足以支持继续访问服务"
            "403" -> "无访问权限，可能是绑定的 PackageName、BundleID 不一致"
            "404" -> "查询的数据或地区不存在"
            "429" -> "超过限定的QPM（每分钟访问次数）"
            "500" -> "无响应或超时"
            else -> "未知错误码: $code"
        }
    }

    // ========== 温度转换 ==========

    private fun celsiusToKelvin(celsius: Double): Double {
        return celsius + 273.15
    }

    // ========== 和风天气图标映射 ==========
    // 参考 iOS: QWeatherProvider.swift:211

    private fun mapQWeatherIconToOpenWeather(qweatherIcon: String): String {
        return when (qweatherIcon) {
            "100" -> "01d"  // 晴
            "101", "102", "103" -> "02d"  // 多云
            "104" -> "04d"  // 阴
            in listOf("300", "301", "305", "306", "307", "308", "309", "310",
                     "311", "312", "313", "314", "315", "316", "317", "318") -> "10d"  // 雨
            "350", "351" -> "09d"  // 阵雨
            in listOf("400", "401", "402", "403", "404", "405", "406",
                     "407", "408", "409", "410") -> "13d"  // 雪
            in listOf("499", "500", "501", "502", "503", "504", "507", "508",
                     "509", "510", "511", "512", "513", "514", "515") -> "50d"  // 雾霾沙尘
            else -> "01d"
        }
    }

    // ========== 数据模型 ==========

    private data class QWeatherResponse(
        val code: String?,
        val daily: List<QWeatherDaily>?,
        val updateTime: String?,
        val message: String?,  // 旧格式错误消息
        val error: QWeatherError?  // 新格式错误对象
    )

    private data class QWeatherError(
        val status: Int,
        val type: String?,
        val title: String,
        val detail: String
    )

    private data class QWeatherDaily(
        val fxDate: String,
        val tempMax: String,
        val tempMin: String,
        val iconDay: String,
        val textDay: String,
        val iconNight: String?,
        val textNight: String?
    )
}
```

---

### 5.6 智能路由器 (WeatherRouter.kt)

```kotlin
import android.util.Log

/**
 * 智能天气数据路由器
 * 根据用户位置自动选择最优数据源
 *
 * 参考 iOS 端: WeatherRouter.swift
 */
class WeatherRouter private constructor() {

    companion object {
        private const val TAG = "WeatherRouter"

        // 单例
        val instance: WeatherRouter by lazy { WeatherRouter() }
    }

    // 数据源枚举
    enum class DataSource {
        OPEN_METEO,
        QWEATHER;

        override fun toString(): String {
            return when (this) {
                OPEN_METEO -> "Open-Meteo"
                QWEATHER -> "QWeather"
            }
        }
    }

    // 提供者映射
    private val providers: Map<DataSource, WeatherProvider> = mapOf(
        DataSource.OPEN_METEO to OpenMeteoProvider(),
        DataSource.QWEATHER to QWeatherProvider()
    )

    // 当前使用的数据源（用于日志和调试）
    var currentDataSource: DataSource? = null
        private set

    /**
     * 获取天气数据（自动路由）
     * 参考 iOS: WeatherRouter.swift:56
     */
    fun fetchWeather(
        latitude: Double,
        longitude: Double,
        onSuccess: (UnifiedWeatherData) -> Unit,
        onError: (Exception) -> Unit
    ) {
        // 1. 选择数据源
        val dataSource = selectDataSource(latitude, longitude)
        currentDataSource = dataSource

        // 2. 获取对应的提供者
        val provider = providers[dataSource]
        if (provider == null) {
            Log.e(TAG, "❌ 无法找到天气数据提供者: $dataSource")
            onError(Exception("Weather provider not found"))
            return
        }

        Log.d(TAG, "🌤 使用 ${provider.providerName} 获取天气数据")

        // 3. 调用提供者获取数据
        provider.fetchWeather(
            latitude = latitude,
            longitude = longitude,
            onSuccess = { weatherData ->
                Log.d(TAG, "✅ ${provider.providerName} 天气数据获取成功")
                onSuccess(weatherData)
            },
            onError = { error ->
                Log.e(TAG, "❌ ${provider.providerName} 天气数据获取失败: ${error.message}")

                // 失败时尝试备用数据源
                fallbackToAlternativeSource(
                    primarySource = dataSource,
                    latitude = latitude,
                    longitude = longitude,
                    onSuccess = onSuccess,
                    onError = onError
                )
            }
        )
    }

    /**
     * 根据用户位置智能选择天气数据源
     * 参考 iOS: WeatherRouter.swift:40
     */
    private fun selectDataSource(latitude: Double, longitude: Double): DataSource {
        return if (LocationHelper.isInMainlandChina(latitude, longitude)) {
            // 中国大陆使用和风天气（数据更准确，响应更快）
            Log.d(TAG, "📍 位置在中国大陆，使用和风天气")
            DataSource.QWEATHER
        } else {
            // 国外使用 Open-Meteo（完全免费，无需 API Key）
            Log.d(TAG, "🌍 位置在海外，使用 Open-Meteo")
            DataSource.OPEN_METEO
        }
    }

    /**
     * 当主数据源失败时，尝试使用备用数据源
     * 参考 iOS: WeatherRouter.swift:103
     */
    private fun fallbackToAlternativeSource(
        primarySource: DataSource,
        latitude: Double,
        longitude: Double,
        onSuccess: (UnifiedWeatherData) -> Unit,
        onError: (Exception) -> Unit
    ) {
        // 选择备用数据源
        val fallbackSource = if (primarySource == DataSource.QWEATHER) {
            DataSource.OPEN_METEO
        } else {
            DataSource.QWEATHER
        }

        val fallbackProvider = providers[fallbackSource]
        if (fallbackProvider == null) {
            onError(Exception("Fallback provider not found"))
            return
        }

        Log.d(TAG, "🔄 尝试使用备用数据源: ${fallbackProvider.providerName}")

        fallbackProvider.fetchWeather(
            latitude = latitude,
            longitude = longitude,
            onSuccess = { weatherData ->
                Log.d(TAG, "✅ 备用数据源 ${fallbackProvider.providerName} 成功")
                onSuccess(weatherData)
            },
            onError = { fallbackError ->
                Log.e(TAG, "❌ 备用数据源也失败了: ${fallbackError.message}")
                onError(fallbackError)
            }
        )
    }

    /**
     * 手动指定天气数据源（仅用于测试和调试）
     * 参考 iOS: WeatherRouter.swift:138
     */
    fun fetchWeatherWithSource(
        latitude: Double,
        longitude: Double,
        forceDataSource: DataSource,
        onSuccess: (UnifiedWeatherData) -> Unit,
        onError: (Exception) -> Unit
    ) {
        val provider = providers[forceDataSource]
        if (provider == null) {
            onError(Exception("Provider not found"))
            return
        }

        Log.d(TAG, "🔧 强制使用数据源: ${provider.providerName}")

        provider.fetchWeather(
            latitude = latitude,
            longitude = longitude,
            onSuccess = onSuccess,
            onError = onError
        )
    }
}
```

---

## 配置说明

### 6.1 添加依赖

在 `build.gradle (Module: app)` 中添加：

```gradle
dependencies {
    // 网络请求
    implementation 'com.squareup.okhttp3:okhttp:4.11.0'

    // JSON 解析
    implementation 'com.google.code.gson:gson:2.10.1'

    // 协程
    implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3'
    implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3'
}
```

### 6.2 权限配置

在 `AndroidManifest.xml` 中添加：

```xml
<!-- 网络权限 -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

<!-- 位置权限（用于判断国内外） -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### 6.3 配置和风天气 API

**步骤 1**: 获取 API Key 和专属域名

1. 访问 [和风天气开发平台](https://dev.qweather.com/)
2. 注册并登录
3. 控制台 → 应用管理 → 创建应用 → 选择「免费订阅」
4. 获取以下信息：
   - **API Key**: 32位字符串（如：`3f53759a415245dbabc8e6f96a7b18bb`）
   - **API Host**: 专属域名（如：`p42mtekqgk.re.qweatherapi.com`）

**步骤 2**: 更新配置文件

编辑 `WeatherConfig.kt`:

```kotlin
object WeatherConfig {
    const val QWEATHER_API_KEY = "你的API_Key"  // ⚠️ 替换这里
    const val QWEATHER_HOST = "你的专属域名"    // ⚠️ 替换这里
}
```

---

## 测试验证

### 7.1 基础测试代码

```kotlin
import android.os.Bundle
import android.util.Log
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {

    companion object {
        private const val TAG = "WeatherTest"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        // 测试天气 API
        testWeatherAPI()
    }

    private fun testWeatherAPI() {
        val router = WeatherRouter.instance

        // 测试 1: 国内位置（北京）
        Log.d(TAG, "========== 测试 1: 国内位置（北京） ==========")
        router.fetchWeather(
            latitude = 39.9042,
            longitude = 116.4074,
            onSuccess = { weatherData ->
                Log.d(TAG, "✅ 获取成功，数据源: ${router.currentDataSource}")
                Log.d(TAG, "   天气数量: ${weatherData.list.size} 天")
                weatherData.list.firstOrNull()?.let { item ->
                    Log.d(TAG, "   今日天气: ${item.weatherDescription}")
                    Log.d(TAG, "   温度: ${kelvinToCelsius(item.minTemp)}°C ~ ${kelvinToCelsius(item.maxTemp)}°C")
                }
            },
            onError = { error ->
                Log.e(TAG, "❌ 获取失败: ${error.message}", error)
            }
        )

        // 测试 2: 国外位置（纽约）
        Log.d(TAG, "========== 测试 2: 国外位置（纽约） ==========")
        router.fetchWeather(
            latitude = 40.7128,
            longitude = -74.0060,
            onSuccess = { weatherData ->
                Log.d(TAG, "✅ 获取成功，数据源: ${router.currentDataSource}")
                Log.d(TAG, "   天气数量: ${weatherData.list.size} 天")
            },
            onError = { error ->
                Log.e(TAG, "❌ 获取失败: ${error.message}", error)
            }
        )

        // 测试 3: 强制使用 Open-Meteo
        Log.d(TAG, "========== 测试 3: 强制使用 Open-Meteo ==========")
        router.fetchWeatherWithSource(
            latitude = 39.9042,
            longitude = 116.4074,
            forceDataSource = WeatherRouter.DataSource.OPEN_METEO,
            onSuccess = { weatherData ->
                Log.d(TAG, "✅ Open-Meteo 测试成功")
            },
            onError = { error ->
                Log.e(TAG, "❌ Open-Meteo 测试失败: ${error.message}")
            }
        )
    }

    private fun kelvinToCelsius(kelvin: Double): Int {
        return (kelvin - 273.15).toInt()
    }
}
```

### 7.2 预期日志输出

**国内位置（使用和风天气）**:

```
D/WeatherTest: ========== 测试 1: 国内位置（北京） ==========
D/WeatherRouter: 📍 位置在中国大陆，使用和风天气
D/WeatherRouter: 🌤 使用 QWeather 获取天气数据
D/QWeatherProvider: 🌐 QWeather 请求 URL: https://p42mtekqgk.re.qweatherapi.com/v7/weather/7d?location=116.4074,39.9042&key=3f53***
D/QWeatherProvider: ✅ QWeather API 返回 7 天天气数据
D/WeatherRouter: ✅ QWeather 天气数据获取成功
D/WeatherTest: ✅ 获取成功，数据源: QWEATHER
D/WeatherTest:    天气数量: 7 天
D/WeatherTest:    今日天气: 多云
D/WeatherTest:    温度: -2°C ~ 6°C
```

**国外位置（使用 Open-Meteo）**:

```
D/WeatherTest: ========== 测试 2: 国外位置（纽约） ==========
D/WeatherRouter: 🌍 位置在海外，使用 Open-Meteo
D/WeatherRouter: 🌤 使用 Open-Meteo 获取天气数据
D/WeatherRouter: ✅ Open-Meteo 天气数据获取成功
D/WeatherTest: ✅ 获取成功，数据源: OPEN_METEO
D/WeatherTest:    天气数量: 7 天
```

### 7.3 单元测试示例

```kotlin
import org.junit.Test
import org.junit.Assert.*

class LocationHelperTest {

    @Test
    fun testIsInMainlandChina_Beijing_ReturnsTrue() {
        val result = LocationHelper.isInMainlandChina(39.9042, 116.4074)
        assertTrue("北京应该被识别为中国大陆", result)
    }

    @Test
    fun testIsInMainlandChina_Shanghai_ReturnsTrue() {
        val result = LocationHelper.isInMainlandChina(31.2304, 121.4737)
        assertTrue("上海应该被识别为中国大陆", result)
    }

    @Test
    fun testIsInMainlandChina_NewYork_ReturnsFalse() {
        val result = LocationHelper.isInMainlandChina(40.7128, -74.0060)
        assertFalse("纽约不应该被识别为中国大陆", result)
    }

    @Test
    fun testIsInMainlandChina_Tokyo_ReturnsFalse() {
        val result = LocationHelper.isInMainlandChina(35.6762, 139.6503)
        assertFalse("东京不应该被识别为中国大陆", result)
    }

    @Test
    fun testIsInMainlandChina_HongKong_ReturnsFalse() {
        // 香港虽然在地理范围内，但不是大陆
        // 这里粗略判断可能会识别为true，实际可能需要更精确的边界
        val result = LocationHelper.isInMainlandChina(22.3193, 114.1694)
        // 根据实际需求调整
    }
}
```

---

## 常见问题

### 8.1 和风天气返回 403 Invalid Host 错误

**原因**: API Key 和 API Host 不匹配

**解决方案**:

1. 登录 [和风天气控制台](https://dev.qweather.com/)
2. 进入「应用管理」→ 你的应用
3. 查看「API Host」字段（通常是个性化域名，如 `p42mtekqgk.re.qweatherapi.com`）
4. 复制完整域名并更新 `WeatherConfig.kt` 中的 `QWEATHER_HOST`

⚠️ **重要**: 不要使用通用域名 `devapi.qweather.com`，必须使用专属域名

---

### 8.2 和风天气返回 401 认证失败

**原因**: API Key 错误或格式不正确

**解决方案**:

1. 检查 `WeatherConfig.kt` 中的 `QWEATHER_API_KEY` 是否正确
2. 确认 API Key 是32位字符串
3. 检查是否有多余的空格或换行符
4. 重新从控制台复制 API Key

---

### 8.3 温度单位转换

项目内部使用**开尔文（Kelvin）**作为统一单位，显示时需要转换：

```kotlin
// 开尔文转摄氏度
fun kelvinToCelsius(kelvin: Double): Double {
    return kelvin - 273.15
}

// 开尔文转华氏度
fun kelvinToFahrenheit(kelvin: Double): Double {
    return (kelvin - 273.15) * 9/5 + 32
}
```

---

### 8.4 网络请求超时处理

建议配置 OkHttpClient 超时参数：

```kotlin
val httpClient = OkHttpClient.Builder()
    .connectTimeout(10, TimeUnit.SECONDS)
    .readTimeout(10, TimeUnit.SECONDS)
    .writeTimeout(10, TimeUnit.SECONDS)
    .build()
```

---

### 8.5 ProGuard 混淆配置

如果项目开启了混淆，需要在 `proguard-rules.pro` 中添加：

```proguard
# Gson
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.yourpackage.weather.** { *; }

# OkHttp
-dontwarn okhttp3.**
-keep class okhttp3.** { *; }
```

---

## 附录

### A. iOS 代码对照表

| 功能 | iOS 文件 | iOS 行号 | 安卓对应组件 |
|------|---------|---------|-------------|
| 智能路由 | WeatherRouter.swift | 40-51 | WeatherRouter.kt |
| 位置判断 | WeatherProvider.swift | 112-119 | LocationHelper.kt |
| Open-Meteo 请求 | OpenMeteoProvider.swift | 52-68 | OpenMeteoProvider.kt |
| QWeather 请求 | QWeatherProvider.swift | 73-88 | QWeatherProvider.kt |
| WMO 代码映射 | OpenMeteoProvider.swift | 114-165 | OpenMeteoProvider.kt |
| 和风图标映射 | QWeatherProvider.swift | 211-224 | QWeatherProvider.kt |
| API 配置 | WeatherAPIConfig.swift | 全文 | WeatherConfig.kt |

### B. 相关文档链接

- **Open-Meteo 官方文档**: https://open-meteo.com/en/docs
- **和风天气 API 文档**: https://dev.qweather.com/docs/api/
- **和风天气控制台**: https://console.qweather.com/
- **OkHttp 官方文档**: https://square.github.io/okhttp/
- **Gson 官方文档**: https://github.com/google/gson

---

## 📝 变更记录

| 版本 | 日期 | 变更内容 |
|------|------|---------|
| v1.0 | 2026-01-09 | 初始版本，基于 iOS 端实现文档 |

---

## 👥 联系方式

如有疑问，请联系：
- **技术支持**: [你的联系方式]
- **项目仓库**: [GitHub 地址]

---

**文档结束** 🎉
