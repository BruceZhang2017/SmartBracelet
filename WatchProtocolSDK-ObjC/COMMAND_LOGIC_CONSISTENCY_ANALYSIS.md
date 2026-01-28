# WPBluetoothManager 查找设备与电量查询逻辑一致性分析

## 📊 对比摘要

| 对比项 | 电量查询 (`queryBatteryLevel`) | 查找设备 (`findDeviceWithCompletion`) | 一致性 |
|--------|--------------------------------|---------------------------------------|--------|
| **入口方法位置** | `WPBluetoothManager` | `WPBluetoothManager` | ✅ 一致 |
| **检查连接状态** | ✅ 检查 `isConnected` | ✅ 检查 `isConnected` | ✅ 一致 |
| **检查蓝牙状态** | ❌ 不检查 | ✅ 检查 `isBluetoothPoweredOff` | ❌ **不一致** |
| **发送指令方式** | 通过 `[WPCommands getBatteryLevel]` | 通过 `[WPCommands findBandWithCompletion:]` | ✅ 一致（都委托给 WPCommands） |
| **底层发送实现** | `[WPCommands sendCommand:]` | 直接调用 `[btManager sendData:]` | ❌ **不一致** |
| **获取发送结果** | ❌ 不获取返回值 | ✅ 获取 `BOOL success` 返回值 | ❌ **不一致** |
| **完成回调** | ❌ 无回调 | ✅ 有 completion 回调 | ❌ **不一致** |
| **结果通知方式** | 通过代理方法异步返回 | 通过 completion 同步返回 + 代理异步返回 | ❌ **不一致** |
| **重复请求保护** | ❌ 无保护 | ✅ 检查 `_isFindingDevice` | ❌ **不一致** |
| **状态管理** | ❌ 无状态 | ✅ 维护 `_isFindingDevice` 状态 | ❌ **不一致** |

---

## 📝 详细分析

### 1️⃣ 电量查询逻辑 (`queryBatteryLevel`)

#### WPBluetoothManager 层

```objc
- (void)queryBatteryLevel {
    // 1. 检查连接状态
    if (!self.isConnected) {
        [[WPLogger sharedInstance] log:@"❌ 查询电量失败：设备未连接"];
        return;
    }

    [[WPLogger sharedInstance] log:@"🔋 开始查询设备电量"];

    // 2. 委托给 WPCommands
    [WPCommands getBatteryLevel];

    // 3. 响应通过代理方法异步返回
    // 注意：响应会通过 handleResponse 自动解析并回调 didReceiveBatteryLevel:isCharging:
}
```

#### WPCommands 层

```objc
+ (void)getBatteryLevel {
    // 1. 构建指令
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeGetBatteryLevel),
        @(0x01),
        @(0x00),
        @(0x01),
        @(0x00)
    ]];

    [[WPLogger sharedInstance] log:@"🔋 发送获取电量指令"];

    // 2. 发送指令（不关心返回值）
    [self sendCommand:command];
}

+ (void)sendCommand:(NSData *)commandData {
    // 3. 最终通过 WPBluetoothManager 发送
    [[WPBluetoothManager sharedInstance] sendData:commandData];
}
```

#### 特点

- ✅ 简洁明了
- ✅ 无阻塞
- ❌ 无法知道指令是否发送成功
- ❌ 无回调机制
- ❌ 不检查蓝牙状态
- ❌ 无重复请求保护

---

### 2️⃣ 查找设备逻辑 (`findDeviceWithCompletion`)

#### WPBluetoothManager 层

```objc
- (void)findDeviceWithCompletion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion {
    [[WPLogger sharedInstance] log:@"🔍 [WPBluetoothManager] 开始查找设备"];

    // 委托给 WPCommands+FindDevice 的类方法
    [WPCommands findBandWithCompletion:completion];
}
```

#### WPCommands+FindDevice 层

```objc
+ (void)findBandWithCompletion:(nullable WPFindDeviceCompletion)completion {
    WPBluetoothManager *btManager = [WPBluetoothManager sharedInstance];

    // 1. 检查蓝牙是否开启
    if (btManager.isBluetoothPoweredOff) {
        [[WPLogger sharedInstance] log:@"❌ 查找手环失败: 蓝牙未开启"];
        if (completion) {
            NSError *error = [NSError errorWithDomain:WPFindDeviceErrorDomain
                                               code:WPFindDeviceErrorCodeBluetoothOff
                                           userInfo:@{NSLocalizedDescriptionKey: @"蓝牙未开启，请先打开蓝牙"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
        }
        return;
    }

    // 2. 检查设备连接状态
    if (!btManager.isConnected) {
        [[WPLogger sharedInstance] log:@"❌ 查找手环失败: 设备未连接"];
        if (completion) {
            NSError *error = [NSError errorWithDomain:WPFindDeviceErrorDomain
                                               code:WPFindDeviceErrorCodeDeviceNotConnected
                                           userInfo:@{NSLocalizedDescriptionKey: @"设备未连接，请先连接设备"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
        }
        return;
    }

    // 3. 检查是否已在查找中（重复请求保护）
    if (_isFindingDevice) {
        [[WPLogger sharedInstance] log:@"⚠️ 已在查找中，忽略重复请求"];
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(YES, nil);
            });
        }
        return;
    }

    // 4. 构建查找指令
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeFindBand),
        @(0x01),
        @(0x00),
        @(0x01),
        @(WPFindDeviceActionStart)  // 1 = 开始查找
    ]];

    // 5. 直接发送指令并获取结果
    BOOL success = [btManager sendData:command];

    // 6. 根据发送结果立即回调
    if (success) {
        _isFindingDevice = YES;  // 更新状态
        [[WPLogger sharedInstance] log:@"🔍 查找手环指令已发送"];

        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(YES, nil);
            });
        }
    } else {
        [[WPLogger sharedInstance] log:@"❌ 查找手环指令发送失败"];

        if (completion) {
            NSError *error = [NSError errorWithDomain:WPFindDeviceErrorDomain
                                               code:WPFindDeviceErrorCodeSendFailed
                                           userInfo:@{NSLocalizedDescriptionKey: @"指令发送失败，请重试"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
        }
    }
}
```

#### 特点

- ✅ 完整的状态检查（蓝牙、连接、查找状态）
- ✅ 完成回调机制
- ✅ 立即返回发送结果
- ✅ 重复请求保护
- ✅ 状态管理
- ✅ 详细的错误信息

---

## ⚠️ 主要不一致之处

### 1. **发送指令方式不同**

**电量查询**:
```objc
[WPCommands getBatteryLevel]
    └─> [WPCommands sendCommand:command]
        └─> [[WPBluetoothManager sharedInstance] sendData:commandData]
```

**查找设备**:
```objc
[WPCommands findBandWithCompletion:completion]
    └─> [btManager sendData:command]  // 直接调用，跳过了 sendCommand
```

### 2. **返回值处理不同**

**电量查询**:
```objc
[self sendCommand:command];  // 不获取返回值
```

**查找设备**:
```objc
BOOL success = [btManager sendData:command];  // 获取返回值
if (success) {
    // 处理成功逻辑
} else {
    // 处理失败逻辑
}
```

### 3. **回调机制不同**

**电量查询**:
- ❌ 无完成回调
- 结果通过代理方法 `didReceiveBatteryLevel:isCharging:` 异步返回
- 用户无法立即知道指令是否发送成功

**查找设备**:
- ✅ 有完成回调
- 立即返回发送结果（success/error）
- 用户可以立即知道指令是否发送成功

### 4. **状态检查完整性不同**

**电量查询**:
```objc
if (!self.isConnected) {  // 只检查连接状态
    return;
}
```

**查找设备**:
```objc
if (btManager.isBluetoothPoweredOff) {  // 检查蓝牙状态
    // 返回错误
}

if (!btManager.isConnected) {  // 检查连接状态
    // 返回错误
}

if (_isFindingDevice) {  // 检查重复请求
    // 返回成功（已在查找中）
}
```

---

## 💡 建议

### 🎯 统一逻辑建议

为了保持代码一致性和可维护性，建议对电量查询也采用类似查找设备的逻辑：

#### 方案 1：增强电量查询（推荐）

```objc
// WPBluetoothManager.h
- (void)queryBatteryLevelWithCompletion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion;

// WPBluetoothManager.m
- (void)queryBatteryLevelWithCompletion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion {
    // 1. 检查蓝牙状态
    if (self.isBluetoothPoweredOff) {
        [[WPLogger sharedInstance] log:@"❌ 查询电量失败：蓝牙未开启"];
        if (completion) {
            NSError *error = [NSError errorWithDomain:@"WPBatteryError"
                                               code:1003
                                           userInfo:@{NSLocalizedDescriptionKey: @"蓝牙未开启"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
        }
        return;
    }

    // 2. 检查连接状态
    if (!self.isConnected) {
        [[WPLogger sharedInstance] log:@"❌ 查询电量失败：设备未连接"];
        if (completion) {
            NSError *error = [NSError errorWithDomain:@"WPBatteryError"
                                               code:1001
                                           userInfo:@{NSLocalizedDescriptionKey: @"设备未连接"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
        }
        return;
    }

    // 3. 构建指令
    NSData *command = [WPCommands createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeGetBatteryLevel),
        @(0x01),
        @(0x00),
        @(0x01),
        @(0x00)
    ]];

    // 4. 发送指令并获取结果
    BOOL success = [self sendData:command];

    if (success) {
        [[WPLogger sharedInstance] log:@"🔋 电量查询指令已发送"];
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(YES, nil);
            });
        }
    } else {
        [[WPLogger sharedInstance] log:@"❌ 电量查询指令发送失败"];
        if (completion) {
            NSError *error = [NSError errorWithDomain:@"WPBatteryError"
                                               code:1002
                                           userInfo:@{NSLocalizedDescriptionKey: @"指令发送失败"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
        }
    }

    // 注意：响应仍通过代理方法 didReceiveBatteryLevel:isCharging: 返回
}
```

#### 方案 2：简化查找设备（不推荐）

将查找设备简化为与电量查询一致的逻辑（去掉回调），但这会降低用户体验。

---

## 📊 对比总结

| 逻辑层面 | 电量查询 | 查找设备 | 推荐统一方向 |
|----------|----------|----------|--------------|
| **状态检查** | 简单 | 完善 | ✅ 采用查找设备的完善检查 |
| **回调机制** | 无 | 有 | ✅ 采用查找设备的回调机制 |
| **错误处理** | 简单 | 完善 | ✅ 采用查找设备的完善错误处理 |
| **发送方式** | 通过 sendCommand | 直接 sendData | ✅ 统一为直接 sendData（便于获取返回值） |
| **用户体验** | 一般 | 优秀 | ✅ 采用查找设备的优秀体验 |

---

## ✅ 结论

**查找设备与电量查询在逻辑层面存在明显的不一致性**：

1. **发送指令方式不同**：电量查询通过 `sendCommand`（不获取返回值），查找设备直接调用 `sendData`（获取返回值）
2. **回调机制不同**：电量查询无完成回调，查找设备有完成回调
3. **状态检查不同**：电量查询只检查连接状态，查找设备检查蓝牙状态、连接状态、重复请求
4. **错误处理不同**：电量查询简单，查找设备详细

**建议**：
- ✅ 采用查找设备的逻辑作为标准模板
- ✅ 对电量查询、心率测量等功能进行增强，添加完成回调机制
- ✅ 统一所有指令发送方式为直接调用 `sendData` 并获取返回值
- ✅ 为所有功能添加完善的状态检查和错误处理

这样可以：
- 提升用户体验（立即知道操作是否成功）
- 提高代码一致性和可维护性
- 便于单元测试和 Mock
- 减少用户集成时的困惑
