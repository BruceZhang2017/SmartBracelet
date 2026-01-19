# WatchProtocolSDK-ObjC v2.0.0 发布说明

## 📅 发布日期
2026-01-19

---

## ⚠️ 重要提示

**这是一个破坏性更新版本！** 升级到 v2.0.0 需要修改代码。

如果您正在使用 v1.x 版本，请务必阅读 [迁移指南](MIGRATION-GUIDE-v2.0.md)。

---

## 🎯 核心变更

### 统一 API 参数类型：CBPeripheral → WPPeripheralInfo

为了提供更一致、更易用的 API 设计，v2.0.0 将所有公开接口的 `CBPeripheral` 参数统一替换为 `WPPeripheralInfo`。

---

## 📝 详细变更

### 1. 代理方法参数变更

#### `didConnectPeripheral:` - 连接成功回调

```objective-c
// ❌ v1.x 旧版本
- (void)didConnectPeripheral:(CBPeripheral *)peripheral;

// ✅ v2.0 新版本
- (void)didConnectPeripheral:(WPPeripheralInfo *)peripheralInfo;
```

**优势**：
- 直接获取设备信息，无需手动查找
- 可直接访问 MAC 地址等扩展信息
- 代码更简洁，减少出错可能

---

#### `didDisconnectPeripheral:error:` - 断开连接回调

```objective-c
// ❌ v1.x 旧版本
- (void)didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;

// ✅ v2.0 新版本
- (void)didDisconnectPeripheral:(WPPeripheralInfo *)peripheralInfo error:(NSError *)error;
```

**优势**：
- 可以直接获取 MAC 地址用于日志记录
- 提供更完整的设备上下文信息

---

### 2. 连接方法参数变更

```objective-c
// ❌ v1.x 旧版本
WPPeripheralInfo *info = ...;
[[WPBluetoothManager sharedInstance] connectToPeripheral:info.peripheral];

// ✅ v2.0 新版本
WPPeripheralInfo *info = ...;
[[WPBluetoothManager sharedInstance] connectToPeripheral:info];
```

**优势**：
- 使用更直观，无需访问 `.peripheral` 属性
- 统一的参数类型

---

### 3. 内部实现改进

- ✅ 添加 `peripheralInfoMap` 映射字典，自动追踪 `CBPeripheral` → `WPPeripheralInfo` 关系
- ✅ 扫描发现设备时自动保存映射
- ✅ 连接设备时自动保存映射
- ✅ 系统蓝牙回调时自动查找对应的 `WPPeripheralInfo` 对象

---

## ✨ 为什么升级？

### 更一致的 API 设计
所有方法使用统一的设备信息类型，降低学习成本。

### 更丰富的设备信息
`WPPeripheralInfo` 封装了：
- `CBPeripheral` 原始对象
- MAC 地址（扩展信息）
- 未来可能的其他设备属性

### 更简化的使用方式
无需在 `CBPeripheral` 和 `WPPeripheralInfo` 之间手动转换。

### 更好的封装性
隐藏底层蓝牙实现细节，提供更高层次的抽象。

---

## 📦 下载地址

### XCFramework
位置：`Output-ObjC-Dynamic/WatchProtocolSDK.xcframework`

大小：~708KB

支持架构：
- iOS 设备：arm64
- iOS 模拟器：arm64 + x86_64

---

## 📚 迁移指南

### 快速迁移步骤

1. **更新 SDK 版本**
   ```ruby
   # CocoaPods
   pod 'WatchProtocolSDK-ObjC', '~> 2.0'
   ```

2. **修改代理方法签名**
   ```objective-c
   // 修改参数类型：CBPeripheral* -> WPPeripheralInfo*
   - (void)didConnectPeripheral:(WPPeripheralInfo *)peripheralInfo {
       // 通过 .peripheral 访问原始 CBPeripheral
       NSString *name = peripheralInfo.peripheral.name;
       // 直接访问 MAC 地址
       NSString *mac = peripheralInfo.macAddress;
   }
   ```

3. **更新连接调用**
   ```objective-c
   // 直接传递 WPPeripheralInfo 对象
   [[WPBluetoothManager sharedInstance] connectToPeripheral:info];
   ```

4. **编译测试**
   - 清理构建：⇧⌘K
   - 重新编译：⌘B
   - 运行测试

**详细指南**：[MIGRATION-GUIDE-v2.0.md](MIGRATION-GUIDE-v2.0.md)

---

## ⏱ 预计迁移时间

- **小型项目**（1-2个文件）：~10 分钟
- **中型项目**（3-5个文件）：~20 分钟
- **大型项目**（6+个文件）：~30 分钟

---

## 🔄 兼容性

| 版本 | 兼容性 | 说明 |
|------|--------|------|
| v1.x → v2.0 | ❌ 不兼容 | 需要修改代码 |
| v2.0+ | ✅ 向下兼容 | 未来小版本更新保持兼容 |

---

## 📋 完整变更日志

详见：[CHANGELOG.md](CHANGELOG.md)

---

## 🐛 已知问题

无

---

## 📧 技术支持

如有问题或建议：

1. 查看 [迁移指南](MIGRATION-GUIDE-v2.0.md)
2. 查看 [常见问题](README.md#常见问题)
3. 提交 Issue
4. 联系技术支持团队

---

## 🎉 总结

v2.0.0 是一次重要的架构升级，虽然需要修改代码，但带来了：

- ✅ 更统一的 API 设计
- ✅ 更简洁的使用方式
- ✅ 更好的开发体验
- ✅ 为未来功能扩展打下基础

**我们强烈建议升级到 v2.0.0！** 🚀

---

**发布团队**
WatchProtocolSDK-ObjC 开发组
2026-01-19
