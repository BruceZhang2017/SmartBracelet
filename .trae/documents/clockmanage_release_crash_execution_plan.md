# ClockManage 释放崩溃执行计划

## Summary
- 目标：继续收敛 `FitDAY 2.6.5 (7)` 在表盘管理链路中的 `EXC_BREAKPOINT / FOUNDATION 1` 崩溃，重点覆盖本次新增 incident `C436000A-7765-4343-9C6D-19D0708CC093` 所对应的释放路径。
- 成功标准：
  - 不再保留 `MyClockViewController` / `ClockUseViewController` / `UploadImageViewController` 中“释放阶段 + dismiss + completion/异步刷新 + 宿主引用回写”的同型风险。
  - `ClockManage` 页面进入、上传弹窗展示、取消、失败、成功、返回上级页面等路径在代码上都走一致的关闭语义。
  - 回归时不再出现与 incident 一致的关键栈形态：`objc_initWeak`、`swift_unknownObjectWeakInit`、`MyClockViewController.__deallocating_deinit`、`_os_unfair_lock_recursive_abort`。

## Current State Analysis

### 1. incident 与当前仓库的对应关系
- 用户给出的最新 incident 栈关键链路为：
  - `MyClockViewController.__deallocating_deinit`
  - `swift_unknownObjectWeakInit`
  - `objc_initWeak`
  - `_os_unfair_lock_recursive_abort`
  - `BLYCrashManager.didCrashAccidentHappened -> BLYDataManager persist/save`
- 该形态说明：对象已进入析构阶段，但析构过程中仍触发了新的 weak 初始化或关闭回调链。
- 仓库中与该栈最接近的代码仍集中在 `ClockManage` 模块，而 `BLYCrashManager` / `BLYDataManager` 源码当前不在仓库内，无法作为本轮直接修复点，只能作为“崩溃后放大链路”纳入验证结论。

### 2. 已确认的高风险文件与现状

#### A. `MyClockViewController.swift`
- 文件：[MyClockViewController.swift](file:///Users/bruce/SmartBracelet/SmartBracelet/Device/ClockManage/MyClockViewController.swift)
- 当前已存在的修复基础：
  - `deinit` 已改为先取局部引用，再断开 `itemVC` / `imageUploadVc`，最后执行 `dismiss(animated:false, completion:nil)`。
  - 已新增 `dismissImageUploadController()`，并在部分上传结束分支统一调用。
- 仍需继续确认的点：
  - 主线程异步刷新 `imageUploadVc?.refreshProgress(...)` 的分支仍然分散。
  - 展示弹窗、停止上传、推送失败、成功收尾这些入口是否都已统一走“先断链后 dismiss”的策略，需要补齐并消除遗漏。
  - `present(itemVC!)` / `present(imageUploadVc!)` 对应的宿主引用生命周期还需要继续收口。

#### B. `ClockUseViewController.swift`
- 文件：[ClockUseViewController.swift](file:///Users/bruce/SmartBracelet/SmartBracelet/Device/ClockManage/ClockUseViewController.swift)
- 当前现状：
  - `deinit` 已改成先拿局部 `uploadController`，再把 `imageUploadVc` 置空，然后同步 `dismiss`。
  - 但通知回调里仍有多处 `DispatchQueue.main.async { [weak self] self?.imageUploadVc?.refreshProgress(...) }` 和结果分支调弹窗逻辑。
- 风险判断：
  - 虽然它没有直接命中本次 incident 栈，但结构上与 `MyClockViewController` 高度同型，属于下一跳风险点。

#### C. `UploadImageViewController.swift`
- 文件：[UploadImageViewController.swift](file:///Users/bruce/SmartBracelet/SmartBracelet/Device/ClockManage/UploadImageViewController.swift)
- 当前现状：
  - `handleStop()` 已改成先抓取 `delegate` 到局部变量，再 `dismiss(animated:false, completion:nil)`，然后调用 `currentDelegate?.dismissVC()`。
  - `handleCancel()` 仍然是先 `delegate?.dismissVC()` 再 `dismiss(...)`，关闭语义与 `handleStop()` 不一致。
- 风险判断：
  - 该类是两个宿主控制器的共同下游，一旦关闭顺序不一致，就可能在边缘路径重新形成释放竞态。

#### D. `ClockManageViewController.swift`
- 文件：[ClockManageViewController.swift](file:///Users/bruce/SmartBracelet/SmartBracelet/Device/ClockManage/ClockManageViewController.swift)
- 当前现状：
  - 仅做通知监听与子控制器承载，`deinit` 只移除通知。
- 结论：
  - 它在栈中更像父控制器被子控制器异常释放牵连的表现，本轮不应把它当作主因误改。

### 3. 可证伪假设
1. `MyClockViewController` 仍残留至少一条在退出/失败/停止路径上访问 `imageUploadVc` 的异步分支，释放时重新触发弱引用初始化。
2. `UploadImageViewController` 的不同关闭入口顺序不一致，导致宿主对象有时先收到回写、后销毁，有时反过来。
3. `ClockUseViewController` 与 `MyClockViewController` 共享相同的上传弹窗模式，如果不一起收口，会继续保留同类线上风险。
4. `BLYCrashManager` 不是业务根因，但会在崩溃态再次持久化对象，使表面栈更深；因此真正需要修的是页面释放路径，而不是误改崩溃上报行为。

## Proposed Changes

### 1. 彻底统一 `MyClockViewController` 的弹窗关闭与引用断链策略
- 文件：`/Users/bruce/SmartBracelet/SmartBracelet/Device/ClockManage/MyClockViewController.swift`
- 具体实施：
  - 保留现有 `deinit` 热修。
  - 继续把上传完成、停止、失败、不支持、成功收尾等全部关闭分支收敛到统一的关闭辅助方法。
  - 如果存在 `imageUploadVc = nil`、`dismiss(...)`、`refreshProgress(...)` 的分散写法，统一成“不在 completion 中回写宿主属性”的方式。
  - 对 `itemVC` 也补一个同类关闭辅助方法，避免未来又回到分散 `dismiss` 写法。
- 原因：
  - 当前直接命中 incident 的就是它；这里必须保证所有出口语义一致，而不是只修 `deinit`。

### 2. 收敛 `ClockUseViewController` 的同型上传弹窗风险
- 文件：`/Users/bruce/SmartBracelet/SmartBracelet/Device/ClockManage/ClockUseViewController.swift`
- 具体实施：
  - 增加与 `MyClockViewController` 相同风格的统一关闭辅助方法。
  - 将通知回调中的成功、失败、停止、进度分支改为复用统一策略，避免一部分逻辑仍绕开安全关闭路径。
  - 审核 `showDialog()` / `hideDialog()` / `dismissVC()` 之间的职责边界，确保只有一个入口负责断链。
- 原因：
  - 它与主崩溃类共享几乎相同的资源持有模式，本轮应顺手收口，避免后续 incident 漂移到这个类。

### 3. 统一 `UploadImageViewController` 的关闭顺序
- 文件：`/Users/bruce/SmartBracelet/SmartBracelet/Device/ClockManage/UploadImageViewController.swift`
- 具体实施：
  - 对齐 `handleStop()` 与 `handleCancel()` 的关闭语义。
  - 明确“通知宿主断链”和“关闭自身弹窗”的先后顺序，只保留一种顺序。
  - 保证 `delegate?.dismissVC()` 不再依赖 `dismiss` completion，也不在析构阶段间接触发宿主属性回写。
- 原因：
  - 这是两个宿主类共同依赖的弹窗基类，顺序不一致会把问题重新带回来。

### 4. 保持修复边界，不误改无关模块
- 文件：仅限 `ClockManage` 相关 3 个文件；`ClockManageViewController.swift` 只在必要时做最小配套调整。
- 具体实施：
  - 不对全项目普通 `[weak self]`、普通网络回调、动画闭包做机械替换。
  - 不修改仓库外的 `BLYCrashManager` / `BLYDataManager` 实现。
  - 不动与本次 incident 无关的 UI、设备页、解绑冷启动链路代码。
- 原因：
  - 用户当前给的是 release incident，目标是精准收敛，不是扩大改动面。

## Assumptions & Decisions
- 决策：
  - 采用“继续深挖 `ClockManage` 模块 + 不扩大到无关模块”的执行策略。
  - 以统一关闭语义为核心，不做大规模架构重写。
- 假设：
  - 当前仓库中已改过一部分的 `MyClockViewController` / `ClockUseViewController` / `UploadImageViewController`，与线上 2.6.5(7) 的问题结构一致，能作为本轮修复基础。
  - `BLYCrashManager` 出现在栈中是崩溃后的放大链路，不是宿主控制器释放问题的根因。
  - 当前 worktree 已有多处未提交改动，因此实施时需要只在目标文件内增量修改，避免碰到用户其他在制修改。

## Verification
1. 代码级验证
  - `MyClockViewController.swift` 不再残留“`dismiss(... completion:)` 内回写 `imageUploadVc` / `itemVC`”模式。
  - `ClockUseViewController.swift` 的弹窗关闭路径只保留一个统一入口。
  - `UploadImageViewController.swift` 的 `handleStop()` 与 `handleCancel()` 关闭顺序一致。
2. 路径级验证
  - 进入 `ClockManageViewController`
  - 打开 `MyClockViewController`
  - 展示上传弹窗
  - 依次验证：取消上传、开始上传后停止、上传失败、上传成功、返回上一级页面
  - 再进入 `ClockUseViewController` 验证相同关闭路径
3. 崩溃回归验证
  - 人工对照新的控制器关闭语义，确认不会在析构阶段再创建新的 weak 引用回写宿主。
  - 如可获取新日志，重点观察是否还出现：
    - `objc_initWeak`
    - `swift_unknownObjectWeakInit`
    - `MyClockViewController.__deallocating_deinit`
4. 构建与环境说明
  - 若本地 `xcodebuild` 仍因依赖缺失失败，需要明确记录为环境限制，而不是本轮改动语法问题。
