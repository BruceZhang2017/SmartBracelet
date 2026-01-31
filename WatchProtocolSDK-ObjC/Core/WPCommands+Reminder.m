//
//  WPCommands+Reminder.m
//  WatchProtocolSDK-ObjC
//
//  Created by Claude on 2026/01/30.
//  Copyright © 2026 Huaxin. All rights reserved.
//

#import "WPCommands+Reminder.h"
#import "WPBluetoothManager.h"
#import "WPLogger.h"
#import "../Models/WPDeviceModel.h"

// MARK: - 错误域定义
static NSString * const WPReminderErrorDomain = @"com.huaxin.watchprotocolsdk.reminder";

// MARK: - 错误码定义
typedef NS_ENUM(NSInteger, WPReminderErrorCode) {
    WPReminderErrorCodeDeviceNotConnected = 4001,  // 设备未连接
    WPReminderErrorCodeSendFailed = 4002,          // 指令发送失败
    WPReminderErrorCodeBluetoothOff = 4003,        // 蓝牙未开启
    WPReminderErrorCodeInvalidParameter = 4004     // 参数无效
};

@implementation WPCommands (Reminder)

// MARK: - 🔧 辅助方法

/**
 * 创建错误对象
 */
+ (NSError *)createReminderError:(WPReminderErrorCode)code message:(NSString *)message {
    return [NSError errorWithDomain:WPReminderErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: message}];
}

/**
 * 检查设备连接状态
 */
+ (nullable NSError *)checkReminderDeviceConnection {
    WPBluetoothManager *btManager = [WPBluetoothManager sharedInstance];

    if (btManager.isBluetoothPoweredOff) {
        return [self createReminderError:WPReminderErrorCodeBluetoothOff message:@"蓝牙未开启，请先打开蓝牙"];
    }

    if (!btManager.isConnected) {
        return [self createReminderError:WPReminderErrorCodeDeviceNotConnected message:@"设备未连接，请先连接设备"];
    }

    return nil;
}

/**
 * 验证提醒参数
 */
+ (nullable NSError *)validateReminder:(WPReminderInfo *)reminder {
    if (!reminder) {
        return [self createReminderError:WPReminderErrorCodeInvalidParameter message:@"提醒数据不能为空"];
    }

    if (reminder.startHour < 0 || reminder.startHour > 23 ||
        reminder.startMinute < 0 || reminder.startMinute > 59 ||
        reminder.endHour < 0 || reminder.endHour > 23 ||
        reminder.endMinute < 0 || reminder.endMinute > 59) {
        return [self createReminderError:WPReminderErrorCodeInvalidParameter message:@"时间参数无效"];
    }

    if (reminder.interval < 0) {
        return [self createReminderError:WPReminderErrorCodeInvalidParameter message:@"间隔时间不能为负数"];
    }

    return nil;
}

/**
 * 获取提醒类型名称（用于日志）
 */
+ (NSString *)reminderTypeName:(WPReminderType)type {
    return type == WPReminderTypeLongSit ? @"久坐提醒" : @"喝水提醒";
}

// MARK: - 🔥 查询提醒

+ (void)queryReminder:(WPReminderType)reminderType completion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion {
    // 1. 检查设备连接
    NSError *connectionError = [self checkReminderDeviceConnection];
    if (connectionError) {
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"❌ 查询%@失败: %@",
            [self reminderTypeName:reminderType], connectionError.localizedDescription]];
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, connectionError);
            });
        }
        return;
    }

    // 2. 构建查询指令
    // 参考 Swift: XGZTCommands.swift getReminderInfo
    // 协议格式：[Header] [0x85] [Length] [0x00=查询] [eventType]
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeReminderInfo),  // 0x85
        @(0x01),
        @(0x00),
        @(0x02),           // ✅ 修正：长度改为 0x02
        @(0x00),           // 0x00 = 查询
        @(reminderType)    // ✅ 修正：移除末尾多余的 0x00
    ]];

    // 3. 发送指令
    WPBluetoothManager *btManager = [WPBluetoothManager sharedInstance];
    BOOL success = [btManager sendData:command];

    if (success) {
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"🔍 查询%@指令已发送", [self reminderTypeName:reminderType]]];

        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(YES, nil);
            });
        }
    } else {
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"❌ 查询%@指令发送失败", [self reminderTypeName:reminderType]]];

        if (completion) {
            NSError *error = [self createReminderError:WPReminderErrorCodeSendFailed message:@"指令发送失败"];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
        }
    }
}

+ (void)queryLongSitReminder:(nullable void(^)(BOOL success, NSError * _Nullable error))completion {
    [self queryReminder:WPReminderTypeLongSit completion:completion];
}

+ (void)queryDrinkWaterReminder:(nullable void(^)(BOOL success, NSError * _Nullable error))completion {
    [self queryReminder:WPReminderTypeDrinkWater completion:completion];
}

// MARK: - 🔥 设置提醒

+ (void)setReminder:(WPReminderInfo *)reminder type:(WPReminderType)reminderType completion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion {
    // 1. 参数校验
    NSError *validationError = [self validateReminder:reminder];
    if (validationError) {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, validationError);
            });
        }
        return;
    }

    // 2. 检查设备连接
    NSError *connectionError = [self checkReminderDeviceConnection];
    if (connectionError) {
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"❌ 设置%@失败: %@",
            [self reminderTypeName:reminderType], connectionError.localizedDescription]];
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, connectionError);
            });
        }
        return;
    }

    // 3. 构建设置指令
    // 参考 Swift: XGZTCommands.swift setReminderInfo
    // 协议格式：[Header] [0x85] [Length] [0x01=设置] [eventType] [cycle] [startHour] [startMinute] [endHour] [endMinute] [period]
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeReminderInfo),  // 0x85
        @(0x01),
        @(0x00),
        @(0x08),                       // 长度 8 字节
        @(0x01),                       // 0x01 = 设置
        @(reminderType),               // 事件类型
        @(reminder.enabled ? 1 : 0),   // cycle（周期/开关）
        @(reminder.startHour),         // 开始小时
        @(reminder.startMinute),       // 开始分钟
        @(reminder.endHour),           // 结束小时
        @(reminder.endMinute),         // 结束分钟
        @(reminder.interval)           // period（间隔）
    ]];

    // 4. 发送指令
    WPBluetoothManager *btManager = [WPBluetoothManager sharedInstance];
    BOOL success = [btManager sendData:command];

    if (success) {
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:
            @"⏰ %@设置指令已发送: %@, 时段 %02ld:%02ld-%02ld:%02ld, 间隔 %ld 分钟",
            [self reminderTypeName:reminderType],
            reminder.enabled ? @"开启" : @"关闭",
            (long)reminder.startHour, (long)reminder.startMinute,
            (long)reminder.endHour, (long)reminder.endMinute,
            (long)reminder.interval]];

        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(YES, nil);
            });
        }
    } else {
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"❌ %@设置指令发送失败", [self reminderTypeName:reminderType]]];

        if (completion) {
            NSError *error = [self createReminderError:WPReminderErrorCodeSendFailed message:@"指令发送失败"];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
        }
    }
}

+ (void)setLongSitReminder:(WPReminderInfo *)reminder completion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion {
    [self setReminder:reminder type:WPReminderTypeLongSit completion:completion];
}

+ (void)setDrinkWaterReminder:(WPReminderInfo *)reminder completion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion {
    [self setReminder:reminder type:WPReminderTypeDrinkWater completion:completion];
}

// MARK: - 🔥 快捷方法

+ (void)enableLongSitReminderWithCompletion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion {
    WPReminderInfo *reminder = [[WPReminderInfo alloc] init];
    reminder.enabled = YES;
    reminder.startHour = 9;
    reminder.startMinute = 0;
    reminder.endHour = 18;
    reminder.endMinute = 0;
    reminder.interval = 60;  // 每60分钟提醒一次

    [self setLongSitReminder:reminder completion:completion];
}

+ (void)disableLongSitReminderWithCompletion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion {
    WPReminderInfo *reminder = [[WPReminderInfo alloc] init];
    reminder.enabled = NO;
    reminder.startHour = 0;
    reminder.startMinute = 0;
    reminder.endHour = 0;
    reminder.endMinute = 0;
    reminder.interval = 0;

    [self setLongSitReminder:reminder completion:completion];
}

+ (void)enableDrinkWaterReminderWithCompletion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion {
    WPReminderInfo *reminder = [[WPReminderInfo alloc] init];
    reminder.enabled = YES;
    reminder.startHour = 8;
    reminder.startMinute = 0;
    reminder.endHour = 20;
    reminder.endMinute = 0;
    reminder.interval = 120;  // 每120分钟提醒一次

    [self setDrinkWaterReminder:reminder completion:completion];
}

+ (void)disableDrinkWaterReminderWithCompletion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion {
    WPReminderInfo *reminder = [[WPReminderInfo alloc] init];
    reminder.enabled = NO;
    reminder.startHour = 0;
    reminder.startMinute = 0;
    reminder.endHour = 0;
    reminder.endMinute = 0;
    reminder.interval = 0;

    [self setDrinkWaterReminder:reminder completion:completion];
}

@end
