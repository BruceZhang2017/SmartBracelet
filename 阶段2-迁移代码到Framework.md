# 阶段2：迁移代码到 Framework

> **当前阶段**: 将 WatchProtocol 代码添加到 Framework Target
> **预计时间**: 10-15 分钟
> **难度**: ⭐⭐⭐☆☆

---

## 📋 操作前状态检查

- [x] WatchProtocolSDK Target 已创建
- [x] 验证脚本显示 22 项全部通过
- [x] 首次编译成功
- [ ] 已在 Xcode 中打开项目（.xcworkspace）

---

## 🎯 本阶段目标

将以下 9 个文件添加到 WatchProtocolSDK Target 并组织到正确的目录结构：

```
Core/ (6个核心业务文件)
├── XGZTBlueToothManager.swift
├── XGZTBusinessHandler.swift
├── XGZTCommands.swift
├── XGZTDeviceManager.swift
├── XGZTCommandStateManager.swift
└── XGZTConnectionStateManager.swift

Models/ (2个数据模型文件)
├── XGZTSwitchDevice.swift
└── DatabaseManager.swift

Utils/ (1个工具文件)
└── XLogger.swift
```

---

## 📝 重要概念：Target Membership

**什么是 Target Membership？**
- 每个文件可以属于一个或多个 Target
- 文件只会被它所属的 Target 编译
- 我们需要将文件同时添加到 `SmartBracelet` 和 `WatchProtocolSDK` 两个 Target

**为什么需要同时属于两个 Target？**
- `SmartBracelet`：主应用仍需使用这些代码
- `WatchProtocolSDK`：Framework 需要包含这些代码

---

## 🔧 操作步骤

### 步骤 1：添加 Core 文件到 Framework

#### 1.1 选择第一个文件

1. 在 Xcode 左侧导航栏，展开：
   ```
   SmartBracelet → SmartBracelet → huaxin → WatchProtocol
   ```

2. 点击选中：`XGZTBlueToothManager.swift`

#### 1.2 设置 Target Membership

1. 打开右侧检查器（Inspector）
   - 如果看不到，点击右上角的工具栏按钮（最右边的图标）
   - 或按快捷键：`⌘ + Option + 1`

2. 在 **File Inspector** 标签页（第一个标签）中，找到 `Target Membership` 部分

3. 你会看到类似这样的复选框列表：
   ```
   ☑️ SmartBracelet
   ☐ SmartBraceletTests
   ☐ WatchProtocolSDK        <-- 勾选这个
   ☐ WatchProtocolSDKTests
   ```

4. **勾选** `WatchProtocolSDK`
   - ⚠️ **保持** `SmartBracelet` 也勾选着
   - 现在这个文件同时属于两个 Target

#### 1.3 移动文件到 Core 组

现在文件已经属于 Framework Target，但它仍在原来的位置。我们需要在 Framework 的 Core 组中添加引用：

**方法 A：拖动（推荐）**

1. 在左侧导航栏，找到：
   ```
   WatchProtocolSDK → Core/
   ```

2. 按住 `Option` 键，将 `XGZTBlueToothManager.swift` 拖到 `Core/` 文件夹
   - ⚠️ 必须按住 `Option` 键，这样会创建引用而不是移动文件

3. 松开鼠标后，文件会出现在两个地方：
   - 原位置：`SmartBracelet/huaxin/WatchProtocol/`
   - Framework：`WatchProtocolSDK/Core/`

**方法 B：手动添加引用（如果拖动不生效）**

1. 右键点击 `WatchProtocolSDK/Core/` 文件夹
2. 选择：`Add Files to "SmartBracelet"...`
3. 找到并选择：`SmartBracelet/huaxin/WatchProtocol/XGZTBlueToothManager.swift`
4. ⚠️ **取消勾选** `Copy items if needed`（重要！）
5. 在 `Add to targets` 中，确保 `WatchProtocolSDK` 已勾选
6. 点击 `Add`

#### 1.4 重复操作其他 Core 文件

用同样的方法，为以下文件设置 Target Membership 并添加到 `Core/`：

- [ ] `XGZTBusinessHandler.swift`
- [ ] `XGZTCommands.swift`
- [ ] `XGZTDeviceManager.swift`
- [ ] `XGZTCommandStateManager.swift`
- [ ] `XGZTConnectionStateManager.swift`

**快捷方式**：
- 可以按住 `⌘` 键一次选中多个文件
- 然后在 File Inspector 中一次性勾选 `WatchProtocolSDK`

---

### 步骤 2：添加 Models 文件到 Framework

使用同样的方法，将以下文件添加到 `WatchProtocolSDK/Models/`：

- [ ] `XGZTSwitchDevice.swift`
- [ ] `DatabaseManager.swift`

操作步骤：
1. 选中文件
2. File Inspector → Target Membership → 勾选 `WatchProtocolSDK`
3. 按住 `Option` 拖到 `WatchProtocolSDK/Models/` 或手动添加引用

---

### 步骤 3：添加 Utils 文件到 Framework

将以下文件添加到 `WatchProtocolSDK/Utils/`：

- [ ] `XLogger.swift`

---

### 步骤 4：验证文件结构

完成后，在 Xcode 左侧应该看到：

```
WatchProtocolSDK/
├── WatchProtocolSDK.h
├── Info.plist
├── Core/
│   ├── XGZTBlueToothManager.swift
│   ├── XGZTBusinessHandler.swift
│   ├── XGZTCommands.swift
│   ├── XGZTDeviceManager.swift
│   ├── XGZTCommandStateManager.swift
│   └── XGZTConnectionStateManager.swift
├── Models/
│   ├── XGZTSwitchDevice.swift
│   └── DatabaseManager.swift
├── Utils/
│   └── XLogger.swift
└── Public/
    (暂时为空)
```

同时，原位置的文件仍然存在：
```
SmartBracelet/
└── SmartBracelet/
    └── huaxin/
        └── WatchProtocol/
            ├── XGZTBlueToothManager.swift  (仍在这里)
            ├── ... (其他文件也在)
```

---

## ✅ 验证配置

### 验证 1：检查 Target Membership

1. 随机选中一个已添加的文件（如 `XGZTDeviceManager.swift`）
2. 在 File Inspector 中检查 Target Membership
3. 确认同时勾选了：
   - ☑️ `SmartBracelet`
   - ☑️ `WatchProtocolSDK`

### 验证 2：编译测试

1. 选择 Scheme：`WatchProtocolSDK`
2. 按 `⌘ + B` 编译

**预期结果**：
- ⚠️ **会有编译错误**（这是正常的）
- 错误主要是：
  - `Use of unresolved identifier 'Async'`
  - `Cannot find type 'BLEManager' in scope`
  - 访问权限问题

不用担心，这些错误我们会在下一阶段修复。

### 验证 3：检查文件数量

在终端运行：

```bash
# 检查 Framework 中的文件
find . -path "*/WatchProtocolSDK/*" -name "*.swift" | grep -v "/Pods/" | wc -l
```

应该输出：`9`（9 个 Swift 文件）

---

## 🎨 可选：整理主项目中的文件

由于文件现在同时属于两个 Target，你可以选择：

**选项 A：保持原样**（推荐）
- 文件保留在原位置
- Framework 只是引用这些文件
- 优点：主项目代码不需要修改导入路径

**选项 B：移动到 Framework 专用目录**
- 将文件从 `SmartBracelet/huaxin/WatchProtocol/` 移到专门的 Framework 源码目录
- 需要更新主项目的导入路径
- 优点：代码组织更清晰

**建议**：先保持原样（选项 A），等 Framework 完全可用后再考虑重组。

---

## 📊 完成状态检查

当前阶段完成后，你应该有：

- [x] 9 个文件已添加到 WatchProtocolSDK Target
- [x] 文件已组织到正确的 Group（Core/Models/Utils）
- [x] 所有文件的 Target Membership 正确设置
- [x] Framework 编译（虽然有错误）
- [ ] 编译错误已记录（下一阶段修复）

---

## 🎯 下一步预览

完成本阶段后，下一步将：

1. **创建公开 API 接口**
   - 在 `Public/` 中创建 `WPPublicAPI.swift`
   - 设计易用的公开接口

2. **处理编译错误**
   - 替换 `Async` 为 `DispatchQueue`
   - 处理 `BLEManager` 依赖
   - 添加 `public` 访问控制

3. **配置访问权限**
   - 为需要暴露的类添加 `public` 关键字
   - 设计 Framework 的 API 边界

---

## ⚠️ 常见问题

### Q1: 拖动文件时没有按住 Option 会怎样？
**A**: 文件会被移动而不是创建引用，导致原位置没有文件。如果发生了，按 `⌘ + Z` 撤销。

### Q2: Target Membership 列表中找不到 WatchProtocolSDK？
**A**:
- 确认你打开的是 `.xcworkspace` 而不是 `.xcodeproj`
- 重启 Xcode 并重新打开项目

### Q3: 文件添加后编译报错太多？
**A**: 这是正常的，主要错误类型：
- `Async` 未定义：需要替换为 `DispatchQueue`
- `BLEManager` 未定义：需要解耦或通过协议
- 访问权限：需要添加 `public` 关键字

我们会在下一阶段系统性修复这些问题。

### Q4: 可以只把文件加到 WatchProtocolSDK，不加到 SmartBracelet 吗？
**A**: 不建议。至少在过渡期，文件应该同时属于两个 Target，确保主应用不受影响。等 Framework 完全稳定后再考虑移除主应用的依赖。

---

## 📞 完成后通知

完成所有步骤后，请告诉我：

1. ✅ 9 个文件是否都已添加到 Framework
2. ✅ 文件是否正确组织到 Core/Models/Utils
3. ✅ 编译时的错误数量和主要类型
4. ✅ 是否遇到任何问题

我将根据编译错误的情况，准备下一阶段的修复工作。

---

**创建时间**: 2025-12-27
**文档版本**: 1.0
**预计完成时间**: 10-15 分钟
