//
//  WFDeviceScreenInfo.m
//  WatchFaceSDK-ObjC
//
//  Created by Claude on 2026-01-13.
//

#import "WFDeviceScreenInfo.h"

@implementation WFScreenSize

- (instancetype)initWithWidth:(NSInteger)width height:(NSInteger)height {
    self = [super init];
    if (self) {
        _width = width;
        _height = height;
    }
    return self;
}

- (CGSize)cgSize {
    return CGSizeMake(self.width, self.height);
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<WFScreenSize: %ldx%ld>", (long)self.width, (long)self.height];
}

@end

@implementation WFDeviceScreenInfo

- (instancetype)initWithWidth:(NSInteger)width
                       height:(NSInteger)height
                        shape:(WFScreenShape)shape
                          mtu:(NSInteger)mtu {
    self = [super init];
    if (self) {
        _width = width;
        _height = height;
        _shape = shape;
        _mtu = mtu;
    }
    return self;
}

- (WFScreenSize *)size {
    return [[WFScreenSize alloc] initWithWidth:self.width height:self.height];
}

- (CGSize)cgSize {
    return CGSizeMake(self.width, self.height);
}

- (NSString *)description {
    NSString *shapeStr = (self.shape == WFScreenShapeRound) ? @"round" : @"square";
    return [NSString stringWithFormat:@"<WFDeviceScreenInfo: %ldx%ld, shape:%@, mtu:%ld>",
            (long)self.width, (long)self.height, shapeStr, (long)self.mtu];
}

@end
