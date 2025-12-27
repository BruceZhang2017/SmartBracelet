# 修复 WatchProtocolSDK 中的 RealmSwift 导入问题

> **问题**: `No such module 'RealmSwift'`
> **原因**: WatchProtocolSDK Target 未正确链接 Pods 中的 RealmSwift
> **解决方案**: 手动配置 Framework Search Paths 和链接

---

## 🎯 解决方案

由于 CocoaPods 与 Xcode 16.4 的兼容性问题，我们需要手动配置 RealmSwift 的链接。

### 方法 1：在 Xcode 中手动配置（推荐）

#### 步骤 1：配置 Framework Search Paths

1. 在 Xcode 中，选择项目导航器中的 **SmartBracelet** 项目（最顶部的蓝色图标）

2. 在 TARGETS 列表中，选择 **WatchProtocolSDK**

3. 切换到 **Build Settings** 标签页

4. 在右上角搜索框输入：`Framework Search Paths`

5. 找到 **Framework Search Paths** 设置项

6. 双击值区域，添加以下路径（点击 + 按钮）：
   ```
   $(inherited)
   $(PROJECT_DIR)/Pods/RealmSwift
   $(PROJECT_DIR)/Pods/Realm
   ```

7. 确保每一行都设置为 `recursive`（递归）

#### 步骤 2：链接 RealmSwift Framework

1. 保持选中 **WatchProtocolSDK** Target

2. 切换到 **Build Phases** 标签页

3. 展开 **Link Binary With Libraries** 部分

4. 点击左下角的 **+** 按钮

5. 在弹出窗口中，点击 **Add Other...** → **Add Files...**

6. 导航到项目目录下的 Pods 文件夹：
   ```
   SmartBracelet/Pods/RealmSwift/RealmSwift/
   ```

7. 选择 **RealmSwift.framework**（如果看不到，可能需要先编译 Pods 项目）

8. 点击 **Add**

9. 重复步骤 4-8，添加 **Realm.framework**：
   ```
   SmartBracelet/Pods/Realm/core/realm-monorepo.xcframework
   ```

#### 步骤 3：配置 Header Search Paths

1. 回到 **Build Settings** 标签页

2. 搜索：`Header Search Paths`

3. 双击值区域，添加：
   ```
   $(inherited)
   $(PROJECT_DIR)/Pods/Headers/Public
   $(PROJECT_DIR)/Pods/Headers/Public/RealmSwift
   $(PROJECT_DIR)/Pods/Headers/Public/Realm
   ```

4. 设置为 `recursive`

#### 步骤 4：清理并重新编译

1. 按 `⌘ + Shift + K` 清理项目

2. 按 `⌘ + B` 重新编译

---

### 方法 2：使用脚本自动配置（备选）

如果手动配置太复杂，可以尝试以下脚本：

```bash
#!/bin/bash

# 这个脚本会修改 project.pbxproj 文件，添加 Framework 搜索路径

PROJECT_FILE="SmartBracelet.xcodeproj/project.pbxproj"

# 备份项目文件
cp "$PROJECT_FILE" "${PROJECT_FILE}.backup"

# 添加 Framework Search Paths
# （注意：这个脚本需要根据实际的 project.pbxproj 结构调整）

echo "请使用方法1（手动配置）更可靠"
```

---

### 方法 3：简化 Podfile 配置

编辑 Podfile，将 WatchProtocolSDK 嵌套在 SmartBracelet target 中：

```ruby
platform :ios,'13.0'

use_frameworks!

target 'SmartBracelet' do
  source 'https://github.com/CocoaPods/Specs.git'
  source 'https://github.com/aliyun/aliyun-specs.git'

  # ... 其他 pods ...

  pod 'RealmSwift', '~> 10.13.0'
  pod 'Realm', '~> 10.13.0'

  # ... 其他 pods ...

  # WatchProtocolSDK 嵌套在内部
  target 'WatchProtocolSDK' do
    inherit! :search_paths
    # WatchProtocolSDK 会继承 SmartBracelet 的所有依赖
  end

  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['ENABLE_BITCODE'] ='NO'
        config.build_settings['ENABLE_STRICT_OBJC_MSGSEND'] = 'NO'
        config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'NO'
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      end
    end
  end
end
```

然后运行：
```bash
pod deintegrate
pod install
```

---

## ✅ 验证方法

配置完成后，验证是否成功：

### 1. 编译测试

```bash
# 选择 WatchProtocolSDK Scheme
# 按 ⌘ + B 编译
```

如果仍然报 `No such module 'RealmSwift'` 错误，检查：

- [ ] Framework Search Paths 是否正确添加
- [ ] Build Phases 中是否链接了 RealmSwift.framework
- [ ] Header Search Paths 是否正确配置

### 2. 检查 Build Settings

在终端运行：

```bash
xcodebuild -workspace SmartBracelet.xcworkspace \
  -scheme WatchProtocolSDK \
  -showBuildSettings | grep FRAMEWORK_SEARCH_PATHS
```

应该看到包含 Pods 路径的输出。

### 3. 检查链接的 Frameworks

```bash
xcodebuild -workspace SmartBracelet.xcworkspace \
  -scheme WatchProtocolSDK \
  -showBuildSettings | grep "OTHER_LDFLAGS\|FRAMEWORK_SEARCH_PATHS"
```

---

## 🔧 如果仍然失败

### 临时解决方案：直接在源文件中使用条件编译

在 DatabaseManager.swift 中：

```swift
#if canImport(RealmSwift)
import RealmSwift
#else
// Framework 暂时不使用 Realm
// 使用 UserDefaults 或其他替代方案
#endif
```

### 推荐方案：重新组织依赖

考虑将 Database 相关功能作为可选模块：

1. 在 Framework 中不直接依赖 RealmSwift
2. 通过协议定义数据存储接口
3. 主应用提供 Realm 实现

这样 Framework 可以更独立，减少外部依赖。

---

## 📞 需要帮助？

如果按照方法 1 配置后仍然无法解决，请告诉我：

1. Build Settings 中的 Framework Search Paths 内容
2. Build Phases → Link Binary With Libraries 的列表
3. 完整的编译错误信息

我会根据实际情况提供更具体的解决方案。

---

**创建时间**: 2025-12-27
**适用于**: Xcode 16.4 + CocoaPods 兼容性问题
