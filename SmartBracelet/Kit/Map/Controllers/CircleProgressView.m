//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  CircleProgressView.m
//  SmartBracelet
//
//  Created by ANKER on 2021/2/15.
//  Copyright © 2021 tjd. All rights reserved.
//
	

#import "CircleProgressView.h"

 @interface CircleProgressView() {
    NSUInteger num;
}
/** timer */
@property (nonatomic, strong) NSTimer *timer;
/** 背景layer */
@property (nonatomic, strong) CAShapeLayer *backgroundLayer;
/** 进度条layer */
@property (nonatomic, strong) CAShapeLayer *progressLayer;

@end

@implementation CircleProgressView

- (void)dealloc {
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self buildView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

- (void)buildView {
    // 设置self
    self.transform = CGAffineTransformMakeRotation(-M_PI_2);
    self.layer.cornerRadius = self.frame.size.width * 0.5;
    self.layer.masksToBounds = YES;
    // 设置进度条的背景 Layer
    [self.layer addSublayer:self.backgroundLayer];
    // 设置进度条 Layer
    [self.layer addSublayer:self.progressLayer];
    self.progressLayer.strokeEnd = 0;
    // 设置 Timer
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval: 0.1 target:self selector:@selector(timeInterval) userInfo:nil repeats:YES];
    self.timer = timer;
}

- (CALayer *)backgroundLayer {
    if (!_backgroundLayer) {
        _backgroundLayer = [self buildShapeLayerColor:[UIColor clearColor] lineWidth: 2];
    }
    return _backgroundLayer;
}

- (CALayer *)progressLayer {
    if (!_progressLayer) {
        _progressLayer =  [self buildShapeLayerColor:[UIColor whiteColor] lineWidth: 2];
    }
    return _progressLayer;
}

- (CAShapeLayer *)buildShapeLayerColor:(UIColor *)color lineWidth:(CGFloat)width  {
    CAShapeLayer *layer = [CAShapeLayer layer];
    CGRect rect = {2 * 0.5, 2 * 0.5, self.frame.size.width - 2, self.frame.size.height - 2};
    // 设置path
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:rect];
    layer.path = path.CGPath;
    // 设置layer
    layer.strokeColor = color.CGColor;
    layer.fillColor = [UIColor clearColor].CGColor;
    layer.lineWidth = width;
    layer.lineCap = kCALineCapRound;
    return layer;
}

- (void)timeInterval {
    if (num == 20) {
        [self.timer invalidate];
        self.timer = nil;
    }
    num ++;
    [self updateProgressWithNumber:num];
}

- (void)updateProgressWithNumber:(NSUInteger)number {
    [CATransaction begin];

    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
    [CATransaction setAnimationDuration:1];
    // 20为倒计时时间
    self.progressLayer.strokeEnd = number / 20.0f;
    
    [CATransaction commit];
}

@end
