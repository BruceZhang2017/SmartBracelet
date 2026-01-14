//
//  ExampleViewController.m
//  WatchProtocolSDK-ObjC Example
//
//  Created by Claude on 2026/01/12.
//  Copyright © 2026 Huaxin. All rights reserved.
//

#import "ExampleViewController.h"
#import <WatchProtocolSDK/WatchProtocolSDK.h>
#import <CoreBluetooth/CoreBluetooth.h>

// MARK: - 数据存储实现示例
@interface ExampleHealthDataStorage : NSObject <WPHealthDataStorageProtocol>
@end

@implementation ExampleHealthDataStorage

- (void)saveStepData:(WPStepData *)data {
    NSLog(@"💾 保存步数数据: %ld steps on %@", (long)data.step, data.date);
    // TODO: 实际项目中应保存到数据库（如 CoreData, Realm 等）
}

- (void)saveSleepData:(WPSleepData *)data {
    NSLog(@"💾 保存睡眠数据: 深睡=%ld, 浅睡=%ld, 清醒=%ld",
          (long)data.deep, (long)data.light, (long)data.awake);
    // TODO: 实际项目中应保存到数据库
}

- (void)saveHeartData:(WPHeartData *)data {
    NSLog(@"💾 保存心率数据: %ld bpm at %ld", (long)data.heart, (long)data.time);
    // TODO: 实际项目中应保存到数据库
}

- (void)saveOxygenData:(WPOxygenData *)data {
    NSLog(@"💾 保存血氧数据: %ld%% at %ld", (long)data.oxygen, (long)data.time);
    // TODO: 实际项目中应保存到数据库
}

- (void)saveBloodPressureData:(WPBloodPressureData *)data {
    NSLog(@"💾 保存血压数据: %ld/%ld mmHg at %ld",
          (long)data.max, (long)data.min, (long)data.time);
    // TODO: 实际项目中应保存到数据库
}

@end

// MARK: - 主视图控制器
@interface ExampleViewController () <WPBluetoothManagerDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIButton *scanButton;
@property (nonatomic, strong) UILabel *statusLabel;

@property (nonatomic, strong) ExampleHealthDataStorage *dataStorage;
@property (nonatomic, strong) NSMutableArray<WPPeripheralInfo *> *discoveredDevices;
@property (nonatomic, strong) WPBluetoothWatchDevice *connectedDevice;

@end

@implementation ExampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"WatchProtocolSDK Demo";
    self.view.backgroundColor = [UIColor whiteColor];

    // 1. 初始化数据存储
    self.dataStorage = [[ExampleHealthDataStorage alloc] init];
    [[WPDeviceManager sharedInstance] initializeWithStorage:self.dataStorage];

    // 2. 初始化蓝牙管理器
    [[WPBluetoothManager sharedInstance] initCentral];
    [WPBluetoothManager sharedInstance].delegate = self;

    // 3. 初始化设备列表
    self.discoveredDevices = [NSMutableArray array];

    // 4. 设置 UI
    [self setupUI];

    // 5. 重新加载已保存的设备
    [[WPDeviceManager sharedInstance] reloadDevices];
}

- (void)setupUI {
    // 状态标签
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 100, self.view.bounds.size.width - 40, 40)];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.textColor = [UIColor grayColor];
    self.statusLabel.font = [UIFont systemFontOfSize:14];
    self.statusLabel.text = @"准备就绪";
    [self.view addSubview:self.statusLabel];

    // 扫描按钮
    self.scanButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.scanButton.frame = CGRectMake(20, 150, self.view.bounds.size.width - 40, 44);
    [self.scanButton setTitle:@"开始扫描设备" forState:UIControlStateNormal];
    [self.scanButton addTarget:self action:@selector(scanButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.scanButton];

    // 设备列表
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 210, self.view.bounds.size.width, self.view.bounds.size.height - 210) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"DeviceCell"];
    [self.view addSubview:self.tableView];
}

// MARK: - 按钮事件

- (void)scanButtonTapped:(UIButton *)sender {
    if ([[WPBluetoothManager sharedInstance] isScanning]) {
        // 停止扫描
        [[WPBluetoothManager sharedInstance] stopScanning];
        [sender setTitle:@"开始扫描设备" forState:UIControlStateNormal];
        self.statusLabel.text = @"已停止扫描";
    } else {
        // 开始扫描
        [self.discoveredDevices removeAllObjects];
        [self.tableView reloadData];

        [[WPBluetoothManager sharedInstance] startScanning:YES];
        [sender setTitle:@"停止扫描" forState:UIControlStateNormal];
        self.statusLabel.text = @"正在扫描设备...";
    }
}

// MARK: - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.discoveredDevices.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DeviceCell" forIndexPath:indexPath];

    WPPeripheralInfo *info = self.discoveredDevices[indexPath.row];
    cell.textLabel.text = info.peripheral.name ?: @"未知设备";
    cell.detailTextLabel.text = info.macAddress;

    return cell;
}

// MARK: - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    WPPeripheralInfo *info = self.discoveredDevices[indexPath.row];

    // 停止扫描
    [[WPBluetoothManager sharedInstance] stopScanning];
    [self.scanButton setTitle:@"开始扫描设备" forState:UIControlStateNormal];

    // 连接设备
    self.statusLabel.text = [NSString stringWithFormat:@"正在连接 %@...", info.peripheral.name ?: @"设备"];
    [[WPBluetoothManager sharedInstance] connectToPeripheral:info.peripheral];
}

// MARK: - WPBluetoothManagerDelegate

- (void)onBleReady {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.statusLabel.text = @"蓝牙已准备就绪";
        NSLog(@"✅ 蓝牙已准备就绪");
    });
}

- (void)didDiscoverPeripheral:(WPPeripheralInfo *)peripheralInfo {
    dispatch_async(dispatch_get_main_queue(), ^{
        // 检查是否已存在
        BOOL exists = NO;
        for (WPPeripheralInfo *info in self.discoveredDevices) {
            if ([info.peripheral.identifier isEqual:peripheralInfo.peripheral.identifier]) {
                exists = YES;
                break;
            }
        }

        if (!exists) {
            [self.discoveredDevices addObject:peripheralInfo];
            [self.tableView reloadData];

            NSLog(@"🔍 发现设备: %@ [%@]",
                  peripheralInfo.peripheral.name ?: @"未知",
                  peripheralInfo.macAddress);
        }

        self.statusLabel.text = [NSString stringWithFormat:@"已发现 %ld 个设备", (long)self.discoveredDevices.count];
    });
}

- (void)didConnectPeripheral:(CBPeripheral *)peripheral {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.statusLabel.text = [NSString stringWithFormat:@"✅ 已连接到 %@", peripheral.name ?: @"设备"];

        // 创建设备对象
        self.connectedDevice = [[WPBluetoothWatchDevice alloc] init];
        self.connectedDevice.deviceName = peripheral.name;
        self.connectedDevice.mac = peripheral.identifier.UUIDString;

        // 保存到沙盒
        [WPBluetoothWatchDevice saveToSandbox:self.connectedDevice];

        NSLog(@"✅ 设备连接成功: %@", peripheral.name);

        // TODO: 可以在这里发送指令获取设备信息
    });
}

- (void)didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error) {
            self.statusLabel.text = [NSString stringWithFormat:@"❌ 连接断开: %@", error.localizedDescription];
            NSLog(@"❌ 设备断开: %@ - %@", peripheral.name, error.localizedDescription);
        } else {
            self.statusLabel.text = @"设备已断开";
            NSLog(@"🔌 设备已断开: %@", peripheral.name);
        }

        self.connectedDevice = nil;
    });
}

- (void)receiveData:(NSData *)data {
    NSLog(@"📩 接收到数据 (%ld bytes): %@", (long)data.length, data);

    // TODO: 根据协议解析数据
    // 示例：解析健康数据并保存
    // [self parseAndSaveHealthData:data];
}

- (void)sentData {
    NSLog(@"📤 数据发送成功");
}

// MARK: - 辅助方法

- (void)dealloc {
    [[WPBluetoothManager sharedInstance] disconnect];
}

@end
