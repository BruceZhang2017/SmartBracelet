//
//  WPCommands+RaiseToWake.m
//  WatchProtocolSDK-ObjC
//
//  Created by Claude on 2026/01/28.
//  Copyright © 2026 Huaxin. All rights reserved.
//

#import "WPCommands+RaiseToWake.h"
#import "WPBluetoothManager.h"
#import "WPLogger.h"
#import "../Models/WPDeviceModel.h"

// MARK: - 错误域定义
static NSString * const WPRaiseToWakeErrorDomain = @"com.huaxin.watchprotocolsdk.raisetowake";

// MARK: - 错误码定义
typedef NS_ENUM(NSInteger, WPRaiseToWakeErrorCode) {
    WPRaiseToWakeErrorCodeDeviceNotConnected = 2001,  // 设备未连接
    WPRaiseToWakeErrorCodeSendFailed = 2002,          // 指令发送失败
    WPRaiseToWakeErrorCodeBluetoothOff = 2003         // 蓝牙未开启
};

@implementation WPCommands (RaiseToWake)

// MARK: - 🔧 辅助方法

/**
 * 计算 p0 开关状态字节（参考 Swift: DeviceSettingsViewController.swift:519-530）
 * @param device 设备模型
 * @return p0 字节值
 */
+ (uint8_t)calculateP0FromDevice:(WPBluetoothWatchDevice *)device {
    if (!device) return 0;

    uint8_t p0 = 0;
    p0 |= device.isAntiLostSwitch ? (1 << 0) : 0;                      // bit 0: 防丢开关
    p0 |= device.isRaiseHandToBrightenScreen ? (1 << 1) : 0;          // bit 1: 抬手亮屏 ⭐️
    p0 |= device.isAntiLostSwitch ? (1 << 2) : 0;                      // bit 2: 防丢开关（重复）
    p0 |= device.isSleepMonitoringSwitch ? (1 << 4) : 0;              // bit 4: 睡眠监测
    p0 |= device.isMessageReminderMainSwitch ? (1 << 5) : 0;          // bit 5: 消息提醒总开关
    p0 |= device.isRegularExerciseDataUploadSwitch ? (1 << 6) : 0;   // bit 6: 定期运动数据上传
    p0 |= device.isGoalAchievementSwitch ? (1 << 7) : 0;              // bit 7: 目标达成开关

    return p0;
}

/**
 * 计算 p1 开关状态字节（参考 Swift: DeviceSettingsViewController.swift:532-541）
 * @param device 设备模型
 * @return p1 字节值
 */
+ (uint8_t)calculateP1FromDevice:(WPBluetoothWatchDevice *)device {
    if (!device) return 0;

    uint8_t p1 = 0;
    p1 |= device.isMessageScreenDisplaySwitch ? (1 << 1) : 0;         // bit 1: 消息屏幕显示
    p1 |= device.isSoundSwitch ? (1 << 2) : 0;                         // bit 2: 声音开关
    p1 |= device.isVibrationSwitch ? (1 << 3) : 0;                     // bit 3: 震动开关
    p1 |= device.isRegularHealthDataUploadSwitch ? (1 << 4) : 0;      // bit 4: 定期健康数据上传
    p1 |= device.isMessageVibrationSwitch ? (1 << 5) : 0;             // bit 5: 消息震动开关

    return p1;
}

// MARK: - 🔥 核心方法实现

+ (void)setRaiseToWake:(BOOL)enable completion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion {
    // 1. 检查蓝牙是否开启
    WPBluetoothManager *btManager = [WPBluetoothManager sharedInstance];

    if (btManager.isBluetoothPoweredOff) {
        [[WPLogger sharedInstance] log:@"❌ 设置抬手亮屏失败: 蓝牙未开启"];

        if (completion) {
            NSError *error = [NSError errorWithDomain:WPRaiseToWakeErrorDomain
                                               code:WPRaiseToWakeErrorCodeBluetoothOff
                                           userInfo:@{NSLocalizedDescriptionKey: @"蓝牙未开启，请先打开蓝牙"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
        }
        return;
    }

    // 2. 检查设备连接状态
    if (!btManager.isConnected) {
        [[WPLogger sharedInstance] log:@"❌ 设置抬手亮屏失败: 设备未连接"];

        if (completion) {
            NSError *error = [NSError errorWithDomain:WPRaiseToWakeErrorDomain
                                               code:WPRaiseToWakeErrorCodeDeviceNotConnected
                                           userInfo:@{NSLocalizedDescriptionKey: @"设备未连接，请先连接设备"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
        }
        return;
    }

    // 3. 获取当前设备模型
    WPBluetoothWatchDevice *device = btManager.currentDevice;
    if (!device) {
        [[WPLogger sharedInstance] log:@"❌ 设置抬手亮屏失败: 设备模型不存在"];

        if (completion) {
            NSError *error = [NSError errorWithDomain:WPRaiseToWakeErrorDomain
                                               code:WPRaiseToWakeErrorCodeDeviceNotConnected
                                           userInfo:@{NSLocalizedDescriptionKey: @"设备模型不存在，请重新连接设备"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
        }
        return;
    }

    // 4. 更新设备模型中的抬手亮屏状态
    // 参考 Swift: DeviceSettingsViewController.swift:442
    device.isRaiseHandToBrightenScreen = enable;

    // 5. 计算完整的开关状态字节（组合所有开关位）
    // 参考 Swift: DeviceSettingsViewController.swift:443
    uint8_t p0 = [self calculateP0FromDevice:device];
    uint8_t p1 = [self calculateP1FromDevice:device];

    // 6. 构建开关状态指令数据包
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeSwitchStatus),  // 0x80
        @(0x01),
        @(0x00),
        @(0x05),
        @(0x01),  // 0x01 = 设置操作
        @(p0),
        @(p1),
        @(0x00),
        @(0x00)
    ]];

    // 7. 发送指令
    BOOL success = [btManager sendData:command];

    if (success) {
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:
            @"✋ 抬手亮屏设置指令已发送: %@ (p0=0x%02X, p1=0x%02X)",
            enable ? @"开启" : @"关闭", p0, p1]];

        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(YES, nil);
            });
        }
    } else {
        [[WPLogger sharedInstance] log:@"❌ 抬手亮屏设置指令发送失败"];

        if (completion) {
            NSError *error = [NSError errorWithDomain:WPRaiseToWakeErrorDomain
                                               code:WPRaiseToWakeErrorCodeSendFailed
                                           userInfo:@{NSLocalizedDescriptionKey: @"指令发送失败，请重试"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
        }
    }
}

+ (void)getRaiseToWakeStatus:(nullable void(^)(BOOL success, NSError * _Nullable error))completion {
    // 1. 检查蓝牙是否开启
    WPBluetoothManager *btManager = [WPBluetoothManager sharedInstance];

    if (btManager.isBluetoothPoweredOff) {
        [[WPLogger sharedInstance] log:@"❌ 查询抬手亮屏状态失败: 蓝牙未开启"];

        if (completion) {
            NSError *error = [NSError errorWithDomain:WPRaiseToWakeErrorDomain
                                               code:WPRaiseToWakeErrorCodeBluetoothOff
                                           userInfo:@{NSLocalizedDescriptionKey: @"蓝牙未开启"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
        }
        return;
    }

    // 2. 检查设备连接状态
    if (!btManager.isConnected) {
        [[WPLogger sharedInstance] log:@"❌ 查询抬手亮屏状态失败: 设备未连接"];

        if (completion) {
            NSError *error = [NSError errorWithDomain:WPRaiseToWakeErrorDomain
                                               code:WPRaiseToWakeErrorCodeDeviceNotConnected
                                           userInfo:@{NSLocalizedDescriptionKey: @"设备未连接"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
        }
        return;
    }

    // 3. 构建查询指令
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeSwitchStatus),  // 0x80
        @(0x01),
        @(0x00),
        @(0x02),
        @(0x00),  // 0x00 = 查询
        @(0x00)
    ]];

    // 4. 发送指令
    BOOL success = [btManager sendData:command];

    if (success) {
        [[WPLogger sharedInstance] log:@"🔍 查询抬手亮屏状态指令已发送"];

        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(YES, nil);
            });
        }
    } else {
        [[WPLogger sharedInstance] log:@"❌ 查询指令发送失败"];

        if (completion) {
            NSError *error = [NSError errorWithDomain:WPRaiseToWakeErrorDomain
                                               code:WPRaiseToWakeErrorCodeSendFailed
                                           userInfo:@{NSLocalizedDescriptionKey: @"指令发送失败"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
        }
    }
}

@end
