# WatchProtocolSDK 创建检查清单

> 使用本清单确保 Framework 创建的每个步骤都正确完成

---

## 🎯 准备阶段

- [ ] **代码优化已完成**
  - [x] XGZTDeviceManager 已创建（设备缓存管理）
  - [x] XGZTCommandStateManager 已创建（指令状态管理）
  - [x] XGZTConnectionStateManager 已创建（连接状态管理）
  - [x] 全局变量已迁移到管理器
  - [x] 死锁问题已修复

- [ ] **Git 准备**
  - [ ] 当前工作已提交到 Git
  - [ ] 创建新分支：`feature/watchprotocol-framework`
  - [ ] 分支已推送到远程

- [ ] **开发环境检查**
  - [ ] Xcode 版本 >= 15.0
  - [ ] CocoaPods 已安装（运行 `pod --version` 检查）
  - [ ] 项目能正常编译运行

---

## 📦 第一阶段：创建 Framework Target

### 1.1 在 Xcode 中创建 Framework

- [ ] 打开 `SmartBracelet.xcodeproj`
- [ ] 菜单：`File` → `New` → `Target...`
- [ ] 选择模板：`iOS` → `Framework`
- [ ] 配置信息：
  - [ ] Product Name: `WatchProtocolSDK`
  - [ ] Language: `Swift`
  - [ ] Include Tests: ☑️

- [ ] 验证创建结果：
  - [ ] 左侧导航器出现 `WatchProtocolSDK` 文件夹
  - [ ] 包含 `WatchProtocolSDK.h` 文件
  - [ ] TARGETS 列表中有 `WatchProtocolSDK`

### 1.2 配置 Build Settings

- [ ] 选择 `WatchProtocolSDK` Target
- [ ] General 设置：
  - [ ] iOS Deployment Target: `12.0`
  - [ ] Version: `1.0.0`
  - [ ] Build: `1`

- [ ] Build Settings 关键配置：
  - [ ] `Swift Language Version`: `Swift 5`
  - [ ] `Build Libraries for Distribution`: `YES` ⭐ 重要
  - [ ] `Defines Module`: `YES`
  - [ ] `Skip Install`: `NO`

---

## 📁 第二阶段：组织目录结构

### 2.1 创建文件夹

在 `WatchProtocolSDK` 下创建以下 Group：

- [ ] `Core` - 核心业务类
- [ ] `Models` - 数据模型
- [ ] `Utils` - 工具类
- [ ] `Public` - 公开 API

### 2.2 验证结构

```
WatchProtocolSDK/
├── WatchProtocolSDK.h
├── Info.plist
├── Core/           ✓
├── Models/         ✓
├── Utils/          ✓
└── Public/         ✓
```

---

## 🔗 第三阶段：配置依赖

### 3.1 系统框架

- [ ] 进入 `Build Phases` → `Link Binary With Libraries`
- [ ] 添加以下框架：
  - [ ] `Foundation.framework`
  - [ ] `CoreBluetooth.framework`
  - [ ] `UIKit.framework`

### 3.2 第三方库（RealmSwift）

**使用 CocoaPods：**

- [ ] 编辑 `Podfile`，添加：
  ```ruby
  target 'WatchProtocolSDK' do
    pod 'RealmSwift', '~> 10.0'
  end
  ```

- [ ] 运行：`pod install`
- [ ] 重新打开 `.xcworkspace` 文件

### 3.3 解决工具类依赖

选择以下方案之一：

- [ ] **方案 A**：复制 `Async` 工具类到 Framework
- [ ] **方案 B**：使用 `DispatchQueue` 替代 `Async`
- [ ] **方案 C**：通过协议解耦

推荐：**方案 B**（使用系统 API）

---

## 📄 第四阶段：移动文件到 Framework

### 4.1 移动到 Core 文件夹

从 `SmartBracelet/huaxin/WatchProtocol/` 移动以下文件：

- [ ] `XGZTBlueToothManager.swift` → `Core/`
- [ ] `XGZTBusinessHandler.swift` → `Core/`
- [ ] `XGZTCommands.swift` → `Core/`
- [ ] `XGZTDeviceManager.swift` → `Core/`
- [ ] `XGZTCommandStateManager.swift` → `Core/`
- [ ] `XGZTConnectionStateManager.swift` → `Core/`

### 4.2 移动到 Models 文件夹

- [ ] `XGZTSwitchDevice.swift` → `Models/`
- [ ] `DatabaseManager.swift` → `Models/`

### 4.3 移动到 Utils 文件夹

- [ ] `XLogger.swift` → `Utils/`

### 4.4 移动方式

**重要**：不要直接拖动，使用以下步骤：

1. 在 Xcode 中选中文件
2. 右键 → `Delete` → 选择 `Remove Reference`（不要选择 Move to Trash）
3. 右键 Framework 的目标文件夹 → `Add Files to "SmartBracelet"...`
4. 选择文件 → 确保 `Copy items if needed` 未勾选
5. Target Membership 勾选 `WatchProtocolSDK`

---

## 🎨 第五阶段：创建公开 API

### 5.1 更新头文件

- [ ] 打开 `WatchProtocolSDK.h`
- [ ] 更新内容（参考创建指南）

### 5.2 创建 Swift 公开 API

- [ ] 在 `Public/` 中创建 `WPPublicAPI.swift`
- [ ] 实现以下类：
  - [ ] `WatchProtocolSDK`（主入口）
  - [ ] `WPBluetoothManager`（蓝牙管理）
  - [ ] `WPDeviceManager`（设备管理）
  - [ ] `WPConnectionStateManager`（连接状态）

### 5.3 设置访问权限

为以下类添加 `public` 关键字：

- [ ] `XGZTBlueToothManager`
- [ ] `XGZTBusinessHandler`
- [ ] `BluetoothWatchDevice`
- [ ] `XGZTDeviceManager`
- [ ] `XGZTCommandStateManager`
- [ ] `XGZTConnectionStateManager`
- [ ] `DeviceType` 枚举

---

## 🔧 第六阶段：修复编译错误

### 6.1 处理 Async 依赖

在所有使用 `Async` 的地方替换为：

```swift
// 旧代码
Async.main(after: 0.5) {
    // code
}

// 新代码
DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
    // code
}
```

受影响的文件：
- [ ] `XGZTBusinessHandler.swift`
- [ ] `XGZTBlueToothManager.swift`

### 6.2 处理 BLEManager 依赖

找到以下代码：

```swift
BLEManager.shared.stopScan()
```

修改为使用协议或注释掉（Framework 内部不应依赖主项目）

### 6.3 处理 NotificationCenter 字符串

建议创建通知名称枚举：

- [ ] 在 `Utils/` 中创建 `WPNotifications.swift`
- [ ] 定义通知名称常量

### 6.4 首次编译

- [ ] 选择 Scheme: `WatchProtocolSDK`
- [ ] 选择目标: `Any iOS Device (arm64)`
- [ ] 按 `⌘ + B` 编译
- [ ] 记录所有错误

---

## 🧪 第七阶段：测试 Framework

### 7.1 在主项目中集成

- [ ] 选择 `SmartBracelet` Target
- [ ] `General` → `Frameworks, Libraries, and Embedded Content`
- [ ] 添加 `WatchProtocolSDK.framework`
- [ ] Embed 设置为：`Embed & Sign`

### 7.2 测试导入

在主项目某个文件中：

```swift
import WatchProtocolSDK

// 测试
WatchProtocolSDK.shared.initialize()
```

- [ ] 能正常导入
- [ ] 能调用公开 API
- [ ] 编译通过

### 7.3 功能测试

- [ ] 蓝牙初始化
- [ ] 设备扫描
- [ ] 设备连接
- [ ] 数据同步
- [ ] 断开连接

---

## 📦 第八阶段：构建和导出

### 8.1 构建 Release 版本

- [ ] 编辑 Scheme → Build Configuration → `Release`
- [ ] 构建 iOS 真机版本
- [ ] 构建 iOS 模拟器版本

### 8.2 创建 XCFramework

运行以下命令：

```bash
xcodebuild -create-xcframework \
  -framework build/Release-iphoneos/WatchProtocolSDK.framework \
  -framework build/Release-iphonesimulator/WatchProtocolSDK.framework \
  -output WatchProtocolSDK.xcframework
```

- [ ] XCFramework 创建成功
- [ ] 文件大小合理（< 20MB）

---

## 📚 第九阶段：文档和发布

### 9.1 创建文档

- [ ] `README.md` - 使用说明
- [ ] `CHANGELOG.md` - 版本变更记录
- [ ] `LICENSE` - 开源协议（如果开源）
- [ ] API 文档（使用 Jazzy 生成）

### 9.2 发布准备

- [ ] 更新版本号
- [ ] 创建 Git tag: `v1.0.0`
- [ ] 推送到远程仓库
- [ ] 创建 Release（GitHub/GitLab）

### 9.3 CocoaPods 发布（可选）

- [ ] 创建 `.podspec` 文件
- [ ] 验证：`pod lib lint WatchProtocolSDK.podspec`
- [ ] 发布：`pod trunk push WatchProtocolSDK.podspec`

---

## ✅ 最终验证

### 完整性检查

- [ ] Framework 能独立编译
- [ ] 主项目集成 Framework 后能正常运行
- [ ] 所有核心功能正常工作
- [ ] 无内存泄漏
- [ ] 无崩溃

### 性能检查

- [ ] 启动时间无明显增加
- [ ] 内存占用正常
- [ ] 蓝牙扫描和连接速度正常

### 兼容性检查

- [ ] iOS 12.0 设备测试通过
- [ ] iOS 17.0 设备测试通过
- [ ] 真机测试通过
- [ ] 模拟器测试通过

---

## 🎉 完成

当所有检查项都完成后，Framework 创建工作就完成了！

**完成日期**：__________
**验证人员**：__________
**版本号**：v1.0.0

---

## 📝 备注

记录遇到的问题和解决方案：

1.

2.

3.
