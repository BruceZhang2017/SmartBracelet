//
//  WFTransferDelegate.h
//  WatchFaceSDK-ObjC
//
//  Created by Claude on 2026-01-13.
//

#import <Foundation/Foundation.h>

@class WFTransferProgress;

NS_ASSUME_NONNULL_BEGIN

/// 传输代理协议
@protocol WFTransferDelegate <NSObject>

@required

/// 开始传输
- (void)transferDidStart;

/// 传输进度更新
/// @param progress 进度对象
- (void)transferDidUpdateProgress:(WFTransferProgress *)progress;

/// 传输成功
- (void)transferDidComplete;

/// 传输失败
/// @param error 错误信息
- (void)transferDidFailWithError:(NSError *)error;

@optional

/// 传输取消
- (void)transferDidCancel;

@end

NS_ASSUME_NONNULL_END
