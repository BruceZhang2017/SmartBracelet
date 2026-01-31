//
//  WPCommands+Alarm.h
//  WatchProtocolSDK-ObjC
//
//  Created by Claude on 2026/01/30.
//  Copyright © 2026 Huaxin. All rights reserved.
//

#import "WPCommands.h"

@class WPAlarmData;

NS_ASSUME_NONNULL_BEGIN

/**
 * WPCommands+Alarm - 闹钟功能扩展
 *
 * 🎯 功能：管理手表的闹钟设置
 * 📡 协议：使用闹钟指令（0x83）控制
 */
@interface WPCommands (Alarm)

/**
 * 查询闹钟总数和可用数量
 * @param completion 完成回调（success: 是否发送成功, error: 错误信息）
 *
 * @discussion 发送查询指令后，设备会返回闹钟总数和可用数量
 * @note 响应数据通过 handleResponse 方法自动解析
 * @note 解析结果会：
 *       1. 自动更新 currentDevice.alarmCount 和 currentDevice.alarmCanUse 属性
 *       2. 触发代理方法 didUpdateAlarmCount:canUse: 回调应用层
 *
 * @note 使用示例:
 * ```objc
 * // 1. 实现代理方法（可选）
 * - (void)didUpdateAlarmCount:(NSInteger)count canUse:(NSInteger)canUse {
 *     NSLog(@"闹钟总数: %ld, 可用: %ld", count, canUse);
 * }
 *
 * // 2. 发送查询指令
 * [WPCommands queryAlarmCount:^(BOOL success, NSError *error) {
 *     if (success) {
 *         // 等待代理回调或读取 currentDevice 属性
 *         NSInteger count = [WPBluetoothManager sharedInstance].currentDevice.alarmCount;
 *     }
 * }];
 * ```
 */
+ (void)queryAlarmCount:(nullable void(^)(BOOL success, NSError * _Nullable error))completion;

/**
 * 查询指定闹钟的详细信息
 * @param alarmId 闹钟索引（从 0 开始）
 * @param completion 完成回调
 *
 * @discussion 发送查询指令后，设备会返回指定闹钟的详细信息
 * @note 响应数据通过 handleResponse 方法自动解析
 * @note 解析结果会：
 *       1. 自动更新 currentDevice.alarms 数组中对应索引的闹钟
 *       2. 触发代理方法 didUpdateAlarmInfo: 回调应用层
 */
+ (void)queryAlarmInfo:(NSInteger)alarmId completion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion;

/**
 * 设置闹钟
 * @param alarm 闹钟数据对象
 * @param completion 完成回调
 *
 * @discussion 设置或更新指定索引的闹钟
 * @note 闹钟数据包含：索引、开关、时间、重复周期等
 * @note 参考 Swift 实现：XGZTCommands.swift alarmInfo 方法
 *
 * @note 使用示例:
 * ```objc
 * WPAlarmData *alarm = [[WPAlarmData alloc] init];
 * alarm.alarmId = 0;
 * alarm.enabled = YES;
 * alarm.hour = 7;
 * alarm.minute = 30;
 * alarm.repeatDays = 0b01111110; // 周一到周五
 *
 * [WPCommands setAlarm:alarm completion:^(BOOL success, NSError *error) {
 *     if (success) {
 *         NSLog(@"✅ 闹钟设置成功");
 *     } else {
 *         NSLog(@"❌ 设置失败: %@", error.localizedDescription);
 *     }
 * }];
 * ```
 */
+ (void)setAlarm:(WPAlarmData *)alarm completion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion;

/**
 * 删除闹钟
 * @param alarmId 闹钟索引
 * @param completion 完成回调
 *
 * @discussion 删除指定索引的闹钟（实际是将该闹钟的 enabled 设为 NO）
 */
+ (void)deleteAlarm:(NSInteger)alarmId completion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion;

/**
 * 查询所有闹钟
 * @param completion 完成回调
 *
 * @discussion 先查询闹钟总数，然后逐个查询每个闹钟的详细信息
 * @note 这是一个便捷方法，内部会自动完成多次查询
 * @note 结果通过多次代理回调 didUpdateAlarmInfo: 返回
 */
+ (void)queryAllAlarms:(nullable void(^)(BOOL success, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
