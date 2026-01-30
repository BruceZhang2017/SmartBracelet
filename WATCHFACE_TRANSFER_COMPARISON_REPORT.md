# WatchFaceSDK 传输逻辑对比分析报告

## 📋 概述

本报告对比分析 **WatchFaceSDK Swift 版本** 和 **WatchFaceSDK-Pure-ObjC 版本** 在上传 bin 包给设备端的逻辑差异。

**分析日期**: 2026-01-29
**对比文件**:
- Swift: `WatchFaceSDK/WatchFaceSDK/Core/WatchFaceTransferEngine.swift`
- ObjC: `WatchFaceSDK-Pure-ObjC/Core/WFTransferEngine.m`

---

## 🔍 核心流程对比

### Swift 版本流程
```
1. startTransfer()
   ↓
2. 设置时间位置和颜色（自定义表盘）
   ↓
3. queryMTUAndStartTransfer() - 异步查询 MTU
   ↓
4. prepareTransfer() - 使用 PacketManager 计算分包（固定 200 字节）
   ↓
5. configureAndStartTransfer() - 发送配置
   ↓
6. startPacketTransfer() - 开始传输
   ↓
7. sendNextPacket() - 逐包发送（主动延迟 0.03s）
   ↓
8. 完成或错误处理
```

### ObjC 版本流程
```
1. startTransferWithData()
   ↓
2. 设置时间位置和颜色（自定义表盘）
   ↓
3. queryMTUAndStartTransfer() - 直接读取 MTU
   ↓
4. sendTransferConfig() - 发送配置
   ↓
5. beginTransfer() - 开始传输
   ↓
6. sendNextPacket() - 逐包发送
   ↓
7. 等待通知 XGZTCommandDialDataSendCompleteCallback
   ↓
8. 完成或错误处理
```

---

## ⚠️ 关键差异分析

### 1. **分包策略不一致** 🔴 严重问题

| 特性 | Swift 版本 | ObjC 版本 | 状态 |
|------|-----------|----------|------|
| **包大小计算** | `PacketManager.maxPacketSize = 200` 字节（固定） | `mtu - 20` 字节（动态） | ❌ 不一致 |
| **分包总数计算** | `(dataSize % 200 == 0) ? (dataSize / 200) : (dataSize / 200 + 1)` | `(dataSize + packetSize - 1) / packetSize` | ❌ 逻辑不同 |

**问题**:
- Swift 使用固定 200 字节，符合 XGZT 协议规范
- ObjC 动态计算包大小，可能导致协议不兼容

**建议**: ObjC 应改为固定 200 字节

---

### 2. **binNum（字节偏移量）计算错误** 🔴 严重问题

| 版本 | binNum 计算方式 | 正确性 |
|------|----------------|--------|
| **Swift** | `packetIndex * 200` | ✅ 正确 |
| **ObjC** | `0`（固定值） | ❌ **错误** |

**Swift 代码 (WatchFaceTransferEngine.swift:192)**:
```swift
let binNum = packetManager.getByteOffset(for: currentPacketIndex)
// getByteOffset 实现: packetIndex * maxPacketSize (200)
```

**ObjC 代码 (WFTransferEngine.m:220-221)**:
```objc
[WPCommands dialMarketTransferData:self.currentPacketIndex + 1  // 包序号从1开始
                            binNum:0                             // ❌ 固定为 0
                       progressBar:progress
                           control:0
                              data:packetData];
```

**影响**:
- 设备端无法正确定位数据写入位置
- 可能导致数据覆盖或传输失败

**修复方案**:
```objc
// 应该改为:
NSInteger binNum = self.currentPacketIndex * 200;  // 或 self.currentPacketIndex * self.packetSize（如果使用固定200）
```

---

### 3. **control 控制标志未正确使用** 🔴 严重问题

| 版本 | control 值 | 最后一包标记 |
|------|-----------|-------------|
| **Swift** | `isLast ? 1 : 0` | ✅ 正确区分 |
| **ObjC** | `0`（固定值） | ❌ 未区分 |

**Swift 代码 (WatchFaceTransferEngine.swift:194)**:
```swift
let control = isLast ? 1 : 0
```

**ObjC 代码 (WFTransferEngine.m:223)**:
```objc
control:0  // ❌ 所有包都是 0
```

**影响**:
- 设备端无法判断传输是否完成
- 可能导致设备等待超时或无法完成传输

**修复方案**:
```objc
// 判断是否为最后一包
BOOL isLastPacket = (self.currentPacketIndex >= self.totalPackets - 1);
NSInteger control = isLastPacket ? 1 : 0;
```

---

### 4. **传输配置参数硬编码错误** 🔴 严重问题

**Swift 代码 (XGZTDialProtocol.swift:51-60)**:
```swift
XGZTCommand.dialMarketSetTransferConfig(
    packageTotal: config.packageTotal,
    binSize: config.binSize,
    mtu: config.mtu,
    dialType: config.dialType.rawValue,
    dialNum: 1,                              // ✅ 固定为 1
    local: config.timePosition.rawValue,     // ✅ 使用配置的时间位置
    typeValue: 0,                            // ✅ 固定为 0
    dialTypeValue: config.color.rawValue     // ✅ 使用配置的颜色
)
```

**ObjC 代码 (WFTransferEngine.m:172-179)**:
```objc
[WPCommands dialMarketSetTransferConfig:self.totalPackets
                                binSize:self.currentData.length
                                    mtu:mtu
                               dialType:dialType
                                dialNum:0        // ❌ 应该是 1
                                  local:1        // ❌ 应该是 timePosition
                              typeValue:1        // ❌ 应该是 0
                          dialTypeValue:0];      // ❌ 应该是 color
```

**问题列表**:
1. `dialNum`: 应该是 `1`，ObjC 写成了 `0`
2. `local`: 应该传入 `self.timePosition`，ObjC 硬编码为 `1`
3. `typeValue`: 应该是 `0`，ObjC 写成了 `1`
4. `dialTypeValue`: 应该传入 `self.color`，ObjC 硬编码为 `0`

**修复方案**:
```objc
[WPCommands dialMarketSetTransferConfig:self.totalPackets
                                binSize:self.currentData.length
                                    mtu:mtu
                               dialType:dialType
                                dialNum:1                        // ✅ 修复为 1
                                  local:(NSInteger)self.timePosition  // ✅ 使用实际值
                              typeValue:0                        // ✅ 修复为 0
                          dialTypeValue:(NSInteger)self.color];  // ✅ 使用实际值
```

---

### 5. **MTU 查询方式不同** 🟡 中等问题

| 特性 | Swift 版本 | ObjC 版本 |
|------|-----------|----------|
| **查询方式** | 异步调用 `XGZTCommand.dialMarketQuery(dataType: 0)` | 直接读取 `WPBluetoothManager.currentDevice.mtu` |
| **回调机制** | 使用闭包回调 | 无回调，直接使用 |
| **默认值** | 需要等待查询结果 | MTU > 0 ? MTU : 240 |

**Swift 代码 (WatchFaceTransferEngine.swift:110-123)**:
```swift
self.dialProtocol.queryMTU { [weak self] result in
    switch result {
    case .success(let mtu):
        self.prepareTransfer(mtu: mtu, ...)
    case .failure(let error):
        self.handleTransferError(error)
    }
}
```

**ObjC 代码 (WFTransferEngine.m:143-154)**:
```objc
WPBluetoothManager *btManager = [WPBluetoothManager sharedInstance];
WPBluetoothWatchDevice *device = btManager.currentDevice;
NSInteger mtu = (device && device.mtu > 0) ? device.mtu : 240;
```

**影响**:
- ObjC 版本可能使用过期的 MTU 值
- Swift 版本确保使用最新的设备 MTU

**建议**: ObjC 版本应改为异步查询方式

---

### 6. **进度计算方式差异** 🟢 次要问题

| 版本 | 进度计算方式 | 精确度 |
|------|-------------|--------|
| **Swift** | 基于字节数：`(bytesTransferred / totalBytes) * 100` | 更精确 |
| **ObjC** | 基于包数：`((currentPacket + 1) / totalPackets) * 100` | 较粗糙 |

**Swift 代码 (PacketManager.swift:70-73)**:
```swift
public func calculateProgressByBytes(bytesTransferred: Int, totalBytes: Int) -> Float {
    guard totalBytes > 0 else { return 0.0 }
    return min(Float(bytesTransferred) / Float(totalBytes), 1.0)
}
```

**ObjC 代码 (WFTransferEngine.m:214)**:
```objc
NSInteger progress = ((self.currentPacketIndex + 1) * 100) / self.totalPackets;
```

**建议**: ObjC 应改为基于字节数计算，更准确反映实际传输进度

---

### 7. **发送时机策略差异** 🟡 中等问题

| 版本 | 发送策略 | 优点 | 缺点 |
|------|---------|------|------|
| **Swift** | 主动延迟 0.03s 后发送下一包 | 传输速度可控，避免拥塞 | 不等待设备确认 |
| **ObjC** | 被动等待通知后发送 | 确保设备接收完成 | 依赖通知，可能更慢 |

**Swift 代码 (WatchFaceTransferEngine.swift:222-226)**:
```swift
if !isLast {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) { [weak self] in
        self?.sendNextPacket()
    }
}
```

**ObjC 代码 (WFTransferEngine.m:269-272)**:
```objc
- (void)handleDialDataSendComplete:(NSNotification *)notification {
    // 一包数据发送完成，发送下一包
    [self sendNextPacket];
}
```

**分析**:
- Swift 采用主动推送策略，传输更快但可能导致丢包
- ObjC 采用握手确认策略，更可靠但速度较慢

**建议**: 根据实际设备测试结果选择合适策略

---

### 8. **通知监听差异** 🟢 次要问题

| 版本 | 监听的通知 | 数量 |
|------|-----------|------|
| **Swift** | `MyClockViewController`, `ClockUseViewController` | 2 个 |
| **ObjC** | `XGZTCommandDialDataSendCompleteCallback` | 1 个 |

**Swift 代码 (WatchFaceTransferEngine.swift:258-270)**:
```swift
NotificationCenter.default.addObserver(
    self,
    selector: #selector(handleTransferNotification(_:)),
    name: Notification.Name("MyClockViewController"),
    object: nil
)

NotificationCenter.default.addObserver(
    self,
    selector: #selector(handleTransferNotification(_:)),
    name: Notification.Name("ClockUseViewController"),
    object: nil
)
```

**ObjC 代码 (WFTransferEngine.m:51-54)**:
```objc
[[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(handleDialDataSendComplete:)
                                             name:@"XGZTCommandDialDataSendCompleteCallback"
                                           object:nil];
```

**影响**: 可能漏掉某些状态通知

---

## 📊 问题优先级总结

| 优先级 | 问题 | 影响 | 必须修复 |
|-------|------|------|---------|
| 🔴 **P0** | binNum 固定为 0 | 传输失败 | ✅ 是 |
| 🔴 **P0** | control 未标记最后一包 | 传输无法完成 | ✅ 是 |
| 🔴 **P0** | 配置参数硬编码错误 | 功能异常 | ✅ 是 |
| 🔴 **P0** | 分包大小不一致 | 协议不兼容 | ✅ 是 |
| 🟡 **P1** | MTU 查询方式简化 | 可能使用过期值 | ⚠️ 建议修复 |
| 🟡 **P1** | 发送时机策略不同 | 性能差异 | ⚠️ 需测试验证 |
| 🟢 **P2** | 进度计算方式差异 | 显示精度差异 | ⏸ 可选优化 |
| 🟢 **P2** | 通知监听不完整 | 状态感知不全 | ⏸ 可选优化 |

---

## ✅ 修复建议清单

### 必须修复（P0）

#### 1. 修复 binNum 计算
**位置**: `WFTransferEngine.m:220-221`

```objc
// 修复前:
[WPCommands dialMarketTransferData:self.currentPacketIndex + 1
                            binNum:0  // ❌ 错误
                       progressBar:progress
                           control:0
                              data:packetData];

// 修复后:
NSInteger binNum = self.currentPacketIndex * 200;  // 使用固定 200 字节
[WPCommands dialMarketTransferData:self.currentPacketIndex + 1
                            binNum:binNum  // ✅ 正确
                       progressBar:progress
                           control:control  // 同时修复 control
                              data:packetData];
```

---

#### 2. 修复 control 标志
**位置**: `WFTransferEngine.m:196-233`

```objc
- (void)sendNextPacket {
    // ... 现有代码 ...

    // 判断是否为最后一包
    BOOL isLastPacket = (self.currentPacketIndex >= self.totalPackets - 1);
    NSInteger control = isLastPacket ? 1 : 0;

    NSInteger binNum = self.currentPacketIndex * 200;

    [WPCommands dialMarketTransferData:self.currentPacketIndex + 1
                                binNum:binNum
                           progressBar:progress
                               control:control  // ✅ 使用动态值
                                  data:packetData];
}
```

---

#### 3. 修复配置参数
**位置**: `WFTransferEngine.m:168-183`

```objc
// 修复前:
[WPCommands dialMarketSetTransferConfig:self.totalPackets
                                binSize:self.currentData.length
                                    mtu:mtu
                               dialType:dialType
                                dialNum:0        // ❌
                                  local:1        // ❌
                              typeValue:1        // ❌
                          dialTypeValue:0];      // ❌

// 修复后:
[WPCommands dialMarketSetTransferConfig:self.totalPackets
                                binSize:self.currentData.length
                                    mtu:mtu
                               dialType:dialType
                                dialNum:1                            // ✅
                                  local:(NSInteger)self.timePosition // ✅
                              typeValue:0                            // ✅
                          dialTypeValue:(NSInteger)self.color];      // ✅
```

---

#### 4. 统一分包大小为 200 字节
**位置**: `WFTransferEngine.m:143-166`

```objc
// 修复前:
self.packetSize = mtu - 20;  // ❌ 动态计算

// 修复后:
self.packetSize = 200;  // ✅ 固定 200 字节（符合 XGZT 协议）
```

---

### 建议修复（P1）

#### 5. 改进 MTU 查询方式（可选）
```objc
// 添加异步查询方法
- (void)queryMTUWithCompletion:(void(^)(NSInteger mtu, NSError *error))completion {
    // 调用协议层查询
    [WPCommands dialMarketQueryDataType:0];

    // 保存回调，等待通知
    self.mtuQueryCompletion = completion;
}
```

#### 6. 改进进度计算方式
```objc
- (void)updateProgress {
    NSInteger bytesTransferred = self.currentPacketIndex * 200 + packetData.length;
    NSInteger totalBytes = self.currentData.length;

    WFTransferProgress *progress = [[WFTransferProgress alloc] init];
    progress.currentPacket = self.currentPacketIndex + 1;
    progress.totalPackets = self.totalPackets;
    progress.bytesTransferred = bytesTransferred;  // ✅ 使用字节数
    progress.totalBytes = totalBytes;

    // ...
}
```

---

## 🧪 测试验证建议

修复完成后，建议进行以下测试：

1. **小文件传输测试** (< 1KB)
   - 验证单包和多包传输
   - 确认 control 标志正确

2. **大文件传输测试** (> 100KB)
   - 验证 binNum 计算正确
   - 确认进度更新准确

3. **边界条件测试**
   - 文件大小正好是 200 的倍数
   - 文件大小 < 200 字节

4. **自定义表盘测试**
   - 验证时间位置和颜色配置正确传递

5. **错误处理测试**
   - 中途断开连接
   - 设备返回错误

---

## 📝 结论

Objective-C 版本的传输引擎存在 **4 个 P0 级别的严重问题**，这些问题会导致传输功能完全无法正常工作：

1. ❌ **binNum 计算错误** - 导致设备无法定位数据
2. ❌ **control 标志错误** - 导致设备无法判断传输结束
3. ❌ **配置参数错误** - 导致功能异常
4. ❌ **分包大小不一致** - 导致协议不兼容

**建议立即修复所有 P0 问题后再进行功能测试。**

---

## 📎 附录：关键代码位置

### Swift 版本
- 传输引擎: `WatchFaceSDK/WatchFaceSDK/Core/WatchFaceTransferEngine.swift`
- 分包管理: `WatchFaceSDK/WatchFaceSDK/Transfer/PacketManager.swift`
- 协议封装: `WatchFaceSDK/WatchFaceSDK/Transfer/XGZTDialProtocol.swift`

### ObjC 版本
- 传输引擎: `WatchFaceSDK-Pure-ObjC/Core/WFTransferEngine.m`
- 传输引擎头文件: `WatchFaceSDK-Pure-ObjC/Core/WFTransferEngine.h`

---

**报告生成时间**: 2026-01-29
**分析工具**: Claude Code
**报告版本**: v1.0
