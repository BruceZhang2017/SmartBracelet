//
//  WPCommands+Alarm.m
//  WatchProtocolSDK-ObjC
//
//  Created by Claude on 2026/01/30.
//  Copyright © 2026 Huaxin. All rights reserved.
//

#import "WPCommands+Alarm.h"
#import "WPBluetoothManager.h"
#import "WPLogger.h"
#import "../Models/WPDeviceModel.h"

// MARK: - 错误域定义
static NSString * const WPAlarmErrorDomain = @"com.huaxin.watchprotocolsdk.alarm";

// MARK: - 错误码定义
typedef NS_ENUM(NSInteger, WPAlarmErrorCode) {
    WPAlarmErrorCodeDeviceNotConnected = 3001,  // 设备未连接
    WPAlarmErrorCodeSendFailed = 3002,          // 指令发送失败
    WPAlarmErrorCodeBluetoothOff = 3003,        // 蓝牙未开启
    WPAlarmErrorCodeInvalidParameter = 3004     // 参数无效
};

@implementation WPCommands (Alarm)

// MARK: - 🔧 辅助方法

/**
 * 创建错误对象
 */
+ (NSError *)createError:(WPAlarmErrorCode)code message:(NSString *)message {
    return [NSError errorWithDomain:WPAlarmErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: message}];
}

/**
 * 检查设备连接状态
 * @return 返回错误对象，如果无错误则返回 nil
 */
+ (nullable NSError *)checkDeviceConnection {
    WPBluetoothManager *btManager = [WPBluetoothManager sharedInstance];

    if (btManager.isBluetoothPoweredOff) {
        return [self createError:WPAlarmErrorCodeBluetoothOff message:@"蓝牙未开启，请先打开蓝牙"];
    }

    if (!btManager.isConnected) {
        return [self createError:WPAlarmErrorCodeDeviceNotConnected message:@"设备未连接，请先连接设备"];
    }

    return nil;
}

// MARK: - 🔥 核心方法实现

+ (void)queryAlarmCount:(nullable void(^)(BOOL success, NSError * _Nullable error))completion {
    // 1. 检查设备连接
    NSError *connectionError = [self checkDeviceConnection];
    if (connectionError) {
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"❌ 查询闹钟总数失败: %@", connectionError.localizedDescription]];
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, connectionError);
            });
        }
        return;
    }

    // 2. 构建查询指令
    // 参考 Swift: XGZTCommands.swift alarmInfo (查询类型)
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeAlarmInfo),  // 0x83
        @(0x01),
        @(0x00),
        @(0x02),
        @(0x00),  // 0x00 = 查询总数
        @(0x00)
    ]];

    // 3. 发送指令
    WPBluetoothManager *btManager = [WPBluetoothManager sharedInstance];
    BOOL success = [btManager sendData:command];

    if (success) {
        [[WPLogger sharedInstance] log:@"🔍 查询闹钟总数指令已发送"];

        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(YES, nil);
            });
        }
    } else {
        [[WPLogger sharedInstance] log:@"❌ 查询闹钟总数指令发送失败"];

        if (completion) {
            NSError *error = [self createError:WPAlarmErrorCodeSendFailed message:@"指令发送失败，请重试"];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
        }
    }
}

+ (void)queryAlarmInfo:(NSInteger)alarmId completion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion {
    // 1. 参数校验
    if (alarmId < 0) {
        NSError *error = [self createError:WPAlarmErrorCodeInvalidParameter message:@"闹钟索引不能为负数"];
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
        }
        return;
    }

    // 2. 检查设备连接
    NSError *connectionError = [self checkDeviceConnection];
    if (connectionError) {
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"❌ 查询闹钟 %ld 失败: %@", (long)alarmId, connectionError.localizedDescription]];
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, connectionError);
            });
        }
        return;
    }

    // 3. 构建查询指令
    // 参考 Swift: XGZTCommands.swift getAlarmInfo
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeAlarmInfo),  // 0x83
        @(0x01),
        @(0x00),
        @(0x02),
        @(0x00),       // 0x00 = 查询
        @(alarmId)     // type (闹钟索引)
    ]];

    // 4. 发送指令
    WPBluetoothManager *btManager = [WPBluetoothManager sharedInstance];
    BOOL success = [btManager sendData:command];

    if (success) {
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"🔍 查询闹钟 %ld 详细信息指令已发送", (long)alarmId]];

        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(YES, nil);
            });
        }
    } else {
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"❌ 查询闹钟 %ld 指令发送失败", (long)alarmId]];

        if (completion) {
            NSError *error = [self createError:WPAlarmErrorCodeSendFailed message:@"指令发送失败"];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
        }
    }
}

+ (void)setAlarm:(WPAlarmData *)alarm completion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion {
    // 1. 参数校验
    if (!alarm) {
        NSError *error = [self createError:WPAlarmErrorCodeInvalidParameter message:@"闹钟数据不能为空"];
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
        }
        return;
    }

    if (alarm.alarmId < 0 || alarm.hour < 0 || alarm.hour > 23 || alarm.minute < 0 || alarm.minute > 59) {
        NSError *error = [self createError:WPAlarmErrorCodeInvalidParameter message:@"闹钟参数无效"];
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
        }
        return;
    }

    // 2. 检查设备连接
    NSError *connectionError = [self checkDeviceConnection];
    if (connectionError) {
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"❌ 设置闹钟失败: %@", connectionError.localizedDescription]];
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, connectionError);
            });
        }
        return;
    }

    // 3. 构建设置指令
    // 参考 Swift: XGZTCommands.swift setAlarmInfo
    // 协议格式：[Header] [0x83] [Length] [0x01] [setCmd] [index] [switch] [cycle] [hour] [minute] [vibration] [later]
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeAlarmInfo),  // 0x83
        @(0x01),
        @(0x00),
        @(0x09),                    // 长度 9 字节
        @(0x01),                    // 0x01 = 设置操作
        @(0x00),                    // setCmd (默认 0)
        @(alarm.alarmIndex),        // 闹钟索引
        @(alarm.mswitch),           // 开关
        @(alarm.alarmCycle),        // 重复周期
        @(alarm.alarmHour),         // 小时
        @(alarm.alarmMinute),       // 分钟
        @(alarm.vibrationMode),     // 振动模式
        @(alarm.remindLater)        // 稍后提醒
    ]];

    // 4. 发送指令
    WPBluetoothManager *btManager = [WPBluetoothManager sharedInstance];
    BOOL success = [btManager sendData:command];

    if (success) {
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:
            @"⏰ 闹钟设置指令已发送: ID=%ld, %@, %02ld:%02ld, 周期=0x%02lX, 振动=%ld, 稍后=%ld",
            (long)alarm.alarmIndex,
            alarm.mswitch ? @"开启" : @"关闭",
            (long)alarm.alarmHour,
            (long)alarm.alarmMinute,
            (unsigned long)alarm.alarmCycle,
            (long)alarm.vibrationMode,
            (long)alarm.remindLater]];

        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(YES, nil);
            });
        }
    } else {
        [[WPLogger sharedInstance] log:@"❌ 闹钟设置指令发送失败"];

        if (completion) {
            NSError *error = [self createError:WPAlarmErrorCodeSendFailed message:@"指令发送失败"];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
        }
    }
}

+ (void)deleteAlarm:(NSInteger)alarmId completion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion {
    // 1. 创建一个 disabled 的闹钟对象（完整初始化所有字段）
    WPAlarmData *alarm = [[WPAlarmData alloc] init];
    alarm.alarmIndex = alarmId;
    alarm.mswitch = 0;           // 关闭
    alarm.alarmHour = 0;
    alarm.alarmMinute = 0;
    alarm.alarmCycle = 0;
    alarm.vibrationMode = 0;     // ✅ 新增：振动模式
    alarm.remindLater = 0;       // ✅ 新增：稍后提醒

    // 2. 调用设置方法（设置为关闭状态即为删除）
    [self setAlarm:alarm completion:completion];
}

+ (void)queryAllAlarms:(nullable void(^)(BOOL success, NSError * _Nullable error))completion {
    // 1. 先查询闹钟总数
    [self queryAlarmCount:^(BOOL success, NSError * _Nullable error) {
        if (!success) {
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(NO, error);
                });
            }
            return;
        }

        // 2. 等待一小段时间确保设备响应已处理
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            WPBluetoothWatchDevice *device = [WPBluetoothManager sharedInstance].currentDevice;
            NSInteger alarmCount = device.alarmCount;

            if (alarmCount <= 0) {
                [[WPLogger sharedInstance] log:@"ℹ️ 设备没有闹钟"];
                if (completion) {
                    completion(YES, nil);
                }
                return;
            }

            // 3. 逐个查询每个闹钟
            [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"🔍 开始查询 %ld 个闹钟", (long)alarmCount]];

            __block NSInteger queriedCount = 0;
            __block BOOL hasError = NO;

            for (NSInteger i = 0; i < alarmCount; i++) {
                // 每个查询间隔 100ms，避免指令冲突
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(i * 0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self queryAlarmInfo:i completion:^(BOOL querySuccess, NSError * _Nullable queryError) {
                        queriedCount++;

                        if (!querySuccess) {
                            hasError = YES;
                        }

                        // 所有查询完成
                        if (queriedCount == alarmCount) {
                            if (completion) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    completion(!hasError, hasError ? queryError : nil);
                                });
                            }
                        }
                    }];
                });
            }
        });
    }];
}

@end
