# MAC 地址提取修复说明 (v2.0.3)

## 🐛 问题描述

在 WatchProtocolSDK-ObjC v2.0.2 及之前版本中，`WPBluetoothManager` 的 `didDiscoverPeripheral` 方法错误地使用了 `peripheral.identifier.UUIDString` 作为设备的 MAC 地址。

```objc
// ❌ 错误的实现（v2.0.2）
NSString *macAddress = [peripheral.identifier.UUIDString uppercaseString];
```

**问题**：
- `peripheral.identifier` 是 iOS 系统分配的**随机 UUID**，不是设备的真实 MAC 地址
- 每次重启蓝牙或系统后，同一设备的 UUID 可能会变化
- 导致无法通过 MAC 地址进行设备识别和重连

## ✅ 解决方案

参考 Swift 版本的 `XGZTBlueToothManager.swift` 实现，从广播数据的**制造商数据（Manufacturer Data）**中提取真实的 MAC 地址。

### 1. 创建 NSData 扩展

新增文件：
- `WatchProtocolSDK-ObjC/Utils/NSData+HexString.h`
- `WatchProtocolSDK-ObjC/Utils/NSData+HexString.m`

提供方法：
```objc
@interface NSData (HexString)
- (NSString *)hexEncodedStringWithSeparator:(NSString *)separator;
- (NSString *)hexEncodedString;
@end
```

### 2. 修改 MAC 地址提取逻辑

在 `WPBluetoothManager.m` 的 `didDiscoverPeripheral` 方法中：

```objc
// ✅ 正确的实现（v2.0.3）
// 从广播数据的制造商数据中提取真实的 MAC 地址
NSData *manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey];

// 检查制造商数据是否符合协议规范：
// - 长度为 15 字节
// - manufacturerData[0] == 0x06
// - manufacturerData[1] == 0x01
if (!manufacturerData || manufacturerData.length != 15) {
    return; // 不符合协议规范，跳过此设备
}

const uint8_t *bytes = (const uint8_t *)manufacturerData.bytes;
if (bytes[0] != 0x06 || bytes[1] != 0x01) {
    return; // 不符合协议规范，跳过此设备
}

// 从索引 5-10 提取 MAC 地址（共 6 个字节）
NSData *macData = [manufacturerData subdataWithRange:NSMakeRange(5, 6)];
// 转换为十六进制字符串，格式如 "AA:BB:CC:DD:EE:FF"
NSString *macAddress = [macData hexEncodedStringWithSeparator:@":"];

// 提取品牌信息（索引 12）
NSInteger brand = bytes[12];
[self.brands setObject:@(brand) forKey:macAddress];
```

### 3. 协议数据格式

设备广播数据中的制造商数据（15 字节）格式：

| 索引 | 说明 | 示例值 |
|------|------|--------|
| 0 | 协议标识1 | 0x06 |
| 1 | 协议标识2 | 0x01 |
| 2-4 | 保留 | - |
| 5-10 | **MAC 地址（6 字节）** | AA:BB:CC:DD:EE:FF |
| 11 | 保留 | - |
| 12 | **品牌标识** | 设备品牌代码 |
| 13-14 | 保留 | - |

## 📋 修改文件清单

### 新增文件
1. `WatchProtocolSDK-ObjC/Utils/NSData+HexString.h` - NSData 扩展头文件
2. `WatchProtocolSDK-ObjC/Utils/NSData+HexString.m` - NSData 扩展实现
3. `WatchProtocolSDK-ObjC/MAC_ADDRESS_FIX_v2.0.3.md` - 本说明文档

### 修改文件
1. `WatchProtocolSDK-ObjC/Core/WPBluetoothManager.m`
   - 第 13 行：新增 `#import "NSData+HexString.h"`
   - 第 445-521 行：重写 `didDiscoverPeripheral` 方法

2. `WatchProtocolSDK-ObjC/WatchProtocolSDK.h`
   - 第 48 行：新增 `#import <WatchProtocolSDK/NSData+HexString.h>`
   - 第 51 行：新增 `#import "NSData+HexString.h"`

## 🔄 对比 Swift 版本

修改后的 Objective-C 版本完全匹配 Swift 版本的实现逻辑：

| 特性 | Swift 版本 | ObjC 版本（修复后） |
|------|------------|---------------------|
| MAC 地址来源 | manufacturerData[5...10] | manufacturerData[5-10] |
| 数据格式验证 | ✅ 长度 15 字节 + 协议标识 | ✅ 长度 15 字节 + 协议标识 |
| 转换格式 | hexEncodedString() | hexEncodedStringWithSeparator(@":") |
| 品牌信息提取 | ✅ manufacturerData[12] | ✅ bytes[12] |
| 大小写处理 | lowercased() | lowercaseString |

## ✨ 修复效果

### 修复前
```
🔍 发现设备: e watch [550E8400-E29B-41D4-A716-446655440000]
```
（使用 iOS 系统分配的 UUID，不稳定）

### 修复后
```
🔍 发现设备: e watch [AA:BB:CC:DD:EE:FF] RSSI: -45
广播数据: {...}
```
（使用设备真实 MAC 地址，稳定可靠）

## 📦 Framework 更新

运行构建脚本更新 Framework：
```bash
./build_watchprotocol_objc_dynamic.sh
```

输出位置：
```
Output-ObjC-Dynamic/WatchProtocolSDK.xcframework
```

## 🔍 验证方法

### 1. 检查符号表
```bash
nm Output-ObjC-Dynamic/WatchProtocolSDK.xcframework/ios-arm64/WatchProtocolSDK.framework/WatchProtocolSDK | grep hexEncoded
```

预期输出：
```
0000000000010fb4 t -[NSData(HexString) hexEncodedStringWithSeparator:]
0000000000011160 t -[NSData(HexString) hexEncodedString]
```

### 2. 检查头文件
```bash
ls Output-ObjC-Dynamic/WatchProtocolSDK.xcframework/ios-arm64/WatchProtocolSDK.framework/Headers/
```

预期包含：
```
NSData+HexString.h
WatchProtocolSDK.h
WPBluetoothManager.h
...
```

## ⚠️ 重要说明

1. **协议兼容性**：仅识别符合协议规范的设备（manufacturerData[0] == 0x06 && manufacturerData[1] == 0x01）
2. **不影响现有功能**：其他蓝牙设备扫描功能保持不变
3. **向后兼容**：保持与 v2.0.2 的 API 兼容性

## 📝 版本历史

- **v2.0.3**（2026-01-21）
  - 🐛 修复：从制造商数据中正确提取 MAC 地址
  - ✨ 新增：NSData+HexString 扩展
  - 🔄 对齐：与 Swift 版本实现逻辑完全一致

- **v2.0.2**（2026-01-20）
  - ❌ 问题：使用 peripheral.identifier 作为 MAC 地址（不正确）

---

**修复日期**：2026-01-21
**修复版本**：v2.0.3
**修复人员**：Claude Code
