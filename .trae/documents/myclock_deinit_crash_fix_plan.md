# MyClockViewController 崩溃修复计划

## Summary
- 目标：修复 `FitDAY 2.6.5 (7)` 在表盘管理页返回/释放链路中的崩溃。
- 成功标准：
  - 不再出现崩溃栈中的 `objc_initWeak` / `_os_unfair_lock_recursive_abort`
  - `MyClockViewController` 从导航栈移除时可正常释放
  - 不引入表盘上传弹窗无法关闭、回调丢失、通知残留等回归
- 本次范围：按用户选择，采用最小热修，只修复崩溃栈直接命中的释放逻辑，并验证紧邻同类入口。

## Current State Analysis
- 崩溃栈关键链路：
  - `objc_initWeak`
  - `MyClockViewController.__deallocating_deinit`
  - `ClockManageViewController.__deallocating_deinit`
- 代码对应位置：
  - [MyClockViewController.swift](file:///Users/bruce/SmartBracelet/SmartBracelet/Device/ClockManage/MyClockViewController.swift#L109-L120)
  - [ClockManageViewController.swift](file:///Users/bruce/SmartBracelet/SmartBracelet/Device/ClockManage/ClockManageViewController.swift#L79-L80)
  - [UploadImageViewController.swift](file:///Users/bruce/SmartBracelet/SmartBracelet/Device/ClockManage/UploadImageViewController.swift#L118-L123)
- 已确认的高概率根因：
  - `MyClockViewController.deinit` 内存在：
    - `imageUploadVc?.dismiss(animated: false, completion: { [weak self] in self?.imageUploadVc = nil })`
  - 当 `self` 已进入 `deallocating_deinit` 阶段时，再创建 `[weak self]` 会命中崩溃栈里的 `objc_initWeak`。
  - 这与系统报错 `FOUNDATION 1`、`_os_unfair_lock_recursive_abort`、`objc_initWeak` 的组合完全吻合。
- 相关但非直接根因的邻近代码：
  - `UploadImageViewController.handleStop()` 也用了 `dismiss(animated: false) { [weak self] ... }`
  - 该处不在本次栈上，但与页面销毁路径相关，需要在修复时确认不会形成新的释放时序问题。

## Proposed Changes

### 1. 修复 `MyClockViewController.deinit` 中的非法 weak 初始化
- 文件：`/Users/bruce/SmartBracelet/SmartBracelet/Device/ClockManage/MyClockViewController.swift`
- 变更：
  - 移除 `deinit` 中 `dismiss(... completion:)` 里对 `self` 的弱引用捕获。
  - 将释放阶段的清理改为“无 self 捕获”的同步断链方式。
- 具体做法：
  - 在 `deinit` 里先取局部强引用或直接把 `imageUploadVc` 置空，再调用不依赖 `self` 的关闭逻辑。
  - 避免任何在 `deinit` 中创建闭包并捕获 `self` / `[weak self]` 的写法。
- 原因：
  - `deinit` 是对象销毁阶段，不能再构造新的 weak 引用到自身。

### 2. 保持弹窗关闭与引用释放顺序可预测
- 文件：`/Users/bruce/SmartBracelet/SmartBracelet/Device/ClockManage/MyClockViewController.swift`
- 变更：
  - 明确 `itemVC`、`imageUploadVc`、`NotificationCenter`、`needStop` 的清理顺序。
- 具体做法：
  - 先停止上传相关状态与通知，再解除观察者，再处理子弹窗的引用断开。
  - 如需 dismiss，使用不捕获 `self` 的 completion，或在 dismiss 之前就把属性置空。
- 原因：
  - 避免释放链路里再次触发回调访问已销毁对象。

### 3. 只做相邻风险点验证，不扩大修改面
- 文件：`/Users/bruce/SmartBracelet/SmartBracelet/Device/ClockManage/UploadImageViewController.swift`
- 变更：
  - 本次默认不修改该文件业务逻辑。
  - 实施时会检查 `handleStop()` 的 dismiss 回调是否会在 `MyClockViewController` 修复后仍形成释放竞争。
- 原因：
  - 用户选择最小热修，优先控制改动面。
  - 若验证发现这里仍可能形成相同风险，再做第二步最小补丁。

## Assumptions & Decisions
- 决策：本次不做全局 `deinit` 审计，只修复崩溃栈直接命中的 `MyClockViewController`。
- 假设：当前仓库代码与 App Store 崩溃版本的 `MyClockViewController.deinit` 结构一致，足以复现该根因。
- 假设：`ClockManageViewController` 在栈中出现是因为其子控制器 `MyClockViewController` 释放异常向上传导，不是它自身的主因。
- 假设：`BLYCrashManager` 相关栈帧只是崩溃上报链路，不是业务根因。

## Verification
1. 代码级验证
   - 确认 `MyClockViewController.deinit` 中不再有任何捕获 `self` / `[weak self]` 的闭包。
   - 确认 `imageUploadVc` / `itemVC` 清理后不会留下悬空引用。
2. 本地行为验证
   - 进入 `ClockManageViewController`
   - 打开 `MyClockViewController`
   - 触发上传图片弹窗显示/关闭
   - 返回上一级，确认页面可正常销毁
3. 崩溃回归验证
   - 重复执行用户提供的 App Store 场景对应的表盘管理进入/退出流程
   - 观察是否仍出现 `objc_initWeak` / `_os_unfair_lock_recursive_abort`
4. 风险检查
   - 验证上传弹窗关闭、取消上传、通知移除后无新异常
   - 若仍存在同类释放崩溃，再将 `UploadImageViewController.handleStop()` 纳入第二轮最小补丁
