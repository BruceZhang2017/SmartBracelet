//
//  WPHealthDataStorage.h
//  WatchProtocolSDK-ObjC
//
//  Created by Claude on 2026/01/12.
//  Copyright © 2026 Huaxin. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WPStepData, WPSleepData, WPHeartData, WPOxygenData, WPBloodPressureData;

NS_ASSUME_NONNULL_BEGIN

/**
 * 健康数据存储协议
 * SDK 通过此协议与外部数据存储交互，不直接依赖具体实现
 */
@protocol WPHealthDataStorageProtocol <NSObject>

@required

/**
 * 保存步数数据
 * @param data 步数数据对象
 */
- (void)saveStepData:(WPStepData *)data;

/**
 * 保存睡眠数据
 * @param data 睡眠数据对象
 */
- (void)saveSleepData:(WPSleepData *)data;

/**
 * 保存心率数据
 * @param data 心率数据对象
 */
- (void)saveHeartData:(WPHeartData *)data;

/**
 * 保存血氧数据
 * @param data 血氧数据对象
 */
- (void)saveOxygenData:(WPOxygenData *)data;

/**
 * 保存血压数据
 * @param data 血压数据对象
 */
- (void)saveBloodPressureData:(WPBloodPressureData *)data;

@end

/**
 * 默认空实现（用于测试或无数据存储需求场景）
 */
@interface WPEmptyHealthDataStorage : NSObject <WPHealthDataStorageProtocol>
@end

NS_ASSUME_NONNULL_END
