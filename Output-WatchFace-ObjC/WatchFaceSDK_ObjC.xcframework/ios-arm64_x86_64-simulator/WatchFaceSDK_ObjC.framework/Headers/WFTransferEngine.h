//
//  WFTransferEngine.h
//  WatchFaceSDK-Pure-ObjC
//
//  纯 Objective-C 传输引擎
//

#import <Foundation/Foundation.h>
#import "WFTransferProgress.h"
#import "WFTransferDelegate.h"
#import "WFEnums.h"

NS_ASSUME_NONNULL_BEGIN

/// 表盘传输引擎（纯 Objective-C 实现）
@interface WFTransferEngine : NSObject

/// 开始传输
/// @param data 要传输的数据
/// @param dialType 表盘类型
/// @param timePosition 时间位置（仅自定义表盘）
/// @param color 颜色（仅自定义表盘）
/// @param delegate 传输代理
- (void)startTransferWithData:(NSData *)data
                     dialType:(WFDialType)dialType
                 timePosition:(WFTimePosition)timePosition
                        color:(WFDialColor)color
                     delegate:(nullable id<WFTransferDelegate>)delegate;

/// 暂停传输
- (void)pauseTransfer;

/// 取消传输
- (void)cancelTransfer;

/// 重试传输
- (void)retryTransfer;

/// 是否正在传输
@property (nonatomic, readonly) BOOL isTransferring;

@end

NS_ASSUME_NONNULL_END
