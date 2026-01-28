//
//  WPCommands.h
//  WatchProtocolSDK-ObjC
//
//  Created by Claude on 2026/01/20.
//  Copyright © 2026 Huaxin. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WPAlarmData;
@class WPDoNotDisturb;
@class WPReminderInfoResponse;

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

// MARK: - 数据结构（引用已有定义）
// WPAlarmData, WPDoNotDisturb, WPReminderInfo 已在 WPDeviceModel.h 中定义

/**
 * 提醒信息响应数据结构（用于设置提醒）
 */
@interface WPReminderInfoResponse : NSObject

@property (nonatomic, assign) NSInteger eventType;      // 事件类型
@property (nonatomic, assign) NSInteger cycle;          // 周期
@property (nonatomic, assign) NSInteger startHour;      // 开始小时
@property (nonatomic, assign) NSInteger startMinute;    // 开始分钟
@property (nonatomic, assign) NSInteger endHour;        // 结束小时
@property (nonatomic, assign) NSInteger endMinute;      // 结束分钟
@property (nonatomic, assign) NSInteger period;         // 周期

@end

/**
 * 联系人数据结构
 */
@interface WPContactData : NSObject

@property (nonatomic, assign) NSInteger index;          // 索引
@property (nonatomic, copy) NSString *name;             // 姓名
@property (nonatomic, copy) NSString *phoneNumber;      // 电话号码

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

// MARK: - 基础设备控制指令

/**
 * 查询设备语言
 */
+ (void)getDeviceLanguage;

/**
 * 设置设备语言
 * @param language 语言类型
 */
+ (void)setDeviceLanguage:(NSInteger)language;

/**
 * 获取设备单位格式
 */
+ (void)getDeviceUnitFormat;

/**
 * 设置设备单位格式
 * @param unitType 单位类型
 */
+ (void)setDeviceUnitFormat:(NSInteger)unitType;

/**
 * 恢复出厂设置
 */
+ (void)resetToFactorySettings;

/**
 * 设置设备屏幕超时时间
 * @param screenTimeout 超时时间（毫秒）
 */
+ (void)setDeviceScreenTimeout:(NSInteger)screenTimeout;

/**
 * 获取勿扰模式设置
 */
+ (void)getDoNotDisturb;

/**
 * 设置勿扰模式
 * @param bSwitch 开关
 * @param startHour 开始小时
 * @param startMinute 开始分钟
 * @param endHour 结束小时
 * @param endMinute 结束分钟
 */
+ (void)setDoNotDisturb:(BOOL)bSwitch
              startHour:(NSInteger)startHour
            startMinute:(NSInteger)startMinute
                endHour:(NSInteger)endHour
              endMinute:(NSInteger)endMinute;

/**
 * 设置天气单位
 * @param unit 单位类型
 */
+ (void)setWeatherUnit:(NSInteger)unit;

/**
 * 获取12/24小时制设置
 */
+ (void)get12H24HTimeFormat;

/**
 * 设置12/24小时制
 * @param format 格式 (0:12小时制 1:24小时制)
 */
+ (void)set12H24HTimeFormat:(NSInteger)format;

/**
 * 设置APP信息
 * @param phoneType 手机类型 (0:Android 1:iOS)
 */
+ (void)setAppInfo:(NSInteger)phoneType;

// MARK: - 个人信息指令

/**
 * 获取个人信息
 */
+ (void)getPersonalInfo;

// MARK: - 开关与设置指令

/**
 * 获取开关状态
 */
+ (void)getSwitchStatus;

/**
 * 设置开关状态
 * @param p0 开关参数0
 * @param p1 开关参数1
 */
+ (void)setSwitchStatus:(uint8_t)p0 p1:(uint8_t)p1;

/**
 * 绑定设备
 * @param value 绑定值 (0:解绑 1:绑定)
 */
+ (void)bindDevice:(uint8_t)value;

/**
 * 获取闹钟信息
 * @param type 闹钟类型
 */
+ (void)getAlarmInfo:(NSInteger)type;

/**
 * 设置闹钟信息
 * @param setCmd 设置命令
 * @param alarm 闹钟数据
 */
+ (void)setAlarmInfo:(NSInteger)setCmd alarm:(WPAlarmData *)alarm;

/**
 * 获取提醒信息
 * @param eventType 事件类型
 */
+ (void)getReminderInfo:(NSInteger)eventType;

/**
 * 设置提醒信息
 * @param response 提醒信息数据
 */
+ (void)setReminderInfo:(WPReminderInfoResponse *)response;

/**
 * 获取开关表扩展
 */
+ (void)getSwitchTableExtension;

/**
 * 设置开关表扩展
 * @param p0 参数0
 * @param p1 参数1
 * @param p2 参数2
 * @param p3 参数3
 */
+ (void)setSwitchTableExtension:(uint8_t)p0 p1:(uint8_t)p1 p2:(uint8_t)p2 p3:(uint8_t)p3;

// MARK: - 多媒体控制指令

/**
 * 音乐控制
 * @param action 操作类型
 * @param dataType 数据类型
 */
+ (void)musicControl:(NSInteger)action dataType:(NSInteger)dataType;

/**
 * 远程拍照
 * @param action 操作 (0:进入拍照模式 1:拍照 2:退出拍照模式)
 */
+ (void)remotePhoto:(NSInteger)action;

// MARK: - 通知与天气指令

/**
 * 消息推送
 * @param action 操作类型
 * @param control 控制参数
 * @param messageType 消息类型
 * @param messageContent 消息内容
 */
+ (void)messagePush:(NSInteger)action
            control:(NSInteger)control
        messageType:(NSInteger)messageType
     messageContent:(NSData *)messageContent;

/**
 * 设置天气信息
 * @param dateType 日期类型
 * @param weatherType 天气类型
 * @param currTemp 当前温度
 * @param lTemp 最低温度
 * @param hTemp 最高温度
 * @param cmd 命令
 */
+ (void)setWeatherInfo:(NSInteger)dateType
           weatherType:(NSInteger)weatherType
              currTemp:(NSInteger)currTemp
                 lTemp:(NSInteger)lTemp
                 hTemp:(NSInteger)hTemp
                   cmd:(NSInteger)cmd;

/**
 * 获取联系人信息
 */
+ (void)getContactInfo;

/**
 * 设置联系人信息
 * @param index 索引
 * @param name 姓名
 * @param phoneNumber 电话号码
 */
+ (void)setContactInfo:(NSInteger)index name:(NSString *)name phoneNumber:(NSString *)phoneNumber;

/**
 * 来电静音
 * @param mute 静音状态 (0:取消静音 1:静音)
 */
+ (void)incomingCallMute:(NSInteger)mute;

// MARK: - 健康数据指令（扩展）

/**
 * 获取目标设置
 */
+ (void)getTargetSettings;

/**
 * 设置目标设置
 * @param targetSwitch 目标开关
 * @param targetType 目标类型
 * @param targetLength 目标长度
 */
+ (void)setTargetSettings:(NSInteger)targetSwitch
               targetType:(NSInteger)targetType
             targetLength:(NSInteger)targetLength;

/**
 * 获取多运动模式数据
 */
+ (void)getMultiSportModeData;

/**
 * 删除运动模式数据
 */
+ (void)deleteSportModeData;

/**
 * 获取睡眠监测
 */
+ (void)getSleepMonitoring;

/**
 * 设置自动睡眠监测
 * @param startHour 开始小时
 * @param startMinute 开始分钟
 * @param endHour 结束小时
 * @param endMinute 结束分钟
 * @param alarmCycle 闹钟周期
 */
+ (void)setAutoSleepMonitoring:(NSInteger)startHour
                   startMinute:(NSInteger)startMinute
                       endHour:(NSInteger)endHour
                     endMinute:(NSInteger)endMinute
                    alarmCycle:(NSInteger)alarmCycle;

// MARK: - 表盘与资源指令

/**
 * 表盘市场查询
 * @param dataType 数据类型
 */
+ (void)dialMarketQuery:(NSInteger)dataType;

/**
 * 表盘市场设置传输配置
 * @param packageTotal 总包数
 * @param binSize 文件大小
 * @param mtu MTU值
 * @param dialType 表盘类型
 * @param dialNum 表盘编号
 * @param local 本地标志
 * @param typeValue 类型值
 * @param dialTypeValue 表盘类型值
 */
+ (void)dialMarketSetTransferConfig:(NSInteger)packageTotal
                            binSize:(NSInteger)binSize
                                mtu:(NSInteger)mtu
                           dialType:(NSInteger)dialType
                            dialNum:(NSInteger)dialNum
                              local:(NSInteger)local
                          typeValue:(NSInteger)typeValue
                      dialTypeValue:(NSInteger)dialTypeValue;

/**
 * 表盘市场传输数据
 * @param packageNum 包序号
 * @param binNum 文件序号
 * @param progressBar 进度条
 * @param control 控制参数
 * @param data 数据
 */
+ (void)dialMarketTransferData:(NSInteger)packageNum
                        binNum:(NSInteger)binNum
                   progressBar:(NSInteger)progressBar
                       control:(NSInteger)control
                          data:(NSData *)data;

/**
 * 资源升级查询
 */
+ (void)resourceUpgradeQuery;

/**
 * 资源升级设置传输配置
 * @param packageTotal 总包数
 * @param binSize 文件大小
 * @param mtu MTU值
 */
+ (void)resourceUpgradeSetTransferConfig:(NSInteger)packageTotal
                                 binSize:(NSInteger)binSize
                                     mtu:(NSInteger)mtu;

/**
 * 资源升级传输数据
 * @param data 数据
 */
+ (void)resourceUpgradeTransferData:(NSData *)data;

/**
 * 设置时间位置和颜色
 * @param type 类型
 * @param position 位置
 * @param color 颜色
 */
+ (void)setTimePositionAndColor:(NSInteger)type
                       position:(NSInteger)position
                          color:(NSInteger)color;

/**
 * 设置二维码
 * @param type 二维码类型
 * @param qrString 二维码字符串
 */
+ (void)setQRCode:(uint8_t)type qrString:(NSString *)qrString;

// MARK: - 辅助方法（供 Category 使用）

/**
 * 创建指令数据包
 * @param bytes 字节数组（NSNumber 数组）
 * @return 指令数据包
 *
 * @note 此方法用于将字节数组转换为 NSData 格式的指令
 * @note v2.0.7+: 声明为公开方法，供 WPCommands+FindDevice 等 Category 使用
 */
+ (NSData *)createCommandWithBytes:(NSArray<NSNumber *> *)bytes;

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
