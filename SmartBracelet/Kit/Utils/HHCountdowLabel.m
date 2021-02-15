//
//  HHCountdowLabel.m
//  HHCountdown
//
//  Created by chh on 2017/7/27.
//  Copyright © 2017年 chh. All rights reserved.
//

#import "HHCountdowLabel.h"
@interface HHCountdowLabel() {
    void (^_cycleReferenceBlock)(void);
}
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation HHCountdowLabel

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]){
        self.textAlignment = NSTextAlignmentCenter;
    }
    return self;
}
//开始倒计时
- (void)startCount: (void (^)(void))callback {
    [self initTimer];
    _cycleReferenceBlock = callback;
}

- (void)initTimer{
    //如果没有设置，则默认为3
    if (self.count == 0){
        self.count = 3;
    }
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(countDown) userInfo:nil repeats:YES];
}

- (void)countDown{
    if (_count > 0){
        self.text = [NSString stringWithFormat:@"%d",_count];
        CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        opacityAnimation.fromValue = [NSNumber numberWithFloat:1.0];
        opacityAnimation.toValue = [NSNumber numberWithFloat:0.2];
        
        CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        scaleAnimation.fromValue = [NSNumber numberWithFloat:1.0];
        scaleAnimation.toValue = [NSNumber numberWithFloat:3.0];
        scaleAnimation.duration = 1.0f;
        scaleAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];

        CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
        animationGroup.duration = 1.0f;
        animationGroup.autoreverses = YES;   //是否重播，原动画的倒播
        animationGroup.repeatCount = NSNotFound;//HUGE_VALF;     //HUGE_VALF,源自math.h
        animationGroup.removedOnCompletion = YES;
        [animationGroup setAnimations:[NSArray arrayWithObjects:opacityAnimation, scaleAnimation, nil]];
        
        [self.layer addAnimation:animationGroup forKey:@"animationGroup"];
        
        _count -= 1;
    }else {
        [_timer invalidate];
        [self removeFromSuperview];
        _cycleReferenceBlock();
    }
}

@end
