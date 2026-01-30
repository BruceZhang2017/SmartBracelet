//
//  WatchFaceSDK.h
//  WatchFaceSDK-Pure-ObjC
//
//  Umbrella header for WatchFaceSDK framework
//

#import <Foundation/Foundation.h>

//! Project version number for WatchFaceSDK.
FOUNDATION_EXPORT double WatchFaceSDKVersionNumber;

//! Project version string for WatchFaceSDK.
FOUNDATION_EXPORT const unsigned char WatchFaceSDKVersionString[];

// MARK: - 枚举与常量
#if __has_include(<WatchFaceSDK/WFEnums.h>)
    #import <WatchFaceSDK/WFEnums.h>
#else
    #import "WFEnums.h"
#endif

// MARK: - 数据模型
#if __has_include(<WatchFaceSDK/WFDeviceScreenInfo.h>)
    #import <WatchFaceSDK/WFDeviceScreenInfo.h>
    #import <WatchFaceSDK/WFTransferProgress.h>
#else
    #import "WFDeviceScreenInfo.h"
    #import "WFTransferProgress.h"
#endif

// MARK: - 协议
#if __has_include(<WatchFaceSDK/WFTransferDelegate.h>)
    #import <WatchFaceSDK/WFTransferDelegate.h>
#else
    #import "WFTransferDelegate.h"
#endif

// MARK: - 核心管理类
#if __has_include(<WatchFaceSDK/WFManager.h>)
    #import <WatchFaceSDK/WFManager.h>
    #import <WatchFaceSDK/WFTransferEngine.h>
    #import <WatchFaceSDK/WFImageProcessor.h>
#else
    #import "WFManager.h"
    #import "WFTransferEngine.h"
    #import "WFImageProcessor.h"
#endif
