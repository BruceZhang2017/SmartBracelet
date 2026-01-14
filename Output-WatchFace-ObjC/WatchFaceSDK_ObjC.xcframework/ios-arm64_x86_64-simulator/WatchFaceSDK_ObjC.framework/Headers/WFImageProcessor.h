//
//  WFImageProcessor.h
//  WatchFaceSDK-Pure-ObjC
//
//  纯 Objective-C 图片处理器
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 图片处理器（纯 Objective-C 实现）
@interface WFImageProcessor : NSObject

/// 调整图片尺寸
/// @param image 原始图片
/// @param targetSize 目标尺寸
/// @return 调整后的图片，失败返回 nil
+ (nullable UIImage *)resizeImage:(UIImage *)image toSize:(CGSize)targetSize;

/// 将图片转换为 RGB 原始数据
/// @param image 图片
/// @return RGB 原始数据，格式为 RGB565
+ (nullable NSData *)imageToRawData:(UIImage *)image;

/// 压缩并转换图片为 PAR 格式
/// @param image 原始图片
/// @param targetSize 目标尺寸
/// @param maxFileSize 最大文件大小（字节），默认 120KB
/// @param error 错误信息
/// @return PAR 格式数据
+ (nullable NSData *)convertToPAR:(UIImage *)image
                       targetSize:(CGSize)targetSize
                      maxFileSize:(NSInteger)maxFileSize
                            error:(NSError **)error;

/// 验证图片是否符合要求
/// @param image 图片
/// @param message 错误消息（输出参数）
/// @return 是否有效
+ (BOOL)validateImage:(UIImage *)image message:(NSString **)message;

@end

NS_ASSUME_NONNULL_END
