# 最终修复：RealmSwift 导入问题

> **根本原因**: WatchProtocolSDK 的 Framework Search Paths 配置不正确
> **解决方案**: 使用正确的路径指向 DerivedData 中编译好的 framework

---

## 🎯 精确的修复步骤（在 Xcode 中操作）

### 步骤 1：打开项目

```bash
open SmartBracelet.xcworkspace
```

### 步骤 2：选择 WatchProtocolSDK Target

1. 点击左侧项目导航器最顶部的 **SmartBracelet** 项目（蓝色图标）
2. 在中间 TARGETS 列表中，选择 **WatchProtocolSDK**
3. 切换到 **Build Settings** 标签页

### 步骤 3：清空并重新配置 Framework Search Paths

1. 在右上角搜索框输入：`framework search`

2. 找到 **Framework Search Paths** 设置项

3. **删除所有现有的路径**（包括那些错误的路径）

4. 双击值区域，点击 **+** 按钮，**只添加**以下路径：

```
$(inherited)
$(BUILD_DIR)/$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)/RealmSwift
$(BUILD_DIR)/$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)/Realm
```

5. 确保这两行都设置为 **non-recursive**（非递归）

### 步骤 4：清空并重新配置 Header Search Paths

1. 搜索：`header search`

2. 找到 **Header Search Paths**

3. **删除所有现有的路径**

4. 双击值区域，添加：

```
$(inherited)
$(BUILD_DIR)/$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)/RealmSwift/RealmSwift.framework/Headers
$(BUILD_DIR)/$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)/Realm/Realm.framework/Headers
```

### 步骤 5：配置 Other Linker Flags

1. 搜索：`other linker`

2. 找到 **Other Linker Flags**

3. 双击值区域，确保有：

```
$(inherited)
-framework "RealmSwift"
-framework "Realm"
```

### 步骤 6：清理并重新编译

1. 按 `⌘ + Shift + K` 清理项目

2. 按 `⌘ + B` 重新编译 WatchProtocolSDK

---

## ✅ 预期结果

编译后，`No such module 'RealmSwift'` 错误应该**完全消失**。

可能会出现其他错误（这是正常的，我们下一步修复）：

- ✅ `Use of unresolved identifier 'Async'`
- ✅ `Cannot find type 'BLEManager' in scope`
- ✅ `'XGZTDeviceManager' is internal and cannot be referenced...`

---

## 🔍 为什么使用这些路径？

### `$(BUILD_DIR)/$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)`

这个变量展开后是：
```
/Users/anker/Library/Developer/Xcode/DerivedData/SmartBracelet-xxx/Build/Products/Debug-iphoneos
```

这是 Xcode 存放编译产物的地方，RealmSwift 和 Realm 的 framework 都在这里。

### 为什么不使用 Pods 目录？

因为 Pods 目录下只有**源代码**，不是编译好的 framework。
CocoaPods 会将源代码编译成 framework 放到 DerivedData 中。

---

## 🆘 如果仍然失败

### 方法 1：验证 framework 是否存在

在终端运行：

```bash
ls -la ~/Library/Developer/Xcode/DerivedData/SmartBracelet-*/Build/Products/Debug-iphoneos/RealmSwift/RealmSwift.framework
```

如果文件不存在，先编译主项目：

```bash
xcodebuild -workspace SmartBracelet.xcworkspace \
  -scheme SmartBracelet \
  -sdk iphonesimulator \
  -configuration Debug \
  build
```

### 方法 2：先编译 SmartBracelet，再编译 WatchProtocolSDK

RealmSwift 需要先被主项目编译出来，才能被 Framework 使用。

在 Xcode 中：

1. 选择 Scheme: **SmartBracelet**
2. ⌘+B 编译
3. 等待编译完成
4. 选择 Scheme: **WatchProtocolSDK**
5. ⌘+B 编译

### 方法 3：检查 Scheme 依赖

1. 点击顶部工具栏的 Scheme 选择器 → **Edit Scheme...**
2. 左侧选择 **Build**
3. 确保 **SmartBracelet** 在 **WatchProtocolSDK** 之前编译
4. 如果不是，拖动调整顺序

---

## 📞 完成后告诉我

配置完成并编译后，请告诉我：

1. ✅ `No such module 'RealmSwift'` 是否消失
2. ✅ 新的错误类型和数量
3. ✅ 错误信息的前几行

我将立即帮你修复剩下的错误！

---

**创建时间**: 2025-12-27 21:10
**预计时间**: 5 分钟
