//
//  WPCommands.m
//  WatchProtocolSDK-ObjC
//
//  Created by Claude on 2026/01/20.
//  Copyright © 2026 Huaxin. All rights reserved.
//

#import "WPCommands.h"
#import "WPBluetoothManager.h"
#import "../Models/WPDeviceModel.h"
#import "WPLogger.h"

// MARK: - 响应数据结构实现

@implementation WPBatteryLevelResponse
@end

@implementation WPDeviceInfoResponse
@end

@implementation WPHeartRateResponse
@end

@implementation WPReminderInfoResponse
@end

@implementation WPContactData
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

// MARK: - 基础设备控制指令实现

+ (void)getDeviceLanguage {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeGetDeviceLanguage),
        @(0x01),
        @(0x00),
        @(0x02),
        @(0x00)
    ]];

    [[WPLogger sharedInstance] log:@"🌐 发送查询设备语言指令"];
    [self sendCommand:command];
}

+ (void)setDeviceLanguage:(NSInteger)language {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeGetDeviceLanguage),
        @(0x01),
        @(0x00),
        @(0x02),
        @(0x01),
        @((uint8_t)language)
    ]];

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"🌐 发送设置设备语言指令 - 语言:%ld", (long)language]];
    [self sendCommand:command];
}

+ (void)getDeviceUnitFormat {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeSetDeviceUnitFormat),
        @(0x01),
        @(0x00),
        @(0x01),
        @(0x00)
    ]];

    [[WPLogger sharedInstance] log:@"📏 发送获取设备单位格式指令"];
    [self sendCommand:command];
}

+ (void)setDeviceUnitFormat:(NSInteger)unitType {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeSetDeviceUnitFormat),
        @(0x01),
        @(0x00),
        @(0x02),
        @(0x01),
        @((uint8_t)unitType)
    ]];

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"📏 发送设置设备单位格式指令 - 单位:%ld", (long)unitType]];
    [self sendCommand:command];
}

+ (void)resetToFactorySettings {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeResetToFactorySettings),
        @(0x01),
        @(0x00),
        @(0x01),
        @(0x00)
    ]];

    [[WPLogger sharedInstance] log:@"🔄 发送恢复出厂设置指令"];
    [self sendCommand:command];
}

+ (void)setDeviceScreenTimeout:(NSInteger)screenTimeout {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeSetDeviceScreenTimeout),
        @(0x01),
        @(0x00),
        @(0x05),
        @(0x01),
        @((uint8_t)((screenTimeout >> 24) & 0xFF)),
        @((uint8_t)((screenTimeout >> 16) & 0xFF)),
        @((uint8_t)((screenTimeout >> 8) & 0xFF)),
        @((uint8_t)(screenTimeout & 0xFF))
    ]];

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"⏱ 发送设置屏幕超时指令 - 超时:%ld", (long)screenTimeout]];
    [self sendCommand:command];
}

+ (void)getDoNotDisturb {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeSetDoNotDisturb),
        @(0x01),
        @(0x00),
        @(0x01),
        @(0x00)
    ]];

    [[WPLogger sharedInstance] log:@"🌙 发送获取勿扰模式指令"];
    [self sendCommand:command];
}

+ (void)setDoNotDisturb:(BOOL)bSwitch
              startHour:(NSInteger)startHour
            startMinute:(NSInteger)startMinute
                endHour:(NSInteger)endHour
              endMinute:(NSInteger)endMinute {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeSetDoNotDisturb),
        @(0x01),
        @(0x00),
        @(0x06),
        @(0x01),
        @(bSwitch ? 0x01 : 0x00),
        @((uint8_t)startHour),
        @((uint8_t)startMinute),
        @((uint8_t)endHour),
        @((uint8_t)endMinute)
    ]];

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"🌙 发送设置勿扰模式指令 - 开关:%@ 时间:%ld:%02ld-%ld:%02ld",
                                   bSwitch ? @"开" : @"关", (long)startHour, (long)startMinute, (long)endHour, (long)endMinute]];
    [self sendCommand:command];
}

+ (void)setWeatherUnit:(NSInteger)unit {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeSetWeatherUnit),
        @(0x01),
        @(0x00),
        @(0x02),
        @(0x01),
        @((uint8_t)unit)
    ]];

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"🌤 发送设置天气单位指令 - 单位:%ld", (long)unit]];
    [self sendCommand:command];
}

+ (void)get12H24HTimeFormat {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeSet12H24HTimeFormat),
        @(0x01),
        @(0x00),
        @(0x01),
        @(0x00)
    ]];

    [[WPLogger sharedInstance] log:@"🕐 发送获取时间格式指令"];
    [self sendCommand:command];
}

+ (void)set12H24HTimeFormat:(NSInteger)format {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeSet12H24HTimeFormat),
        @(0x01),
        @(0x00),
        @(0x02),
        @(0x01),
        @((uint8_t)format)
    ]];

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"🕐 发送设置时间格式指令 - 格式:%@", format == 0 ? @"12小时制" : @"24小时制"]];
    [self sendCommand:command];
}

+ (void)setAppInfo:(NSInteger)phoneType {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeSetAppInfo),
        @(0x01),
        @(0x00),
        @(0x03),
        @(0x01),
        @(0x00),
        @((uint8_t)phoneType)
    ]];

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"📱 发送设置APP信息指令 - 手机类型:%@", phoneType == 0 ? @"Android" : @"iOS"]];
    [self sendCommand:command];
}

// MARK: - 个人信息指令实现

+ (void)getPersonalInfo {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypePersonalInfo),
        @(0x01),
        @(0x00),
        @(0x01),
        @(0x00)
    ]];

    [[WPLogger sharedInstance] log:@"👤 发送获取个人信息指令"];
    [self sendCommand:command];
}

// MARK: - 开关与设置指令实现

+ (void)getSwitchStatus {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeSwitchStatus),
        @(0x01),
        @(0x00),
        @(0x01),
        @(0x00)
    ]];

    [[WPLogger sharedInstance] log:@"🔀 发送获取开关状态指令"];
    [self sendCommand:command];
}

+ (void)setSwitchStatus:(uint8_t)p0 p1:(uint8_t)p1 {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeSwitchStatus),
        @(0x01),
        @(0x00),
        @(0x05),
        @(0x01),
        @(p0),
        @(p1),
        @(0x00),
        @(0x00)
    ]];

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"🔀 发送设置开关状态指令 - P0:0x%02X P1:0x%02X", p0, p1]];
    [self sendCommand:command];
}

+ (void)bindDevice:(uint8_t)value {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeBindDevice),
        @(0x01),
        @(0x00),
        @(0x02),
        @(0x01),
        @(value)
    ]];

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"🔗 发送绑定设备指令 - 值:%@", value == 1 ? @"绑定" : @"解绑"]];
    [self sendCommand:command];
}

+ (void)getAlarmInfo:(NSInteger)type {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeAlarmInfo),
        @(0x01),
        @(0x00),
        @(0x02),
        @(0x00),
        @((uint8_t)type)
    ]];

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"⏰ 发送获取闹钟信息指令 - 类型:%ld", (long)type]];
    [self sendCommand:command];
}

+ (void)setAlarmInfo:(NSInteger)setCmd alarm:(WPAlarmData *)alarm {
    // 映射 WPDeviceModel.h 中的 WPAlarmData 属性到协议字段
    // alarmId -> alarmIndex
    // enabled -> switchOn (0或1)
    // hour -> alarmHour
    // minute -> alarmMinute
    // repeatDays -> alarmCycle

    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeAlarmInfo),
        @(0x01),
        @(0x00),
        @(0x09),
        @(0x01),
        @((uint8_t)setCmd),
        @((uint8_t)alarm.alarmId),        // alarmIndex
        @(alarm.enabled ? 0x01 : 0x00),    // switchOn
        @((uint8_t)alarm.repeatDays),      // alarmCycle
        @((uint8_t)alarm.hour),            // alarmHour
        @((uint8_t)alarm.minute),          // alarmMinute
        @(0x01),                            // vibrationMode (默认值)
        @(0x00)                             // remindLater (默认值)
    ]];

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"⏰ 发送设置闹钟信息指令 - ID:%ld 时间:%02ld:%02ld 启用:%@",
                                   (long)alarm.alarmId, (long)alarm.hour, (long)alarm.minute, alarm.enabled ? @"是" : @"否"]];
    [self sendCommand:command];
}

+ (void)getReminderInfo:(NSInteger)eventType {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeReminderInfo),
        @(0x01),
        @(0x00),
        @(0x02),
        @(0x00),
        @((uint8_t)eventType)
    ]];

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"📌 发送获取提醒信息指令 - 事件类型:%ld", (long)eventType]];
    [self sendCommand:command];
}

+ (void)setReminderInfo:(WPReminderInfoResponse *)response {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeReminderInfo),
        @(0x01),
        @(0x00),
        @(0x08),
        @(0x01),
        @((uint8_t)response.eventType),
        @((uint8_t)response.cycle),
        @((uint8_t)response.startHour),
        @((uint8_t)response.startMinute),
        @((uint8_t)response.endHour),
        @((uint8_t)response.endMinute),
        @((uint8_t)response.period)
    ]];

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"📌 发送设置提醒信息指令 - 事件类型:%ld", (long)response.eventType]];
    [self sendCommand:command];
}

+ (void)getSwitchTableExtension {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeSwitchTableExtension),
        @(0x01),
        @(0x00),
        @(0x02),
        @(0x00),
        @(0x00)
    ]];

    [[WPLogger sharedInstance] log:@"📊 发送获取开关表扩展指令"];
    [self sendCommand:command];
}

+ (void)setSwitchTableExtension:(uint8_t)p0 p1:(uint8_t)p1 p2:(uint8_t)p2 p3:(uint8_t)p3 {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeSwitchTableExtension),
        @(0x01),
        @(0x00),
        @(0x06),
        @(0x01),
        @(0x00),
        @(p0),
        @(p1),
        @(p2),
        @(p3)
    ]];

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"📊 发送设置开关表扩展指令 - P0:0x%02X P1:0x%02X P2:0x%02X P3:0x%02X",
                                   p0, p1, p2, p3]];
    [self sendCommand:command];
}

// MARK: - 多媒体控制指令实现

+ (void)musicControl:(NSInteger)action dataType:(NSInteger)dataType {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeMusicControl),
        @(0x01),
        @(0x00),
        @(0x02),
        @((uint8_t)action),
        @((uint8_t)dataType)
    ]];

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"🎵 发送音乐控制指令 - 操作:%ld 类型:%ld", (long)action, (long)dataType]];
    [self sendCommand:command];
}

+ (void)remotePhoto:(NSInteger)action {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeRemotePhoto),
        @(0x01),
        @(0x00),
        @(0x02),
        @(0x01),
        @((uint8_t)action)
    ]];

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"📷 发送远程拍照指令 - 操作:%ld", (long)action]];
    [self sendCommand:command];
}

// MARK: - 通知与天气指令实现

+ (void)messagePush:(NSInteger)action
            control:(NSInteger)control
        messageType:(NSInteger)messageType
     messageContent:(NSData *)messageContent {
    NSMutableArray *commandBytes = [NSMutableArray arrayWithArray:@[
        @(0x00),
        @(WPCommandTypeMessagePush),
        @(0x01),
        @(0x00),
        @((uint8_t)(6 + messageContent.length)),
        @((uint8_t)action),
        @((uint8_t)control),
        @((uint8_t)messageType)
    ]];

    const uint8_t *bytes = (const uint8_t *)messageContent.bytes;
    for (NSUInteger i = 0; i < messageContent.length; i++) {
        [commandBytes addObject:@(bytes[i])];
    }

    NSData *command = [self createCommandWithBytes:commandBytes];

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"💬 发送消息推送指令 - 类型:%ld 长度:%lu",
                                   (long)messageType, (unsigned long)messageContent.length]];
    [self sendCommand:command];
}

+ (void)setWeatherInfo:(NSInteger)dateType
           weatherType:(NSInteger)weatherType
              currTemp:(NSInteger)currTemp
                 lTemp:(NSInteger)lTemp
                 hTemp:(NSInteger)hTemp
                   cmd:(NSInteger)cmd {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeSetWeatherInfo),
        @(0x01),
        @(0x00),
        @(14),
        @((uint8_t)cmd),
        @((uint8_t)dateType),
        @(0x00),
        @(0x01),
        @((uint8_t)weatherType),
        @(0x01),
        @(0x01),
        @((uint8_t)currTemp),
        @(0x02),
        @(0x01),
        @((uint8_t)lTemp),
        @(0x03),
        @(0x01),
        @((uint8_t)hTemp)
    ]];

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"🌤 发送设置天气信息指令 - 天气:%ld 温度:%ld/%ld/%ld",
                                   (long)weatherType, (long)currTemp, (long)lTemp, (long)hTemp]];
    [self sendCommand:command];
}

+ (void)getContactInfo {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeContactInfo),
        @(0x01),
        @(0x00),
        @(0x02),
        @(0x01),
        @(0x03)
    ]];

    [[WPLogger sharedInstance] log:@"📞 发送获取联系人信息指令"];
    [self sendCommand:command];
}

+ (void)setContactInfo:(NSInteger)index name:(NSString *)name phoneNumber:(NSString *)phoneNumber {
    NSData *nameData = [name dataUsingEncoding:NSUTF8StringEncoding];
    NSString *cleanedNumber = [phoneNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
    cleanedNumber = [cleanedNumber stringByReplacingOccurrencesOfString:@"-" withString:@""];
    cleanedNumber = [cleanedNumber stringByReplacingOccurrencesOfString:@"(" withString:@""];
    cleanedNumber = [cleanedNumber stringByReplacingOccurrencesOfString:@")" withString:@""];
    cleanedNumber = [cleanedNumber stringByReplacingOccurrencesOfString:@"." withString:@""];

    NSData *phoneData = [self phoneNumberToBytes:cleanedNumber];

    NSMutableArray *commandBytes = [NSMutableArray arrayWithArray:@[
        @(0x00),
        @(WPCommandTypeContactInfo),
        @(0x01),
        @(0x00),
        @((uint8_t)(5 + nameData.length + phoneData.length)),
        @(0x01),
        @(0x00),
        @((uint8_t)index),
        @((uint8_t)nameData.length)
    ]];

    const uint8_t *nameBytes = (const uint8_t *)nameData.bytes;
    for (NSUInteger i = 0; i < nameData.length; i++) {
        [commandBytes addObject:@(nameBytes[i])];
    }

    [commandBytes addObject:@((uint8_t)cleanedNumber.length)];

    const uint8_t *phoneBytes = (const uint8_t *)phoneData.bytes;
    for (NSUInteger i = 0; i < phoneData.length; i++) {
        [commandBytes addObject:@(phoneBytes[i])];
    }

    NSData *command = [self createCommandWithBytes:commandBytes];

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"📞 发送设置联系人信息指令 - 索引:%ld 姓名:%@",
                                   (long)index, name]];
    [self sendCommand:command];
}

+ (void)incomingCallMute:(NSInteger)mute {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeIncomingCallMute),
        @(0x01),
        @(0x00),
        @(0x02),
        @((uint8_t)mute)
    ]];

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"🔇 发送来电静音指令 - 静音:%@", mute ? @"是" : @"否"]];
    [self sendCommand:command];
}

// MARK: - 健康数据指令（扩展）实现

+ (void)getTargetSettings {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeTargetSettings),
        @(0x01),
        @(0x00),
        @(0x01),
        @(0x00)
    ]];

    [[WPLogger sharedInstance] log:@"🎯 发送获取目标设置指令"];
    [self sendCommand:command];
}

+ (void)setTargetSettings:(NSInteger)targetSwitch
               targetType:(NSInteger)targetType
             targetLength:(NSInteger)targetLength {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeTargetSettings),
        @(0x01),
        @(0x00),
        @(0x06),
        @((uint8_t)targetSwitch),
        @((uint8_t)targetType),
        @((uint8_t)targetLength)
    ]];

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"🎯 发送设置目标设置指令 - 开关:%ld 类型:%ld",
                                   (long)targetSwitch, (long)targetType]];
    [self sendCommand:command];
}

+ (void)getMultiSportModeData {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeMultiSportModeData),
        @(0x01),
        @(0x00),
        @(0x01),
        @(0x00)
    ]];

    [[WPLogger sharedInstance] log:@"🏃 发送获取多运动模式数据指令"];
    [self sendCommand:command];
}

+ (void)deleteSportModeData {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeMultiSportModeData),
        @(0x01),
        @(0x00),
        @(0x01),
        @(0x01)
    ]];

    [[WPLogger sharedInstance] log:@"🗑 发送删除运动模式数据指令"];
    [self sendCommand:command];
}

+ (void)getSleepMonitoring {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeGetSleepMonitoring),
        @(0x01),
        @(0x00),
        @(0x01),
        @(0x01)
    ]];

    [[WPLogger sharedInstance] log:@"😴 发送获取睡眠监测指令"];
    [self sendCommand:command];
}

+ (void)setAutoSleepMonitoring:(NSInteger)startHour
                   startMinute:(NSInteger)startMinute
                       endHour:(NSInteger)endHour
                     endMinute:(NSInteger)endMinute
                    alarmCycle:(NSInteger)alarmCycle {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeSetAutoSleepMonitoring),
        @(0x01),
        @(0x00),
        @(0x07),
        @((uint8_t)startHour),
        @((uint8_t)startMinute),
        @((uint8_t)endHour),
        @((uint8_t)endMinute),
        @((uint8_t)alarmCycle)
    ]];

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"😴 发送设置自动睡眠监测指令 - 时间:%ld:%02ld-%ld:%02ld",
                                   (long)startHour, (long)startMinute, (long)endHour, (long)endMinute]];
    [self sendCommand:command];
}

// MARK: - 表盘与资源指令实现

+ (void)dialMarketQuery:(NSInteger)dataType {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeDialMarket),
        @(0x01),
        @(0x00),
        @(0x02),
        @(0x00),
        @((uint8_t)dataType)
    ]];

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"⌚️ 发送表盘市场查询指令 - 类型:%ld", (long)dataType]];
    [self sendCommand:command];
}

+ (void)dialMarketSetTransferConfig:(NSInteger)packageTotal
                            binSize:(NSInteger)binSize
                                mtu:(NSInteger)mtu
                           dialType:(NSInteger)dialType
                            dialNum:(NSInteger)dialNum
                              local:(NSInteger)local
                          typeValue:(NSInteger)typeValue
                      dialTypeValue:(NSInteger)dialTypeValue {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeDialMarket),
        @(0x01),
        @(0x00),
        @(0x10),
        @(0x01),
        @((uint8_t)(packageTotal & 0xFF)),
        @((uint8_t)((packageTotal >> 8) & 0xFF)),
        @((uint8_t)(binSize & 0xFF)),
        @((uint8_t)((binSize >> 8) & 0xFF)),
        @((uint8_t)((binSize >> 16) & 0xFF)),
        @((uint8_t)((binSize >> 24) & 0xFF)),
        @((uint8_t)(mtu & 0xFF)),
        @((uint8_t)((mtu >> 8) & 0xFF)),
        @((uint8_t)dialType),
        @((uint8_t)dialNum),
        @((uint8_t)local),
        @((uint8_t)typeValue),
        @((uint8_t)((dialTypeValue >> 16) & 0xFF)),
        @((uint8_t)((dialTypeValue >> 8) & 0xFF)),
        @((uint8_t)(dialTypeValue & 0xFF))
    ]];

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"⌚️ 发送表盘市场传输配置指令 - 总包数:%ld 大小:%ld",
                                   (long)packageTotal, (long)binSize]];
    [self sendCommand:command];
}

+ (void)dialMarketTransferData:(NSInteger)packageNum
                        binNum:(NSInteger)binNum
                   progressBar:(NSInteger)progressBar
                       control:(NSInteger)control
                          data:(NSData *)data {
    NSMutableArray *commandBytes = [NSMutableArray arrayWithArray:@[
        @(0x00),
        @(WPCommandTypeDialMarket),
        @(0x01),
        @(0x00),
        @((uint8_t)(11 + data.length)),
        @(0x02),
        @((uint8_t)(packageNum & 0xFF)),
        @((uint8_t)((packageNum >> 8) & 0xFF)),
        @((uint8_t)(binNum & 0xFF)),
        @((uint8_t)((binNum >> 8) & 0xFF)),
        @((uint8_t)((binNum >> 16) & 0xFF)),
        @((uint8_t)((binNum >> 24) & 0xFF)),
        @((uint8_t)progressBar),
        @((uint8_t)control)
    ]];

    // 计算校验码
    NSInteger checkCode = 0;
    for (NSNumber *num in commandBytes) {
        checkCode += [num unsignedCharValue];
    }
    const uint8_t *bytes = (const uint8_t *)data.bytes;
    for (NSUInteger i = 0; i < data.length; i++) {
        checkCode += bytes[i];
    }

    [commandBytes addObject:@((uint8_t)(checkCode & 0xFF))];
    [commandBytes addObject:@((uint8_t)((checkCode >> 8) & 0xFF))];

    for (NSUInteger i = 0; i < data.length; i++) {
        [commandBytes addObject:@(bytes[i])];
    }

    NSData *command = [self createCommandWithBytes:commandBytes];

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"⌚️ 发送表盘市场数据 - 包号:%ld 进度:%ld%%",
                                   (long)packageNum, (long)progressBar]];
    [self sendCommand:command];
}

+ (void)resourceUpgradeQuery {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeResourceUpgrade),
        @(0x01),
        @(0x00),
        @(0x02),
        @(0x00)
    ]];

    [[WPLogger sharedInstance] log:@"📦 发送资源升级查询指令"];
    [self sendCommand:command];
}

+ (void)resourceUpgradeSetTransferConfig:(NSInteger)packageTotal
                                 binSize:(NSInteger)binSize
                                     mtu:(NSInteger)mtu {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeResourceUpgrade),
        @(0x01),
        @(0x00),
        @(0x0A),
        @(0x01),
        @((uint8_t)((packageTotal >> 8) & 0xFF)),
        @((uint8_t)(packageTotal & 0xFF)),
        @((uint8_t)((binSize >> 24) & 0xFF)),
        @((uint8_t)((binSize >> 16) & 0xFF)),
        @((uint8_t)((binSize >> 8) & 0xFF)),
        @((uint8_t)(binSize & 0xFF)),
        @((uint8_t)((mtu >> 8) & 0xFF)),
        @((uint8_t)(mtu & 0xFF))
    ]];

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"📦 发送资源升级传输配置指令 - 总包数:%ld 大小:%ld",
                                   (long)packageTotal, (long)binSize]];
    [self sendCommand:command];
}

+ (void)resourceUpgradeTransferData:(NSData *)data {
    NSMutableArray *commandBytes = [NSMutableArray arrayWithArray:@[
        @(0x00),
        @(WPCommandTypeResourceUpgrade),
        @(0x01),
        @(0x00),
        @((uint8_t)(6 + data.length)),
        @(0x02)
    ]];

    const uint8_t *bytes = (const uint8_t *)data.bytes;
    for (NSUInteger i = 0; i < data.length; i++) {
        [commandBytes addObject:@(bytes[i])];
    }

    NSData *command = [self createCommandWithBytes:commandBytes];

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"📦 发送资源升级数据 - 长度:%lu", (unsigned long)data.length]];
    [self sendCommand:command];
}

+ (void)setTimePositionAndColor:(NSInteger)type
                       position:(NSInteger)position
                          color:(NSInteger)color {
    NSData *command = [self createCommandWithBytes:@[
        @(0x00),
        @(WPCommandTypeSetTimePositionAndColor),
        @(0x01),
        @(0x00),
        @(0x06),
        @(0x01),
        @((uint8_t)type),
        @((uint8_t)position),
        @((uint8_t)((color >> 16) & 0xFF)),
        @((uint8_t)((color >> 8) & 0xFF)),
        @((uint8_t)(color & 0xFF))
    ]];

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"🎨 发送设置时间位置和颜色指令 - 类型:%ld 位置:%ld 颜色:0x%06lX",
                                   (long)type, (long)position, (long)color]];
    [self sendCommand:command];
}

+ (void)setQRCode:(uint8_t)type qrString:(NSString *)qrString {
    NSData *qrData = [qrString dataUsingEncoding:NSUTF8StringEncoding];

    NSMutableArray *commandBytes = [NSMutableArray arrayWithArray:@[
        @(0x00),
        @(WPCommandTypeQRCode),
        @(0x01),
        @(0x00),
        @((uint8_t)(3 + qrData.length)),
        @(0x01),
        @(type)
    ]];

    const uint8_t *bytes = (const uint8_t *)qrData.bytes;
    for (NSUInteger i = 0; i < qrData.length; i++) {
        [commandBytes addObject:@(bytes[i])];
    }

    NSData *command = [self createCommandWithBytes:commandBytes];

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"🔲 发送设置二维码指令 - 类型:%d 长度:%lu",
                                   type, (unsigned long)qrString.length]];
    [self sendCommand:command];
}

// MARK: - 辅助方法

+ (NSData *)phoneNumberToBytes:(NSString *)phoneNumber {
    NSString *processedNumber = phoneNumber;
    if (processedNumber.length % 2 != 0) {
        processedNumber = [processedNumber stringByAppendingString:@"f"];
    }
    processedNumber = [processedNumber stringByReplacingOccurrencesOfString:@"+" withString:@"a"];

    NSMutableData *result = [NSMutableData data];
    for (NSUInteger i = 0; i < processedNumber.length; i += 2) {
        NSString *hex = [processedNumber substringWithRange:NSMakeRange(i, 2)];
        unsigned int byteValue;
        [[NSScanner scannerWithString:hex] scanHexInt:&byteValue];
        uint8_t byte = (uint8_t)byteValue;
        [result appendBytes:&byte length:1];
    }

    return result;
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
    // 🆕 v2.0.4: 直接抛弃异常电量值（>100），不进行修正
    if (rawBatteryLevel > 100) {
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:
            @"⚠️ 电量值异常:%ld (超出范围100)，已抛弃该值", (long)rawBatteryLevel]];
        return;  // 直接返回，不保存，不回调
    } else if (rawBatteryLevel < 0) {
        // 理论上不会发生，但保留检查
        [[WPLogger sharedInstance] log:@"⚠️ 电量值异常（负数），已抛弃该值"];
        return;  // 直接返回，不保存，不回调
    }

    NSInteger batteryLevel = rawBatteryLevel;
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
