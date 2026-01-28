//
//  WPCommands+FindDevice.m
//  WatchProtocolSDK-ObjC
//
//  Created by Claude on 2026/01/27.
//  Copyright © 2026 Huaxin. All rights reserved.
//

#import "WPCommands+FindDevice.h"
#import "WPBluetoothManager.h"
#import "WPLogger.h"

// MARK: - 静态变量

/// 是否正在查找设备
static BOOL _isFindingDevice = NO;

/// 自动停止定时器
static NSTimer * _Nullable _autoStopTimer = nil;

// MARK: - 错误域定义
static NSString * const WPFindDeviceErrorDomain = @"com.huaxin.watchprotocolsdk.finddevice";

// MARK: - 错误码定义
typedef NS_ENUM(NSInteger, WPFindDeviceErrorCode) {
    WPFindDeviceErrorCodeDeviceNotConnected = 1001,  // 设备未连接
    WPFindDeviceErrorCodeSendFailed = 1002,          // 指令发送失败
    WPFindDeviceErrorCodeBluetoothOff = 1003         // 蓝牙未开启
};

// MARK: - Category 实现

@implementation WPCommands (FindDevice)

// MARK: - 属性访问器

+ (BOOL)isFindingDevice {
    return _isFindingDevice;
}

// MARK: - 🔥 核心方法实现

+ (void)findBandWithCompletion:(nullable WPFindDeviceCompletion)completion {
    // 1. 检查蓝牙是否开启
    WPBluetoothManager *btManager = [WPBluetoothManager sharedInstance];

    if (btManager.isBluetoothPoweredOff) {
        [[WPLogger sharedInstance] log:@"❌ 查找手环失败: 蓝牙未开启"];

        if (completion) {
            NSError *error = [NSError errorWithDomain:WPFindDeviceErrorDomain
                                               code:WPFindDeviceErrorCodeBluetoothOff
                                           userInfo:@{NSLocalizedDescriptionKey: @"蓝牙未开启，请先打开蓝牙"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
        }
        return;
    }

    // 2. 检查设备连接状态
    if (!btManager.isConnected) {
        [[WPLogger sharedInstance] log:@"❌ 查找手环失败: 设备未连接"];

        if (completion) {
            NSError *error = [NSError errorWithDomain:WPFindDeviceErrorDomain
                                               code:WPFindDeviceErrorCodeDeviceNotConnected
                                           userInfo:@{NSLocalizedDescriptionKey: @"设备未连接，请先连接设备"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
        }
        return;
    }

    // 3. 检查是否已在查找中（避免重复请求）
    if (_isFindingDevice) {
        [[WPLogger sharedInstance] log:@"⚠️ 已在查找中，忽略重复请求"];

        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(YES, nil);
            });
        }
        return;
    }

    // 4. 构建查找指令
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeFindBand),
        @(0x01),
        @(0x00),
        @(0x01),
        @(WPFindDeviceActionStart)  // 0 = 开始查找
    ]];

    // 5. 发送指令
    BOOL success = [btManager sendData:command];

    if (success) {
        _isFindingDevice = YES;
        [[WPLogger sharedInstance] log:@"🔍 查找手环指令已发送"];

        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(YES, nil);
            });
        }
    } else {
        [[WPLogger sharedInstance] log:@"❌ 查找手环指令发送失败"];

        if (completion) {
            NSError *error = [NSError errorWithDomain:WPFindDeviceErrorDomain
                                               code:WPFindDeviceErrorCodeSendFailed
                                           userInfo:@{NSLocalizedDescriptionKey: @"指令发送失败，请重试"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
        }
    }
}

+ (void)stopFindBandWithCompletion:(nullable WPFindDeviceCompletion)completion {
    // 1. 取消自动停止定时器（如果存在）
    [self cancelAutoStopTimer];

    // 2. 如果未在查找中，直接返回成功
    if (!_isFindingDevice) {
        [[WPLogger sharedInstance] log:@"ℹ️ 未在查找中，无需停止"];

        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(YES, nil);
            });
        }
        return;
    }

    // 3. 构建停止指令
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeFindBand),
        @(0x01),
        @(0x00),
        @(0x01),
        @(WPFindDeviceActionStop)  // 1 = 停止查找
    ]];

    // 4. 发送指令
    WPBluetoothManager *btManager = [WPBluetoothManager sharedInstance];
    BOOL success = [btManager sendData:command];

    if (success) {
        _isFindingDevice = NO;
        [[WPLogger sharedInstance] log:@"⏹ 停止查找手环指令已发送"];

        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(YES, nil);
            });
        }
    } else {
        [[WPLogger sharedInstance] log:@"❌ 停止查找指令发送失败"];

        if (completion) {
            NSError *error = [NSError errorWithDomain:WPFindDeviceErrorDomain
                                               code:WPFindDeviceErrorCodeSendFailed
                                           userInfo:@{NSLocalizedDescriptionKey: @"停止指令发送失败"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
        }
    }
}

+ (void)findBandWithDuration:(NSTimeInterval)duration
                  completion:(nullable WPFindDeviceCompletion)completion {
    // 1. 先发送查找指令
    [self findBandWithCompletion:^(BOOL success, NSError * _Nullable error) {
        if (!success) {
            // 查找失败，直接回调
            if (completion) {
                completion(success, error);
            }
            return;
        }

        // 2. 如果 duration <= 0，使用设备默认时长（不设置定时器）
        if (duration <= 0) {
            [[WPLogger sharedInstance] log:@"ℹ️ 使用设备默认查找时长"];
            if (completion) {
                completion(YES, nil);
            }
            return;
        }

        // 3. 设置自动停止定时器
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"⏱ 设置自动停止定时器: %.1f秒", duration]];

        [self cancelAutoStopTimer];  // 先取消之前的定时器

        _autoStopTimer = [NSTimer scheduledTimerWithTimeInterval:duration
                                                         repeats:NO
                                                           block:^(NSTimer * _Nonnull timer) {
            [[WPLogger sharedInstance] log:@"⏰ 自动停止定时器触发"];

            [self stopFindBandWithCompletion:^(BOOL stopSuccess, NSError * _Nullable stopError) {
                if (completion) {
                    // 返回停止操作的结果
                    completion(stopSuccess, stopError);
                }
            }];
        }];
    }];
}

// MARK: - 状态管理方法

+ (void)cancelAllFindTasks {
    [[WPLogger sharedInstance] log:@"🧹 取消所有查找任务"];

    // 取消定时器
    [self cancelAutoStopTimer];

    // 重置状态
    _isFindingDevice = NO;
}

// MARK: - 兼容性方法

+ (void)findPhoneWithCompletion:(nullable WPFindDeviceCompletion)completion {
    // 检查设备连接状态
    WPBluetoothManager *btManager = [WPBluetoothManager sharedInstance];

    if (!btManager.isConnected) {
        [[WPLogger sharedInstance] log:@"❌ 查找手机失败: 设备未连接"];

        if (completion) {
            NSError *error = [NSError errorWithDomain:WPFindDeviceErrorDomain
                                               code:WPFindDeviceErrorCodeDeviceNotConnected
                                           userInfo:@{NSLocalizedDescriptionKey: @"设备未连接"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
        }
        return;
    }

    // 构建查找手机指令
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeFindPhone),
        @(0x01),
        @(0x00),
        @(0x01),
        @(0x01)
    ]];

    // 发送指令
    BOOL success = [btManager sendData:command];

    if (success) {
        [[WPLogger sharedInstance] log:@"📱 查找手机指令已发送"];

        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(YES, nil);
            });
        }
    } else {
        [[WPLogger sharedInstance] log:@"❌ 查找手机指令发送失败"];

        if (completion) {
            NSError *error = [NSError errorWithDomain:WPFindDeviceErrorDomain
                                               code:WPFindDeviceErrorCodeSendFailed
                                           userInfo:@{NSLocalizedDescriptionKey: @"指令发送失败"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
        }
    }
}

// MARK: - 私有辅助方法

/**
 * 取消自动停止定时器
 */
+ (void)cancelAutoStopTimer {
    if (_autoStopTimer) {
        [_autoStopTimer invalidate];
        _autoStopTimer = nil;
        [[WPLogger sharedInstance] log:@"⏹ 取消自动停止定时器"];
    }
}

@end
