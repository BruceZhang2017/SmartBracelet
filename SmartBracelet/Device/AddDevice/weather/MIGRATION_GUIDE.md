# 天气 API 迁移指南

## 🎯 迁移目标

将付费的 **OpenWeatherMap API** 替换为免费的 **Open-Meteo + 和风天气** 双源方案。

---

## ✅ 已完成的工作

### 1. 新增文件（共6个）

```
SmartBracelet/Device/AddDevice/weather/
├── WeatherProvider.swift          ✅ 统一天气数据协议
├── OpenMeteoProvider.swift        ✅ Open-Meteo 适配器（无需 API Key）
├── QWeatherProvider.swift         ✅ 和风天气适配器（需要 API Key）
├── WeatherRouter.swift            ✅ 智能路由管理器
├── WeatherAPIConfig.swift         ✅ API 配置中心
├── README_Weather_API.md          ✅ 使用说明文档
└── MIGRATION_GUIDE.md             ✅ 本迁移指南
```

### 2. 修改文件（共1个）

```
SmartBracelet/Device/AddDevice/weather/
└── OpenWeatherManager.swift       ✅ 已更新为使用新的天气路由器
```

### 3. 保留文件（暂不删除，保持兼容）

```
SmartBracelet/Device/AddDevice/weather/
├── Constant.swift                 ⚠️ 包含旧的 OpenWeatherMap API Key
├── NetworkManager.swift           ⚠️ 旧的网络管理器（已不再使用）
├── ViewModel.swift                ⚠️ 旧的视图模型（已不再使用）
├── CurrentWeatherData.swift       ✅ 保留（新系统仍在使用此数据模型）
└── OpenWeatherViewController.swift ✅ 保留（无需修改）
```

---

## 🚀 下一步操作

### ⭐ 必须操作（2 步）

#### 1️⃣ 配置和风天气 API Key（推荐）

虽然不配置也能用（会使用 Open-Meteo），但为了国内用户体验更好，建议配置：

**步骤：**

1. 访问 https://dev.qweather.com/
2. 注册账号 → 创建项目 → 选择「免费订阅」
3. 复制 API Key（32位字符串）
4. 打开 `WeatherAPIConfig.swift`，填写：

```swift
static let qWeatherAPIKey = "你的32位API_Key"  // ⚠️ 替换这里
```

#### 2️⃣ 运行测试

```bash
# 在 Xcode 中运行项目，观察控制台日志
```

**预期日志：**

```
📍 获取到位置: lat=39.9042, lon=116.4074
📍 位置在中国大陆，使用和风天气
🌤 使用 QWeather 获取天气数据
✅ QWeather 天气数据获取成功
```

或（如果未配置和风天气）：

```
📍 获取到位置: lat=39.9042, lon=116.4074
🌍 位置在海外，使用 Open-Meteo
🌤 使用 Open-Meteo 获取天气数据
✅ Open-Meteo 天气数据获取成功
```

---

### 🧹 可选操作（清理旧代码）

**⚠️ 建议在测试稳定后再执行以下操作**

#### 删除旧的 OpenWeatherMap 相关代码

```bash
# 可以删除的文件（测试稳定后）
rm SmartBracelet/Device/AddDevice/weather/Constant.swift
rm SmartBracelet/Device/AddDevice/weather/NetworkManager.swift
rm SmartBracelet/Device/AddDevice/weather/ViewModel.swift
```

**注意：**
- `CurrentWeatherData.swift` **不要删除**（新系统仍在使用）
- `OpenWeatherViewController.swift` **不要删除**

---

## 🔍 验证清单

在正式发布前，请逐项验证：

- [ ] **国内用户**：获取北京/上海等地天气正常（使用和风天气）
- [ ] **海外用户**：获取纽约/伦敦等地天气正常（使用 Open-Meteo）
- [ ] **网络异常**：关闭 WiFi 后能正常显示错误提示
- [ ] **权限拒绝**：拒绝定位权限后有合理提示
- [ ] **温度单位**：摄氏度/华氏度切换正常
- [ ] **手表同步**：天气数据能正常同步到手表设备

---

## 🐛 常见问题

### Q1: 和风天气一直失败？

**原因：** 可能是 API Key 未配置或配置错误

**解决：**
1. 检查 `WeatherAPIConfig.swift` 中的 `qWeatherAPIKey` 是否正确
2. 确认 API Key 是「免费订阅」版本（不是商业版）
3. 查看控制台日志，确认错误信息

### Q2: 所有数据源都失败？

**原因：** 网络问题或防火墙限制

**解决：**
1. 检查网络连接
2. 尝试使用 VPN（部分地区可能限制）
3. 查看控制台详细错误信息

### Q3: 温度数据不准确？

**原因：** 不同 API 数据源精度不同

**解决：**
1. 国内用户：确保配置了和风天气（数据更准确）
2. 海外用户：Open-Meteo 数据可能有 1-2°C 偏差，属正常

### Q4: 想要强制使用某个数据源？

**解决：** 修改 `WeatherRouter.swift` 的 `selectDataSource` 方法：

```swift
private func selectDataSource(...) -> WeatherDataSource {
    return .openMeteo  // 强制使用 Open-Meteo
    // 或
    return .qWeather   // 强制使用和风天气
}
```

---

## 📊 对比总结

| 对比项           | OpenWeatherMap (旧) | Open-Meteo + 和风 (新) |
|------------------|---------------------|------------------------|
| **费用**         | 付费/限制免费额度    | 完全免费               |
| **API Key**      | 必需                | Open-Meteo 不需要      |
| **调用限制**     | 1000次/天           | 无限制                 |
| **国内数据精度** | 中等                | 高（和风天气）         |
| **海外数据精度** | 高                  | 高（Open-Meteo）       |
| **备用策略**     | 无                  | 自动切换               |
| **风险**         | 超额收费            | 无                     |

---

## 🎉 迁移完成！

**核心优势：**
✅ **零成本**：完全免费，无需担心账单
✅ **高可用**：双源自动切换，数据获取成功率更高
✅ **更精准**：国内用户使用和风天气，数据更准确
✅ **易维护**：统一适配层，方便后续扩展

**如有问题，请查看 `README_Weather_API.md` 获取详细文档。**
