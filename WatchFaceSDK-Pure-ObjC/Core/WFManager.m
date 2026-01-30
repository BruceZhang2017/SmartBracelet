//
//  WFManager.m
//  WatchFaceSDK-Pure-ObjC
//
//  表盘管理器实现 - 纯 Objective-C
//

#import "WFManager.h"
#import "WFImageProcessor.h"
#import "WFTransferEngine.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import <WatchProtocolSDK/WatchProtocolSDK.h>
// WPBluetoothManager.h 已被 WatchProtocolSDK.h umbrella header 包含，无需重复导入

@interface WFManager ()

@property (nonatomic, strong) WFTransferEngine *transferEngine;

@end

@implementation WFManager

#pragma mark - Singleton

+ (instancetype)sharedInstance {
    static WFManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[WFManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _transferEngine = [[WFTransferEngine alloc] init];
        NSLog(@"🎨 WatchFaceSDK-Pure-ObjC 初始化完成");
    }
    return self;
}

#pragma mark - 设备信息查询

- (WFDeviceScreenInfo *)getCurrentDeviceScreenInfo {
    // 从 WPBluetoothManager 获取设备信息
    WPBluetoothManager *btManager = [WPBluetoothManager sharedInstance];
    WPBluetoothWatchDevice *device = btManager.currentDevice;

    if (!device) {
        NSLog(@"⚠️ 设备未连接，返回默认屏幕信息");
        // 返回默认值
        WFDeviceScreenInfo *info = [[WFDeviceScreenInfo alloc] init];
        info.width = 240;
        info.height = 240;
        info.shape = WFScreenShapeRound;
        info.mtu = 240;
        return info;
    }

    // 从设备信息构建屏幕信息
    WFDeviceScreenInfo *info = [[WFDeviceScreenInfo alloc] init];
    info.width = device.screenWidth > 0 ? device.screenWidth : 240;
    info.height = device.screenHeight > 0 ? device.screenHeight : 240;
    // 根据 screenType 判断形状：1=方形, 2=圆形
    info.shape = (device.screenType == 1) ? WFScreenShapeSquare : WFScreenShapeRound;
    info.mtu = device.mtu > 0 ? device.mtu : 240;

    NSLog(@"📱 设备屏幕信息: %ldx%ld, 形状: %ld, MTU: %ld",
          (long)info.width, (long)info.height, (long)info.shape, (long)info.mtu);

    return info;
}

- (BOOL)isDeviceConnected {
    // 从 WPBluetoothManager 获取连接状态
    // currentDevice 不为 nil 表示有设备已连接
    WPBluetoothManager *btManager = [WPBluetoothManager sharedInstance];
    BOOL isConnected = (btManager.currentDevice != nil);

    NSLog(@"🔗 设备连接状态: %@", isConnected ? @"已连接" : @"未连接");

    return isConnected;
}

- (CGSize)getRecommendedImageSize {
    WFDeviceScreenInfo *info = [self getCurrentDeviceScreenInfo];

    if (!info) {
        return CGSizeZero;
    }

    return [info cgSize];
}

#pragma mark - 上传市场表盘

- (BOOL)uploadMarketWatchFaceWithData:(NSData *)data
                             delegate:(id<WFTransferDelegate>)delegate
                                error:(NSError **)error {

    if (![self isDeviceConnected]) {
        if (error) {
            *error = [self errorWithCode:WFErrorCodeDeviceNotConnected
                              description:@"设备未连接"];
        }
        return NO;
    }

    if (data.length == 0) {
        if (error) {
            *error = [self errorWithCode:WFErrorCodeInvalidData
                              description:@"数据为空"];
        }
        return NO;
    }

    NSLog(@"📤 开始上传市场表盘 - 大小: %ld bytes", (long)data.length);

    [self.transferEngine startTransferWithData:data
                                      dialType:WFDialTypeMarket
                                  timePosition:WFTimePositionNone
                                         color:WFDialColorWhite
                                      delegate:delegate];

    return YES;
}

- (BOOL)uploadMarketWatchFaceWithFileURL:(NSURL *)fileURL
                                delegate:(id<WFTransferDelegate>)delegate
                                   error:(NSError **)error {

    if (![self isDeviceConnected]) {
        if (error) {
            *error = [self errorWithCode:WFErrorCodeDeviceNotConnected
                              description:@"设备未连接"];
        }
        return NO;
    }

    NSError *readError = nil;
    NSData *data = [NSData dataWithContentsOfURL:fileURL options:0 error:&readError];

    if (!data || readError) {
        if (error) {
            *error = readError ?: [self errorWithCode:WFErrorCodeInvalidData
                                          description:@"无法读取文件"];
        }
        return NO;
    }

    return [self uploadMarketWatchFaceWithData:data delegate:delegate error:error];
}

#pragma mark - 上传自定义表盘

- (BOOL)uploadCustomWatchFaceWithImage:(UIImage *)image
                          timePosition:(WFTimePosition)timePosition
                                 color:(WFDialColor)color
                              delegate:(id<WFTransferDelegate>)delegate
                                 error:(NSError **)error {

    if (![self isDeviceConnected]) {
        if (error) {
            *error = [self errorWithCode:WFErrorCodeDeviceNotConnected
                              description:@"设备未连接"];
        }
        return NO;
    }

    // 获取设备屏幕信息
    WFDeviceScreenInfo *screenInfo = [self getCurrentDeviceScreenInfo];
    if (!screenInfo) {
        if (error) {
            *error = [self errorWithCode:WFErrorCodeDeviceNotConnected
                              description:@"无法获取设备屏幕信息"];
        }
        return NO;
    }

    // 验证图片
    NSString *validationMessage = nil;
    if (![self validateImage:image message:&validationMessage]) {
        if (error) {
            *error = [self errorWithCode:WFErrorCodeInvalidImage
                              description:validationMessage ?: @"图片无效"];
        }
        return NO;
    }

    CGSize targetSize = [screenInfo cgSize];
    NSLog(@"🖼 处理自定义表盘 - 目标尺寸: %.0fx%.0f", targetSize.width, targetSize.height);

    // 转换为 PAR 格式
    NSError *convertError = nil;
    NSData *parData = [WFImageProcessor convertToPAR:image
                                          targetSize:targetSize
                                         maxFileSize:120 * 1024
                                               error:&convertError];

    if (!parData || convertError) {
        if (error) {
            *error = convertError ?: [self errorWithCode:WFErrorCodeImageProcessFailed
                                              description:@"图片处理失败"];
        }
        return NO;
    }

    NSLog(@"📤 开始上传自定义表盘 - PAR 大小: %ld bytes", (long)parData.length);

    [self.transferEngine startTransferWithData:parData
                                      dialType:WFDialTypeCustom
                                  timePosition:timePosition
                                         color:color
                                      delegate:delegate];

    return YES;
}

#pragma mark - 图片验证

- (BOOL)validateImage:(UIImage *)image message:(NSString **)message {
    return [WFImageProcessor validateImage:image message:message];
}

#pragma mark - 传输控制

- (void)pauseTransfer {
    [self.transferEngine pauseTransfer];
}

- (void)cancelTransfer {
    [self.transferEngine cancelTransfer];
}

- (void)retryTransfer {
    [self.transferEngine retryTransfer];
}

#pragma mark - Error Helper

- (NSError *)errorWithCode:(WFErrorCode)code description:(NSString *)description {
    return [NSError errorWithDomain:@"com.anker.WatchFaceSDK"
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: description}];
}

@end
