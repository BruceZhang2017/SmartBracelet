# 🐛 Bug 修复：开关状态响应解析缺失

## 📌 问题描述

**问题**：`WPCommands+RaiseToWake` 的 `getRaiseToWakeStatus` 方法只发送了查询指令（0x80），但没有对应的响应解析逻辑。

**影响**：
- 设备返回的开关状态数据被忽略
- 控制台打印 "⚠️ 未处理的指令响应:0x80"
- `currentDevice.isRaiseHandToBrightenScreen` 属性无法更新
- 应用层无法获取抬手亮屏的真实状态

---

## ✅ 修复内容

### 1. 添加开关状态响应处理（WPCommands.m:1221-1227）

在 `handleResponse:` 方法的 switch 语句中添加：

```objc
case WPCommandTypeSwitchStatus:
    [self handleSwitchStatusResponse:response];
    break;
```

### 2. 实现响应解析方法（WPCommands.m:1636-1738）

添加 `handleSwitchStatusResponse:` 方法，参考 Swift 实现（XGZTCommands.swift:1438-1471）：

**核心功能**：
- ✅ **区分响应类型**：
  - 响应长度 >= 10：查询响应，包含所有开关状态（P0 和 P1 字节）
  - 响应长度 < 10：设置响应，只返回成功/失败

- ✅ **解析 P0 字节**（byte 6）：
  - bit 0: 防丢开关
  - **bit 1: 抬手亮屏** ⭐️
  - bit 4: 睡眠监测
  - bit 5: 消息提醒总开关
  - bit 6: 定期运动数据上传
  - bit 7: 目标达成开关

- ✅ **解析 P1 字节**（byte 7）：
  - bit 1: 消息屏幕显示
  - bit 2: 声音开关
  - bit 3: 震动开关
  - bit 4: 定期健康数据上传
  - bit 5: 消息震动开关

- ✅ **自动更新设备模型**：解析后自动更新 `currentDevice` 的所有开关属性

- ✅ **代理回调**：触发 `didReceiveSwitchStatus:p1:` 通知应用层

### 3. 添加代理方法（WPBluetoothManager.h:146-158）

在 `WPBluetoothManagerDelegate` 协议中添加：

```objc
/**
 * 🆕 v2.0.10: 接收到开关状态数据
 * @param p0 P0 字节（包含多个开关位）
 * @param p1 P1 字节（包含多个开关位）
 */
- (void)didReceiveSwitchStatus:(NSInteger)p0 p1:(NSInteger)p1;
```

### 4. 更新文档（WPCommands+RaiseToWake.h:39-67）

完善 `getRaiseToWakeStatus` 方法的注释，添加：
- 响应解析说明
- 数据流向说明（自动更新 + 代理回调）
- 完整的使用示例代码

---

## 📊 对比 Swift 实现

| 特性 | Swift 版本 | ObjC 版本（修复后） | 状态 |
|------|-----------|-------------------|------|
| 发送查询指令 | ✅ | ✅ | ✅ 已对齐 |
| 响应解析 | ✅ | ✅ | ✅ 已对齐 |
| P0 字节解析 | ✅ | ✅ | ✅ 已对齐 |
| P1 字节解析 | ✅ | ✅ | ✅ 已对齐 |
| 更新设备模型 | ✅ | ✅ | ✅ 已对齐 |
| 发送通知 | ✅ | ✅ | ✅ 已对齐 |
| 代理回调 | ❌ | ✅ | ✅ ObjC 更好 |

**改进点**：ObjC 版本增加了代理回调 `didReceiveSwitchStatus:p1:`，比 Swift 版本更规范。

---

## 🧪 测试验证

### 测试场景 1：查询抬手亮屏状态

```objc
// 设置代理
[WPBluetoothManager sharedInstance].delegate = self;

// 发送查询指令
[[WPBluetoothManager sharedInstance] getRaiseToWakeStatus:^(BOOL success, NSError *error) {
    if (success) {
        NSLog(@"查询指令已发送");
        // 等待代理回调或读取 currentDevice 属性
    }
}];

// 实现代理方法
- (void)didReceiveSwitchStatus:(NSInteger)p0 p1:(NSInteger)p1 {
    BOOL raiseToWake = ((p0 >> 1) & 1) > 0;
    NSLog(@"抬手亮屏状态: %@", raiseToWake ? @"开启" : @"关闭");
}
```

### 测试场景 2：读取 currentDevice 属性

```objc
[[WPBluetoothManager sharedInstance] getRaiseToWakeStatus:^(BOOL success, NSError *error) {
    if (success) {
        // 稍等设备响应后读取
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            WPBluetoothWatchDevice *device = [WPBluetoothManager sharedInstance].currentDevice;
            NSLog(@"抬手亮屏: %@", device.isRaiseHandToBrightenScreen ? @"开启" : @"关闭");
        });
    }
}];
```

### 预期日志输出

```
📥 接收指令 [10 bytes]: 00800300050001020000
📥 收到响应 - 指令代码:0x80 长度:10
🔀 开关状态响应 - P0:0x02 P1:0x00
✋ 抬手亮屏状态: 开启
```

---

## 📝 修改文件清单

1. ✅ `WatchProtocolSDK-ObjC/Core/WPCommands.m`
   - 添加 `case WPCommandTypeSwitchStatus:` 分支
   - 实现 `handleSwitchStatusResponse:` 方法

2. ✅ `WatchProtocolSDK-ObjC/Core/WPBluetoothManager.h`
   - 添加代理方法 `didReceiveSwitchStatus:p1:`

3. ✅ `WatchProtocolSDK-ObjC/Core/WPCommands+RaiseToWake.h`
   - 完善 `getRaiseToWakeStatus` 方法注释
   - 添加使用示例

---

## 🎯 版本说明

**修复版本**：v2.0.10
**修复时间**：2026-01-30
**修复内容**：补充开关状态响应解析逻辑，对齐 Swift 实现
**向后兼容**：✅ 完全兼容，新增功能不影响现有代码

---

## 🔗 相关文件

- `WatchProtocolSDK-ObjC/Core/WPCommands.m` - 响应解析实现
- `WatchProtocolSDK-ObjC/Core/WPCommands+RaiseToWake.h` - 抬手亮屏接口
- `WatchProtocolSDK-ObjC/Core/WPCommands+RaiseToWake.m` - 抬手亮屏实现
- `WatchProtocolSDK/Core/XGZTCommands.swift:1438-1471` - Swift 参考实现

---

## ✅ 验证通过

- [x] 编译通过
- [x] 响应解析逻辑正确
- [x] 代理方法定义正确
- [x] 与 Swift 实现对齐
- [x] 文档注释完善
