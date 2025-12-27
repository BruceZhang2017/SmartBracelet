# XGZTConnectionStateManager 使用指南

> **优化日期**: 2025-12-27
> **优化内容**: 将全局变量 `isXGZT` 和 `lastestDeviceMac` 封装为线程安全的连接状态管理器

---

## 📋 优化概述

### 原有问题

```swift
// ❌ 旧代码：全局可变变量，非线程安全
var lastestDeviceMac: String = ""  // 最后连接的设备MAC地址
var isXGZT = false                 // 自研手表标识

// 问题1: 任何地方都可以直接修改
lastestDeviceMac = "AA:BB:CC:DD:EE:FF"
isXGZT = true

// 问题2: 多线程访问不安全
DispatchQueue.global().async {
    lastestDeviceMac = device.mac  // ⚠️ 可能崩溃
}

// 问题3: 状态不一致
isXGZT = true
lastestDeviceMac = ""  // ⚠️ 逻辑矛盾：标记为XGZT设备，但没有MAC地址

// 问题4: 与 UserDefaults 同步困难
lastestDeviceMac = newMac
UserDefaults.standard.set(newMac, forKey: "LastestDeviceMac")  // ⚠️ 容易忘记
```

### 优化方案

```swift
// ✅ 新代码：线程安全的连接状态管理器
class XGZTConnectionStateManager {
    static let shared = XGZTConnectionStateManager()

    // 线程安全的设备类型
    private let deviceTypeLock = NSLock()
    private var _currentDeviceType: DeviceType = .none

    // 线程安全的MAC地址（自动持久化到 UserDefaults）
    private let macAddressLock = NSLock()
    private var _lastDeviceMac: String = ""
}

// 设备类型枚举
enum DeviceType {
    case none          // 未连接设备
    case standard      // 标准设备（TJD SDK）
    case xgzt          // 自研设备（XGZT协议）
}
```

---

## 🚀 快速迁移指南

### 1. 设备类型相关

#### 检查是否为XGZT设备

```swift
// ❌ 旧代码
if isXGZT {
    // 执行XGZT专属逻辑
}

// ✅ 新代码（推荐）
if XGZTConnectionStateManager.shared.isXGZTDevice {
    // 执行XGZT专属逻辑
}

// ✅ 向后兼容（不推荐，已标记为 deprecated）
if isXGZT {  // 仍然可用，但会有警告
    // 执行XGZT专属逻辑
}
```

#### 设置设备类型

```swift
// ❌ 旧代码
func handleConnected() {
    isXGZT = true
    // 其他逻辑...
}

func handleDisconnected() {
    isXGZT = false
    // 其他逻辑...
}

// ✅ 新代码（推荐）
func handleConnected() {
    XGZTConnectionStateManager.shared.setDeviceType(.xgzt)
    // 或者使用便捷方法：
    // XGZTConnectionStateManager.shared.markXGZTConnected(mac: "AA:BB:CC:DD:EE:FF")
    // 其他逻辑...
}

func handleDisconnected() {
    XGZTConnectionStateManager.shared.markDisconnected(clearMac: false)
    // 其他逻辑...
}

// ✅ 向后兼容
isXGZT = true   // 仍然可用
isXGZT = false  // 仍然可用
```

#### 检查其他设备类型

```swift
// ✅ 新代码：更丰富的设备类型检查
if XGZTConnectionStateManager.shared.isStandardDevice {
    // 标准设备逻辑
}

if XGZTConnectionStateManager.shared.isDeviceConnected {
    // 有设备连接（不管是XGZT还是标准设备）
}

// 获取详细类型
let type = XGZTConnectionStateManager.shared.currentDeviceType
switch type {
case .none:
    print("未连接设备")
case .standard:
    print("标准设备")
case .xgzt:
    print("自研设备")
}
```

### 2. 设备MAC地址相关

#### 读取MAC地址

```swift
// ❌ 旧代码
let mac = lastestDeviceMac
if lastestDeviceMac.isEmpty {
    // 没有设备
}

// 或从 UserDefaults 读取
let mac = UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? ""

// ✅ 新代码（推荐）
let mac = XGZTConnectionStateManager.shared.lastDeviceMac
if mac.isEmpty {
    // 没有设备
}

// ✅ 向后兼容
let mac = lastestDeviceMac  // 仍然可用
```

#### 设置MAC地址

```swift
// ❌ 旧代码（需要手动同步到 UserDefaults）
lastestDeviceMac = device.mac
UserDefaults.standard.set(device.mac, forKey: "LastestDeviceMac")
UserDefaults.standard.synchronize()

// ✅ 新代码（推荐，自动持久化）
XGZTConnectionStateManager.shared.lastDeviceMac = device.mac

// ✅ 向后兼容（也会自动持久化）
lastestDeviceMac = device.mac  // 仍然可用
```

#### 清除MAC地址

```swift
// ❌ 旧代码
lastestDeviceMac = ""
UserDefaults.standard.set("", forKey: "LastestDeviceMac")

// ✅ 新代码（推荐）
XGZTConnectionStateManager.shared.clearLastDeviceMac()

// ✅ 向后兼容
lastestDeviceMac = ""  // 仍然可用
```

### 3. 连接状态管理

#### 设备连接时

```swift
// ❌ 旧代码
func onDeviceConnected(mac: String, isXGZT: Bool) {
    lastestDeviceMac = mac
    UserDefaults.standard.set(mac, forKey: "LastestDeviceMac")
    isXGZT = isXGZT
}

// ✅ 新代码（推荐）
func onDeviceConnected(mac: String, isXGZT: Bool) {
    if isXGZT {
        XGZTConnectionStateManager.shared.markXGZTConnected(mac: mac)
    } else {
        XGZTConnectionStateManager.shared.markStandardConnected(mac: mac)
    }
}
```

#### 设备断开时

```swift
// ❌ 旧代码
func onDeviceDisconnected(clearMac: Bool) {
    isXGZT = false
    if clearMac {
        lastestDeviceMac = ""
        UserDefaults.standard.set("", forKey: "LastestDeviceMac")
    }
}

// ✅ 新代码（推荐）
func onDeviceDisconnected(clearMac: Bool) {
    XGZTConnectionStateManager.shared.markDisconnected(clearMac: clearMac)
}
```

### 4. 便捷方法

#### 检查是否为当前设备

```swift
// ❌ 旧代码（需要手动比较）
let mac = "AA:BB:CC:DD:EE:FF"
if lastestDeviceMac == mac && !lastestDeviceMac.isEmpty {
    // 是当前设备
}

// ✅ 新代码（推荐）
let mac = "AA:BB:CC:DD:EE:FF"
if XGZTConnectionStateManager.shared.isCurrentDevice(mac: mac) {
    // 是当前设备
}
```

#### 打印调试信息

```swift
// ❌ 旧代码
print("isXGZT: \(isXGZT), MAC: \(lastestDeviceMac)")

// ✅ 新代码（推荐）
XGZTConnectionStateManager.shared.printStatus()
// 输出: 设备状态: 自研设备(XGZT), MAC: AA:BB:CC:DD:EE:FF

// 或获取状态描述
let status = XGZTConnectionStateManager.shared.statusDescription
print(status)
```

---

## 📝 代码迁移示例

### 示例1: MTabBarController.swift - 应用启动时加载MAC

```swift
// ❌ 旧代码
private func setupLastestDeviceMac() {
    lastestDeviceMac = UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? ""
    XLogger.shared.log("最后连接的设备MAC地址为：\(lastestDeviceMac)")
    if !lastestDeviceMac.isEmpty {
        perform(#selector(checkIfNeedScanDevice), with: nil, afterDelay: 1)
    }
}

// ✅ 新代码（推荐）
private func setupLastestDeviceMac() {
    // XGZTConnectionStateManager 已在初始化时自动加载MAC地址
    let mac = XGZTConnectionStateManager.shared.lastDeviceMac
    XLogger.shared.log("最后连接的设备MAC地址为：\(mac)")
    if !mac.isEmpty {
        perform(#selector(checkIfNeedScanDevice), with: nil, afterDelay: 1)
    }
}
```

### 示例2: XGZTBusinessHandler.swift - 连接和断开

```swift
// ❌ 旧代码
func handleConnected() {
    isXGZT = true
    // 通知各模块...
}

func handleDisconnected() {
    isXGZT = false
    // 通知各模块...
}

// ✅ 新代码（推荐）
func handleConnected() {
    XGZTConnectionStateManager.shared.setDeviceType(.xgzt)
    // 通知各模块...
}

func handleDisconnected() {
    XGZTConnectionStateManager.shared.markDisconnected(clearMac: false)
    // 通知各模块...
}
```

### 示例3: BLEManager.swift - 标准设备连接

```swift
// ❌ 旧代码
func onDeviceConnected() {
    lastestDeviceMac = bleModel.mac
    UserDefaults.standard.set(bleModel.mac, forKey: "LastestDeviceMac")
    isXGZT = false
}

// ✅ 新代码（推荐）
func onDeviceConnected() {
    XGZTConnectionStateManager.shared.markStandardConnected(mac: bleModel.mac)
}
```

### 示例4: XGZTBlueToothManager.swift - XGZT设备连接

```swift
// ❌ 旧代码
func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    lastestDeviceMac = peripheral.macAddress
    UserDefaults.standard.set(peripheral.macAddress, forKey: "LastestDeviceMac")
    // isXGZT 由 BusinessHandler 设置
}

// ✅ 新代码（推荐）
func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    XGZTConnectionStateManager.shared.markXGZTConnected(mac: peripheral.macAddress)
}
```

### 示例5: DevicesViewController.swift - 检查设备类型

```swift
// ❌ 旧代码
func checkDeviceType() {
    if isXGZT {
        // XGZT设备特殊处理
        if lastestDeviceMac == someDevice.mac {
            // 是当前设备
        }
    } else {
        // 标准设备处理
    }
}

// ✅ 新代码（推荐）
func checkDeviceType() {
    if XGZTConnectionStateManager.shared.isXGZTDevice {
        // XGZT设备特殊处理
        if XGZTConnectionStateManager.shared.isCurrentDevice(mac: someDevice.mac) {
            // 是当前设备
        }
    } else if XGZTConnectionStateManager.shared.isStandardDevice {
        // 标准设备处理
    }
}
```

### 示例6: HealthViewController.swift - 读取MAC地址

```swift
// ❌ 旧代码（多处重复从 UserDefaults 读取）
let lastestDeviceMac = UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? ""
if !lastestDeviceMac.isEmpty {
    // 使用MAC地址...
}

// ✅ 新代码（推荐，统一管理）
let mac = XGZTConnectionStateManager.shared.lastDeviceMac
if !mac.isEmpty {
    // 使用MAC地址...
}
```

---

## 🎯 优势对比

| 特性 | 旧方案（全局变量） | 新方案（XGZTConnectionStateManager） |
|------|-------------------|-------------------------------------|
| **线程安全** | ❌ 不安全 | ✅ NSLock 保护 |
| **持久化** | ❌ 手动同步 UserDefaults | ✅ 自动持久化 |
| **状态一致性** | ❌ 容易不一致 | ✅ 统一管理 |
| **设备类型** | ❌ 仅区分XGZT/非XGZT | ✅ 三种类型（none/standard/xgzt） |
| **日志记录** | ❌ 无 | ✅ 完整日志(🔌 📱 ⌚️ 💾) |
| **API设计** | ❌ 直接操作变量 | ✅ 封装方法，易用 |
| **向后兼容** | N/A | ✅ 完全兼容 |
| **调试能力** | ❌ 难以追踪 | ✅ 状态描述丰富 |

---

## ⚠️ 注意事项

### 1. 向后兼容性

新的管理器提供了完全的向后兼容：

```swift
// ✅ 旧代码仍然可以运行（但有 deprecated 警告）
isXGZT = true
lastestDeviceMac = "AA:BB:CC:DD:EE:FF"
if isXGZT && !lastestDeviceMac.isEmpty {
    // 仍然可以工作
}

// 建议逐步迁移到新 API
XGZTConnectionStateManager.shared.setDeviceType(.xgzt)
XGZTConnectionStateManager.shared.lastDeviceMac = "AA:BB:CC:DD:EE:FF"
if XGZTConnectionStateManager.shared.isXGZTDevice {
    // 新的写法
}
```

### 2. 自动持久化

```swift
// ✅ 设置MAC地址时自动持久化到 UserDefaults
XGZTConnectionStateManager.shared.lastDeviceMac = "AA:BB:CC:DD:EE:FF"
// 无需手动调用 UserDefaults.standard.set(...)

// ✅ 应用重启后自动加载
// XGZTConnectionStateManager.shared 初始化时会自动从 UserDefaults 加载
```

### 3. 性能影响

- **读取性能**: 轻微开销（NSLock加锁/解锁）
- **写入性能**: 同上，加上 UserDefaults 写入
- **内存占用**: 单例模式，常驻内存

### 4. 多线程安全

```swift
// ✅ 现在可以安全地在多线程中操作
DispatchQueue.global().async {
    XGZTConnectionStateManager.shared.lastDeviceMac = "AA:BB:CC:DD:EE:FF"
}

DispatchQueue.global().async {
    let mac = XGZTConnectionStateManager.shared.lastDeviceMac
    print(mac)
}

// 不会崩溃，线程安全
```

### 5. 日志输出

新的管理器会自动记录操作日志：

```
📖 加载设备MAC: AA:BB:CC:DD:EE:FF
⌚️ 已连接自研设备(XGZT)
💾 保存设备MAC: AA:BB:CC:DD:EE:FF
✅ XGZT设备已连接: AA:BB:CC:DD:EE:FF
🔌 设备已断开
🗑️ 清除最后连接的设备MAC
📱 已连接标准设备
```

---

## 🔧 最佳实践

### 1. 优先使用便捷方法

```swift
// ✅ 推荐：使用便捷方法
XGZTConnectionStateManager.shared.markXGZTConnected(mac: "AA:BB:CC:DD:EE:FF")

// ⚠️ 不推荐：分别设置
XGZTConnectionStateManager.shared.setDeviceType(.xgzt)
XGZTConnectionStateManager.shared.lastDeviceMac = "AA:BB:CC:DD:EE:FF"

// ❌ 不推荐：使用旧API
isXGZT = true
lastestDeviceMac = "AA:BB:CC:DD:EE:FF"
```

### 2. 断开连接时保留MAC

```swift
// ✅ 推荐：保留MAC以便重连
XGZTConnectionStateManager.shared.markDisconnected(clearMac: false)

// ⚠️ 仅在删除设备时清除MAC
XGZTConnectionStateManager.shared.markDisconnected(clearMac: true)
```

### 3. 使用类型检查而非布尔值

```swift
// ✅ 好的做法：使用具体类型
let type = XGZTConnectionStateManager.shared.currentDeviceType
switch type {
case .xgzt:
    // XGZT设备逻辑
case .standard:
    // 标准设备逻辑
case .none:
    // 未连接逻辑
}

// ❌ 不好的做法：使用布尔值
if XGZTConnectionStateManager.shared.isXGZTDevice {
    // XGZT设备逻辑
} else {
    // 可能是标准设备，也可能是未连接
}
```

### 4. 及时更新连接状态

```swift
// ✅ 推荐：连接时立即更新
func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    XGZTConnectionStateManager.shared.markXGZTConnected(mac: peripheral.macAddress)
    // 其他逻辑...
}

// ✅ 推荐：断开时立即更新
func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral) {
    XGZTConnectionStateManager.shared.markDisconnected(clearMac: false)
    // 其他逻辑...
}
```

---

## 📚 API 参考

### XGZTConnectionStateManager

#### 单例

```swift
static let shared: XGZTConnectionStateManager
```

#### 设备类型属性

```swift
var currentDeviceType: DeviceType { get }      // 当前设备类型
var isXGZTDevice: Bool { get }                 // 是否为自研设备
var isStandardDevice: Bool { get }             // 是否为标准设备
var isDeviceConnected: Bool { get }            // 是否已连接设备
```

#### 设备类型方法

```swift
func setDeviceType(_ type: DeviceType)         // 设置设备类型
```

#### MAC地址属性

```swift
var lastDeviceMac: String { get set }          // 最后连接的设备MAC（自动持久化）
```

#### MAC地址方法

```swift
func clearLastDeviceMac()                      // 清除MAC地址
```

#### 连接状态方法

```swift
func markXGZTConnected(mac: String)            // 标记XGZT设备已连接
func markStandardConnected(mac: String)        // 标记标准设备已连接
func markDisconnected(clearMac: Bool)          // 标记设备已断开
```

#### 便捷方法

```swift
func isCurrentDevice(mac: String) -> Bool      // 检查是否为当前设备
var statusDescription: String { get }          // 获取状态描述
func printStatus()                             // 打印状态（调试用）
```

### DeviceType 枚举

```swift
enum DeviceType {
    case none          // 未连接设备
    case standard      // 标准设备（TJD SDK）
    case xgzt          // 自研设备（XGZT协议）
}
```

---

## 🔍 故障排查

### 问题1: MAC地址未保存到 UserDefaults

**症状**: 应用重启后 MAC 地址丢失

**原因**: 可能使用了旧的直接赋值方式，未触发持久化

**解决方案**:
```swift
// ❌ 错误：直接修改（旧代码）
lastestDeviceMac = newMac
// 忘记调用 UserDefaults.standard.set(...)

// ✅ 正确：使用管理器（自动持久化）
XGZTConnectionStateManager.shared.lastDeviceMac = newMac
```

### 问题2: 设备类型判断错误

**症状**: `isXGZT` 返回 true，但实际是标准设备

**原因**: 断开连接时未正确更新状态

**解决方案**:
```swift
// ❌ 错误：只清除 isXGZT
isXGZT = false
// 如果 lastDeviceMac 不为空，向后兼容层会认为是标准设备

// ✅ 正确：使用统一的断开方法
XGZTConnectionStateManager.shared.markDisconnected(clearMac: false)
```

### 问题3: 多线程访问崩溃

**症状**: 偶发性崩溃，EXC_BAD_ACCESS

**原因**: 使用旧的全局变量在多线程中访问

**解决方案**:
```swift
// ❌ 危险：旧代码多线程不安全
DispatchQueue.global().async {
    lastestDeviceMac = newMac  // ⚠️ 可能崩溃
}

// ✅ 安全：新代码线程安全
DispatchQueue.global().async {
    XGZTConnectionStateManager.shared.lastDeviceMac = newMac
}
```

---

## 📞 支持与反馈

如有问题或建议，请联系开发团队。

**优化完成时间**: 2025-12-27
**文档版本**: 1.0
