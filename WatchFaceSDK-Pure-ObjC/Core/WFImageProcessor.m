//
//  WFImageProcessor.m
//  WatchFaceSDK-Pure-ObjC
//
//  纯 Objective-C 图片处理器实现
//

#import "WFImageProcessor.h"
#import <ABParTool/ABParTool.h>

@implementation WFImageProcessor

#pragma mark - Public Methods

+ (UIImage *)resizeImage:(UIImage *)image toSize:(CGSize)targetSize {
    if (!image) return nil;

    UIGraphicsBeginImageContextWithOptions(targetSize, NO, 1.0);
    [image drawInRect:CGRectMake(0, 0, targetSize.width, targetSize.height)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return resizedImage;
}

+ (NSData *)imageToRawData:(UIImage *)image {
    if (!image) return nil;

    CGImageRef imageRef = image.CGImage;
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);

    // 创建 RGB 颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    // 分配内存用于存储像素数据
    NSUInteger bytesPerPixel = 4; // RGBA
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;

    unsigned char *rawData = (unsigned char *)calloc(height * width * bytesPerPixel, sizeof(unsigned char));

    if (!rawData) {
        CGColorSpaceRelease(colorSpace);
        return nil;
    }

    // 创建上下文
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);

    CGColorSpaceRelease(colorSpace);

    if (!context) {
        free(rawData);
        return nil;
    }

    // 绘制图片到上下文
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);

    // 转换为 RGB565 格式
    NSUInteger rgb565Size = width * height * 2; // 2 bytes per pixel
    unsigned char *rgb565Data = (unsigned char *)malloc(rgb565Size);

    if (!rgb565Data) {
        free(rawData);
        return nil;
    }

    for (NSUInteger i = 0; i < width * height; i++) {
        unsigned char r = rawData[i * 4];
        unsigned char g = rawData[i * 4 + 1];
        unsigned char b = rawData[i * 4 + 2];

        // 转换为 RGB565
        unsigned short rgb565 = ((r & 0xF8) << 8) | ((g & 0xFC) << 3) | (b >> 3);

        // 大端序
        rgb565Data[i * 2] = (rgb565 >> 8) & 0xFF;
        rgb565Data[i * 2 + 1] = rgb565 & 0xFF;
    }

    NSData *resultData = [NSData dataWithBytes:rgb565Data length:rgb565Size];

    free(rawData);
    free(rgb565Data);

    return resultData;
}

+ (NSData *)convertToPAR:(UIImage *)image
             targetSize:(CGSize)targetSize
            maxFileSize:(NSInteger)maxFileSize
                  error:(NSError **)error {

    if (!image) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.bruce.WatchFaceSDK"
                                         code:1001
                                     userInfo:@{NSLocalizedDescriptionKey: @"图片为空"}];
        }
        return nil;
    }

    NSLog(@"🔄 开始转换图片为 PAR 格式 - 目标尺寸: %.0fx%.0f", targetSize.width, targetSize.height);

    // 1. 调整图片尺寸
    UIImage *resizedImage = [self resizeImage:image toSize:targetSize];
    if (!resizedImage) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.bruce.WatchFaceSDK"
                                         code:1002
                                     userInfo:@{NSLocalizedDescriptionKey: @"图片尺寸调整失败"}];
        }
        return nil;
    }

    // 2. 循环压缩直到满足大小要求
    UIImage *currentImage = resizedImage;
    NSInteger attemptCount = 0;
    NSInteger maxAttempts = 10;

    while (attemptCount < maxAttempts) {
        // 获取原始 RGB 数据
        NSData *rawImageData = [self imageToRawData:currentImage];
        if (!rawImageData) {
            if (error) {
                *error = [NSError errorWithDomain:@"com.bruce.WatchFaceSDK"
                                             code:1003
                                         userInfo:@{NSLocalizedDescriptionKey: @"无法获取图片原始数据"}];
            }
            return nil;
        }

        NSLog(@"📊 尝试 %ld: 原始数据大小 = %ld bytes", (long)(attemptCount + 1), (long)rawImageData.length);

        // 转换为 PAR 格式（调用 ABParTool）
        NSData *parData = [ParTool parFromRaw:rawImageData
                                        width:(int32_t)targetSize.width
                                       height:(int32_t)targetSize.height
                                     runAlpha:NO
                                    useFilter:NO
                               supportRotate:NO];

        if (parData) {
            NSLog(@"📦 PAR 数据大小: %ld bytes (限制: %ld bytes)", (long)parData.length, (long)maxFileSize);

            if (parData.length <= maxFileSize) {
                NSLog(@"✅ PAR 转换成功: %ld bytes", (long)parData.length);
                return parData;
            }

            NSLog(@"⚠️ PAR 文件过大，继续压缩...");

            // 继续压缩
            CGFloat quality = MAX(0.1, 0.9 - (CGFloat)attemptCount * 0.1);
            NSData *compressedData = UIImageJPEGRepresentation(currentImage, quality);
            if (!compressedData) {
                if (error) {
                    *error = [NSError errorWithDomain:@"com.bruce.WatchFaceSDK"
                                                 code:1004
                                             userInfo:@{NSLocalizedDescriptionKey: @"JPEG 压缩失败"}];
                }
                return nil;
            }

            UIImage *compressedImage = [UIImage imageWithData:compressedData];
            if (!compressedImage) {
                if (error) {
                    *error = [NSError errorWithDomain:@"com.bruce.WatchFaceSDK"
                                                 code:1005
                                             userInfo:@{NSLocalizedDescriptionKey: @"压缩图片创建失败"}];
                }
                return nil;
            }

            currentImage = compressedImage;
            NSLog(@"🔄 图片已压缩，质量系数: %.2f", quality);

        } else {
            if (error) {
                *error = [NSError errorWithDomain:@"com.bruce.WatchFaceSDK"
                                             code:1006
                                         userInfo:@{NSLocalizedDescriptionKey: @"PAR 转换失败"}];
            }
            return nil;
        }

        attemptCount++;
    }

    // 超过最大尝试次数
    if (error) {
        *error = [NSError errorWithDomain:@"com.bruce.WatchFaceSDK"
                                     code:1007
                                 userInfo:@{NSLocalizedDescriptionKey: @"无法将图片压缩到指定大小"}];
    }
    return nil;
}

+ (BOOL)validateImage:(UIImage *)image message:(NSString **)message {
    if (!image) {
        if (message) *message = @"图片为空";
        return NO;
    }

    if (image.size.width < 10 || image.size.height < 10) {
        if (message) *message = @"图片尺寸太小";
        return NO;
    }

    if (image.size.width > 10000 || image.size.height > 10000) {
        if (message) *message = @"图片尺寸太大";
        return NO;
    }

    return YES;
}

@end
