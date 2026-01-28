//
//  CommandLogicComparisonExample.m
//  WatchProtocolSDK-ObjC Examples
//
//  Created by Claude on 2026/01/27.
//  Copyright © 2026 Huaxin. All rights reserved.
//
//  🎯 功能演示：电量查询 vs 查找设备 逻辑对比
//  📝 说明：展示两种指令发送方式的差异和使用场景
//

#import <Foundation/Foundation.h>
#import "WPBluetoothManager.h"

@interface CommandComparisonExample : NSObject <WPBluetoothManagerDelegate>

@property (nonatomic, strong) WPBluetoothManager *bluetoothManager;

@end

@implementation CommandComparisonExample

- (instancetype)init {
    self = [super init];
    if (self) {
        _bluetoothManager = [WPBluetoothManager sharedInstance];
        _bluetoothManager.delegate = self;
        [_bluetoothManager initCentral];
    }
    return self;
}

#pragma mark - 📊 对比示例

/**
 * 示例 1：电量查询（旧模式 - 无完成回调）
 */
- (void)example1_batteryQuery_OldMode {
    NSLog(@"\n=== 示例 1: 电量查询（旧模式）===");

    // 调用电量查询
    [self.bluetoothManager queryBatteryLevel];

    // ❌ 问题：无法立即知道指令是否发送成功
    NSLog(@"⚠️ 指令已发送？不知道！");
    NSLog(@"⚠️ 只能等待代理回调来确认...");

    // 用户体验：
    // - 不知道指令是否发送成功
    // - 无法立即显示加载状态
    // - 无法处理发送失败的情况
}

/**
 * 示例 2：查找设备（新模式 - 有完成回调）
 */
- (void)example2_findDevice_NewMode {
    NSLog(@"\n=== 示例 2: 查找设备（新模式）===");

    // 调用查找设备
    [self.bluetoothManager findDeviceWithCompletion:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"✅ 指令发送成功！");
            NSLog(@"✅ 可以立即更新 UI：显示'正在查找...'");
        } else {
            NSLog(@"❌ 指令发送失败：%@", error.localizedDescription);
            NSLog(@"❌ 可以立即更新 UI：显示错误提示");

            // 根据错误码处理
            switch (error.code) {
                case 1001:
                    NSLog(@"💡 提示：请先连接设备");
                    break;
                case 1002:
                    NSLog(@"💡 提示：发送失败，请重试");
                    break;
                case 1003:
                    NSLog(@"💡 提示：请先打开蓝牙");
                    break;
            }
        }
    }];

    // 用户体验：
    // - 立即知道指令是否发送成功
    // - 可以立即显示加载状态或错误提示
    // - 可以根据错误码提供精准的用户引导
}

#pragma mark - 🔄 实际应用场景对比

/**
 * 场景 1：UI 按钮点击 - 电量查询（旧模式）
 */
- (void)scenario1_batteryButton_OldMode {
    NSLog(@"\n=== 场景 1: 电量按钮（旧模式）===");

    // 用户点击"查询电量"按钮
    NSLog(@"用户点击：查询电量");

    // ❌ 无法立即给用户反馈
    [self.bluetoothManager queryBatteryLevel];

    // ❌ UI 处理很尴尬
    NSLog(@"❌ UI 不知道如何更新：");
    NSLog(@"   - 显示加载中？但不确定指令是否发送成功");
    NSLog(@"   - 不显示？用户感觉点击无反应");
    NSLog(@"   - 只能猜测性地显示'正在查询...'");

    // ❌ 如果发送失败，用户会一直等待
    NSLog(@"❌ 如果蓝牙未开启或设备未连接，用户会一直等待代理回调（永远不会来）");
}

/**
 * 场景 2：UI 按钮点击 - 查找设备（新模式）
 */
- (void)scenario2_findButton_NewMode {
    NSLog(@"\n=== 场景 2: 查找按钮（新模式）===");

    // 用户点击"查找设备"按钮
    NSLog(@"用户点击：查找设备");

    // ✅ 可以立即给用户反馈
    [self.bluetoothManager findDeviceWithCompletion:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"✅ UI 更新：显示'手环正在震动...'");
            // [self.statusLabel setText:@"手环正在震动..."];
            // [self.activityIndicator startAnimating];
        } else {
            NSLog(@"❌ UI 更新：显示错误提示 '%@'", error.localizedDescription);
            // [self showAlert:error.localizedDescription];
        }
    }];

    // ✅ UI 处理很清晰
    NSLog(@"✅ UI 可以准确反映操作状态");
}

#pragma mark - 🎨 UI 集成对比

/**
 * 场景 3：带加载状态的按钮 - 电量查询（旧模式）
 */
- (void)scenario3_loadingButton_BatteryQuery_OldMode {
    NSLog(@"\n=== 场景 3: 加载状态按钮 - 电量查询（旧模式）===");

    // 模拟按钮点击
    // [self.queryButton setEnabled:NO];
    NSLog(@"🔘 禁用按钮");

    // ❌ 只能猜测性地显示加载状态
    // [self.activityIndicator startAnimating];
    NSLog(@"⚠️ 显示加载中（但不确定是否成功）");

    [self.bluetoothManager queryBatteryLevel];

    // ❌ 何时恢复按钮？不确定！
    // 只能等待代理回调或设置一个超时时间
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        // [self.activityIndicator stopAnimating];
        // [self.queryButton setEnabled:YES];
        NSLog(@"⚠️ 超时恢复按钮（但可能指令还没发送成功）");
    });
}

/**
 * 场景 4：带加载状态的按钮 - 查找设备（新模式）
 */
- (void)scenario4_loadingButton_FindDevice_NewMode {
    NSLog(@"\n=== 场景 4: 加载状态按钮 - 查找设备（新模式）===");

    // 模拟按钮点击
    // [self.findButton setEnabled:NO];
    NSLog(@"🔘 禁用按钮");

    // [self.activityIndicator startAnimating];
    NSLog(@"⏳ 显示加载中");

    [self.bluetoothManager findDeviceWithCompletion:^(BOOL success, NSError *error) {
        // ✅ 立即恢复按钮状态
        // [self.activityIndicator stopAnimating];
        // [self.findButton setEnabled:YES];
        NSLog(@"✅ 立即恢复按钮");

        if (success) {
            NSLog(@"✅ 显示成功状态：'正在查找...'");
            // [self.statusLabel setText:@"正在查找..."];
        } else {
            NSLog(@"❌ 显示错误状态：%@", error.localizedDescription);
            // [self showAlert:error.localizedDescription];
        }
    }];
}

#pragma mark - 💡 最佳实践对比

/**
 * 场景 5：完整的错误处理 - 电量查询（旧模式）
 */
- (void)scenario5_errorHandling_BatteryQuery_OldMode {
    NSLog(@"\n=== 场景 5: 错误处理 - 电量查询（旧模式）===");

    // ❌ 无法处理发送失败的情况
    [self.bluetoothManager queryBatteryLevel];

    // ❌ 只能在方法内部检查连接状态
    // 但如果发送失败（sendData 返回 NO），无法得知
    NSLog(@"❌ 无法处理以下情况：");
    NSLog(@"   1. 蓝牙未开启");
    NSLog(@"   2. sendData 返回 NO（写入失败）");
    NSLog(@"   3. 其他未知错误");
}

/**
 * 场景 6：完整的错误处理 - 查找设备（新模式）
 */
- (void)scenario6_errorHandling_FindDevice_NewMode {
    NSLog(@"\n=== 场景 6: 错误处理 - 查找设备（新模式）===");

    // ✅ 完整的错误处理
    [self.bluetoothManager findDeviceWithCompletion:^(BOOL success, NSError *error) {
        if (!success) {
            NSLog(@"❌ 操作失败：%@", error.localizedDescription);

            // 根据错误码进行精准处理
            NSString *errorDomain = @"com.huaxin.watchprotocolsdk.finddevice";
            if ([error.domain isEqualToString:errorDomain]) {
                switch (error.code) {
                    case 1001:
                        NSLog(@"💡 引导用户：请先连接设备");
                        // [self showConnectDeviceGuide];
                        break;

                    case 1002:
                        NSLog(@"💡 提示用户：发送失败，请重试");
                        // [self showRetryButton];
                        break;

                    case 1003:
                        NSLog(@"💡 引导用户：请打开蓝牙");
                        // [self showBluetoothSettingsGuide];
                        break;
                }
            }
        }
    }];

    NSLog(@"✅ 可以处理所有错误情况并提供精准引导");
}

#pragma mark - WPBluetoothManagerDelegate

- (void)didReceiveBatteryLevel:(NSInteger)batteryLevel isCharging:(BOOL)isCharging {
    NSLog(@"🔋 [代理回调] 接收到电量数据：%ld%% (充电中: %@)",
          (long)batteryLevel, isCharging ? @"是" : @"否");

    // 电量查询的结果只能通过这个代理方法获取
    // 用户需要等待设备响应（可能很久，也可能永远不会来）
}

@end

#pragma mark - 运行示例

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSLog(@"========================================");
        NSLog(@"📊 电量查询 vs 查找设备 逻辑对比");
        NSLog(@"========================================\n");

        CommandComparisonExample *example = [[CommandComparisonExample alloc] init];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [example example1_batteryQuery_OldMode];
        });

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [example example2_findDevice_NewMode];
        });

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [example scenario1_batteryButton_OldMode];
        });

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 7 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [example scenario2_findButton_NewMode];
        });

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 9 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [example scenario3_loadingButton_BatteryQuery_OldMode];
        });

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 15 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [example scenario4_loadingButton_FindDevice_NewMode];
        });

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 17 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [example scenario5_errorHandling_BatteryQuery_OldMode];
        });

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 19 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [example scenario6_errorHandling_FindDevice_NewMode];
        });

        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:25]];

        NSLog(@"\n========================================");
        NSLog(@"📝 总结");
        NSLog(@"========================================");
        NSLog(@"✅ 查找设备（新模式）优势：");
        NSLog(@"   1. 立即反馈发送结果");
        NSLog(@"   2. 完善的错误处理");
        NSLog(@"   3. 精准的用户引导");
        NSLog(@"   4. 更好的 UI 集成");
        NSLog(@"   5. 易于测试和维护");
        NSLog(@"");
        NSLog(@"❌ 电量查询（旧模式）问题：");
        NSLog(@"   1. 无法立即知道发送结果");
        NSLog(@"   2. 无法处理发送失败");
        NSLog(@"   3. UI 更新不确定");
        NSLog(@"   4. 用户体验差");
        NSLog(@"");
        NSLog(@"💡 建议：");
        NSLog(@"   将电量查询、心率测量等功能也升级为带完成回调的新模式");
    }
    return 0;
}

/*
 📊 核心差异总结

 ┌─────────────────────────────────────────────────────────────┐
 │ 特性对比                                                      │
 ├─────────────────────────────────────────────────────────────┤
 │                      电量查询      查找设备                    │
 ├─────────────────────────────────────────────────────────────┤
 │ 完成回调             ❌            ✅                          │
 │ 状态检查             简单          完善                         │
 │ 错误处理             简单          完善                         │
 │ 立即反馈             ❌            ✅                          │
 │ UI 集成              困难          简单                         │
 │ 用户体验             一般          优秀                         │
 │ 可测试性             一般          优秀                         │
 └─────────────────────────────────────────────────────────────┘

 💡 建议统一为查找设备的模式，提升整体 SDK 质量
 */
