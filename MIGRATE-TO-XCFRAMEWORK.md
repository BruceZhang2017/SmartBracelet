# SmartBracelet 项目迁移指南
## 从 WatchFaceSDK 源代码迁移到 WatchFaceSDK.xcframework

---

## 📋 当前状态

SmartBracelet 项目目前同时包含:
- ✅ **WatchFaceSDK.xcframework** (已添加,来自 Output2)
- ⚠️ **WatchFaceSDK 源代码** (需要移除)

这会导致:
- 符号重复定义
- 编译冲突
- 不必要的源代码依赖

---

## 🎯 目标

移除 WatchFaceSDK 源代码引用,只使用 WatchFaceSDK.xcframework。

---

## 🔍 检查当前引用

### 源文件被编译到项目中

以下 WatchFaceSDK 源文件当前正在被编译:
- `WatchFaceManager.swift`
- `WatchFaceTransferEngine.swift`
- `WatchFaceInfo.swift`
- `WatchFaceSDK.swift`

### XCFramework 引用

✅ `WatchFaceSDK.xcframework` 已正确添加到:
- Frameworks, Libraries, and Embedded Content
- 设置为 "Embed & Sign"

---

## 📝 迁移步骤

### 方法 1: Xcode 图形界面操作 (推荐)

#### 步骤 1: 备份项目
```bash
# 创建备份
cp -R SmartBracelet.xcodeproj SmartBracelet.xcodeproj.backup
```

#### 步骤 2: 在 Xcode 中打开项目
```bash
open SmartBracelet.xcworkspace
```

#### 步骤 3: 移除 WatchFaceSDK 源代码

1. **在项目导航器 (⌘1) 中找到 "WatchFaceSDK" 文件夹**
   - 通常在项目根目录下
   - 包含 Core, Extensions, Models 等子文件夹

2. **右键点击 "WatchFaceSDK" 文件夹**
   - 选择 **"Delete"**

3. **在弹出的对话框中**
   - 选择 **"Remove Reference"** (不要选 "Move to Trash")
   - 这只会从项目中移除引用,不会删除磁盘上的文件

4. **验证移除成功**
   - 项目导航器中不应再看到 WatchFaceSDK 源代码文件夹
   - 但 WatchFaceSDK.xcframework 应该仍然存在

#### 步骤 4: 清理构建

1. **清理构建文件夹**
   - Product → Clean Build Folder (⌘⇧K)

2. **删除派生数据 (可选但推荐)**
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/SmartBracelet-*
   ```

#### 步骤 5: 重新编译

1. **选择目标设备或模拟器**
2. **编译项目 (⌘B)**
3. **检查编译输出**
   - 不应有 "duplicate symbol" 错误
   - 不应有 WatchFaceSDK 源文件相关的警告

#### 步骤 6: 测试功能

运行应用并测试表盘相关功能:
- [ ] 自定义表盘上传
- [ ] 市场表盘上传
- [ ] 表盘预览
- [ ] 传输进度显示

---

### 方法 2: 命令行脚本 (高级用户)

```bash
# 使用提供的清理脚本
chmod +x cleanup_watchface_sources.sh
./cleanup_watchface_sources.sh
```

**注意**: 脚本会自动备份项目文件。

---

## ✅ 验证清单

迁移完成后,请确认:

- [ ] 项目导航器中没有 WatchFaceSDK 源代码文件夹
- [ ] WatchFaceSDK.xcframework 存在于 Frameworks 中
- [ ] xcframework 设置为 "Embed & Sign"
- [ ] 项目成功编译,无错误
- [ ] 没有 "duplicate symbol" 警告
- [ ] 应用运行正常
- [ ] 表盘功能正常工作

---

## 🔍 检查引用情况

### 使用 grep 检查项目文件

```bash
# 检查是否还有源文件编译引用
grep "WatchFace.*\.swift in Sources" SmartBracelet.xcodeproj/project.pbxproj

# 如果没有输出,说明源文件已成功移除
```

```bash
# 确认 xcframework 引用存在
grep "WatchFaceSDK.xcframework" SmartBracelet.xcodeproj/project.pbxproj

# 应该看到 "in Frameworks" 和 "in Embed Frameworks"
```

---

## 🛠️ 故障排除

### 问题 1: 编译时出现 "duplicate symbol" 错误

**原因**: 源文件引用未完全移除

**解决**:
1. 重新执行移除步骤
2. 检查 Build Phases → Compile Sources
3. 确保没有 WatchFaceSDK 源文件

### 问题 2: 运行时找不到 WatchFaceSDK

**原因**: xcframework 未正确嵌入

**解决**:
1. Target → General → Frameworks, Libraries, and Embedded Content
2. 检查 WatchFaceSDK.xcframework 是否设置为 "Embed & Sign"
3. Clean Build 并重新编译

### 问题 3: 找不到 WatchFaceSDK 模块

**原因**: Framework Search Paths 配置问题

**解决**:
1. Target → Build Settings
2. 搜索 "Framework Search Paths"
3. 确保包含: `$(PROJECT_DIR)/Output2`

### 问题 4: 编译后仍有源文件相关警告

**解决**:
```bash
# 清理所有缓存
rm -rf ~/Library/Developer/Xcode/DerivedData/SmartBracelet-*
cd ~/Library/Developer/Xcode/DerivedData
find . -name "SmartBracelet-*" -exec rm -rf {} \;

# 在 Xcode 中
# Product → Clean Build Folder (⌘⇧K)
# 然后重新编译
```

---

## 📊 对比:迁移前后

### 迁移前

```
SmartBracelet Project
├── SmartBracelet (源代码)
├── WatchFaceSDK (源代码) ← 被编译到项目中
│   ├── Core
│   ├── Extensions
│   ├── Models
│   └── ...
├── Frameworks
│   └── WatchFaceSDK.xcframework ← 也被链接
```

**问题**: 源代码和 xcframework 同时存在,导致重复

### 迁移后

```
SmartBracelet Project
├── SmartBracelet (源代码)
├── Frameworks
│   └── WatchFaceSDK.xcframework ← 只使用 xcframework
```

**优势**:
- ✅ 无符号冲突
- ✅ 更清晰的依赖关系
- ✅ 更容易升级 SDK
- ✅ 编译更快

---

## 🎯 最佳实践

### 1. 使用 xcframework 的优势

- **版本管理**: 易于升级和回退
- **稳定性**: 使用已编译的二进制
- **性能**: 无需每次都编译源代码
- **安全性**: 修复的 bug (如 v1.0.3 的崩溃修复) 已包含

### 2. 保持源代码仓库独立

- WatchFaceSDK 源代码保留在 `WatchFaceSDK/` 目录
- 用于开发和调试
- 不应添加到 SmartBracelet target

### 3. 更新流程

当 WatchFaceSDK 有新版本时:
1. 重新编译 WatchFaceSDK.xcframework
2. 替换 Output2 中的 xcframework
3. SmartBracelet 项目自动使用新版本
4. Clean Build 并测试

---

## 📞 获取帮助

如果遇到问题:

1. **检查备份**
   ```bash
   ls -la SmartBracelet.xcodeproj.backup*
   ```

2. **恢复备份**
   ```bash
   # 如果需要恢复
   rm -rf SmartBracelet.xcodeproj
   cp -R SmartBracelet.xcodeproj.backup SmartBracelet.xcodeproj
   ```

3. **查看日志**
   - Xcode → Report Navigator (⌘9)
   - 检查编译日志

---

## ✅ 完成

迁移完成后,SmartBracelet 项目将:
- ✅ 只使用 WatchFaceSDK.xcframework
- ✅ 无源代码依赖
- ✅ 编译更快,更稳定
- ✅ 易于升级 SDK

**重要**: 确保使用 WatchFaceSDK v1.0.3 或更高版本,以避免崩溃问题!

---

**文档版本**: 1.0
**最后更新**: 2026-01-14
