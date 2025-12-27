# XGZTDeviceManager 使用指南

> **优化日期**: 2025-12-27
> **优化内容**: 将全局变量 `cacheDevices` 和 `connectFailMessage` 封装为线程安全的单例类

---

## 📋 优化概述

### 原有问题

```swift
// ❌ 旧代码：全局可变变量，非线程安全
public var cacheDevices = [BluetoothWatchDevice]()
public var connectFailMessage = ""

// 问题1: 任何地方都可以直接修改
cacheDevices.append(device)
cacheDevices.removeAll()

// 问题2: 多线程访问不安全
DispatchQueue.global().async {
    cacheDevices.append(device)  // ⚠️ 可能崩溃
}

// 问题3: connectFailMessage 无限增长
connectFailMessage += "新错误"  // ⚠️ 内存泄漏
```

### 优化方案

```swift
// ✅ 新代码：线程安全的单例管理器
class XGZTDeviceManager {
    static let shared = XGZTDeviceManager()

    // 线程安全的设备缓存
    private let deviceCacheLock = NSLock()
    private var _cacheDevices: [BluetoothWatchDevice] = []

    // 线程安全的失败信息（自动限制50条）
    private let failMessageLock = NSLock()
    private var _failMessages: [String] = []
    private let maxFailMessageCount = 50
}
```

---

## 🚀 快速迁移指南

### 1. 设备缓存相关

#### 读取设备列表

```swift
// ❌ 旧代码
let devices = cacheDevices
let count = cacheDevices.count
let lastDevice = cacheDevices.last

// ✅ 新代码（推荐）
let devices = XGZTDeviceManager.shared.cacheDevices
let count = XGZTDeviceManager.shared.deviceCount
let lastDevice = XGZTDeviceManager.shared.lastDevice()

// ✅ 向后兼容（不推荐，已标记为 deprecated）
let devices = cacheDevices  // 仍然可用，但会有警告
```

#### 查找设备

```swift
// ❌ 旧代码（需要手动遍历）
var foundDevice: BluetoothWatchDevice?
for device in cacheDevices {
    if device.max == targetMac {
        foundDevice = device
        break
    }
}

// ✅ 新代码（更简洁）
let foundDevice = XGZTDeviceManager.shared.findDevice(mac: targetMac)
```

#### 添加设备

```swift
// ❌ 旧代码（手动去重）
if !cacheDevices.contains(where: { $0.max == newDevice.max }) {
    cacheDevices.append(newDevice)
}

// ✅ 新代码（自动去重）
XGZTDeviceManager.shared.addDevice(newDevice)
```

#### 移除设备

```swift
// ❌ 旧代码
cacheDevices.removeAll { $0.max == targetMac }

// ✅ 新代码
XGZTDeviceManager.shared.removeDevice(mac: targetMac)
```

#### 清空缓存

```swift
// ❌ 旧代码
cacheDevices.removeAll()
cacheDevices = []

// ✅ 新代码
XGZTDeviceManager.shared.clearDeviceCache()
```

#### 重新加载

```swift
// ❌ 旧代码
BluetoothWatchDevice.loadAll()

// ✅ 新代码（两种方式都可以）
XGZTDeviceManager.shared.reloadDevices()
BluetoothWatchDevice.loadAll()  // 内部调用上面的方法
```

### 2. 连接失败信息相关

#### 追加失败信息

```swift
// ❌ 旧代码（无限增长）
connectFailMessage += "[\(mac)]连接失败: \(error)"

// ✅ 新代码（自动限制50条，带时间戳）
XGZTDeviceManager.shared.appendFailMessage("[\(mac)]连接失败: \(error)")
```

#### 读取失败信息

```swift
// ❌ 旧代码
let failInfo = connectFailMessage

// ✅ 新代码（推荐）
let failInfo = XGZTDeviceManager.shared.connectFailMessage

// ✅ 获取数组格式
let messages = XGZTDeviceManager.shared.recentFailMessages

// ✅ 获取最近 N 条
let last10 = XGZTDeviceManager.shared.getRecentFailMessages(count: 10)

// ✅ 向后兼容
let failInfo = connectFailMessage  // 仍然可用，但不推荐
```

#### 清空失败信息

```swift
// ❌ 旧代码
connectFailMessage = ""

// ✅ 新代码（推荐）
XGZTDeviceManager.shared.clearFailMessages()

// ✅ 向后兼容
connectFailMessage = ""  // 仍然可用
```

---

## 📝 代码迁移示例

### 示例1: HealthViewController.swift

```swift
// ❌ 旧代码
override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    var count = DeviceManager.shared.devices.count
    count += cacheDevices.count  // 全局变量

    if cacheDevices.count >= 1 && !XGZTBlueToothManager.shared.isconnected() {
        for device in cacheDevices {
            // 处理设备
        }
    }
}

// ✅ 新代码（推荐）
override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    var count = DeviceManager.shared.devices.count
    count += XGZTDeviceManager.shared.deviceCount  // 线程安全

    if XGZTDeviceManager.shared.deviceCount >= 1 && !XGZTBlueToothManager.shared.isconnected() {
        for device in XGZTDeviceManager.shared.cacheDevices {
            // 处理设备
        }
    }
}
```

### 示例2: DevicesViewController.swift

```swift
// ❌ 旧代码
func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    var count = DeviceManager.shared.devices.count
    count += cacheDevices.count
    return count
}

func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let count = DeviceManager.shared.devices.count
    if indexPath.row >= count {
        let model = cacheDevices[indexPath.row - count]
        // 配置cell
    }
}

// ✅ 新代码（推荐）
func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    var count = DeviceManager.shared.devices.count
    count += XGZTDeviceManager.shared.deviceCount
    return count
}

func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let count = DeviceManager.shared.devices.count
    if indexPath.row >= count {
        let devices = XGZTDeviceManager.shared.cacheDevices
        let model = devices[indexPath.row - count]
        // 配置cell
    }
}
```

### 示例3: HelpCenterViewController.swift

```swift
// ❌ 旧代码
@IBAction func submitFeedback(_ sender: UIButton) {
    let parameters = [
        "title": "iOS-\(localVersion)",
        "content": "\(content)---\(connectFailMessage)",  // 全局变量
        "byCountry": getLocaleCountryCode()
    ]

    // 提交后清空
    connectFailMessage = ""
}

// ✅ 新代码（推荐）
@IBAction func submitFeedback(_ sender: UIButton) {
    let failInfo = XGZTDeviceManager.shared.connectFailMessage

    let parameters = [
        "title": "iOS-\(localVersion)",
        "content": "\(content)---\(failInfo)",
        "byCountry": getLocaleCountryCode()
    ]

    // 提交后清空
    XGZTDeviceManager.shared.clearFailMessages()
}
```

### 示例4: XGZTBlueToothManager.swift

```swift
// ❌ 旧代码
func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
    XLogger.shared.log("连接蓝牙设备失败: \(error?.localizedDescription ?? "未知错误")")
    connectFailMessage.append("[\(device?.max ?? "")]连接失败: \(error?.localizedDescription ?? "未知错误")")
    self.peripheral = nil
    handler.handleDisconnected()
    device = nil
}

// ✅ 新代码（推荐）
func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
    let errorMsg = "[\(device?.max ?? "")]连接失败: \(error?.localizedDescription ?? "未知错误")"
    XLogger.shared.log("连接蓝牙设备失败: \(error?.localizedDescription ?? "未知错误")")
    XGZTDeviceManager.shared.appendFailMessage(errorMsg)
    self.peripheral = nil
    handler.handleDisconnected()
    device = nil
}
```

---

## 🎯 优势对比

| 特性 | 旧方案（全局变量） | 新方案（XGZTDeviceManager） |
|------|-------------------|---------------------------|
| **线程安全** | ❌ 不安全 | ✅ NSLock 保护 |
| **内存管理** | ❌ 无限增长 | ✅ 自动限制50条 |
| **日志记录** | ❌ 无 | ✅ 带时间戳日志 |
| **API设计** | ❌ 直接操作数组 | ✅ 封装方法，易用 |
| **去重逻辑** | ❌ 手动去重 | ✅ 自动去重 |
| **向后兼容** | N/A | ✅ 完全兼容 |
| **类型安全** | ❌ 任意修改 | ✅ 受控访问 |

---

## ⚠️ 注意事项

### 1. 避免死锁问题（重要）

**问题描述：**
- `XGZTDeviceManager` 的 `init()` 方法中**不能**调用 `BluetoothWatchDevice.loadAll()`
- 因为 `loadAll()` 内部会调用 `XGZTDeviceManager.shared.reloadDevices()`
- 这会形成循环依赖导致死锁

**正确的初始化顺序：**

```swift
// ❌ 错误：在 XGZTDeviceManager.init() 中调用
private init() {
    BluetoothWatchDevice.loadAll()  // ⚠️ 死锁！
}

// ✅ 正确：在应用启动时调用
class MTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // 在这里调用，此时所有单例都已初始化
        BluetoothWatchDevice.loadAll()
    }
}
```

### 2. 向后兼容性

新的管理器提供了完全的向后兼容：

```swift
// ✅ 旧代码仍然可以运行（但有 deprecated 警告）
let devices = cacheDevices
connectFailMessage += "错误信息"

// 建议逐步迁移到新 API
let devices = XGZTDeviceManager.shared.cacheDevices
XGZTDeviceManager.shared.appendFailMessage("错误信息")
```

### 2. 性能影响

- **读取性能**: 轻微开销（NSLock加锁/解锁）
- **写入性能**: 同上
- **内存优化**: 失败信息自动限制在50条，避免泄漏

### 3. 多线程安全

```swift
// ✅ 现在可以安全地在多线程中操作
DispatchQueue.global().async {
    XGZTDeviceManager.shared.addDevice(device1)
}

DispatchQueue.global().async {
    XGZTDeviceManager.shared.addDevice(device2)
}

// 不会崩溃，自动去重
```

### 4. 日志输出

新的管理器会自动记录操作日志：

```
✅ 添加设备到缓存: E Watch Pro [A1:B2:C3:D4:E5:F6]
📦 缓存设备: A1:B2:C3:D4:E5:F6 - E Watch Pro
✅ 重新加载设备完成，共 3 个设备
🗑️ 移除设备缓存: [A1:B2:C3:D4:E5:F6]
🧹 清空所有设备缓存
❌ 连接失败: [A1:B2:C3:D4:E5:F6]连接超时
🧹 清空连接失败信息
```

---

## 🔧 Xcode 集成步骤

### 1. 将文件添加到项目

1. 打开 Xcode 项目
2. 右键点击 `SmartBracelet/huaxin/WatchProtocol` 文件夹
3. 选择 `Add Files to "SmartBracelet"...`
4. 选择 `XGZTDeviceManager.swift`
5. 确保 `Copy items if needed` 未勾选（文件已在正确位置）
6. 点击 `Add`

### 2. 验证编译

```bash
# 清理并重新编译
xcodebuild -scheme SmartBracelet clean build
```

### 3. 运行测试

- 启动应用
- 测试设备扫描和连接
- 检查设备列表显示
- 验证连接失败信息收集

---

## 📚 API 参考

### XGZTDeviceManager

#### 单例

```swift
static let shared: XGZTDeviceManager
```

#### 设备缓存属性

```swift
var cacheDevices: [BluetoothWatchDevice] { get }  // 只读，线程安全
var deviceCount: Int { get }                       // 设备数量
```

#### 设备管理方法

```swift
func addDevice(_ device: BluetoothWatchDevice)     // 添加设备（自动去重）
func removeDevice(mac: String)                     // 移除设备
func findDevice(mac: String) -> BluetoothWatchDevice?  // 查找设备
func lastDevice() -> BluetoothWatchDevice?         // 获取最后一个设备
func clearDeviceCache()                            // 清空缓存
func reloadDevices()                               // 重新加载
```

#### 失败信息属性

```swift
var connectFailMessage: String { get }             // 所有失败信息（换行连接）
var recentFailMessages: [String] { get }           // 失败信息数组
```

#### 失败信息方法

```swift
func appendFailMessage(_ message: String)          // 追加失败信息（带时间戳）
func clearFailMessages()                           // 清空失败信息
func getRecentFailMessages(count: Int) -> [String] // 获取最近N条
```

---

## 🎓 最佳实践

### 1. 优先使用新 API

```swift
// ✅ 推荐
XGZTDeviceManager.shared.addDevice(device)

// ⚠️ 不推荐（虽然可用）
cacheDevices.append(device)
```

### 2. 批量操作时缓存结果

```swift
// ✅ 好的做法：缓存一次
let devices = XGZTDeviceManager.shared.cacheDevices
for device in devices {
    // 处理设备
}

// ❌ 不好的做法：多次访问
for i in 0..<XGZTDeviceManager.shared.deviceCount {
    let device = XGZTDeviceManager.shared.cacheDevices[i]
    // 每次都要加锁
}
```

### 3. 错误信息分类记录

```swift
// ✅ 推荐：带上下文信息
XGZTDeviceManager.shared.appendFailMessage("[\(mac)]连接失败: \(error.localizedDescription)")
XGZTDeviceManager.shared.appendFailMessage("[\(mac)]指令故障: 嵌入式未回复指令81")

// ❌ 不推荐：信息不完整
XGZTDeviceManager.shared.appendFailMessage("连接失败")
```

### 4. 及时清理失败信息

```swift
// ✅ 推荐：提交反馈后清空
func submitFeedback() {
    let failInfo = XGZTDeviceManager.shared.connectFailMessage
    uploadToServer(failInfo)
    XGZTDeviceManager.shared.clearFailMessages()  // 清空
}
```

---

## 📞 支持与反馈

如有问题或建议，请联系开发团队。

**优化完成时间**: 2025-12-27
**文档版本**: 1.0
