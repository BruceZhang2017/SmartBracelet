//
//  WPDeviceModel.h
//  WatchProtocolSDK-ObjC
//
//  Created by Claude on 2026/01/12.
//  Copyright © 2026 Huaxin. All rights reserved.
//
//  🆕 v2.0.5 更新内容:
//  - 新增 peripheralUUID 属性支持快速重连
//  - 升级沙盒存储格式（兼容旧版本）
//  - 支持 UUID 持久化存储和恢复
//

#import <Foundation/Foundation.h>

@class WPPeripheralInfo;

NS_ASSUME_NONNULL_BEGIN

// MARK: - 勿扰模式数据
@interface WPDoNotDisturb : NSObject

@property (nonatomic, assign) BOOL bSwitch;
@property (nonatomic, assign) NSInteger startHour;
@property (nonatomic, assign) NSInteger startMinute;
@property (nonatomic, assign) NSInteger endHour;
@property (nonatomic, assign) NSInteger endMinute;

@end

// MARK: - 闹钟数据
@interface WPAlarmData : NSObject

@property (nonatomic, assign) NSInteger alarmId;
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) NSInteger hour;
@property (nonatomic, assign) NSInteger minute;
@property (nonatomic, assign) NSInteger repeatDays;  // 位图：周一到周日

@end

// MARK: - 提醒信息
@interface WPReminderInfo : NSObject

@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) NSInteger startHour;
@property (nonatomic, assign) NSInteger startMinute;
@property (nonatomic, assign) NSInteger endHour;
@property (nonatomic, assign) NSInteger endMinute;
@property (nonatomic, assign) NSInteger interval;  // 间隔（分钟）

@end

// MARK: - 蓝牙手表设备
@interface WPBluetoothWatchDevice : NSObject

// MARK: - 基本信息
@property (nonatomic, copy, nullable) NSString *deviceName;
@property (nonatomic, assign) NSInteger deviceModel;
@property (nonatomic, assign) NSInteger deviceID;
@property (nonatomic, assign) NSInteger brandID;
@property (nonatomic, copy, nullable) NSString *mac;

// 🆕 v2.0.5: 添加 peripheral UUID 用于快速重连
/// 设备的蓝牙外设标识符（UUID 字符串）
/// @note 用于快速重连，无需扫描
/// @note 首次连接成功后自动保存，支持持久化
/// @note 示例: "12345678-1234-1234-1234-123456789ABC"
@property (nonatomic, copy, nullable) NSString *peripheralUUID;

@property (nonatomic, assign) NSInteger batteryLevel;
@property (nonatomic, assign) BOOL isCharging;
@property (nonatomic, assign) NSInteger deviceLanguage;
@property (nonatomic, assign) NSInteger deviceUnitFormat;
@property (nonatomic, assign) NSInteger hardwareVersion;
@property (nonatomic, copy, nullable) NSString *firmwareVersion;

// MARK: - 屏幕信息
@property (nonatomic, assign) NSInteger screenType;      // 1=方形, 2=圆形
@property (nonatomic, assign) NSInteger screenWidth;     // 默认240
@property (nonatomic, assign) NSInteger screenHeight;    // 默认240
@property (nonatomic, assign) NSInteger screenBrightness; // 0-100

// MARK: - MTU
@property (nonatomic, assign) NSInteger mtu;

// MARK: - 个人信息
@property (nonatomic, assign) NSInteger sex;         // 0=男, 1=女
@property (nonatomic, assign) NSInteger age;
@property (nonatomic, assign) NSInteger height;
@property (nonatomic, assign) NSInteger weight;
@property (nonatomic, assign) NSInteger timeUnit;    // 0=12h, 1=24h
@property (nonatomic, assign) NSInteger baseUnit;

// MARK: - 勿扰和闹钟
@property (nonatomic, strong, nullable) WPDoNotDisturb *doNotDisturb;
@property (nonatomic, assign) NSInteger alarmCount;
@property (nonatomic, assign) NSInteger alarmCanUse;
@property (nonatomic, strong) NSMutableArray<WPAlarmData *> *alarms;

// MARK: - 提醒
@property (nonatomic, strong, nullable) WPReminderInfo *longSit;
@property (nonatomic, strong, nullable) WPReminderInfo *drinkWater;

// MARK: - 健康数据
@property (nonatomic, assign) NSInteger currentStep;
@property (nonatomic, assign) NSInteger currentSleep;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *currentSleepArray;
@property (nonatomic, assign) NSInteger currentCalorie;
@property (nonatomic, assign) NSInteger currentDistance;
@property (nonatomic, assign) NSInteger currentHeartrate;
@property (nonatomic, assign) NSInteger currentOxygen;
@property (nonatomic, assign) NSInteger currentSystolicPressure;   // 收缩压
@property (nonatomic, assign) NSInteger currentDiastolicPressure;  // 舒张压

// MARK: - 功能标志
@property (nonatomic, assign) NSInteger functionControlFlags;  // 功能控制标志位
@property (nonatomic, assign) NSInteger healthControlFlags;    // 健康控制标志位

// MARK: - 开关设置
@property (nonatomic, assign) BOOL isAntiLostSwitch;
@property (nonatomic, assign) BOOL isRaiseHandToBrightenScreen;
@property (nonatomic, assign) BOOL isAutoSyncSwitch;
@property (nonatomic, assign) BOOL isSleepMonitoringSwitch;
@property (nonatomic, assign) BOOL isMessageReminderMainSwitch;
@property (nonatomic, assign) BOOL isRegularExerciseDataUploadSwitch;
@property (nonatomic, assign) BOOL isGoalAchievementSwitch;
@property (nonatomic, assign) BOOL isMessageScreenDisplaySwitch;
@property (nonatomic, assign) BOOL isSoundSwitch;
@property (nonatomic, assign) BOOL isVibrationSwitch;
@property (nonatomic, assign) BOOL isRegularHealthDataUploadSwitch;
@property (nonatomic, assign) BOOL isMessageVibrationSwitch;

// MARK: - 通知开关
@property (nonatomic, assign) BOOL isNullMessage;
@property (nonatomic, assign) BOOL isIncomingCall;
@property (nonatomic, assign) BOOL isMissedCall;
@property (nonatomic, assign) BOOL isMessages;
@property (nonatomic, assign) BOOL isEmail;
@property (nonatomic, assign) BOOL isSchedule;
@property (nonatomic, assign) BOOL isFacetime;
@property (nonatomic, assign) BOOL isQQ;
@property (nonatomic, assign) BOOL isSkype;
@property (nonatomic, assign) BOOL isWechat;
@property (nonatomic, assign) BOOL isWhatsapp;
@property (nonatomic, assign) BOOL isGmail;
@property (nonatomic, assign) BOOL isHangout;
@property (nonatomic, assign) BOOL isInbox;
@property (nonatomic, assign) BOOL isLine;
@property (nonatomic, assign) BOOL isTwitter;
@property (nonatomic, assign) BOOL isFacebook;
@property (nonatomic, assign) BOOL isFacebookMessenger;
@property (nonatomic, assign) BOOL isInstagram;
@property (nonatomic, assign) BOOL isWeibo;
@property (nonatomic, assign) BOOL isKakaotalk;
@property (nonatomic, assign) BOOL isFacebookPageManager;
@property (nonatomic, assign) BOOL isViber;
@property (nonatomic, assign) BOOL isVkClient;
@property (nonatomic, assign) BOOL isTelegram;
@property (nonatomic, assign) BOOL isSnapchat;
@property (nonatomic, assign) BOOL isDingTalk;
@property (nonatomic, assign) BOOL isAlipay;
@property (nonatomic, assign) BOOL isTiktok;
@property (nonatomic, assign) BOOL isLinkedIn;

// MARK: - 步数换算方法
- (void)calculateCalorieAndDistance;
- (float)getFormattedDistance;
- (float)getFormattedCalorie;

// MARK: - 工厂方法
/**
 * 从扫描到的外设信息创建设备对象
 * @param peripheralInfo 扫描到的外设信息
 * @return 设备对象（仅包含基本信息：设备名和MAC地址）
 * @note 创建的设备对象仅包含扫描时可获取的基本信息，其他属性需要连接设备后获取
 */
+ (instancetype)deviceFromPeripheralInfo:(WPPeripheralInfo *)peripheralInfo;

/**
 * 从扫描到的外设信息创建设备对象并保存到沙盒
 * @param peripheralInfo 扫描到的外设信息
 * @note 这是一个便捷方法，等同于 [WPBluetoothWatchDevice saveToSandbox:[WPBluetoothWatchDevice deviceFromPeripheralInfo:peripheralInfo]]
 */
+ (void)savePeripheralInfoToSandbox:(WPPeripheralInfo *)peripheralInfo;

// MARK: - 沙盒存储方法
+ (void)saveToSandbox:(WPBluetoothWatchDevice *)device;
+ (nullable WPBluetoothWatchDevice *)loadFromSandboxWithMac:(NSString *)mac;
+ (nullable WPBluetoothWatchDevice *)loadFromSandboxWithDeviceName:(NSString *)deviceName;
+ (void)deleteFromSandboxWithMac:(NSString *)mac;
+ (void)loadAll;

@end

NS_ASSUME_NONNULL_END
