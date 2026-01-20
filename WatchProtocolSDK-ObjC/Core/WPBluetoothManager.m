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

@property (nonatomic, strong) NSMutableSet<CBPeripheral *> *connectingPeripherals;
@property (nonatomic, copy) NSString *scanMacAddress;

// 映射：CBPeripheral identifier -> WPPeripheralInfo
@property (nonatomic, strong) NSMutableDictionary<NSUUID *, WPPeripheralInfo *> *peripheralInfoMap;

@property (nonatomic, strong) NSTimer *reconnectTimer;
@property (nonatomic, strong) NSTimer *scanTimer;

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

    [self reconnectToDevice];
}

- (void)stopScanning {
    [[WPLogger sharedInstance] log:@"⏹ 停止扫描"];
    self.isScanning = NO;
    [self.centralManager stopScan];
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
    }
}

// MARK: - 连接管理

- (void)connectToPeripheral:(WPPeripheralInfo *)peripheralInfo {
    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"📱 连接指定的蓝牙设备: %@", peripheralInfo.peripheral.name]];

    // 保存映射关系
    [self.peripheralInfoMap setObject:peripheralInfo forKey:peripheralInfo.peripheral.identifier];

    [self.centralManager connectPeripheral:peripheralInfo.peripheral options:nil];
    [self.connectingPeripherals addObject:peripheralInfo.peripheral];
}

- (void)connectToDeviceWithMac:(NSString *)macAddress {
    // 🆕 v2.0.1: 改进逻辑，设备不在列表时自动扫描
    BOOL found = NO;
    for (WPPeripheralInfo *info in self.mutableDiscoveredPeripherals) {
        if ([info.macAddress isEqualToString:macAddress]) {
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
    self.scanMacAddress = macAddress;
    self.isReconnectingNow = YES;

    // 检查是否已经在扫描结果中
    for (WPPeripheralInfo *info in self.mutableDiscoveredPeripherals) {
        if ([info.macAddress isEqualToString:macAddress]) {
            [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"📱 发现目标设备 %@，直接连接", macAddress]];
            [self connectToPeripheral:info];
            return;
        }
    }

    // 开始扫描
    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"🔍 开始扫描目标设备: %@", deviceName]];
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

    if (self.characteristic) {
        [self.peripheral writeValue:data
                  forCharacteristic:self.characteristic
                               type:CBCharacteristicWriteWithoutResponse];
        return YES;
    } else if (self.dataInCharacteristic) {
        [self.peripheral writeValue:data
                  forCharacteristic:self.dataInCharacteristic
                               type:CBCharacteristicWriteWithoutResponse];
        return YES;
    }

    [[WPLogger sharedInstance] log:@"❌ 发送失败：特征值未找到"];
    return NO;
}

// MARK: - 重连管理

- (void)reconnectToDevice {
    // 重连逻辑（简化版本）
    if (self.currentDevice && self.currentDevice.mac) {
        [self connectToDeviceWithMac:self.currentDevice.mac];
    }
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

    // 从广播数据中提取 MAC 地址（简化处理）
    NSString *macAddress = peripheral.identifier.UUIDString;

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

        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"🔍 发现设备: %@ [%@]",
                                       peripheral.name ?: @"未知", macAddress]];

        if ([self.delegate respondsToSelector:@selector(didDiscoverPeripheral:)]) {
            [self.delegate didDiscoverPeripheral:info];
        }
    }

    // 自动连接目标设备
    if (self.scanMacAddress.length > 0 && [macAddress containsString:self.scanMacAddress]) {
        [self stopScanning];
        [self connectToPeripheral:info];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"✅ 设备连接成功: %@", peripheral.name]];

    self.peripheral = peripheral;
    peripheral.delegate = self;

    [self.connectingPeripherals removeObject:peripheral];

    // 发现服务
    [peripheral discoverServices:nil];

    // 从映射中获取 WPPeripheralInfo
    WPPeripheralInfo *peripheralInfo = [self.peripheralInfoMap objectForKey:peripheral.identifier];

    // 🆕 v2.0.1: 自动创建并设置 currentDevice
    if (peripheralInfo) {
        WPBluetoothWatchDevice *device = [WPBluetoothWatchDevice deviceFromPeripheralInfo:peripheralInfo];
        self.currentDevice = device;

        // 自动保存到沙盒
        [WPBluetoothWatchDevice saveToSandbox:device];

        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"✅ 已自动设置 currentDevice: %@", device.deviceName]];
    }

    if (peripheralInfo && [self.delegate respondsToSelector:@selector(didConnectPeripheral:)]) {
        [self.delegate didConnectPeripheral:peripheralInfo];
    }
}

- (void)centralManager:(CBCentralManager *)central
didFailToConnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error {
    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"❌ 连接失败: %@ - %@",
                                   peripheral.name, error.localizedDescription]];
    [self.connectingPeripherals removeObject:peripheral];
}

- (void)centralManager:(CBCentralManager *)central
didDisconnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error {
    [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"🔌 设备已断开: %@", peripheral.name]];

    // 从映射中获取 WPPeripheralInfo
    WPPeripheralInfo *peripheralInfo = [self.peripheralInfoMap objectForKey:peripheral.identifier];
    if (peripheralInfo && [self.delegate respondsToSelector:@selector(didDisconnectPeripheral:error:)]) {
        [self.delegate didDisconnectPeripheral:peripheralInfo error:error];
    }

    // 🆕 v2.0.1: 智能管理 currentDevice
    if (self.autoDisconnect || !error) {
        // 主动断开或正常断开，清空 currentDevice
        self.currentDevice = nil;
        [[WPLogger sharedInstance] log:@"🔌 已清空 currentDevice（主动断开）"];
    } else {
        // 意外断开，保留 currentDevice 以便重连
        [[WPLogger sharedInstance] log:@"⚠️ 意外断开，保留 currentDevice 用于重连"];
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
        [[WPLogger sharedInstance] log:[NSString stringWithFormat:@"🔍 发现特征: %@", characteristic.UUID]];

        // 订阅通知
        if (characteristic.properties & CBCharacteristicPropertyNotify) {
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            self.notifyCharacteristic = characteristic;
        }

        // 保存可写特征
        if (characteristic.properties & CBCharacteristicPropertyWrite ||
            characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse) {
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

- (void)dealloc {
    [self.reconnectTimer invalidate];
    [self.scanTimer invalidate];
}

@end
