# 表盘传输测试示例

## 🧪 快速测试指南

此示例用于验证表盘传输回调修复是否生效。

---

## 📋 前提条件

1. 已集成 WatchProtocolSDK.xcframework v2.0.9+
2. 已集成 WatchFaceSDK_ObjC.xcframework
3. 设备已连接并绑定

---

## 🔧 测试步骤

### 1. 实现传输代理

```objc
// YourViewController.h
#import <WatchFaceSDK/WatchFaceSDK.h>
#import <WatchProtocolSDK/WatchProtocolSDK.h>

@interface YourViewController : UIViewController <WFTransferDelegate, WPBluetoothManagerDelegate>
@end
```

```objc
// YourViewController.m
@implementation YourViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // 设置 WPBluetoothManager 代理
    [WPBluetoothManager sharedInstance].delegate = self;
}

#pragma mark - WFTransferDelegate

- (void)transferDidStart {
    NSLog(@"✅ 传输开始");
}

- (void)transferDidUpdateProgress:(WFTransferProgress *)progress {
    NSLog(@"📊 传输进度: %ld/%ld (%.1f%%)",
          (long)progress.currentPacket,
          (long)progress.totalPackets,
          progress.percentage * 100);
}

- (void)transferDidComplete {
    NSLog(@"🎉 传输完成！");
}

- (void)transferDidFailWithError:(NSError *)error {
    NSLog(@"❌ 传输失败: %@", error.localizedDescription);
}

- (void)transferDidCancel {
    NSLog(@"⚠️ 传输已取消");
}

#pragma mark - WPBluetoothManagerDelegate (可选)

- (void)didReceiveSleepData:(NSInteger)deepSleep
                 lightSleep:(NSInteger)lightSleep
                      awake:(NSInteger)awake {
    NSLog(@"😴 睡眠数据 - 深睡:%ldmin 浅睡:%ldmin 清醒:%ldmin",
          (long)deepSleep, (long)lightSleep, (long)awake);
}

@end
```

### 2. 测试市场表盘传输

```objc
- (void)testUploadMarketWatchFace {
    // 准备表盘文件
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"watch_face" ofType:@"bin"];
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];

    // 开始上传
    NSError *error = nil;
    BOOL success = [[WFManager sharedInstance] uploadMarketWatchFaceWithFileURL:fileURL
                                                                       delegate:self
                                                                          error:&error];

    if (success) {
        NSLog(@"🚀 表盘上传已启动");
    } else {
        NSLog(@"❌ 启动失败: %@", error.localizedDescription);
    }
}
```

### 3. 测试自定义表盘传输

```objc
- (void)testUploadCustomWatchFace {
    // 准备图片
    UIImage *image = [UIImage imageNamed:@"custom_background"];

    // 开始上传
    NSError *error = nil;
    BOOL success = [[WFManager sharedInstance] uploadCustomWatchFaceWithImage:image
                                                                  timePosition:WFTimePositionTopLeft
                                                                         color:WFDialColorWhite
                                                                      delegate:self
                                                                         error:&error];

    if (success) {
        NSLog(@"🚀 自定义表盘上传已启动");
    } else {
        NSLog(@"❌ 启动失败: %@", error.localizedDescription);
    }
}
```

### 4. 测试睡眠数据查询

```objc
- (void)testGetSleepData {
    // 发送查询指令
    [WPCommands getSleepMonitoring];

    // 响应将通过 didReceiveSleepData 回调
    NSLog(@"📤 已发送睡眠监测查询");
}
```

---

## ✅ 预期输出

### 成功的表盘传输日志

```
🚀 表盘上传已启动
✅ 传输开始
📤 发送传输配置指令 - 总包数:5 大小:1004
📥 收到响应 - 指令代码:0xE0 长度:7
📱 表盘市场响应 - 类型:1
✅ 表盘传输配置成功
📊 传输进度: 1/5 (20.0%)
📤 发送包 1/5 (大小: 220 bytes, 进度: 20%)
📥 收到响应 - 指令代码:0xE0 长度:10
📱 表盘市场响应 - 类型:2
📦 数据包接收成功，继续传输
📊 传输进度: 2/5 (40.0%)
📤 发送包 2/5 (大小: 220 bytes, 进度: 40%)
...
📊 传输进度: 5/5 (100.0%)
📥 收到响应 - 指令代码:0xE0 长度:10
📱 表盘市场响应 - 类型:2
✅ 表盘传输完成
🎉 传输完成！
```

### 成功的睡眠数据查询日志

```
📤 已发送睡眠监测查询
📥 收到响应 - 指令代码:0xB5 长度:11
😴 睡眠监测 - 深睡:240min 浅睡:180min 清醒:60min
😴 睡眠数据 - 深睡:240min 浅睡:180min 清醒:60min
```

---

## 🔍 常见问题排查

### 问题 1: 传输在第一包后卡死

**症状：**
```
📤 发送包 1/5 (大小: 220 bytes, 进度: 20%)
📥 收到响应 - 指令代码:0xE0 长度:10
⚠️ 未处理的指令响应:0xE0
[传输停止]
```

**原因：** 使用了旧版本的 WatchProtocolSDK（v2.0.8 或更早）

**解决方案：**
1. 确认使用 WatchProtocolSDK v2.0.9+
2. 检查 `Output-ObjC-Dynamic/WatchProtocolSDK.xcframework` 的修改时间
3. 重新运行 `./build_watchprotocol_objc_dynamic.sh`

### 问题 2: 收到 "未处理的指令响应:0xE0"

**原因：** WPCommands.m 中未添加 0xE0 响应处理

**解决方案：**
1. 确认 WPCommands.m 中包含以下代码：
   ```objc
   case WPCommandTypeDialMarket:
       [self handleDialMarketResponse:response];
       break;
   ```
2. 重新编译 framework

### 问题 3: 编译错误 "Use of undeclared identifier 'handleDialMarketResponse'"

**原因：** 方法声明或实现缺失

**解决方案：**
1. 确认 WPCommands.m 文件末尾包含 `handleDialMarketResponse` 和 `handleSleepMonitoringResponse` 的完整实现
2. 检查文件是否有语法错误

---

## 📊 测试检查清单

使用以下清单验证修复：

- [ ] WatchProtocolSDK.xcframework 版本 ≥ v2.0.9
- [ ] 编译无错误、无警告
- [ ] 市场表盘传输能完整执行（5包全部发送）
- [ ] 自定义表盘传输能完整执行
- [ ] 传输进度回调正常触发（0% → 100%）
- [ ] 传输完成回调正常触发
- [ ] 睡眠数据查询有响应
- [ ] 控制台无 "未处理的指令响应:0xE0" 警告
- [ ] 控制台无 "未处理的指令响应:0xB5" 警告

---

## 🚀 下一步

修复验证通过后，可以：

1. **更新版本号**
   - 将 SDK 版本更新为 v2.0.9
   - 更新 CHANGELOG.md

2. **提交代码**
   ```bash
   git add .
   git commit -m "fix(watchface): 修复表盘传输回调处理问题 (0xE0, 0xB5)"
   git tag v2.0.9
   git push origin main --tags
   ```

3. **分发 SDK**
   - 压缩 Output-ObjC-Dynamic/WatchProtocolSDK.xcframework
   - 压缩 Output-WatchFace-ObjC/WatchFaceSDK_ObjC.xcframework
   - 提供给第三方开发者

---

## 📞 支持

如果遇到问题，请检查：

- [WATCHFACE_CALLBACK_FIX_COMPLETE.md](WATCHFACE_CALLBACK_FIX_COMPLETE.md) - 完整修复报告
- [WATCHFACE_CALLBACK_ISSUE_ANALYSIS.md](WATCHFACE_CALLBACK_ISSUE_ANALYSIS.md) - 问题分析
- WatchProtocolSDK-ObjC/Core/WPCommands.m - 源码实现
