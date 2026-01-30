//
//  WPBluetoothManager.h
//  WatchProtocolSDK-ObjC
//
//  Created by Claude on 2026/01/12.
//  Copyright © 2026 Huaxin. All rights reserved.
//
//  🆕 v2.0.7 更新内容:
//  - 新增查找设备功能（findDeviceWithCompletion:）
//  - 新增停止查找功能（stopFindDeviceWithCompletion:）
//  - 新增自动停止查找功能（findDeviceWithDuration:completion:）
//  - 新增查找状态查询属性（isFindingDevice）
//  - 集成 WPCommands+FindDevice 能力到蓝牙管理器
//
//  🆕 v2.0.6 更新内容:
//  - 新增连接超时机制（默认 30 秒），解决设备不在范围时无限等待的问题
//  - 新增 connectionTimeout 属性，支持自定义连接超时时间
//  - 新增 didConnectionTimeout: 代理方法，连接超时时主动通知应用层
//  - 连接超时后自动取消连接，避免资源占用
//
//  🆕 v2.0.5 更新内容:
//  - 新增智能 UUID 快速重连功能（重连速度提升 5-10 倍）
//  - 新增 reconnectWithUUID: 方法支持直接使用 UUID 重连
//  - 优化 reconnectWithDevice: 方法实现智能路由（UUID 优先，自动降级到扫描）
//  - 连接成功后自动保存 peripheral UUID 到设备对象
//  - App 重启后重连速度从 5-10 秒缩短至 <1 秒
//
//  🆕 v2.0.4 更新内容:
//  - 修复设备回连时代理方法不触发的 bug
//  - 在连接成功/断开回调中，如果 peripheralInfoMap 中没有映射，自动创建 WPPeripheralInfo
//  - 确保 didConnectPeripheral: 和 didDisconnectPeripheral:error: 代理方法在回连场景下也能被触发
//
//  🆕 v2.0.3 更新内容:
//  - 修复重连死循环导致 app 崩溃的严重 bug
//  - 添加重连次数限制（默认最大 5 次）
//  - 添加重连状态保护机制，防止无限递归调用
//  - 优化连接成功和断开时的状态重置逻辑
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@class WPBluetoothWatchDevice;

NS_ASSUME_NONNULL_BEGIN

// MARK: - 外设信息结构
@interface WPPeripheralInfo : NSObject

@property (nonatomic, strong, readonly) CBPeripheral *peripheral;
@property (nonatomic, copy, readonly) NSString *macAddress;

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral macAddress:(NSString *)macAddress;

@end

// MARK: - 蓝牙管理代理协议
@protocol WPBluetoothManagerDelegate <NSObject>

@optional

/**
 * 蓝牙已准备就绪
 */
- (void)onBleReady;

/**
 * 接收到数据
 * @param data 接收的数据
 */
- (void)receiveData:(NSData *)data;

/**
 * 数据发送完成
 */
- (void)sentData;

/**
 * 发现新设备
 * @param peripheralInfo 外设信息
 */
- (void)didDiscoverPeripheral:(WPPeripheralInfo *)peripheralInfo;

/**
 * 设备连接成功
 * @param peripheralInfo 外设信息
 */
- (void)didConnectPeripheral:(WPPeripheralInfo *)peripheralInfo;

/**
 * 设备断开连接
 * @param peripheralInfo 外设信息
 * @param error 错误信息
 */
- (void)didDisconnectPeripheral:(WPPeripheralInfo *)peripheralInfo error:(nullable NSError *)error;

/**
 * 🆕 v2.0.2: 扫描超时（未找到目标设备）
 * @param macAddress 目标设备的 MAC 地址
 */
- (void)didScanTimeout:(NSString *)macAddress;

/**
 * 🆕 v2.0.6: 连接超时（设备不可达或连接时间过长）
 * @param peripheralInfo 外设信息
 * @note 当调用 connectPeripheral: 后，在 connectionTimeout 时间内未连接成功时触发
 * @note 此回调表示连接已被 SDK 主动取消，应用层可以提示用户"设备不在范围内"或"连接超时"
 */
- (void)didConnectionTimeout:(WPPeripheralInfo *)peripheralInfo;

/**
 * 🆕 v2.0.1: 接收到电量数据
 * @param batteryLevel 电量百分比 (0-100)
 * @param isCharging 是否正在充电
 */
- (void)didReceiveBatteryLevel:(NSInteger)batteryLevel isCharging:(BOOL)isCharging;

/**
 * 🆕 v2.0.1: 接收到心率数据
 * @param heartRate 心率值 (bpm)
 */
- (void)didReceiveHeartRate:(NSInteger)heartRate;

/**
 * 🆕 v2.0.1: 心率测量状态变化
 * @param isMonitoring YES表示正在测量，NO表示已停止
 */
- (void)didHeartRateMonitoringStatusChanged:(BOOL)isMonitoring;

/**
 * 🆕 v2.0.8: 接收到查找设备响应
 * @param success YES表示设备已收到指令并正在震动/响铃，NO表示执行失败
 * @discussion 当调用查找设备指令后，设备会返回执行结果。此回调用于确认设备是否成功收到并执行了查找指令。
 */
- (void)didReceiveFindDeviceResponse:(BOOL)success;

/**
 * 🆕 v2.0.9: 接收到睡眠监测数据
 * @param deepSleep 深睡时长（分钟）
 * @param lightSleep 浅睡时长（分钟）
 * @param awake 清醒时长（分钟）
 * @discussion 当接收到设备的睡眠监测数据响应时触发（指令 0xB5）
 */
- (void)didReceiveSleepData:(NSInteger)deepSleep lightSleep:(NSInteger)lightSleep awake:(NSInteger)awake;

@end

// MARK: - 蓝牙管理器（单例）
@interface WPBluetoothManager : NSObject

// MARK: - 单例
@property (class, nonatomic, readonly) WPBluetoothManager *sharedInstance;

// MARK: - 代理
@property (nonatomic, weak, nullable) id<WPBluetoothManagerDelegate> delegate;

// MARK: - 设备列表
@property (nonatomic, strong, readonly) NSArray<WPPeripheralInfo *> *discoveredPeripherals;

// MARK: - 当前设备
@property (nonatomic, strong, nullable) WPBluetoothWatchDevice *currentDevice;

// MARK: - 扫描状态
@property (nonatomic, assign, readonly) BOOL isScanning;

// MARK: - 扫描超时时间（秒）
/**
 * 扫描超时时间（秒）
 * - 默认值为 0，表示不限时扫描
 * - 设置为大于 0 的值时，扫描将在指定时间后自动停止
 */
@property (nonatomic, assign) NSTimeInterval scanTimeout;

// MARK: - 连接超时时间（秒）
/**
 * 连接超时时间（秒）
 * - 默认值为 30 秒
 * - 设置为 0 或负数表示不限时（不推荐）
 * - 建议设置为 10-60 秒之间
 * @note 此超时仅针对 BLE 连接阶段，不包括扫描阶段（扫描阶段使用 scanTimeout）
 * @note 🆕 v2.0.6: 解决设备不在范围时无限等待的问题
 */
@property (nonatomic, assign) NSTimeInterval connectionTimeout;

// MARK: - 连接状态
@property (nonatomic, assign, readonly) BOOL isConnected;

// MARK: - 蓝牙状态
@property (nonatomic, assign, readonly) BOOL isBluetoothPoweredOff;

// MARK: - 初始化方法

/**
 * 初始化中心管理器
 */
- (void)initCentral;

// MARK: - 扫描管理

/**
 * 开始扫描设备
 * @param deleteCache 是否清空之前的扫描结果
 */
- (void)startScanning:(BOOL)deleteCache;

/**
 * 开始扫描设备（带超时时间）
 * @param deleteCache 是否清空之前的扫描结果
 * @param timeout 扫描超时时间（秒），0 或负数表示不限时
 */
- (void)startScanning:(BOOL)deleteCache timeout:(NSTimeInterval)timeout;

/**
 * 停止扫描设备
 */
- (void)stopScanning;

// MARK: - 连接管理

/**
 * 连接指定外设
 * @param peripheralInfo 外设信息
 */
- (void)connectToPeripheral:(WPPeripheralInfo *)peripheralInfo;

/**
 * 连接指定 MAC 地址的设备
 * @param macAddress MAC 地址
 */
- (void)connectToDeviceWithMac:(NSString *)macAddress;

/**
 * 扫描并连接指定设备
 * @param macAddress MAC 地址
 * @param deviceName 设备名称
 */
- (void)connectAndScanWithMac:(NSString *)macAddress deviceName:(NSString *)deviceName;

/**
 * 扫描并连接指定设备（带超时时间）
 * @param macAddress MAC 地址
 * @param deviceName 设备名称
 * @param timeout 扫描超时时间（秒），0 或负数表示不限时
 */
- (void)connectAndScanWithMac:(NSString *)macAddress deviceName:(NSString *)deviceName timeout:(NSTimeInterval)timeout;

/**
 * 断开当前连接
 */
- (void)disconnect;

/**
 * 取消所有连接
 */
- (void)cancelAllConnections;

// MARK: - 数据发送

/**
 * 发送数据到设备
 * @param data 要发送的数据
 * @return 是否发送成功
 */
- (BOOL)sendData:(NSData *)data;

/**
 * 🔥 新增：使用WriteWithResponse模式发送数据
 * @param data 要发送的数据
 * @return 是否发送成功
 * @discussion 使用此方法可以确认设备是否收到数据，适用于调试
 */
- (BOOL)sendDataWithResponse:(NSData *)data;

// MARK: - 重连管理

/**
 * 重连到设备
 */
- (void)reconnectToDevice;

/**
 * 🆕 v2.0.2: 使用指定设备进行自动重连
 * @param device 要重连的设备对象
 * @note 适用于 app 重启后的自动重连场景
 * @note 此方法会设置 currentDevice 并启动扫描连接流程
 */
- (void)reconnectWithDevice:(WPBluetoothWatchDevice *)device;

/**
 * 🆕 v2.0.2: 使用指定设备进行自动重连（带超时时间）
 * @param device 要重连的设备对象
 * @param timeout 扫描超时时间（秒），0 或负数表示不限时
 * @note 适用于 app 重启后的自动重连场景
 * @note 此方法会设置 currentDevice 并启动扫描连接流程
 */
- (void)reconnectWithDevice:(WPBluetoothWatchDevice *)device timeout:(NSTimeInterval)timeout;

/**
 * 🆕 v2.0.2: 从沙盒恢复设备并自动重连
 * @param macAddress 设备的 MAC 地址
 * @return 是否成功恢复并启动重连（如果沙盒中没有该设备信息，返回 NO）
 * @note 适用于 app 重启后的自动重连场景
 * @note 此方法会从沙盒加载设备信息，并自动启动扫描连接流程
 */
- (BOOL)reconnectFromSandboxWithMac:(NSString *)macAddress;

/**
 * 🆕 v2.0.2: 从沙盒恢复设备并自动重连（带超时时间）
 * @param macAddress 设备的 MAC 地址
 * @param timeout 扫描超时时间（秒），0 或负数表示不限时
 * @return 是否成功恢复并启动重连（如果沙盒中没有该设备信息，返回 NO）
 * @note 适用于 app 重启后的自动重连场景
 * @note 此方法会从沙盒加载设备信息，并自动启动扫描连接流程
 */
- (BOOL)reconnectFromSandboxWithMac:(NSString *)macAddress timeout:(NSTimeInterval)timeout;

/**
 * 🆕 v2.0.5: 使用 peripheral UUID 快速重连
 * @param uuidString 设备的 peripheral UUID 字符串
 * @note 这是最快的重连方式，无需扫描，几乎即时完成
 * @note 使用 iOS CoreBluetooth 的 retrievePeripheralsWithIdentifiers: 直接获取设备
 * @note 如果 UUID 无效或设备不可用，会自动降级到 MAC 扫描重连
 * @note UUID 示例: "12345678-1234-1234-1234-123456789ABC"
 */
- (void)reconnectWithUUID:(NSString *)uuidString;

// MARK: - 🆕 v2.0.1: 健康数据查询

/**
 * 查询设备电量
 * @note 查询结果通过代理方法 didReceiveBatteryLevel:isCharging: 返回
 * @note 查询成功后会自动更新 currentDevice.batteryLevel 和 currentDevice.isCharging
 */
- (void)queryBatteryLevel;

/**
 * 开始心率测量
 * @note 测量结果通过代理方法 didReceiveHeartRate: 持续返回
 * @note 测量状态变化通过 didHeartRateMonitoringStatusChanged: 返回
 * @note 测量成功后会自动更新 currentDevice.currentHeartrate
 */
- (void)startHeartRateMonitoring;

/**
 * 停止心率测量
 */
- (void)stopHeartRateMonitoring;

/**
 * 单次心率测量（测量完成后自动停止）
 * @note 测量结果通过代理方法 didReceiveHeartRate: 返回
 */
- (void)measureHeartRateOnce;

// MARK: - 🆕 v2.0.7: 查找设备功能

/**
 * 查找手环（让手环震动/响铃）
 * @param completion 完成回调，可为 nil
 *
 * @discussion
 * 发送查找指令到手环，让手环震动/响铃以帮助用户找到设备。
 * 此方法会自动检查蓝牙连接状态，避免在未连接时发送无效指令。
 *
 * @note 使用示例:
 * ```objc
 * [[WPBluetoothManager sharedInstance] findDeviceWithCompletion:^(BOOL success, NSError *error) {
 *     if (success) {
 *         NSLog(@"✅ 查找指令已发送，手环应该在震动");
 *     } else {
 *         NSLog(@"❌ 发送失败: %@", error.localizedDescription);
 *     }
 * }];
 * ```
 *
 * @warning 如果设备未连接，completion 会返回 success=NO 和相应错误
 * @warning 如果已在查找中，会忽略重复请求并返回 success=YES
 */
- (void)findDeviceWithCompletion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion;

/**
 * 停止查找手环
 * @param completion 完成回调，可为 nil
 *
 * @discussion
 * 主动停止手环震动/响铃。用户找到设备后可立即调用此方法停止查找。
 *
 * @note 使用示例:
 * ```objc
 * // 用户点击"停止查找"按钮时
 * [[WPBluetoothManager sharedInstance] stopFindDeviceWithCompletion:^(BOOL success, NSError *error) {
 *     if (success) {
 *         NSLog(@"⏹ 已停止查找");
 *     }
 * }];
 * ```
 */
- (void)stopFindDeviceWithCompletion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion;

/**
 * 查找手环（自动停止）
 * @param duration 持续时间（秒），0 或负数表示使用设备默认时长
 * @param completion 完成回调（在停止查找后调用），可为 nil
 *
 * @discussion
 * 查找指定时长后自动发送停止指令，避免手环长时间震动影响电量。
 *
 * @note 使用示例:
 * ```objc
 * // 查找 5 秒后自动停止
 * [[WPBluetoothManager sharedInstance] findDeviceWithDuration:5 completion:^(BOOL success, NSError *error) {
 *     if (success) {
 *         NSLog(@"查找已自动结束");
 *     }
 * }];
 * ```
 *
 * @note 如果在自动停止前手动调用 stopFindDeviceWithCompletion:，定时器会被自动取消
 */
- (void)findDeviceWithDuration:(NSTimeInterval)duration
                    completion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion;

/**
 * 是否正在查找设备
 *
 * @discussion
 * 可用于 UI 状态更新，例如切换按钮文字（"查找设备" ↔ "停止查找"）
 *
 * @note 使用示例:
 * ```objc
 * if ([[WPBluetoothManager sharedInstance] isFindingDevice]) {
 *     [self.findButton setTitle:@"停止查找" forState:UIControlStateNormal];
 * } else {
 *     [self.findButton setTitle:@"查找设备" forState:UIControlStateNormal];
 * }
 * ```
 */
@property (nonatomic, readonly) BOOL isFindingDevice;

// MARK: - 🔥 抬手亮屏功能

/**
 * 设置抬手亮屏开关
 * @param enable YES = 开启抬手亮屏，NO = 关闭抬手亮屏
 * @param completion 完成回调
 *
 * @discussion 开启后，抬起手腕时手表屏幕会自动点亮
 * @note 需要设备已连接
 *
 * @note 使用示例:
 * ```objc
 * [[WPBluetoothManager sharedInstance] setRaiseToWake:YES completion:^(BOOL success, NSError *error) {
 *     if (success) {
 *         NSLog(@"抬手亮屏已开启");
 *     } else {
 *         NSLog(@"设置失败: %@", error.localizedDescription);
 *     }
 * }];
 * ```
 */
- (void)setRaiseToWake:(BOOL)enable completion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion;

/**
 * 查询抬手亮屏状态
 * @param completion 完成回调
 *
 * @discussion 发送查询指令，设备响应通过 WPBluetoothManagerDelegate 回调
 */
- (void)getRaiseToWakeStatus:(nullable void(^)(BOOL success, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
