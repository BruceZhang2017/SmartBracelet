# WatchProtocolSDK CocoaPods 发布指南

本指南详细说明如何将 WatchProtocolSDK 发布到 CocoaPods。

---

## 前置条件

### 1. 确保 GitHub 仓库已推送成功

在发布到 CocoaPods 之前，必须先完成 GitHub 仓库的推送：

```bash
# 按照 GitHub-PAT-Setup-Guide.md 创建 Personal Access Token

# 然后推送代码
cd /Users/anker/Downloads/HuaXinSDK
git push origin main
```

### 2. 为发布版本打 Git Tag

CocoaPods 需要通过 Git Tag 来标识版本：

```bash
cd /Users/anker/Downloads/HuaXinSDK

# 创建并推送 tag
git tag v1.0.1
git push origin v1.0.1
```

---

## CocoaPods 发布步骤

### 步骤 1: 注册 CocoaPods Trunk 账号（仅首次需要）

```bash
# 使用您的邮箱注册
pod trunk register 315082431@qq.com 'Xiaotengzxf' --description='WatchProtocolSDK Release'

# 系统会发送一封确认邮件到 315082431@qq.com
# 点击邮件中的链接完成验证
```

验证成功后，检查注册状态：

```bash
pod trunk me
```

### 步骤 2: 验证 Podspec 文件

在发布前，验证 podspec 文件是否正确：

```bash
cd /Users/anker/Downloads/HuaXinSDK

# 验证 podspec（会检查语法和依赖）
pod spec lint WatchProtocolSDK.podspec --allow-warnings
```

**注意事项**:
- 如果验证失败，根据错误提示修复问题
- `--allow-warnings` 允许有警告的情况下通过验证
- 如果是私有 pod，添加 `--private` 参数

### 步骤 3: 发布到 CocoaPods

验证通过后，发布到 CocoaPods：

```bash
cd /Users/anker/Downloads/HuaXinSDK

# 推送到 CocoaPods Trunk
pod trunk push WatchProtocolSDK.podspec --allow-warnings
```

发布成功后，会显示类似以下信息：
```
🎉  Congrats

 🚀  WatchProtocolSDK (1.0.1) successfully published
 📅  January 3rd, 10:00
 🌎  https://cocoapods.org/pods/WatchProtocolSDK
 👍  Tell your friends!
```

### 步骤 4: 验证发布

发布完成后（可能需要几分钟），验证是否可以搜索到：

```bash
# 搜索 pod
pod search WatchProtocolSDK

# 或更新本地 CocoaPods 仓库
pod repo update
pod search WatchProtocolSDK
```

---

## 在项目中使用

发布成功后，其他开发者可以通过以下方式集成：

### 方式 1: 使用 CocoaPods（公开发布）

在 `Podfile` 中添加：

```ruby
pod 'WatchProtocolSDK', '~> 1.0.1'
```

然后执行：
```bash
pod install
```

### 方式 2: 直接使用 GitHub（不发布到 CocoaPods）

如果不想公开发布到 CocoaPods，可以直接从 GitHub 安装：

```ruby
# 使用 Git 仓库
pod 'WatchProtocolSDK', :git => 'https://github.com/Xiaotengzxf/HuaXinSDK.git', :tag => 'v1.0.1'

# 或使用特定分支
pod 'WatchProtocolSDK', :git => 'https://github.com/Xiaotengzxf/HuaXinSDK.git', :branch => 'main'
```

### 方式 3: 使用私有 CocoaPods Spec 仓库

如果是企业内部使用，可以创建私有 Spec 仓库：

1. **创建私有 Spec 仓库**
```bash
# 在 GitHub 创建一个新的仓库，如 HuaXinSpecs
# 然后添加到 CocoaPods
pod repo add HuaXinSpecs https://github.com/Xiaotengzxf/HuaXinSpecs.git
```

2. **推送 Podspec 到私有仓库**
```bash
pod repo push HuaXinSpecs WatchProtocolSDK.podspec --allow-warnings
```

3. **在 Podfile 中使用**
```ruby
source 'https://github.com/Xiaotengzxf/HuaXinSpecs.git'
source 'https://github.com/CocoaPods/Specs.git'

pod 'WatchProtocolSDK', '~> 1.0.1'
```

---

## 常见问题

### Q1: 验证失败怎么办？

**A**: 查看错误信息并修复。常见问题：
- 源代码路径不正确：检查 `s.source_files`
- Git tag 不存在：确保已创建并推送 tag
- 依赖库版本问题：检查 `s.dependency`

### Q2: 如何更新已发布的版本？

**A**:
1. 修改代码
2. 更新 `podspec` 中的版本号
3. 提交并推送代码
4. 创建新的 Git tag
5. 重新验证并推送 podspec

```bash
# 更新版本示例（v1.0.2）
git add .
git commit -m "Update to v1.0.2"
git tag v1.0.2
git push origin main
git push origin v1.0.2
pod trunk push WatchProtocolSDK.podspec --allow-warnings
```

### Q3: 如何删除已发布的版本？

**A**:
```bash
# 删除指定版本
pod trunk delete WatchProtocolSDK 1.0.1

# 注意：删除后无法恢复，谨慎操作
```

### Q4: 推送时提示"Unable to find a pod with name"

**A**: 这是正常的首次发布提示，继续执行即可。

---

## 完整发布流程总结

```bash
# 1. 推送代码到 GitHub
cd /Users/anker/Downloads/HuaXinSDK
git add .
git commit -m "Release WatchProtocolSDK v1.0.1"
git push origin main

# 2. 创建并推送 Git Tag
git tag v1.0.1
git push origin v1.0.1

# 3. 注册 CocoaPods（仅首次）
pod trunk register 315082431@qq.com 'Xiaotengzxf'
# 检查邮箱并点击验证链接

# 4. 验证 Podspec
pod spec lint WatchProtocolSDK.podspec --allow-warnings

# 5. 发布到 CocoaPods
pod trunk push WatchProtocolSDK.podspec --allow-warnings

# 6. 验证发布
pod search WatchProtocolSDK
```

---

## 推荐使用方式

对于企业内部使用，我们**推荐使用方式 2**（直接从 GitHub 安装），理由：

✅ **优点**:
- 无需注册 CocoaPods Trunk 账号
- 更快的发布速度（不需要等待 CocoaPods 审核）
- 更好的版本控制（通过 Git Tag）
- 企业内部可控

❌ **缺点**:
- 需要访问 GitHub 仓库权限
- 不能通过 `pod search` 搜索到

如果需要公开发布给所有开发者使用，则选择发布到 CocoaPods。

---

**准备好后，按照上述步骤操作即可！**

如有问题，请联系技术支持。
