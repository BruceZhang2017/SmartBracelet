# 扫描超时功能使用说明

## 概述

WatchProtocolSDK 的蓝牙扫描功能已优化，支持灵活配置扫描超时时间。

## 主要变更

### 1. 新增属性

在 `WPBluetoothManager` 中新增了 `scanTimeout` 属性：

```objc
/**
 * 扫描超时时间（秒）
 * - 默认值为 0，表示不限时扫描
 * - 设置为大于 0 的值时，扫描将在指定时间后自动停止
 */
@property (nonatomic, assign) NSTimeInterval scanTimeout;
```

### 2. 新增方法

#### 带超时参数的扫描方法

```objc
/**
 * 开始扫描设备（带超时时间）
 * @param deleteCache 是否清空之前的扫描结果
 * @param timeout 扫描超时时间（秒），0 或负数表示不限时
 */
- (void)startScanning:(BOOL)deleteCache timeout:(NSTimeInterval)timeout;
```

#### 带超时参数的连接扫描方法

```objc
/**
 * 扫描并连接指定设备（带超时时间）
 * @param macAddress MAC 地址
 * @param deviceName 设备名称
 * @param timeout 扫描超时时间（秒），0 或负数表示不限时
 */
- (void)connectAndScanWithMac:(NSString *)macAddress
                   deviceName:(NSString *)deviceName
                      timeout:(NSTimeInterval)timeout;
```

## 使用示例

### 方式一：通过 scanTimeout 属性设置（推荐用于全局配置）

```objc
WPBluetoothManager *btManager = [WPBluetoothManager sharedInstance];

// 设置全局扫描超时为 30 秒
btManager.scanTimeout = 30.0;

// 使用默认的 scanTimeout 进行扫描
[btManager startScanning:YES];

// 连接指定设备，使用默认的 scanTimeout
[btManager connectAndScanWithMac:@"AA:BB:CC:DD:EE:FF" deviceName:@"MyWatch"];
```

### 方式二：使用带超时参数的方法（推荐用于一次性配置）

```objc
WPBluetoothManager *btManager = [WPBluetoothManager sharedInstance];

// 扫描 15 秒后自动停止
[btManager startScanning:YES timeout:15.0];

// 连接指定设备，扫描 20 秒后超时
[btManager connectAndScanWithMac:@"AA:BB:CC:DD:EE:FF"
                      deviceName:@"MyWatch"
                         timeout:20.0];
```

### 方式三：不限时扫描（默认行为）

```objc
WPBluetoothManager *btManager = [WPBluetoothManager sharedInstance];

// 方式 1：使用默认的 scanTimeout（初始值为 0）
[btManager startScanning:YES];

// 方式 2：显式设置为 0（不限时）
[btManager startScanning:YES timeout:0];

// 方式 3：设置 scanTimeout 为 0
btManager.scanTimeout = 0;
[btManager startScanning:YES];
```

## 向后兼容性

原有的方法签名保持不变，确保现有代码无需修改即可继续使用：

```objc
// 原有方法仍然可用，会使用 scanTimeout 属性的值
- (void)startScanning:(BOOL)deleteCache;
- (void)connectAndScanWithMac:(NSString *)macAddress deviceName:(NSString *)deviceName;
```

## 默认行为

- **初始状态**：`scanTimeout = 0`（不限时扫描）
- **超时行为**：当设置 `timeout > 0` 时，扫描将在指定秒数后自动停止
- **日志输出**：
  - 设置超时时：`⏱ 设置扫描超时: X.X 秒`
  - 不限时扫描：`♾️ 不限时扫描`
  - 超时触发：`⏰ 扫描超时，停止扫描`

## 最佳实践

1. **快速配对场景**：建议设置 10-30 秒超时
   ```objc
   [btManager startScanning:YES timeout:15.0];
   ```

2. **后台持续扫描**：设置为 0（不限时）
   ```objc
   btManager.scanTimeout = 0;
   [btManager startScanning:YES];
   ```

3. **已知设备连接**：建议设置较短的超时时间
   ```objc
   [btManager connectAndScanWithMac:deviceMac deviceName:deviceName timeout:10.0];
   ```

4. **手动停止扫描**：无论是否设置超时，都可以手动停止
   ```objc
   [btManager stopScanning];
   ```

## 注意事项

- 超时只影响扫描过程，不影响已建立的连接
- 设置为 0 或负数表示不限时，建议使用 0 作为标准值
- 如果在超时前找到目标设备并连接，扫描会自动停止
- 修改 `scanTimeout` 属性会影响后续所有未指定超时参数的扫描操作
