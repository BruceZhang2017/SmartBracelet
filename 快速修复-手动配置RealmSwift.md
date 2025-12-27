# 快速修复：手动配置 RealmSwift（绕过 CocoaPods Bug）

> **问题**: CocoaPods 1.16.2 与 Xcode 16.4 不兼容
> **解决方案**: 直接在 Xcode 中手动配置，无需重新运行 `pod install`

---

## 🎯 快速步骤（5分钟）

### 步骤 1：打开 Xcode 项目

```bash
open SmartBracelet.xcworkspace
```

### 步骤 2：配置 Framework Search Paths

1. 点击左侧项目导航器最顶部的 **SmartBracelet** 项目（蓝色图标）

2. 在中间 **TARGETS** 列表中，选择 **WatchProtocolSDK**

3. 切换到 **Build Settings** 标签页

4. 在右上角搜索框输入：`framework search`

5. 找到 **Framework Search Paths** 设置项

6. 双击值区域（通常显示为 `$(inherited)`）

7. 点击 **+** 按钮，添加以下路径（每行一个）：
   ```
   $(inherited)
   "${PODS_CONFIGURATION_BUILD_DIR}/RealmSwift"
   "${PODS_CONFIGURATION_BUILD_DIR}/Realm"
   $(PROJECT_DIR)/Pods/RealmSwift
   $(PROJECT_DIR)/Pods/Realm/core
   ```

8. 每一行都设置为 **recursive**（递归搜索）

### 步骤 3：配置 Header Search Paths

1. 在同一个 **Build Settings** 页面

2. 搜索：`header search`

3. 找到 **Header Search Paths**

4. 双击值区域，添加：
   ```
   $(inherited)
   "${PODS_CONFIGURATION_BUILD_DIR}/RealmSwift/RealmSwift.framework/Headers"
   "${PODS_CONFIGURATION_BUILD_DIR}/Realm/Realm.framework/Headers"
   $(PROJECT_DIR)/Pods/Headers/Public
   $(PROJECT_DIR)/Pods/Headers/Public/Realm
   $(PROJECT_DIR)/Pods/Headers/Public/RealmSwift
   ```

### 步骤 4：配置 Other Linker Flags

1. 搜索：`other linker`

2. 找到 **Other Linker Flags**

3. 双击值区域，添加：
   ```
   $(inherited)
   -framework "RealmSwift"
   -framework "Realm"
   ```

### 步骤 5：清理并重新编译

1. 按 `⌘ + Shift + K` 清理项目

2. 按 `⌘ + B` 重新编译 WatchProtocolSDK

---

## ✅ 预期结果

编译后，`No such module 'RealmSwift'` 错误应该消失。

可能会出现其他错误（这是正常的）：

- ✅ `Use of unresolved identifier 'Async'` - 下一阶段修复
- ✅ `Cannot find type 'BLEManager'` - 下一阶段修复
- ✅ 访问权限问题 - 下一阶段修复

---

## 🔍 如果仍然报错

### 检查 1：验证 Build Settings

在终端运行：

```bash
xcodebuild -workspace SmartBracelet.xcworkspace \
  -scheme WatchProtocolSDK \
  -showBuildSettings | grep "FRAMEWORK_SEARCH_PATHS\|HEADER_SEARCH_PATHS"
```

应该看到包含 Pods 路径的输出。

### 检查 2：验证 Pods 文件是否存在

```bash
ls -la Pods/RealmSwift/
ls -la Pods/Realm/
```

应该看到目录存在。

### 检查 3：尝试使用绝对路径

如果相对路径不生效，在 Framework Search Paths 中使用绝对路径：

```
/Users/anker/Downloads/SmartBracelet/Pods/RealmSwift
/Users/anker/Downloads/SmartBracelet/Pods/Realm/core
```

---

## 📞 操作完成后

完成配置后，请告诉我：

1. ✅ `No such module 'RealmSwift'` 错误是否消失
2. ✅ 新出现的错误类型和数量
3. ✅ 是否需要进一步帮助

我将根据新的错误情况，进入下一阶段：修复 Async 依赖和创建公开 API。

---

**预计时间**: 5 分钟
**难度**: ⭐⭐☆☆☆

开始操作吧！ 💪
