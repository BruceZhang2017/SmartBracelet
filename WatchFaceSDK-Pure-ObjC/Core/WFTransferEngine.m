//
//  WFTransferEngine.m
//  WatchFaceSDK-Pure-ObjC
//
//  纯 Objective-C 传输引擎实现
//

#import "WFTransferEngine.h"
// TODO: Import proper WatchProtocolSDK classes when available
// #import <WatchProtocolSDK/WatchProtocolSDK.h>

typedef NS_ENUM(NSInteger, WFTransferState) {
    WFTransferStateIdle,
    WFTransferStatePreparing,
    WFTransferStateTransferring,
    WFTransferStatePaused,
    WFTransferStateCompleted,
    WFTransferStateFailed,
    WFTransferStateCancelled
};

@interface WFTransferEngine ()

@property (nonatomic, strong, nullable) NSData *currentData;
@property (nonatomic, assign) NSInteger currentPacketIndex;
@property (nonatomic, assign) NSInteger totalPackets;
@property (nonatomic, assign) NSInteger packetSize;
@property (nonatomic, assign) WFTransferState transferState;
@property (nonatomic, weak, nullable) id<WFTransferDelegate> delegate;

// 缓存的传输参数
@property (nonatomic, assign) WFDialType dialType;
@property (nonatomic, assign) WFTimePosition timePosition;
@property (nonatomic, assign) WFDialColor color;

@end

@implementation WFTransferEngine

#pragma mark - Lifecycle

- (instancetype)init {
    self = [super init];
    if (self) {
        _transferState = WFTransferStateIdle;
        _currentPacketIndex = 0;
        _totalPackets = 0;
        _packetSize = 0;

        // 注册通知
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleDialDataSendComplete:)
                                                     name:@"XGZTCommandDialDataSendCompleteCallback"
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public Methods

- (void)startTransferWithData:(NSData *)data
                     dialType:(WFDialType)dialType
                 timePosition:(WFTimePosition)timePosition
                        color:(WFDialColor)color
                     delegate:(id<WFTransferDelegate>)delegate {

    if (self.transferState != WFTransferStateIdle) {
        NSLog(@"⚠️ 传输正在进行中，无法开始新的传输");
        return;
    }

    self.delegate = delegate;
    self.currentData = data;
    self.dialType = dialType;
    self.timePosition = timePosition;
    self.color = color;
    self.currentPacketIndex = 0;
    self.transferState = WFTransferStatePreparing;

    NSLog(@"🚀 开始传输表盘 - 类型: %ld, 数据大小: %ld bytes", (long)dialType, (long)data.length);

    // 如果是自定义表盘，先设置时间位置和颜色
    if (dialType == WFDialTypeCustom) {
        NSLog(@"🎨 设置自定义表盘时间位置和颜色: %ld, %ld", (long)timePosition, (long)color);
        [self setTimePositionAndColor:timePosition color:color];
    }

    // 查询 MTU 并开始传输
    [self queryMTUAndStartTransfer];
}

- (void)pauseTransfer {
    NSLog(@"⏸ 暂停传输");
    self.transferState = WFTransferStatePaused;
}

- (void)cancelTransfer {
    NSLog(@"❌ 取消传输");
    self.transferState = WFTransferStateCancelled;
    self.currentData = nil;
    self.currentPacketIndex = 0;

    if ([self.delegate respondsToSelector:@selector(transferDidCancel)]) {
        [self.delegate transferDidCancel];
    }
}

- (void)retryTransfer {
    if (!self.currentData) {
        NSLog(@"⚠️ 没有可重试的传输");
        return;
    }

    NSLog(@"🔄 重试传输");
    [self startTransferWithData:self.currentData
                       dialType:self.dialType
                   timePosition:self.timePosition
                          color:self.color
                       delegate:self.delegate];
}

- (BOOL)isTransferring {
    return self.transferState == WFTransferStateTransferring ||
           self.transferState == WFTransferStatePreparing;
}

#pragma mark - Private Methods

- (void)setTimePositionAndColor:(WFTimePosition)position color:(WFDialColor)color {
    // TODO: Implement with proper WatchProtocolSDK integration
    NSLog(@"⏱ 设置时间位置: %ld, 颜色: %ld", (long)position, (long)color);
}

- (void)queryMTUAndStartTransfer {
    // TODO: Query actual MTU from WatchProtocolSDK
    NSInteger mtu = 240; // 默认 MTU

    // 计算包大小（MTU - 协议头）
    self.packetSize = mtu - 20;

    NSLog(@"📡 设备 MTU: %ld, 包大小: %ld", (long)mtu, (long)self.packetSize);

    // 计算总包数
    self.totalPackets = (self.currentData.length + self.packetSize - 1) / self.packetSize;

    NSLog(@"📦 总包数: %ld", (long)self.totalPackets);

    // 开始传输
    [self beginTransfer];
}

- (void)beginTransfer {
    self.transferState = WFTransferStateTransferring;

    if ([self.delegate respondsToSelector:@selector(transferDidStart)]) {
        [self.delegate transferDidStart];
    }

    // 发送第一包
    [self sendNextPacket];
}

- (void)sendNextPacket {
    if (self.transferState != WFTransferStateTransferring) {
        return;
    }

    if (self.currentPacketIndex >= self.totalPackets) {
        // 传输完成
        [self handleTransferComplete];
        return;
    }

    // 计算当前包的范围
    NSInteger offset = self.currentPacketIndex * self.packetSize;
    NSInteger length = MIN(self.packetSize, self.currentData.length - offset);

    NSData *packetData = [self.currentData subdataWithRange:NSMakeRange(offset, length)];

    NSLog(@"📤 发送包 %ld/%ld (大小: %ld bytes)", (long)(self.currentPacketIndex + 1), (long)self.totalPackets, (long)length);

    // TODO: Send data packet via WatchProtocolSDK
    // For now, simulate successful send by posting notification
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"XGZTCommandDialDataSendCompleteCallback" object:nil];
    });

    // 更新进度
    [self updateProgress];

    self.currentPacketIndex++;
}

- (void)updateProgress {
    WFTransferProgress *progress = [[WFTransferProgress alloc] init];
    progress.currentPacket = self.currentPacketIndex + 1;
    progress.totalPackets = self.totalPackets;
    progress.bytesTransferred = MIN((self.currentPacketIndex + 1) * self.packetSize, self.currentData.length);
    progress.totalBytes = self.currentData.length;

    if ([self.delegate respondsToSelector:@selector(transferDidUpdateProgress:)]) {
        [self.delegate transferDidUpdateProgress:progress];
    }
}

- (void)handleTransferComplete {
    NSLog(@"✅ 传输完成");
    self.transferState = WFTransferStateCompleted;
    self.currentData = nil;
    self.currentPacketIndex = 0;

    if ([self.delegate respondsToSelector:@selector(transferDidComplete)]) {
        [self.delegate transferDidComplete];
    }
}

- (void)handleTransferError:(NSError *)error {
    NSLog(@"❌ 传输失败: %@", error.localizedDescription);
    self.transferState = WFTransferStateFailed;

    if ([self.delegate respondsToSelector:@selector(transferDidFailWithError:)]) {
        [self.delegate transferDidFailWithError:error];
    }
}

#pragma mark - Notifications

- (void)handleDialDataSendComplete:(NSNotification *)notification {
    // 一包数据发送完成，发送下一包
    [self sendNextPacket];
}

// TODO: Add type conversion methods when integrating with WatchProtocolSDK

@end
