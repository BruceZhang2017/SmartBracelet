# Debug Session: same-crash-project
- **Status**: [OPEN]
- **Issue**: 当前项目也出现与前一个项目相同的崩溃问题，疑似与自定义表盘图片处理或发送链路相关，但具体崩溃点尚未确认。
- **Debug Server**: N/A
- **Log File**: N/A

## Reproduction Steps
1. 进入出现崩溃的页面或操作路径
2. 执行与上一个项目相同的触发步骤
3. 记录崩溃前最后一段日志、堆栈或页面动作

## Hypotheses & Verification
| ID | Hypothesis | Likelihood | Effort | Evidence |
|----|------------|------------|--------|----------|
| A | 崩溃仍发生在自定义表盘的图片压缩 / RLE 转换链路 | High | Low | Pending |
| B | 压缩失败后仍继续进入蓝牙发送或 UI 回调，导致状态异常崩溃 | High | Low | Pending |
| C | 当前项目设备参数不同，触发了另一条未覆盖分支 | Medium | Low | Pending |
| D | 崩溃本质是图片处理中间对象引起的内存峰值问题 | Medium | Medium | Pending |
| E | 现象相似但 crash stack 不同，实际是另一处问题 | Medium | Low | Pending |

## Log Evidence
- 当前已知复现条件：没有设备的情况，启动 App 后发生崩溃
- 已确认启动链路会在无设备时自动切到设备页：`MTabBarController.viewWillAppear -> selectedIndex = 1`
- 设备页冷启动高风险点：
  - `DevicesViewController.viewDidLoad` 中直接调用 `bleSelf.getSwitchForWristband()`
  - 同页初始化阶段会调用 `AppDelegate.IsDeviceNotRound()` 并访问 `bleSelf.bleModel`
  - `DevicesView.refreshData()` 会在设备卡刷新时访问设备缓存与连接态

## Verification Conclusion
- Pending

## Instrumentation
- `AppDelegate.pushToTab`：记录根控制器选择和是否存在绑定设备
- `MTabBarController.viewDidLoad/viewWillAppear`：记录无设备时切换到设备页的时机
- `DevicesViewController.viewDidLoad`：记录设备页初始化入口、`getSwitchForWristband` 前后、屏幕形态计算前后
- `DevicesView.refreshData`：记录设备卡刷新时的缓存和连接态
