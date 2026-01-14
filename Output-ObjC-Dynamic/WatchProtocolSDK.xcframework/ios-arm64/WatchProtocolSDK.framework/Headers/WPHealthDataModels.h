//
//  WPHealthDataModels.h
//  WatchProtocolSDK-ObjC
//
//  Created by Claude on 2026/01/12.
//  Copyright © 2026 Huaxin. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// MARK: - 步数数据模型
@interface WPStepData : NSObject

@property (nonatomic, copy, readonly) NSString *date;
@property (nonatomic, copy, readonly) NSString *mac;
@property (nonatomic, assign, readonly) NSInteger step;

- (instancetype)initWithDate:(NSString *)date mac:(NSString *)mac step:(NSInteger)step;

@end

// MARK: - 睡眠数据模型
@interface WPSleepData : NSObject

@property (nonatomic, copy, readonly) NSString *date;
@property (nonatomic, copy, readonly) NSString *mac;
@property (nonatomic, assign, readonly) NSInteger awake;
@property (nonatomic, assign, readonly) NSInteger light;
@property (nonatomic, assign, readonly) NSInteger deep;

- (instancetype)initWithDate:(NSString *)date
                         mac:(NSString *)mac
                       awake:(NSInteger)awake
                       light:(NSInteger)light
                        deep:(NSInteger)deep;

@end

// MARK: - 心率数据模型
@interface WPHeartData : NSObject

@property (nonatomic, copy, readonly) NSString *mac;
@property (nonatomic, assign, readonly) NSInteger time;
@property (nonatomic, assign, readonly) NSInteger heart;

- (instancetype)initWithMac:(NSString *)mac time:(NSInteger)time heart:(NSInteger)heart;

@end

// MARK: - 血氧数据模型
@interface WPOxygenData : NSObject

@property (nonatomic, copy, readonly) NSString *mac;
@property (nonatomic, assign, readonly) NSInteger time;
@property (nonatomic, assign, readonly) NSInteger oxygen;

- (instancetype)initWithMac:(NSString *)mac time:(NSInteger)time oxygen:(NSInteger)oxygen;

@end

// MARK: - 血压数据模型
@interface WPBloodPressureData : NSObject

@property (nonatomic, copy, readonly) NSString *mac;
@property (nonatomic, assign, readonly) NSInteger time;
@property (nonatomic, assign, readonly) NSInteger max;  // 收缩压
@property (nonatomic, assign, readonly) NSInteger min;  // 舒张压

- (instancetype)initWithMac:(NSString *)mac
                       time:(NSInteger)time
                        max:(NSInteger)max
                        min:(NSInteger)min;

@end

NS_ASSUME_NONNULL_END
