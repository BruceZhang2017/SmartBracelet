//
//  SGSportingViewController.m
//  SGRunning
//
//  Created by 孙冠 on 16/11/4.
//  Copyright © 2016年 sunguan. All rights reserved.
//

#import "SGSportingViewController.h"
#import "SGSportMapViewController.h"

@interface SGSportingViewController () {
    NSTimer * mTimer;
    int count;
}
/**
 运动地图控制器
 */
@property (nonatomic, weak) SGSportMapViewController *mapViewController;

@end

@implementation SGSportingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupMapView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setHidden:true];
    mTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(handleTimer:) userInfo:nil repeats:true];
    [[NSRunLoop currentRunLoop] addTimer:mTimer forMode:NSRunLoopCommonModes];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController.navigationBar setHidden:false];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [mTimer invalidate];
    mTimer = nil;
}

- (void)handleTimer: (NSTimer *)timer {
    count += 1;
    double distance = _mapViewController.sportTracking.totalDistance;
    self.distanceLabel.text = [NSString stringWithFormat:@"%.2f", distance];
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
    // 修改地图控制器的运动状态
    _mapViewController.sportTracking.sportState = sender.tag;
    switch (sender.tag) {
        case 1:
            if (_mapViewController.sportTracking.sportState == SGSportStatePause) {
                _mapViewController.sportTracking.sportState = SGSportStateContinue;
                [self.stopButton setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
                self.stopLabel.text = @"暂停";
                [mTimer setFireDate:[NSDate date]];
            } else {
                _mapViewController.sportTracking.sportState = SGSportStatePause;
                [self.stopButton setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
                self.stopLabel.text = @"继续";
                [mTimer setFireDate:[NSDate distantFuture]];
            }
            break;
        default:
            _mapViewController.sportTracking.sportState = SGSportStateFinish;
            double distance = _mapViewController.sportTracking.totalDistance;
            [[NSUserDefaults standardUserDefaults] setDouble:distance forKey:@"distance"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self.navigationController popViewControllerAnimated:true];
            break;
    }
    
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
}

@end
