# WatchProtocol Framework 创建指南

> **文档版本**: 1.0
> **创建日期**: 2025-12-27
> **适用于**: Xcode 15+, iOS 12+

---

## 📋 准备工作清单

在开始之前，请确认以下内容已完成：

- [x] 全局变量优化已完成（XGZTDeviceManager, XGZTCommandStateManager, XGZTConnectionStateManager）
- [x] 代码编译通过，无错误
- [x] Git 已提交当前工作，创建了新分支
- [ ] 确认 Xcode 版本 >= 15.0
- [ ] 确认已安装 CocoaPods（如果需要）

---

## 🎯 Framework 架构设计

### 最终目标

```
WatchProtocolSDK.framework
├── Core（核心模块）
│   ├── XGZTBlueToothManager
│   ├── XGZTBusinessHandler
│   ├── XGZTCommands
│   ├── XGZTDeviceManager
│   ├── XGZTCommandStateManager
│   └── XGZTConnectionStateManager
│
├── Models（数据模型）
│   ├── BluetoothWatchDevice
│   └── DatabaseManager
│
├── Utils（工具类）
│   └── XLogger
│
└── Public（公开接口）
    ├── WatchProtocolSDK.h
    └── WPPublicAPI.swift
```

---

## 📝 第一步：在 Xcode 中创建 Framework Target

### 1.1 创建 Framework

1. **打开项目**
   - 启动 Xcode
   - 打开 `SmartBracelet.xcodeproj`

2. **添加新 Target**
   - 菜单栏：`File` → `New` → `Target...`
   - 或使用快捷键：`⌘ + N`

3. **选择模板**
   - 平台：`iOS`
   - 模板：`Framework`
   - 点击 `Next`

4. **配置 Framework**
   ```
   Product Name: WatchProtocolSDK
   Team: [选择你的开发团队]
   Organization Identifier: com.yourcompany
   Bundle Identifier: com.yourcompany.WatchProtocolSDK
   Language: Swift
   Include Tests: ☑️ （推荐勾选）
   ```
   - 点击 `Finish`

5. **验证创建结果**
   - 左侧项目导航器应该出现 `WatchProtocolSDK` 文件夹
   - 包含 `WatchProtocolSDK.h` 头文件
   - Targets 列表中出现 `WatchProtocolSDK`

### 1.2 配置 Framework 基础设置

1. **选择 WatchProtocolSDK Target**
   - 点击项目名称（顶部）
   - 在 TARGETS 列表中选择 `WatchProtocolSDK`

2. **General 设置**
   ```
   Display Name: WatchProtocolSDK
   Bundle Identifier: com.yourcompany.WatchProtocolSDK
   Version: 1.0.0
   Build: 1

   Deployment Info:
   ├─ iOS: 12.0（最低支持版本）
   └─ Devices: iPhone/iPad
   ```

3. **Build Settings 关键配置**

   点击 `Build Settings` 标签，搜索并设置：

   **Swift 语言设置**
   ```
   Swift Language Version: Swift 5
   ```

   **模块稳定性**（重要！）
   ```
   Build Libraries for Distribution: YES
   ```
   > 这个设置确保 Framework 可以在不同 Swift 版本间使用

   **框架搜索路径**
   ```
   Framework Search Paths:
   - $(inherited)
   - $(PROJECT_DIR)/Pods  （如果使用 CocoaPods）
   ```

   **安装设置**
   ```
   Skip Install: NO
   Installation Directory: $(LOCAL_LIBRARY_DIR)/Frameworks
   ```

   **头文件可见性**
   ```
   Defines Module: YES
   ```

4. **Build Phases 设置**

   点击 `Build Phases` 标签：

   - **Headers**（如果没有则点击 `+` 添加）
     - Public: 拖入需要公开的头文件
     - Project: 项目内部使用的头文件
     - Private: 私有头文件

   - **Compile Sources**
     - 确保所有 Swift 文件都在这里

   - **Link Binary With Libraries**
     - 后续添加依赖（CoreBluetooth, RealmSwift 等）

---

## 📂 第二步：组织 Framework 目录结构

### 2.1 创建目录结构

在 Xcode 中右键 `WatchProtocolSDK` 文件夹：

1. **创建 Core 文件夹**
   - `New Group` → 命名为 `Core`
   - 存放核心业务类

2. **创建 Models 文件夹**
   - `New Group` → 命名为 `Models`
   - 存放数据模型

3. **创建 Utils 文件夹**
   - `New Group` → 命名为 `Utils`
   - 存放工具类

4. **创建 Public 文件夹**
   - `New Group` → 命名为 `Public`
   - 存放公开 API

最终结构：
```
WatchProtocolSDK/
├── WatchProtocolSDK.h
├── Info.plist
├── Core/
├── Models/
├── Utils/
└── Public/
```

### 2.2 移动现有文件（稍后执行）

> ⚠️ 注意：文件移动需要在配置完依赖后进行，本步骤稍后执行

文件移动计划：
```
从 SmartBracelet/huaxin/WatchProtocol/ 移动到 WatchProtocolSDK/

Core/ 文件夹
├── XGZTBlueToothManager.swift
├── XGZTBusinessHandler.swift
├── XGZTCommands.swift
├── XGZTDeviceManager.swift
├── XGZTCommandStateManager.swift
└── XGZTConnectionStateManager.swift

Models/ 文件夹
├── XGZTSwitchDevice.swift
└── DatabaseManager.swift

Utils/ 文件夹
└── XLogger.swift
```

---

## 🔗 第三步：配置依赖项

### 3.1 系统框架依赖

1. 选择 `WatchProtocolSDK` Target
2. `Build Phases` → `Link Binary With Libraries`
3. 点击 `+` 添加：
   ```
   Foundation.framework
   CoreBluetooth.framework
   UIKit.framework
   ```

### 3.2 第三方库依赖（RealmSwift）

**方式一：使用 CocoaPods（推荐）**

1. 编辑 `Podfile`，添加 Framework target：

```ruby
# Podfile 示例

platform :ios, '12.0'
use_frameworks!

# 主项目 Target
target 'SmartBracelet' do
  pod 'RealmSwift', '~> 10.0'
  # 其他依赖...
end

# Framework Target
target 'WatchProtocolSDK' do
  pod 'RealmSwift', '~> 10.0'
end
```

2. 运行安装命令：
```bash
cd /Users/anker/Downloads/SmartBracelet
pod install
```

3. 重新打开 `.xcworkspace` 文件（不是 `.xcodeproj`）

**方式二：手动添加（不推荐）**

如果不使用 CocoaPods：
1. 下载 RealmSwift XCFramework
2. 拖入项目
3. 在 `General` → `Frameworks, Libraries, and Embedded Content` 中添加

### 3.3 解决循环依赖

由于 Framework 需要引用主项目的某些工具类（如 `Async`），有几种方案：

**方案 A：复制代码到 Framework（推荐）**
```swift
// 在 WatchProtocolSDK/Utils/ 中创建 WPAsync.swift
// 复制 Async 的实现
```

**方案 B：通过协议解耦**
```swift
// 定义协议
public protocol AsyncProvider {
    func main(after: Double, _ block: @escaping () -> Void)
}

// Framework 使用协议
class SomeManager {
    var asyncProvider: AsyncProvider?
}
```

**方案 C：使用 DispatchQueue 替代**
```swift
// 直接使用系统 API
DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
    // code
}
```

> 推荐使用**方案 A 或方案 C**

---

## 📄 第四步：创建公开 API

### 4.1 更新 WatchProtocolSDK.h

打开 `WatchProtocolSDK/WatchProtocolSDK.h`，更新为：

```objc
//
//  WatchProtocolSDK.h
//  WatchProtocolSDK
//
//  Created on 2025-12-27.
//

#import <Foundation/Foundation.h>

//! Project version number for WatchProtocolSDK.
FOUNDATION_EXPORT double WatchProtocolSDKVersionNumber;

//! Project version string for WatchProtocolSDK.
FOUNDATION_EXPORT const unsigned char WatchProtocolSDKVersionString[];

// In this header, you should import all the public headers of your framework using statements like:
// #import <WatchProtocolSDK/PublicHeader.h>

// Swift classes will be automatically exposed through the generated header
```

### 4.2 创建 Swift 公开 API

在 `Public/` 文件夹中创建 `WPPublicAPI.swift`：

```swift
//
//  WPPublicAPI.swift
//  WatchProtocolSDK
//
//  Created on 2025-12-27.
//

import Foundation
import CoreBluetooth

/// WatchProtocol SDK 主入口类
public class WatchProtocolSDK {

    // MARK: - 单例

    public static let shared = WatchProtocolSDK()

    private init() {}

    // MARK: - 版本信息

    /// SDK 版本号
    public static let version = "1.0.0"

    /// SDK 构建号
    public static let build = "1"

    // MARK: - 初始化

    /// 初始化 SDK
    /// - Parameters:
    ///   - logLevel: 日志级别
    ///   - databasePath: 数据库路径（可选，默认使用应用Documents目录）
    public func initialize(logLevel: WPLogLevel = .info, databasePath: String? = nil) {
        XLogger.shared.log("🚀 WatchProtocolSDK v\(Self.version) 初始化")

        // 初始化数据库
        if let path = databasePath {
            // 配置自定义数据库路径
            XLogger.shared.log("📦 使用自定义数据库路径: \(path)")
        }
    }

    // MARK: - 蓝牙管理

    /// 获取蓝牙管理器实例
    public var bluetoothManager: WPBluetoothManager {
        return WPBluetoothManager.shared
    }

    /// 获取设备管理器实例
    public var deviceManager: WPDeviceManager {
        return WPDeviceManager.shared
    }

    /// 获取连接状态管理器实例
    public var connectionManager: WPConnectionStateManager {
        return WPConnectionStateManager.shared
    }
}

/// 日志级别枚举
public enum WPLogLevel: Int {
    case verbose = 0
    case debug = 1
    case info = 2
    case warning = 3
    case error = 4
}

/// 蓝牙管理器（对外封装）
public class WPBluetoothManager {
    static let shared = WPBluetoothManager()
    private init() {}

    /// 蓝牙是否已初始化
    public var isInitialized: Bool {
        return XGZTBlueToothManager.shared.centralManager != nil
    }

    /// 初始化蓝牙
    public func initialize() {
        XGZTBlueToothManager.shared.initCentral()
    }

    /// 开始扫描设备
    public func startScan() {
        XGZTBlueToothManager.shared.startScan()
    }

    /// 停止扫描
    public func stopScan() {
        XGZTBlueToothManager.shared.stopScanning()
    }

    /// 连接设备
    /// - Parameter device: 设备对象
    public func connect(device: BluetoothWatchDevice) {
        XGZTBlueToothManager.shared.connect(device: device)
    }

    /// 断开连接
    public func disconnect() {
        XGZTBlueToothManager.shared.disConnectBle()
    }

    /// 是否已连接
    public func isConnected() -> Bool {
        return XGZTBlueToothManager.shared.isconnected()
    }
}

/// 设备管理器（对外封装）
public class WPDeviceManager {
    static let shared = WPDeviceManager()
    private init() {}

    /// 获取缓存的设备列表
    public var cachedDevices: [BluetoothWatchDevice] {
        return XGZTDeviceManager.shared.cacheDevices
    }

    /// 添加设备到缓存
    public func addDevice(_ device: BluetoothWatchDevice) {
        XGZTDeviceManager.shared.addDevice(device)
    }

    /// 查找设备
    public func findDevice(mac: String) -> BluetoothWatchDevice? {
        return XGZTDeviceManager.shared.findDevice(mac: mac)
    }

    /// 重新加载设备
    public func reloadDevices() {
        XGZTDeviceManager.shared.reloadDevices()
    }
}

/// 连接状态管理器（对外封装）
public class WPConnectionStateManager {
    static let shared = WPConnectionStateManager()
    private init() {}

    /// 是否为XGZT设备
    public var isXGZTDevice: Bool {
        return XGZTConnectionStateManager.shared.isXGZTDevice
    }

    /// 最后连接的设备MAC
    public var lastDeviceMac: String {
        return XGZTConnectionStateManager.shared.lastDeviceMac
    }

    /// 当前设备类型
    public var deviceType: DeviceType {
        return XGZTConnectionStateManager.shared.currentDeviceType
    }
}
```

### 4.3 设置文件访问权限

确保需要公开的类和方法都标记为 `public`：

1. 打开每个需要公开的 Swift 文件
2. 在类定义前添加 `public` 关键字：
   ```swift
   public class XGZTBlueToothManager { ... }
   public class BluetoothWatchDevice { ... }
   public enum DeviceType { ... }
   ```

---

## 🧪 第五步：测试 Framework

### 5.1 编译 Framework

1. 选择 Scheme：`WatchProtocolSDK`
2. 选择目标设备：`Any iOS Device (arm64)`
3. 菜单：`Product` → `Build` 或按 `⌘ + B`
4. 检查编译输出，确保无错误

### 5.2 在主项目中集成测试

1. 选择 `SmartBracelet` Target
2. `General` → `Frameworks, Libraries, and Embedded Content`
3. 点击 `+` → 选择 `WatchProtocolSDK.framework`
4. Embed 设置为：`Embed & Sign`

5. 在主项目代码中导入：
```swift
import WatchProtocolSDK

// 测试初始化
WatchProtocolSDK.shared.initialize()

// 测试蓝牙管理器
let btManager = WatchProtocolSDK.shared.bluetoothManager
btManager.initialize()
```

6. 编译主项目，确保能正常使用 Framework

---

## 📦 第六步：导出 Framework

### 6.1 构建 Release 版本

1. 编辑 Scheme
   - `Product` → `Scheme` → `Edit Scheme...`
   - 选择 `Run`
   - Build Configuration 改为 `Release`

2. 构建 Framework
   ```bash
   # 构建 iOS 真机版本
   xcodebuild -project SmartBracelet.xcodeproj \
              -scheme WatchProtocolSDK \
              -configuration Release \
              -sdk iphoneos \
              BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
              clean build

   # 构建 iOS 模拟器版本
   xcodebuild -project SmartBracelet.xcodeproj \
              -scheme WatchProtocolSDK \
              -configuration Release \
              -sdk iphonesimulator \
              BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
              clean build
   ```

### 6.2 创建 XCFramework（支持多架构）

```bash
# 合并真机和模拟器版本为 XCFramework
xcodebuild -create-xcframework \
  -framework build/Release-iphoneos/WatchProtocolSDK.framework \
  -framework build/Release-iphonesimulator/WatchProtocolSDK.framework \
  -output WatchProtocolSDK.xcframework
```

### 6.3 Framework 位置

编译后的 Framework 位置：
```
~/Library/Developer/Xcode/DerivedData/SmartBracelet-xxx/Build/Products/Release-iphoneos/WatchProtocolSDK.framework
```

---

## 📚 第七步：文档和发布

### 7.1 创建 README

在 Framework 文件夹中创建 `README.md`：

```markdown
# WatchProtocolSDK

自研手表蓝牙通信协议 SDK

## 功能特性

- ✅ 蓝牙设备扫描和连接
- ✅ 设备数据同步
- ✅ 健康数据管理
- ✅ 线程安全的状态管理
- ✅ 自动持久化

## 系统要求

- iOS 12.0+
- Xcode 15.0+
- Swift 5.0+

## 安装

### CocoaPods

\`\`\`ruby
pod 'WatchProtocolSDK', '~> 1.0'
\`\`\`

### 手动集成

1. 下载 `WatchProtocolSDK.xcframework`
2. 拖入 Xcode 项目
3. 在 Target → General → Frameworks 中添加

## 快速开始

\`\`\`swift
import WatchProtocolSDK

// 初始化 SDK
WatchProtocolSDK.shared.initialize()

// 初始化蓝牙
let btManager = WatchProtocolSDK.shared.bluetoothManager
btManager.initialize()

// 开始扫描
btManager.startScan()
\`\`\`

## 文档

详见 [完整文档](https://your-docs-url.com)

## 许可

Copyright © 2025 Your Company
```

### 7.2 版本发布清单

发布新版本时的检查清单：

- [ ] 更新版本号（Info.plist 和 WPPublicAPI.swift）
- [ ] 更新 CHANGELOG.md
- [ ] 运行所有测试
- [ ] 编译 Release 版本
- [ ] 创建 Git tag
- [ ] 上传到仓库/发布平台

---

## ⚠️ 常见问题

### Q1: 编译时找不到 RealmSwift

**解决方案**：
1. 确认 Podfile 中添加了 Framework target
2. 运行 `pod install`
3. 打开 `.xcworkspace` 而不是 `.xcodeproj`

### Q2: Framework 在主项目中无法导入

**解决方案**：
1. 检查 Framework 是否在 `Embed & Sign` 列表中
2. 检查 Build Settings → `Defines Module` 是否为 YES
3. Clean Build Folder (`⌘ + Shift + K`) 后重新编译

### Q3: 运行时崩溃 "dyld: Library not loaded"

**解决方案**：
1. 检查 Framework 的 Embed 设置
2. 确保 Framework 的 Deployment Target <= 主项目

### Q4: Swift 版本不兼容

**解决方案**：
1. 确保设置了 `Build Libraries for Distribution = YES`
2. 使用 XCFramework 而不是 Framework

---

## 📞 支持

如有问题，请联系开发团队或提交 Issue。

**创建完成时间**: 2025-12-27
**文档版本**: 1.0
