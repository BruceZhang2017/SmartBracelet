//
//  WPDeviceManager.m
//  WatchProtocolSDK-ObjC
//
//  Created by Claude on 2026/01/12.
//  Copyright © 2026 Huaxin. All rights reserved.
//

#import "WPDeviceManager.h"
#import "WPDeviceModel.h"
#import "WPLogger.h"
#import "WPHealthDataStorage.h"

@interface WPDeviceManager ()

@property (nonatomic, strong) NSLock *deviceCacheLock;
@property (nonatomic, strong) NSMutableArray<WPBluetoothWatchDevice *> *mutableCacheDevices;

@property (nonatomic, strong) NSLock *failMessageLock;
@property (nonatomic, strong) NSMutableArray<NSString *> *mutableFailMessages;
@property (nonatomic, assign) NSInteger maxFailMessageCount;

@property (nonatomic, strong) NSDateFormatter *logDateFormatter;

@end

@implementation WPDeviceManager

+ (instancetype)sharedInstance {
    static WPDeviceManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 初始化锁
        _deviceCacheLock = [[NSLock alloc] init];
        _failMessageLock = [[NSLock alloc] init];

        // 初始化设备缓存
        _mutableCacheDevices = [NSMutableArray array];

        // 初始化失败消息缓存
        _mutableFailMessages = [NSMutableArray array];
        _maxFailMessageCount = 50;  // 最多保留50条失败信息

        // 初始化日期格式化器
        _logDateFormatter = [[NSDateFormatter alloc] init];
        _logDateFormatter.dateFormat = @"HH:mm:ss.SSS";
        _logDateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    }
    return self;
}

// MARK: - 初始化方法

- (void)initializeWithStorage:(id<WPHealthDataStorageProtocol>)storage {
    self.dataStorage = storage;
    [[WPLogger sharedInstance] log:@"✅ WPDeviceManager 初始化成功"];
}

// MARK: - 设备缓存管理

- (NSArray<WPBluetoothWatchDevice *> *)cacheDevices {
    [self.deviceCacheLock lock];
    NSArray *result = [self.mutableCacheDevices copy];
    [self.deviceCacheLock unlock];
    return result;
}

- (NSInteger)deviceCount {
    [self.deviceCacheLock lock];
    NSInteger count = self.mutableCacheDevices.count;
    [self.deviceCacheLock unlock];
    return count;
}

- (void)addDevice:(WPBluetoothWatchDevice *)device {
    [self.deviceCacheLock lock];

    // 去重：如果已存在相同 MAC 地址的设备，则不添加
    if (device.mac && device.mac.length > 0) {
        BOOL exists = NO;
        for (WPBluetoothWatchDevice *existingDevice in self.mutableCacheDevices) {
            if ([existingDevice.mac isEqualToString:device.mac]) {
                exists = YES;
                break;
            }
        }

        if (!exists) {
            [self.mutableCacheDevices addObject:device];
            NSString *deviceName = device.deviceName ?: @"未知";
            [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"✅ 添加设备到缓存: %@ [%@]", deviceName, device.mac]];
        }
    }

    [self.deviceCacheLock unlock];
}

- (void)removeDeviceWithMac:(NSString *)mac {
    [self.deviceCacheLock lock];

    NSMutableArray *devicesToRemove = [NSMutableArray array];
    for (WPBluetoothWatchDevice *device in self.mutableCacheDevices) {
        if ([device.mac isEqualToString:mac]) {
            [devicesToRemove addObject:device];
        }
    }

    for (WPBluetoothWatchDevice *device in devicesToRemove) {
        [self.mutableCacheDevices removeObject:device];
    }

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"🗑️ 移除设备缓存: [%@]", mac]];

    [self.deviceCacheLock unlock];
}

- (nullable WPBluetoothWatchDevice *)findDeviceWithMac:(NSString *)mac {
    [self.deviceCacheLock lock];

    WPBluetoothWatchDevice *foundDevice = nil;
    for (WPBluetoothWatchDevice *device in self.mutableCacheDevices) {
        if ([device.mac isEqualToString:mac]) {
            foundDevice = device;
            break;
        }
    }

    [self.deviceCacheLock unlock];
    return foundDevice;
}

- (nullable WPBluetoothWatchDevice *)lastDevice {
    [self.deviceCacheLock lock];
    WPBluetoothWatchDevice *lastDevice = self.mutableCacheDevices.lastObject;
    [self.deviceCacheLock unlock];
    return lastDevice;
}

- (void)clearDeviceCache {
    [self.deviceCacheLock lock];
    [self.mutableCacheDevices removeAllObjects];
    [[WPLogger sharedInstance] log:@"🧹 清空所有设备缓存"];
    [self.deviceCacheLock unlock];
}

- (void)reloadDevices {
    [self.deviceCacheLock lock];

    [self.mutableCacheDevices removeAllObjects];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *dic = [defaults dictionaryForKey:@"xgzt"];

    if (!dic || dic.count == 0) {
        [self.deviceCacheLock unlock];
        return;
    }

    NSMutableSet *existingMACs = [NSMutableSet set];

    for (NSString *mac in dic) {
        // 检查 MAC 是否已存在（去重）
        if ([existingMACs containsObject:mac]) {
            continue;
        }

        [existingMACs addObject:mac];

        NSString *name = dic[mac];
        WPBluetoothWatchDevice *device = [[WPBluetoothWatchDevice alloc] init];
        device.deviceName = name;
        device.mac = mac;

        [self.mutableCacheDevices addObject:device];
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"📦 缓存设备: %@ - %@", mac, name]];
    }

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"✅ 重新加载设备完成，共 %ld 个设备", (long)self.mutableCacheDevices.count]];

    [self.deviceCacheLock unlock];
}

// MARK: - 连接失败诊断信息管理

- (NSString *)connectFailMessage {
    [self.failMessageLock lock];
    NSString *result = [self.mutableFailMessages componentsJoinedByString:@"\n"];
    [self.failMessageLock unlock];
    return result;
}

- (NSArray<NSString *> *)recentFailMessages {
    [self.failMessageLock lock];
    NSArray *result = [self.mutableFailMessages copy];
    [self.failMessageLock unlock];
    return result;
}

- (void)appendFailMessage:(NSString *)message {
    [self.failMessageLock lock];

    // 添加时间戳
    NSString *timestamp = [self.logDateFormatter stringFromDate:[NSDate date]];
    NSString *messageWithTimestamp = [NSString stringWithFormat:@"[%@] %@", timestamp, message];

    [self.mutableFailMessages addObject:messageWithTimestamp];

    // 限制数组大小，避免内存泄漏
    if (self.mutableFailMessages.count > self.maxFailMessageCount) {
        NSInteger removeCount = self.mutableFailMessages.count - self.maxFailMessageCount;
        NSRange range = NSMakeRange(0, removeCount);
        [self.mutableFailMessages removeObjectsInRange:range];
    }

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"❌ 连接失败: %@", message]];

    [self.failMessageLock unlock];
}

- (void)clearFailMessages {
    [self.failMessageLock lock];
    [self.mutableFailMessages removeAllObjects];
    [[WPLogger sharedInstance] log:@"🧹 清空连接失败信息"];
    [self.failMessageLock unlock];
}

- (NSArray<NSString *> *)getRecentFailMessagesWithCount:(NSInteger)count {
    [self.failMessageLock lock];

    NSInteger startIndex = MAX(0, (NSInteger)self.mutableFailMessages.count - count);
    NSRange range = NSMakeRange(startIndex, self.mutableFailMessages.count - startIndex);
    NSArray *result = [self.mutableFailMessages subarrayWithRange:range];

    [self.failMessageLock unlock];
    return result;
}

@end
