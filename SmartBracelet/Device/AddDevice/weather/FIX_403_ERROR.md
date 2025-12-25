# ⚠️ 和风天气 403 Invalid Host 错误解决方案

## 🔍 问题描述

当你运行应用时，看到以下错误：

```
❌ QWeather API 返回错误 (新格式):
   状态码: 403
   标题: Invalid Host
   详情: An invalid or unauthorized API Host.

⚠️  403 Invalid Host 错误说明:
   这个错误表示你的 API Key 绑定了特定的应用
   当前应用的 BundleID 不在授权列表中
```

## 💡 根本原因

和风天气的 API Key 被配置为**仅允许特定的应用使用**，而你的 iOS 应用的 BundleID 不在授权列表中。

这是和风天气的**安全机制**，防止 API Key 被盗用。

---

## ✅ 解决方案（3 种方案任选其一）

### 方案 1：添加 BundleID 到白名单（推荐用于生产环境）

#### 步骤：

1. **获取当前应用的 BundleID**
   - 重新运行应用，在日志中查找：
     ```
     📱 当前应用信息:
        BundleID: com.yourcompany.yourapp
     ```
   - 或在 Xcode 中查看：
     - 打开 Xcode
     - 选择项目 → Target → General
     - 查看 "Bundle Identifier"

2. **登录和风天气开发平台**
   - 访问：https://dev.qweather.com/
   - 使用你的账号登录

3. **找到你的应用**
   - 进入「控制台」→「应用管理」
   - 找到 API Key 为 `3f53759a415245dbabc8e6f96a7b18bb` 的应用

4. **配置 BundleID 白名单**
   - 点击应用名称进入详情
   - 找到「应用设置」或「Package Name/BundleID」配置
   - 在 **iOS BundleID** 字段中添加你的应用 BundleID
     ```
     com.yourcompany.yourapp
     ```
   - 点击「保存」

5. **等待生效**
   - 配置通常会在 **1-5 分钟**后生效
   - 重新运行应用测试

#### ✅ 优点：
- 安全性高，防止 API Key 被盗用
- 适合生产环境

#### ❌ 缺点：
- 需要手动配置
- 每个新的应用都需要添加

---

### 方案 2：取消 BundleID 绑定（推荐用于开发测试）

#### 步骤：

1. **登录和风天气开发平台**
   - 访问：https://dev.qweather.com/

2. **找到你的应用**
   - 进入「控制台」→「应用管理」
   - 找到 API Key 为 `3f53759a415245dbabc8e6f96a7b18bb` 的应用

3. **清空 BundleID 配置**
   - 点击应用名称进入详情
   - 找到「应用设置」或「Package Name/BundleID」配置
   - **删除或清空** iOS BundleID 字段
   - 点击「保存」

4. **等待生效**
   - 配置通常会在 **1-5 分钟**后生效
   - 重新运行应用测试

#### ✅ 优点：
- 简单快捷
- 适合开发和测试阶段
- 任何 BundleID 都可以使用

#### ❌ 缺点：
- 安全性较低，API Key 可能被盗用
- 不推荐用于生产环境

---

### 方案 3：创建新的 API Key（无 BundleID 绑定）

如果你不想修改现有配置，可以创建一个新的 API Key：

#### 步骤：

1. **登录和风天气开发平台**
   - 访问：https://dev.qweather.com/

2. **创建新应用**
   - 进入「控制台」→「应用管理」
   - 点击「创建应用」

3. **填写应用信息**
   - 应用名称：填写一个描述性名称（如 "SmartBracelet-Dev"）
   - 选择「免费订阅」
   - **不填写** Package Name 和 BundleID 字段（留空）
   - 提交创建

4. **获取新的 API Key**
   - 创建成功后，复制新的 API Key（32位字符串）

5. **更新代码**
   - 打开文件：`SmartBracelet/Device/AddDevice/weather/WeatherAPIConfig.swift`
   - 修改第 21 行：
     ```swift
     static let qWeatherAPIKey = "你的新API_Key"
     ```

6. **重新运行应用**

#### ✅ 优点：
- 不影响现有配置
- 可以随时切换回旧的 API Key

#### ❌ 缺点：
- 需要修改代码
- 如果旧 Key 有其他地方在用，需要注意区分

---

## 🔄 临时解决方案：使用 Open-Meteo（无需配置）

如果你暂时无法修复和风天气的配置，系统会**自动切换到 Open-Meteo**：

### 自动切换流程

```
和风天气 (失败) → 自动切换 → Open-Meteo (成功)
```

你会看到日志：

```
❌ QWeather 天气数据获取失败: Failed to parse weather data
🔄 尝试使用备用数据源: Open-Meteo
✅ 备用数据源 Open-Meteo 成功
```

### Open-Meteo 特点

- ✅ **完全免费**：无需 API Key，无调用限制
- ✅ **全球覆盖**：支持全球所有地区
- ✅ **数据质量**：WMO 标准气象数据
- ⚠️ **精度略低**：中国地区数据可能不如和风天气精准

### 强制使用 Open-Meteo（可选）

如果你想暂时跳过和风天气，可以强制使用 Open-Meteo：

**修改文件：** `SmartBracelet/Device/AddDevice/weather/WeatherRouter.swift`

找到第 51-60 行的 `selectDataSource` 方法：

```swift
private func selectDataSource(latitude: CLLocationDegrees, longitude: CLLocationDegrees) -> WeatherDataSource {
    // 临时强制使用 Open-Meteo
    XLogger.shared.log("🔧 强制使用 Open-Meteo（跳过和风天气）")
    return .openMeteo

    /* 原逻辑（注释掉）
    if LocationHelper.isInMainlandChina(latitude: latitude, longitude: longitude) {
        XLogger.shared.log("📍 位置在中国大陆，使用和风天气")
        return .qWeather
    } else {
        XLogger.shared.log("🌍 位置在海外，使用 Open-Meteo")
        return .openMeteo
    }
    */
}
```

---

## 🧪 验证修复

### 测试步骤

1. **重新运行应用**
   - 在 Xcode 中运行项目
   - 查看控制台日志

2. **预期成功日志（和风天气）：**

```
📍 获取到位置: lat=22.59, lon=113.92
📍 位置在中国大陆，使用和风天气
🌐 QWeather 请求 URL: https://devapi.qweather.com/v7/weather/7d?...
🌤 使用 QWeather 获取天气数据
🔍 QWeather 原始响应: {"code":"200","daily":[...]}
✅ QWeather API 返回 7 天天气数据
✅ QWeather 天气数据获取成功
```

3. **预期成功日志（Open-Meteo 备用）：**

```
📍 获取到位置: lat=22.59, lon=113.92
📍 位置在中国大陆，使用和风天气
🌤 使用 QWeather 获取天气数据
❌ QWeather API 返回错误 (新格式):
   状态码: 403
   ...
🔄 尝试使用备用数据源: Open-Meteo
✅ 备用数据源 Open-Meteo 成功
```

---

## 📞 需要帮助？

### 和风天气官方支持

- **文档中心**：https://dev.qweather.com/docs/
- **常见问题**：https://dev.qweather.com/docs/faq/
- **错误代码说明**：https://dev.qweather.com/docs/resource/error-code/
- **技术支持**：support@qweather.com

### 常见问题

**Q1: 配置后还是 403 错误？**

A: 等待 1-5 分钟让配置生效，然后重启应用。

**Q2: 找不到 BundleID 配置在哪里？**

A: 在和风天气控制台：
1. 应用管理 → 点击应用名称
2. 找到「应用设置」标签页
3. 查找「Package Name」或「BundleID」字段

**Q3: 可以同时绑定多个 BundleID 吗？**

A: 可以。在 BundleID 字段中，用**逗号**分隔多个 BundleID：
```
com.yourcompany.app1,com.yourcompany.app2
```

**Q4: Open-Meteo 和和风天气数据差异大吗？**

A: 对于基础天气数据（温度、天气状况），差异很小。和风天气在中国地区的优势：
- 更精确的位置定位
- 支持空气质量 (AQI)
- 支持生活指数（穿衣、洗车等）

---

## 🎯 推荐方案

### 📱 开发测试阶段

**推荐：方案 2（取消 BundleID 绑定）**

优势：
- 快速简单
- 无需每次修改代码
- 方便测试

### 🚀 生产环境

**推荐：方案 1（添加 BundleID 到白名单）**

优势：
- 安全性高
- 符合最佳实践
- 防止 API Key 被盗用

### 🌍 全球应用

**推荐：直接使用 Open-Meteo**

如果你的应用用户主要在海外，或者不想配置 API Key：
- 修改 `WeatherRouter.swift` 强制使用 Open-Meteo
- 完全免费，无需任何配置
- 全球数据覆盖

---

## ✅ 问题解决！

按照上述任一方案操作后，你的应用应该能正常获取天气数据了！

**记住：** 即使和风天气失败，系统也会自动切换到 Open-Meteo，确保天气功能始终可用！🌤️
