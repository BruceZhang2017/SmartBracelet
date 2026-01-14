//
//  WPDeviceModel.m
//  WatchProtocolSDK-ObjC
//
//  Created by Claude on 2026/01/12.
//  Copyright © 2026 Huaxin. All rights reserved.
//

#import "WPDeviceModel.h"

// MARK: - 勿扰模式实现
@implementation WPDoNotDisturb
@end

// MARK: - 闹钟数据实现
@implementation WPAlarmData
@end

// MARK: - 提醒信息实现
@implementation WPReminderInfo
@end

// MARK: - 蓝牙手表设备实现
@implementation WPBluetoothWatchDevice

- (instancetype)init {
    self = [super init];
    if (self) {
        // 初始化默认值
        _screenType = 1;       // 默认方形
        _screenWidth = 240;    // 默认240
        _screenHeight = 240;   // 默认240
        _mtu = 0;
        _sex = 0;
        _age = 0;
        _height = 0;
        _weight = 0;
        _timeUnit = 0;
        _baseUnit = 0;

        _alarms = [NSMutableArray array];
        _currentSleepArray = [NSMutableArray arrayWithObjects:@0, @0, @0, nil];

        // 通知开关默认值
        _isNullMessage = YES;
        _isMessages = YES;
        _isEmail = YES;
        _isSchedule = YES;
        _isFacetime = YES;
        _isQQ = YES;
        _isSkype = YES;
        _isWechat = YES;
        _isWhatsapp = YES;
        _isGmail = YES;
        _isHangout = YES;
        _isInbox = YES;
        _isLine = YES;
        _isTwitter = YES;
        _isFacebook = YES;
        _isFacebookMessenger = YES;
        _isInstagram = YES;
        _isWeibo = YES;
        _isKakaotalk = YES;
        _isFacebookPageManager = YES;
        _isViber = YES;
        _isVkClient = YES;
        _isTelegram = YES;
        _isSnapchat = YES;
        _isDingTalk = YES;
        _isAlipay = YES;
        _isTiktok = YES;
        _isLinkedIn = YES;
    }
    return self;
}

// MARK: - 步数换算方法

- (void)calculateCalorieAndDistance {
    // 计算每一步的基准距离（单位转换）
    // distance = height * 415 / 1000
    NSInteger stepDistance = self.height * 415 / 1000;

    // 计算总距离（内部单位）
    // unit = step * distance
    NSInteger totalDistanceUnit = self.currentStep * stepDistance;

    // 计算卡路里（内部单位）
    // v = unit * weight * 55
    NSInteger calorieUnit = totalDistanceUnit * self.weight * 55;

    // 更新距离
    self.currentDistance = totalDistanceUnit;

    // 更新卡路里
    self.currentCalorie = calorieUnit;

    NSLog(@"步数换算 - 步数：%ld, 距离（内部单位）：%ld, 卡路里（内部单位）：%ld",
          (long)self.currentStep, (long)totalDistanceUnit, (long)calorieUnit);
}

- (float)getFormattedDistance {
    return (float)self.currentDistance / 100000.0f;
}

- (float)getFormattedCalorie {
    float truncated = floorf((float)self.currentCalorie / 10000.0f) / 1000.0f;
    return truncated;
}

// MARK: - 沙盒存储方法

+ (void)saveToSandbox:(WPBluetoothWatchDevice *)device {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // 安全检查 mac 地址
    if (!device.mac || device.mac.length == 0) {
        NSLog(@"Error: device.mac is nil or empty");
        return;
    }

    // 安全检查设备名称
    if (!device.deviceName || device.deviceName.length == 0) {
        NSLog(@"Error: deviceName is nil for mac address %@", device.mac);
        return;
    }

    NSMutableDictionary *dic = [[defaults dictionaryForKey:@"xgzt"] mutableCopy];
    if (!dic) {
        dic = [NSMutableDictionary dictionary];
    }

    // 检查是否已存在
    NSString *existingName = dic[device.mac];
    if (existingName && existingName.length > 0) {
        // 已存在，不执行保存
        return;
    }

    // 存储设备
    dic[device.mac] = device.deviceName;
    [defaults setObject:dic forKey:@"xgzt"];
    [defaults synchronize];

    // 重新加载设备列表
    [WPBluetoothWatchDevice loadAll];
}

+ (nullable WPBluetoothWatchDevice *)loadFromSandboxWithMac:(NSString *)mac {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *dic = [defaults dictionaryForKey:@"xgzt"];

    if (!dic) {
        return nil;
    }

    NSString *name = dic[mac];
    if (!name) {
        return nil;
    }

    WPBluetoothWatchDevice *device = [[WPBluetoothWatchDevice alloc] init];
    device.deviceName = name;
    device.mac = mac;

    return device;
}

+ (nullable WPBluetoothWatchDevice *)loadFromSandboxWithDeviceName:(NSString *)deviceName {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *dic = [defaults dictionaryForKey:@"xgzt"];

    if (!dic) {
        return nil;
    }

    // 遍历查找匹配的设备
    for (NSString *mac in dic) {
        NSString *name = dic[mac];
        if ([name isEqualToString:deviceName]) {
            WPBluetoothWatchDevice *device = [[WPBluetoothWatchDevice alloc] init];
            device.deviceName = name;
            device.mac = mac;
            return device;
        }
    }

    return nil;
}

+ (void)deleteFromSandboxWithMac:(NSString *)mac {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *dic = [[defaults dictionaryForKey:@"xgzt"] mutableCopy];

    if (!dic || dic.count == 0) {
        return;
    }

    [dic removeObjectForKey:mac];

    NSLog(@"删除设备后：%lu", (unsigned long)dic.count);

    [defaults setObject:dic forKey:@"xgzt"];
    [defaults synchronize];

    // 重新加载设备列表
    [WPBluetoothWatchDevice loadAll];
}

+ (void)loadAll {
    // 在设备管理器中实现
    // 此处仅作为接口保留
    NSLog(@"loadAll called - will be implemented in WPDeviceManager");
}

@end
