//
//  FindDeviceWithBluetoothManagerExample.m
//  WatchProtocolSDK-ObjC Examples
//
//  Created by Claude on 2026/01/27.
//  Copyright © 2026 Huaxin. All rights reserved.
//
//  🎯 功能演示：通过 WPBluetoothManager 使用查找设备功能
//  📝 说明：本示例展示如何使用 WPBluetoothManager 提供的查找设备 API
//

#import <Foundation/Foundation.h>
#import "WPBluetoothManager.h"

@interface FindDeviceExample : NSObject <WPBluetoothManagerDelegate>

@property (nonatomic, strong) WPBluetoothManager *bluetoothManager;

@end

@implementation FindDeviceExample

- (instancetype)init {
    self = [super init];
    if (self) {
        // 获取蓝牙管理器实例
        _bluetoothManager = [WPBluetoothManager sharedInstance];
        _bluetoothManager.delegate = self;

        // 初始化蓝牙
        [_bluetoothManager initCentral];
    }
    return self;
}

#pragma mark - 示例 1：基础查找

/**
 * 最简单的用法：查找手环
 */
- (void)example1_basicFind {
    NSLog(@"📝 示例 1: 基础查找");

    // 检查设备是否已连接
    if (!self.bluetoothManager.isConnected) {
        NSLog(@"❌ 设备未连接，请先连接设备");
        return;
    }

    // 开始查找
    [self.bluetoothManager findDeviceWithCompletion:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"✅ 查找指令已发送，手环应该在震动");
            NSLog(@"💡 提示：请留意周围的震动声");
        } else {
            NSLog(@"❌ 查找失败: %@", error.localizedDescription);
        }
    }];
}

#pragma mark - 示例 2：自动停止查找

/**
 * 查找 5 秒后自动停止
 */
- (void)example2_findWithAutoStop {
    NSLog(@"📝 示例 2: 自动停止查找（5 秒）");

    [self.bluetoothManager findDeviceWithDuration:5.0 completion:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"✅ 查找已自动结束");
        } else {
            NSLog(@"❌ 查找失败: %@", error.localizedDescription);
        }
    }];
}

#pragma mark - 示例 3：手动停止查找

/**
 * 开始查找，然后在 3 秒后手动停止
 */
- (void)example3_manualStop {
    NSLog(@"📝 示例 3: 手动停止查找");

    // 开始查找
    [self.bluetoothManager findDeviceWithCompletion:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"✅ 开始查找");

            // 3 秒后手动停止
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self.bluetoothManager stopFindDeviceWithCompletion:^(BOOL stopSuccess, NSError *stopError) {
                    if (stopSuccess) {
                        NSLog(@"⏹ 已手动停止查找");
                    }
                }];
            });
        }
    }];
}

#pragma mark - 示例 4：UI 状态管理

/**
 * 根据查找状态动态更新 UI
 */
- (void)example4_uiStateManagement {
    NSLog(@"📝 示例 4: UI 状态管理");

    // 模拟按钮点击事件
    if (self.bluetoothManager.isFindingDevice) {
        // 正在查找中，点击停止
        NSLog(@"🔴 当前正在查找中，准备停止...");

        [self.bluetoothManager stopFindDeviceWithCompletion:^(BOOL success, NSError *error) {
            if (success) {
                NSLog(@"⏹ 已停止查找");
                [self updateButtonTitle];
            }
        }];
    } else {
        // 未在查找中，点击开始查找
        NSLog(@"🟢 当前未在查找，准备开始...");

        [self.bluetoothManager findDeviceWithDuration:10.0 completion:^(BOOL success, NSError *error) {
            if (success) {
                NSLog(@"✅ 查找完成（10秒后自动停止）");
                [self updateButtonTitle];
            } else {
                NSLog(@"❌ 查找失败: %@", error.localizedDescription);
            }
        }];
    }
}

- (void)updateButtonTitle {
    if (self.bluetoothManager.isFindingDevice) {
        NSLog(@"🔴 按钮文字应更新为：停止查找");
    } else {
        NSLog(@"🟢 按钮文字应更新为：查找设备");
    }
}

#pragma mark - 示例 5：完整的查找流程（推荐）

/**
 * 完整的查找流程，包含连接检查、状态管理、错误处理
 */
- (void)example5_completeFlow {
    NSLog(@"📝 示例 5: 完整的查找流程");

    // 1. 检查蓝牙状态
    if (self.bluetoothManager.isBluetoothPoweredOff) {
        NSLog(@"❌ 蓝牙未开启，请先打开蓝牙");
        return;
    }

    // 2. 检查设备连接状态
    if (!self.bluetoothManager.isConnected) {
        NSLog(@"⚠️ 设备未连接，尝试连接...");

        // 这里应该先连接设备
        // [self.bluetoothManager connectToDeviceWithMac:@"XX:XX:XX:XX:XX:XX"];
        return;
    }

    // 3. 检查当前查找状态
    if (self.bluetoothManager.isFindingDevice) {
        NSLog(@"ℹ️ 已在查找中，无需重复操作");
        return;
    }

    // 4. 开始查找（推荐使用自动停止）
    NSLog(@"🔍 开始查找设备...");

    [self.bluetoothManager findDeviceWithDuration:10.0 completion:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"✅ 查找完成");
        } else {
            // 5. 错误处理
            NSLog(@"❌ 查找失败: %@", error.localizedDescription);

            // 根据错误码进行不同的处理
            NSString *errorDomain = @"com.huaxin.watchprotocolsdk.finddevice";
            if ([error.domain isEqualToString:errorDomain]) {
                switch (error.code) {
                    case 1001:
                        NSLog(@"💡 提示：请先连接设备");
                        break;
                    case 1002:
                        NSLog(@"💡 提示：指令发送失败，请重试");
                        break;
                    case 1003:
                        NSLog(@"💡 提示：请先打开蓝牙");
                        break;
                }
            }
        }
    }];
}

#pragma mark - 示例 6：实际应用场景

/**
 * 场景：设备列表页的快捷查找
 */
- (void)example6_deviceListQuickFind {
    NSLog(@"📝 示例 6: 设备列表快捷查找");

    // 模拟设备列表中的"查找"按钮点击
    NSString *deviceMac = @"AA:BB:CC:DD:EE:FF";

    // 1. 先连接设备（如果未连接）
    if (!self.bluetoothManager.isConnected) {
        NSLog(@"📱 连接设备: %@", deviceMac);
        [self.bluetoothManager connectToDeviceWithMac:deviceMac];

        // 2. 等待连接成功后查找（实际应用中应监听连接成功的代理回调）
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self performQuickFind];
        });
    } else {
        // 已连接，直接查找
        [self performQuickFind];
    }
}

- (void)performQuickFind {
    // 快速查找：5 秒后自动停止
    [self.bluetoothManager findDeviceWithDuration:5.0 completion:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"✅ 快速查找完成");
        } else {
            NSLog(@"❌ 快速查找失败: %@", error.localizedDescription);
        }
    }];
}

#pragma mark - WPBluetoothManagerDelegate

- (void)didConnectPeripheral:(WPPeripheralInfo *)peripheralInfo {
    NSLog(@"🔗 设备已连接: %@", peripheralInfo.peripheral.name);
}

- (void)didDisconnectPeripheral:(WPPeripheralInfo *)peripheralInfo error:(NSError *)error {
    NSLog(@"🔌 设备已断开: %@", peripheralInfo.peripheral.name);

    // 设备断开时，如果正在查找，应停止查找
    if (self.bluetoothManager.isFindingDevice) {
        [self.bluetoothManager stopFindDeviceWithCompletion:nil];
    }
}

@end

#pragma mark - 运行示例

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSLog(@"🚀 WPBluetoothManager 查找设备功能示例");
        NSLog(@"========================================");

        FindDeviceExample *example = [[FindDeviceExample alloc] init];

        // 等待蓝牙初始化
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            // 运行示例（实际使用时，应在设备连接后调用）

            NSLog(@"\n");
            [example example1_basicFind];

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                NSLog(@"\n");
                [example example2_findWithAutoStop];
            });

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 8 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                NSLog(@"\n");
                [example example3_manualStop];
            });

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 12 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                NSLog(@"\n");
                [example example4_uiStateManagement];
            });

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 24 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                NSLog(@"\n");
                [example example5_completeFlow];
            });
        });

        // 让程序运行足够长的时间以完成所有示例
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:40]];
    }
    return 0;
}

/*
 💡 使用建议：

 1. **基础用法**（最简单）
    - 适用场景：设备已连接，只需快速查找
    - 示例：example1_basicFind

 2. **自动停止**（推荐）
    - 适用场景：避免手环长时间震动耗电
    - 示例：example2_findWithAutoStop

 3. **手动控制**（灵活）
    - 适用场景：用户可随时停止查找
    - 示例：example3_manualStop

 4. **状态管理**（UI 集成）
    - 适用场景：需要动态更新按钮文字/颜色
    - 示例：example4_uiStateManagement

 5. **完整流程**（生产环境）
    - 适用场景：需要完善的错误处理和状态检查
    - 示例：example5_completeFlow

 ⚠️ 注意事项：
 - 所有查找方法都会自动检查设备连接状态
 - 重复调用会被自动忽略
 - 页面销毁时无需手动清理（SDK 内部管理）
 - 建议使用自动停止（3-10 秒），避免耗电
 */
