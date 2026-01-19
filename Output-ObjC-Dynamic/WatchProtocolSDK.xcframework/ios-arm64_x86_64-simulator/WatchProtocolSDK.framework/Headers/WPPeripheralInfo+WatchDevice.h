//
//  WPPeripheralInfo+WatchDevice.h
//  WatchProtocolSDK-ObjC
//
//  Created by Claude on 2026/01/19.
//  Copyright © 2026 Huaxin. All rights reserved.
//

#import "../Core/WPBluetoothManager.h"
#import "../Models/WPDeviceModel.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * WPPeripheralInfo 便捷扩展
 *
 * 提供将扫描到的外设信息转换为 WPBluetoothWatchDevice 的便捷方法
 *
 * 使用示例:
 * @code
 * WPPeripheralInfo *info = ...;
 * WPBluetoothWatchDevice *device = [info toWatchDevice];
 * @endcode
 */
@interface WPPeripheralInfo (WatchDevice)

/**
 * 将外设信息转换为设备对象
 * @return 设备对象（仅包含基本信息：设备名和MAC地址）
 * @note 这是一个便捷方法，内部调用 [WPBluetoothWatchDevice deviceFromPeripheralInfo:self]
 */
- (WPBluetoothWatchDevice *)toWatchDevice;

/**
 * 将外设信息转换为设备对象并保存到沙盒
 * @note 这是一个便捷方法，内部调用 [WPBluetoothWatchDevice savePeripheralInfoToSandbox:self]
 */
- (void)saveToSandbox;

@end

NS_ASSUME_NONNULL_END
