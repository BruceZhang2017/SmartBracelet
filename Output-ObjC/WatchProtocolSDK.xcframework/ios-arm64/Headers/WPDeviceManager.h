//
//  WPDeviceManager.h
//  WatchProtocolSDK-ObjC
//
//  Created by Claude on 2026/01/12.
//  Copyright © 2026 Huaxin. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WPBluetoothWatchDevice;
@protocol WPHealthDataStorageProtocol;

NS_ASSUME_NONNULL_BEGIN

/**
 * 设备管理器（线程安全单例）
 * 负责管理设备缓存和连接失败诊断信息
 */
@interface WPDeviceManager : NSObject

// MARK: - 单例
@property (class, nonatomic, readonly) WPDeviceManager *sharedInstance;

// MARK: - 数据存储
@property (nonatomic, weak, nullable) id<WPHealthDataStorageProtocol> dataStorage;

// MARK: - 设备缓存管理

/**
 * 设备缓存列表（只读，线程安全）
 */
@property (nonatomic, copy, readonly) NSArray<WPBluetoothWatchDevice *> *cacheDevices;

/**
 * 设备缓存数量
 */
@property (nonatomic, assign, readonly) NSInteger deviceCount;

/**
 * 添加设备到缓存
 * @param device 要添加的设备
 */
- (void)addDevice:(WPBluetoothWatchDevice *)device;

/**
 * 移除指定 MAC 地址的设备
 * @param mac 设备 MAC 地址
 */
- (void)removeDeviceWithMac:(NSString *)mac;

/**
 * 查找指定 MAC 地址的设备
 * @param mac 设备 MAC 地址
 * @return 找到的设备，如果不存在则返回 nil
 */
- (nullable WPBluetoothWatchDevice *)findDeviceWithMac:(NSString *)mac;

/**
 * 获取最后一个设备
 * @return 最后一个设备，如果缓存为空则返回 nil
 */
- (nullable WPBluetoothWatchDevice *)lastDevice;

/**
 * 清空所有设备缓存
 */
- (void)clearDeviceCache;

/**
 * 重新加载所有设备（从 UserDefaults）
 */
- (void)reloadDevices;

// MARK: - 连接失败诊断信息管理

/**
 * 获取所有连接失败信息（只读）
 */
@property (nonatomic, copy, readonly) NSString *connectFailMessage;

/**
 * 获取最近的失败信息数组
 */
@property (nonatomic, copy, readonly) NSArray<NSString *> *recentFailMessages;

/**
 * 追加连接失败信息
 * @param message 失败信息
 */
- (void)appendFailMessage:(NSString *)message;

/**
 * 清空所有连接失败信息
 */
- (void)clearFailMessages;

/**
 * 获取最近 N 条失败信息
 * @param count 要获取的数量
 * @return 最近的失败信息数组
 */
- (NSArray<NSString *> *)getRecentFailMessagesWithCount:(NSInteger)count;

// MARK: - 初始化方法

/**
 * 初始化设备管理器（配置数据存储）
 * @param storage 数据存储实现
 */
- (void)initializeWithStorage:(id<WPHealthDataStorageProtocol>)storage;

@end

NS_ASSUME_NONNULL_END
