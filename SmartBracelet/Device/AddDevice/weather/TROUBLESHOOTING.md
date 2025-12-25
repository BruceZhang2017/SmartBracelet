# 天气 API 故障排查指南

## 🚨 当前问题：和风天气 API 解析失败

### 问题描述

```
QWeather parsing error: keyNotFound(CodingKeys(stringValue: "code", intValue: nil)
❌ QWeather 天气数据获取失败: Failed to parse weather data
```

### 根本原因

和风天气 API 返回的 JSON 数据结构与代码预期不符，可能的原因：

1. **API Key 无效或权限不足**
   - API Key 过期
   - API Key 未正确配置
   - API Key 类型不匹配（商业版 vs 免费版）

2. **API 端点错误**
   - 免费版应使用 `devapi.qweather.com`
   - 商业版使用 `api.qweather.com`

3. **请求参数错误**
   - 经纬度格式不正确
   - 缺少必需参数

---

## ✅ 已实施的修复

### 1️⃣ 改进数据模型（容错处理）

**修改前：**
```swift
private struct QWeatherResponse: Codable {
    let code: String           // 必需字段，解析失败会崩溃
    let daily: [QWeatherDaily] // 必需字段，解析失败会崩溃
}
```

**修改后：**
```swift
private struct QWeatherResponse: Codable {
    let code: String?          // 可选字段，允许为空
    let daily: [QWeatherDaily]? // 可选字段，允许为空
    let message: String?       // 错误消息（仅在错误时存在）
}
```

### 2️⃣ 添加详细的调试日志

现在会打印：
- 🌐 请求的完整 URL
- 🔍 API 返回的原始 JSON 数据
- ❌ 详细的错误代码和说明

### 3️⃣ 添加错误码解释

自动识别和风天气的错误码：

| 错误码 | 说明 |
|--------|------|
| 200 | 成功 |
| 204 | 请求成功但数据为空 |
| 400 | 请求参数错误 |
| 401 | API Key 认证失败 ⚠️ |
| 402 | 超过访问次数 |
| 403 | 无访问权限（BundleID 不匹配）⚠️ |
| 404 | 数据或地区不存在 |
| 429 | 超过 QPM 限制 |
| 500 | 服务器错误 |

---

## 🔍 诊断步骤

### 第 1 步：重新运行 App，查看详细日志

运行 App 后，查看 Xcode 控制台，现在会显示：

```
📍 获取到位置: lat=22.59, lon=113.92
📍 位置在中国大陆，使用和风天气
🌐 QWeather 请求 URL: https://devapi.qweather.com/v7/weather/7d?location=113.92,22.59&key=3f5375...
🌤 使用 QWeather 获取天气数据
🔍 QWeather 原始响应: {"code":"401","message":"认证失败..."}
❌ QWeather API error: code=401
   错误说明: 认证失败，可能使用了错误的 API Key
```

### 第 2 步：根据错误码判断问题

#### ✅ 如果看到 `code=401`（认证失败）

**原因：** API Key 无效或错误

**解决方案：**

1. 访问 https://dev.qweather.com/
2. 登录账号，进入控制台
3. 检查 API Key 是否正确
4. 确认 API Key 的类型（应选择「免费订阅」）
5. 复制正确的 API Key
6. 修改 `WeatherAPIConfig.swift:21`：

```swift
static let qWeatherAPIKey = "你的正确API_Key"
```

#### ✅ 如果看到 `code=403`（无访问权限）

**原因：** BundleID 绑定不匹配

**解决方案：**

1. 在和风天气控制台检查「应用设置」
2. 确认是否绑定了特定的 BundleID
3. 如果绑定了，需要修改为你的 App 的 BundleID
4. 或者在控制台取消 BundleID 绑定（推荐用于测试）

#### ✅ 如果看到 `code=400`（请求错误）

**原因：** 请求参数格式不正确

**当前配置：**
```
location=经度,纬度 (例如: 113.92,22.59)
```

这个格式是正确的，如果还报错，可能需要：
1. 检查经纬度是否在有效范围内
2. 尝试使用城市 ID 代替经纬度

#### ✅ 如果完全解析失败（没有 code 字段）

**可能原因：**
1. API 返回的不是 JSON 格式（可能是 HTML 错误页面）
2. 网络被拦截或重定向

**查看原始响应：**
```
🔍 解析失败的原始数据: <!DOCTYPE html>...
```

如果是 HTML，说明请求被防火墙或代理拦截。

---

## 🛠 临时解决方案：切换到 Open-Meteo

如果和风天气持续失败，系统会**自动切换到 Open-Meteo**（完全免费，无需 API Key）。

**手动强制使用 Open-Meteo：**

修改 `WeatherRouter.swift:51-60`：

```swift
private func selectDataSource(...) -> WeatherDataSource {
    // 临时强制使用 Open-Meteo
    XLogger.shared.log("🔧 强制使用 Open-Meteo")
    return .openMeteo

    // 原逻辑（注释掉）
    // if LocationHelper.isInMainlandChina(...) {
    //     return .qWeather
    // } else {
    //     return .openMeteo
    // }
}
```

---

## 📞 获取帮助

### 方案 1：使用 Open-Meteo（推荐）

**优势：**
- ✅ 完全免费，无需 API Key
- ✅ 无需注册和配置
- ✅ 全球数据覆盖

**劣势：**
- ⚠️ 中国地区数据精度可能略低于和风

**操作：** 按上述方法强制使用 Open-Meteo

### 方案 2：重新获取和风天气 API Key

1. 访问 https://dev.qweather.com/
2. 重新注册或登录
3. 创建新项目，选择「免费订阅」
4. 获取新的 API Key
5. 更新到 `WeatherAPIConfig.swift`

### 方案 3：联系和风天气支持

- 邮箱：support@qweather.com
- 文档：https://dev.qweather.com/docs/

---

## 🧪 测试验证

### 测试 1：验证 API Key 是否有效

**手动测试和风天气 API：**

在浏览器或 Postman 中访问：

```
https://devapi.qweather.com/v7/weather/now?location=116.41,39.92&key=你的API_Key
```

**预期成功响应：**
```json
{
  "code": "200",
  "now": {
    "temp": "23",
    "text": "晴"
  }
}
```

**如果返回 401：**
```json
{
  "code": "401"
}
```

说明 API Key 无效。

### 测试 2：验证 Open-Meteo 是否可用

在浏览器访问：

```
https://api.open-meteo.com/v1/forecast?latitude=39.92&longitude=116.41&daily=temperature_2m_max,temperature_2m_min,weathercode&forecast_days=7
```

应该能看到 JSON 数据返回。

---

## ✅ 验证修复

重新运行 App 后，预期日志：

### 成功情况（和风天气）：

```
📍 获取到位置: lat=22.59, lon=113.92
📍 位置在中国大陆，使用和风天气
🌐 QWeather 请求 URL: https://devapi.qweather.com/v7/weather/7d?...
🌤 使用 QWeather 获取天气数据
🔍 QWeather 原始响应: {"code":"200","daily":[...]}
✅ QWeather API 返回 7 天天气数据
✅ QWeather 天气数据获取成功
```

### 成功情况（自动切换到 Open-Meteo）：

```
📍 获取到位置: lat=22.59, lon=113.92
📍 位置在中国大陆，使用和风天气
🌤 使用 QWeather 获取天气数据
❌ QWeather API error: code=401
🔄 尝试使用备用数据源: Open-Meteo
✅ 备用数据源 Open-Meteo 成功
```

---

## 📊 最佳实践建议

### 1. 推荐配置（生产环境）

- ✅ **中国用户为主**：配置和风天气 API Key
- ✅ **海外用户为主**：使用 Open-Meteo（无需配置）
- ✅ **全球用户**：配置和风 + Open-Meteo 双源

### 2. API Key 安全

当前 API Key 硬编码在代码中，**不推荐**用于生产环境。

**推荐方案：**

```swift
// 方案 1：从环境变量读取
static let qWeatherAPIKey = ProcessInfo.processInfo.environment["QWEATHER_API_KEY"] ?? ""

// 方案 2：从 Keychain 读取
static let qWeatherAPIKey = KeychainHelper.retrieveAPIKey(forService: "QWeather")

// 方案 3：从服务器动态获取
static func fetchAPIKey(completion: @escaping (String?) -> Void) {
    // 从你的服务器获取
}
```

---

## 🎉 问题解决后

删除或注释掉调试日志（可选）：

在 `QWeatherProvider.swift` 中移除：
- 🔍 QWeather 原始响应
- 🔍 解析失败的原始数据

保留有价值的日志：
- 📍 位置信息
- ✅/❌ 成功/失败状态
