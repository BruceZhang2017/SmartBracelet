# WatchFaceSDK-ObjC 快速开始

5 分钟集成智能手表表盘功能！

---

## 📦 第一步：添加 Framework

将以下文件拖入 Xcode 项目：

```
✅ WatchFaceSDK_ObjC.xcframework
✅ WatchProtocolSDK.xcframework
✅ ABParTool.xcframework
```

在 **Target** → **General** → **Frameworks** 中，将它们设置为 **Embed & Sign**。

---

## 📝 第二步：导入头文件

**Objective-C：**

```objc
#import <WatchFaceSDK_ObjC/WFManager.h>
```

**Swift：**

在 Bridging Header 中：

```objc
#import <WatchFaceSDK_ObjC/WFManager.h>
```

---

## 🚀 第三步：开始使用

### 1️⃣ 检查设备连接

```objc
WFManager *manager = [WFManager sharedInstance];

if ([manager isDeviceConnected]) {
    NSLog(@"设备已连接 ✅");
} else {
    NSLog(@"设备未连接 ❌");
}
```

### 2️⃣ 上传自定义表盘

```objc
UIImage *image = [UIImage imageNamed:@"my_background"];

[[WFManager sharedInstance] uploadCustomWatchFaceWithImage:image
                                              timePosition:WFTimePositionTopLeft
                                                     color:WFDialColorWhite
                                                  delegate:self
                                                     error:nil];
```

### 3️⃣ 监听进度

在你的 ViewController 中：

```objc
@interface YourViewController () <WFTransferDelegate>
@end

@implementation YourViewController

- (void)watchFaceTransferDidUpdateProgress:(WFTransferProgress *)progress {
    // 更新进度条
    self.progressView.progress = progress.percentage;
    NSLog(@"进度: %.0f%%", progress.percentage * 100);
}

- (void)watchFaceTransferDidComplete {
    NSLog(@"上传完成！🎉");
}

@end
```

---

## 🎨 时间位置和颜色选项

### 时间位置

```objc
WFTimePositionTopLeft       // 左上 ↖️
WFTimePositionTopRight      // 右上 ↗️
WFTimePositionBottomLeft    // 左下 ↙️
WFTimePositionBottomRight   // 右下 ↘️
WFTimePositionCenter        // 居中 ⏺
```

### 时间颜色

```objc
WFDialColorWhite    // 白色 ⚪️
WFDialColorBlack    // 黑色 ⚫️
WFDialColorYellow   // 黄色 🟡
WFDialColorOrange   // 橙色 🟠
WFDialColorPink     // 粉色 🩷
WFDialColorPurple   // 紫色 🟣
WFDialColorBlue     // 蓝色 🔵
WFDialColorCyan     // 青色 🔷
WFDialColorGreen    // 绿色 🟢
```

---

## 💡 完整示例

```objc
#import <WatchFaceSDK_ObjC/WFManager.h>

@interface MyViewController () <WFTransferDelegate>
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@end

@implementation MyViewController

- (IBAction)uploadWatchFace:(id)sender {
    // 1. 准备图片
    UIImage *backgroundImage = [UIImage imageNamed:@"my_background"];

    // 2. 检查连接
    WFManager *manager = [WFManager sharedInstance];
    if (![manager isDeviceConnected]) {
        NSLog(@"请先连接设备");
        return;
    }

    // 3. 开始上传
    NSError *error = nil;
    BOOL success = [manager uploadCustomWatchFaceWithImage:backgroundImage
                                              timePosition:WFTimePositionTopLeft
                                                     color:WFDialColorWhite
                                                  delegate:self
                                                     error:&error];

    if (!success) {
        NSLog(@"上传失败: %@", error.localizedDescription);
    }
}

#pragma mark - WFTransferDelegate

- (void)watchFaceTransferDidStart {
    NSLog(@"开始上传");
    self.progressView.hidden = NO;
}

- (void)watchFaceTransferDidUpdateProgress:(WFTransferProgress *)progress {
    self.progressView.progress = progress.percentage;
}

- (void)watchFaceTransferDidComplete {
    NSLog(@"上传完成！");
    self.progressView.hidden = YES;
}

- (void)watchFaceTransferDidFailWithError:(NSError *)error {
    NSLog(@"上传失败: %@", error.localizedDescription);
    self.progressView.hidden = YES;
}

@end
```

---

## ✅ 就是这么简单！

更多详细信息，请查看 [README.md](README.md)

---

**需要帮助？**
- 📧 Email: 315082431@qq.com
- 📖 完整文档: [README.md](README.md)
