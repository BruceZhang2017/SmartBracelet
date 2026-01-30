//
//  WFTransferProgress.h
//  WatchFaceSDK-ObjC
//
//  Created by Claude on 2026-01-13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 传输进度
@interface WFTransferProgress : NSObject

@property (nonatomic, assign) NSInteger currentPacket;      // 当前包序号
@property (nonatomic, assign) NSInteger totalPackets;       // 总包数
@property (nonatomic, assign) NSInteger bytesTransferred;   // 已传输字节数
@property (nonatomic, assign) NSInteger totalBytes;         // 总字节数
@property (nonatomic, assign, readonly) float percentage;   // 百分比 (0.0-1.0)
@property (nonatomic, copy) NSString *message;              // 进度消息

- (instancetype)initWithCurrentPacket:(NSInteger)currentPacket
                         totalPackets:(NSInteger)totalPackets
                     bytesTransferred:(NSInteger)bytesTransferred
                           totalBytes:(NSInteger)totalBytes;

@end

NS_ASSUME_NONNULL_END
