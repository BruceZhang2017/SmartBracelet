# WatchProtocolSDK-ObjC Auto-Reconnect Guide

## 📖 Overview

This guide demonstrates how to implement auto-reconnect functionality in your third-party app: automatically reconnect to the last connected device when the app is reopened after being killed.

**Good News**: WatchProtocolSDK-ObjC v2.0.1+ has all the necessary features built-in. **No SDK modifications required** - just use the existing APIs correctly.

## ✨ Built-in SDK Features

### 1. Auto-Save Device Information
```objc
// SDK automatically saves device info to sandbox on successful connection
- (void)didConnectDevice:(WPDeviceModel *)device {
    // ✅ SDK automatically executes: [device saveToSandbox:device.macAddress];
    // ✅ SDK automatically sets: manager.currentDevice = device;
}
```

### 2. Load Device from Sandbox
```objc
// Load saved device by MAC address
WPDeviceModel *savedDevice = [WPDeviceModel loadFromSandboxWithMac:@"AA:BB:CC:DD:EE:FF"];
```

### 3. Auto-Scan and Connect
```objc
// Scan for specific device and auto-connect (with timeout)
[[WPBluetoothManager sharedInstance] connectAndScanWithMac:macAddress
                                                 deviceName:deviceName
                                                    timeout:10.0];
```

### 4. Smart currentDevice Management
- ✅ On successful connection: automatically sets `currentDevice`
- ✅ On unexpected disconnect: preserves `currentDevice` (for reconnection)
- ✅ On intentional disconnect: clears `currentDevice`

## 🚀 Implementation Steps

### Step 1: Save Device MAC Address

Save the MAC address to UserDefaults when connection succeeds:

```objc
// In your delegate callback
- (void)didConnectDevice:(WPDeviceModel *)device {
    // Save MAC address to UserDefaults
    [[NSUserDefaults standardUserDefaults] setObject:device.macAddress
                                               forKey:@"LastConnectedDeviceMAC"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    NSLog(@"✅ Device connected and MAC saved: %@", device.macAddress);
}
```

### Step 2: Auto-Reconnect on App Launch

In `AppDelegate.m`'s `application:didFinishLaunchingWithOptions:`:

```objc
- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // Set Bluetooth delegate
    [WPBluetoothManager sharedInstance].delegate = self;

    // Delay auto-reconnect (wait for Bluetooth to be ready)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [self autoReconnectToLastDevice];
    });

    return YES;
}

#pragma mark - Auto Reconnect

- (void)autoReconnectToLastDevice {
    // 1. Get last saved MAC address
    NSString *lastMAC = [[NSUserDefaults standardUserDefaults]
                         stringForKey:@"LastConnectedDeviceMAC"];

    if (!lastMAC || lastMAC.length == 0) {
        NSLog(@"ℹ️ No last connection record, skipping auto-reconnect");
        return;
    }

    // 2. Load device info from sandbox
    WPDeviceModel *savedDevice = [WPDeviceModel loadFromSandboxWithMac:lastMAC];

    if (!savedDevice) {
        NSLog(@"⚠️ Failed to load device from sandbox: %@", lastMAC);
        return;
    }

    NSLog(@"🔄 Starting auto-reconnect to device: %@ (%@)", savedDevice.name, lastMAC);

    // 3. Auto-scan and connect (10 second timeout)
    [[WPBluetoothManager sharedInstance] connectAndScanWithMac:lastMAC
                                                     deviceName:savedDevice.name
                                                        timeout:10.0];
}

#pragma mark - WPBluetoothDelegate

- (void)didConnectDevice:(WPDeviceModel *)device {
    NSLog(@"✅ Auto-reconnect successful: %@", device.name);

    // Update saved MAC (usually unchanged, but keep in sync)
    [[NSUserDefaults standardUserDefaults] setObject:device.macAddress
                                               forKey:@"LastConnectedDeviceMAC"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    // TODO: Update UI, notify user of connection
}

- (void)didDisconnectDevice:(WPDeviceModel *)device error:(NSError *)error {
    if (error) {
        NSLog(@"⚠️ Device disconnected unexpectedly: %@", error.localizedDescription);
        // Can implement reconnection logic here
    } else {
        NSLog(@"ℹ️ Device disconnected intentionally");
    }
}

- (void)didFailToConnectDevice:(WPDeviceModel *)device error:(NSError *)error {
    NSLog(@"❌ Auto-reconnect failed: %@", error.localizedDescription);
    // TODO: Prompt user to connect manually
}
```

### Step 3: Clear Record on Intentional Disconnect (Optional)

Clear saved MAC when user disconnects intentionally:

```objc
- (void)userTappedDisconnectButton {
    // Clear saved MAC
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"LastConnectedDeviceMAC"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    // Disconnect
    [[WPBluetoothManager sharedInstance] disconnect];

    NSLog(@"✅ Auto-reconnect record cleared");
}
```

### Step 4: Handle Timeout

`connectAndScanWithMac:deviceName:timeout:` automatically stops scanning on timeout:

```objc
- (void)didFailToConnectDevice:(WPDeviceModel *)device error:(NSError *)error {
    if ([error.domain isEqualToString:@"WPBluetoothError"] &&
        error.code == -1001) {  // Assuming -1001 is timeout error code
        NSLog(@"⏱ Auto-reconnect timeout, device may be out of range");

        // TODO: Show alert: "Device not found, ensure device is powered on and nearby"
    } else {
        NSLog(@"❌ Auto-reconnect failed: %@", error.localizedDescription);
    }
}
```

## 📱 Complete Example

### AppDelegate.h
```objc
#import <UIKit/UIKit.h>
#import <WatchProtocolSDK/WatchProtocolSDK.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, WPBluetoothDelegate>

@property (strong, nonatomic) UIWindow *window;

- (void)autoReconnectToLastDevice;

@end
```

### AppDelegate.m
```objc
#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // Set Bluetooth delegate
    [WPBluetoothManager sharedInstance].delegate = self;

    // Delay 1 second before attempting auto-reconnect
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [self autoReconnectToLastDevice];
    });

    return YES;
}

#pragma mark - Auto Reconnect

- (void)autoReconnectToLastDevice {
    // Get last saved MAC
    NSString *lastMAC = [[NSUserDefaults standardUserDefaults]
                         stringForKey:@"LastConnectedDeviceMAC"];

    if (!lastMAC || lastMAC.length == 0) {
        NSLog(@"ℹ️ No last connection record");
        return;
    }

    // Load device from sandbox
    WPDeviceModel *savedDevice = [WPDeviceModel loadFromSandboxWithMac:lastMAC];

    if (!savedDevice) {
        NSLog(@"⚠️ Failed to load device: %@", lastMAC);
        return;
    }

    NSLog(@"🔄 Auto-reconnecting: %@ (%@)", savedDevice.name, lastMAC);

    // Start scanning and connecting
    [[WPBluetoothManager sharedInstance] connectAndScanWithMac:lastMAC
                                                     deviceName:savedDevice.name
                                                        timeout:10.0];
}

#pragma mark - WPBluetoothDelegate

- (void)didConnectDevice:(WPDeviceModel *)device {
    NSLog(@"✅ Connection successful: %@", device.name);

    // Save MAC
    [[NSUserDefaults standardUserDefaults] setObject:device.macAddress
                                               forKey:@"LastConnectedDeviceMAC"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)didDisconnectDevice:(WPDeviceModel *)device error:(NSError *)error {
    if (error) {
        NSLog(@"⚠️ Unexpected disconnect: %@", error.localizedDescription);
    } else {
        NSLog(@"ℹ️ Intentional disconnect");
    }
}

- (void)didFailToConnectDevice:(WPDeviceModel *)device error:(NSError *)error {
    NSLog(@"❌ Connection failed: %@", error.localizedDescription);
}

@end
```

## 🎯 Advanced Usage

### 1. Auto-Reconnect on Disconnect

Immediately attempt reconnection on unexpected disconnect:

```objc
- (void)didDisconnectDevice:(WPDeviceModel *)device error:(NSError *)error {
    if (error) {  // Unexpected disconnect
        NSLog(@"⚠️ Device disconnected, retrying in 3 seconds...");

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            if (device.macAddress) {
                [[WPBluetoothManager sharedInstance]
                    connectAndScanWithMac:device.macAddress
                               deviceName:device.name
                                  timeout:10.0];
            }
        });
    }
}
```

### 2. Limit Reconnection Attempts

Prevent infinite reconnection loops:

```objc
@interface AppDelegate ()
@property (nonatomic, assign) NSInteger reconnectAttempts;
@property (nonatomic, assign) NSInteger maxReconnectAttempts;
@end

@implementation AppDelegate

- (void)didDisconnectDevice:(WPDeviceModel *)device error:(NSError *)error {
    if (error && self.reconnectAttempts < self.maxReconnectAttempts) {
        self.reconnectAttempts++;

        NSLog(@"⚠️ Reconnect attempt %ld/%ld",
              (long)self.reconnectAttempts,
              (long)self.maxReconnectAttempts);

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [[WPBluetoothManager sharedInstance]
                connectAndScanWithMac:device.macAddress
                           deviceName:device.name
                              timeout:10.0];
        });
    } else if (self.reconnectAttempts >= self.maxReconnectAttempts) {
        NSLog(@"❌ Max reconnection attempts reached, stopping");
    }
}

- (void)didConnectDevice:(WPDeviceModel *)device {
    // Reset counter on successful connection
    self.reconnectAttempts = 0;

    NSLog(@"✅ Connection successful");
}

@end
```

## ❓ FAQ

### Q1: Why delay 1 second before auto-reconnect?

**A**: CoreBluetooth needs time to initialize. Immediate calls may fail if Bluetooth isn't ready (state not `CBManagerStatePoweredOn`).

Recommendations:
- Monitor `centralManagerDidUpdateState:` callback
- Or use 1-2 second delay

### Q2: How to verify successful connection?

**A**: Listen for `didConnectDevice:` delegate callback. SDK calls this automatically on successful connection.

### Q3: What's a good timeout value?

**A**: Recommend 10-15 seconds:
- Too short (<5s): May not find device in time
- Too long (>30s): Poor user experience

### Q4: What if device is out of range?

**A**: SDK calls `didFailToConnectDevice:error:` with timeout error after the specified timeout.

### Q5: How to clear auto-reconnect?

**A**: Remove MAC from UserDefaults:

```objc
[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"LastConnectedDeviceMAC"];
[[NSUserDefaults standardUserDefaults] synchronize];
```

### Q6: What device info is saved in sandbox?

**A**: `WPDeviceModel` saves:
- MAC address
- Device name
- Device type
- Other device properties

Can be fully restored via `loadFromSandboxWithMac:`.

### Q7: Does it support background reconnection?

**A**: iOS limitations:
- ✅ Works when app is in foreground
- ⚠️ Limited when app is in background
- ❌ Cannot run when app is killed

**Solutions**:
- Implement reconnection in `application:didFinishLaunchingWithOptions:` (when app reopens)
- Consider requesting background Bluetooth permission (add `UIBackgroundModes` - `bluetooth-central` in Info.plist)

### Q8: How to debug auto-reconnect?

**A**: Enable SDK logging:

```objc
[[WPLogger sharedInstance] setLogEnabled:YES];
```

Console will show:
- Scan status
- Connection progress
- Error messages

## 🎉 Summary

### ✅ What SDK Provides
- Auto-save device to sandbox
- Load device from sandbox
- Auto-scan and connect to specific device
- Smart currentDevice management

### 📝 What You Need to Do
1. Save MAC to UserDefaults on connection success
2. Call `autoReconnectToLastDevice` on app launch
3. Handle connection success/failure callbacks

### 💡 Recommended Configuration
- Delay: 1-2 seconds
- Timeout: 10-15 seconds
- Reconnection attempts: 3-5 times

### 🚀 Next Steps
Follow the complete example code to implement auto-reconnect in your app. If you have questions, check SDK logs or contact technical support.

---

**Document Version**: v2.0.2
**Last Updated**: 2026-01-20
**Compatible With**: WatchProtocolSDK-ObjC v2.0.1+
