//
//  WPCommands.h
//  WatchProtocolSDK-ObjC
//
//  Created by Claude on 2026/01/20.
//  Copyright © 2026 Huaxin. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// MARK: - 指令类型枚举
typedef NS_ENUM(UInt8, WPCommandType) {
    // 基础设备控制指令 (0x50 - 0x5D)
    WPCommandTypeSyncTime = 0x50,                    // 同步时间
    WPCommandTypeGetBatteryLevel = 0x51,             // 获取电量
    WPCommandTypeSetScreenBrightness = 0x52,         // 设置屏幕亮度
    WPCommandTypeGetDeviceLanguage = 0x53,           // 获取设备语言
    WPCommandTypeSetDeviceUnitFormat = 0x54,         // 设置设备单位格式
    WPCommandTypeResetToFactorySettings = 0x55,      // 恢复出厂设置
    WPCommandTypeSetDeviceScreenTimeout = 0x56,      // 设置屏幕超时
    WPCommandTypeSetDoNotDisturb = 0x57,             // 设置勿扰模式
    WPCommandTypeFindBand = 0x58,                    // 查找手环
    WPCommandTypeFindPhone = 0x59,                   // 查找手机
    WPCommandTypeSetWeatherUnit = 0x5A,              // 设置天气单位
    WPCommandTypeSet12H24HTimeFormat = 0x5B,         // 设置12/24小时制
    WPCommandTypeGetDeviceInfo = 0x5C,               // 获取设备信息
    WPCommandTypeSetAppInfo = 0x5D,                  // 设置APP信息

    // 个人信息指令 (0x70)
    WPCommandTypePersonalInfo = 0x70,                // 个人信息

    // 开关与设置指令 (0x80 - 0x87)
    WPCommandTypeSwitchStatus = 0x80,                // 开关状态
    WPCommandTypeBindDevice = 0x81,                  // 绑定设备
    WPCommandTypeUnbindDeviceNotif = 0x82,           // 解绑设备通知
    WPCommandTypeAlarmInfo = 0x83,                   // 闹钟信息
    WPCommandTypeReminderInfo = 0x85,                // 提醒信息
    WPCommandTypeSwitchTableExtension = 0x86,        // 开关扩展表
    WPCommandTypeDisconnectBT = 0x87,                // 断开蓝牙

    // 多媒体控制指令 (0x90 - 0x91)
    WPCommandTypeMusicControl = 0x90,                // 音乐控制
    WPCommandTypeRemotePhoto = 0x91,                 // 远程拍照

    // 通知与天气指令 (0xA0 - 0xA6)
    WPCommandTypeMessagePush = 0xA0,                 // 消息推送
    WPCommandTypeSetWeatherInfo = 0xA1,              // 设置天气信息
    WPCommandTypeContactInfo = 0xA4,                 // 联系人信息
    WPCommandTypeIncomingCallMute = 0xA6,            // 来电静音

    // 健康数据指令 (0xB0 - 0xCA)
    WPCommandTypeTargetSettings = 0xB0,              // 目标设置
    WPCommandTypeMultiSportModeData = 0xB3,          // 多运动模式数据
    WPCommandTypeGetSleepMonitoring = 0xB5,          // 获取睡眠监测
    WPCommandTypeSetAutoSleepMonitoring = 0xB6,      // 设置自动睡眠监测
    WPCommandTypeStartTest = 0xC5,                   // 开始测试（心率/血氧/血压）
    WPCommandTypeGetNewestHealthData = 0xC7,         // 获取最新健康数据
    WPCommandTypeGetStepData = 0xC8,                 // 获取步数数据
    WPCommandTypeGetHistorySleepData = 0xC9,         // 获取历史睡眠数据
    WPCommandTypeGetNewestHeartData = 0xCA,          // 获取最新心率数据

    // 表盘与资源指令 (0xE0 - 0xE3)
    WPCommandTypeDialMarket = 0xE0,                  // 表盘市场
    WPCommandTypeSetTimePositionAndColor = 0xE1,     // 设置时间位置和颜色
    WPCommandTypeResourceUpgrade = 0xE2,             // 资源升级
    WPCommandTypeQRCode = 0xE3                       // 二维码
};

// MARK: - 响应数据结构

/**
 * 电量响应数据
 */
@interface WPBatteryLevelResponse : NSObject

@property (nonatomic, assign) NSInteger batteryLevel;  // 电量百分比 0-100
@property (nonatomic, assign) BOOL isCharging;         // 是否正在充电

@end

/**
 * 设备信息响应数据
 */
@interface WPDeviceInfoResponse : NSObject

@property (nonatomic, assign) NSInteger watchType;             // 手表类型
@property (nonatomic, assign) NSInteger supportLanguage;       // 支持的语言
@property (nonatomic, copy) NSString *serialNumber;            // 序列号
@property (nonatomic, assign) NSInteger firmwareMajorVersion;  // 固件主版本号
@property (nonatomic, assign) NSInteger firmwareMinorVersion;  // 固件次版本号

@end

/**
 * 心率响应数据
 */
@interface WPHeartRateResponse : NSObject

@property (nonatomic, assign) NSInteger timestamp;    // 时间戳（秒）
@property (nonatomic, assign) NSInteger heartRate;    // 心率值 (bpm)

@end

// MARK: - 指令管理器

/**
 * WPCommands - 核心指令集
 *
 * 🎯 功能：提供与手表设备通信的所有指令方法
 * 📡 协议：基于自定义二进制协议，通过 BLE 特征值写入
 * 🔄 响应：通过 handleResponse 方法统一解析设备返回的数据
 */
@interface WPCommands : NSObject

// MARK: - 健康数据存储协议
/**
 * 健康数据存储实现（由外部注入）
 * 用于保存心率、血氧、血压等健康数据
 */
@property (class, nonatomic, strong) id healthDataStorage;

// MARK: - 🔥 P0 核心指令方法

/**
 * 同步时间到设备
 * @param timeZone 时区（小时差，例如 +8 表示东八区）
 * @param utc UTC时间戳（秒）
 */
+ (void)syncTime:(NSInteger)timeZone utc:(uint32_t)utc;

/**
 * 🔥 获取设备电量
 * @note 响应将通过 handleResponse 解析并回调 WPBluetoothManagerDelegate
 */
+ (void)getBatteryLevel;

/**
 * 🔥 获取设备信息
 * @note 包括设备类型、序列号、固件版本等
 */
+ (void)getDeviceInfo;

/**
 * 设置个人信息
 * @param age 年龄
 * @param height 身高（厘米）
 * @param weight 体重（千克）
 * @param gender 性别（0:女 1:男）
 */
+ (void)setPersonalInfo:(NSInteger)age height:(NSInteger)height weight:(NSInteger)weight gender:(NSInteger)gender;

// MARK: - 🟡 P1 健康数据指令

/**
 * 🔥 开始测试（心率/血氧/血压）
 * @param cmdType 测试类型（0:心率 1:血氧 2:血压）
 * @param control 控制参数（0:停止 1:开始）
 */
+ (void)startTest:(NSInteger)cmdType control:(NSInteger)control;

/**
 * 🔥 获取最新心率数据
 * @param type 数据类型（0:心率 1:血氧 2:血压）
 */
+ (void)getNewestHeartData:(NSInteger)type;

/**
 * 获取最新健康数据
 * @param type 数据类型
 */
+ (void)getNewestHealthData:(NSInteger)type;

/**
 * 获取步数数据
 * @param startTime 开始时间戳
 * @param endTime 结束时间戳
 */
+ (void)getStepData:(uint32_t)startTime endTime:(uint32_t)endTime;

/**
 * 获取历史睡眠数据
 * @param startTime 开始时间戳
 * @param endTime 结束时间戳
 */
+ (void)getHistorySleepData:(uint32_t)startTime endTime:(uint32_t)endTime;

// MARK: - 🟢 P2 设备控制指令

/**
 * 获取屏幕亮度
 */
+ (void)getScreenBrightness;

/**
 * 设置屏幕亮度
 * @param brightnessValue 亮度值 0-100
 */
+ (void)setScreenBrightness:(NSInteger)brightnessValue;

/**
 * 查找手环
 */
+ (void)findBand;

/**
 * 查找手机
 */
+ (void)findPhone;

/**
 * 断开蓝牙连接
 */
+ (void)disconnectBT;

// MARK: - 🔥 核心响应解析方法

/**
 * 🔥 统一处理设备响应数据包
 * @param response 设备返回的字节数组
 *
 * @note 此方法是协议解析的核心，负责：
 *   1. 识别响应数据包的指令类型
 *   2. 解析响应数据并提取有效信息
 *   3. 通过代理回调通知应用层
 *   4. 自动更新 currentDevice 的相关属性
 *
 * @warning 此方法应由 WPBluetoothManager 在接收到 BLE 数据时自动调用
 */
+ (void)handleResponse:(NSData *)response;

@end

NS_ASSUME_NONNULL_END
