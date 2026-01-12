# WatchProtocolSDK 接入文档

## 版本信息
- **SDK 版本**: v1.0.2
- **发布日期**: 2026-01-10
- **支持平台**: iOS 13.0+
- **开发语言**: Swift 5.0+

---

## 目录
1. [SDK 简介](#sdk-简介)
2. [系统要求](#系统要求)
3. [SDK 集成](#sdk-集成)
4. [快速开始](#快速开始)
5. [核心功能](#核心功能)
6. [API 参考](#api-参考)
7. [数据模型](#数据模型)
8. [示例代码](#示例代码)
9. [常见问题](#常见问题)
10. [更新日志](#更新日志)

---

## SDK 简介

WatchProtocolSDK 是一款专为智能手表设备开发的 iOS 蓝牙通信协议 SDK。它提供了完整的设备连接管理、健康数据同步、协议指令处理等功能，帮助开发者快速集成智能手表设备功能到 iOS 应用中。

### 主要特性

- ✅ **蓝牙设备管理**: 支持设备扫描、连接、断开、重连等完整生命周期管理
- ✅ **健康数据同步**: 支持步数、睡眠、心率、血氧、血压等多种健康数据同步
- ✅ **协议化存储**: 基于协议的数据存储设计，灵活适配不同存储方案
- ✅ **设备指令**: 支持时间同步、语言设置、闹钟管理、运动模式等丰富指令
- ✅ **线程安全**: 核心管理类采用线程安全设计
- ✅ **日志系统**: 内置完善的日志记录系统，便于问题排查
- ✅ **模块化架构**: 清晰的模块划分，易于维护和扩展

---

## 系统要求

| 项目 | 要求 |
|------|------|
| iOS 版本 | iOS 13.0 及以上 |
| Xcode 版本 | Xcode 12.0 及以上 |
| Swift 版本 | Swift 5.0 及以上 |
| 设备蓝牙 | 支持 Bluetooth 4.0 (BLE) |

### 依赖框架

- `CoreBluetooth.framework` (系统框架)
- `Foundation.framework` (系统框架)
- `SwiftyJSON` (第三方库，需通过 CocoaPods 引入)
- `CryptoSwift` (第三方库，需通过 CocoaPods 引入)

---

## SDK 集成

### 方式一：使用 XCFramework（推荐）

1. 将 `WatchProtocolSDK.xcframework` 拖入项目
2. 在项目 Target -> General -> Frameworks, Libraries, and Embedded Content 中添加 xcframework
3. 设置 Embed 为 "Embed & Sign"

### 方式二：使用 CocoaPods

在 `Podfile` 中添加：

```ruby
# WatchProtocolSDK 依赖
pod 'SwiftyJSON'
pod 'CryptoSwift'

# 本地 podspec（如果已发布到远程仓库，可直接使用远程地址）
pod 'WatchProtocolSDK', :path => './WatchProtocolSDK.podspec'
```

然后执行：
```bash
pod install
```

### 配置项目

1. **添加蓝牙权限**
   在 `Info.plist` 中添加以下权限描述：

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>需要使用蓝牙连接智能手表设备</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>需要使用蓝牙与智能手表进行数据交互</string>
```

2. **导入框架**

```swift
import WatchProtocolSDK
```

---

## 快速开始

### 1. 初始化蓝牙管理器

```swift
import WatchProtocolSDK

class YourViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // 初始化蓝牙中心管理器
        XGZTBlueToothManager.shared.initCentral()

        // 设置代理
        XGZTBlueToothManager.shared.delegate = self
    }
}

// 实现蓝牙管理器代理
extension YourViewController: BleManagerDelegate {

    // 蓝牙准备就绪
    func onBleReady() {
        print("蓝牙已准备就绪，可以开始扫描设备")
    }

    // 接收到设备数据
    func receiveData(_ data: Data) {
        print("收到数据：\(data.hexString)")
    }

    // 数据发送完成
    func sentData() {
        print("数据发送成功")
    }
}
```

### 2. 扫描并连接设备

```swift
// 开始扫描设备
func startScan() {
    XGZTBlueToothManager.shared.scanDevice { peripheral, macAddress in
        print("发现设备：\(peripheral.name ?? "未知") - MAC: \(macAddress)")

        // 将设备添加到列表
        // ... 更新UI显示设备列表
    }
}

// 连接指定设备
func connectDevice(macAddress: String) {
    XGZTBlueToothManager.shared.connectDevice(macAddress) { success in
        if success {
            print("设备连接成功")
            // 连接成功后可以开始同步数据
            self.syncDeviceData()
        } else {
            print("设备连接失败")
        }
    }
}

// 停止扫描
func stopScan() {
    XGZTBlueToothManager.shared.stopScan()
}

// 断开设备
func disconnectDevice() {
    XGZTBlueToothManager.shared.disconnectBle()
}
```

### 3. 同步健康数据

```swift
// 实现数据存储协议
class MyHealthDataStorage: HealthDataStorageProtocol {

    func saveStepData(_ data: StepData) {
        print("保存步数数据：\(data.step) 步，日期：\(data.date)")
        // 实现您的数据存储逻辑（如保存到数据库）
    }

    func saveSleepData(_ data: SleepData) {
        print("保存睡眠数据：深睡 \(data.deep) 分钟，浅睡 \(data.light) 分钟")
        // 实现您的数据存储逻辑
    }

    func saveHeartData(_ data: HeartData) {
        print("保存心率数据：\(data.heart) bpm")
        // 实现您的数据存储逻辑
    }

    func saveOxygenData(_ data: OxygenData) {
        print("保存血氧数据：\(data.oxygen)%")
        // 实现您的数据存储逻辑
    }

    func saveBloodPressureData(_ data: BloodPressureData) {
        print("保存血压数据：\(data.max)/\(data.min) mmHg")
        // 实现您的数据存储逻辑
    }
}

// 设置数据存储实现
func setupDataStorage() {
    let storage = MyHealthDataStorage()
    XGZTBlueToothManager.shared.handler.dataStorage = storage
}

// 同步设备数据
func syncDeviceData() {
    // 获取设备信息
    XGZTCommand.getDeviceInfo()

    // 同步历史数据
    XGZTCommand.syncHistoryData()
}
```

### 4. 发送设备指令

```swift
// 同步时间到设备
func syncTime() {
    XGZTCommand.syncTime()
}

// 设置设备语言
func setDeviceLanguage() {
    XGZTCommand.getDeviceLanguage()
}

// 查找设备（设备震动或响铃）
func findDevice() {
    XGZTCommand.findDevice()
}

// 设置闹钟
func setAlarm(hour: Int, minute: Int, isEnabled: Bool) {
    // 构建闹钟数据并发送
    // 具体实现参考 XGZTCommand 中的闹钟相关方法
}
```

---

## 核心功能

### 1. 蓝牙设备管理

#### XGZTBlueToothManager（蓝牙管理器）

负责蓝牙设备的扫描、连接、断开、数据收发等核心功能。

**主要方法：**

- `initCentral()`: 初始化蓝牙中心管理器
- `scanDevice(callback:)`: 扫描附近的蓝牙设备
- `connectDevice(_:completion:)`: 连接指定 MAC 地址的设备
- `disconnectBle()`: 断开当前连接的设备
- `stopScan()`: 停止扫描
- `isconnected()`: 检查设备连接状态

#### XGZTDeviceManager（设备管理器）

负责设备缓存管理和连接失败诊断信息管理，采用线程安全设计。

**主要方法：**

- `addDevice(_:)`: 添加设备到缓存
- `removeDevice(mac:)`: 移除指定设备
- `findDevice(mac:)`: 查找指定设备
- `clearDeviceCache()`: 清空设备缓存
- `appendFailMessage(_:)`: 记录连接失败信息

### 2. 健康数据同步

SDK 支持以下健康数据类型：

| 数据类型 | 说明 | 数据模型 |
|---------|------|---------|
| 步数 | 每日步数统计 | `StepData` |
| 睡眠 | 深睡、浅睡、清醒时长 | `SleepData` |
| 心率 | 实时心率数据 | `HeartData` |
| 血氧 | 血氧饱和度 | `OxygenData` |
| 血压 | 收缩压/舒张压 | `BloodPressureData` |

**数据存储协议：**

通过实现 `HealthDataStorageProtocol` 协议，您可以自定义数据的存储方式（如数据库、Core Data、文件等）。

### 3. 设备指令系统

#### XGZTCommand（指令管理器）

提供丰富的设备指令，包括：

- **基础指令**：获取设备信息、同步时间、查找设备
- **健康数据**：同步历史数据、实时测量
- **设备设置**：语言设置、震动强度、屏幕亮度
- **运动功能**：运动模式切换、运动数据同步
- **闹钟管理**：添加、删除、修改闹钟

### 4. 连接状态管理

#### XGZTConnectionStateManager（连接状态管理器）

管理蓝牙连接的各种状态：

- 设备连接状态
- 上次连接的设备信息
- 自动重连标志
- OTA 升级状态

### 5. 指令状态管理

#### XGZTCommandStateManager（指令状态管理器）

管理设备指令的执行状态：

- 数据读取状态
- 时间同步状态
- 数据同步进度

### 6. 日志系统

#### XLogger（日志管理器）

提供完善的日志记录功能，支持不同日志级别：

```swift
XLogger.shared.log("普通日志信息")
XLogger.shared.logError("错误信息")
XLogger.shared.logWarning("警告信息")
```

---

## API 参考

### XGZTBlueToothManager

```swift
/// 蓝牙管理器单例
public static let shared: XGZTBlueToothManager

/// 初始化蓝牙中心管理器
public func initCentral()

/// 扫描设备
/// - Parameter callback: 发现设备回调 (CBPeripheral, MAC地址)
public func scanDevice(callback: @escaping (CBPeripheral, String) -> Void)

/// 连接设备
/// - Parameters:
///   - macAddress: 设备 MAC 地址
///   - completion: 连接结果回调
public func connectDevice(_ macAddress: String,
                          completion: @escaping (Bool) -> Void)

/// 断开连接
public func disconnectBle()

/// 停止扫描
public func stopScan()

/// 检查设备连接状态
/// - Returns: 是否已连接
public func isconnected() -> Bool

/// 检查蓝牙是否关闭
/// - Returns: 蓝牙是否处于关闭状态
public func isCurrentBleStateOFF() -> Bool
```

### XGZTDeviceManager

```swift
/// 设备管理器单例
public static let shared: XGZTDeviceManager

/// 设备缓存列表（只读）
public var cacheDevices: [BluetoothWatchDevice] { get }

/// 设备数量
public var deviceCount: Int { get }

/// 添加设备到缓存
public func addDevice(_ device: BluetoothWatchDevice)

/// 移除设备
public func removeDevice(mac: String)

/// 查找设备
public func findDevice(mac: String) -> BluetoothWatchDevice?

/// 获取最后一个设备
public func lastDevice() -> BluetoothWatchDevice?

/// 清空设备缓存
public func clearDeviceCache()

/// 重新加载设备
public func reloadDevices()

/// 追加连接失败信息
public func appendFailMessage(_ message: String)

/// 获取连接失败信息
public var connectFailMessage: String { get }

/// 清空失败信息
public func clearFailMessages()
```

### XGZTCommand

```swift
/// 获取设备信息
public static func getDeviceInfo()

/// 同步时间
public static func syncTime()

/// 查找设备
public static func findDevice()

/// 获取设备语言
public static func getDeviceLanguage()

/// 同步历史数据
public static func syncHistoryData()

/// 开始实时心率测量
public static func startHeartRateMonitoring()

/// 停止实时心率测量
public static func stopHeartRateMonitoring()
```

### HealthDataStorageProtocol

```swift
/// 健康数据存储协议
public protocol HealthDataStorageProtocol: AnyObject {

    /// 保存步数数据
    func saveStepData(_ data: StepData)

    /// 保存睡眠数据
    func saveSleepData(_ data: SleepData)

    /// 保存心率数据
    func saveHeartData(_ data: HeartData)

    /// 保存血氧数据
    func saveOxygenData(_ data: OxygenData)

    /// 保存血压数据
    func saveBloodPressureData(_ data: BloodPressureData)
}
```

---

## 数据模型

### StepData（步数数据）

```swift
public struct StepData {
    public let date: String      // 日期 (格式: yyyy-MM-dd)
    public let mac: String        // 设备 MAC 地址
    public let step: Int          // 步数
}
```

### SleepData（睡眠数据）

```swift
public struct SleepData {
    public let date: String      // 日期
    public let mac: String        // 设备 MAC 地址
    public let awake: Int         // 清醒时长（分钟）
    public let light: Int         // 浅睡时长（分钟）
    public let deep: Int          // 深睡时长（分钟）
}
```

### HeartData（心率数据）

```swift
public struct HeartData {
    public let mac: String        // 设备 MAC 地址
    public let time: Int          // 时间戳
    public let heart: Int         // 心率值（bpm）
}
```

### OxygenData（血氧数据）

```swift
public struct OxygenData {
    public let mac: String        // 设备 MAC 地址
    public let time: Int          // 时间戳
    public let oxygen: Int        // 血氧值（%）
}
```

### BloodPressureData（血压数据）

```swift
public struct BloodPressureData {
    public let mac: String        // 设备 MAC 地址
    public let time: Int          // 时间戳
    public let max: Int           // 收缩压（mmHg）
    public let min: Int           // 舒张压（mmHg）
}
```

---

## 示例代码

### 完整的设备连接流程

```swift
import UIKit
import WatchProtocolSDK

class DeviceListViewController: UIViewController {

    private var discoveredDevices: [(peripheral: CBPeripheral, mac: String)] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBluetooth()
    }

    // MARK: - 初始化蓝牙

    func setupBluetooth() {
        XGZTBlueToothManager.shared.initCentral()
        XGZTBlueToothManager.shared.delegate = self
    }

    // MARK: - 扫描设备

    @IBAction func startScanButtonTapped(_ sender: UIButton) {
        discoveredDevices.removeAll()

        XGZTBlueToothManager.shared.scanDevice { [weak self] peripheral, macAddress in
            guard let self = self else { return }

            // 检查是否已存在
            if !self.discoveredDevices.contains(where: { $0.mac == macAddress }) {
                self.discoveredDevices.append((peripheral, macAddress))

                DispatchQueue.main.async {
                    // 更新 UI（如刷新 TableView）
                    self.tableView.reloadData()
                }
            }
        }
    }

    // MARK: - 连接设备

    func connectDevice(at index: Int) {
        let device = discoveredDevices[index]

        // 停止扫描
        XGZTBlueToothManager.shared.stopScan()

        // 连接设备
        XGZTBlueToothManager.shared.connectDevice(device.mac) { success in
            DispatchQueue.main.async {
                if success {
                    print("设备连接成功")
                    self.onDeviceConnected(device.mac)
                } else {
                    print("设备连接失败")
                    self.showAlert(message: "设备连接失败，请重试")
                }
            }
        }
    }

    // MARK: - 连接成功后的操作

    func onDeviceConnected(_ macAddress: String) {
        // 保存设备信息
        let device = BluetoothWatchDevice()
        device.max = macAddress
        device.deviceName = "我的智能手表"
        XGZTDeviceManager.shared.addDevice(device)

        // 同步时间
        XGZTCommand.syncTime()

        // 获取设备信息
        XGZTCommand.getDeviceInfo()

        // 跳转到设备详情页
        // navigateToDeviceDetail()
    }

    // MARK: - 辅助方法

    func showAlert(message: String) {
        let alert = UIAlertController(title: "提示",
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - BleManagerDelegate

extension DeviceListViewController: BleManagerDelegate {

    func onBleReady() {
        print("✅ 蓝牙已准备就绪")
        // 可以自动开始扫描
        // startScanButtonTapped(scanButton)
    }

    func receiveData(_ data: Data) {
        print("📥 收到数据：\(data.hexString)")
    }

    func sentData() {
        print("📤 数据发送成功")
    }
}
```

### 健康数据存储示例

```swift
import Foundation
import WatchProtocolSDK
import CoreData // 或其他数据库框架

class HealthDataStorageManager: HealthDataStorageProtocol {

    static let shared = HealthDataStorageManager()

    private init() {}

    // MARK: - HealthDataStorageProtocol

    func saveStepData(_ data: StepData) {
        // 示例：保存到 UserDefaults（生产环境建议使用数据库）
        let key = "step_\(data.date)_\(data.mac)"
        UserDefaults.standard.set(data.step, forKey: key)

        // 或者保存到数据库
        // saveToDatabase(data)

        // 发送通知更新 UI
        NotificationCenter.default.post(
            name: .stepDataUpdated,
            object: data
        )
    }

    func saveSleepData(_ data: SleepData) {
        let sleepInfo: [String: Any] = [
            "date": data.date,
            "mac": data.mac,
            "deep": data.deep,
            "light": data.light,
            "awake": data.awake,
            "total": data.deep + data.light + data.awake
        ]

        let key = "sleep_\(data.date)_\(data.mac)"
        UserDefaults.standard.set(sleepInfo, forKey: key)

        NotificationCenter.default.post(
            name: .sleepDataUpdated,
            object: data
        )
    }

    func saveHeartData(_ data: HeartData) {
        // 心率数据可能频繁更新，建议批量保存
        var heartRateList = getHeartRateList(for: data.mac)
        heartRateList.append(data)

        // 只保留最近 100 条
        if heartRateList.count > 100 {
            heartRateList.removeFirst()
        }

        // 保存到本地
        saveHeartRateList(heartRateList, for: data.mac)

        NotificationCenter.default.post(
            name: .heartRateUpdated,
            object: data
        )
    }

    func saveOxygenData(_ data: OxygenData) {
        let key = "oxygen_\(data.time)_\(data.mac)"
        UserDefaults.standard.set(data.oxygen, forKey: key)

        NotificationCenter.default.post(
            name: .oxygenDataUpdated,
            object: data
        )
    }

    func saveBloodPressureData(_ data: BloodPressureData) {
        let bpInfo: [String: Any] = [
            "time": data.time,
            "mac": data.mac,
            "systolic": data.max,  // 收缩压
            "diastolic": data.min  // 舒张压
        ]

        let key = "bp_\(data.time)_\(data.mac)"
        UserDefaults.standard.set(bpInfo, forKey: key)

        NotificationCenter.default.post(
            name: .bloodPressureUpdated,
            object: data
        )
    }

    // MARK: - 辅助方法

    private func getHeartRateList(for mac: String) -> [HeartData] {
        // 从本地读取心率列表
        // 这里简化处理，实际应使用数据库
        return []
    }

    private func saveHeartRateList(_ list: [HeartData], for mac: String) {
        // 保存心率列表到本地
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let stepDataUpdated = Notification.Name("stepDataUpdated")
    static let sleepDataUpdated = Notification.Name("sleepDataUpdated")
    static let heartRateUpdated = Notification.Name("heartRateUpdated")
    static let oxygenDataUpdated = Notification.Name("oxygenDataUpdated")
    static let bloodPressureUpdated = Notification.Name("bloodPressureUpdated")
}
```

---

## 常见问题

### 1. 蓝牙权限问题

**问题**: 应用无法访问蓝牙
**解决方案**: 确保在 `Info.plist` 中正确添加了蓝牙权限描述：

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>需要使用蓝牙连接智能手表设备</string>
```

### 2. 设备连接失败

**问题**: 调用 `connectDevice` 后连接失败
**可能原因**:
- 设备不在范围内
- 设备已连接到其他手机
- 蓝牙未开启
- MAC 地址错误

**解决方案**:
```swift
// 检查蓝牙状态
if XGZTBlueToothManager.shared.isCurrentBleStateOFF() {
    print("请先打开蓝牙")
    return
}

// 查看连接失败日志
let failLog = XGZTDeviceManager.shared.connectFailMessage
print("连接失败原因：\(failLog)")
```

### 3. 数据同步失败

**问题**: 无法同步健康数据
**解决方案**:
1. 确保设备已成功连接
2. 确保已实现并设置 `HealthDataStorageProtocol`
3. 检查设备是否支持该数据类型

```swift
// 确认连接状态
if !XGZTBlueToothManager.shared.isconnected() {
    print("设备未连接，无法同步数据")
    return
}

// 设置数据存储
XGZTBlueToothManager.shared.handler.dataStorage = HealthDataStorageManager.shared

// 同步数据
XGZTCommand.syncHistoryData()
```

### 4. 内存泄漏问题

**问题**: 长时间使用后内存占用过高
**解决方案**:
```swift
// 定期清理设备缓存
XGZTDeviceManager.shared.clearDeviceCache()

// 清理连接失败日志
XGZTDeviceManager.shared.clearFailMessages()

// 在不需要时断开蓝牙连接
XGZTBlueToothManager.shared.disconnectBle()
```

### 5. 多设备管理

**问题**: 如何管理多个智能手表设备
**解决方案**:
```swift
// 获取所有缓存的设备
let devices = XGZTDeviceManager.shared.cacheDevices

// 查找特定设备
if let device = XGZTDeviceManager.shared.findDevice(mac: "AA:BB:CC:DD:EE:FF") {
    print("找到设备：\(device.deviceName ?? "未知")")
}

// 切换连接设备
func switchDevice(to mac: String) {
    // 先断开当前设备
    XGZTBlueToothManager.shared.disconnectBle()

    // 等待断开完成后连接新设备
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        XGZTBlueToothManager.shared.connectDevice(mac) { success in
            print(success ? "切换成功" : "切换失败")
        }
    }
}
```

### 6. 日志调试

**问题**: 如何查看详细的运行日志
**解决方案**:
```swift
// 启用日志输出
XLogger.shared.enableLogging = true

// 设置日志级别
XLogger.shared.logLevel = .debug

// 查看日志
XLogger.shared.log("这是一条普通日志")
XLogger.shared.logWarning("这是一条警告")
XLogger.shared.logError("这是一条错误")

// 获取日志历史
let logs = XLogger.shared.getRecentLogs()
```

---

## 更新日志

### v1.0.2 (2026-01-10)

#### 新增功能
- ✨ 新增 `calculateCalorieAndDistance()` 方法：根据步数自动计算卡路里和距离
- ✨ 新增 `getFormattedDistance()` 方法：获取格式化后的距离值（公里）
- ✨ 新增 `getFormattedCalorie()` 方法：获取格式化后的卡路里值（千卡）

#### 功能增强
- 🚀 增强 `BluetoothWatchDevice` 模型，支持基于步数的健康指标计算

### v1.0.1 (2026-01-03)

#### 新增功能
- ✨ 首次发布 WatchProtocolSDK v1.0.1
- ✨ 完整的蓝牙设备管理功能
- ✨ 支持步数、睡眠、心率、血氧、血压数据同步
- ✨ 基于协议的数据存储设计，灵活适配不同存储方案
- ✨ 线程安全的设备管理和状态管理
- ✨ 完善的日志系统

#### 架构优化
- 🏗️ 模块化设计，清晰的职责划分
- 🏗️ 协议化编程，降低耦合度
- 🏗️ 单例模式，便于全局访问

#### 文档
- 📖 提供完整的中英文接入文档
- 📖 丰富的示例代码
- 📖 详细的 API 参考

---

## 技术支持

如有问题或建议，请联系：

- **Email**: your.email@example.com
- **GitHub**: https://github.com/yourcompany/WatchProtocolSDK
- **文档**: https://docs.yourcompany.com/WatchProtocolSDK

---

## 许可协议

WatchProtocolSDK 采用 MIT 许可协议，详见 LICENSE 文件。

---

**© 2025-2026 Your Company. All Rights Reserved.**
