# WatchProtocol Framework 设计方案

## 📋 项目概述

将 `SmartBracelet/huaxin/WatchProtocol` 及相关模块封装为独立的 **WatchProtocolSDK.framework**，既能在当前项目中使用，也能提供给其他团队集成。

---

## 🔍 现状分析

### WatchProtocol 目录结构
```
SmartBracelet/huaxin/
├── WatchProtocol/                    # 核心协议模块
│   ├── XGZTBlueToothManager.swift   # 蓝牙管理器（核心）
│   ├── XGZTBusinessHandler.swift    # 业务逻辑处理
│   ├── XGZTCommands.swift           # 命令集定义（2300+ 行）
│   ├── XGZTSwitchDevice.swift       # 设备模型和缓存
│   ├── DatabaseManager.swift         # 数据库管理（Realm）
│   └── XLogger.swift                 # 日志工具
│
└── OTA/                              # 固件升级模块（相关依赖）
    ├── OtaService.swift             # OTA 服务定义
    └── FOTA/
        ├── Log/Logger.swift         # OTA 日志
        └── ABOta/ABOtaManager.swift # OTA 管理器
```

### 依赖关系图
```
WatchProtocol 模块
├── 系统框架
│   ├── Foundation
│   ├── CoreBluetooth
│   └── UIKit
│
├── 第三方库
│   └── RealmSwift (数据库)
│
└── 项目内部依赖
    ├── OTA 模块
    │   ├── OTAService (结构体)
    │   └── Logger (OTA 日志)
    │
    ├── 工具类
    │   └── Async (异步工具)
    │
    ├── 其他模块
    │   └── BLEManager.shared.stopScan()
    │
    └── 全局变量
        ├── isXGZT (在 MTabBarController.swift)
        ├── lastestDeviceMac (通过 UserDefaults)
        └── connectFailMessage (在 XGZTSwitchDevice.swift)
```

---

## 🎯 Framework 设计方案

### 方案一：完整集成方案（推荐）⭐

将 WatchProtocol + OTA 相关模块一起封装，提供完整功能。

#### 架构设计
```
WatchProtocolSDK.framework
│
├── Core/                          # 核心模块
│   ├── WPBluetoothManager.swift  # 蓝牙管理（重命名）
│   ├── WPBusinessHandler.swift   # 业务处理
│   ├── WPCommands.swift          # 命令集
│   ├── WPDevice.swift            # 设备模型
│   └── WPDatabaseManager.swift   # 数据库管理
│
├── OTA/                          # OTA 模块
│   ├── WPOTAService.swift       # OTA 服务
│   ├── WPOTAManager.swift       # OTA 管理器
│   └── Logger.swift              # OTA 日志
│
├── Utils/                        # 工具类
│   ├── WPLogger.swift           # 日志工具
│   └── WPAsync.swift            # 异步工具（内部实现）
│
└── Public/                       # 公开接口
    ├── WatchProtocolSDK.h       # 主头文件
    └── WPPublicAPI.swift        # 公开 API
```

#### 优点
- ✅ 功能完整，包含蓝牙通信 + OTA 升级
- ✅ 依赖清晰，仅需 RealmSwift
- ✅ 易于维护和版本管理
- ✅ 其他团队可以直接集成完整功能

#### 缺点
- ⚠️ Framework 体积较大（包含 OTA 模块）
- ⚠️ 需要一起维护 OTA 代码

---

### 方案二：分离模块方案

将协议和 OTA 分成两个独立 Framework。

#### 架构设计
```
1. WatchProtocolSDK.framework     # 核心协议
   - 蓝牙通信
   - 设备管理
   - 数据库操作

2. WatchOTASDK.framework          # OTA 升级
   - 固件升级功能
   - 依赖 WatchProtocolSDK
```

#### 优点
- ✅ 模块职责清晰
- ✅ 可按需集成（不需要 OTA 的团队只集成协议 SDK）
- ✅ 更新 OTA 不影响协议模块

#### 缺点
- ⚠️ 需要维护两个 Framework
- ⚠️ 依赖关系复杂（OTA 依赖 Protocol）
- ⚠️ 集成成本增加

---

## 🛠 实施方案（方案一详细步骤）

### 1. 创建 Framework 工程

#### Xcode 配置
```bash
# 在 SmartBracelet 项目根目录下创建
File > New > Target > Framework
- Product Name: WatchProtocolSDK
- Language: Swift
- Deployment Target: iOS 12.0
```

#### Framework 配置
```ruby
# Framework 配置参数
PRODUCT_NAME = WatchProtocolSDK
PRODUCT_BUNDLE_IDENTIFIER = com.yourcompany.watchprotocolsdk
IPHONEOS_DEPLOYMENT_TARGET = 12.0
BUILD_LIBRARY_FOR_DISTRIBUTION = YES  # 支持不同 Swift 版本
SKIP_INSTALL = NO
DEFINES_MODULE = YES
```

---

### 2. 代码迁移和重构

#### 文件迁移列表
```
源文件                                      -> 目标位置
--------------------------------------------------------------------
WatchProtocol/XGZTBlueToothManager.swift  -> Core/WPBluetoothManager.swift
WatchProtocol/XGZTBusinessHandler.swift   -> Core/WPBusinessHandler.swift
WatchProtocol/XGZTCommands.swift          -> Core/WPCommands.swift
WatchProtocol/XGZTSwitchDevice.swift      -> Core/WPDevice.swift
WatchProtocol/DatabaseManager.swift        -> Core/WPDatabaseManager.swift
WatchProtocol/XLogger.swift               -> Utils/WPLogger.swift
OTA/OtaService.swift                      -> OTA/WPOTAService.swift
OTA/FOTA/Log/Logger.swift                 -> OTA/WPOTALogger.swift
```

#### 命名规范重构
```swift
// 原命名（XGZT前缀）                 -> 新命名（WP前缀）
XGZTBlueToothManager                 -> WPBluetoothManager
XGZTBusinessHandler                  -> WPBusinessHandler
XGZTCommands                         -> WPCommands
XGZTCommand                          -> WPCommand
BluetoothWatchDevice                 -> WPDevice
DatabaseManager                      -> WPDatabaseManager
XLogger                              -> WPLogger
```

---

### 3. 依赖解耦处理

#### 3.1 全局变量解耦

**原代码（项目依赖）**
```swift
// MTabBarController.swift
var isXGZT = false

// XGZTSwitchDevice.swift
public var connectFailMessage = ""
public var cacheDevices = [BluetoothWatchDevice]()

// 通过 UserDefaults 访问
let lastestDeviceMac = UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? ""
```

**Framework 解决方案（代理模式）**
```swift
// WPPublicAPI.swift - Framework 公开接口

/// Framework 配置协议
public protocol WPConfigurationDelegate: AnyObject {
    /// 获取当前连接的设备 MAC 地址
    func getCurrentDeviceMac() -> String

    /// 保存设备 MAC 地址
    func saveDeviceMac(_ mac: String)

    /// 获取连接失败消息
    func getConnectFailMessage() -> String

    /// 追加连接失败消息
    func appendConnectFailMessage(_ message: String)

    /// 通知连接状态变化
    func didConnectStatusChanged(isConnected: Bool)
}

/// Framework 主类
public class WatchProtocolSDK {
    public static let shared = WatchProtocolSDK()

    /// 配置代理
    public weak var configDelegate: WPConfigurationDelegate?

    /// 蓝牙管理器
    public var bluetoothManager: WPBluetoothManager {
        return WPBluetoothManager.shared
    }

    private init() {}
}
```

**本项目集成实现**
```swift
// SmartBracelet/Bridge/WPBridge.swift

class WPBridge: WPConfigurationDelegate {
    static let shared = WPBridge()

    func getCurrentDeviceMac() -> String {
        return UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? ""
    }

    func saveDeviceMac(_ mac: String) {
        UserDefaults.standard.setValue(mac, forKey: "LastestDeviceMac")
        UserDefaults.standard.synchronize()
    }

    func getConnectFailMessage() -> String {
        return connectFailMessage
    }

    func appendConnectFailMessage(_ message: String) {
        connectFailMessage += message
    }

    func didConnectStatusChanged(isConnected: Bool) {
        isXGZT = isConnected
        NotificationCenter.default.post(name: Notification.Name("DevicesViewController"), object: "1")
    }
}

// AppDelegate.swift 初始化
func application(_ application: UIApplication, didFinishLaunchingWithOptions...) -> Bool {
    // 配置 Framework
    WatchProtocolSDK.shared.configDelegate = WPBridge.shared
    return true
}
```

#### 3.2 BLEManager 依赖解耦

**原代码**
```swift
// XGZTBlueToothManager.swift:126
BLEManager.shared.stopScan()
```

**Framework 解决方案（可选协议）**
```swift
// WPPublicAPI.swift

/// 额外蓝牙操作协议（可选）
public protocol WPExternalBLEDelegate: AnyObject {
    /// 停止外部扫描
    func stopExternalScan()
}

// WPBluetoothManager.swift
class WPBluetoothManager {
    weak var externalBLEDelegate: WPExternalBLEDelegate?

    func stopScanning() {
        isScanning = false
        centralManager?.stopScan()

        // 调用外部代理
        externalBLEDelegate?.stopExternalScan()
    }
}
```

**本项目实现**
```swift
extension WPBridge: WPExternalBLEDelegate {
    func stopExternalScan() {
        BLEManager.shared.stopScan()
    }
}

// 初始化时设置
WatchProtocolSDK.shared.bluetoothManager.externalBLEDelegate = WPBridge.shared
```

#### 3.3 Async 工具解耦

**原代码**
```swift
// XGZTBusinessHandler.swift:74
Async.main(after: 0.5) {
    NotificationCenter.default.post(...)
}
```

**Framework 内部实现**
```swift
// Utils/WPAsync.swift

struct WPAsync {
    static func main(after seconds: TimeInterval, _ block: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: block)
    }

    static func background(_ block: @escaping () -> Void) {
        DispatchQueue.global(qos: .background).async(execute: block)
    }
}

// 替换所有 Async 调用为 WPAsync
```

#### 3.4 OTA 模块整合

**OTAService 保留在 Framework 内**
```swift
// OTA/WPOTAService.swift
public struct WPOTAService {
    public static let uuid        = CBUUID(string: "FF12")
    public static let dataInUuid  = CBUUID(string: "FF14")
    public static let dataOutUuid = CBUUID(string: "FF15")
}
```

**Logger 统一**
```swift
// OTA/WPOTALogger.swift
class WPOTALogger {
    static func log(_ message: String) {
        WPLogger.shared.log("[OTA] \(message)")
    }
}
```

---

### 4. 公开 API 设计

#### WatchProtocolSDK.h（主头文件）
```objc
#import <Foundation/Foundation.h>

FOUNDATION_EXPORT double WatchProtocolSDKVersionNumber;
FOUNDATION_EXPORT const unsigned char WatchProtocolSDKVersionString[];

// Public headers
```

#### WPPublicAPI.swift（Swift 公开接口）
```swift
import Foundation
import CoreBluetooth

// MARK: - Framework 主类
public class WatchProtocolSDK {
    public static let shared = WatchProtocolSDK()

    /// 配置代理
    public weak var configDelegate: WPConfigurationDelegate?

    /// 蓝牙管理器
    public var bluetoothManager: WPBluetoothManager {
        return WPBluetoothManager.shared
    }

    /// 版本号
    public static var version: String {
        return "1.0.0"
    }

    private init() {}
}

// MARK: - 蓝牙管理器公开接口
public class WPBluetoothManager {
    public static let shared = WPBluetoothManager()

    /// 蓝牙代理
    public weak var delegate: WPBluetoothDelegate?

    /// 初始化蓝牙
    public func initializeBluetooth() {
        centralManager = CBCentralManager(delegate: self, queue: .global())
    }

    /// 开始扫描设备
    public func startScanning(deleteCache: Bool = false) { }

    /// 停止扫描
    public func stopScanning() { }

    /// 连接设备
    public func connect(toMac mac: String) { }

    /// 断开连接
    public func disconnect() { }

    /// 是否已连接
    public func isConnected() -> Bool { }

    /// 获取当前设备
    public var currentDevice: WPDevice? { }

    /// 发送命令
    public func sendCommand(_ command: WPCommand) { }

    /// OTA 准备检查
    public func prepareForOTA(completion: @escaping (Bool) -> Void) { }
}

// MARK: - 蓝牙代理协议
public protocol WPBluetoothDelegate: AnyObject {
    /// 蓝牙状态变化
    func bluetoothDidUpdateState(_ state: CBManagerState)

    /// 发现设备
    func bluetoothDidDiscoverDevice(_ device: WPDevice, rssi: Int)

    /// 连接成功
    func bluetoothDidConnect(_ device: WPDevice)

    /// 连接失败
    func bluetoothDidFailToConnect(_ error: Error?)

    /// 断开连接
    func bluetoothDidDisconnect(_ error: Error?)

    /// 接收数据
    func bluetoothDidReceiveData(_ data: Data)
}

// MARK: - 设备模型
public class WPDevice {
    public var deviceName: String?
    public var macAddress: String?
    public var batteryLevel: Int?
    public var firmwareVersion: String?
    // ... 其他属性
}

// MARK: - 命令类
public class WPCommand {
    /// 同步时间
    public static func syncTime() -> WPCommand { }

    /// 获取电池信息
    public static func getBattery() -> WPCommand { }

    /// 设置屏幕亮度
    public static func setScreenBrightness(_ level: Int) -> WPCommand { }

    // ... 其他命令
}
```

---

### 5. CocoaPods 配置

#### WatchProtocolSDK.podspec
```ruby
Pod::Spec.new do |s|
  s.name             = 'WatchProtocolSDK'
  s.version          = '1.0.0'
  s.summary          = '智能手表通信协议 SDK'
  s.description      = <<-DESC
                       提供完整的智能手表蓝牙通信和 OTA 升级功能。
                       支持设备扫描、连接、数据同步、固件升级等。
                       DESC
  s.homepage         = 'https://github.com/yourcompany/WatchProtocolSDK'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Your Name' => 'email@example.com' }
  s.source           = { :git => 'https://github.com/yourcompany/WatchProtocolSDK.git',
                         :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'
  s.swift_version = '5.0'

  # 源文件
  s.source_files = 'WatchProtocolSDK/**/*.{swift,h,m}'

  # 资源文件
  # s.resources = 'WatchProtocolSDK/Resources/**/*'

  # 依赖
  s.dependency 'RealmSwift', '~> 10.0'

  # Framework
  s.frameworks = 'Foundation', 'CoreBluetooth', 'UIKit'

  # 模块化
  s.module_name = 'WatchProtocolSDK'
end
```

#### 本项目 Podfile 修改
```ruby
# Podfile

target 'SmartBracelet' do
  use_frameworks!

  # 其他依赖
  pod 'RealmSwift'

  # 本地开发时使用
  pod 'WatchProtocolSDK', :path => './WatchProtocolSDK'

  # 或者使用 git 仓库
  # pod 'WatchProtocolSDK', :git => 'https://github.com/yourcompany/WatchProtocolSDK.git',
  #                         :tag => '1.0.0'
end
```

---

### 6. 本项目集成步骤

#### 步骤 1：创建桥接文件
```swift
// SmartBracelet/Bridge/WPBridge.swift

import WatchProtocolSDK
import Foundation

class WPBridge: NSObject {
    static let shared = WPBridge()

    private override init() {
        super.init()
        setupFramework()
    }

    private func setupFramework() {
        // 设置代理
        WatchProtocolSDK.shared.configDelegate = self

        // 设置蓝牙代理
        WatchProtocolSDK.shared.bluetoothManager.delegate = self
        WatchProtocolSDK.shared.bluetoothManager.externalBLEDelegate = self

        // 初始化蓝牙
        WatchProtocolSDK.shared.bluetoothManager.initializeBluetooth()
    }
}

// MARK: - 配置代理
extension WPBridge: WPConfigurationDelegate {
    func getCurrentDeviceMac() -> String {
        return UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? ""
    }

    func saveDeviceMac(_ mac: String) {
        UserDefaults.standard.setValue(mac, forKey: "LastestDeviceMac")
        UserDefaults.standard.synchronize()
    }

    func getConnectFailMessage() -> String {
        return connectFailMessage
    }

    func appendConnectFailMessage(_ message: String) {
        connectFailMessage += message
    }

    func didConnectStatusChanged(isConnected: Bool) {
        isXGZT = isConnected
        NotificationCenter.default.post(name: Notification.Name("DevicesViewController"), object: "1")
    }
}

// MARK: - 蓝牙代理
extension WPBridge: WPBluetoothDelegate {
    func bluetoothDidUpdateState(_ state: CBManagerState) {
        // 处理蓝牙状态变化
    }

    func bluetoothDidDiscoverDevice(_ device: WPDevice, rssi: Int) {
        // 发现设备
        NotificationCenter.default.post(name: Notification.Name.SearchDevice, object: "scan")
    }

    func bluetoothDidConnect(_ device: WPDevice) {
        // 连接成功
    }

    func bluetoothDidFailToConnect(_ error: Error?) {
        // 连接失败
    }

    func bluetoothDidDisconnect(_ error: Error?) {
        // 断开连接
    }

    func bluetoothDidReceiveData(_ data: Data) {
        // 接收数据
    }
}

// MARK: - 外部蓝牙代理
extension WPBridge: WPExternalBLEDelegate {
    func stopExternalScan() {
        BLEManager.shared.stopScan()
    }
}
```

#### 步骤 2：替换原有调用
```swift
// 原代码
XGZTBlueToothManager.shared.initCentral()
XGZTBlueToothManager.shared.startScanning()

// 新代码
WatchProtocolSDK.shared.bluetoothManager.initializeBluetooth()
WatchProtocolSDK.shared.bluetoothManager.startScanning()
```

---

### 7. 其他团队集成指南

#### 示例：新项目集成

**Podfile**
```ruby
target 'YourApp' do
  use_frameworks!

  pod 'WatchProtocolSDK', '~> 1.0.0'
end
```

**AppDelegate.swift**
```swift
import UIKit
import WatchProtocolSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // 配置 SDK
        WatchProtocolSDK.shared.configDelegate = MyConfigBridge.shared
        WatchProtocolSDK.shared.bluetoothManager.delegate = MyBluetoothHandler.shared

        // 初始化蓝牙
        WatchProtocolSDK.shared.bluetoothManager.initializeBluetooth()

        return true
    }
}
```

**MyConfigBridge.swift**
```swift
import WatchProtocolSDK

class MyConfigBridge: WPConfigurationDelegate {
    static let shared = MyConfigBridge()

    private var deviceMac: String = ""
    private var failMessages: [String] = []

    func getCurrentDeviceMac() -> String {
        return deviceMac
    }

    func saveDeviceMac(_ mac: String) {
        deviceMac = mac
        // 保存到本地数据库或 UserDefaults
    }

    func getConnectFailMessage() -> String {
        return failMessages.joined(separator: "\n")
    }

    func appendConnectFailMessage(_ message: String) {
        failMessages.append(message)
    }

    func didConnectStatusChanged(isConnected: Bool) {
        // 处理连接状态变化
        print("设备连接状态: \(isConnected)")
    }
}
```

**使用示例**
```swift
import WatchProtocolSDK

class DeviceViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // 开始扫描
        WatchProtocolSDK.shared.bluetoothManager.startScanning()
    }

    func connectToDevice(mac: String) {
        WatchProtocolSDK.shared.bluetoothManager.connect(toMac: mac)
    }

    func syncTime() {
        let command = WPCommand.syncTime()
        WatchProtocolSDK.shared.bluetoothManager.sendCommand(command)
    }
}
```

---

## 📝 实施清单

### Phase 1: 准备阶段（1-2天）
- [ ] 创建 Framework Target
- [ ] 配置 Framework 构建设置
- [ ] 创建目录结构
- [ ] 准备 CocoaPods 配置

### Phase 2: 代码迁移（3-4天）
- [ ] 迁移 WatchProtocol 核心文件
- [ ] 迁移 OTA 相关文件
- [ ] 重命名类和文件（XGZT -> WP）
- [ ] 修复编译错误

### Phase 3: 依赖解耦（2-3天）
- [ ] 实现配置代理协议
- [ ] 解耦全局变量
- [ ] 解耦 BLEManager 依赖
- [ ] 实现内部 Async 工具
- [ ] 处理 NotificationCenter 通知

### Phase 4: API 设计（2天）
- [ ] 设计公开接口
- [ ] 编写头文件
- [ ] 实现公开 API
- [ ] 隐藏内部实现

### Phase 5: 本项目集成（2天）
- [ ] 创建 WPBridge 桥接类
- [ ] 替换原有调用
- [ ] 测试功能完整性
- [ ] 修复 Bug

### Phase 6: 测试和文档（2-3天）
- [ ] 单元测试
- [ ] 集成测试
- [ ] 编写 API 文档
- [ ] 编写集成指南
- [ ] 准备示例代码

### Phase 7: 发布准备（1天）
- [ ] 版本号管理
- [ ] 生成 .framework 文件
- [ ] 创建 Git 仓库
- [ ] 发布到 CocoaPods（可选）

**预计总时间：13-17 工作日**

---

## ⚠️ 注意事项

### 1. 版本兼容性
- iOS 最低支持版本：iOS 12.0
- Swift 版本：5.0+
- Xcode 最低版本：13.0+

### 2. 数据迁移
- UserDefaults key 需要保持兼容
- Realm 数据库模型不能破坏性修改
- 设备缓存需要平滑迁移

### 3. 向后兼容
- 保留原有 API 作为 deprecated
- 提供迁移指南
- 至少保持 2 个版本的兼容期

### 4. 安全考虑
- 蓝牙权限处理
- 敏感数据加密（MAC 地址等）
- 防止内存泄漏

### 5. 性能优化
- 减少不必要的通知发送
- 优化数据库查询
- 蓝牙通信优化

---

## 🎁 预期收益

### 对当前项目
- ✅ 代码模块化，职责清晰
- ✅ 降低耦合度
- ✅ 便于测试和维护
- ✅ 可以独立升级 SDK 版本

### 对其他团队
- ✅ 开箱即用的完整方案
- ✅ 清晰的 API 文档
- ✅ 示例代码和集成指南
- ✅ 持续维护和技术支持

---

## 📚 参考资源

- [Apple Framework Programming Guide](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPFrameworks/Frameworks.html)
- [Creating a Framework for iOS](https://www.raywenderlich.com/5109-creating-a-framework-for-ios)
- [CocoaPods Guides](https://guides.cocoapods.org/)
- [Swift Package Manager](https://swift.org/package-manager/)

---

**文档版本**: 1.0
**最后更新**: 2025-12-27
**作者**: Claude Code
