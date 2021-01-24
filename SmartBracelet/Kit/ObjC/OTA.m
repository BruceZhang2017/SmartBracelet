//
//  DownloadFiles.m
//  OTA-2-16-OC
//
//  Created by Arvin on 2017/2/16.
//  Copyright © 2017年 Arvin. All rights reserved.
//


//#define kSelectThisFileForOTA (@"it will select this file for OTA")

#import "OTA.h"

@interface OTA ()

@property (assign, nonatomic) BOOL isOnePartSent;
@property (assign, nonatomic) BOOL isStartOTA;
@property (assign, nonatomic) BOOL isSingleOTAFinish;
@property (strong, nonatomic) NSTimer *otaTimer;
@property (strong, nonatomic) NSTimer *endTimer;
@property (strong, nonatomic) NSData *localData;
@property (assign, nonatomic) NSInteger location;
@property (assign, nonatomic) NSInteger count;
@end

@implementation OTA
@synthesize otaCMD;
@synthesize delegate;

+ (instancetype)share {
    static OTA *ota = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        ota = [[OTA alloc] init];
    });
    return ota;
}

- (void)initialCMD {
    otaCMD = [[OTACMD alloc] init];
}

- (void)ota {
    NSString *path = [[NSBundle mainBundle] pathForResource: @"8267_module_tOTA" ofType:@"bin"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    
    if (data.length) {
        [otaCMD versionGet];
        [otaCMD startOTA];
        otaCMD.otaPackIndex = 0;
        
        self.localData = data;
        self.count = (self.localData.length % 16) ? (self.localData.length/16 + 1) : (self.localData.length/16);
        _isStartOTA = YES;
        NSLog(@"总包数：%ld", self.count);
        [self performSelector:@selector(sendDataPack) withObject:nil afterDelay:0.3];
    }
}

- (void)stopSendDataPack {
    self.isSingleOTAFinish = NO;
    self.isStartOTA = NO;
    self.localData = nil;
    if (self.otaTimer != nil) {
        [self.otaTimer invalidate];
        self.otaTimer = nil;
    }
}

- (void)sendDataPack {
    if (self.otaTimer != nil) {
        [self.otaTimer invalidate];
        self.otaTimer = nil;
    }
    self.isStartOTA = YES;
    NSUInteger packLoction;
    NSUInteger packLength;
    NSUInteger length;
    if (otaCMD.otaPackIndex > self.count) return;
    NSLog(@"当前包数：%ld", otaCMD.otaPackIndex);
    if (otaCMD.otaPackIndex < self.count) {
        if(otaCMD.otaPackIndex == self.count-1){
            packLength = self.localData.length-otaCMD.otaPackIndex*16;
            length = self.localData.length;
        }else{
            packLength = 16;
            length = otaCMD.otaPackIndex*16;
        }
        packLoction = otaCMD.otaPackIndex*16;
        NSRange range = NSMakeRange(packLoction, packLength);
        NSData *sendData = [self.localData subdataWithRange:range];
        
        [otaCMD sendOTAPackData:sendData];
        CGFloat progress = (otaCMD.otaPackIndex+1) * 1.0 / self.count * 1.0;
        if ([delegate respondsToSelector:@selector(callback:)]) {
            [delegate callback:progress * 100];
        }
    } else {
        packLength = 0;
        length = self.localData.length;
        if ([delegate respondsToSelector:@selector(callback:)]) {
            [delegate callback: 100];
        }
        [otaCMD endOTA];
        
        self.isSingleOTAFinish = YES;
        self.count = 0;
        self.location = 0;
    }
    if (length % (16*8) == 0 && length) {
        self.isOnePartSent = YES;
        [otaCMD readOTA];
        NSLog(@"执行读取操作");
        otaCMD.otaPackIndex++;
        return;
    }
    otaCMD.otaPackIndex++;
    self.otaTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(sendDataPack) userInfo:nil repeats:YES];
}

- (void)handleOTA {
    if (self.isOnePartSent&&!self.isSingleOTAFinish) {
        _isOnePartSent = NO;
        [self sendDataPack];
        return;
    }
    if (self.isStartOTA&&!_isSingleOTAFinish) {
        [self sendDataPack];
    }
}
    
@end
