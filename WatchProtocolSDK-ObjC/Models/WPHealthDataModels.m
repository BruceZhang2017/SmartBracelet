//
//  WPHealthDataModels.m
//  WatchProtocolSDK-ObjC
//
//  Created by Claude on 2026/01/12.
//  Copyright © 2026 Huaxin. All rights reserved.
//

#import "WPHealthDataModels.h"

// MARK: - 步数数据模型实现
@implementation WPStepData

- (instancetype)initWithDate:(NSString *)date mac:(NSString *)mac step:(NSInteger)step {
    self = [super init];
    if (self) {
        _date = [date copy];
        _mac = [mac copy];
        _step = step;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<WPStepData: date=%@, mac=%@, step=%ld>",
            self.date, self.mac, (long)self.step];
}

@end

// MARK: - 睡眠数据模型实现
@implementation WPSleepData

- (instancetype)initWithDate:(NSString *)date
                         mac:(NSString *)mac
                       awake:(NSInteger)awake
                       light:(NSInteger)light
                        deep:(NSInteger)deep {
    self = [super init];
    if (self) {
        _date = [date copy];
        _mac = [mac copy];
        _awake = awake;
        _light = light;
        _deep = deep;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<WPSleepData: date=%@, mac=%@, awake=%ld, light=%ld, deep=%ld>",
            self.date, self.mac, (long)self.awake, (long)self.light, (long)self.deep];
}

@end

// MARK: - 心率数据模型实现
@implementation WPHeartData

- (instancetype)initWithMac:(NSString *)mac time:(NSInteger)time heart:(NSInteger)heart {
    self = [super init];
    if (self) {
        _mac = [mac copy];
        _time = time;
        _heart = heart;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<WPHeartData: mac=%@, time=%ld, heart=%ld>",
            self.mac, (long)self.time, (long)self.heart];
}

@end

// MARK: - 血氧数据模型实现
@implementation WPOxygenData

- (instancetype)initWithMac:(NSString *)mac time:(NSInteger)time oxygen:(NSInteger)oxygen {
    self = [super init];
    if (self) {
        _mac = [mac copy];
        _time = time;
        _oxygen = oxygen;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<WPOxygenData: mac=%@, time=%ld, oxygen=%ld>",
            self.mac, (long)self.time, (long)self.oxygen];
}

@end

// MARK: - 血压数据模型实现
@implementation WPBloodPressureData

- (instancetype)initWithMac:(NSString *)mac
                       time:(NSInteger)time
                        max:(NSInteger)max
                        min:(NSInteger)min {
    self = [super init];
    if (self) {
        _mac = [mac copy];
        _time = time;
        _max = max;
        _min = min;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<WPBloodPressureData: mac=%@, time=%ld, max=%ld, min=%ld>",
            self.mac, (long)self.time, (long)self.max, (long)self.min];
}

@end
