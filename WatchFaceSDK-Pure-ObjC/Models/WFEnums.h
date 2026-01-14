//
//  WFEnums.h
//  WatchFaceSDK-ObjC
//
//  Created by Claude on 2026-01-13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 屏幕形状
typedef NS_ENUM(NSInteger, WFScreenShape) {
    WFScreenShapeRound = 0,   // 圆形
    WFScreenShapeSquare = 1   // 方形
};

/// 表盘类型
typedef NS_ENUM(NSInteger, WFDialType) {
    WFDialTypeMarket = 0,     // 市场表盘
    WFDialTypeCustom = 1      // 自定义表盘
};

/// 时间位置
typedef NS_ENUM(NSInteger, WFTimePosition) {
    WFTimePositionNone = 0,         // 无
    WFTimePositionTopLeft = 1,      // 左上
    WFTimePositionBottomLeft = 2,   // 左下
    WFTimePositionTopRight = 3,     // 右上
    WFTimePositionBottomRight = 4,  // 右下
    WFTimePositionCenter = 5        // 居中
};

/// 表盘颜色
typedef NS_ENUM(NSInteger, WFDialColor) {
    WFDialColorWhite = 0,
    WFDialColorBlack = 1,
    WFDialColorYellow = 2,
    WFDialColorOrange = 3,
    WFDialColorPink = 4,
    WFDialColorPurple = 5,
    WFDialColorBlue = 6,
    WFDialColorCyan = 7,
    WFDialColorGreen = 8
};

/// 表盘错误
typedef NS_ENUM(NSInteger, WFErrorCode) {
    WFErrorCodeDeviceNotConnected = 1000,       // 设备未连接
    WFErrorCodeDeviceNotSupported = 1001,       // 设备不支持
    WFErrorCodeImageProcessFailed = 1002,       // 图片处理失败
    WFErrorCodeRawDataConversionFailed = 1003,  // 原始数据转换失败
    WFErrorCodeCompressionFailed = 1004,        // 压缩失败
    WFErrorCodeExceedMaxAttempts = 1005,        // 超过最大尝试次数
    WFErrorCodeExceedMaxFileSize = 1006,        // 超过最大文件大小
    WFErrorCodeTransferFailed = 1007,           // 传输失败
    WFErrorCodeNetworkError = 1008,             // 网络错误
    WFErrorCodeCacheError = 1009,               // 缓存错误
    WFErrorCodeInvalidMTU = 1010,               // 无效的MTU
    WFErrorCodeInvalidConfiguration = 1011,     // 无效的配置
    WFErrorCodeInvalidData = 1012,              // 无效的数据
    WFErrorCodeInvalidImage = 1013              // 无效的图片
};

NS_ASSUME_NONNULL_END
