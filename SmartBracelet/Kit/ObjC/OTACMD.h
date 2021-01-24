//
//  Bluetooth.h
//  OTA-2-16-OC
//
//  Created by Arvin on 2017/2/16.
//  Copyright © 2017年 Arvin. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OTACMDDelegate<NSObject>
    
- (void)writeOTAData:(NSData *)data;
- (void)readOTA;
    
@end

@interface OTACMD : NSObject

@property (assign, nonatomic) NSUInteger otaPackIndex;
@property (weak, nonatomic) id<OTACMDDelegate> delegate;

- (void)versionGet;
- (void)startOTA;
- (void)endOTA;
- (void)sendOTAPackData:(NSData *)data;
- (void)readOTA;

@end
