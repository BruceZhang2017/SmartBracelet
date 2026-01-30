//
//  WFDeviceScreenInfo.h
//  WatchFaceSDK-ObjC
//
//  Created by Claude on 2026-01-13.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "WFEnums.h"

NS_ASSUME_NONNULL_BEGIN

/// 屏幕尺寸
@interface WFScreenSize : NSObject

@property (nonatomic, assign, readonly) NSInteger width;
@property (nonatomic, assign, readonly) NSInteger height;

- (instancetype)initWithWidth:(NSInteger)width height:(NSInteger)height;
- (CGSize)cgSize;

@end

/// 设备屏幕信息
@interface WFDeviceScreenInfo : NSObject

@property (nonatomic, assign) NSInteger width;
@property (nonatomic, assign) NSInteger height;
@property (nonatomic, assign) WFScreenShape shape;
@property (nonatomic, assign) NSInteger mtu;

- (instancetype)initWithWidth:(NSInteger)width
                       height:(NSInteger)height
                        shape:(WFScreenShape)shape
                          mtu:(NSInteger)mtu;

- (WFScreenSize *)size;
- (CGSize)cgSize;

@end

NS_ASSUME_NONNULL_END
