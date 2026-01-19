//
//  WPPeripheralInfo+WatchDevice.m
//  WatchProtocolSDK-ObjC
//
//  Created by Claude on 2026/01/19.
//  Copyright © 2026 Huaxin. All rights reserved.
//

#import "WPPeripheralInfo+WatchDevice.h"

@implementation WPPeripheralInfo (WatchDevice)

- (WPBluetoothWatchDevice *)toWatchDevice {
    return [WPBluetoothWatchDevice deviceFromPeripheralInfo:self];
}

- (void)saveToSandbox {
    [WPBluetoothWatchDevice savePeripheralInfoToSandbox:self];
}

@end
