# Debug Session: unbind-relaunch-crash
- **Status**: [OPEN]
- **Issue**: App 端解绑设备后，杀掉 App 再重新打开，冷启动发生崩溃。
- **Debug Server**: N/A
- **Log File**: N/A

## Reproduction Steps
1. 在 App 内解绑当前设备
2. 杀掉 App
3. 重新打开 App
4. 观察冷启动阶段崩溃

## Hypotheses & Verification
| ID | Hypothesis | Likelihood | Effort | Evidence |
|----|------------|------------|--------|----------|
| A | 解绑只清了数据库绑定记录，但 `LastestDeviceMac` 或缓存设备列表没清，冷启动时进入“无数据库设备 + 有缓存设备”的脏状态 | High | Low | Pending |
| B | 启动时设备页/Tab 仍按“存在上次设备”路径初始化，访问了已解绑设备的屏幕参数或连接态 | High | Low | Pending |
| C | 冷启动时某个 UI 容器重复插入相同 item，`Item already exists at index 0` 只是前兆，后续数组/视图状态错乱导致崩溃 | Medium | Medium | Pending |
| D | 解绑后缓存设备对象仍保留，`DeviceManager` / `cacheDevices` / `XGZTBlueToothManager.shared.device` 三者状态不一致，触发空值或非法状态访问 | High | Low | Pending |
| E | 真正崩溃点不在解绑逻辑，而在冷启动 4 秒刷新链路中某个定时器或通知回调 | Medium | Medium | Pending |

## Log Evidence
- 启动时数据库设备数量为 `0`
- 仍存在 `最后连接的设备MAC地址：41:43:02:02:E7:7A`
- 仍存在 `已经缓存的设备：41:43:02:02:E7:7A e watch`
- 冷启动过程中出现多次 `Item already exists at index 0`
- 之后仍继续进入设备页初始化：`当前连接设备为：方形`、`width: 123.333...`

## Verification Conclusion
- 当前静态证据强烈支持 A / D：
  - 冷启动日志显示数据库设备为 `0`，但 `LastestDeviceMac` 与 `xgzt` 缓存设备仍存在
  - `MTabBarController.setupLastestDeviceMac()` 会只根据 `LastestDeviceMac` 决定后续回连和启动路径
  - `BluetoothWatchDevice.loadAll()` 会从 `UserDefaults["xgzt"]` 继续恢复缓存设备
  - 某些解绑路径依赖 `DevicesViewController` 的通知处理去真正删除 `xgzt` 缓存，链路较脆弱
- 目前尚未确认：
  - 是解绑时根本没删掉缓存
  - 还是删掉后又被回连/重连流程写回

## Instrumentation
- `BLEManager.unbind()`：记录解绑前后 `LastestDeviceMac` / `deleteLastestDeviceMac`
- `DevicesViewController.handleNotification(2000/3000)`：记录解绑通知入口与结束时的缓存、数据库、默认值状态
- `BluetoothWatchDevice.deleteFromSandbox/loadAll()`：记录 `xgzt` 沙盒缓存删除前后键集合
- `MTabBarController.setupLastestDeviceMac()`：记录冷启动读到的默认值和缓存状态
