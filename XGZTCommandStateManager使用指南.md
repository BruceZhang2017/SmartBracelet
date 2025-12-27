# XGZTCommandStateManager 使用指南

> **优化日期**: 2025-12-27
> **优化内容**: 将全局 flag 变量封装为线程安全的指令状态管理器

---

## 📋 优化概述

### 原有问题

```swift
// ❌ 旧代码:全局可变变量,非线程安全
var flag_81 = false
var flag_82 = false
var flag_5d = false
var flag_device_reading = false
var sync_time_single = false

// 问题1: 任何地方都可以直接修改
flag_81 = true
flag_device_reading = false

// 问题2: 多线程访问不安全
DispatchQueue.global().async {
    flag_device_reading = true  // ⚠️ 可能崩溃
}

// 问题3: 缺少日志记录,难以调试
flag_81 = false  // ⚠️ 不知道何时被清除

// 问题4: 难以扩展
// 如果增加新指令,需要新增全局变量
var flag_83 = false  // ⚠️ 扩展性差
```

### 优化方案

```swift
// ✅ 新代码:线程安全的指令状态管理器
class XGZTCommandStateManager {
    static let shared = XGZTCommandStateManager()

    // 线程安全的指令标志管理
    private let commandFlagsLock = NSLock()
    private var _commandFlags: [XGZTCommandType: Bool] = [:]

    // 线程安全的设备读取状态
    private let readingStateLock = NSLock()
    private var _deviceReadingState: DeviceReadingState = .idle

    // 线程安全的时间同步标志
    private let syncTimeLock = NSLock()
    private var _isSyncTimeSingle: Bool = false
}

// 指令类型枚举(易于扩展)
enum XGZTCommandType {
    case bind81          // 绑定设备阶段1
    case bind82          // 绑定设备阶段2
    case setAppInfo5D    // 设置APP信息
    // 新增指令只需添加枚举值即可
}

// 设备读取状态枚举
enum DeviceReadingState {
    case idle       // 空闲状态
    case reading    // 正在读取
    case completed  // 读取完成
}
```

---

## 🚀 快速迁移指南

### 1. 指令响应标志相关

#### 设置指令为待响应状态

```swift
// ❌ 旧代码
func syncDevcieInfo() {
    XGZTCommand.bindDevice(value: 0)
    flag_81 = true

    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
        if !flag_81 {
            return
        }
        XGZTCommand.bindDevice(value: 0)
        connectFailMessage += "[\(mac)]指令故障:嵌入式未回复指令81"
    }
}

// ✅ 新代码(推荐)
func syncDevcieInfo() {
    XGZTCommand.bindDevice(value: 0)
    XGZTCommandStateManager.shared.setCommandPending(.bind81)

    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
        if !XGZTCommandStateManager.shared.isCommandPending(.bind81) {
            return
        }
        XGZTCommand.bindDevice(value: 0)
        XGZTDeviceManager.shared.appendFailMessage("[\(mac)]指令故障:嵌入式未回复指令81")
    }
}

// ✅ 向后兼容(不推荐,已标记为 deprecated)
flag_81 = true  // 仍然可用,但会有警告
```

#### 清除指令标志(收到响应)

```swift
// ❌ 旧代码(在 XGZTCommands.swift 中)
if response[5] == 0x81 {
    flag_81 = false
    // 处理响应数据
}

// ✅ 新代码(推荐)
if response[5] == 0x81 {
    XGZTCommandStateManager.shared.clearCommandFlag(.bind81)
    // 处理响应数据
}

// ✅ 向后兼容
flag_81 = false  // 仍然可用
```

#### 检查指令是否仍在等待

```swift
// ❌ 旧代码
if flag_82 {
    // 仍在等待响应
}

// ✅ 新代码(推荐)
if XGZTCommandStateManager.shared.isCommandPending(.bind82) {
    // 仍在等待响应
}

// ✅ 向后兼容
if flag_82 {  // 仍然可用
    // 仍在等待响应
}
```

### 2. 设备读取流程控制相关

#### 开始读取设备信息

```swift
// ❌ 旧代码
func readDeviceInfo() {
    flag_device_reading = true
    // 开始读取流程...
}

// ✅ 新代码(推荐)
func readDeviceInfo() {
    XGZTCommandStateManager.shared.startDeviceReading()
    // 开始读取流程...
}

// ✅ 向后兼容
flag_device_reading = true  // 仍然可用
```

#### 检查是否正在读取

```swift
// ❌ 旧代码
private func readDeviceInfo2() {
    if !flag_device_reading {
        return
    }
    XGZTCommand.getNewestHealthData(type: 0)
}

// ✅ 新代码(推荐)
private func readDeviceInfo2() {
    if !XGZTCommandStateManager.shared.isDeviceReading {
        return
    }
    XGZTCommand.getNewestHealthData(type: 0)
}

// ✅ 获取详细状态
let state = XGZTCommandStateManager.shared.deviceReadingState
switch state {
case .idle:
    print("空闲状态")
case .reading:
    print("正在读取")
case .completed:
    print("读取完成")
}

// ✅ 向后兼容
if !flag_device_reading {  // 仍然可用
    return
}
```

#### 停止读取流程

```swift
// ❌ 旧代码
private func readDeviceInfo17() {
    flag_device_reading = false
    // 读取完成...
}

// ✅ 新代码(推荐)
private func readDeviceInfo17() {
    XGZTCommandStateManager.shared.stopDeviceReading()
    // 读取完成...
}

// ✅ 向后兼容
flag_device_reading = false  // 仍然可用
```

### 3. 时间同步标志相关

#### 设置单次时间同步

```swift
// ❌ 旧代码(在 XGZTCommands.swift 中)
sync_time_single = true
XGZTCommand.syncTime(timeZone: 12, utc: currentUTC)

// ✅ 新代码(推荐)
XGZTCommandStateManager.shared.isSyncTimeSingle = true
XGZTCommand.syncTime(timeZone: 12, utc: currentUTC)

// ✅ 向后兼容
sync_time_single = true  // 仍然可用
```

#### 检查并清除同步标志

```swift
// ❌ 旧代码
if sync_time_single {
    sync_time_single = false
    // 跳过后续流程
    return
}

// ✅ 新代码(推荐)
if XGZTCommandStateManager.shared.isSyncTimeSingle {
    XGZTCommandStateManager.shared.isSyncTimeSingle = false
    // 跳过后续流程
    return
}

// ✅ 向后兼容
if sync_time_single {  // 仍然可用
    sync_time_single = false
    // 跳过后续流程
    return
}
```

### 4. 设备断开连接清理

```swift
// ❌ 旧代码
func handleDisconnected() {
    isXGZT = false
    flag_device_reading = false
    // 其他清理...
}

// ✅ 新代码(推荐)
func handleDisconnected() {
    isXGZT = false
    XGZTCommandStateManager.shared.handleDisconnected()
    // 其他清理...
}
```

---

## 📝 代码迁移示例

### 示例1: XGZTBusinessHandler.swift - 指令超时重试

```swift
// ❌ 旧代码
public func syncDevcieInfo() {
    XGZTCommand.bindDevice(value: 0)
    flag_81 = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
        if !flag_81 {
            return
        }
        XGZTCommand.bindDevice(value: 0)
        connectFailMessage += "[\(lastestDeviceMac)]指令故障:嵌入式未回复指令81"
    }
}

public func syncDevcieInfo2() {
    XGZTCommand.bindDevice(value: 1)
    flag_82 = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
        if !flag_82 {
            return
        }
        XGZTCommand.bindDevice(value: 1)
        connectFailMessage += "[\(lastestDeviceMac)]指令故障:嵌入式未回复指令82"
    }
}

// ✅ 新代码(推荐)
public func syncDevcieInfo() {
    XGZTCommand.bindDevice(value: 0)
    XGZTCommandStateManager.shared.setCommandPending(.bind81)

    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
        if !XGZTCommandStateManager.shared.isCommandPending(.bind81) {
            return
        }
        XGZTCommand.bindDevice(value: 0)
        XGZTDeviceManager.shared.appendFailMessage("[\(lastestDeviceMac)]指令故障:嵌入式未回复指令81")
    }
}

public func syncDevcieInfo2() {
    XGZTCommand.bindDevice(value: 1)
    XGZTCommandStateManager.shared.setCommandPending(.bind82)

    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
        if !XGZTCommandStateManager.shared.isCommandPending(.bind82) {
            return
        }
        XGZTCommand.bindDevice(value: 1)
        XGZTDeviceManager.shared.appendFailMessage("[\(lastestDeviceMac)]指令故障:嵌入式未回复指令82")
    }
}
```

### 示例2: XGZTCommands.swift - 处理指令响应

```swift
// ❌ 旧代码
func handleBindResponse(_ response: [UInt8]) {
    if response[5] == 0x81 {
        flag_81 = false
        // 继续下一步...
        NotificationCenter.default.post(name: Notification.Name("XGZTBusinessHandler"), object: "17")
    }

    if response[5] == 0x82 {
        flag_82 = false
        // 继续下一步...
        NotificationCenter.default.post(name: Notification.Name("XGZTBusinessHandler"), object: "1")
    }
}

// ✅ 新代码(推荐)
func handleBindResponse(_ response: [UInt8]) {
    if response[5] == 0x81 {
        XGZTCommandStateManager.shared.clearCommandFlag(.bind81)
        // 继续下一步...
        NotificationCenter.default.post(name: Notification.Name("XGZTBusinessHandler"), object: "17")
    }

    if response[5] == 0x82 {
        XGZTCommandStateManager.shared.clearCommandFlag(.bind82)
        // 继续下一步...
        NotificationCenter.default.post(name: Notification.Name("XGZTBusinessHandler"), object: "1")
    }
}
```

### 示例3: XGZTBusinessHandler.swift - 设备读取流程

```swift
// ❌ 旧代码
public func readDeviceInfo() {
    flag_device_reading = true
    // 开始同步时间...
    XGZTCommand.syncTime(timeZone: 12, utc: UInt32(correctedUtc))
}

private func readDeviceInfo2() {
    if !flag_device_reading {
        return
    }
    XGZTCommand.getNewestHealthData(type: 0)
}

private func readDeviceInfo17() {
    flag_device_reading = false
    // 读取完成...
}

// ✅ 新代码(推荐)
public func readDeviceInfo() {
    XGZTCommandStateManager.shared.startDeviceReading()
    // 开始同步时间...
    XGZTCommand.syncTime(timeZone: 12, utc: UInt32(correctedUtc))
}

private func readDeviceInfo2() {
    if !XGZTCommandStateManager.shared.isDeviceReading {
        return
    }
    XGZTCommand.getNewestHealthData(type: 0)
}

private func readDeviceInfo17() {
    XGZTCommandStateManager.shared.stopDeviceReading()
    // 读取完成...
}
```

### 示例4: XGZTCommands.swift - 时间同步

```swift
// ❌ 旧代码
func handleSyncTimeResponse(_ response: [UInt8]) {
    if sync_time_single {
        sync_time_single = false
        return  // 如果是因为时区变化同步时间,则不需要往下走
    }
    // 继续下一步...
    NotificationCenter.default.post(name: Notification.Name("XGZTBusinessHandler"), object: "2")
}

// ✅ 新代码(推荐)
func handleSyncTimeResponse(_ response: [UInt8]) {
    if XGZTCommandStateManager.shared.isSyncTimeSingle {
        XGZTCommandStateManager.shared.isSyncTimeSingle = false
        return  // 如果是因为时区变化同步时间,则不需要往下走
    }
    // 继续下一步...
    NotificationCenter.default.post(name: Notification.Name("XGZTBusinessHandler"), object: "2")
}
```

---

## 🎯 优势对比

| 特性 | 旧方案(全局变量) | 新方案(XGZTCommandStateManager) |
|------|-------------------|------------------------------|
| **线程安全** | ❌ 不安全 | ✅ NSLock 保护 |
| **状态管理** | ❌ 混乱(Bool 标志) | ✅ 枚举状态机 |
| **日志记录** | ❌ 无 | ✅ 带时间戳日志(⏳ ✅ 📖 🔌) |
| **API设计** | ❌ 直接操作变量 | ✅ 封装方法,易用 |
| **扩展性** | ❌ 需新增全局变量 | ✅ 添加枚举值即可 |
| **向后兼容** | N/A | ✅ 完全兼容 |
| **类型安全** | ❌ 任意修改 | ✅ 受控访问 |
| **调试能力** | ❌ 难以追踪 | ✅ 日志完整 |

---

## ⚠️ 注意事项

### 1. 向后兼容性

新的管理器提供了完全的向后兼容:

```swift
// ✅ 旧代码仍然可以运行(但有 deprecated 警告)
flag_81 = true
flag_device_reading = false
sync_time_single = true

// 建议逐步迁移到新 API
XGZTCommandStateManager.shared.setCommandPending(.bind81)
XGZTCommandStateManager.shared.stopDeviceReading()
XGZTCommandStateManager.shared.isSyncTimeSingle = true
```

### 2. 性能影响

- **读取性能**: 轻微开销(NSLock加锁/解锁)
- **写入性能**: 同上
- **日志开销**: 仅在 Debug 模式下输出,Release 可关闭

### 3. 多线程安全

```swift
// ✅ 现在可以安全地在多线程中操作
DispatchQueue.global().async {
    XGZTCommandStateManager.shared.setCommandPending(.bind81)
}

DispatchQueue.global().async {
    XGZTCommandStateManager.shared.clearCommandFlag(.bind81)
}

// 不会崩溃,线程安全
```

### 4. 日志输出

新的管理器会自动记录操作日志:

```
⏳ 指令81(绑定设备-阶段1) 等待响应
✅ 指令81(绑定设备-阶段1) 已收到响应
📖 开始读取设备信息
✅ 设备信息读取完成
🔌 设备断开,清理所有指令状态
🕐 设置单次时间同步标志
✅ 清除单次时间同步标志
🧹 清空所有指令标志
```

---

## 🔧 扩展指南

### 如何添加新的指令类型

```swift
// 1. 在 XGZTCommandStateManager.swift 中添加枚举
public enum XGZTCommandType: String {
    case bind81 = "指令81(绑定设备-阶段1)"
    case bind82 = "指令82(绑定设备-阶段2)"
    case setAppInfo5D = "指令5D(设置APP信息)"
    case newCommand83 = "指令83(新功能)"  // ✅ 新增
}

// 2. 使用新指令
XGZTCommand.sendCommand83()
XGZTCommandStateManager.shared.setCommandPending(.newCommand83)

DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
    if XGZTCommandStateManager.shared.isCommandPending(.newCommand83) {
        // 超时重试
        XGZTCommand.sendCommand83()
        XGZTDeviceManager.shared.appendFailMessage("指令83超时")
    }
}

// 3. 收到响应时清除标志
XGZTCommandStateManager.shared.clearCommandFlag(.newCommand83)
```

---

## 📚 API 参考

### XGZTCommandStateManager

#### 单例

```swift
static let shared: XGZTCommandStateManager
```

#### 指令标志管理

```swift
func setCommandPending(_ command: XGZTCommandType)     // 设置指令为待响应状态
func clearCommandFlag(_ command: XGZTCommandType)      // 清除指令标志
func isCommandPending(_ command: XGZTCommandType) -> Bool  // 检查是否仍在等待
func clearAllCommandFlags()                            // 清除所有指令标志
```

#### 设备读取状态

```swift
var deviceReadingState: DeviceReadingState { get }    // 当前读取状态
var isDeviceReading: Bool { get }                     // 是否正在读取

func startDeviceReading()                             // 开始读取流程
func stopDeviceReading()                              // 停止读取流程
func resetDeviceReadingState()                        // 重置为空闲状态
```

#### 时间同步控制

```swift
var isSyncTimeSingle: Bool { get set }                // 单次时间同步标志
```

#### 断开连接清理

```swift
func handleDisconnected()                             // 清理所有状态
```

### XGZTCommandType 枚举

```swift
enum XGZTCommandType: String {
    case bind81          // 指令81(绑定设备-阶段1)
    case bind82          // 指令82(绑定设备-阶段2)
    case setAppInfo5D    // 指令5D(设置APP信息)
}
```

### DeviceReadingState 枚举

```swift
enum DeviceReadingState {
    case idle       // 空闲状态
    case reading    // 正在读取
    case completed  // 读取完成
}
```

---

## 🎓 最佳实践

### 1. 优先使用新 API

```swift
// ✅ 推荐
XGZTCommandStateManager.shared.setCommandPending(.bind81)

// ⚠️ 不推荐(虽然可用)
flag_81 = true
```

### 2. 使用枚举提高可读性

```swift
// ✅ 好的做法:清晰明了
XGZTCommandStateManager.shared.setCommandPending(.bind81)
XGZTCommandStateManager.shared.setCommandPending(.setAppInfo5D)

// ❌ 不好的做法:难以理解
flag_81 = true
flag_5d = true
```

### 3. 统一错误处理

```swift
// ✅ 推荐:结合两个管理器使用
DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
    if XGZTCommandStateManager.shared.isCommandPending(.bind81) {
        XGZTDeviceManager.shared.appendFailMessage("[\(mac)]指令故障:嵌入式未回复指令81")
    }
}
```

### 4. 断开连接时及时清理

```swift
// ✅ 推荐:使用统一的清理方法
func handleDisconnected() {
    isXGZT = false
    XGZTCommandStateManager.shared.handleDisconnected()  // 清理所有状态
    // 其他清理...
}
```

---

## 🔍 故障排查

### 问题1: 指令一直超时重发

**症状**: 发送指令后,4秒后不断重发

**原因**: 响应处理时未清除标志

**解决方案**:
```swift
// ❌ 错误:忘记清除标志
func handleResponse(_ response: [UInt8]) {
    if response[5] == 0x81 {
        // 处理响应数据...
        // 忘记调用 clearCommandFlag
    }
}

// ✅ 正确:收到响应后立即清除标志
func handleResponse(_ response: [UInt8]) {
    if response[5] == 0x81 {
        XGZTCommandStateManager.shared.clearCommandFlag(.bind81)
        // 处理响应数据...
    }
}
```

### 问题2: 设备读取流程被中断

**症状**: readDeviceInfo2-15 都没有执行

**原因**: 读取状态未正确设置为 reading

**解决方案**:
```swift
// ❌ 错误:忘记调用 startDeviceReading
func readDeviceInfo() {
    // 直接开始同步时间...
    XGZTCommand.syncTime(...)
}

// ✅ 正确:先设置状态
func readDeviceInfo() {
    XGZTCommandStateManager.shared.startDeviceReading()
    XGZTCommand.syncTime(...)
}
```

### 问题3: 断开连接后旧状态残留

**症状**: 重新连接时,旧的指令标志仍然存在

**原因**: 断开连接时未清理状态

**解决方案**:
```swift
// ❌ 错误:未调用清理方法
func handleDisconnected() {
    isXGZT = false
    // 未清理状态...
}

// ✅ 正确:调用统一清理
func handleDisconnected() {
    isXGZT = false
    XGZTCommandStateManager.shared.handleDisconnected()
}
```

---

## 📞 支持与反馈

如有问题或建议,请联系开发团队。

**优化完成时间**: 2025-12-27
**文档版本**: 1.0
