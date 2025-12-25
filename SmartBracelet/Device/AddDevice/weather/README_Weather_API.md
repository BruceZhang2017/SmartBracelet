# 天气 API 替换方案说明

## 📖 概述

本项目已将付费的 **OpenWeatherMap API** 替换为 **免费的双源天气 API 方案**：

- **Open-Meteo**（海外/全球）：完全免费，无需 API Key，无调用限制
- **和风天气 QWeather**（中国大陆）：免费额度充足，数据更准确

系统会根据用户位置**自动选择最优数据源**，并在主数据源失败时自动切换到备用数据源。

---

## 🏗 架构设计

```
┌─────────────────────────────────────┐
│    OpenWeatherManager.swift         │  ← 业务层（无需修改）
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      WeatherRouter.swift            │  ← 智能路由器
│  (自动选择最佳数据源 + 备用切换)      │
└──────────────┬──────────────────────┘
               │
       ┌───────┴────────┐
       │                │
┌──────▼──────┐  ┌──────▼──────┐
│ Open-Meteo  │  │  QWeather   │
│  Provider   │  │  Provider   │
└─────────────┘  └─────────────┘
```

---

## 🚀 快速开始

### 1️⃣ 配置和风天气 API Key（可选，推荐）

虽然 **Open-Meteo 无需配置即可使用**，但为了获得更好的国内天气数据，建议配置和风天气：

**步骤：**

1. 访问 [和风天气开发平台](https://dev.qweather.com/)
2. 注册账号并登录
3. 在控制台创建项目，选择 **「免费订阅」**
4. 获取 **API Key**（格式：32位字符串）
5. 打开 `WeatherAPIConfig.swift`，填写 API Key：

```swift
struct WeatherAPIConfig {
    static let qWeatherAPIKey = "你的和风天气API_Key"  // ⚠️ 替换这里
}
```

### 2️⃣ 运行项目

无需其他配置，直接运行项目即可：

- **如果配置了和风天气**：国内用户自动使用和风，国外用户使用 Open-Meteo
- **如果未配置和风天气**：所有用户使用 Open-Meteo（仍然完全免费可用）

---

## 📂 文件说明

| 文件                          | 作用                                      |
|-------------------------------|-------------------------------------------|
| `WeatherProvider.swift`       | 定义统一的天气数据协议和模型              |
| `OpenMeteoProvider.swift`     | Open-Meteo API 适配器（无需 API Key）     |
| `QWeatherProvider.swift`      | 和风天气 API 适配器（需要 API Key）       |
| `WeatherRouter.swift`         | 智能路由管理器（自动选择最优数据源）      |
| `WeatherAPIConfig.swift`      | API Key 配置中心                          |
| `OpenWeatherManager.swift`    | 业务层管理器（已更新为使用新 API）        |

---

## 🌍 数据源选择策略

### 自动路由规则

```
用户位置
    │
    ├─ 中国大陆（经度 73.5-135.1°E，纬度 18.2-53.5°N）
    │       │
    │       ├─ 和风天气已配置 → 使用和风天气 ✅
    │       └─ 和风天气未配置 → 使用 Open-Meteo 🔄
    │
    └─ 海外地区 → 使用 Open-Meteo ✅
```

### 备用策略

如果主数据源失败（网络错误、API 限流等），系统会**自动切换到备用数据源**：

- 和风天气失败 → 切换到 Open-Meteo
- Open-Meteo 失败 → 切换到和风天气

---

## 🧪 测试验证

### 方法 1：通过日志验证

运行 App 并查看 Xcode 控制台日志：

```
📍 获取到位置: lat=39.9042, lon=116.4074
📍 位置在中国大陆，使用和风天气
🌤 使用 QWeather 获取天气数据
✅ QWeather 天气数据获取成功
```

### 方法 2：手动测试不同数据源

在 `OpenWeatherManager.swift` 中临时添加代码：

```swift
// 强制测试 Open-Meteo
weatherRouter.fetchWeather(
    latitude: latitude,
    longitude: longitude,
    forceDataSource: .openMeteo,  // 强制使用 Open-Meteo
    onSuccess: { ... },
    onError: { ... }
)
```

---

## 💰 费用对比

| API 服务        | 费用            | 调用限制               | 是否需要 API Key |
|-----------------|-----------------|------------------------|------------------|
| OpenWeatherMap  | **付费**        | 免费版 1000次/天       | ✅ 需要          |
| Open-Meteo      | **完全免费**    | 无限制                 | ❌ 不需要        |
| 和风天气(免费版) | **免费**        | 非商业无限制           | ✅ 需要          |

---

## ⚠️ 注意事项

### 1. API Key 安全

- ✅ 推荐：将 API Key 存储在 **环境变量** 或 **Keychain** 中
- ❌ 不推荐：直接硬编码在代码中（当前为演示方便采用此方式）

### 2. 数据精度差异

- **和风天气**：国内数据更准确，支持空气质量、生活指数等
- **Open-Meteo**：全球数据均可用，但中国地区可能不如和风精确

### 3. 温度单位

- 现有代码保持使用 **开尔文（Kelvin）** 作为内部单位
- 显示时根据设备设置转换为 **摄氏度（°C）** 或 **华氏度（°F）**

---

## 🔧 高级配置

### 修改数据源选择逻辑

编辑 `WeatherRouter.swift` 的 `selectDataSource` 方法：

```swift
private func selectDataSource(...) -> WeatherDataSource {
    // 示例：强制所有用户使用 Open-Meteo
    return .openMeteo

    // 示例：根据语言选择
    if Locale.current.languageCode == "zh" {
        return .qWeather
    } else {
        return .openMeteo
    }
}
```

### 禁用备用数据源

编辑 `WeatherRouter.swift` 的 `fetchWeather` 方法，移除 `fallbackToAlternativeSource` 调用。

---

## 📞 支持

- **Open-Meteo 文档**：https://open-meteo.com/en/docs
- **和风天气文档**：https://dev.qweather.com/docs/

---

## ✅ 迁移检查清单

- [x] 创建统一天气数据协议 (`WeatherProvider.swift`)
- [x] 实现 Open-Meteo 适配器 (`OpenMeteoProvider.swift`)
- [x] 实现和风天气适配器 (`QWeatherProvider.swift`)
- [x] 创建智能路由管理器 (`WeatherRouter.swift`)
- [x] 更新业务层代码 (`OpenWeatherManager.swift`)
- [x] 创建 API 配置文件 (`WeatherAPIConfig.swift`)
- [ ] **配置和风天气 API Key**（可选但推荐）
- [ ] 测试验证天气数据获取
- [ ] 删除旧的 OpenWeatherMap 相关代码（可选）

---

## 🎉 完成！

现在你的项目已经成功迁移到免费的天气 API 方案！

**核心优势：**
✅ 完全免费，无需担心账单
✅ 智能路由，自动选择最优数据源
✅ 备用切换，提高数据获取成功率
✅ 向后兼容，无需修改业务逻辑
