//
//  QCY_BLEApple.m
//  QCY_Demo
//
//  Created by 杰理科技 on 2020/3/17.
//  Copyright © 2020 杰理科技. All rights reserved.
//

#import "QCY_BLEApple.h"

NSString *kQCY_BLE_FOUND        = @"QCY_BLE_FOUND";            //发现设备
NSString *kQCY_BLE_PAIRED       = @"QCY_BLE_PAIRED";           //BLE已配对
NSString *kQCY_BLE_CONNECTED    = @"QCY_BLE_CONNECTED";        //BLE已连接
NSString *kQCY_BLE_DISCONNECTED = @"QCY_BLE_DISCONNECTED";     //BLE断开连接
NSString *kQCY_BLE_ON           = @"QCY_BLE_ON";               //BLE开启
NSString *kQCY_BLE_OFF          = @"QCY_BLE_OFF";              //BLE关闭
NSString *kQCY_BLE_ERROR        = @"QCY_BLE_ERROR";            //BLE错误提示

NSString *QCY_BLE_SERVICE = @"AE00"; //服务号
NSString *QCY_BLE_RCSP_W  = @"AE01"; //命令“写”通道
NSString *QCY_BLE_RCSP_R  = @"AE02"; //命令“读”通道


@interface QCY_BLEApple()<CBCentralManagerDelegate,
                         CBPeripheralDelegate>
{
    CBCentralManager    *bleManager;
    CBManagerState      bleManagerState;
    
    NSMutableArray      *blePeripheralArr;
    CBPeripheral        *bleCurrentPeripheral;
    NSString            *bleCurrentName;
    
    /*--- 连接超时管理 ---*/
    NSTimer             *linkTimer;

}

@end

@implementation QCY_BLEApple

- (instancetype)init
{
    self = [super init];
    if (self) {
        bleManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        
        linkTimer = [JL_Tools timingStart:@selector(startScanBLE)
                                   target:self Time:1.0];
        [JL_Tools timingPause:linkTimer];
        
        self.isSaveUUID = YES;
        
        /*--- JLSDK ADD ---*/
        self.mAssist = [[JL_Assist alloc] init];
        self.mAssist.mNeedPaired = YES;             //是否需要握手配对
        self.mAssist.mPairKey    = nil;             //配对秘钥
        self.mAssist.mService    = QCY_BLE_SERVICE; //服务号
        self.mAssist.mRcsp_W     = QCY_BLE_RCSP_W;  //特征「写」
        self.mAssist.mRcsp_R     = QCY_BLE_RCSP_R;  //特征「读」
    }
    return self;
}


-(void)startScanTimer{
    if (linkTimer) {
        [JL_Tools timingContinue:linkTimer];
    }else{
        linkTimer = [JL_Tools timingStart:@selector(startScanBLE)
                                   target:self Time:1.0];
    }
}

-(void)stopScanTimer{
    [JL_Tools timingPause:linkTimer];
    [self stopScanBLE];
}


#pragma mark - 开始扫描
-(void)startScanBLE{
    blePeripheralArr = [NSMutableArray new];
    [self newScanBLE];
}

-(void)newScanBLE{
    if (bleManager) {
        if (bleManager.state == CBManagerStatePoweredOn) {
            [self scan];
        }else{
            [JL_Tools delay:0.5 Task:^{
                if (self->bleManager.state == CBManagerStatePoweredOn) {
                    [self scan];
                }
            }];
        }
    }
}
-(void)scan{
    [bleManager scanForPeripheralsWithServices:nil options:nil];
}


#pragma mark - 停止扫描
-(void)stopScanBLE{
    if (bleManager) [bleManager stopScan];
}

#pragma mark - 连接设备
-(void)connectBLE:(CBPeripheral*)peripheral{
    
    bleCurrentPeripheral = peripheral;
    [bleCurrentPeripheral setDelegate:self];
    
    [bleManager connectPeripheral:bleCurrentPeripheral
                          options:@{CBConnectPeripheralOptionNotifyOnDisconnectionKey:@(YES),
                                    CBConnectPeripheralOptionNotifyOnConnectionKey:@(YES)
                          }];
    [bleManager stopScan];

    NSLog(@"BLE Connecting... Name ---> %@ UUID:%@",peripheral.name,peripheral.identifier.UUIDString);
}

#pragma mark - 断开连接
-(void)disconnectBLE{
    if (bleCurrentPeripheral) {
        NSLog(@"BLE --->To disconnectBLE.");
        [bleManager cancelPeripheralConnection:bleCurrentPeripheral];
    }
}



#pragma mark - 使用UUID，重连设备。
-(void)connectPeripheralWithUUID:(NSString*)uuid{
    
    NSArray *uuidArr = @[[[NSUUID alloc] initWithUUIDString:uuid]];
    NSArray *phArr = [bleManager retrievePeripheralsWithIdentifiers:uuidArr];//serviceUUID就是你首次连接配对的蓝牙

    
    if (phArr.count == 0) {
        return;
    }
    
    CBPeripheral* peripheral = phArr[0];
    
    if(phArr.firstObject
       && [phArr.firstObject state] != CBPeripheralStateConnected
       && [phArr.firstObject state] != CBPeripheralStateConnecting)
    {
        
        NSString *ble_name = peripheral.name;
        NSString *ble_uuid = peripheral.identifier.UUIDString;
        NSLog(@"QCY Connecting(Last)... Name ---> %@ UUID:%@",ble_name,ble_uuid);
        
        bleCurrentPeripheral = peripheral;
        [bleCurrentPeripheral setDelegate:self];
        
        [bleManager connectPeripheral:bleCurrentPeripheral
                              options:@{CBConnectPeripheralOptionNotifyOnDisconnectionKey:@(YES)}];
    }
}

#pragma mark - 蓝牙初始化 Callback
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSInteger st = central.state;
    /*--- JLSDK ADD ---*/
    [self.mAssist assistUpdateState:central.state];
    
    bleManagerState = st;

    if (bleManagerState != CBManagerStatePoweredOn) {
        self.mBlePeripheral = nil;
    }
    
    switch (central.state) {
        case CBManagerStatePoweredOn:
            NSLog(@"BLE--> CBManagerStatePoweredOn....");
            [JL_Tools post:kQCY_BLE_ON Object:@(1)];
            break;
        case CBManagerStatePoweredOff:
            NSLog(@"BLE--> CBManagerStatePoweredOff");
            [JL_Tools post:kQCY_BLE_ERROR Object:@(4001)];
            [JL_Tools post:kQCY_BLE_OFF Object:@(0)];
            break;
        case CBManagerStateUnsupported:
            NSLog(@"BLE--> CBManagerStateUnsupported");
            [JL_Tools post:kQCY_BLE_ERROR Object:@(4002)];
            [JL_Tools post:kQCY_BLE_OFF Object:@(-1)];
            break;
        case CBManagerStateUnauthorized:
            NSLog(@"BLE--> CBManagerStateUnauthorized");
            [JL_Tools post:kQCY_BLE_ERROR Object:@(4003)];
            [JL_Tools post:kQCY_BLE_OFF Object:@(-2)];
            break;
        case CBManagerStateResetting:
            NSLog(@"BLE--> CBCentralManagerStateResetting");
            [JL_Tools post:kQCY_BLE_ERROR Object:@(4004)];
            [JL_Tools post:kQCY_BLE_OFF Object:@(-3)];
            break;
        case CBManagerStateUnknown:
            NSLog(@"BLE--> CBCentralManagerStateUnknown");
            [JL_Tools post:kQCY_BLE_ERROR Object:@(4005)];
            [JL_Tools post:kQCY_BLE_OFF Object:@(-4)];
            break;
    }
}


#pragma mark - 发现设备
-(void)centralManager:(CBCentralManager *)central
didDiscoverPeripheral:(CBPeripheral *)peripheral
    advertisementData:(NSDictionary<NSString *,id> *)advertisementData
                 RSSI:(NSNumber *)RSSI
{
    //NSString *ble_uuid = peripheral.identifier.UUIDString;
    NSString *ble_name = advertisementData[@"kCBAdvDataLocalName"]; //peripheral.name;
    NSData   *ble_AD   = advertisementData[@"kCBAdvDataManufacturerData"];
    //if (ble_name.length == 0 || [RSSI intValue] < -70) return;
    //if (ble_name.length == 0) return;
    
    NSLog(@"发现 ----> NAME:%@ RSSI:%@ AD:%@ ",ble_name,RSSI,ble_AD);
    
    [self addPeripheral:peripheral RSSI:RSSI Name:ble_name];
    [JL_Tools post:kQCY_BLE_FOUND Object:blePeripheralArr];
}

-(void)addPeripheral:(CBPeripheral*)peripheral
                RSSI:(NSNumber *)rssi
                Name:(NSString*)name
{
    int flag = 0;
    for (NSMutableDictionary *infoDic in blePeripheralArr) {
        CBPeripheral *info_pl = infoDic[@"BLE"];
        NSString *info_uuid = info_pl.identifier.UUIDString;
        NSString *ble_uuid  = peripheral.identifier.UUIDString;
        if ([info_uuid isEqual:ble_uuid]) {
            flag = 1;
            [infoDic setObject:rssi forKey:@"RSSI"];
            break;
        }
    }
    if (flag == 0 && name.length>0) {
        NSMutableDictionary *mDic = [NSMutableDictionary new];
        [mDic setObject:peripheral      forKey:@"BLE"];
        [mDic setObject:rssi            forKey:@"RSSI"];
        [mDic setObject:name?:@"Unknow" forKey:@"NAME"];
        [blePeripheralArr addObject:mDic];
    }
}

-(void)centralManager:(CBCentralManager *)central connectionEventDidOccur:(CBConnectionEvent)event
        forPeripheral:(CBPeripheral *)peripheral{
    if (event == CBConnectionEventPeerConnected) {
        NSLog(@"---> 系统界面，已连接设备:%@",peripheral.name);
        if (peripheral.name.length > 0) {
            [self connectBLE:peripheral];
        }
    }
    
    if (event == CBConnectionEventPeerDisconnected) {
        NSLog(@"---> 系统界面，断开设备:%@",peripheral.name);
    }
}


#pragma mark - 设备连接回调
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"BLE Connected ---> Device %@",peripheral.name);
    [JL_Tools post:kQCY_BLE_CONNECTED Object:peripheral];
    
    // 连接成功后，查找服务
    [peripheral discoverServices:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral
                 error:(nullable NSError *)error
{
    NSLog(@"Err:BLE Connect FAIL ---> Device:%@ Error:%@",peripheral.name,[error description]);
    [JL_Tools post:kQCY_BLE_ERROR Object:@(4006)];
}

#pragma mark - 设备服务回调
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error
{
    if (error) { NSLog(@"Err: Discovered services fail."); return; }
    
    for (CBService *service in peripheral.services) {
        NSLog(@"BLE Service ---> %@",service.UUID.UUIDString);
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

#pragma mark - 设备特征回调
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service
             error:(nullable NSError *)error
{
    if (error) { NSLog(@"Err: Discovered Characteristics fail."); return; }
    
    /*--- JLSDK ADD ---*/
    [self.mAssist assistDiscoverCharacteristicsForService:service Peripheral:peripheral];
}


#pragma mark - 更新通知特征的状态
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(nonnull CBCharacteristic *)characteristic
             error:(nullable NSError *)error
{
    if (error) { NSLog(@"Err: Update NotificationState For Characteristic fail."); return; }
    
    /*--- JLSDK ADD ---*/
    [self.mAssist assistUpdateCharacteristic:characteristic
                                  Peripheral:peripheral
                                      Result:^(BOOL isPaired) {
        if (isPaired == YES) {
            [JL_Tools setUser:peripheral.identifier.UUIDString forKey:kUUID_BLE_LAST];
            
            self->_mBlePeripheral = peripheral;
            /*--- UI配对成功 ---*/
            [JL_Tools post:kQCY_BLE_PAIRED Object:peripheral];
        }else{
            [self->bleManager cancelPeripheralConnection:peripheral];
        }
    }];
}


#pragma mark - 设备返回的数据 GET
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    if (error) { NSLog(@"Err: receive data fail."); return; }

    /*--- JLSDK ADD ---*/
    [self.mAssist assistUpdateValueForCharacteristic:characteristic];
}

#pragma mark - 设备断开连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral
                 error:(nullable NSError *)error
{
    NSLog(@"BLE Disconnect ---> Device %@ error:%d",peripheral.name,(int)error.code);
    self.mBlePeripheral = nil;
    
    /*--- JLSDK ADD ---*/
    [self.mAssist assistDisconnectPeripheral:peripheral];
    
    /*--- UI刷新，设备断开 ---*/
    [JL_Tools post:kQCY_BLE_DISCONNECTED Object:peripheral];
}

@end


@implementation QCY_Entity
- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    QCY_Entity *entity   = [[self class] allocWithZone:zone];
    entity.mRSSI        = self.mRSSI;
    entity.mPeripheral  = self.mPeripheral;
    entity.mName        = self.mName;
    return entity;
}
@end
