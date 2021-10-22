//
//  OTAUpgradeViewController.m
//  PHY
//
//  Created by Han on 2018/10/9.
//  Copyright © 2018年 phy. All rights reserved.
//

#import "OTAUpgradeViewController.h"
#import "OTAListCell.h"
#import "OTCModel.h"
#import "MBProgressHUD.h"
#import "ProgressView.h"
#import "OTASDK.h"
#import "ColorDefine.h"

@interface OTAUpgradeViewController ()<UIDocumentInteractionControllerDelegate,JCBluetoothManagerDelegate,MBProgressHUDDelegate,OTAManagerDelegate> {
    
    NSMutableArray *fileList;
    UIDocumentInteractionController *_documentController; //文档交互控制器
    NSString *docDirs;
    
}

@property (strong, nonatomic) ProgressView *progressView;
@property (assign, nonatomic) float progressValue;//完成进度
@property (weak, nonatomic) JCBluetoothManager *bluetoothManager;
@property (assign, nonatomic) BOOL isFirstConnectionOTA;//判断首次连接的网络是否是OTA
@property (strong, nonatomic) NSString *OTAOrAPPType;//重新连接蓝牙时是OTA模式还是应用模式

@end

@implementation OTAUpgradeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"OTA";
    
    self.isFirstConnectionOTA = false;
    [self setUpBluetooth];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.progressValue = 0;
    [OTAManager shareOTAManager].delegate = self;
   
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self startOTAUpdate];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.progressView != nil) {
        [self.progressView remove];
        self.progressView = nil;
        NSString* filePath = [[NSBundle mainBundle] pathForResource:@"SmartBand_PHY_ota" ofType:@"hex"];
        [OTAManager shareOTAManager].filePath = filePath;
    }
    [OTAManager shareOTAManager].delegate = nil;
    
}

- (void)popVC {
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - UIDocumentInteractionControllerDelegate
- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller {
    //注意：此处要求的控制器，必须是它的页面view，已经显示在window之上了
    return self.navigationController;
}

#pragma mark - OTA部分代码
- (void)startOTAUpdate{
    NSLog(@"startOTAUpdate ~~");
    self.progressView = [[ProgressView alloc] init];
    [self.progressView setState:KMProgressView_Begin withProgress:0];
    [self.progressView showAt:self.view];
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"SmartBand_PHY_ota" ofType:@"hex"];
    [OTAManager shareOTAManager].filePath = filePath;
    
    if ([OTAManager shareOTAManager].isSLB) {
        [[OTAManager shareOTAManager] ParseBinFile];
    }else if([_bluetoothManager.currentPeripheral.name hasSuffix:@"OTA"]) {
        self.isFirstConnectionOTA = true;
        if([[OTAManager shareOTAManager].filePath hasSuffix:@"hexe16"]){
            [[OTAManager shareOTAManager] securityOTAStart];
        }else {
            [[OTAManager shareOTAManager] updateOTAFirmwareConfirmPath];
        }
       
    } else {
        [[OTAManager shareOTAManager] startOTA];//开始OTA
        self.OTAOrAPPType = @"OTA";
    }

}


#pragma mark - 蓝牙及相关设置初始化
- (void)setUpBluetooth {
    _bluetoothManager = [JCBluetoothManager shareCBCentralManager];
    _bluetoothManager.delegate = self;
    
}

- (void)updateOTAProgressDataback:(JCBluetoothManager *)manager feedBackInfo:(float)progressValue {
//    NSLog(@"进度条的值，progressValue：%.2f",progressValue);
    self.progressValue = progressValue;
    if (progressValue > 99.99) {
        return;
    }
    if (progressValue >= 100.0) {
        if (progressValue > 100.0) {
            return;
        }
        [[OTAManager shareOTAManager] reRoot];
    } else {
//        NSLog(@"进度条，progressValue：%.2f",progressValue);
        [self.progressView setState:KMProgressView_Uploading withProgress:progressValue/100];
    }
}

-(void)updateOTAProgressDataback:(JCBluetoothManager *)manager isComplete:(BOOL)isComplete {
    NSLog(@"升级完成~~！");
    [self.progressView setState:KMProgressView_Completed withProgress:1.0];
    [self.progressView remove];
    self.progressView = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self popVC];
    });
}

#pragma mark - JCBluetoothManagerDelegate

//reboot成功之后
-(void)reBootOTASuccess:(JCBluetoothManager *)manager feedBackInfo:(BOOL)result reconnectBluetoothType:(NSString *)OTAOrAPPType {
    if (result) {
        self.OTAOrAPPType = OTAOrAPPType;
        [_bluetoothManager disConnectToPeripheral];//断开蓝牙
        //扫描设备
        if (_bluetoothManager.bluetoothState == BluetoothOpenStateIsOpen && _bluetoothManager.currentPeripheral == nil) {
            [_bluetoothManager reScan];
        }
    }
}

- (void)bluetoothManager:(nullable JCBluetoothManager *)manager didDisconnectPeripheral:(nullable CBPeripheral *)peripheral error:(nullable NSError *)error {
    NSLog(@"知道断开连接了");
    [self.progressView setState:KMProgressView_Failed withProgress:0.0];
    [self.progressView remove];
    self.progressView = nil;
    NSString *tip = [NSString stringWithFormat:@"与外设连接断开,请退出重试!"];
    [self hudSetting:tip];
}

//升级错误码处理
- (void)updateOTAErrorCallBack:(nullable OTAManager *) manager
                     errorCode:(NSUInteger)errorCode {

    if (self.progressView != nil) {
        [self.progressView remove];
        self.progressView = nil;
    }
//     ota服务特征值(读取到的)data: <CBCharacteristic: 0x281758c00, UUID = 5833FF03-9B8B-5191-6142-22A4536EF123, properties = 0x10, value = {length = 1, bytes = 0x64}, notifying = YES>
    switch (errorCode) {
        case 0x64: {
            NSString *tip = [NSString stringWithFormat:@"文件解析错误"];
            [self hudSetting:tip];
        }
            break;
        case 0x65: {
            NSString *tip = [NSString stringWithFormat:@"进入OTA状态后连接错误"];
            [self hudSetting:tip];
        }
            break;
        case 0x66: {
            NSString *tip = [NSString stringWithFormat:@"OTA数据发送service未找到"];
            [self hudSetting:tip];
        }
            break;
        case 0x67: {
            NSString *tip = [NSString stringWithFormat:@"OTA命令发送service未找到"];
            [self hudSetting:tip];
        }
            break;
        case 0x68: {
            NSString *tip = [NSString stringWithFormat:@"OTA数据写入错误"];
            [self hudSetting:tip];
        }
            break;
        case 0x69: {
//            NSString *tip = [NSString stringWithFormat:@"OTA响应错误"];
//            [self hudSetting:tip];
        }
            break;
        case 0x6a: {
            NSString *tip = [NSString stringWithFormat:@"断开连接"];
            [self hudSetting:tip];
        }
            break;
        case 0x6b: {
            NSString *tip = [NSString stringWithFormat:NSLocalizedString(@"mine_unconnect", nil)];
            [self hudSetting:tip];
        }
            break;
        case 0x6c: {
            NSString *tip = [NSString stringWithFormat:@"设备不在OTA状态"];
            [self hudSetting:tip];
        }
            break;
        case 0x6887: {
            NSString *tip = [NSString stringWithFormat:@"检测到丢包"];
            [self hudSetting:tip];
        }
            break;
        case 0x666: {
            NSString *tip = [NSString stringWithFormat:@"完成72指令验证"];
            [self hudSetting:tip];
        }
            break;
        case 0x777: {
            NSString *tip = [NSString stringWithFormat:@"收到72指令后，验证有问题"];
            [self hudSetting:tip];
            UIAlertController *alertC = [UIAlertController alertControllerWithTitle:nil message:manager.bleKeyStr preferredStyle:UIAlertControllerStyleAlert];

            UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"mine_confirm", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            }];
            [alertC addAction:action];
            [self presentViewController:alertC animated:YES completion:nil];
        }
            break;
        default:{
            NSString *tip = [NSString stringWithFormat:NSLocalizedString(@"mine_device_ota_fail", nil)];
            [self hudSetting:tip];
        }
            break;

    }
}

//发现设备
- (void)foundPeripheral:(JCBluetoothManager *)manager peripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    //应用模式下根据UUID自动连接
    if ([self.OTAOrAPPType isEqualToString:@"APP"]) {
        if (self.isFirstConnectionOTA) {
            //首次进入已经连接了OTA模式的蓝牙，提醒手动连接
            self.isFirstConnectionOTA = NO;
            UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"device_tip", nil) message:@"请手动连接设备" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"mine_confirm", nil) style:UIAlertActionStyleDefault handler:nil];
            [alertC addAction:action];
            [self presentViewController:alertC animated:YES completion:nil];
            [self popVC];
            return;
        }
        if ([self.originalUUID isEqualToString:peripheral.identifier.UUIDString]) {
            [_bluetoothManager connectToPeripheral:peripheral];
        }

    } else if ([self.OTAOrAPPType isEqualToString:@"OTA"]) {
        // 2 -解析广播数据
        NSObject *value = [advertisementData objectForKey:@"kCBAdvDataManufacturerData"];
        NSString *macStr = nil;
        if (![value isKindOfClass: [NSArray class]]){
            const char *valueString = [[value description] cStringUsingEncoding: NSUTF8StringEncoding];
            if (valueString != NULL) {
                
                //获得ota模式下的Mac地址
                NSString *tempStr = [NSString stringWithFormat:@"%s",valueString];
                macStr = [JCDataConvert getOriginalToDataString:tempStr]; //获取到的mac地址
                macStr = [JCDataConvert getPeripheralMac:macStr];
                
                const char *pConstChar = [self.mscAddress UTF8String];
                tempStr = [NSString stringWithFormat:@"%s",pConstChar];
                NSString *oldMacStr = [JCDataConvert getOriginalToDataString:tempStr];

                NSData *macd = [JCDataConvert hexToBytes:oldMacStr];
                //取前两位转十进制
                NSUInteger respond = [JCDataConvert oneByteToDecimalUint:[macd subdataWithRange:NSMakeRange(0, 1)]];//16进制转10进制

                if ([self.OTAOrAPPType isEqualToString:@"OTA"]) {
                    respond ++;
                }

                //转十六进制
                NSString *firstStr = [JCDataConvert ToHex:(int)respond];
                //替换
                NSString *replacedStr = [NSString stringWithFormat:@"%@%@",firstStr,[oldMacStr substringFromIndex:2]];
                replacedStr = [JCDataConvert convertOriginalToMacString:replacedStr];

                if ([replacedStr isEqualToString:macStr]) {
                    NSLog(@"重新连接APP模式首位地址前：%@",macStr);
                    [_bluetoothManager connectToPeripheral:peripheral];
                }else if([peripheral.name isEqualToString:@"PPlusOTA"]||[peripheral.name isEqualToString:@"LefunOTA"]){
//                    NSLog(@"因为iOS无法获取设备MAC地址， OTA模式下BLE的广播数据必须携带MAC地址， 固件需要修改，跟APP无关！");
                    [_bluetoothManager connectToPeripheral:peripheral];
                }
            }
        }
    }
}

//连接蓝牙成功调用
- (void)bluetoothManager:(JCBluetoothManager *)manager didSucceedConectPeripheral:(CBPeripheral *)peripheral {
    [_bluetoothManager stopScan];

    //更新系统时间
    if ([self.OTAOrAPPType isEqualToString:@"APP"]) {
        NSString *currentDate = [self getDate];
        [[OTAManager shareOTAManager] updateSystemTime:currentDate];
        
        [self popVC];
        NSLog(@"本次操作完成，并已经连接设备");
    }
    //开始上传文件
    if ([self.OTAOrAPPType isEqualToString:@"OTA"]) {
        NSString* filePath = [[NSBundle mainBundle] pathForResource:@"SmartBand_PHY_ota" ofType:@"hex"];
        [OTAManager shareOTAManager].filePath = filePath;
    }
}


- (NSString *)getDate {
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:@"YYMMddhhmmss"];
    NSString *DateTime = [formatter stringFromDate:date];

    NSString *yearStr = [DateTime substringWithRange:NSMakeRange(0,2)];
    NSString *monthStr = [DateTime substringWithRange:NSMakeRange(2,2)];
    NSString *dayStr = [DateTime substringWithRange:NSMakeRange(4,2)];
    NSString *hourStr = [DateTime substringWithRange:NSMakeRange(6,2)];
    NSString *miniteStr = [DateTime substringWithRange:NSMakeRange(8,2)];
    NSString *secStr = [DateTime substringWithRange:NSMakeRange(10,2)];

    NSString *data = [NSString stringWithFormat:@"%@%@%@%@%@%@",[JCDataConvert ToHex:[yearStr intValue]],[JCDataConvert ToHex:[monthStr intValue]],[JCDataConvert ToHex:[dayStr intValue]],[JCDataConvert ToHex:[hourStr intValue]],[JCDataConvert ToHex:[miniteStr intValue]],[JCDataConvert ToHex:[secStr intValue]]];
    NSLog(@"%@============年-月-日  时：分：秒=====================",data);
    return data;
}

- (void)hudSetting:(NSString *)tip {
    dispatch_async(dispatch_get_main_queue(), ^{
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = tip;
        hud.label.numberOfLines = 0;
        hud.delegate = self;
        hud.removeFromSuperViewOnHide = YES;
        [hud hideAnimated:YES afterDelay:5];
    });
}


@end
