//
//  WPLogger.h
//  WatchProtocolSDK-ObjC
//
//  Created by Claude on 2026/01/12.
//  Copyright © 2026 Huaxin. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 日志管理器（单例模式，线程安全）
 */
@interface WPLogger : NSObject

/**
 * 单例实例
 */
+ (instancetype)sharedInstance;

/**
 * 记录日志
 * @param message 日志消息
 */
- (void)log:(NSString *)message;

/**
 * 获取日志文件路径
 */
- (NSString *)logFilePath;

@end

NS_ASSUME_NONNULL_END
