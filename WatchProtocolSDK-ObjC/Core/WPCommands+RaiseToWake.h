//
//  WPCommands+RaiseToWake.h
//  WatchProtocolSDK-ObjC
//
//  Created by Claude on 2026/01/28.
//  Copyright © 2026 Huaxin. All rights reserved.
//

#import "WPCommands.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * WPCommands+RaiseToWake - 抬手亮屏功能扩展
 *
 * 🎯 功能：控制手表的抬手亮屏功能
 * 📡 协议：使用开关状态指令（0x80）控制
 */
@interface WPCommands (RaiseToWake)

/**
 * 设置抬手亮屏开关
 * @param enable YES = 开启抬手亮屏，NO = 关闭抬手亮屏
 * @param completion 完成回调（success: 是否发送成功, error: 错误信息）
 *
 * @discussion 开启后，抬起手腕时手表屏幕会自动点亮
 * @note 需要设备已连接且蓝牙已开启
 * @note 参考 Swift 实现：DeviceSettingsViewController.swift:436-448
 *
 * @implementation 完整实现：
 * 1. 更新设备模型中的 isRaiseHandToBrightenScreen 属性
 * 2. 读取设备模型的所有开关状态
 * 3. 组合所有开关位到 p0 和 p1 字节
 * 4. 发送完整的开关状态，保护其他开关不受影响
 */
+ (void)setRaiseToWake:(BOOL)enable completion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion;

/**
 * 获取抬手亮屏状态
 * @param completion 完成回调
 *
 * @discussion 发送查询指令，设备响应通过 WPBluetoothManagerDelegate 回调
 * @note 响应数据通过 handleResponse 方法解析
 */
+ (void)getRaiseToWakeStatus:(nullable void(^)(BOOL success, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
