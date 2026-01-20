//
//  WPCommands.m
//  WatchProtocolSDK-ObjC
//
//  Created by Claude on 2026/01/20.
//  Copyright © 2026 Huaxin. All rights reserved.
//

#import "WPCommands.h"
#import "WPBluetoothManager.h"
#import "WPDeviceModel.h"
#import "WPLogger.h"

// MARK: - 响应数据结构实现

@implementation WPBatteryLevelResponse
@end

@implementation WPDeviceInfoResponse
@end

@implementation WPHeartRateResponse
@end

// MARK: - WPCommands 实现

@implementation WPCommands

static id _healthDataStorage = nil;

+ (void)setHealthDataStorage:(id)healthDataStorage {
    _healthDataStorage = healthDataStorage;
}

+ (id)healthDataStorage {
    return _healthDataStorage;
}

// MARK: - 辅助方法

/**
 * 创建指令数据包
 * @param bytes 字节数组
 * @return NSData 指令数据包
 */
+ (NSData *)createCommandWithBytes:(NSArray<NSNumber *> *)bytes {
    NSMutableData *data = [NSMutableData data];
    for (NSNumber *byte in bytes) {
        uint8_t value = [byte unsignedCharValue];
        [data appendBytes:&value length:1];
    }
    return data;
}

/**
 * 发送指令到设备
 * @param commandData 指令数据包
 */
+ (void)sendCommand:(NSData *)commandData {
    [[WPBluetoothManager sharedInstance] sendData:commandData];
}

// MARK: - 🔥 P0 核心指令实现

+ (void)syncTime:(NSInteger)timeZone utc:(uint32_t)utc {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeSyncTime),
        @(0x01),
        @(0x00),
        @(0x06),
        @(0x01),
        @((uint8_t)timeZone),
        @((uint8_t)(utc & 0xFF)),
        @((uint8_t)((utc >> 8) & 0xFF)),
        @((uint8_t)((utc >> 16) & 0xFF)),
        @((uint8_t)((utc >> 24) & 0xFF))
    ]];

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"⏰ 发送同步时间指令 - 时区:%ld UTC:%u", (long)timeZone, utc]];
    [self sendCommand:command];
}

+ (void)getBatteryLevel {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeGetBatteryLevel),
        @(0x01),
        @(0x00),
        @(0x01),
        @(0x00)
    ]];

    [[WPLogger sharedInstance] log:@"🔋 发送获取电量指令"];
    [self sendCommand:command];
}

+ (void)getDeviceInfo {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeGetDeviceInfo),
        @(0x01),
        @(0x00),
        @(0x01),
        @(0x00)
    ]];

    [[WPLogger sharedInstance] log:@"📱 发送获取设备信息指令"];
    [self sendCommand:command];
}

+ (void)setPersonalInfo:(NSInteger)age height:(NSInteger)height weight:(NSInteger)weight gender:(NSInteger)gender {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypePersonalInfo),
        @(0x01),
        @(0x00),
        @(0x05),
        @(0x01),
        @((uint8_t)age),
        @((uint8_t)height),
        @((uint8_t)weight),
        @((uint8_t)gender)
    ]];

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"👤 发送设置个人信息指令 - 年龄:%ld 身高:%ld 体重:%ld 性别:%ld", (long)age, (long)height, (long)weight, (long)gender]];
    [self sendCommand:command];
}

// MARK: - 🟡 P1 健康数据指令实现

+ (void)startTest:(NSInteger)cmdType control:(NSInteger)control {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeStartTest),
        @(0x01),
        @(0x00),
        @(0x03),
        @(0x01),
        @((uint8_t)cmdType),
        @((uint8_t)control)
    ]];

    NSString *typeName = cmdType == 0 ? @"心率" : (cmdType == 1 ? @"血氧" : @"血压");
    NSString *action = control == 1 ? @"开始" : @"停止";
    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"❤️ 发送%@测试指令 - %@", action, typeName]];
    [self sendCommand:command];
}

+ (void)getNewestHeartData:(NSInteger)type {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeGetNewestHeartData),
        @(0x01),
        @(0x00),
        @(0x01),
        @((uint8_t)type)
    ]];

    NSString *typeName = type == 0 ? @"心率" : (type == 1 ? @"血氧" : @"血压");
    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"❤️ 发送获取最新%@数据指令", typeName]];
    [self sendCommand:command];
}

+ (void)getNewestHealthData:(NSInteger)type {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeGetNewestHealthData),
        @(0x01),
        @(0x00),
        @(0x01),
        @((uint8_t)type)
    ]];

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"📊 发送获取最新健康数据指令 - 类型:%ld", (long)type]];
    [self sendCommand:command];
}

+ (void)getStepData:(uint32_t)startTime endTime:(uint32_t)endTime {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeGetStepData),
        @(0x01),
        @(0x00),
        @(0x09),
        @(0x00),
        @((uint8_t)(startTime & 0xFF)),
        @((uint8_t)((startTime >> 8) & 0xFF)),
        @((uint8_t)((startTime >> 16) & 0xFF)),
        @((uint8_t)((startTime >> 24) & 0xFF)),
        @((uint8_t)(endTime & 0xFF)),
        @((uint8_t)((endTime >> 8) & 0xFF)),
        @((uint8_t)((endTime >> 16) & 0xFF)),
        @((uint8_t)((endTime >> 24) & 0xFF))
    ]];

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"🚶 发送获取步数数据指令 - 时间范围:%u-%u", startTime, endTime]];
    [self sendCommand:command];
}

+ (void)getHistorySleepData:(uint32_t)startTime endTime:(uint32_t)endTime {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeGetHistorySleepData),
        @(0x01),
        @(0x00),
        @(0x09),
        @(0x00),
        @((uint8_t)(startTime & 0xFF)),
        @((uint8_t)((startTime >> 8) & 0xFF)),
        @((uint8_t)((startTime >> 16) & 0xFF)),
        @((uint8_t)((startTime >> 24) & 0xFF)),
        @((uint8_t)(endTime & 0xFF)),
        @((uint8_t)((endTime >> 8) & 0xFF)),
        @((uint8_t)((endTime >> 16) & 0xFF)),
        @((uint8_t)((endTime >> 24) & 0xFF))
    ]];

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"😴 发送获取睡眠数据指令 - 时间范围:%u-%u", startTime, endTime]];
    [self sendCommand:command];
}

// MARK: - 🟢 P2 设备控制指令实现

+ (void)getScreenBrightness {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeSetScreenBrightness),
        @(0x01),
        @(0x00),
        @(0x01),
        @(0x00)
    ]];

    [[WPLogger sharedInstance] log:@"💡 发送获取屏幕亮度指令"];
    [self sendCommand:command];
}

+ (void)setScreenBrightness:(NSInteger)brightnessValue {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeSetScreenBrightness),
        @(0x01),
        @(0x00),
        @(0x02),
        @(0x01),
        @((uint8_t)brightnessValue)
    ]];

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"💡 发送设置屏幕亮度指令 - 亮度:%ld", (long)brightnessValue]];
    [self sendCommand:command];
}

+ (void)findBand {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeFindBand),
        @(0x01),
        @(0x00),
        @(0x01),
        @(0x01)
    ]];

    [[WPLogger sharedInstance] log:@"🔍 发送查找手环指令"];
    [self sendCommand:command];
}

+ (void)findPhone {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeFindPhone),
        @(0x01),
        @(0x00),
        @(0x01),
        @(0x01)
    ]];

    [[WPLogger sharedInstance] log:@"📱 发送查找手机指令"];
    [self sendCommand:command];
}

+ (void)disconnectBT {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeDisconnectBT),
        @(0x01),
        @(0x00),
        @(0x01),
        @(0x00)
    ]];

    [[WPLogger sharedInstance] log:@"🔌 发送断开蓝牙指令"];
    [self sendCommand:command];
}

// MARK: - 🔥 核心响应解析实现

+ (void)handleResponse:(NSData *)response {
    if (response.length < 2) {
        [[WPLogger sharedInstance] log:@"⚠️ 响应数据长度不足"];
        return;
    }

    const uint8_t *bytes = (const uint8_t *)response.bytes;
    uint8_t commandCode = bytes[1];

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"📥 收到响应 - 指令代码:0x%02X 长度:%lu", commandCode, (unsigned long)response.length]];

    WPCommandType commandType = (WPCommandType)commandCode;

    switch (commandType) {
        case WPCommandTypeSyncTime:
            [self handleSyncTimeResponse:response];
            break;

        case WPCommandTypeGetBatteryLevel:
            [self handleBatteryLevelResponse:response];
            break;

        case WPCommandTypeGetDeviceInfo:
            [self handleDeviceInfoResponse:response];
            break;

        case WPCommandTypeStartTest:
            [self handleStartTestResponse:response];
            break;

        case WPCommandTypeGetNewestHeartData:
            [self handleNewestHeartDataResponse:response];
            break;

        case WPCommandTypeGetStepData:
            [self handleStepDataResponse:response];
            break;

        case WPCommandTypeGetHistorySleepData:
            [self handleSleepDataResponse:response];
            break;

        case WPCommandTypeSetScreenBrightness:
            [self handleScreenBrightnessResponse:response];
            break;

        default:
            [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"⚠️ 未处理的指令响应:0x%02X", commandCode]];
            break;
    }
}

// MARK: - 具体响应解析方法

+ (void)handleSyncTimeResponse:(NSData *)response {
    const uint8_t *bytes = (const uint8_t *)response.bytes;

    if (response.length < 7) {
        [[WPLogger sharedInstance] log:@"❌ 同步时间响应数据长度不足"];
        return;
    }

    BOOL success = bytes[6] == 0x00;
    if (success) {
        [[WPLogger sharedInstance] log:@"✅ 时间同步成功"];
    } else {
        [[WPLogger sharedInstance] log:@"❌ 时间同步失败"];
    }
}

+ (void)handleBatteryLevelResponse:(NSData *)response {
    const uint8_t *bytes = (const uint8_t *)response.bytes;

    if (response.length < 7) {
        [[WPLogger sharedInstance] log:@"❌ 电量响应数据长度不足"];
        return;
    }

    // 解析电量数据（byte 6）
    // 低7位：电量百分比 (0-100)
    // 最高位：充电状态 (0:未充电 1:充电中)
    NSInteger rawBatteryLevel = bytes[6] & 0x7F;
    BOOL isCharging = (bytes[6] & 0x80) != 0;

    // 🆕 v2.0.2: 范围检查和容错处理（修复 BATTERY-127 BUG）
    NSInteger batteryLevel = rawBatteryLevel;
    if (rawBatteryLevel > 100) {
        // 超出范围，限制在 0-100
        batteryLevel = 100;
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:
            @"⚠️ 电量值异常:%ld (超出范围)，已修正为:100", (long)rawBatteryLevel]];
    } else if (rawBatteryLevel < 0) {
        // 理论上不会发生，但保留检查
        batteryLevel = 0;
        [[WPLogger sharedInstance] log:@"⚠️ 电量值异常（负数），已修正为:0"];
    }

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"🔋 电量:%ld%% 充电状态:%@", (long)batteryLevel, isCharging ? @"充电中" : @"未充电"]];

    // 🆕 v2.0.1: 自动更新 currentDevice 的电量信息
    WPBluetoothManager *manager = [WPBluetoothManager sharedInstance];
    if (manager.currentDevice) {
        manager.currentDevice.batteryLevel = batteryLevel;
        manager.currentDevice.isCharging = isCharging;
    }

    // 🆕 v2.0.1: 通过代理回调通知应用层
    if ([manager.delegate respondsToSelector:@selector(didReceiveBatteryLevel:isCharging:)]) {
        [manager.delegate didReceiveBatteryLevel:batteryLevel isCharging:isCharging];
    }
}

+ (void)handleDeviceInfoResponse:(NSData *)response {
    const uint8_t *bytes = (const uint8_t *)response.bytes;

    if (response.length < 20) {
        [[WPLogger sharedInstance] log:@"❌ 设备信息响应数据长度不足"];
        return;
    }

    // 解析设备信息
    NSInteger watchType = bytes[6];
    NSInteger supportLanguage = bytes[7];

    // 序列号（8字节，从byte 8开始）
    NSMutableString *serialNumber = [NSMutableString string];
    for (int i = 8; i < 16; i++) {
        [serialNumber appendFormat:@"%02X", bytes[i]];
    }

    NSInteger firmwareMajorVersion = bytes[16];
    NSInteger firmwareMinorVersion = bytes[17];

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"📱 设备信息 - 类型:%ld 序列号:%@ 固件:v%ld.%ld",
                                   (long)watchType, serialNumber, (long)firmwareMajorVersion, (long)firmwareMinorVersion]];

    // 创建响应对象
    WPDeviceInfoResponse *deviceInfo = [[WPDeviceInfoResponse alloc] init];
    deviceInfo.watchType = watchType;
    deviceInfo.supportLanguage = supportLanguage;
    deviceInfo.serialNumber = serialNumber;
    deviceInfo.firmwareMajorVersion = firmwareMajorVersion;
    deviceInfo.firmwareMinorVersion = firmwareMinorVersion;
}

+ (void)handleStartTestResponse:(NSData *)response {
    const uint8_t *bytes = (const uint8_t *)response.bytes;

    // 简短响应：命令执行结果
    if (response.length == 7) {
        BOOL success = bytes[6] == 0x00;
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"%@ 测试命令执行%@",
                                       success ? @"✅" : @"❌", success ? @"成功" : @"失败"]];
        return;
    }

    // 完整响应：测试数据
    if (response.length >= 11) {
        // 时间戳（bytes 6-9，小端序）
        uint32_t timestamp = bytes[6] | (bytes[7] << 8) | (bytes[8] << 16) | (bytes[9] << 24);
        NSInteger cmdType = bytes[5];

        if (cmdType == 0) {
            // 心率数据
            NSInteger heartRate = bytes[10];
            if (heartRate == 0) return;

            [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"❤️ 心率测量结果:%ld bpm (时间戳:%u)", (long)heartRate, timestamp]];

            // 🆕 v2.0.1: 自动更新 currentDevice
            WPBluetoothManager *manager = [WPBluetoothManager sharedInstance];
            if (manager.currentDevice) {
                manager.currentDevice.currentHeartrate = heartRate;
            }

            // 🆕 v2.0.1: 通过代理回调
            if ([manager.delegate respondsToSelector:@selector(didReceiveHeartRate:)]) {
                [manager.delegate didReceiveHeartRate:heartRate];
            }

        } else if (cmdType == 1) {
            // 血氧数据
            NSInteger oxygen = bytes[10];
            if (oxygen == 0) return;

            [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"🫁 血氧测量结果:%ld%% (时间戳:%u)", (long)oxygen, timestamp]];

            // 更新 currentDevice
            WPBluetoothManager *manager = [WPBluetoothManager sharedInstance];
            if (manager.currentDevice) {
                manager.currentDevice.currentOxygen = oxygen;
            }

        } else if (cmdType == 2 && response.length >= 12) {
            // 血压数据
            NSInteger systolic = bytes[10];  // 收缩压
            NSInteger diastolic = bytes[11]; // 舒张压
            if (systolic == 0) return;

            [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"🩺 血压测量结果:%ld/%ld mmHg (时间戳:%u)",
                                           (long)systolic, (long)diastolic, timestamp]];

            // 更新 currentDevice
            WPBluetoothManager *manager = [WPBluetoothManager sharedInstance];
            if (manager.currentDevice) {
                manager.currentDevice.currentSystolicPressure = systolic;
                manager.currentDevice.currentDiastolicPressure = diastolic;
            }
        }
    }
}

+ (void)handleNewestHeartDataResponse:(NSData *)response {
    const uint8_t *bytes = (const uint8_t *)response.bytes;

    if (response.length < 11) {
        [[WPLogger sharedInstance] log:@"❌ 最新心率数据响应长度不足"];
        return;
    }

    // 时间戳（bytes 6-9，小端序）
    uint32_t timestamp = bytes[6] | (bytes[7] << 8) | (bytes[8] << 16) | (bytes[9] << 24);
    NSInteger cmdType = bytes[5];

    if (cmdType == 0) {
        // 心率数据
        NSInteger heartRate = bytes[10];

        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"❤️ 最新心率:%ld bpm (时间戳:%u)", (long)heartRate, timestamp]];

        // 🆕 v2.0.1: 自动更新 currentDevice
        WPBluetoothManager *manager = [WPBluetoothManager sharedInstance];
        if (manager.currentDevice) {
            manager.currentDevice.currentHeartrate = heartRate;
        }

        // 🆕 v2.0.1: 通过代理回调
        if ([manager.delegate respondsToSelector:@selector(didReceiveHeartRate:)]) {
            [manager.delegate didReceiveHeartRate:heartRate];
        }

    } else if (cmdType == 1) {
        // 血氧数据
        NSInteger oxygen = bytes[10];
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"🫁 最新血氧:%ld%% (时间戳:%u)", (long)oxygen, timestamp]];

        WPBluetoothManager *manager = [WPBluetoothManager sharedInstance];
        if (manager.currentDevice) {
            manager.currentDevice.currentOxygen = oxygen;
        }

    } else if (cmdType == 2 && response.length >= 12) {
        // 血压数据
        NSInteger systolic = bytes[10];
        NSInteger diastolic = bytes[11];
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"🩺 最新血压:%ld/%ld mmHg (时间戳:%u)",
                                       (long)systolic, (long)diastolic, timestamp]];

        WPBluetoothManager *manager = [WPBluetoothManager sharedInstance];
        if (manager.currentDevice) {
            manager.currentDevice.currentSystolicPressure = systolic;
            manager.currentDevice.currentDiastolicPressure = diastolic;
        }
    }
}

+ (void)handleStepDataResponse:(NSData *)response {
    const uint8_t *bytes = (const uint8_t *)response.bytes;

    if (response.length < 10) {
        [[WPLogger sharedInstance] log:@"❌ 步数数据响应长度不足"];
        return;
    }

    // 步数（bytes 6-9，小端序）
    uint32_t steps = bytes[6] | (bytes[7] << 8) | (bytes[8] << 16) | (bytes[9] << 24);

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"🚶 步数数据:%u 步", steps]];

    // TODO: 根据具体协议解析更多步数详情（距离、卡路里等）
}

+ (void)handleSleepDataResponse:(NSData *)response {
    const uint8_t *bytes = (const uint8_t *)response.bytes;

    if (response.length < 10) {
        [[WPLogger sharedInstance] log:@"❌ 睡眠数据响应长度不足"];
        return;
    }

    [[WPLogger sharedInstance] log:@"😴 收到睡眠数据"];

    // TODO: 根据具体协议解析睡眠数据（深睡、浅睡、清醒等）
}

+ (void)handleScreenBrightnessResponse:(NSData *)response {
    const uint8_t *bytes = (const uint8_t *)response.bytes;

    if (response.length < 7) {
        [[WPLogger sharedInstance] log:@"❌ 屏幕亮度响应长度不足"];
        return;
    }

    if (bytes[5] == 0x00) {
        // 查询响应
        NSInteger brightness = bytes[6];
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"💡 当前屏幕亮度:%ld", (long)brightness]];

        WPBluetoothManager *manager = [WPBluetoothManager sharedInstance];
        if (manager.currentDevice) {
            manager.currentDevice.screenBrightness = brightness;
        }
    } else {
        // 设置响应
        BOOL success = bytes[6] == 0x00;
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"%@ 设置屏幕亮度%@",
                                       success ? @"✅" : @"❌", success ? @"成功" : @"失败"]];
    }
}

@end
