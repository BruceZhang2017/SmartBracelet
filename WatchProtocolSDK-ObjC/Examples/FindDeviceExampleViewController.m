//
//  FindDeviceExampleViewController.m
//  WatchProtocolSDK-ObjC Example
//
//  Created by Claude on 2026/01/27.
//  Copyright © 2026 Huaxin. All rights reserved.
//

#import "FindDeviceExampleViewController.h"
#import "../WatchProtocolSDK.h"

@interface FindDeviceExampleViewController ()

// MARK: - UI 控件
@property (nonatomic, weak) IBOutlet UIButton *findButton;
@property (nonatomic, weak) IBOutlet UILabel *statusLabel;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, weak) IBOutlet UISegmentedControl *durationSegment;

@end

@implementation FindDeviceExampleViewController

// MARK: - 生命周期

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"查找设备示例";
    self.view.backgroundColor = [UIColor whiteColor];

    [self setupUI];
    [self updateUI];
}

- (void)dealloc {
    // ⚠️ 重要：页面销毁时取消所有查找任务
    [WPCommands cancelAllFindTasks];
    NSLog(@"FindDeviceExampleViewController dealloc");
}

// MARK: - UI 初始化

- (void)setupUI {
    // 如果是代码创建的 UI（非 Storyboard/XIB）
    if (!self.findButton) {
        [self createUIManually];
    }

    // 配置初始状态
    self.statusLabel.text = @"请先连接设备";
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.numberOfLines = 0;

    [self.findButton setTitle:@"查找设备" forState:UIControlStateNormal];
    self.findButton.layer.cornerRadius = 8;
    self.findButton.clipsToBounds = YES;

    // 配置时长选择器
    [self.durationSegment removeAllSegments];
    [self.durationSegment insertSegmentWithTitle:@"3秒" atIndex:0 animated:NO];
    [self.durationSegment insertSegmentWithTitle:@"5秒" atIndex:1 animated:NO];
    [self.durationSegment insertSegmentWithTitle:@"10秒" atIndex:2 animated:NO];
    [self.durationSegment insertSegmentWithTitle:@"持续" atIndex:3 animated:NO];
    self.durationSegment.selectedSegmentIndex = 1;  // 默认 5 秒
}

- (void)createUIManually {
    // 状态标签
    UILabel *statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 120, self.view.bounds.size.width - 40, 60)];
    statusLabel.textAlignment = NSTextAlignmentCenter;
    statusLabel.numberOfLines = 0;
    statusLabel.font = [UIFont systemFontOfSize:16];
    [self.view addSubview:statusLabel];
    _statusLabel = statusLabel;

    // 时长选择器
    UISegmentedControl *segment = [[UISegmentedControl alloc] initWithFrame:CGRectMake(20, 200, self.view.bounds.size.width - 40, 40)];
    [self.view addSubview:segment];
    _durationSegment = segment;

    // 查找按钮
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(20, 260, self.view.bounds.size.width - 40, 50);
    button.backgroundColor = [UIColor systemBlueColor];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [button addTarget:self action:@selector(findButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    _findButton = button;

    // 活动指示器
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    indicator.center = CGRectMake(self.view.bounds.size.width / 2, 340, 0, 0).origin;
    [self.view addSubview:indicator];
    _activityIndicator = indicator;
}

// MARK: - 按钮点击事件

- (IBAction)findButtonTapped:(id)sender {
    if ([WPCommands isFindingDevice]) {
        // 正在查找中 → 点击停止
        [self stopFinding];
    } else {
        // 未在查找中 → 点击开始查找
        [self startFinding];
    }
}

// MARK: - 查找操作

- (void)startFinding {
    // 1. 显示加载状态
    [self showLoadingState:YES message:@"正在发送指令..."];

    // 2. 获取选择的持续时间
    NSTimeInterval duration = [self getSelectedDuration];

    // 3. 发送查找指令
    if (duration > 0) {
        // 自动停止模式
        [WPCommands findBandWithDuration:duration completion:^(BOOL success, NSError *error) {
            [self handleFindResult:success error:error isAutoStop:YES];
        }];
    } else {
        // 持续模式（使用设备默认时长）
        [WPCommands findBandWithCompletion:^(BOOL success, NSError *error) {
            [self handleFindResult:success error:error isAutoStop:NO];
        }];
    }

    // 4. 立即更新 UI（不等回调）
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([WPCommands isFindingDevice]) {
            [self showLoadingState:NO message:@""];
            [self updateUIForFindingState];
        }
    });
}

- (void)stopFinding {
    // 1. 显示加载状态
    [self showLoadingState:YES message:@"正在停止..."];

    // 2. 发送停止指令
    [WPCommands stopFindBandWithCompletion:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showLoadingState:NO message:@""];

            if (success) {
                self.statusLabel.text = @"已停止查找";
                NSLog(@"⏹ 停止查找成功");
            } else {
                self.statusLabel.text = [NSString stringWithFormat:@"停止失败: %@", error.localizedDescription];
                [self showError:error.localizedDescription];
            }

            [self updateUI];
        });
    }];
}

// MARK: - 结果处理

- (void)handleFindResult:(BOOL)success error:(NSError *)error isAutoStop:(BOOL)isAutoStop {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showLoadingState:NO message:@""];

        if (success) {
            // 查找成功/停止成功
            if (isAutoStop) {
                self.statusLabel.text = @"查找已自动结束";
                [self showToast:@"查找完成"];
            } else {
                self.statusLabel.text = @"查找已结束";
            }

            NSLog(@"✅ 查找操作完成");
        } else {
            // 查找失败
            self.statusLabel.text = [NSString stringWithFormat:@"操作失败: %@", error.localizedDescription];
            [self showError:error.localizedDescription];

            NSLog(@"❌ 查找失败: %@", error);
        }

        [self updateUI];
    });
}

// MARK: - UI 更新

- (void)updateUI {
    if ([WPCommands isFindingDevice]) {
        [self updateUIForFindingState];
    } else {
        [self updateUIForIdleState];
    }
}

- (void)updateUIForFindingState {
    // 正在查找中的 UI 状态
    [self.findButton setTitle:@"停止查找" forState:UIControlStateNormal];
    self.findButton.backgroundColor = [UIColor systemRedColor];
    self.findButton.enabled = YES;
    self.durationSegment.enabled = NO;

    NSTimeInterval duration = [self getSelectedDuration];
    if (duration > 0) {
        self.statusLabel.text = [NSString stringWithFormat:@"🔍 手环正在震动\n(%.0f秒后自动停止)", duration];
    } else {
        self.statusLabel.text = @"🔍 手环正在震动\n(点击按钮可停止)";
    }
}

- (void)updateUIForIdleState {
    // 未在查找中的 UI 状态
    [self.findButton setTitle:@"查找设备" forState:UIControlStateNormal];
    self.findButton.backgroundColor = [UIColor systemBlueColor];
    self.findButton.enabled = YES;
    self.durationSegment.enabled = YES;

    // 检查连接状态
    BOOL isConnected = [[WPBluetoothManager sharedInstance] isConnected];
    if (!isConnected) {
        self.statusLabel.text = @"⚠️ 设备未连接\n请先连接设备后再查找";
        self.findButton.enabled = NO;
        self.findButton.backgroundColor = [UIColor systemGrayColor];
    }
}

- (void)showLoadingState:(BOOL)loading message:(NSString *)message {
    if (loading) {
        [self.activityIndicator startAnimating];
        self.findButton.enabled = NO;
        self.durationSegment.enabled = NO;
        self.statusLabel.text = message;
    } else {
        [self.activityIndicator stopAnimating];
        self.findButton.enabled = YES;
    }
}

// MARK: - 辅助方法

- (NSTimeInterval)getSelectedDuration {
    switch (self.durationSegment.selectedSegmentIndex) {
        case 0: return 3.0;   // 3 秒
        case 1: return 5.0;   // 5 秒
        case 2: return 10.0;  // 10 秒
        case 3: return 0.0;   // 持续（使用设备默认）
        default: return 5.0;
    }
}

- (void)showToast:(NSString *)message {
    // 简单的 Toast 提示（生产环境可使用第三方库）
    UIAlertController *toast = [UIAlertController alertControllerWithTitle:nil
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:toast animated:YES completion:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [toast dismissViewControllerAnimated:YES completion:nil];
        });
    }];
}

- (void)showError:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"错误"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                             style:UIAlertActionStyleDefault
                                           handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
