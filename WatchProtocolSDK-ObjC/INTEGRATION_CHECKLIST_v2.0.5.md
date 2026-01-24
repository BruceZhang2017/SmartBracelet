# WatchProtocolSDK-ObjC v2.0.5 集成验证清单

## 📋 安装验证

### ✅ 步骤 1：Framework 集成

- [ ] 已删除旧版本的 `WatchProtocolSDK.xcframework`
- [ ] 已将 v2.0.5 的 `WatchProtocolSDK.xcframework` 拖入项目
- [ ] Target → General → Frameworks, Libraries, and Embedded Content 中可以看到 WatchProtocolSDK.xcframework
- [ ] Embed 设置为 **"Embed & Sign"**（非常重要）

### ✅ 步骤 2：编译验证

- [ ] 清理项目：Product → Clean Build Folder (⇧⌘K)
- [ ] 编译成功：Product → Build (⌘B)
- [ ] 无链接错误
- [ ] 无符号找不到的错误

### ✅ 步骤 3：导入验证

```objc
#import <WatchProtocolSDK/WatchProtocolSDK.h>

// 如果导入成功，说明集成正确
```

---

## 🧪 功能验证

### ✅ 场景 1：首次连接设备（UUID 自动保存）

**测试代码**：
```objc
- (void)testFirstConnection {
    WPBluetoothManager *manager = [WPBluetoothManager sharedInstance];
    manager.delegate = self;
    [manager initCentral];

    // 扫描并连接设备
    [manager connectAndScanWithMac:@"AA:BB:CC:DD:EE:FF"
                        deviceName:@"智能手环"
                           timeout:10.0];
}

- (void)didConnectPeripheral:(WPPeripheralInfo *)peripheralInfo {
    NSLog(@"✅ 首次连接成功");

    // 🆕 v2.0.5: 检查 UUID 是否自动保存
    WPBluetoothManager *manager = [WPBluetoothManager sharedInstance];
    NSString *savedUUID = manager.currentDevice.peripheralUUID;

    if (savedUUID && savedUUID.length > 0) {
        NSLog(@"✅✅✅ UUID 已自动保存: %@", savedUUID);
    } else {
        NSLog(@"❌ UUID 未保存（集成失败）");
    }
}
```

**验证清单**：
- [ ] 扫描到设备
- [ ] 连接成功后触发 `didConnectPeripheral:`
- [ ] **`currentDevice.peripheralUUID` 不为 `nil`**（v2.0.5 新功能）
- [ ] Console 中看到 `💾 已保存设备 UUID` 日志
- [ ] Console 中看到 `💾 保存设备信息（含UUID）` 日志

---

### ✅ 场景 2：App 重启后快速重连（核心功能验证）

**测试步骤**：
1. 首次连接设备（确保连接成功）
2. 完全杀掉 App（⌘Q 或从后台滑掉）
3. 重新启动 App
4. 调用重连方法
5. **观察重连速度**（应该在 1 秒内完成）

**测试代码**：
```objc
- (void)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    WPBluetoothManager *manager = [WPBluetoothManager sharedInstance];
    manager.delegate = self;
    [manager initCentral];

    // 🚀 v2.0.5: 从沙盒恢复设备并自动重连
    // SDK 会自动使用 UUID 快速重连（如果之前保存了 UUID）
    BOOL success = [manager reconnectFromSandboxWithMac:@"AA:BB:CC:DD:EE:FF"];

    if (success) {
        NSLog(@"✅ 启动自动重连");
    } else {
        NSLog(@"⚠️ 沙盒中未找到设备信息");
    }

    return YES;
}

- (void)didConnectPeripheral:(WPPeripheralInfo *)peripheralInfo {
    // 🎯 v2.0.5 核心验证：快速重连
    NSLog(@"✅✅✅ 快速重连成功！");
    NSLog(@"设备名称: %@", peripheralInfo.peripheral.name);
    NSLog(@"MAC 地址: %@", peripheralInfo.macAddress);

    // 检查是否使用了 UUID 重连
    NSString *uuid = [WPBluetoothManager sharedInstance].currentDevice.peripheralUUID;
    if (uuid) {
        NSLog(@"🚀 使用了 UUID 快速重连: %@", uuid);
    }
}
```

**验证清单**：
- [ ] App 重启后自动开始重连
- [ ] **Console 中看到 `🚀 检测到 UUID，使用快速重连`**（证明使用了快速路径）
- [ ] **Console 中看到 `✅ 找到设备（UUID匹配）`**
- [ ] **Console 中看到 `🔗 开始直接连接...`**（无扫描日志）
- [ ] **重连速度很快（<1 秒）**（v2.0.5 核心改进）
- [ ] 重连成功后触发 `didConnectPeripheral:`

---

### ✅ 场景 3：UUID 不可用时的降级测试

**测试步骤**：
1. 首次连接设备
2. 手动清除设备的 UUID（模拟 UUID 丢失）
3. 重启 App 并重连
4. 验证自动降级到 MAC 扫描

**测试代码**：
```objc
- (void)testFallbackToMacScan {
    // 模拟 UUID 不可用的情况
    WPBluetoothWatchDevice *device =
        [WPBluetoothWatchDevice loadFromSandboxWithMac:@"AA:BB:CC:DD:EE:FF"];

    // 清空 UUID（模拟丢失）
    device.peripheralUUID = nil;

    // 尝试重连
    WPBluetoothManager *manager = [WPBluetoothManager sharedInstance];
    manager.delegate = self;
    [manager reconnectWithDevice:device];

    NSLog(@"⚠️ UUID 不可用，应该自动降级到 MAC 扫描");
}

- (void)didConnectPeripheral:(WPPeripheralInfo *)peripheralInfo {
    NSLog(@"✅ 降级重连成功（使用 MAC 扫描）");
}
```

**验证清单**：
- [ ] Console 中看到 `⚠️ UUID 不可用，降级为扫描重连`
- [ ] 开始扫描设备
- [ ] 重连成功（证明降级机制正常工作）

---

### ✅ 场景 4：直接使用 UUID 重连（高级用法）

**测试代码**：
```objc
- (void)testDirectUUIDReconnect {
    // 获取已保存的设备
    WPBluetoothWatchDevice *device =
        [WPBluetoothWatchDevice loadFromSandboxWithMac:@"AA:BB:CC:DD:EE:FF"];

    if (device.peripheralUUID) {
        WPBluetoothManager *manager = [WPBluetoothManager sharedInstance];
        manager.delegate = self;

        // 🆕 v2.0.5: 直接使用 UUID 重连（最快的方式）
        [manager reconnectWithUUID:device.peripheralUUID];

        NSLog(@"🚀 使用 UUID 直接重连: %@", device.peripheralUUID);
    }
}

- (void)didConnectPeripheral:(WPPeripheralInfo *)peripheralInfo {
    NSLog(@"✅ UUID 直接重连成功！");
}
```

**验证清单**：
- [ ] 调用 `reconnectWithUUID:` 方法成功
- [ ] 重连速度很快（<1 秒）
- [ ] 连接成功回调正常触发

---

### ✅ 场景 5：检查沙盒数据格式升级

**测试代码**：
```objc
- (void)testSandboxDataFormat {
    // 保存设备
    WPBluetoothWatchDevice *device = [[WPBluetoothWatchDevice alloc] init];
    device.deviceName = @"测试设备";
    device.mac = @"AA:BB:CC:DD:EE:FF";
    device.peripheralUUID = @"12345678-1234-1234-1234-123456789ABC";

    [WPBluetoothWatchDevice saveToSandbox:device];

    // 读取并验证
    WPBluetoothWatchDevice *loaded =
        [WPBluetoothWatchDevice loadFromSandboxWithMac:@"AA:BB:CC:DD:EE:FF"];

    NSLog(@"设备名称: %@", loaded.deviceName);
    NSLog(@"MAC 地址: %@", loaded.mac);
    NSLog(@"UUID: %@", loaded.peripheralUUID);

    // 验证
    if ([loaded.deviceName isEqualToString:device.deviceName] &&
        [loaded.mac isEqualToString:device.mac] &&
        [loaded.peripheralUUID isEqualToString:device.peripheralUUID]) {
        NSLog(@"✅✅✅ 沙盒数据格式正确");
    } else {
        NSLog(@"❌ 沙盒数据格式错误");
    }
}
```

**验证清单**：
- [ ] 保存设备后，UUID 被正确保存
- [ ] 加载设备后，UUID 被正确恢复
- [ ] Console 中看到 `💾 保存设备信息（含UUID）` 日志
- [ ] Console 中看到 `📱 加载设备信息（含UUID）` 日志

---

### ✅ 场景 6：兼容性测试（旧版本数据升级）

**测试步骤**：
1. 模拟旧版本数据（只有设备名，没有 UUID）
2. 升级到 v2.0.5 后加载数据
3. 验证数据正确加载
4. 首次连接后自动补充 UUID

**验证清单**：
- [ ] 能正确加载旧版本数据（字符串格式）
- [ ] Console 中看到 `📱 加载设备信息（旧格式）` 日志
- [ ] 首次连接后自动保存 UUID
- [ ] 数据格式自动升级为字典格式

---

### ✅ 场景 7：检查日志输出（完整流程）

**期望的完整日志**：

#### 首次连接时
```
🔍 开始扫描目标设备: 智能手环 (AA:BB:CC:DD:EE:FF)
✅ 找到目标设备 智能手环，准备连接
✅ 设备连接成功: 智能手环
💾 已保存设备 UUID: 12345678-1234-1234-1234-123456789ABC [MAC: AA:BB:CC:DD:EE:FF]
💾 保存设备信息（含UUID）: 智能手环 [MAC: AA:BB:CC:DD:EE:FF, UUID: 12345678-...]
✅ 已自动设置 currentDevice: 智能手环
📢 触发代理：didConnectPeripheral
```

#### App 重启后快速重连
```
📱 加载设备信息（含UUID）: 智能手环 [MAC: AA:BB:CC:DD:EE:FF, UUID: 12345678-...]
🚀 检测到 UUID，使用快速重连: 智能手环 [UUID: 12345678-1234-1234-1234-123456789ABC]
🚀 使用 UUID 快速重连: 12345678-1234-1234-1234-123456789ABC
✅ 找到设备（UUID匹配）: 智能手环 [12345678-1234-1234-1234-123456789ABC]
🔗 开始直接连接...
✅ 设备连接成功: 智能手环
```

**验证清单**：
- [ ] 能在 Console 中看到详细的调试日志
- [ ] 日志中包含所有关键步骤
- [ ] 没有错误日志（❌ 开头的）
- [ ] 快速重连时没有扫描相关日志（证明跳过了扫描）

---

## 📊 性能验证

### ✅ 重连速度对比测试

**测试方法**：
1. 记录使用 MAC 扫描重连的耗时
2. 记录使用 UUID 快速重连的耗时
3. 对比两者差异

**期望结果**：
- [ ] MAC 扫描重连：5-10 秒
- [ ] UUID 快速重连：<1 秒
- [ ] **速度提升 5-10 倍**

**测试代码**：
```objc
- (void)testReconnectSpeed {
    NSDate *start = [NSDate date];

    WPBluetoothManager *manager = [WPBluetoothManager sharedInstance];
    manager.delegate = self;
    [manager reconnectFromSandboxWithMac:@"AA:BB:CC:DD:EE:FF"];
}

- (void)didConnectPeripheral:(WPPeripheralInfo *)peripheralInfo {
    NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:self.startTime];
    NSLog(@"⏱ 重连耗时: %.2f 秒", elapsed);

    if (elapsed < 1.0) {
        NSLog(@"✅✅✅ 快速重连成功（<1秒）");
    } else {
        NSLog(@"⚠️ 重连速度较慢（可能使用了扫描）");
    }
}
```

---

## ⚠️ 常见问题排查

### 问题 1：UUID 没有被保存

**可能原因**：
1. 连接成功回调未触发
2. currentDevice 未被正确设置
3. 沙盒存储失败

**排查方法**：
```objc
- (void)didConnectPeripheral:(WPPeripheralInfo *)peripheralInfo {
    WPBluetoothManager *manager = [WPBluetoothManager sharedInstance];

    // 检查 currentDevice
    if (!manager.currentDevice) {
        NSLog(@"❌ currentDevice 为 nil");
    }

    // 检查 UUID
    if (!manager.currentDevice.peripheralUUID) {
        NSLog(@"❌ peripheralUUID 未保存");
    } else {
        NSLog(@"✅ UUID: %@", manager.currentDevice.peripheralUUID);
    }
}
```

### 问题 2：重连速度没有提升

**可能原因**：
1. UUID 未保存（首次连接）
2. UUID 不可用，自动降级到 MAC 扫描
3. 系统未记录该设备

**排查方法**：
- 检查 Console 日志，查找以下关键字：
  - `🚀 检测到 UUID`：证明使用了 UUID 快速重连
  - `⚠️ 降级为扫描重连`：证明使用了 MAC 扫描
  - `⚠️ 未找到 UUID 对应的设备`：系统未记录该设备

### 问题 3：旧数据无法加载

**v2.0.5 已自动兼容旧版本数据**

如果仍然出现问题，检查：
- [ ] 是否使用了 v2.0.5 版本
- [ ] Console 中是否有 `📱 加载设备信息（旧格式）` 日志
- [ ] 旧数据格式是否正确（字符串类型）

---

## ✅ 最终验证

完成以上所有场景测试后，确认：

### 核心功能
- [ ] 首次连接后 UUID 自动保存
- [ ] **App 重启后使用 UUID 快速重连**（v2.0.5 核心功能）
- [ ] **重连速度显著提升（<1 秒）**
- [ ] UUID 不可用时自动降级到 MAC 扫描
- [ ] 沙盒数据格式正确（包含 UUID）
- [ ] 兼容旧版本数据

### 向后兼容
- [ ] 现有代码无需修改即可享受快速重连
- [ ] 旧版本数据自动升级
- [ ] 所有原有功能正常工作

### 日志输出
- [ ] Console 日志完整清晰
- [ ] 关键步骤都有日志记录
- [ ] 无错误日志

---

## 📈 性能改进确认

| 指标 | v2.0.4 及之前 | v2.0.5 | 提升 |
|-----|--------------|--------|------|
| 重连速度 | 5-10 秒 | <1 秒 | ✅ 5-10 倍 |
| 扫描需求 | 每次都扫描 | 无需扫描 | ✅ 跳过 |
| 电量消耗 | 较高 | 极低 | ✅ 改善 |
| 用户体验 | 明显等待 | 无感知 | ✅ 显著改善 |

---

## 📞 技术支持

如果验证过程中遇到问题，请联系：315082431@qq.com

提供以下信息：
1. SDK 版本：v2.0.5
2. Xcode 版本
3. iOS 版本
4. 完整的 Console 日志输出
5. 未通过的验证项
6. 重连耗时数据
7. 是否看到 UUID 相关日志

---

## 🎉 验证成功

如果所有验证项都通过，恭喜！v2.0.5 集成成功。

现在您的 App 可以：
- ✅ 首次连接后自动保存设备 UUID
- ✅ App 重启后使用 UUID 快速重连（<1 秒）
- ✅ UUID 不可用时自动降级到 MAC 扫描
- ✅ 享受 5-10 倍的重连速度提升
- ✅ 提供更好的用户体验

感谢使用 WatchProtocolSDK-ObjC v2.0.5！

---

**重要提示**：
- 首次连接后才能享受快速重连
- 确保设备在首次连接时已被 iOS 系统记录
- 快速重连需要设备在蓝牙范围内
