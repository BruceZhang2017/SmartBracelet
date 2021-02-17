//
//  SGSportingViewController.m
//  SGRunning
//
//  Created by 孙冠 on 16/11/4.
//  Copyright © 2016年 sunguan. All rights reserved.
//

#import "SGSportingViewController.h"
#import "SGSportMapViewController.h"
#import "CircleProgressView.h"
#import <Toast/Toast.h>
#import "HBLockSliderView.h"

@interface SGSportingViewController ()<HBLockSliderDelegate> {
    NSTimer * mTimer;
    int count;
    CircleProgressView* progressView;
    HBLockSliderView * sliderView;
}
/**
 运动地图控制器
 */
@property (nonatomic, weak) SGSportMapViewController *mapViewController;

@end

@implementation SGSportingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"运动";
    [self setupMapView];
    if ([[UIScreen mainScreen] bounds].size.height > 667) {
        self.bottomHeightLConstraint.constant = 250;
    }
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]
                                               initWithTarget:self action:@selector(handleLongPress:)];
    [self.longEndButton addGestureRecognizer:longPress];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@""] style:UIBarButtonItemStylePlain target:nil action:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    mTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(handleTimer:) userInfo:nil repeats:true];
    [[NSRunLoop currentRunLoop] addTimer:mTimer forMode:NSRunLoopCommonModes];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [mTimer invalidate];
    mTimer = nil;
}

- (void)handleBack {
    
}

-  (void)handleLongPress:(UILongPressGestureRecognizer* )sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        [self removeProgressView];
        [self finishedSport];
    } else if (sender.state == UIGestureRecognizerStateBegan){
        [self addProgressView];
    } else if (sender.state == UIGestureRecognizerStateCancelled) {
        [self removeProgressView];
    }
}

- (void) addProgressView {
    progressView = [[CircleProgressView alloc] initWithFrame:CGRectMake(0, 0, 66, 66)];
    [self.longEndButton addSubview:progressView];
}

- (void) removeProgressView {
    if (progressView == nil) {
        return;
    }
    [progressView removeFromSuperview];
    progressView = nil;
}

- (void)handleTimer: (NSTimer *)timer {
    count += 1;
    double distance = _mapViewController.sportTracking.totalDistance;
    self.distanceLabel.text = [NSString stringWithFormat:@"%.2f", distance];
    self.calLabel.text = [NSString stringWithFormat:@"%.2f", distance * 60 * 1.036];
    double speed = (1 / _mapViewController.sportTracking.avgSpeed) * 60 * 60;
    int total = (int)speed;
    int chi = total / 60;
    int cun = total % 60;
    if (chi < 10000) {
        self.speedLabel.text = [NSString stringWithFormat:@"%d'%02d\"", chi, cun];
    }
    int m = count / 60;
    int s = count % 60;
    self.timeLabel.text = [NSString stringWithFormat:@"%02d:%02d", m, s];
}

- (IBAction)chengeSportState:(UIButton *)sender {
    switch (sender.tag) {
        case 1:
            if (_mapViewController.sportTracking.sportState == SGSportStatePause) {
                _mapViewController.sportTracking.sportState = SGSportStateContinue;
                [self.stopButton setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
                self.stopLabel.text = @"暂停";
                [mTimer setFireDate:[NSDate date]];
            } else {
                _mapViewController.sportTracking.sportState = SGSportStatePause;
                [self.stopButton setImage:[UIImage imageNamed:@"icon_start"] forState:UIControlStateNormal];
                self.stopLabel.text = @"继续";
                [mTimer setFireDate:[NSDate distantFuture]];
            }
            break;
        default:
            [self addLockView];
            break;
    }
}

- (void)addLockView {
    sliderView = [[HBLockSliderView alloc] initWithFrame:CGRectMake(20, 25, [[UIScreen mainScreen] bounds].size.width - 20 * 2, 50)];
    [sliderView setThumbBeginImage:[UIImage imageNamed:@"lock"] finishImage:[UIImage imageNamed:@"unlock"]];
    [self.bottomView addSubview:sliderView];
    sliderView.delegate = self;
    [self.lockButton setHidden:YES];
    [self.lockLabel setHidden: YES];
    [self.stopButton setHidden:YES];
    [self.stopLabel setHidden:YES];
    [self.longEndButton setHidden:YES];
    [self.longEndLabel setHidden: YES];
}

- (void)removeLockView {
    [sliderView removeFromSuperview];
    sliderView.delegate = nil;
    sliderView = nil;
    [self.lockButton setHidden:NO];
    [self.lockLabel setHidden: NO];
    [self.stopButton setHidden:NO];
    [self.stopLabel setHidden:NO];
    [self.longEndButton setHidden:NO];
    [self.longEndLabel setHidden: NO];
}

- (void)finishedSport {
    _mapViewController.sportTracking.sportState = SGSportStateFinish;
    double distance = _mapViewController.sportTracking.totalDistance;
    if (distance < 100) {
        [self.view.window makeToast:@"运动距离过短，本次运动产生的数据将不保存"];
    } else {
        [[NSUserDefaults standardUserDefaults] setDouble:distance forKey:@"distance"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SportData" object:@"finished"];
        [_mapViewController saveLocalMapView: [NSString stringWithFormat:@"%d.png", self.timeStamp]];
    }
    [self.navigationController popViewControllerAnimated:true];
}

- (void)setupMapView {
    // 1. 获取地图控制器
    for (UIViewController *child in self.childViewControllers) {
        if ([child isKindOfClass:[SGSportMapViewController class]]) {
            _mapViewController = (SGSportMapViewController *)child;
            
            break;
        }
    }
    
    // 2. 设置运动轨迹模型
    _mapViewController.sportTracking = [[SGSportTracking alloc] initWithType:_sportType state:SGSportStateContinue];
    
    if (_sportType == SGSportTypeRun) {
        self.sportTypeLabel.text = @"跑步";
    } else if (_sportType == SGSportTypeBike) {
        self.sportTypeLabel.text = @"骑行";
    } else {
        self.sportTypeLabel.text = @"步行";
    }
}

- (void)sliderEndValueChanged:(HBLockSliderView *)slider {
    if (slider.value == 1) {
        [self removeLockView];
    }
}

- (void)sliderValueChanging:(HBLockSliderView *)slider {
    
}

@end
