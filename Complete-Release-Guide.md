# WatchProtocolSDK 完整发布指南

本指南整合了 GitHub 上传和 CocoaPods 发布的完整流程。

---

## 📋 目录

1. [当前状态](#当前状态)
2. [GitHub 推送步骤](#github-推送步骤)
3. [CocoaPods 发布步骤](#cocoapods-发布步骤)
4. [推荐使用方式](#推荐使用方式)
5. [后续维护](#后续维护)

---

## 当前状态

✅ **已完成**:
- ✅ SDK 编译成功（WatchProtocolSDK.xcframework）
- ✅ 生成完整的中英文接入文档
- ✅ 代码已提交到本地 Git 仓库
- ✅ 创建 CocoaPods podspec 文件
- ✅ 添加 MIT License

⏳ **待完成**:
- ⏳ 推送代码到 GitHub（需要 Personal Access Token）
- ⏳ 创建 Git Tag (v1.0.1)
- ⏳ 发布到 CocoaPods（可选）

---

## GitHub 推送步骤

### 步骤 1: 创建 Personal Access Token

由于 GitHub 不再支持密码认证，需要创建 Personal Access Token (PAT)：

1. **登录 GitHub**: https://github.com（账号: 315082431@qq.com）
2. **进入设置**: 右上角头像 -> Settings
3. **创建 Token**:
   - 左侧菜单: Developer settings -> Personal access tokens -> Tokens (classic)
   - 点击 "Generate new token (classic)"
4. **配置 Token**:
   - Note: "WatchProtocolSDK Upload"
   - Expiration: 90 days 或 No expiration
   - Scopes: 勾选 `repo` (完整仓库权限)
5. **保存 Token**: 复制生成的 token（格式: `ghp_xxxxxxxxxxxxxxxxxxxx`）

### 步骤 2: 推送代码到 GitHub

```bash
cd /Users/anker/Downloads/HuaXinSDK

# 方式 1: 直接推送（会提示输入凭证）
git push origin main

# 提示时输入:
# Username: Xiaotengzxf
# Password: [粘贴您的 Personal Access Token]

# 方式 2: 在 URL 中包含 token（不推荐，token 会保存在配置中）
# git remote set-url origin https://YOUR_TOKEN@github.com/Xiaotengzxf/HuaXinSDK.git
# git push origin main
```

### 步骤 3: 创建并推送 Git Tag

```bash
cd /Users/anker/Downloads/HuaXinSDK

# 创建 tag
git tag v1.0.1

# 推送 tag
git push origin v1.0.1

# 验证 tag 是否推送成功
git ls-remote --tags origin
```

推送成功后，可以在 GitHub 上看到：
- 仓库地址: https://github.com/Xiaotengzxf/HuaXinSDK
- Tag: https://github.com/Xiaotengzxf/HuaXinSDK/releases/tag/v1.0.1

---

## CocoaPods 发布步骤

### 选项 A: 公开发布到 CocoaPods（推荐给所有开发者使用）

#### 1. 注册 CocoaPods Trunk（仅首次）

```bash
pod trunk register 315082431@qq.com 'Xiaotengzxf' --description='WatchProtocolSDK Release'

# 检查邮箱 315082431@qq.com，点击验证链接

# 验证注册成功
pod trunk me
```

#### 2. 验证 Podspec

```bash
cd /Users/anker/Downloads/HuaXinSDK

pod spec lint WatchProtocolSDK.podspec --allow-warnings
```

#### 3. 发布到 CocoaPods

```bash
pod trunk push WatchProtocolSDK.podspec --allow-warnings
```

#### 4. 使用方式

其他开发者在 Podfile 中添加：

```ruby
pod 'WatchProtocolSDK', '~> 1.0.1'
```

### 选项 B: 仅使用 GitHub（企业内部推荐）

**优点**:
- ✅ 无需注册 CocoaPods
- ✅ 发布更快（无需审核）
- ✅ 版本完全可控

**使用方式**:

在 Podfile 中添加：

```ruby
# 使用指定 tag
pod 'WatchProtocolSDK', :git => 'https://github.com/Xiaotengzxf/HuaXinSDK.git', :tag => 'v1.0.1'

# 或使用最新的 main 分支
pod 'WatchProtocolSDK', :git => 'https://github.com/Xiaotengzxf/HuaXinSDK.git', :branch => 'main'
```

然后执行：
```bash
pod install
```

---

## 推荐使用方式

### 🎯 企业内部使用：选项 B（仅 GitHub）

**理由**:
1. 更快的发布和更新速度
2. 完全控制版本发布
3. 无需依赖 CocoaPods 公共仓库
4. 支持私有仓库（如果设为 private）

### 🎯 公开分发给所有开发者：选项 A（CocoaPods）

**理由**:
1. 方便开发者搜索和发现
2. 标准化的依赖管理
3. 版本自动更新通知

---

## 后续维护

### 发布新版本（例如 v1.0.2）

```bash
cd /Users/anker/Downloads/SmartBracelet

# 1. 修改代码
# 2. 更新版本号
# 编辑 WatchProtocolSDK/Version.swift 和 WatchProtocolSDK.podspec

# 3. 重新编译
xcodebuild -scheme WatchProtocolSDK -configuration Release -destination 'generic/platform=iOS' build
xcodebuild -scheme WatchProtocolSDK -configuration Release -destination 'generic/platform=iOS Simulator' build

# 4. 创建新的 xcframework
rm -rf Output/WatchProtocolSDK.xcframework
xcodebuild -create-xcframework \
    -framework [...]/Release-iphoneos/WatchProtocolSDK.framework \
    -framework [...]/Release-iphonesimulator/WatchProtocolSDK.framework \
    -output Output/WatchProtocolSDK.xcframework

# 5. 复制到 GitHub 仓库
cp -R Output/* /Users/anker/Downloads/HuaXinSDK/WatchProtocolSDK/v1.0.2/

# 6. 提交并推送
cd /Users/anker/Downloads/HuaXinSDK
git add .
git commit -m "Release v1.0.2"
git push origin main

# 7. 创建新 tag
git tag v1.0.2
git push origin v1.0.2

# 8. 如果使用 CocoaPods，重新发布
pod trunk push WatchProtocolSDK.podspec --allow-warnings
```

---

## 快速命令总结

### 首次发布

```bash
# 1. GitHub 推送（需要先创建 PAT）
cd /Users/anker/Downloads/HuaXinSDK
git push origin main
git tag v1.0.1
git push origin v1.0.1

# 2. CocoaPods 发布（可选）
pod trunk register 315082431@qq.com 'Xiaotengzxf'
# 验证邮箱后
pod spec lint WatchProtocolSDK.podspec --allow-warnings
pod trunk push WatchProtocolSDK.podspec --allow-warnings
```

### 使用 SDK（推荐方式）

```ruby
# Podfile
pod 'WatchProtocolSDK', :git => 'https://github.com/Xiaotengzxf/HuaXinSDK.git', :tag => 'v1.0.1'
```

---

## 文件位置说明

```
/Users/anker/Downloads/SmartBracelet/
├── Output/                                          # SDK 输出目录
│   ├── WatchProtocolSDK.xcframework                 # 编译好的 framework
│   ├── VERSION.txt                                  # 版本信息
│   ├── README.md                                    # 快速开始指南
│   ├── WatchProtocolSDK-接入文档-中文.md            # 中文完整文档
│   └── WatchProtocolSDK-Integration-Guide-EN.md    # 英文完整文档
├── WatchProtocolSDK.podspec                         # CocoaPods 配置
├── LICENSE                                          # 许可证
├── GitHub-PAT-Setup-Guide.md                       # GitHub Token 设置指南
├── CocoaPods-Release-Guide.md                      # CocoaPods 详细指南
└── Complete-Release-Guide.md                       # 本文件（完整发布指南）

/Users/anker/Downloads/HuaXinSDK/                    # GitHub 仓库
├── WatchProtocolSDK/
│   ├── README.md                                    # SDK 说明
│   ├── LICENSE                                      # 许可证
│   └── v1.0.1/                                      # 版本目录
│       ├── WatchProtocolSDK.xcframework
│       ├── VERSION.txt
│       ├── README.md
│       ├── WatchProtocolSDK-接入文档-中文.md
│       └── WatchProtocolSDK-Integration-Guide-EN.md
└── WatchProtocolSDK.podspec                         # CocoaPods 配置
```

---

## 疑难解答

### Q: 推送 GitHub 失败，提示 403 错误？
**A**: 需要使用 Personal Access Token 而不是密码。参考 `GitHub-PAT-Setup-Guide.md`。

### Q: pod spec lint 失败？
**A**:
1. 确保 GitHub tag 已推送
2. 检查 podspec 中的 URL 是否正确
3. 使用 `--verbose` 查看详细错误

### Q: 如何撤销已发布的版本？
**A**:
- GitHub: 删除 tag 后重新推送
- CocoaPods: `pod trunk delete WatchProtocolSDK 1.0.1`（谨慎操作）

---

**准备好后，开始第一步：创建 Personal Access Token 并推送到 GitHub！**

有任何问题，请参考对应的详细指南文档。
