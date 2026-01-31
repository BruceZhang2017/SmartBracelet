//
//  WPBluetoothManager.m
//  WatchProtocolSDK-ObjC
//
//  Created by Claude on 2026/01/12.
//  Copyright © 2026 Huaxin. All rights reserved.
//

#import "WPBluetoothManager.h"
#import "WPDeviceModel.h"
#import "WPLogger.h"
#import "WPCommands.h"
#import "WPCommands+FindDevice.h"
#import "WPCommands+RaiseToWake.h"
#import "WPCommands+Alarm.h"
#import "WPCommands+Reminder.h"
#import "NSData+HexString.h"

// MARK: - 外设信息实现
@implementation WPPeripheralInfo

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral macAddress:(NSString *)macAddress {
    self = [super init];
    if (self) {
        _peripheral = peripheral;
        _macAddress = macAddress;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[WPPeripheralInfo class]]) {
        return NO;
    }
    WPPeripheralInfo *other = (WPPeripheralInfo *)object;
    return [self.peripheral isEqual:other.peripheral] && [self.macAddress isEqualToString:other.macAddress];
}

- (NSUInteger)hash {
    return self.peripheral.hash ^ self.macAddress.hash;
}

@end

// MARK: - 蓝牙管理器实现
@interface WPBluetoothManager () <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) CBCharacteristic *characteristic;
@property (nonatomic, strong) CBCharacteristic *dataInCharacteristic;
@property (nonatomic, strong) CBCharacteristic *dataOutCharacteristic;
@property (nonatomic, strong) CBCharacteristic *notifyCharacteristic;

@property (nonatomic, strong) NSMutableArray<WPPeripheralInfo *> *mutableDiscoveredPeripherals;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *brands;

@property (nonatomic, assign) BOOL isScanning;
@property (nonatomic, assign) BOOL isOTAing;
@property (nonatomic, assign) BOOL autoDisconnect;
@property (nonatomic, assign) BOOL isReconnectingNow;

// 🆕 v2.0.3: 重连保护标志，防止死循环
@property (nonatomic, assign) BOOL isReconnecting;  // 正在重连中
@property (nonatomic, assign) NSInteger reconnectAttempts;  // 重连尝试次数
@property (nonatomic, assign) NSInteger maxReconnectAttempts;  // 最大重连次数

@property (nonatomic, strong) NSMutableSet<CBPeripheral *> *connectingPeripherals;
@property (nonatomic, copy) NSString *scanMacAddress;

// 映射：CBPeripheral identifier -> WPPeripheralInfo
@property (nonatomic, strong) NSMutableDictionary<NSUUID *, WPPeripheralInfo *> *peripheralInfoMap;

@property (nonatomic, strong) NSTimer *reconnectTimer;
@property (nonatomic, strong) NSTimer *scanTimer;

// 🆕 v2.0.6: 连接超时定时器
@property (nonatomic, strong) NSTimer *connectionTimer;

// 🆕 v2.0.6: 正在连接的设备（用于超时回调）
@property (nonatomic, strong) CBPeripheral *connectingPeripheral;

@end

@implementation WPBluetoothManager

+ (instancetype)sharedInstance {
    static WPBluetoothManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _mutableDiscoveredPeripherals = [NSMutableArray array];
        _brands = [NSMutableDictionary dictionary];
        _connectingPeripherals = [NSMutableSet set];
        _peripheralInfoMap = [NSMutableDictionary dictionary];
        _isScanning = NO;
        _autoDisconnect = NO;
        _isOTAing = NO;
        _isReconnectingNow = NO;
        _scanMacAddress = @"";
        _scanTimeout = 0; // 默认不限时

        // 🆕 v2.0.3: 初始化重连保护标志
        _isReconnecting = NO;
        _reconnectAttempts = 0;
        _maxReconnectAttempts = 5; // 默认最大重连次数

        // 🆕 v2.0.6: 初始化连接超时
        _connectionTimeout = 30.0; // 默认连接超时 30 秒
    }
    return self;
}

// MARK: - 属性访问器

- (NSArray<WPPeripheralInfo *> *)discoveredPeripherals {
    return [self.mutableDiscoveredPeripherals copy];
}

- (BOOL)isConnected {
    return self.peripheral && self.peripheral.state == CBPeripheralStateConnected;
}

- (BOOL)isBluetoothPoweredOff {
    return self.centralManager.state == CBManagerStatePoweredOff;
}

// MARK: - 初始化方法

- (void)initCentral {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:queue];
    [[WPLogger sharedInstance] log:@"✅ 初始化蓝牙中心管理器"];
}

// MARK: - 扫描管理

- (void)startScanning:(BOOL)deleteCache {
    [self startScanning:deleteCache timeout:self.scanTimeout];
}

- (void)startScanning:(BOOL)deleteCache timeout:(NSTimeInterval)timeout {
    self.isReconnectingNow = NO;

    if (!self.isScanning) {
        self.isScanning = YES;

        NSDictionary *options = @{
            CBCentralManagerScanOptionAllowDuplicatesKey: @NO,
            CBCentralManagerScanOptionSolicitedServiceUUIDsKey: @[]
        };

        if (deleteCache) {
            [self.mutableDiscoveredPeripherals removeAllObjects];
        }

        [self startScanTimerWithMac:@"" timeout:timeout];
        [self.centralManager scanForPeripheralsWithServices:nil options:options];
        [[WPLogger sharedInstance] log:@"🔍 开始扫描设备"];
    }

    // 🆕 v2.0.3: 添加死循环保护 - 防止在重连过程中重复调用导致无限递归
    if (!self.isReconnecting) {
        [[WPLogger sharedInstance] log:@"🔄 检查是否需要重连到已保存设备"];
        [self reconnectToDevice];
    } else {
        [[WPLogger sharedInstance] log:@"⚠️ 已在重连过程中，跳过重复调用"];
    }
}

- (void)stopScanning {
    [[WPLogger sharedInstance] log:@"⏹ 停止扫描"];
    self.isScanning = NO;
    [self.centralManager stopScan];

    // 🆕 v2.0.3: 停止扫描时不重置重连标志，因为可能是扫描超时导致的停止
    // 重连逻辑会在 connectAndScanWithMac 中的超时保护中处理
}

- (void)startScanTimerWithMac:(NSString *)mac timeout:(NSTimeInterval)timeout {
    self.scanMacAddress = mac;
    [self.scanTimer invalidate];

    // 如果 timeout <= 0，表示不限时，不启动定时器
    if (timeout > 0) {
        self.scanTimer = [NSTimer scheduledTimerWithTimeInterval:timeout
                                                          target:self
                                                        selector:@selector(scanTimerFired:)
                                                        userInfo:nil
                                                         repeats:NO];
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"⏱ 设置扫描超时: %.1f 秒", timeout]];
    } else {
        [[WPLogger sharedInstance] log:@"♾️ 不限时扫描"];
    }
}

- (void)scanTimerFired:(NSTimer *)timer {
    if (self.isScanning) {
        [[WPLogger sharedInstance] log:@"⏰ 扫描超时，停止扫描"];
        [self stopScanning];

        // 🆕 v2.0.2: 通知代理扫描超时
        if (self.scanMacAddress.length > 0 && [self.delegate respondsToSelector:@selector(didScanTimeout:)]) {
            [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"⚠️ 未找到目标设备: %@", self.scanMacAddress]];
            [self.delegate didScanTimeout:self.scanMacAddress];
        }
    }
}

// MARK: - 连接管理

- (void)connectToPeripheral:(WPPeripheralInfo *)peripheralInfo {
    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"📱 连接指定的蓝牙设备: %@", peripheralInfo.peripheral.name]];

    // 保存映射关系
    [self.peripheralInfoMap setObject:peripheralInfo forKey:peripheralInfo.peripheral.identifier];

    // 🆕 v2.0.6: 启动连接超时定时器
    [self startConnectionTimerForPeripheral:peripheralInfo.peripheral];

    [self.centralManager connectPeripheral:peripheralInfo.peripheral options:nil];
    [self.connectingPeripherals addObject:peripheralInfo.peripheral];
}

- (void)connectToDeviceWithMac:(NSString *)macAddress {
    // 🆕 v2.0.1: 改进逻辑，设备不在列表时自动扫描
    // 🆕 v2.0.2: 忽略大小写进行匹配
    BOOL found = NO;
    NSString *targetMac = [macAddress uppercaseString];

    for (WPPeripheralInfo *info in self.mutableDiscoveredPeripherals) {
        if ([[info.macAddress uppercaseString] isEqualToString:targetMac]) {
            [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"📱 连接指定MAC地址 %@ 的设备", macAddress]];
            [self connectToPeripheral:info];
            found = YES;
            break;
        }
    }

    if (!found) {
        // 设备不在扫描列表中，自动触发扫描并连接
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"⚠️ 设备 %@ 不在扫描列表中，自动触发扫描", macAddress]];
        [self connectAndScanWithMac:macAddress deviceName:@"" timeout:10.0];
    }
}

- (void)connectAndScanWithMac:(NSString *)macAddress deviceName:(NSString *)deviceName {
    [self connectAndScanWithMac:macAddress deviceName:deviceName timeout:self.scanTimeout];
}

- (void)connectAndScanWithMac:(NSString *)macAddress deviceName:(NSString *)deviceName timeout:(NSTimeInterval)timeout {
    // 🆕 v2.0.2: 统一转换为大写
    self.scanMacAddress = [macAddress uppercaseString];
    self.isReconnectingNow = YES;

    // 🆕 v2.0.3: 设置重连标志，防止死循环
    self.isReconnecting = YES;
    self.reconnectAttempts++;

    // 🆕 v2.0.3: 添加最大重连次数保护
    if (self.reconnectAttempts > self.maxReconnectAttempts) {
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"❌ 重连次数超过限制(%ld次)，停止重连", (long)self.maxReconnectAttempts]];

        // 重置重连状态
        self.isReconnecting = NO;
        self.isReconnectingNow = NO;
        self.reconnectAttempts = 0;
        self.scanMacAddress = @"";

        // 通知代理重连失败
        if ([self.delegate respondsToSelector:@selector(didScanTimeout:)]) {
            [[WPLogger sharedInstance] log:@"📢 通知代理：扫描超时，未找到目标设备"];
            [self.delegate didScanTimeout:macAddress];
        }
        return;
    }

    // 🆕 v2.0.2: 检查是否已经在扫描结果中（忽略大小写）
    NSString *targetMac = [macAddress uppercaseString];
    for (WPPeripheralInfo *info in self.mutableDiscoveredPeripherals) {
        if ([[info.macAddress uppercaseString] isEqualToString:targetMac]) {
            [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"📱 发现目标设备 %@，直接连接", macAddress]];

            // 🆕 v2.0.3: 找到设备，重置重连计数
            self.reconnectAttempts = 0;

            [self connectToPeripheral:info];
            return;
        }
    }

    // 开始扫描
    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"🔍 开始扫描目标设备: %@ (%@) - 第%ld次尝试",
                                   deviceName.length > 0 ? deviceName : @"未知设备",
                                   macAddress,
                                   (long)self.reconnectAttempts]];
    [self startScanning:NO timeout:timeout];
}

- (void)disconnect {
    if (self.peripheral) {
        self.autoDisconnect = YES;
        [[WPLogger sharedInstance] log:@"🔌 主动断开连接"];
        [self.centralManager cancelPeripheralConnection:self.peripheral];
    }
}

- (void)cancelAllConnections {
    NSArray<CBPeripheral *> *connectedPeripherals = [self.centralManager retrieveConnectedPeripheralsWithServices:@[[CBUUID UUIDWithString:@"0000FF12-0000-1000-8000-00805F9B34FB"]]];

    for (CBPeripheral *peripheral in connectedPeripherals) {
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"🔌 取消系统蓝牙连接: %@", peripheral.name]];
        [self.centralManager cancelPeripheralConnection:peripheral];
    }

    [self.connectingPeripherals removeAllObjects];
}

// MARK: - 数据发送

- (BOOL)sendData:(NSData *)data {
    if (!self.peripheral || self.peripheral.state != CBPeripheralStateConnected) {
        [[WPLogger sharedInstance] log:@"❌ 发送失败：设备未连接"];
        return NO;
    }

    // 打印发送给设备的指令数据
    NSString *hexString = [data hexEncodedString];
    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"📤 发送指令 [%ld bytes]: %@", (long)data.length, hexString]];

    if (self.characteristic) {
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"   使用特征值: %@", self.characteristic.UUID]];
        [self.peripheral writeValue:data
                  forCharacteristic:self.characteristic
                               type:CBCharacteristicWriteWithoutResponse];
        return YES;
    } else if (self.dataInCharacteristic) {
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"   使用特征值: %@", self.dataInCharacteristic.UUID]];
        [self.peripheral writeValue:data
                  forCharacteristic:self.dataInCharacteristic
                               type:CBCharacteristicWriteWithoutResponse];
        return YES;
    }

    [[WPLogger sharedInstance] log:@"❌ 发送失败：特征值未找到"];
    return NO;
}

// 🔥 新增：使用WriteWithResponse模式发送数据
- (BOOL)sendDataWithResponse:(NSData *)data {
    if (!self.peripheral || self.peripheral.state != CBPeripheralStateConnected) {
        [[WPLogger sharedInstance] log:@"❌ 发送失败：设备未连接"];
        return NO;
    }

    // 打印发送给设备的指令数据
    NSString *hexString = [data hexEncodedString];
    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"📤 发送指令(WithResponse) [%ld bytes]: %@", (long)data.length, hexString]];

    if (self.characteristic) {
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"   使用特征值: %@", self.characteristic.UUID]];
        [self.peripheral writeValue:data
                  forCharacteristic:self.characteristic
                               type:CBCharacteristicWriteWithResponse];
        return YES;
    } else if (self.dataInCharacteristic) {
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"   使用特征值: %@", self.dataInCharacteristic.UUID]];
        [self.peripheral writeValue:data
                  forCharacteristic:self.dataInCharacteristic
                               type:CBCharacteristicWriteWithResponse];
        return YES;
    }

    [[WPLogger sharedInstance] log:@"❌ 发送失败：特征值未找到"];
    return NO;
}

// MARK: - 🆕 v2.0.6: 连接超时管理

/**
 * 启动连接超时定时器
 * @param peripheral 正在连接的设备
 */
- (void)startConnectionTimerForPeripheral:(CBPeripheral *)peripheral {
    // 取消现有定时器
    [self.connectionTimer invalidate];
    self.connectionTimer = nil;

    // 保存正在连接的设备
    self.connectingPeripheral = peripheral;

    // 如果 connectionTimeout <= 0，表示不限时，不启动定时器（不推荐）
    if (self.connectionTimeout > 0) {
        self.connectionTimer = [NSTimer scheduledTimerWithTimeInterval:self.connectionTimeout
                                                                target:self
                                                              selector:@selector(connectionTimerFired:)
                                                              userInfo:nil
                                                               repeats:NO];
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:
            @"⏱ 启动连接超时定时器: %.1f 秒 [设备: %@]",
            self.connectionTimeout, peripheral.name ?: @"未知"]];
    } else {
        [[WPLogger sharedInstance] log:@"⚠️ 连接超时已禁用（不推荐）"];
    }
}

/**
 * 取消连接超时定时器
 */
- (void)cancelConnectionTimer {
    if (self.connectionTimer) {
        [[WPLogger sharedInstance] log:@"✅ 取消连接超时定时器"];
        [self.connectionTimer invalidate];
        self.connectionTimer = nil;
        self.connectingPeripheral = nil;
    }
}

/**
 * 连接超时定时器触发
 */
- (void)connectionTimerFired:(NSTimer *)timer {
    [[WPLogger sharedInstance] log:@"⏰ 连接超时，强制取消连接"];

    // 取消连接
    if (self.connectingPeripheral) {
        CBPeripheral *peripheral = self.connectingPeripheral;

        // 调用系统方法取消连接
        [self.centralManager cancelPeripheralConnection:peripheral];

        // 从连接中列表移除
        [self.connectingPeripherals removeObject:peripheral];

        // 获取设备信息（用于回调）
        WPPeripheralInfo *peripheralInfo = [self.peripheralInfoMap objectForKey:peripheral.identifier];

        // 如果没有映射，尝试创建
        if (!peripheralInfo) {
            NSString *macAddress = self.currentDevice.mac ?: self.scanMacAddress ?: @"";
            peripheralInfo = [[WPPeripheralInfo alloc] initWithPeripheral:peripheral
                                                               macAddress:macAddress];
        }

        // 通知代理
        if (peripheralInfo && [self.delegate respondsToSelector:@selector(didConnectionTimeout:)]) {
            [[WPLogger sharedInstance] log:[NSString stringWithFormat:
                @"📢 通知代理：连接超时 [设备: %@]", peripheral.name ?: @"未知"]];
            [self.delegate didConnectionTimeout:peripheralInfo];
        }

        // 清理状态
        [self cancelConnectionTimer];
    }
}

// MARK: - 重连管理

- (void)reconnectToDevice {
    // 重连逻辑（简化版本）
    if (self.currentDevice && self.currentDevice.mac) {
        [self connectToDeviceWithMac:self.currentDevice.mac];
    }
}

// MARK: - 🆕 v2.0.2: 增强的重连方法

- (void)reconnectWithDevice:(WPBluetoothWatchDevice *)device {
    [self reconnectWithDevice:device timeout:10.0]; // 默认10秒超时
}

- (void)reconnectWithDevice:(WPBluetoothWatchDevice *)device timeout:(NSTimeInterval)timeout {
    if (!device) {
        [[WPLogger sharedInstance] log:@"❌ 重连失败：设备对象为空"];
        return;
    }

    // 设置 currentDevice
    self.currentDevice = device;

    // 🆕 v2.0.5: 智能路由 - 优先使用 UUID 快速重连
    if (device.peripheralUUID && device.peripheralUUID.length > 0) {
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:
            @"🚀 检测到 UUID，使用快速重连: %@ [UUID: %@]",
            device.deviceName ?: @"未知设备",
            device.peripheralUUID]];

        // 使用 UUID 快速重连（无需扫描）
        [self reconnectWithUUID:device.peripheralUUID];
        return;
    }

    // 降级方案：使用 MAC 地址扫描重连
    if (!device.mac || device.mac.length == 0) {
        [[WPLogger sharedInstance] log:@"❌ 重连失败：设备 MAC 地址为空"];
        return;
    }

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:
        @"⚠️ UUID 不可用，降级为扫描重连: %@ [MAC: %@]",
        device.deviceName ?: @"未知设备", device.mac]];

    // 使用 MAC 地址和设备名进行扫描连接
    [self connectAndScanWithMac:device.mac
                     deviceName:device.deviceName ?: @""
                        timeout:timeout];
}

- (BOOL)reconnectFromSandboxWithMac:(NSString *)macAddress {
    return [self reconnectFromSandboxWithMac:macAddress timeout:10.0]; // 默认10秒超时
}

- (BOOL)reconnectFromSandboxWithMac:(NSString *)macAddress timeout:(NSTimeInterval)timeout {
    if (!macAddress || macAddress.length == 0) {
        [[WPLogger sharedInstance] log:@"❌ 从沙盒恢复失败：MAC 地址为空"];
        return NO;
    }

    // 从沙盒加载设备信息
    WPBluetoothWatchDevice *device = [WPBluetoothWatchDevice loadFromSandboxWithMac:macAddress];

    if (!device) {
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"⚠️ 沙盒中未找到 MAC 为 %@ 的设备信息", macAddress]];
        return NO;
    }

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"✅ 从沙盒恢复设备信息: %@ [%@]",
                                   device.deviceName ?: @"未知设备", device.mac]];

    // 使用恢复的设备信息进行重连
    [self reconnectWithDevice:device timeout:timeout];

    return YES;
}

// MARK: - 🆕 v2.0.5: UUID 快速重连

- (void)reconnectWithUUID:(NSString *)uuidString {
    if (!uuidString || uuidString.length == 0) {
        [[WPLogger sharedInstance] log:@"❌ UUID 为空，无法重连"];
        return;
    }

    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"🚀 使用 UUID 快速重连: %@", uuidString]];

    // 将字符串转换为 NSUUID 对象
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
    if (!uuid) {
        [[WPLogger sharedInstance] log:@"❌ UUID 格式错误，无法重连"];
        // 降级到扫描重连
        if (self.currentDevice && self.currentDevice.mac) {
            [[WPLogger sharedInstance] log:@"⚠️ 降级为 MAC 扫描重连"];
            [self connectAndScanWithMac:self.currentDevice.mac
                             deviceName:self.currentDevice.deviceName ?: @""
                                timeout:10.0];
        }
        return;
    }

    // 🚀 核心：直接通过 UUID 获取已知设备（无需扫描）
    NSArray<CBPeripheral *> *peripherals = [self.centralManager retrievePeripheralsWithIdentifiers:@[uuid]];

    if (peripherals.count == 0) {
        [[WPLogger sharedInstance] log:@"⚠️ 未找到 UUID 对应的设备（系统未曾连接过该设备）"];
        // 降级到扫描重连
        if (self.currentDevice && self.currentDevice.mac) {
            [[WPLogger sharedInstance] log:@"⚠️ 降级为 MAC 扫描重连"];
            [self connectAndScanWithMac:self.currentDevice.mac
                             deviceName:self.currentDevice.deviceName ?: @""
                                timeout:10.0];
        }
        return;
    }

    // 获取到设备
    CBPeripheral *peripheral = peripherals.firstObject;
    [[WPLogger sharedInstance] log:[NSString stringWithFormat:
        @"✅ 找到设备（UUID匹配）: %@ [%@]",
        peripheral.name ?: @"未知设备",
        peripheral.identifier.UUIDString]];

    // 保存 peripheral 引用
    self.peripheral = peripheral;
    peripheral.delegate = self;

    // 🆕 v2.0.6: 启动连接超时定时器
    [self startConnectionTimerForPeripheral:peripheral];

    // 🚀 直接连接，无需扫描（这就是快速重连的核心）
    [[WPLogger sharedInstance] log:@"🔗 开始直接连接..."];
    [self.centralManager connectPeripheral:peripheral options:nil];
}

// MARK: - 🆕 v2.0.1: 健康数据查询

- (void)queryBatteryLevel {
    if (!self.isConnected) {
        [[WPLogger sharedInstance] log:@"❌ 查询电量失败：设备未连接"];
        return;
    }

    [[WPLogger sharedInstance] log:@"🔋 开始查询设备电量"];

    // 🆕 v2.0.1: 使用 WPCommands 发送电量查询指令
    [WPCommands getBatteryLevel];

    // 注意：响应会通过 handleResponse 自动解析并回调 didReceiveBatteryLevel:isCharging:
}

- (void)startHeartRateMonitoring {
    if (!self.isConnected) {
        [[WPLogger sharedInstance] log:@"❌ 开始心率测量失败：设备未连接"];
        return;
    }

    [[WPLogger sharedInstance] log:@"❤️ 开始心率连续测量"];

    // 🆕 v2.0.1: 使用 WPCommands 发送开始心率测试指令
    // cmdType: 0=心率, 1=血氧, 2=血压
    // control: 1=开始, 0=停止
    [WPCommands startTest:0 control:1];

    // 通知代理测量已开始
    if ([self.delegate respondsToSelector:@selector(didHeartRateMonitoringStatusChanged:)]) {
        [self.delegate didHeartRateMonitoringStatusChanged:YES];
    }

    // 注意：心率数据会通过 handleResponse 自动解析并回调 didReceiveHeartRate:
}

- (void)stopHeartRateMonitoring {
    if (!self.isConnected) {
        [[WPLogger sharedInstance] log:@"❌ 停止心率测量失败：设备未连接"];
        return;
    }

    [[WPLogger sharedInstance] log:@"❤️ 停止心率测量"];

    // 🆕 v2.0.1: 使用 WPCommands 发送停止心率测试指令
    // cmdType: 0=心率, control: 0=停止
    [WPCommands startTest:0 control:0];

    // 通知代理测量已停止
    if ([self.delegate respondsToSelector:@selector(didHeartRateMonitoringStatusChanged:)]) {
        [self.delegate didHeartRateMonitoringStatusChanged:NO];
    }
}

- (void)measureHeartRateOnce {
    if (!self.isConnected) {
        [[WPLogger sharedInstance] log:@"❌ 单次心率测量失败：设备未连接"];
        return;
    }

    [[WPLogger sharedInstance] log:@"❤️ 开始单次心率测量"];

    // 🆕 v2.0.1: 使用 WPCommands 获取最新心率数据
    // type: 0=心率, 1=血氧, 2=血压
    [WPCommands getNewestHeartData:0];

    // 注意：心率数据会通过 handleResponse 自动解析并回调 didReceiveHeartRate:
}

// MARK: - 🆕 v2.0.7: 查找设备功能

- (void)findDeviceWithCompletion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion {
    [[WPLogger sharedInstance] log:@"🔍 [WPBluetoothManager] 开始查找设备"];

    // 委托给 WPCommands+FindDevice 的类方法
    [WPCommands findBandWithCompletion:completion];
}

- (void)stopFindDeviceWithCompletion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion {
    [[WPLogger sharedInstance] log:@"⏹ [WPBluetoothManager] 停止查找设备"];

    // 委托给 WPCommands+FindDevice 的类方法
    [WPCommands stopFindBandWithCompletion:completion];
}

- (void)findDeviceWithDuration:(NSTimeInterval)duration
                    completion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion {
    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"🔍 [WPBluetoothManager] 开始查找设备（%.1f秒后自动停止）", duration]];

    // 委托给 WPCommands+FindDevice 的类方法
    [WPCommands findBandWithDuration:duration completion:completion];
}

- (BOOL)isFindingDevice {
    // 委托给 WPCommands+FindDevice 的类属性
    return [WPCommands isFindingDevice];
}

// MARK: - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    switch (central.state) {
        case CBManagerStatePoweredOn:
            [[WPLogger sharedInstance] log:@"✅ 蓝牙已开启"];
            if ([self.delegate respondsToSelector:@selector(onBleReady)]) {
                [self.delegate onBleReady];
            }
            break;
        case CBManagerStatePoweredOff:
            [[WPLogger sharedInstance] log:@"⚠️ 蓝牙已关闭"];
            break;
        case CBManagerStateUnauthorized:
            [[WPLogger sharedInstance] log:@"⚠️ 蓝牙未授权"];
            break;
        case CBManagerStateUnsupported:
            [[WPLogger sharedInstance] log:@"⚠️ 设备不支持蓝牙"];
            break;
        default:
            break;
    }
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary<NSString *,id> *)advertisementData
                  RSSI:(NSNumber *)RSSI {

    // 🆕 v2.0.2: 从广播数据的制造商数据中提取真实的 MAC 地址
    // 对应 Swift 版本 XGZTBlueToothManager.swift 的实现逻辑
    NSData *manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey];

    // 检查制造商数据是否符合协议规范：
    // - 长度为 15 字节
    // - manufacturerData[0] == 0x06
    // - manufacturerData[1] == 0x01
    if (!manufacturerData || manufacturerData.length != 15) {
        // 不符合协议规范，跳过此设备
        return;
    }

    const uint8_t *bytes = (const uint8_t *)manufacturerData.bytes;
    if (bytes[0] != 0x06 || bytes[1] != 0x01) {
        // 不符合协议规范，跳过此设备
        return;
    }

    // 从索引 5-10 提取 MAC 地址（共 6 个字节）
    NSData *macData = [manufacturerData subdataWithRange:NSMakeRange(5, 6)];
    // 转换为十六进制字符串，格式如 "AA:BB:CC:DD:EE:FF"
    NSString *macAddress = [macData hexEncodedStringWithSeparator:@":"];

    // 提取品牌信息（索引 12）
    NSInteger brand = bytes[12];
    [self.brands setObject:@(brand) forKey:macAddress];

    // 创建外设信息
    WPPeripheralInfo *info = [[WPPeripheralInfo alloc] initWithPeripheral:peripheral
                                                               macAddress:macAddress];

    // 检查是否已存在
    BOOL exists = NO;
    for (WPPeripheralInfo *existingInfo in self.mutableDiscoveredPeripherals) {
        if ([existingInfo.peripheral.identifier isEqual:peripheral.identifier]) {
            exists = YES;
            break;
        }
    }

    if (!exists) {
        [self.mutableDiscoveredPeripherals addObject:info];
        // 保存映射关系
        [self.peripheralInfoMap setObject:info forKey:peripheral.identifier];

        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"🔍 发现设备: %@ [%@] RSSI: %@\n广播数据: %@",
                                       peripheral.name ?: @"未知", macAddress, RSSI, advertisementData]];

        if ([self.delegate respondsToSelector:@selector(didDiscoverPeripheral:)]) {
            [self.delegate didDiscoverPeripheral:info];
        }
    }

    // 🆕 v2.0.2: 自动连接目标设备（忽略大小写）
    if (self.scanMacAddress.length > 0) {
        NSString *targetMac = [self.scanMacAddress uppercaseString];
        NSString *discoveredMac = [macAddress uppercaseString];

        // 使用 lowercased 比较以忽略大小写，匹配 Swift 版本的逻辑
        if ([discoveredMac.lowercaseString isEqualToString:targetMac.lowercaseString]) {
            [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"✅ 找到目标设备 %@，准备连接", peripheral.name]];

            // 检查设备名称是否有效（匹配 Swift 版本的逻辑）
            if (peripheral.name.length > 0) {
                [self stopScanning];
                [self connectToPeripheral:info];
                self.scanMacAddress = @""; // 清空扫描目标
            }
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"✅ 设备连接成功: %@", peripheral.name]];

    // 🆕 v2.0.6: 连接成功，取消连接超时定时器
    [self cancelConnectionTimer];

    // 🆕 v2.0.3: 连接成功，重置重连标志和计数器
    self.isReconnecting = NO;
    self.isReconnectingNow = NO;
    self.reconnectAttempts = 0;
    [[WPLogger sharedInstance] log:@"✅ 已重置重连状态（连接成功）"];

    self.peripheral = peripheral;
    peripheral.delegate = self;

    [self.connectingPeripherals removeObject:peripheral];

    // 发现服务
    [peripheral discoverServices:nil];

    // 从映射中获取 WPPeripheralInfo
    WPPeripheralInfo *peripheralInfo = [self.peripheralInfoMap objectForKey:peripheral.identifier];

    // 🆕 v2.0.4: 修复回连时代理未触发的 bug
    // 如果映射中没有 peripheralInfo（例如 app 重启后的系统自动回连），则尝试创建
    if (!peripheralInfo) {
        [[WPLogger sharedInstance] log:@"⚠️ peripheralInfoMap 中未找到映射，尝试创建 WPPeripheralInfo"];

        // 尝试从 currentDevice 获取 MAC 地址
        NSString *macAddress = self.currentDevice.mac ?: @"";

        // 如果没有 currentDevice，尝试从扫描目标 MAC 获取
        if (macAddress.length == 0 && self.scanMacAddress.length > 0) {
            macAddress = self.scanMacAddress;
            [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"📝 使用扫描目标 MAC: %@", macAddress]];
        }

        // 创建 WPPeripheralInfo
        peripheralInfo = [[WPPeripheralInfo alloc] initWithPeripheral:peripheral
                                                            macAddress:macAddress];

        // 保存到映射中，避免下次再创建
        [self.peripheralInfoMap setObject:peripheralInfo forKey:peripheral.identifier];

        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"✅ 已创建并保存 WPPeripheralInfo [MAC: %@]", macAddress]];
    }

    // 🆕 v2.0.1: 自动创建并设置 currentDevice
    if (peripheralInfo) {
        WPBluetoothWatchDevice *device = [WPBluetoothWatchDevice deviceFromPeripheralInfo:peripheralInfo];

        // 🆕 v2.0.5: 保存 peripheral UUID 以支持快速重连
        NSString *uuidString = peripheral.identifier.UUIDString;
        device.peripheralUUID = uuidString;

        [[WPLogger sharedInstance] log:[NSString stringWithFormat:
            @"💾 已保存设备 UUID: %@ [MAC: %@]",
            uuidString, device.mac]];

        self.currentDevice = device;

        // 自动保存到沙盒（包含 UUID）
        [WPBluetoothWatchDevice saveToSandbox:device];

        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"✅ 已自动设置 currentDevice: %@", device.deviceName]];
    }
    // 🆕 v2.0.5: 如果 currentDevice 已存在但没有 UUID，则补充保存 UUID
    else if (self.currentDevice && (!self.currentDevice.peripheralUUID || self.currentDevice.peripheralUUID.length == 0)) {
        NSString *uuidString = peripheral.identifier.UUIDString;
        self.currentDevice.peripheralUUID = uuidString;

        [[WPLogger sharedInstance] log:[NSString stringWithFormat:
            @"💾 补充保存设备 UUID: %@ [MAC: %@]",
            uuidString, self.currentDevice.mac]];

        // 更新沙盒存储
        [WPBluetoothWatchDevice saveToSandbox:self.currentDevice];
    }

    // 🆕 v2.0.4: 确保代理总是被触发（移除 peripheralInfo 的 nil 检查）
    if (peripheralInfo && [self.delegate respondsToSelector:@selector(didConnectPeripheral:)]) {
        [[WPLogger sharedInstance] log:@"📢 触发代理：didConnectPeripheral"];
        [self.delegate didConnectPeripheral:peripheralInfo];
    } else if (!peripheralInfo) {
        [[WPLogger sharedInstance] log:@"❌ 无法创建 WPPeripheralInfo，代理未触发"];
    }
}

- (void)centralManager:(CBCentralManager *)central
didFailToConnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error {
    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"❌ 连接失败: %@ - %@",
                                   peripheral.name, error.localizedDescription]];

    // 🆕 v2.0.6: 连接失败，取消连接超时定时器
    [self cancelConnectionTimer];

    [self.connectingPeripherals removeObject:peripheral];
}

- (void)centralManager:(CBCentralManager *)central
didDisconnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error {
    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"🔌 设备已断开: %@", peripheral.name]];

    // 🆕 v2.0.6: 断开连接，取消连接超时定时器
    [self cancelConnectionTimer];

    // 从映射中获取 WPPeripheralInfo
    WPPeripheralInfo *peripheralInfo = [self.peripheralInfoMap objectForKey:peripheral.identifier];

    // 🆕 v2.0.4: 修复回连时代理未触发的 bug
    // 如果映射中没有 peripheralInfo，则尝试创建
    if (!peripheralInfo) {
        [[WPLogger sharedInstance] log:@"⚠️ peripheralInfoMap 中未找到映射，尝试创建 WPPeripheralInfo"];

        // 尝试从 currentDevice 获取 MAC 地址
        NSString *macAddress = self.currentDevice.mac ?: @"";

        // 创建 WPPeripheralInfo
        peripheralInfo = [[WPPeripheralInfo alloc] initWithPeripheral:peripheral
                                                            macAddress:macAddress];

        // 不需要保存到映射中，因为设备已经断开

        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"✅ 已创建 WPPeripheralInfo [MAC: %@]", macAddress]];
    }

    // 🆕 v2.0.4: 确保代理总是被触发
    if (peripheralInfo && [self.delegate respondsToSelector:@selector(didDisconnectPeripheral:error:)]) {
        [[WPLogger sharedInstance] log:@"📢 触发代理：didDisconnectPeripheral"];
        [self.delegate didDisconnectPeripheral:peripheralInfo error:error];
    } else if (!peripheralInfo) {
        [[WPLogger sharedInstance] log:@"❌ 无法创建 WPPeripheralInfo，代理未触发"];
    }

    // 🆕 v2.0.1: 智能管理 currentDevice
    if (self.autoDisconnect || !error) {
        // 主动断开或正常断开，清空 currentDevice
        self.currentDevice = nil;
        [[WPLogger sharedInstance] log:@"🔌 已清空 currentDevice（主动断开）"];

        // 🆕 v2.0.3: 主动断开时重置重连状态
        self.isReconnecting = NO;
        self.isReconnectingNow = NO;
        self.reconnectAttempts = 0;
        [[WPLogger sharedInstance] log:@"✅ 已重置重连状态（主动断开）"];
    } else {
        // 意外断开，保留 currentDevice 以便重连
        [[WPLogger sharedInstance] log:@"⚠️ 意外断开，保留 currentDevice 用于重连"];

        // 🆕 v2.0.3: 意外断开时也重置重连计数器，避免累积
        self.reconnectAttempts = 0;
        [[WPLogger sharedInstance] log:@"🔄 已重置重连计数器（意外断开，准备重新开始重连）"];
    }

    // 重置自动断开标志
    self.autoDisconnect = NO;

    // 清空特征值
    self.characteristic = nil;
    self.dataInCharacteristic = nil;
    self.dataOutCharacteristic = nil;
    self.notifyCharacteristic = nil;
}

// MARK: - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error) {
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"❌ 发现服务失败: %@", error]];
        return;
    }

    for (CBService *service in peripheral.services) {
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"🔍 发现服务: %@", service.UUID]];
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverCharacteristicsForService:(CBService *)service
             error:(NSError *)error {
    if (error) {
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"❌ 发现特征失败: %@", error]];
        return;
    }

    for (CBCharacteristic *characteristic in service.characteristics) {
        // 🔥 详细日志：显示特征值属性
        NSMutableString *properties = [NSMutableString string];
        if (characteristic.properties & CBCharacteristicPropertyRead) [properties appendString:@"Read "];
        if (characteristic.properties & CBCharacteristicPropertyWrite) [properties appendString:@"Write "];
        if (characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse) [properties appendString:@"WriteNoResp "];
        if (characteristic.properties & CBCharacteristicPropertyNotify) [properties appendString:@"Notify "];
        if (characteristic.properties & CBCharacteristicPropertyIndicate) [properties appendString:@"Indicate "];

        NSString *uuidString = [[characteristic.UUID UUIDString] uppercaseString];

        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"🔍 发现特征: %@", uuidString]];
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"   属性: %@", properties.length > 0 ? properties : @"无"]];

        // 🎯 使用设备指定的UUID进行匹配
        // FF14: 用于接收设备Notify数据 (UUID格式: 0000FF14-0000-1000-8000-00805F9B34FB)
        if ([uuidString rangeOfString:@"FF14"].location != NSNotFound) {
            [[WPLogger sharedInstance] log:@"   ✅ 这是Notify特征值 (FF14)"];
            [[WPLogger sharedInstance] log:@"   📡 开始订阅Notify..."];
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            self.notifyCharacteristic = characteristic;
        }

        // FF13: 用于APP写数据到设备 (UUID格式: 0000FF13-0000-1000-8000-00805F9B34FB)
        if ([uuidString rangeOfString:@"FF13"].location != NSNotFound) {
            [[WPLogger sharedInstance] log:@"   ✅ 这是写入特征值 (FF13)"];
            [[WPLogger sharedInstance] log:@"   ✍️ 保存为写入特征值"];
            self.characteristic = characteristic;
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error {
    if (error) {
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"❌ 读取数据失败: %@", error]];
        return;
    }

    NSData *data = characteristic.value;
    if (data) {
        // 打印设备返回的指令数据
        NSString *hexString = [data hexEncodedString];
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"📥 接收指令 [%ld bytes]: %@", (long)data.length, hexString]];

        // 🆕 v2.0.1: 自动解析协议数据
        [WPCommands handleResponse:data];

        // 保持向后兼容：仍然回调原始数据
        if ([self.delegate respondsToSelector:@selector(receiveData:)]) {
            [self.delegate receiveData:data];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error {
    if (error) {
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"❌ 写入数据失败: %@", error]];
    } else {
        if ([self.delegate respondsToSelector:@selector(sentData)]) {
            [self.delegate sentData];
        }
    }
}

// 🔥 新增：检查notify订阅状态
- (void)peripheral:(CBPeripheral *)peripheral
didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error {
    if (error) {
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"❌ Notify订阅失败: %@ - %@", characteristic.UUID, error]];
    } else {
        if (characteristic.isNotifying) {
            [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"✅ Notify订阅成功: %@", characteristic.UUID]];
        } else {
            [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"⚠️ Notify取消订阅: %@", characteristic.UUID]];
        }
    }
}

// MARK: - 🔥 抬手亮屏功能

- (void)setRaiseToWake:(BOOL)enable completion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion {
    // 导入Category头文件并调用
    [WPCommands setRaiseToWake:enable completion:completion];
}

- (void)getRaiseToWakeStatus:(nullable void(^)(BOOL success, NSError * _Nullable error))completion {
    // 导入Category头文件并调用
    [WPCommands getRaiseToWakeStatus:completion];
}

// MARK: - 🔥 闹钟功能

- (void)queryAlarmCount:(nullable void(^)(BOOL success, NSError * _Nullable error))completion {
    [WPCommands queryAlarmCount:completion];
}

- (void)queryAlarmInfo:(NSInteger)alarmId completion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion {
    [WPCommands queryAlarmInfo:alarmId completion:completion];
}

- (void)setAlarm:(WPAlarmData *)alarm completion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion {
    [WPCommands setAlarm:alarm completion:completion];
}

- (void)deleteAlarm:(NSInteger)alarmId completion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion {
    [WPCommands deleteAlarm:alarmId completion:completion];
}

- (void)queryAllAlarms:(nullable void(^)(BOOL success, NSError * _Nullable error))completion {
    [WPCommands queryAllAlarms:completion];
}

// MARK: - 🔥 久坐提醒和喝水提醒功能

- (void)queryLongSitReminder:(nullable void(^)(BOOL success, NSError * _Nullable error))completion {
    [WPCommands queryLongSitReminder:completion];
}

- (void)queryDrinkWaterReminder:(nullable void(^)(BOOL success, NSError * _Nullable error))completion {
    [WPCommands queryDrinkWaterReminder:completion];
}

- (void)setLongSitReminder:(WPReminderInfo *)reminder completion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion {
    [WPCommands setLongSitReminder:reminder completion:completion];
}

- (void)setDrinkWaterReminder:(WPReminderInfo *)reminder completion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion {
    [WPCommands setDrinkWaterReminder:reminder completion:completion];
}

- (void)enableLongSitReminderWithCompletion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion {
    [WPCommands enableLongSitReminderWithCompletion:completion];
}

- (void)disableLongSitReminderWithCompletion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion {
    [WPCommands disableLongSitReminderWithCompletion:completion];
}

- (void)enableDrinkWaterReminderWithCompletion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion {
    [WPCommands enableDrinkWaterReminderWithCompletion:completion];
}

- (void)disableDrinkWaterReminderWithCompletion:(nullable void(^)(BOOL success, NSError * _Nullable error))completion {
    [WPCommands disableDrinkWaterReminderWithCompletion:completion];
}

- (void)dealloc {
    [self.reconnectTimer invalidate];
    [self.scanTimer invalidate];
    [self.connectionTimer invalidate];  // 🆕 v2.0.6: 清理连接超时定时器
}

@end
