//
//  WFTransferEngine.m
//  WatchFaceSDK-Pure-ObjC
//
//  纯 Objective-C 传输引擎实现
//

#import "WFTransferEngine.h"
#import <WatchProtocolSDK/WatchProtocolSDK.h>
// WPCommands.h 和 WPBluetoothManager.h 已被 WatchProtocolSDK.h umbrella header 包含，无需重复导入

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
    NSLog(@"⏱ 设置时间位置: %ld, 颜色: %ld", (long)position, (long)color);

    // 通过 WPCommands 发送设置指令
    // type: 0 = 自定义表盘设置
    [WPCommands setTimePositionAndColor:0
                               position:(NSInteger)position
                                  color:(NSInteger)color];
}

- (void)queryMTUAndStartTransfer {
    // 从 WPBluetoothManager 查询真实 MTU
    WPBluetoothManager *btManager = [WPBluetoothManager sharedInstance];
    WPBluetoothWatchDevice *device = btManager.currentDevice;

    NSInteger mtu = (device && device.mtu > 0) ? device.mtu : 240; // 默认 MTU 240

    // ✅ 修复：使用固定 200 字节分包大小（符合 XGZT 协议规范）
    // 与 Swift 版本保持一致
    self.packetSize = 200;

    NSLog(@"📡 设备 MTU: %ld, 包大小: %ld (固定)", (long)mtu, (long)self.packetSize);

    // 计算总包数
    self.totalPackets = (self.currentData.length + self.packetSize - 1) / self.packetSize;

    NSLog(@"📦 总包数: %ld, 文件大小: %ld bytes", (long)self.totalPackets, (long)self.currentData.length);

    // 发送传输配置
    [self sendTransferConfig:mtu];

    // 开始传输
    [self beginTransfer];
}

- (void)sendTransferConfig:(NSInteger)mtu {
    // 发送表盘传输配置
    NSInteger dialType = (self.dialType == WFDialTypeMarket) ? 0 : 1; // 0=市场表盘, 1=自定义表盘

    // ✅ 修复：使用正确的配置参数（与 Swift 版本保持一致）
    [WPCommands dialMarketSetTransferConfig:self.totalPackets
                                    binSize:self.currentData.length
                                        mtu:mtu
                                   dialType:dialType
                                    dialNum:1                                    // ✅ 修复：应该是 1
                                      local:(NSInteger)self.timePosition         // ✅ 修复：使用实际的时间位置
                                  typeValue:0                                    // ✅ 修复：应该是 0
                              dialTypeValue:(NSInteger)self.color];              // ✅ 修复：使用实际的颜色

    NSLog(@"📤 已发送传输配置: 总包数=%ld, 文件大小=%ld, MTU=%ld, 类型=%ld, 时间位置=%ld, 颜色=%ld",
          (long)self.totalPackets, (long)self.currentData.length, (long)mtu, (long)dialType,
          (long)self.timePosition, (long)self.color);
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

    // ✅ 修复：判断是否为最后一包
    BOOL isLastPacket = (self.currentPacketIndex >= self.totalPackets - 1);

    // ✅ 修复：计算字节偏移量（binNum）
    NSInteger binNum = self.currentPacketIndex * 200;  // 使用固定 200 字节

    // ✅ 修复：设置控制标志（最后一包为 1，其他为 0）
    NSInteger control = isLastPacket ? 1 : 0;

    // 计算进度（百分比）
    NSInteger progress = ((self.currentPacketIndex + 1) * 100) / self.totalPackets;

    NSLog(@"📤 发送包 %ld/%ld (偏移: %ld, 大小: %ld bytes, 进度: %ld%%, 控制: %ld)",
          (long)(self.currentPacketIndex + 1), (long)self.totalPackets, (long)binNum,
          (long)length, (long)progress, (long)control);

    // ✅ 修复：通过 WPCommands 发送数据包（与 Swift 版本保持一致）
    [WPCommands dialMarketTransferData:self.currentPacketIndex + 1  // 包序号从1开始
                                binNum:binNum                        // ✅ 修复：字节偏移量
                           progressBar:progress                      // 进度百分比
                               control:control                       // ✅ 修复：控制标志
                                  data:packetData];

    // 更新进度
    [self updateProgress];

    self.currentPacketIndex++;

    // 注意：真实传输依赖设备响应，这里简化处理
    // 收到 XGZTCommandDialDataSendCompleteCallback 通知后会自动发送下一包
}

- (void)updateProgress {
    // ✅ 优化：基于字节数计算进度（更精确，与 Swift 版本保持一致）
    NSInteger bytesTransferred = MIN(self.currentPacketIndex * 200 + 200, self.currentData.length);

    WFTransferProgress *progress = [[WFTransferProgress alloc] init];
    progress.currentPacket = self.currentPacketIndex + 1;
    progress.totalPackets = self.totalPackets;
    progress.bytesTransferred = bytesTransferred;  // ✅ 使用精确的字节数
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

@end
