# 运行到当前连接 iPhone 计划

## Summary
- 目标：将当前工程运行到已连接的 iPhone 真机上。
- 执行入口：使用 `SmartBracelet.xcworkspace`、`SmartBracelet` scheme、`Debug` 配置。
- 目标设备：`iPhone (26.5)`，UDID 为 `00008101-001828D22E06001E`。

## Current State Analysis
- 工程同时存在 `Podfile`、`Pods/`、`SmartBracelet.xcworkspace`，说明真机构建应优先走 workspace，而不是单独的 `.xcodeproj`。
- `xcodebuild -list -project SmartBracelet.xcodeproj` 显示：
  - Target：`SmartBracelet`
  - Scheme：`SmartBracelet`
- `xcrun xctrace list devices` 显示当前有一台在线真机：
  - `iPhone (26.5) (00008101-001828D22E06001E)`
- `xcodebuild -showBuildSettings` 显示：
  - `PRODUCT_NAME = FitDAY`
  - `PRODUCT_BUNDLE_IDENTIFIER = com.sinophy.uwatch`
  - `DEVELOPMENT_TEAM = 6BTCM549U7`
  - `CODE_SIGN_STYLE = Automatic`
- 当前最可能的真机运行阻塞点不是工程入口不明确，而是：
  - 签名证书或描述文件不可用
  - 设备未在本机 Xcode 上完成信任
  - Pods/第三方依赖在 workspace 下仍有环境缺口

## Proposed Changes

### 1. 用 workspace 做一次真机构建
- 文件/入口：`/Users/bruce/SmartBracelet/SmartBracelet.xcworkspace`
- 执行方式：
  - 使用 `xcodebuild -workspace SmartBracelet.xcworkspace -scheme SmartBracelet -configuration Debug -destination 'id=00008101-001828D22E06001E' build`
- 目的：
  - 验证当前工程在真实设备目标下能否完成编译和签名。

### 2. 若构建通过，安装并启动到当前 iPhone
- 执行方式：
  - 先通过 `xcodebuild` 完成真机目标产物生成。
  - 再使用系统提供的设备安装/启动命令将 `FitDAY.app` 装到 `00008101-001828D22E06001E`。
- 目的：
  - 完成“运行到我当前连接的 iPhone 手机上”这一目标，而不只是本地编译。

### 3. 若失败，收敛到明确阻塞点
- 优先输出以下类别的错误归因：
  - 签名/描述文件问题
  - 设备信任问题
  - Pods 或 Framework 链接问题
  - 代码编译错误
- 结果要求：
  - 给出精确错误摘要和下一步最小修复动作，不做泛泛建议。

## Assumptions & Decisions
- 默认用户要运行的是当前仓库的主工程，而不是 `fitherenew`。
- 默认使用在线设备 `00008101-001828D22E06001E`，因为它是当前唯一在线的 iPhone 真机。
- 默认优先使用 `SmartBracelet.xcworkspace`，因为仓库存在 CocoaPods 结构。
- 默认保持现有签名配置，不主动改 bundle id、team 或 provisioning 设置，除非执行阶段被签名错误明确阻塞。

## Verification Steps
1. 确认真机仍在线：`xcrun xctrace list devices`
2. 真机构建：`xcodebuild -workspace SmartBracelet.xcworkspace -scheme SmartBracelet -configuration Debug -destination 'id=00008101-001828D22E06001E' build`
3. 如构建成功，定位产物中的 `FitDAY.app`
4. 安装到目标设备并启动
5. 返回结果：
   - 成功：说明已安装并启动到真机
   - 失败：提供首个有效错误与下一步处理建议
