//
//  WPCommands+Reminder.h
//  WatchProtocolSDK-ObjC
//
//  Created by Claude on 2026/01/30.
//  Copyright © 2026 Huaxin. All rights reserved.
//

#import "WPCommands.h"

@class WPReminderInfo;

NS_ASSUME_NONNULL_BEGIN

/**
 * 提醒类型枚举
 */
typedef NS_ENUM(NSInteger, WPReminderType) {
    WPReminderTypeLongSit = 0,      // 久坐提醒
    WPReminderTypeDrinkWater = 1    // 喝水提醒
};

/**
 * WPCommands+Reminder - 久坐提醒和喝水提醒功能扩展
 *
 * 🎯 功能：管理手表的久坐提醒和喝水提醒
 * 📡 协议：使用提醒指令（0x85）控制
 */
@interface WPCommands (Reminder)

// MARK: - 查询提醒

/**
 * 查询久坐提醒设置
 * @param completion 完成回调
 *
 * @discussion 发送查询指令后，设备会返回久坐提醒的详细信息
 * @note 响应数据通过 handleResponse 方法自动解析
 * @note 解析结果会：
 *       1. 自动更新 currentDevice.longSit 属性
 *       2. 触发代理方法 didUpdateLongSitReminder: 回调应用层
 *
 * @note 使用示例:
 * ```objc
 * // 1. 实现代理方法（可选）
 * - (void)didUpdateLongSitReminder:(WPReminderInfo *)reminder {
 *     NSLog(@"久坐提醒: %@, 时段 %02ld:%02ld-%02ld:%02ld, 间隔 %ld 分钟",
 *           reminder.enabled ? @"开启" : @"关闭",
 *           reminder.startHour, reminder.startMinute,
 *           reminder.endHour, reminder.endMinute,
 *           reminder.interval);
 * }
 *
 * // 2. 发送查询指令
 * [WPCommands queryLongSitReminder:^(BOOL success, NSError *error) {
 *     if (success) {
 *         WPReminderInfo *reminder = [WPBluetoothManager sharedInstance].currentDevice.longSit;
 *     }
 * }];
 * ```
 */
+ (void)queryLongSitReminder:(nullable void(^)(BOOL success, NSError * _Nullable error))completion;

/**
 * 查询喝水提醒设置
 * @param completion 完成回调
 *
 * @discussion 发送查询指令后，设备会返回喝水提醒的详细信息
 * @note 响应数据通过 handleResponse 方法自动解析
 * @note 解析结果会：
 *       1. 自动更新 currentDevice.drinkWater 属性
 *       2. 触发代理方法 didUpdateDrinkWaterReminder: 回调应用层
 */
+ (void)queryDrinkWaterReminder:(nullable void(^)(BOOL success, NSError * _Nullable error))completion;

/**
 * 查询指定类型的提醒
 * @param reminderType 提醒类型（久坐或喝水）
 * @param completion 完成回调
 */
+ (void)queryReminder:(WPReminderType)reminderType completion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion;

// MARK: - 设置提醒

/**
 * 设置久坐提醒
 * @param reminder 久坐提醒数据对象
 * @param completion 完成回调
 *
 * @discussion 设置久坐提醒的时间段、间隔等参数
 * @note 参考 Swift 实现：XGZTCommands.swift reminderInfo 方法
 *
 * @note 使用示例:
 * ```objc
 * WPReminderInfo *reminder = [[WPReminderInfo alloc] init];
 * reminder.enabled = YES;
 * reminder.startHour = 9;
 * reminder.startMinute = 0;
 * reminder.endHour = 18;
 * reminder.endMinute = 0;
 * reminder.interval = 60;  // 每60分钟提醒一次
 *
 * [WPCommands setLongSitReminder:reminder completion:^(BOOL success, NSError *error) {
 *     if (success) {
 *         NSLog(@"✅ 久坐提醒设置成功");
 *     } else {
 *         NSLog(@"❌ 设置失败: %@", error.localizedDescription);
 *     }
 * }];
 * ```
 */
+ (void)setLongSitReminder:(WPReminderInfo *)reminder completion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion;

/**
 * 设置喝水提醒
 * @param reminder 喝水提醒数据对象
 * @param completion 完成回调
 *
 * @discussion 设置喝水提醒的时间段、间隔等参数
 */
+ (void)setDrinkWaterReminder:(WPReminderInfo *)reminder completion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion;

/**
 * 设置提醒（通用方法）
 * @param reminder 提醒数据对象
 * @param reminderType 提醒类型
 * @param completion 完成回调
 */
+ (void)setReminder:(WPReminderInfo *)reminder type:(WPReminderType)reminderType completion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion;

// MARK: - 快捷方法

/**
 * 开启久坐提醒（使用默认参数）
 * @param completion 完成回调
 *
 * @discussion 使用默认参数开启久坐提醒：
 *             - 时间段：09:00 - 18:00
 *             - 间隔：60分钟
 */
+ (void)enableLongSitReminderWithCompletion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion;

/**
 * 关闭久坐提醒
 * @param completion 完成回调
 */
+ (void)disableLongSitReminderWithCompletion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion;

/**
 * 开启喝水提醒（使用默认参数）
 * @param completion 完成回调
 *
 * @discussion 使用默认参数开启喝水提醒：
 *             - 时间段：08:00 - 20:00
 *             - 间隔：120分钟
 */
+ (void)enableDrinkWaterReminderWithCompletion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion;

/**
 * 关闭喝水提醒
 * @param completion 完成回调
 */
+ (void)disableDrinkWaterReminderWithCompletion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
