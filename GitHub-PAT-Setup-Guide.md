# GitHub Personal Access Token 设置指南

## 为什么需要 PAT？

GitHub 已于 2021 年 8 月 13 日停止支持使用密码进行 HTTPS Git 操作的身份验证。现在需要使用 Personal Access Token (PAT)。

## 创建 Personal Access Token 的步骤

### 1. 登录 GitHub
- 访问 https://github.com
- 使用账号 315082431@qq.com 登录

### 2. 进入设置页面
- 点击右上角头像
- 选择 "Settings"（设置）

### 3. 创建 Token
1. 在左侧菜单中，滚动到底部，点击 "Developer settings"（开发者设置）
2. 点击 "Personal access tokens" -> "Tokens (classic)"
3. 点击 "Generate new token" -> "Generate new token (classic)"

### 4. 配置 Token
- **Note**: 填写描述，如 "WatchProtocolSDK Upload"
- **Expiration**: 选择过期时间（建议选择 90 days 或 No expiration）
- **Select scopes**: 勾选以下权限
  - ✅ `repo` (完整的仓库访问权限)
    - 这会自动勾选所有子选项

### 5. 生成并保存 Token
1. 点击页面底部的 "Generate token" 按钮
2. **重要**: 复制显示的 token（类似：`ghp_xxxxxxxxxxxxxxxxxxxx`）
3. **保存这个 token**，离开页面后将无法再次查看

## 使用 Token 推送代码

创建 Token 后，在终端中使用以下命令推送：

```bash
cd /Users/anker/Downloads/HuaXinSDK

# 更新远程仓库 URL（使用 token）
git remote set-url origin https://YOUR_TOKEN@github.com/Xiaotengzxf/HuaXinSDK.git

# 推送代码
git push origin main
```

**注意**: 将 `YOUR_TOKEN` 替换为您刚才创建的 Personal Access Token。

## 或者使用 Git Credential Manager

推送时会提示输入用户名和密码：
- **Username**: Xiaotengzxf（或 315082431@qq.com）
- **Password**: 粘贴您的 Personal Access Token（不是密码）

---

## 快速命令（创建 Token 后使用）

```bash
# 方法 1: 在 URL 中包含 token
git remote set-url origin https://YOUR_TOKEN@github.com/Xiaotengzxf/HuaXinSDK.git
git push origin main

# 方法 2: 推送时输入凭证
git push origin main
# 提示时输入：
# Username: Xiaotengzxf
# Password: YOUR_TOKEN
```

---

**安全提示**:
- 不要将 Token 分享给他人
- 不要将包含 Token 的 URL 提交到代码仓库
- 定期更新 Token
- 如果 Token 泄露，立即在 GitHub 上删除该 Token
