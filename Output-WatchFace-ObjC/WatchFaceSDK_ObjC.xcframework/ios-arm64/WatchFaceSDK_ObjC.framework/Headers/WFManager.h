//
//  WFManager.h
//  WatchFaceSDK-Pure-ObjC
//
//  表盘管理器 - 纯 Objective-C 实现
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "WFEnums.h"
#import "WFDeviceScreenInfo.h"
#import "WFTransferDelegate.h"

NS_ASSUME_NONNULL_BEGIN

/// 表盘管理器（纯 Objective-C，SDK 主入口）
@interface WFManager : NSObject

#pragma mark - 单例

/// 获取单例实例
+ (instancetype)sharedInstance;

#pragma mark - 设备信息查询

/// 获取当前设备屏幕信息
/// @return 设备屏幕信息，如果设备未连接则返回 nil
- (nullable WFDeviceScreenInfo *)getCurrentDeviceScreenInfo;

/// 检查设备是否连接
/// @return 是否连接
- (BOOL)isDeviceConnected;

/// 获取推荐的图片尺寸
/// @return 推荐尺寸，如果设备未连接则返回 CGSizeZero
- (CGSize)getRecommendedImageSize;

#pragma mark - 上传市场表盘

/// 上传市场表盘到设备（从 NSData）
/// @param data 表盘文件数据
/// @param delegate 传输进度代理
/// @param error 错误信息
/// @return 是否成功开始传输
- (BOOL)uploadMarketWatchFaceWithData:(NSData *)data
                             delegate:(nullable id<WFTransferDelegate>)delegate
                                error:(NSError **)error;

/// 上传市场表盘到设备（从文件 URL）
/// @param fileURL 表盘文件路径
/// @param delegate 传输进度代理
/// @param error 错误信息
/// @return 是否成功开始传输
- (BOOL)uploadMarketWatchFaceWithFileURL:(NSURL *)fileURL
                                delegate:(nullable id<WFTransferDelegate>)delegate
                                   error:(NSError **)error;

#pragma mark - 上传自定义表盘

/// 上传自定义表盘到设备
/// @param image 原始图片
/// @param timePosition 时间位置
/// @param color 颜色
/// @param delegate 传输进度代理
/// @param error 错误信息
/// @return 是否成功开始传输
- (BOOL)uploadCustomWatchFaceWithImage:(UIImage *)image
                          timePosition:(WFTimePosition)timePosition
                                 color:(WFDialColor)color
                              delegate:(nullable id<WFTransferDelegate>)delegate
                                 error:(NSError **)error;

#pragma mark - 图片验证

/// 验证图片是否符合要求
/// @param image 图片
/// @param message 错误消息（输出参数）
/// @return 是否有效
- (BOOL)validateImage:(UIImage *)image message:(NSString **)message;

#pragma mark - 传输控制

/// 暂停传输
- (void)pauseTransfer;

/// 取消传输
- (void)cancelTransfer;

/// 重试传输
- (void)retryTransfer;

@end

NS_ASSUME_NONNULL_END
