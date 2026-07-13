# ClockManage 释放崩溃修复计划

## Summary
- 目标：修复 `FitDAY 2.6.5 (7)` 在表盘管理模块中的 `EXC_BREAKPOINT / FOUNDATION 1` 崩溃。
- 直接症状：
  - 崩溃栈稳定命中 `objc_initWeak`
  - 命中 `MyClockViewController.__deallocating_deinit`
  - 上层伴随 `ClockManageViewController.__deallocating_deinit`
- 本次范围：按用户选择，扩大到全项目；但实施上会优先完成 `ClockManage` 模块的同类释放风险收敛，并把全项目其余同型风险做清单化筛查，避免漏掉同一类线上崩溃。
- 成功标准：
  - 不再出现 `objc_initWeak` / `_os_unfair_lock_recursive_abort` / `FOUNDATION 1`
  - `ClockManageViewController`、`MyClockViewController`、`ClockUseViewController` 在退出时可稳定释放
  - 上传弹窗关闭、取消上传、上传成功回调、失败回调不出现悬空引用或重复 dismiss

## Current State Analysis

### 1. 已确认的线上根因
- 三份 incident 的核心栈一致：
  - `objc_initWeak`
  - `swift_unknownObjectWeakInit`
  - `MyClockViewController.__deallocating_deinit`
- 这类栈形态说明：对象已经进入销毁阶段，却又在释放路径中创建了新的 weak 引用。

### 2. 当前仓库中已知高风险代码

#### A. `MyClockViewController.deinit`
- 文件：[MyClockViewController.swift](file:///Users/bruce/SmartBracelet/SmartBracelet/Device/ClockManage/MyClockViewController.swift#L109-L121)
- 当前状态：
  - 已有一版最小修复，把 `deinit` 改成了不捕获 `self` 的同步断链。
- 结论：
  - 这是线上 incident 的直接命中点，必须保留并纳入正式修复方案。

#### B. `MyClockViewController` 其余上传结束链路
- 文件：[MyClockViewController.swift](file:///Users/bruce/SmartBracelet/SmartBracelet/Device/ClockManage/MyClockViewController.swift#L450-L563)
- 现状：
  - 存在多处模式相同的写法：
    - `self?.imageUploadVc?.dismiss(animated: false, completion: { [weak self] in self?.imageUploadVc = nil })`
  - 分布在：
    - 上传完成
    - 主动停止
    - 设备不支持
    - 推送失败
    - 推送成功收尾
- 风险：
  - 虽然这些闭包不在 `deinit` 里，但它们都位于退出/收尾路径，容易与控制器销毁重叠，形成同类释放竞态。

#### C. `ClockUseViewController.deinit`
- 文件：[ClockUseViewController.swift](file:///Users/bruce/SmartBracelet/SmartBracelet/Device/ClockManage/ClockUseViewController.swift#L116-L121)
- 现状：
  - `deinit` 中仍有 `imageUploadVc?.dismiss(animated: false, completion: { })`
- 风险：
  - 这虽然没有 `[weak self]`，但仍属于在 `deinit` 中触发 UI dismiss 的高风险模式，和本次崩溃场景同属释放链路不稳定问题。

#### D. `UploadImageViewController.handleStop`
- 文件：[UploadImageViewController.swift](file:///Users/bruce/SmartBracelet/SmartBracelet/Device/ClockManage/UploadImageViewController.swift#L118-L123)
- 现状：
  - `dismiss(animated: false) { [weak self] in self?.delegate?.dismissVC() }`
- 评估：
  - 该处不在当前 incident 栈上，但属于同一个关闭弹窗入口，需要一并统一关闭策略，避免修完主路径后仍有边缘竞态。

### 3. 全项目扫描结果
- 通过只读扫描，真正与本次 incident 同型、且集中在表盘管理链路中的候选点主要是：
  - `MyClockViewController`
  - `ClockUseViewController`
  - `UploadImageViewController`
- 其余全项目 `[weak self]` 大多是普通异步回调、动画、网络请求、通知处理，不应和本次 incident 混为一谈。
- 因此虽然用户选择“扩大到全项目”，执行策略上应以 `ClockManage` 同型风险为主修复对象，并附带给出全项目剩余风险筛查结论，而不是机械改所有 `[weak self]`。

## Proposed Changes

### 1. 统一 `ClockManage` 模块的弹窗关闭与引用断链策略
- 文件：
  - `/Users/bruce/SmartBracelet/SmartBracelet/Device/ClockManage/MyClockViewController.swift`
  - `/Users/bruce/SmartBracelet/SmartBracelet/Device/ClockManage/ClockUseViewController.swift`
  - `/Users/bruce/SmartBracelet/SmartBracelet/Device/ClockManage/UploadImageViewController.swift`
- 改法：
  - 抽成一致策略：
    - 先拿局部引用
    - 先把属性置空
    - 再执行不依赖 `self` 的 `dismiss(animated:completion:nil)`，或将后续回调改为不再读写拥有者自身属性
  - 避免以下模式继续存在于释放/收尾路径：
    - `dismiss(...){ [weak self] ... }`
    - `self?.xxx?.dismiss(...){ [weak self] ... }`
    - `deinit` 中直接触发带 completion 的 dismiss
- 原因：
  - 这些是线上 incident 的共同结构性问题，不是单点 typo。

### 2. 收敛 `MyClockViewController` 多个上传结束分支
- 文件：
  - `/Users/bruce/SmartBracelet/SmartBracelet/Device/ClockManage/MyClockViewController.swift`
- 改法：
  - 将上传结束、失败、取消、成功等多处分散的 `imageUploadVc?.dismiss` 收敛成一个统一的关闭辅助方法。
  - 该辅助方法必须满足：
    - 不在内部捕获 `self` 后再回写 `imageUploadVc`
    - 调用前先把 `imageUploadVc` 断链
    - 可以安全地被重复调用，不会二次 dismiss 同一实例
- 原因：
  - 当前同一模式重复出现 5+ 次，保留分散写法会继续制造新的释放竞态。

### 3. 修复 `ClockUseViewController.deinit` 的同类释放风险
- 文件：
  - `/Users/bruce/SmartBracelet/SmartBracelet/Device/ClockManage/ClockUseViewController.swift`
- 改法：
  - 去掉 `deinit` 中直接对 `imageUploadVc` 做带 completion 的 dismiss。
  - 改成同步断链或提前在生命周期更安全的时机关闭弹窗。
- 原因：
  - 它虽未出现在当前 incident 栈上，但结构上与主问题高度相邻，极易成为下一批同类崩溃来源。

### 4. 统一 `UploadImageViewController` 的关闭回调约束
- 文件：
  - `/Users/bruce/SmartBracelet/SmartBracelet/Device/ClockManage/UploadImageViewController.swift`
- 改法：
  - 重新梳理 `handleStop()` 里的关闭顺序，确保：
    - 关闭弹窗不会回头触发已释放宿主对象的属性回写
    - `delegate?.dismissVC()` 调用时机不依赖 view controller 销毁阶段
- 原因：
  - 这是 `MyClockViewController` / `ClockUseViewController` 的共同下游弹窗，必须保证关闭语义稳定。

### 5. 全项目补充筛查与保守边界
- 文件：
  - 全项目只做筛查，不默认全面改动
- 改法：
  - 实施时只对“释放阶段 + dismiss + completion + self/weak self”完全同型的点继续扩展。
  - 纯网络回调、动画回调、普通异步任务中的 `[weak self]` 不纳入本次修复，避免过度修改。
- 原因：
  - 用户选择扩大到全项目，但本次问题是明确的释放链路崩溃，应该按风险模式扩，不是按关键字机械扩。

## Assumptions & Decisions
- 决策：
  - 采用“全项目筛查 + 重点修复 ClockManage 模块”的执行策略。
  - 不会把所有 `[weak self]` 一刀切替换。
- 假设：
  - 线上 `2.6.5 (7)` 使用的是旧释放逻辑，因此 incident 与当前仓库的已知根因一致。
  - `ClockManageViewController` 出现在栈里是子控制器释放异常向上传导，而不是它自身主因。
  - `BLYCrashManager` 只是崩溃收集链路，不参与业务根因。

## Verification
1. 代码级验证
   - `MyClockViewController.deinit` 中不再出现任何捕获 `self` / `[weak self]` 的闭包
   - `ClockUseViewController.deinit` 中不再直接做高风险 dismiss
   - `MyClockViewController` 上传结束各分支统一走同一关闭策略
2. 路径验证
   - 进入表盘管理页
   - 进入自定义表盘页
   - 打开上传图片弹窗
   - 分别验证：
     - 取消上传
     - 上传成功
     - 上传失败
     - 中途停止
     - 返回上一级页面
3. 崩溃回归验证
   - 重点观察是否还会出现：
     - `objc_initWeak`
     - `swift_unknownObjectWeakInit`
     - `MyClockViewController.__deallocating_deinit`
4. 风险回归验证
   - 验证弹窗不会残留
   - 验证不会出现重复 dismiss、回调丢失、页面无法关闭
   - 如仍有同类 crash，再根据 crash 栈命中点继续扩展到同型释放路径
