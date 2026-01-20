//
//  WatchProtocolSDK.h
//  WatchProtocolSDK-ObjC
//
//  Created by Claude on 2026/01/12.
//  Copyright © 2026 Huaxin. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for WatchProtocolSDK.
FOUNDATION_EXPORT double WatchProtocolSDKVersionNumber;

//! Project version string for WatchProtocolSDK.
FOUNDATION_EXPORT const unsigned char WatchProtocolSDKVersionString[];

// MARK: - 数据模型
// 支持两种导入方式：framework 方式和静态库方式
#if __has_include(<WatchProtocolSDK/WPHealthDataModels.h>)
    #import <WatchProtocolSDK/WPHealthDataModels.h>
    #import <WatchProtocolSDK/WPDeviceModel.h>
#else
    #import "WPHealthDataModels.h"
    #import "WPDeviceModel.h"
#endif

// MARK: - 协议
#if __has_include(<WatchProtocolSDK/WPHealthDataStorage.h>)
    #import <WatchProtocolSDK/WPHealthDataStorage.h>
#else
    #import "WPHealthDataStorage.h"
#endif

// MARK: - 核心管理类
#if __has_include(<WatchProtocolSDK/WPDeviceManager.h>)
    #import <WatchProtocolSDK/WPDeviceManager.h>
    #import <WatchProtocolSDK/WPBluetoothManager.h>
    #import <WatchProtocolSDK/WPCommands.h>
#else
    #import "WPDeviceManager.h"
    #import "WPBluetoothManager.h"
    #import "WPCommands.h"
#endif

// MARK: - 工具类
#if __has_include(<WatchProtocolSDK/WPLogger.h>)
    #import <WatchProtocolSDK/WPLogger.h>
#else
    #import "WPLogger.h"
#endif
