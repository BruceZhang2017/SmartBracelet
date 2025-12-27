# Xcode 操作步骤 - 创建 WatchProtocolSDK Framework

> **当前阶段**: 在 Xcode 中创建 Framework Target
> **预计时间**: 15-20 分钟
> **难度**: ⭐⭐☆☆☆

---

## 📋 操作前检查

- [x] 代码已提交到 Git（提交哈希: 24de6fc）
- [x] 三个管理器已创建并集成
- [x] 文档和配置文件已准备就绪
- [ ] Xcode 已关闭（建议在操作前关闭）

---

## 🎯 第一步：打开项目

1. **双击打开项目**
   ```
   文件路径: /Users/anker/Downloads/SmartBracelet/SmartBracelet.xcodeproj
   ```

2. **等待 Xcode 完全加载**
   - 等待索引完成（顶部状态栏显示 "Indexing..."）
   - 确保没有编译错误

---

## 🔨 第二步：创建 Framework Target

### 2.1 打开新 Target 创建向导

1. 点击菜单栏：**File → New → Target...**

   或使用快捷键：`⌘ + Control + N`

### 2.2 选择模板

1. 在弹出的窗口左侧选择：**iOS**
2. 在右侧模板列表中找到并点击：**Framework**
   - 图标是一个蓝色的盒子，写着 "Framework"
3. 点击右下角：**Next**

### 2.3 配置 Framework 信息

在配置页面填写以下信息：

| 字段 | 值 | 说明 |
|------|-----|------|
| **Product Name** | `WatchProtocolSDK` | Framework 的名称 |
| **Organization Name** | （保持默认） | 你的组织名称 |
| **Organization Identifier** | （保持默认） | 通常是反向域名 |
| **Language** | `Swift` | ⚠️ 必须选择 Swift |
| **Project** | `SmartBracelet` | 应该已自动选中 |
| **Embed in Application** | 不勾选 | 稍后手动配置 |
| **Include Tests** | ✅ 勾选 | 建议勾选，方便测试 |

4. 点击：**Finish**

### 2.4 验证创建结果

创建完成后，检查以下内容：

- [x] 左侧导航栏出现 `WatchProtocolSDK` 文件夹
  - 包含 `WatchProtocolSDK.h` 文件
  - 包含 `Info.plist` 文件

- [x] 项目设置中出现新 Target
  - 点击左侧项目名称（最顶部的蓝色图标）
  - 在中间 TARGETS 列表中看到 `WatchProtocolSDK`

- [x] Scheme 已自动创建
  - 顶部工具栏的 Scheme 选择器中能看到 `WatchProtocolSDK`

---

## ⚙️ 第三步：配置 Build Settings

### 3.1 选择 WatchProtocolSDK Target

1. 点击左侧项目名称（蓝色图标）
2. 在中间 TARGETS 列表中点击：`WatchProtocolSDK`
3. 确保顶部选中了 `Build Settings` 标签页

### 3.2 配置关键设置

#### 方法 1：搜索配置（推荐）

在 Build Settings 右上角的搜索框中输入设置名称，然后修改：

1. **搜索**: `iOS Deployment Target`
   - 修改为：`12.0`
   - 双击值区域即可编辑

2. **搜索**: `Build Libraries for Distribution`
   - 修改为：`Yes`
   - ⚠️ **非常重要**：这确保 Framework 可以跨 Swift 版本使用

3. **搜索**: `Defines Module`
   - 确认为：`Yes`（通常已自动设置）

4. **搜索**: `Skip Install`
   - 修改为：`No`

5. **搜索**: `Swift Language Version`
   - 确认为：`Swift 5`

#### 方法 2：在 General 中配置（部分设置）

1. 切换到 `General` 标签页
2. 在 `Deployment Info` 部分：
   - **iOS Deployment Target**: 选择 `12.0`
3. 在 `Identity` 部分：
   - **Version**: 填写 `1.0.0`
   - **Build**: 填写 `1`

### 3.3 验证配置

切换回 `Build Settings`，在搜索框清空，滚动查看是否所有设置正确。

---

## 📁 第四步：创建目录结构

### 4.1 在 WatchProtocolSDK 下创建 Groups

1. 右键点击 `WatchProtocolSDK` 文件夹
2. 选择：**New Group**
3. 创建以下 4 个 Group：

   - `Core` - 核心业务类
   - `Models` - 数据模型
   - `Utils` - 工具类
   - `Public` - 公开 API

**操作技巧**：
- 重命名 Group：点击 Group 名称，再次点击即可编辑
- 拖动调整顺序：按住 Group 拖动到合适位置

### 4.2 验证目录结构

完成后的结构应该是：

```
WatchProtocolSDK/
├── WatchProtocolSDK.h
├── Info.plist
├── Core/
├── Models/
├── Utils/
└── Public/
```

---

## 🔗 第五步：配置系统框架依赖

### 5.1 添加系统框架

1. 确保选中 `WatchProtocolSDK` Target
2. 切换到 `Build Phases` 标签页
3. 展开 `Link Binary With Libraries` 部分
4. 点击左下角的 `+` 按钮

依次添加以下框架（每次点击 `+` 添加一个）：

- [ ] **Foundation.framework**
  - 搜索 "Foundation"，点击添加

- [ ] **CoreBluetooth.framework**
  - 搜索 "CoreBluetooth"，点击添加

- [ ] **UIKit.framework**
  - 搜索 "UIKit"，点击添加

### 5.2 验证框架添加

在 `Link Binary With Libraries` 列表中应该看到：
```
Foundation.framework
CoreBluetooth.framework
UIKit.framework
```

---

## 📦 第六步：配置 CocoaPods 依赖

### 6.1 编辑 Podfile

1. 在 Xcode 中，**关闭项目**（`File → Close Workspace` 或 `⌘ + W`）

2. 用文本编辑器打开 Podfile：
   ```bash
   open -a Xcode Podfile
   ```

3. 在 Podfile 末尾添加以下内容：

   ```ruby
   # WatchProtocolSDK Framework Target
   target 'WatchProtocolSDK' do
     pod 'RealmSwift', '~> 10.0'
   end
   ```

4. 保存文件（`⌘ + S`）

### 6.2 安装依赖

在终端中运行：

```bash
cd /Users/anker/Downloads/SmartBracelet
pod install
```

等待安装完成，应该看到类似输出：
```
Analyzing dependencies
Downloading dependencies
Installing RealmSwift (10.x.x)
Generating Pods project
Integrating client project
```

### 6.3 重新打开项目

⚠️ **重要**：现在必须使用 `.xcworkspace` 文件打开项目

```bash
open SmartBracelet.xcworkspace
```

或双击 `SmartBracelet.xcworkspace` 文件

---

## ✅ 第七步：验证配置

### 7.1 检查 Pods 集成

1. 在左侧导航栏，应该看到两个项目：
   - `SmartBracelet`（你的主项目）
   - `Pods`（依赖项目）

2. 展开 `Pods` → `Pods` → `RealmSwift`，确认库已添加

### 7.2 首次编译测试

1. 选择 Scheme：`WatchProtocolSDK`
   - 点击顶部工具栏左侧的 Scheme 选择器
   - 选择 `WatchProtocolSDK`

2. 选择目标设备：
   - 点击 Scheme 右侧的设备选择器
   - 选择 `Any iOS Device (arm64)`

3. 执行编译：
   - 按 `⌘ + B` 或点击菜单 `Product → Build`

4. 预期结果：
   - ✅ **编译成功**（绿色勾号）
   - 或者显示 "Build Succeeded"

   如果有错误，暂时不用担心，我们稍后会添加代码。

---

## 📊 完成状态检查

当前阶段完成后，你应该有：

- [x] WatchProtocolSDK Target 已创建
- [x] Build Settings 已正确配置
- [x] 目录结构已创建（Core、Models、Utils、Public）
- [x] 系统框架已添加（Foundation、CoreBluetooth、UIKit）
- [x] CocoaPods 依赖已配置（RealmSwift）
- [x] 项目能够编译（即使是空的）

---

## 🎯 下一步预览

完成上述步骤后，下一阶段将：

1. 将 WatchProtocol 目录下的文件添加到 Framework
2. 创建公开 API 接口
3. 处理编译错误（如 Async 依赖）
4. 在主项目中集成 Framework
5. 进行功能测试

---

## ⚠️ 常见问题

### Q1: 找不到 Framework 模板？
**A**: 确保选择的是 **iOS** 平台，而不是 macOS 或其他平台。

### Q2: CocoaPods 安装失败？
**A**:
```bash
# 更新 CocoaPods 仓库
pod repo update

# 清理缓存后重试
pod cache clean --all
pod install
```

### Q3: 编译失败提示找不到 RealmSwift？
**A**:
- 确认已运行 `pod install`
- 确认使用 `.xcworkspace` 而非 `.xcodeproj` 打开项目
- 重启 Xcode

### Q4: Build Libraries for Distribution 找不到？
**A**:
- 确保在 `Build Settings` 中，过滤器设置为 `All`（而非 `Basic`）
- 在搜索框中输入完整名称：`Build Libraries for Distribution`

---

## 📞 完成后通知

完成所有步骤后，请告诉我：

1. 是否所有步骤都成功完成
2. 是否遇到任何错误或警告
3. 首次编译的结果（成功/失败）

我将根据你的反馈继续下一阶段的工作。

---

**创建时间**: 2025-12-27
**文档版本**: 1.0
**预计完成时间**: 15-20 分钟
