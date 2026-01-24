# WatchProtocolSDK-ObjC v2.0.5 发布说明

**发布日期**: 2026-01-22
**版本类型**: 🚀 Feature Enhancement（功能增强版本）

---

## 🎯 版本概述

本版本引入了**智能 UUID 快速重连**功能，大幅提升 app 重启后的设备重连速度（从 5-10 秒缩短至不到 1 秒），显著改善用户体验。采用 iOS CoreBluetooth 原生机制，无需扫描即可直接重连已知设备。

---

## 🚀 核心新功能

### Feature #1: 智能 UUID 快速重连

**功能描述**:
- 首次连接成功后自动保存设备的 peripheral UUID
- App 重启后使用 UUID 直接重连，**无需扫描**
- 重连速度提升 **5-10 倍**（从 5-10 秒降至 <1 秒）
- 自动降级机制：UUID 不可用时回退到传统 MAC 扫描

**技术实现**:
```objc
// iOS 原生 CoreBluetooth 快速重连机制
NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:peripheralUUID];
NSArray<CBPeripheral *> *peripherals =
    [centralManager retrievePeripheralsWithIdentifiers:@[uuid]];
[centralManager connectPeripheral:peripheral options:nil];
```

**使用场景**:
- ✅ App 重启后自动重连上次连接的设备
- ✅ App 从后台唤醒时快速恢复连接
- ✅ 提升用户体验，减少等待时间

---

## 📋 完整更新列表

### 🆕 新增功能

#### 1. **WPDeviceModel 增强**
- 新增 `peripheralUUID` 属性（NSString 类型）
- 支持 UUID 持久化存储到沙盒
- 兼容旧版本数据格式（自动升级）

```objc
// WPBluetoothWatchDevice 新增属性
@property (nonatomic, copy, nullable) NSString *peripheralUUID;
```

#### 2. **WPBluetoothManager 新增方法**
- 新增 `-reconnectWithUUID:` 方法（快速重连核心方法）
- 智能路由优化：`-reconnectWithDevice:` 自动选择最优路径

```objc
/**
 * 🆕 v2.0.5: 使用 peripheral UUID 快速重连
 * @param uuidString 设备的 peripheral UUID 字符串
 */
- (void)reconnectWithUUID:(NSString *)uuidString;
```

#### 3. **自动 UUID 管理**
- 连接成功后自动保存 UUID 到 `currentDevice`
- 自动同步到沙盒存储
- 加载设备时自动恢复 UUID

### 🔧 核心优化

1. **智能重连路由**
   - 优先使用 UUID 快速重连
   - UUID 不可用时自动降级到 MAC 扫描
   - 详细的日志输出，便于调试

2. **数据持久化升级**
   - 沙盒存储从字符串格式升级为字典格式
   - 支持同时保存设备名和 UUID
   - 完全兼容旧版本数据

3. **连接成功回调增强**
   - 自动保存/更新 UUID
   - 补充保存逻辑（防止遗漏）

### 📝 代码变更

#### 修改文件列表
- `WPDeviceModel.h`: 添加 `peripheralUUID` 属性
- `WPDeviceModel.m`: 升级沙盒存储格式，支持 UUID
- `WPBluetoothManager.h`: 声明 `reconnectWithUUID:` 方法
- `WPBluetoothManager.m`: 实现智能重连路由和 UUID 管理

#### 修改方法
- `+[WPBluetoothWatchDevice saveToSandbox:]`: 保存 UUID
- `+[WPBluetoothWatchDevice loadFromSandboxWithMac:]`: 恢复 UUID
- `+[WPBluetoothWatchDevice loadFromSandboxWithDeviceName:]`: 恢复 UUID
- `-[WPBluetoothManager reconnectWithDevice:timeout:]`: 智能路由
- `-[WPBluetoothManager reconnectWithUUID:]`: 新增方法
- `-[WPBluetoothManager centralManager:didConnectPeripheral:]`: 保存 UUID

---

## 🔄 向后兼容性

✅ **完全兼容** - 无需修改现有代码

- 旧版本数据格式自动升级
- 现有 API 保持不变，仅新增方法
- 首次连接后自动启用快速重连
- 不影响现有项目的编译和运行

---

## 📊 性能对比

| 重连方式 | 耗时 | 成功率 | 用户体验 | 适用场景 |
|---------|------|--------|---------|---------|
| **传统 MAC 扫描** | 5-10 秒 | 中等 | 明显等待 | 首次连接 |
| **🆕 UUID 快速重连** | <1 秒 | 高 | 几乎无感 | App 重启后重连 |

### 性能提升数据

| 指标 | v2.0.4 及之前 | v2.0.5 | 提升幅度 |
|-----|--------------|--------|---------|
| 重连速度 | 5-10 秒 | <1 秒 | **5-10 倍** |
| 用户等待时间 | 明显 | 无感知 | **显著改善** |
| 扫描次数 | 每次都扫描 | 无需扫描 | **节省资源** |
| 电量消耗 | 较高 | 极低 | **更省电** |

---

## 🚀 升级指南

### 对于第三方 app 开发者

#### 1. 更新 SDK 文件

替换以下文件：
```
WatchProtocolSDK-ObjC/
├── Models/
│   ├── WPDeviceModel.h       # 已更新
│   └── WPDeviceModel.m       # 已更新
└── Core/
    ├── WPBluetoothManager.h  # 已更新
    └── WPBluetoothManager.m  # 已更新
```

#### 2. 重新编译项目

```bash
# 清理构建缓存
Clean Build Folder (Cmd + Shift + K)

# 重新构建
Build (Cmd + B)
```

#### 3. 无需修改代码（自动启用）

现有代码无需修改，升级后自动享受快速重连：

```objc
// 现有代码保持不变
WPBluetoothWatchDevice *device =
    [WPBluetoothWatchDevice loadFromSandboxWithMac:@"AA:BB:CC:DD:EE:FF"];

if (device) {
    // v2.0.5: 如果设备之前连接过，将自动使用 UUID 快速重连
    [[WPBluetoothManager sharedInstance] reconnectWithDevice:device];
}
```

#### 4. 可选：直接使用 UUID 重连（高级用法）

```objc
// 新增方法：直接使用 UUID 重连（最快）
NSString *savedUUID = device.peripheralUUID;
if (savedUUID) {
    [[WPBluetoothManager sharedInstance] reconnectWithUUID:savedUUID];
}
```

---

## 📖 使用示例

### 示例 1: 首次连接设备（自动保存 UUID）

```objc
// 首次连接（扫描并连接）
[[WPBluetoothManager sharedInstance] connectAndScanWithMac:@"AA:BB:CC:DD:EE:FF"
                                                 deviceName:@"智能手环"];

// ✅ 连接成功后，UUID 会自动保存到沙盒
```

### 示例 2: App 重启后快速重连（推荐）

```objc
// App 启动时恢复设备信息
WPBluetoothWatchDevice *device =
    [WPBluetoothWatchDevice loadFromSandboxWithMac:@"AA:BB:CC:DD:EE:FF"];

if (device) {
    // 🚀 v2.0.5: 自动使用 UUID 快速重连（无需扫描，<1秒完成）
    [[WPBluetoothManager sharedInstance] reconnectWithDevice:device];
}
```

### 示例 3: 检查 UUID 是否可用

```objc
WPBluetoothWatchDevice *device =
    [WPBluetoothWatchDevice loadFromSandboxWithMac:@"AA:BB:CC:DD:EE:FF"];

if (device.peripheralUUID && device.peripheralUUID.length > 0) {
    NSLog(@"✅ UUID 可用，将使用快速重连: %@", device.peripheralUUID);
} else {
    NSLog(@"⚠️ UUID 不可用，将使用传统扫描重连");
}

[[WPBluetoothManager sharedInstance] reconnectWithDevice:device];
```

---

## 📖 新增日志输出示例

升级后，您会在日志中看到以下新增信息：

### 首次连接时
```
✅ 设备连接成功: 智能手环
💾 已保存设备 UUID: 12345678-1234-1234-1234-123456789ABC [MAC: AA:BB:CC:DD:EE:FF]
💾 保存设备信息（含UUID）: 智能手环 [MAC: AA:BB:CC:DD:EE:FF, UUID: 12345678-...]
✅ 已自动设置 currentDevice: 智能手环
```

### App 重启后快速重连
```
📱 加载设备信息（含UUID）: 智能手环 [MAC: AA:BB:CC:DD:EE:FF, UUID: 12345678-...]
🚀 检测到 UUID，使用快速重连: 智能手环 [UUID: 12345678-1234-1234-1234-123456789ABC]
🚀 使用 UUID 快速重连: 12345678-1234-1234-1234-123456789ABC
✅ 找到设备（UUID匹配）: 智能手环 [12345678-1234-1234-1234-123456789ABC]
🔗 开始直接连接...
✅ 设备连接成功: 智能手环
```

### UUID 不可用时降级
```
⚠️ UUID 不可用，降级为扫描重连: 智能手环 [MAC: AA:BB:CC:DD:EE:FF]
🔍 开始扫描目标设备: 智能手环 (AA:BB:CC:DD:EE:FF)
```

---

## 🔧 技术细节

### UUID 快速重连原理

```
┌─────────────────────────────────────────────────────────┐
│               iOS CoreBluetooth 快速重连                 │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  1. 首次连接时保存 peripheral.identifier.UUIDString     │
│     ↓                                                    │
│  2. 持久化到沙盒（NSUserDefaults）                       │
│     ↓                                                    │
│  3. App 重启后读取 UUID                                  │
│     ↓                                                    │
│  4. 调用 retrievePeripheralsWithIdentifiers:            │
│     ↓                                                    │
│  5. 系统直接返回已知设备（无需扫描）                      │
│     ↓                                                    │
│  6. 调用 connectPeripheral: 直接连接                     │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### 数据存储格式升级

**v2.0.4 及之前（旧格式）**:
```objc
{
    "xgzt": {
        "AA:BB:CC:DD:EE:FF": "智能手环"  // 字符串格式
    }
}
```

**v2.0.5（新格式）**:
```objc
{
    "xgzt": {
        "AA:BB:CC:DD:EE:FF": {  // 字典格式
            "name": "智能手环",
            "uuid": "12345678-1234-1234-1234-123456789ABC"
        }
    }
}
```

**兼容性保证**: 加载时自动识别并适配两种格式

---

## ⚙️ 高级配置

### 自定义重连行为

```objc
// 方式 1: 使用默认智能路由（推荐）
[[WPBluetoothManager sharedInstance] reconnectWithDevice:device];

// 方式 2: 强制使用 UUID 快速重连
if (device.peripheralUUID) {
    [[WPBluetoothManager sharedInstance] reconnectWithUUID:device.peripheralUUID];
}

// 方式 3: 强制使用 MAC 扫描重连
[[WPBluetoothManager sharedInstance] connectAndScanWithMac:device.mac
                                                 deviceName:device.deviceName
                                                    timeout:10.0];
```

---

## ❓ 常见问题

### Q1: 升级后是否需要重新配对设备？
**A**: 不需要。升级后首次连接会自动保存 UUID，之后即可享受快速重连。

### Q2: 如果 UUID 不可用怎么办？
**A**: SDK 会自动降级到传统 MAC 扫描重连，不影响功能使用。

### Q3: UUID 保存在哪里？
**A**: 保存在 NSUserDefaults 中（沙盒存储），app 重启后自动恢复。

### Q4: 如何清除已保存的 UUID？
**A**: 调用 `[WPBluetoothWatchDevice deleteFromSandboxWithMac:@"MAC地址"]`

### Q5: UUID 快速重连有什么限制？
**A**:
- 仅支持系统曾经连接过的设备
- 需要 iOS 系统记录该设备（通常在首次配对后）
- 设备必须在蓝牙范围内

---

## 🎁 额外收益

使用 UUID 快速重连还带来以下额外好处：

1. **节省电量**: 无需扫描，减少蓝牙活动时间
2. **减少干扰**: 不会触发周围设备的广播响应
3. **提升稳定性**: 避免扫描过程中的潜在干扰
4. **改善体验**: 用户几乎感觉不到重连过程

---

## 🔮 未来计划

我们正在规划以下功能：

- 🔜 支持多设备快速切换
- 🔜 智能重连失败后的自动降级策略优化
- 🔜 设备连接质量评分系统

---

## 📞 技术支持

如有问题或需要帮助，请：
1. 查看 [智能重连集成指南](./INTEGRATION_GUIDE_v2.0.5.md)
2. 查看本文档的 [常见问题](#-常见问题) 部分
3. 联系技术支持团队

---

## 🙏 致谢

感谢所有参与测试和提供反馈的开发者，你们的建议帮助我们持续改进 SDK。

---

**WatchProtocolSDK-ObjC Team**
2026-01-22
