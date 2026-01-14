# WatchProtocolSDK Objective-C 兼容性改造方案

## 1. 目标
让 WatchProtocolSDK（Swift SDK）能够被 Objective-C 项目无缝使用。

---

## 2. 技术方案：添加 Objective-C 兼容层

### 2.1 核心改造点

#### ✅ 数据模型改造（Struct → Class）
**当前问题**：Swift `struct` 无法直接暴露给 Objective-C

**解决方案**：
```swift
// 修改前（不兼容 ObjC）
public struct StepData {
    public let date: String
    public let mac: String
    public let step: Int
}

// 修改后（兼容 ObjC）
@objc public class WPStepData: NSObject {
    @objc public let date: String
    @objc public let mac: String
    @objc public let step: Int

    @objc public init(date: String, mac: String, step: Int) {
        self.date = date
        self.mac = mac
        self.step = step
        super.init()
    }
}
```

**需要改造的数据模型**：
- `StepData` → `WPStepData`
- `SleepData` → `WPSleepData`
- `HeartData` → `WPHeartData`
- `OxygenData` → `WPOxygenData`
- `BloodPressureData` → `WPBloodPressureData`

#### ✅ 协议改造
**当前问题**：Swift `protocol` 需要添加 `@objc` 标记

**解决方案**：
```swift
// 修改前
public protocol HealthDataStorageProtocol: AnyObject {
    func saveStepData(_ data: StepData)
}

// 修改后
@objc public protocol WPHealthDataStorageProtocol: NSObjectProtocol {
    @objc func saveStepData(_ data: WPStepData)
    @objc func saveSleepData(_ data: WPSleepData)
    @objc func saveHeartData(_ data: WPHeartData)
    @objc func saveOxygenData(_ data: WPOxygenData)
    @objc func saveBloodPressureData(_ data: WPBloodPressureData)
}
```

#### ✅ 管理类改造
**当前问题**：主要管理类需要暴露给 Objective-C

**解决方案**：
```swift
// XGZTDeviceManager.swift
@objc public class XGZTDeviceManager: NSObject {
    @objc public static let shared = XGZTDeviceManager()

    @objc public weak var dataStorage: WPHealthDataStorageProtocol?

    @objc public func initialize(storage: WPHealthDataStorageProtocol) {
        self.dataStorage = storage
    }
}

// XGZTBlueToothManager.swift
@objc public class XGZTBlueToothManager: NSObject {
    @objc public static let shared = XGZTBlueToothManager()

    @objc public func startScan()
    @objc public func stopScan()
    @objc public func connect(peripheral: CBPeripheral)
    @objc public func disconnect()
}
```

#### ✅ 枚举改造
**当前问题**：Swift 枚举需要使用 `@objc` 和 `Int` rawValue

**解决方案**：
```swift
// 修改前
public enum ConnectionState {
    case disconnected
    case connecting
    case connected
}

// 修改后
@objc public enum WPConnectionState: Int {
    case disconnected = 0
    case connecting = 1
    case connected = 2
}
```

---

### 2.2 命名规范

为了避免与现有 Swift API 冲突，Objective-C 兼容版本采用前缀：

| Swift 类型 | Objective-C 类型 | 前缀规则 |
|-----------|-----------------|---------|
| `StepData` | `WPStepData` | 添加 `WP` 前缀 |
| `HealthDataStorageProtocol` | `WPHealthDataStorageProtocol` | 添加 `WP` 前缀 |
| `XGZTDeviceManager` | 保持不变（已有前缀） | - |

---

### 2.3 模块配置

#### 修改 WatchProtocolSDK.podspec
```ruby
Pod::Spec.new do |s|
  s.name             = 'WatchProtocolSDK'
  s.version          = '1.1.0'  # 升级版本号
  s.summary          = 'A Swift SDK with Objective-C compatibility'

  s.ios.deployment_target = '13.0'
  s.swift_version = '5.0'

  s.source_files = 'WatchProtocolSDK/**/*.swift'

  # 添加模块映射，支持 Objective-C 导入
  s.module_map = 'WatchProtocolSDK/WatchProtocolSDK.modulemap'

  s.frameworks = 'Foundation', 'CoreBluetooth'
  s.dependency 'SwiftyJSON'
  s.dependency 'CryptoSwift'
end
```

#### 创建 modulemap（可选，增强兼容性）
```
// WatchProtocolSDK.modulemap
framework module WatchProtocolSDK {
    umbrella header "WatchProtocolSDK-Swift.h"
    export *
    module * { export * }
}
```

---

## 3. Objective-C 使用示例

### 3.1 导入 SDK
```objc
// AppDelegate.m 或其他 .m 文件
@import WatchProtocolSDK;  // 方式 1：模块导入（推荐）
// 或
#import <WatchProtocolSDK/WatchProtocolSDK-Swift.h>  // 方式 2：传统导入
```

### 3.2 实现数据存储协议
```objc
// MyHealthDataStorage.h
#import <Foundation/Foundation.h>
@import WatchProtocolSDK;

@interface MyHealthDataStorage : NSObject <WPHealthDataStorageProtocol>
@end

// MyHealthDataStorage.m
@implementation MyHealthDataStorage

- (void)saveStepData:(WPStepData *)data {
    NSLog(@"Saving step data: %d steps on %@", data.step, data.date);
    // 保存到数据库
}

- (void)saveSleepData:(WPSleepData *)data {
    NSLog(@"Saving sleep data: deep=%d, light=%d", data.deep, data.light);
}

// ... 实现其他方法
@end
```

### 3.3 初始化 SDK
```objc
// AppDelegate.m
- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // 1. 创建数据存储实例
    MyHealthDataStorage *storage = [[MyHealthDataStorage alloc] init];

    // 2. 初始化设备管理器
    [[XGZTDeviceManager shared] initializeWithStorage:storage];

    // 3. 开始扫描设备
    [[XGZTBlueToothManager shared] startScan];

    return YES;
}
```

### 3.4 监听蓝牙事件
```objc
// 注册通知
[[NSNotificationCenter defaultCenter] addObserver:self
    selector:@selector(deviceConnected:)
    name:@"XGZTDeviceConnectedNotification"  // 需要在 Swift 中定义
    object:nil];

- (void)deviceConnected:(NSNotification *)notification {
    NSLog(@"Device connected successfully");
}
```

---

## 4. 改造工作量评估

| 模块 | 工作内容 | 预计工时 |
|-----|---------|---------|
| 数据模型 | 5个 struct 改为 class | 2 小时 |
| 协议 | 添加 @objc 标记 | 1 小时 |
| 管理类 | 添加 @objc 标记和包装方法 | 4 小时 |
| 枚举/常量 | 改造为 ObjC 兼容格式 | 2 小时 |
| 文档 | 编写 Objective-C 接入文档 | 4 小时 |
| 测试 | 创建 ObjC Demo 项目测试 | 4 小时 |
| **总计** | - | **约 17 小时（2-3 天）** |

---

## 5. 版本发布计划

### 5.1 版本号
- **当前版本**: v1.0.2（纯 Swift）
- **兼容版本**: v1.1.0（Swift + Objective-C 兼容层）

### 5.2 更新日志示例
```markdown
## v1.1.0 (2026-01-XX)

### ✨ New Features
- 🎉 新增 Objective-C 兼容性支持
- 🎉 所有核心 API 现在可以从 Objective-C 项目调用

### 🔄 Breaking Changes
- 数据模型从 `struct` 改为 `class`（Swift 用户仍可正常使用）
- 协议名称添加 `WP` 前缀以区分版本

### 📚 Documentation
- 新增 Objective-C 接入文档
- 新增 Objective-C 示例项目
```

---

## 6. 兼容性保证

### 6.1 向后兼容
- Swift 用户可以继续使用新版本（API 保持不变）
- 旧的 Swift API 保留，新增 ObjC 兼容 API

### 6.2 最佳实践
```swift
// 同时提供两套 API

// Swift 友好 API（保留）
public struct StepData { ... }

// Objective-C 友好 API（新增）
@objc public class WPStepData: NSObject { ... }

// 转换方法
extension WPStepData {
    convenience init(from stepData: StepData) {
        self.init(date: stepData.date, mac: stepData.mac, step: stepData.step)
    }
}
```

---

## 7. 参考资料

- [Using Swift with Objective-C - Apple Official Guide](https://developer.apple.com/documentation/swift/using-swift-with-objective-c)
- [Importing Swift into Objective-C](https://developer.apple.com/documentation/swift/imported_c_and_objective-c_apis/importing_swift_into_objective-c)
- [Creating an Objective-C Bridging Header](https://developer.apple.com/documentation/swift/imported_c_and_objective-c_apis/importing_objective-c_into_swift)

---

## 8. 后续优化方向

1. **性能优化**：确保桥接层不引入性能损失
2. **类型安全**：增强 Objective-C 的类型检查
3. **错误处理**：提供 NSError 版本的错误处理
4. **Block 回调**：为 Objective-C 提供 Block 风格的异步回调

---

## 附录：完整改造 Checklist

- [ ] 改造数据模型（5个 struct → class）
- [ ] 改造协议（添加 @objc）
- [ ] 改造管理类（添加 @objc）
- [ ] 改造枚举（使用 Int rawValue）
- [ ] 更新 podspec 版本号
- [ ] 编写 Objective-C 接入文档
- [ ] 创建 Objective-C Demo 项目
- [ ] 测试所有核心功能
- [ ] 更新 CHANGELOG
- [ ] 发布新版本到 CocoaPods
