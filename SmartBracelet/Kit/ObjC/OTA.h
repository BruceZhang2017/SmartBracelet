//
//  DownloadFiles.h
//  OTA-2-16-OC
//
//  Created by Arvin on 2017/2/16.
//  Copyright © 2017年 Arvin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTACMD.h"

@protocol OTADelegate <NSObject>

- (void)callback: (CGFloat)progress;

@end

@interface OTA : NSObject

+ (instancetype)share;

@property (strong, nonatomic) OTACMD* otaCMD;
@property (weak, nonatomic) id<OTADelegate> delegate;

- (void)initialCMD;
- (void)ota;
- (void)handleOTA;

@end
