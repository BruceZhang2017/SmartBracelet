# WatchFaceSDK-ObjC 集成文档

WatchFaceSDK-ObjC 是一个纯 Objective-C 的智能手表表盘管理 SDK，提供完整的表盘上传、自定义表盘制作和实时进度监控功能。

[![Platform](https://img.shields.io/badge/platform-iOS-blue.svg)](https://developer.apple.com/ios/)
[![Language](https://img.shields.io/badge/language-Objective--C-orange.svg)](https://developer.apple.com/documentation/objectivec)
[![iOS](https://img.shields.io/badge/iOS-13.0+-green.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/license-Copyright-lightgrey.svg)](LICENSE)

---

## 📋 目录

- [功能特性](#-功能特性)
- [系统要求](#-系统要求)
- [安装集成](#-安装集成)
- [快速开始](#-快速开始)
- [详细 API](#-详细-api)
- [示例代码](#-示例代码)
- [常见问题](#-常见问题)

---

## ✨ 功能特性

### 核心功能

- ✅ **市场表盘上传** - 支持从本地文件或 NSData 上传市场表盘
- ✅ **自定义表盘制作** - 从任意图片创建个性化表盘
- ✅ **智能图片处理** - 自动裁剪、压缩、RGB565 和 PAR 格式转换
- ✅ **屏幕自动适配** - 圆形/方形屏幕自动检测和适配
- ✅ **实时进度监控** - 精确的传输进度回调
- ✅ **传输控制** - 支持暂停、取消和重试

### 技术特点

- 🎯 **纯 Objective-C** - 无 Swift 依赖，兼容性更强
- 🚀 **轻量级** - Framework 仅 312KB
- 📦 **易集成** - 提供 XCFramework 和 CocoaPods 两种集成方式
- 🔄 **MTU 自适应** - 智能分包传输，适配不同设备

---

## 📱 系统要求

| 项目 | 要求 |
|------|------|
| iOS 版本 | iOS 13.0+ |
| Xcode | Xcode 12.0+ |
| 架构 | arm64 (真机)<br>arm64, x86_64 (模拟器) |
| 语言 | Objective-C / Swift |

---

## 📦 安装集成

### 方式一：手动集成 XCFramework（推荐）

#### 1. 添加 Framework

将以下 Framework 拖入 Xcode 项目：

```
WatchFaceSDK_ObjC.xcframework
WatchProtocolSDK.xcframework  (依赖)
ABParTool.xcframework          (依赖)
```

#### 2. 配置 Xcode 项目

在 **Target** → **General** → **Frameworks, Libraries, and Embedded Content** 中：

- 将所有 Framework 设置为 **Embed & Sign**

#### 3. 配置 Build Settings

在 **Build Settings** 中添加：

```
Framework Search Paths: $(PROJECT_DIR)/Frameworks
```

### 方式二：CocoaPods 集成

在 `Podfile` 中添加：

```ruby
platform :ios, '13.0'
use_frameworks!

target 'YourApp' do
  # WatchFaceSDK-ObjC
  pod 'WatchFaceSDK-ObjC', '~> 1.0'

  # 依赖（需手动提供）
  pod 'WatchProtocolSDK-ObjC', :path => './Frameworks/WatchProtocolSDK.xcframework'
  pod 'ABParTool', :path => './Frameworks/ABParTool.xcframework'
end
```

然后执行：

```bash
pod install
```

---

## 🚀 快速开始

### 1. 导入头文件

**Objective-C 项目：**

```objc
#import <WatchFaceSDK_ObjC/WFManager.h>
```

**Swift 项目：**

在 Bridging Header 中添加：

```objc
#import <WatchFaceSDK_ObjC/WFManager.h>
```

### 2. 检查设备连接

```objc
WFManager *manager = [WFManager sharedInstance];

if ([manager isDeviceConnected]) {
    NSLog(@"设备已连接");

    // 获取设备屏幕信息
    WFDeviceScreenInfo *screenInfo = [manager getCurrentDeviceScreenInfo];
    NSLog(@"屏幕尺寸: %ldx%ld", screenInfo.width, screenInfo.height);
    NSLog(@"屏幕形状: %@", screenInfo.shape == WFScreenShapeRound ? @"圆形" : @"方形");
} else {
    NSLog(@"设备未连接");
}
```

### 3. 上传市场表盘

```objc
// 从文件上传
NSURL *fileURL = [[NSBundle mainBundle] URLForResource:@"watchface" withExtension:@"bin"];
NSError *error = nil;

BOOL success = [manager uploadMarketWatchFaceWithFileURL:fileURL
                                                delegate:self
                                                   error:&error];
if (!success) {
    NSLog(@"上传失败: %@", error.localizedDescription);
}
```

### 4. 创建自定义表盘

```objc
UIImage *image = [UIImage imageNamed:@"my_background"];
NSError *error = nil;

BOOL success = [manager uploadCustomWatchFaceWithImage:image
                                          timePosition:WFTimePositionTopLeft
                                                 color:WFDialColorWhite
                                              delegate:self
                                                 error:&error];
if (!success) {
    NSLog(@"创建失败: %@", error.localizedDescription);
}
```

### 5. 实现进度回调

```objc
@interface YourViewController () <WFTransferDelegate>
@end

@implementation YourViewController

#pragma mark - WFTransferDelegate

- (void)watchFaceTransferDidStart {
    NSLog(@"开始传输");
    // 显示进度 UI
}

- (void)watchFaceTransferDidUpdateProgress:(WFTransferProgress *)progress {
    float percentage = progress.percentage;
    NSLog(@"传输进度: %.1f%%", percentage * 100);
    // 更新进度条
    self.progressView.progress = percentage;
}

- (void)watchFaceTransferDidComplete {
    NSLog(@"传输完成");
    // 隐藏进度 UI，显示成功提示
}

- (void)watchFaceTransferDidFailWithError:(NSError *)error {
    NSLog(@"传输失败: %@", error.localizedDescription);
    // 显示错误提示
}

@end
```

---

## 📚 详细 API

### WFManager - 主管理类

#### 单例方法

```objc
+ (instancetype)sharedInstance;
```

#### 设备信息查询

```objc
// 获取当前设备屏幕信息
- (nullable WFDeviceScreenInfo *)getCurrentDeviceScreenInfo;

// 检查设备是否连接
- (BOOL)isDeviceConnected;

// 获取推荐的图片尺寸
- (CGSize)getRecommendedImageSize;
```

#### 上传市场表盘

```objc
// 从 NSData 上传
- (BOOL)uploadMarketWatchFaceWithData:(NSData *)data
                             delegate:(nullable id<WFTransferDelegate>)delegate
                                error:(NSError **)error;

// 从文件 URL 上传
- (BOOL)uploadMarketWatchFaceWithFileURL:(NSURL *)fileURL
                                delegate:(nullable id<WFTransferDelegate>)delegate
                                   error:(NSError **)error;
```

#### 上传自定义表盘

```objc
- (BOOL)uploadCustomWatchFaceWithImage:(UIImage *)image
                          timePosition:(WFTimePosition)timePosition
                                 color:(WFDialColor)color
                              delegate:(nullable id<WFTransferDelegate>)delegate
                                 error:(NSError **)error;
```

**参数说明：**

- `image`: 原始背景图片（SDK 会自动处理）
- `timePosition`: 时间显示位置（左上、右上、左下、右下、居中）
- `color`: 时间颜色（白、黑、黄、橙、粉、紫、蓝、青、绿）
- `delegate`: 传输进度回调代理
- `error`: 错误信息输出

#### 图片验证

```objc
// 验证图片是否符合要求
- (BOOL)validateImage:(UIImage *)image message:(NSString **)message;
```

#### 传输控制

```objc
// 暂停传输
- (void)pauseTransfer;

// 取消传输
- (void)cancelTransfer;

// 重试传输
- (void)retryTransfer;
```

---

### WFTransferDelegate - 传输回调协议

```objc
@protocol WFTransferDelegate <NSObject>

@optional

// 传输开始
- (void)watchFaceTransferDidStart;

// 进度更新
- (void)watchFaceTransferDidUpdateProgress:(WFTransferProgress *)progress;

// 传输完成
- (void)watchFaceTransferDidComplete;

// 传输失败
- (void)watchFaceTransferDidFailWithError:(NSError *)error;

// 传输暂停
- (void)watchFaceTransferDidPause;

// 传输取消
- (void)watchFaceTransferDidCancel;

@end
```

---

### WFTransferProgress - 进度模型

```objc
@interface WFTransferProgress : NSObject

@property (nonatomic, assign) NSInteger currentPacket;      // 当前包序号
@property (nonatomic, assign) NSInteger totalPackets;       // 总包数
@property (nonatomic, assign) NSInteger bytesTransferred;   // 已传输字节数
@property (nonatomic, assign) NSInteger totalBytes;         // 总字节数
@property (nonatomic, assign, readonly) float percentage;   // 百分比 (0.0-1.0)
@property (nonatomic, copy) NSString *message;              // 进度消息

@end
```

---

### 枚举类型

#### WFTimePosition - 时间位置

```objc
typedef NS_ENUM(NSInteger, WFTimePosition) {
    WFTimePositionNone = 0,         // 无
    WFTimePositionTopLeft = 1,      // 左上
    WFTimePositionBottomLeft = 2,   // 左下
    WFTimePositionTopRight = 3,     // 右上
    WFTimePositionBottomRight = 4,  // 右下
    WFTimePositionCenter = 5        // 居中
};
```

#### WFDialColor - 表盘颜色

```objc
typedef NS_ENUM(NSInteger, WFDialColor) {
    WFDialColorWhite = 0,   // 白色
    WFDialColorBlack = 1,   // 黑色
    WFDialColorYellow = 2,  // 黄色
    WFDialColorOrange = 3,  // 橙色
    WFDialColorPink = 4,    // 粉色
    WFDialColorPurple = 5,  // 紫色
    WFDialColorBlue = 6,    // 蓝色
    WFDialColorCyan = 7,    // 青色
    WFDialColorGreen = 8    // 绿色
};
```

#### WFScreenShape - 屏幕形状

```objc
typedef NS_ENUM(NSInteger, WFScreenShape) {
    WFScreenShapeRound = 0,   // 圆形
    WFScreenShapeSquare = 1   // 方形
};
```

#### WFErrorCode - 错误代码

```objc
typedef NS_ENUM(NSInteger, WFErrorCode) {
    WFErrorCodeDeviceNotConnected = 1000,       // 设备未连接
    WFErrorCodeDeviceNotSupported = 1001,       // 设备不支持
    WFErrorCodeInvalidParameters = 1002,        // 参数无效
    WFErrorCodeImageProcessingFailed = 1003,    // 图片处理失败
    WFErrorCodeTransferFailed = 1004,           // 传输失败
    WFErrorCodeTransferCancelled = 1005,        // 传输取消
    WFErrorCodeTransferTimeout = 1006,          // 传输超时
    WFErrorCodeFileNotFound = 1007,             // 文件不存在
    WFErrorCodeFileReadFailed = 1008,           // 文件读取失败
    WFErrorCodeInsufficientStorage = 1009,      // 设备存储不足
    WFErrorCodePARConversionFailed = 1010,      // PAR 转换失败
    WFErrorCodeFileTooLarge = 1011,             // 文件过大
    WFErrorCodeInvalidData = 1012,              // 数据无效
    WFErrorCodeInvalidImage = 1013              // 图片无效
};
```

---

## 💡 示例代码

### 示例 1: 完整的自定义表盘创建流程

```objc
@interface WatchFaceViewController () <WFTransferDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *previewImageView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIButton *uploadButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *positionControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *colorControl;

@end

@implementation WatchFaceViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // 检查设备连接状态
    [self updateDeviceStatus];
}

- (void)updateDeviceStatus {
    WFManager *manager = [WFManager sharedInstance];
    BOOL connected = [manager isDeviceConnected];

    self.uploadButton.enabled = connected;

    if (connected) {
        WFDeviceScreenInfo *info = [manager getCurrentDeviceScreenInfo];
        self.title = [NSString stringWithFormat:@"表盘制作 (%ldx%ld)",
                      info.width, info.height];
    } else {
        self.title = @"表盘制作 (设备未连接)";
    }
}

#pragma mark - 选择图片

- (IBAction)selectImageButtonTapped:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    UIImage *selectedImage = info[UIImagePickerControllerOriginalImage];
    self.previewImageView.image = selectedImage;
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 上传表盘

- (IBAction)uploadButtonTapped:(id)sender {
    UIImage *image = self.previewImageView.image;
    if (!image) {
        [self showAlert:@"请先选择图片"];
        return;
    }

    // 验证图片
    WFManager *manager = [WFManager sharedInstance];
    NSString *validationMessage = nil;
    if (![manager validateImage:image message:&validationMessage]) {
        [self showAlert:validationMessage];
        return;
    }

    // 获取时间位置和颜色
    WFTimePosition position = [self selectedTimePosition];
    WFDialColor color = [self selectedColor];

    // 开始上传
    NSError *error = nil;
    BOOL success = [manager uploadCustomWatchFaceWithImage:image
                                              timePosition:position
                                                     color:color
                                                  delegate:self
                                                     error:&error];

    if (!success) {
        [self showAlert:error.localizedDescription];
    } else {
        self.uploadButton.enabled = NO;
        self.progressView.hidden = NO;
    }
}

- (WFTimePosition)selectedTimePosition {
    NSInteger index = self.positionControl.selectedSegmentIndex;
    // 0:左上, 1:右上, 2:左下, 3:右下, 4:居中
    return (WFTimePosition)(index + 1);
}

- (WFDialColor)selectedColor {
    return (WFDialColor)self.colorControl.selectedSegmentIndex;
}

#pragma mark - WFTransferDelegate

- (void)watchFaceTransferDidStart {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressView.progress = 0.0;
        NSLog(@"开始上传表盘");
    });
}

- (void)watchFaceTransferDidUpdateProgress:(WFTransferProgress *)progress {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressView.progress = progress.percentage;
        NSLog(@"上传进度: %.1f%% (%ld/%ld)",
              progress.percentage * 100,
              progress.currentPacket,
              progress.totalPackets);
    });
}

- (void)watchFaceTransferDidComplete {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressView.hidden = YES;
        self.uploadButton.enabled = YES;
        [self showAlert:@"表盘上传成功！"];
        NSLog(@"表盘上传完成");
    });
}

- (void)watchFaceTransferDidFailWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressView.hidden = YES;
        self.uploadButton.enabled = YES;
        [self showAlert:[NSString stringWithFormat:@"上传失败: %@",
                        error.localizedDescription]];
        NSLog(@"表盘上传失败: %@", error);
    });
}

#pragma mark - Helpers

- (void)showAlert:(NSString *)message {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"提示"
                         message:message
                  preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                             style:UIAlertActionStyleDefault
                                           handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
```

### 示例 2: Swift 中使用

```swift
import UIKit

class WatchFaceViewController: UIViewController, WFTransferDelegate {

    @IBOutlet weak var progressView: UIProgressView!

    override func viewDidLoad() {
        super.viewDidLoad()
        checkDeviceConnection()
    }

    func checkDeviceConnection() {
        let manager = WFManager.sharedInstance()

        if manager.isDeviceConnected() {
            if let screenInfo = manager.getCurrentDeviceScreenInfo() {
                print("设备屏幕: \(screenInfo.width)x\(screenInfo.height)")
            }
        } else {
            print("设备未连接")
        }
    }

    @IBAction func uploadCustomWatchFace() {
        guard let image = UIImage(named: "background") else { return }

        let manager = WFManager.sharedInstance()

        do {
            try ObjCExceptionHandler.catchException {
                var error: NSError?
                let success = manager.uploadCustomWatchFace(
                    with: image,
                    timePosition: .topLeft,
                    color: .white,
                    delegate: self,
                    error: &error
                )

                if !success, let error = error {
                    print("上传失败: \(error.localizedDescription)")
                }
            }
        } catch {
            print("异常: \(error)")
        }
    }

    // MARK: - WFTransferDelegate

    func watchFaceTransferDidStart() {
        DispatchQueue.main.async {
            self.progressView.progress = 0.0
        }
    }

    func watchFaceTransferDidUpdateProgress(_ progress: WFTransferProgress) {
        DispatchQueue.main.async {
            self.progressView.progress = progress.percentage
            print("进度: \(progress.percentage * 100)%")
        }
    }

    func watchFaceTransferDidComplete() {
        DispatchQueue.main.async {
            print("上传完成")
        }
    }

    func watchFaceTransferDidFail(withError error: Error) {
        DispatchQueue.main.async {
            print("上传失败: \(error.localizedDescription)")
        }
    }
}
```

---

## ❓ 常见问题

### Q1: 导入 Framework 后提示找不到头文件？

**A:** 检查以下配置：

1. Framework 是否添加到 **Frameworks, Libraries, and Embedded Content**
2. **Framework Search Paths** 是否正确配置
3. 是否设置为 **Embed & Sign**

### Q2: 支持哪些图片格式？

**A:** SDK 支持所有 UIImage 支持的格式：

- PNG（推荐，无损）
- JPEG/JPG
- HEIC
- BMP
- GIF（静态）

建议使用 PNG 格式以获得最佳质量。

### Q3: 自定义表盘图片有什么要求？

**A:** 图片要求：

- **推荐尺寸**: 与设备屏幕尺寸一致（通过 `getRecommendedImageSize` 获取）
- **最小尺寸**: 不小于 240x240
- **最大尺寸**: 不限制（SDK 会自动缩放）
- **长宽比**: 建议 1:1
- **文件大小**: SDK 会自动压缩到设备支持的大小

### Q4: 传输速度慢怎么办？

**A:** 传输速度受以下因素影响：

- 蓝牙信号强度（建议设备距离 < 1米）
- 设备 MTU 大小（SDK 自动适配）
- 图片文件大小（SDK 会自动压缩）

优化建议：
- 确保设备距离近
- 避免其他蓝牙设备干扰
- 使用较小的图片

### Q5: 如何处理传输失败？

**A:** 实现 `watchFaceTransferDidFailWithError:` 回调：

```objc
- (void)watchFaceTransferDidFailWithError:(NSError *)error {
    switch (error.code) {
        case WFErrorCodeDeviceNotConnected:
            // 设备断开，提示用户重新连接
            break;
        case WFErrorCodeTransferTimeout:
            // 超时，自动重试
            [[WFManager sharedInstance] retryTransfer];
            break;
        default:
            // 其他错误，显示错误信息
            NSLog(@"错误: %@", error.localizedDescription);
            break;
    }
}
```

### Q6: Swift 项目如何集成？

**A:** 按以下步骤：

1. 添加 Framework 到项目
2. 创建 Bridging Header (File → New → Header File → YourApp-Bridging-Header.h)
3. 在 Bridging Header 中导入：
   ```objc
   #import <WatchFaceSDK_ObjC/WFManager.h>
   ```
4. 在 Build Settings → Objective-C Bridging Header 中设置 Header 文件路径

### Q7: 如何取消正在进行的传输？

**A:** 调用取消方法：

```objc
[[WFManager sharedInstance] cancelTransfer];
```

会触发 `watchFaceTransferDidCancel` 回调。

### Q8: 是否支持后台传输？

**A:** SDK 依赖蓝牙连接，需要：

1. 在 Info.plist 添加蓝牙后台模式：
   ```xml
   <key>UIBackgroundModes</key>
   <array>
       <string>bluetooth-central</string>
   </array>
   ```

2. 注意：iOS 后台蓝牙有限制，长时间传输可能被系统暂停

### Q9: 上传的表盘在手表上显示异常？

**A:** 检查：

- 时间位置选择是否正确
- 颜色选择是否与背景对比度足够
- 图片是否过暗或过亮
- 设备屏幕形状是否匹配（圆形/方形）

### Q10: 依赖的 Framework 在哪里获取？

**A:** 依赖 Framework：

- **WatchProtocolSDK.xcframework**: 项目提供
- **ABParTool.xcframework**: 项目提供

这些 Framework 应该已包含在 SDK 分发包中。

---

## 📞 技术支持

如有问题，请联系：

- **Email**: 315082431@qq.com
- **GitHub Issues**: [提交问题](https://github.com/BruceZhang2017/SmartBracelet/issues)

---

## 📄 许可证

Copyright © 2026 Anker Innovations. All rights reserved.

---

## 📝 更新日志

### v1.0.0 (2026-01-13)

- ✨ 首次发布
- ✅ 纯 Objective-C 实现
- ✅ 市场表盘上传功能
- ✅ 自定义表盘制作功能
- ✅ 智能图片处理（RGB565、PAR 转换）
- ✅ 实时传输进度监控
- ✅ 传输控制（暂停、取消、重试）

---

**祝您使用愉快！🎉**
