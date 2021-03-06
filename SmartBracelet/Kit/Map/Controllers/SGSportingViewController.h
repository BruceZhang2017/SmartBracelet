//
//  SGSportingViewController.h
//  SGRunning
//
//  Created by 孙冠 on 16/11/4.
//  Copyright © 2016年 sunguan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SGSportTracking.h"
@interface SGSportingViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *sportTypeLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomHeightLConstraint;

@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *speedLabel;
@property (weak, nonatomic) IBOutlet UILabel *calLabel;
@property(nonatomic,assign) SGSportType sportType;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;
@property (weak, nonatomic) IBOutlet UILabel *stopLabel;
@property (weak, nonatomic) IBOutlet UIButton *lockButton;
@property (weak, nonatomic) IBOutlet UILabel *lockLabel;
@property (weak, nonatomic) IBOutlet UIButton *longEndButton;
@property (weak, nonatomic) IBOutlet UILabel *longEndLabel;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (assign, nonatomic) int timeStamp;

@end
