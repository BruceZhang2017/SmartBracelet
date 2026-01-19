//
//  WPBluetoothManager.h
//  WatchProtocolSDK-ObjC
//
//  Created by Claude on 2026/01/12.
//  Copyright © 2026 Huaxin. All rights reserved.
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

// MARK: - 重连管理

/**
 * 重连到设备
 */
- (void)reconnectToDevice;

@end

NS_ASSUME_NONNULL_END
