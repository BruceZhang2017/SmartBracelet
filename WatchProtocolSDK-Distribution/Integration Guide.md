# WatchProtocolSDK Integration Guide

## 📋 Table of Contents
1. [SDK Overview](#sdk-overview)
2. [System Requirements](#system-requirements)
3. [Integration Steps](#integration-steps)
4. [Initialization](#initialization)
5. [Core Features](#core-features)
6. [API Reference](#api-reference)
7. [Sample Code](#sample-code)
8. [FAQ](#faq)
9. [Version History](#version-history)

---

## SDK Overview

WatchProtocolSDK is an iOS framework for smart watch device communication, providing complete Bluetooth connection, data synchronization, and device management capabilities.

### Key Features

- ✅ **Bluetooth Connection Management**: Auto scan, connect, and reconnect to smart watch devices
- ✅ **Health Data Sync**: Steps, sleep, heart rate, blood oxygen, blood pressure data synchronization
- ✅ **Device Control**: Alarm, sedentary reminder, drink water reminder, and other functions
- ✅ **Message Push**: Supports incoming calls, SMS, and third-party app message notifications
- ✅ **OTA Update**: Firmware over-the-air upgrade functionality
- ✅ **Weather Sync**: Real-time weather data push to watch
- ✅ **Contact Sync**: Sync phone contacts to watch
- ✅ **Zero Dependencies**: No external dependencies, only system frameworks

---

## System Requirements

| Item | Requirement |
|------|-------------|
| iOS Version | iOS 12.0 or later |
| Xcode | Xcode 13.0 or later |
| Swift | Swift 5.0 or later |
| Architecture | arm64 (Device), arm64 + x86_64 (Simulator) |
| Permissions | Bluetooth (NSBluetoothAlwaysUsageDescription) |

---

## Integration Steps

### Method 1: XCFramework Integration (Recommended)

#### 1. Choose the Right Version

```
WatchProtocolSDK-Distribution/
├── Debug/
│   └── WatchProtocolSDK.xcframework    # Debug version with debug symbols
└── Release/
    └── WatchProtocolSDK.xcframework    # Release version, optimized and smaller
```

**Recommendations**:
- Use `Debug` version during development
- Use `Release` version for App Store submission

#### 2. Add to Project

1. Drag `WatchProtocolSDK.xcframework` into your Xcode project
2. Verify the framework is added in **General** → **Frameworks, Libraries, and Embedded Content**
3. Set to **Embed & Sign** (if using dynamic framework)

#### 3. Configure Info.plist

Add Bluetooth permission descriptions:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Bluetooth is required to connect with smart watch devices</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>Bluetooth is required for data transmission with watch</string>
```

#### 4. Import Framework

Import the framework in files where you need to use the SDK:

```swift
import WatchProtocolSDK
```

---

## Initialization

### 1. Setup Data Storage Delegate (Required)

The SDK uses delegation pattern for data storage. You need to implement the `WatchDataStorageDelegate` protocol:

```swift
import WatchProtocolSDK

class DatabaseManager: WatchDataStorageDelegate {

    static let shared = DatabaseManager()

    // Save step data
    func saveStepData(_ data: WatchProtocolSDK.StepData) {
        // Implement your database save logic
        print("Save steps: \(data.step) steps, date: \(data.date)")
    }

    // Save sleep data
    func saveSleepData(_ data: WatchProtocolSDK.SleepData) {
        print("Save sleep: Deep \(data.deep) min, Light \(data.light) min")
    }

    // Save heart rate data
    func saveHeartRateData(_ data: WatchProtocolSDK.HeartRateData) {
        print("Save heart rate: \(data.heartRate) bpm")
    }

    // Save blood oxygen data
    func saveOxygenData(_ data: WatchProtocolSDK.OxygenData) {
        print("Save oxygen: \(data.oxygen)%")
    }

    // Save blood pressure data
    func saveBloodPressureData(_ data: WatchProtocolSDK.BloodPressureData) {
        print("Save blood pressure: \(data.systolic)/\(data.diastolic) mmHg")
    }
}
```

### 2. Initialize in AppDelegate

```swift
import UIKit
import WatchProtocolSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Set SDK data storage delegate
        XGZTBlueToothManager.shared.storageDelegate = DatabaseManager.shared

        return true
    }
}
```

---

## Core Features

### 1. Device Scanning and Connection

```swift
import WatchProtocolSDK

// Start scanning for devices
XGZTBlueToothManager.shared.startScan()

// Set Bluetooth manager delegate
XGZTBlueToothManager.shared.delegate = self

// Implement delegate methods
extension ViewController: BleManagerDelegate {

    // Device discovered
    func didDiscoverDevice(device: BluetoothWatchDevice, rssi: NSNumber) {
        print("Device found: \(device.deviceName ?? "Unknown"), RSSI: \(rssi)")
    }

    // Connection successful
    func didConnectDevice() {
        print("Device connected successfully")
        // Read device information
        XGZTBlueToothManager.shared.handler.readDeviceInfo()
    }

    // Connection failed
    func didFailToConnect(error: Error?) {
        print("Connection failed: \(error?.localizedDescription ?? "")")
    }

    // Device disconnected
    func didDisconnectDevice() {
        print("Device disconnected")
    }
}

// Connect to specific device
XGZTBlueToothManager.shared.connectAndScan(to: macAddress, deviceName: deviceName)

// Disconnect
XGZTBlueToothManager.shared.disconnect()
```

### 2. Read Device Information

```swift
// Read basic device info
XGZTBlueToothManager.shared.handler.readDeviceInfo()

// Get current connected device
if let device = XGZTBlueToothManager.shared.device {
    print("Device name: \(device.deviceName ?? "")")
    print("Device model: \(device.deviceModel ?? 0)")
    print("Battery level: \(device.batteryLevel ?? 0)%")
    print("Firmware version: \(device.firmwareVersion ?? "")")
    print("Screen type: \(device.screenType == 1 ? "Square" : "Round")")
    print("Screen size: \(device.screenWidth) x \(device.screenHeight)")
}
```

### 3. Synchronize Health Data

```swift
// Sync step data
XGZTBlueToothManager.shared.handler.syncStepData()

// Sync sleep data
XGZTBlueToothManager.shared.handler.syncSleepData()

// Sync heart rate data
XGZTBlueToothManager.shared.handler.syncHeartRateData()

// Sync blood oxygen data
XGZTBlueToothManager.shared.handler.syncOxygenData()

// Sync blood pressure data
XGZTBlueToothManager.shared.handler.syncBloodPressureData()

// Read real-time health data
if let device = XGZTBlueToothManager.shared.device {
    print("Current steps: \(device.currentStep)")
    print("Current heart rate: \(device.currentHeartrate) bpm")
    print("Current oxygen: \(device.currentOxygen)%")
}
```

### 4. Alarm Management

```swift
// Create alarm
let alarm = AlarmData(
    alarmIndex: 0,          // Alarm index (0-9)
    mswitch: 1,             // Switch (0: off, 1: on)
    alarmCycle: 127,        // Repeat cycle (bitmask: Sun-Sat)
    alarmHour: 7,           // Hour (0-23)
    alarmMinute: 30,        // Minute (0-59)
    vibrationMode: 1,       // Vibration mode
    remindLater: 5          // Snooze time (minutes)
)

// Set alarm
XGZTBlueToothManager.shared.handler.setAlarm(alarm)

// Read alarm list
XGZTBlueToothManager.shared.handler.readAlarms()

// Get alarm data
if let device = XGZTBlueToothManager.shared.device {
    print("Total alarms: \(device.alarmcount)")
    for alarm in device.alarms {
        print("Alarm\(alarm.alarmIndex): \(alarm.alarmHour):\(alarm.alarmMinute)")
    }
}
```

### 5. Sedentary / Drink Water Reminders

```swift
// Set sedentary reminder
let sedentaryReminder = ReminderInfoResponse(
    eventType: 1,       // Event type: 1=sedentary reminder
    cycle: 127,         // Repeat cycle (bitmask)
    startHour: 9,       // Start hour
    startMinute: 0,     // Start minute
    endHour: 18,        // End hour
    endMinute: 0,       // End minute
    period: 60          // Reminder interval (minutes)
)
XGZTBlueToothManager.shared.handler.setLongsitReminder(sedentaryReminder)

// Set drink water reminder
let drinkReminder = ReminderInfoResponse(
    eventType: 2,       // Event type: 2=drink water reminder
    cycle: 127,
    startHour: 8,
    startMinute: 0,
    endHour: 22,
    endMinute: 0,
    period: 120
)
XGZTBlueToothManager.shared.handler.setDrinkWaterReminder(drinkReminder)
```

### 6. Message Push

```swift
// Push incoming call notification
XGZTBlueToothManager.shared.handler.pushIncomingCall(name: "John Doe", phoneNumber: "13800138000")

// Push SMS
XGZTBlueToothManager.shared.handler.pushMessage(title: "SMS", content: "You have a new message")

// Push WeChat message
XGZTBlueToothManager.shared.handler.pushWeChatMessage(sender: "Alice", content: "Hello")

// Push QQ message
XGZTBlueToothManager.shared.handler.pushQQMessage(sender: "Bob", content: "Are you there?")

// Push other app notifications
XGZTBlueToothManager.shared.handler.pushAppNotification(
    appType: .facebook,  // App type
    title: "Facebook",
    content: "You have a new notification"
)
```

### 7. Device Settings

```swift
// Set device parameters
XGZTBlueToothManager.shared.handler.setUserInfo(
    sex: 1,         // Gender (0: male, 1: female)
    age: 30,        // Age
    height: 175,    // Height (cm)
    weight: 70      // Weight (kg)
)

// Set time format
XGZTBlueToothManager.shared.handler.setTimeFormat(is24Hour: true)

// Set unit system
XGZTBlueToothManager.shared.handler.setUnitSystem(isMetric: true)

// Set raise to wake
XGZTBlueToothManager.shared.handler.setRaiseToWake(enabled: true)

// Find phone
XGZTBlueToothManager.shared.handler.findPhone()
```

### 8. Weather Synchronization

```swift
// Push weather data
let weatherData = WeatherData(
    temperature: 25,        // Temperature (℃)
    weatherType: 1,         // Weather type (0: sunny, 1: cloudy, 2: rain...)
    minTemperature: 18,     // Min temperature
    maxTemperature: 28,     // Max temperature
    airQuality: 50          // Air quality index
)
XGZTBlueToothManager.shared.handler.syncWeather(weatherData)
```

---

## API Reference

### Core Classes

#### XGZTBlueToothManager

Bluetooth manager, singleton pattern.

```swift
public class XGZTBlueToothManager {
    public static let shared: XGZTBlueToothManager

    // Properties
    public weak var delegate: BleManagerDelegate?
    public weak var storageDelegate: WatchDataStorageDelegate?
    public var device: BluetoothWatchDevice?
    public var handler: XGZTBusinessHandler

    // Methods
    public func startScan()
    public func stopScan()
    public func connectAndScan(to macAddress: String, deviceName: String)
    public func disconnect()
}
```

#### BluetoothWatchDevice

Device model class.

```swift
public class BluetoothWatchDevice {
    // Device info
    public var deviceName: String?
    public var max: String?              // MAC address
    public var batteryLevel: Int?
    public var isCharging: Bool?
    public var firmwareVersion: String?
    public var hardwareVersion: Int?
    public var screenType: Int           // 1: square, 2: round
    public var screenWidth: Int
    public var screenHeight: Int
    public var mtu: Int

    // User info
    public var sex: Int
    public var age: Int
    public var height: Int
    public var weight: Int

    // Health data
    public var currentStep: Int
    public var currentHeartrate: Int
    public var currentOxygen: Int
    public var currentSystolicpressure: Int
    public var currentDiastolicpressure: Int

    // Alarms and reminders
    public var alarms: [AlarmData]
    public var longsit: ReminderInfoResponse?
    public var drinkWater: ReminderInfoResponse?

    // Static methods
    public static func loadFromSandbox(mac: String) -> BluetoothWatchDevice?
    public static func loadFromSandbox(deviceName: String) -> BluetoothWatchDevice?
    public static func loadAll()
    public static func deleteFromSandbox(mac: String)
}
```

#### WatchDataStorageDelegate

Data storage delegate protocol.

```swift
public protocol WatchDataStorageDelegate: AnyObject {
    func saveStepData(_ data: StepData)
    func saveSleepData(_ data: SleepData)
    func saveHeartRateData(_ data: HeartRateData)
    func saveOxygenData(_ data: OxygenData)
    func saveBloodPressureData(_ data: BloodPressureData)
}
```

### Data Structures

#### StepData - Step Data

```swift
public struct StepData {
    public let date: String      // Date (format: yyyy-MM-dd)
    public let mac: String       // Device MAC address
    public let step: Int         // Steps
}
```

#### SleepData - Sleep Data

```swift
public struct SleepData {
    public let date: String      // Date
    public let mac: String       // Device MAC address
    public let awake: Int        // Awake duration (minutes)
    public let light: Int        // Light sleep duration (minutes)
    public let deep: Int         // Deep sleep duration (minutes)
}
```

#### HeartRateData - Heart Rate Data

```swift
public struct HeartRateData {
    public let time: Int         // Timestamp
    public let mac: String       // Device MAC address
    public let heartRate: Int    // Heart rate value (bpm)
}
```

#### AlarmData - Alarm Data

```swift
public struct AlarmData {
    public var alarmIndex: Int      // Alarm index (0-9)
    public var mswitch: Int         // Switch (0: off, 1: on)
    public var alarmCycle: Int      // Repeat cycle (bitmask)
    public var alarmHour: Int       // Hour (0-23)
    public var alarmMinute: Int     // Minute (0-59)
    public var vibrationMode: Int   // Vibration mode
    public var remindLater: Int     // Snooze (minutes)
}
```

---

## Sample Code

### Complete Device Management Example

```swift
import UIKit
import WatchProtocolSDK

class DeviceViewController: UIViewController {

    // MARK: - Properties

    private var discoveredDevices: [BluetoothWatchDevice] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBluetooth()
    }

    // MARK: - Setup

    private func setupBluetooth() {
        // Set delegate
        XGZTBlueToothManager.shared.delegate = self

        // Start scanning
        XGZTBlueToothManager.shared.startScan()
    }

    // MARK: - Actions

    func connectDevice(device: BluetoothWatchDevice) {
        guard let mac = device.max,
              let name = device.deviceName else { return }

        XGZTBlueToothManager.shared.connectAndScan(to: mac, deviceName: name)
    }

    func syncAllData() {
        let handler = XGZTBlueToothManager.shared.handler

        // Sync all health data
        handler.syncStepData()
        handler.syncSleepData()
        handler.syncHeartRateData()
        handler.syncOxygenData()
        handler.syncBloodPressureData()
    }
}

// MARK: - BleManagerDelegate

extension DeviceViewController: BleManagerDelegate {

    func didDiscoverDevice(device: BluetoothWatchDevice, rssi: NSNumber) {
        // Add to device list
        if !discoveredDevices.contains(where: { $0.max == device.max }) {
            discoveredDevices.append(device)
            // Update UI
        }
    }

    func didConnectDevice() {
        print("✅ Device connected successfully")

        // Read device information
        XGZTBlueToothManager.shared.handler.readDeviceInfo()

        // Wait for device info to load, then sync data
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.syncAllData()
        }
    }

    func didFailToConnect(error: Error?) {
        print("❌ Connection failed: \(error?.localizedDescription ?? "Unknown error")")
    }

    func didDisconnectDevice() {
        print("⚠️ Device disconnected")
    }

    func didReceiveData(data: Data) {
        // Received raw data
    }
}
```

---

## FAQ

### Q1: How to check if device is connected?

```swift
let isConnected = XGZTBlueToothManager.shared.isConnected
// or
let connectionState = XGZTConnectionStateManager.shared.connectionState
```

### Q2: How to handle reconnection?

The SDK handles reconnection automatically, but you can also trigger it manually:

```swift
// When device disconnects
func didDisconnectDevice() {
    // Get last connected device
    if let lastDevice = BluetoothWatchDevice.loadFromSandbox(mac: lastMacAddress) {
        // Attempt to reconnect
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XGZTBlueToothManager.shared.connectAndScan(
                to: lastDevice.max!,
                deviceName: lastDevice.deviceName!
            )
        }
    }
}
```

### Q3: What if data sync fails?

1. Check if device is connected
2. Verify Bluetooth permission is granted
3. Check device battery level
4. Try reconnecting the device

```swift
// Check connection status
if !XGZTBlueToothManager.shared.isConnected {
    print("Device not connected, unable to sync data")
    return
}

// Retry mechanism
func syncDataWithRetry(maxRetries: Int = 3) {
    var retryCount = 0

    func attemptSync() {
        XGZTBlueToothManager.shared.handler.syncStepData()

        // Retry if failed
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if retryCount < maxRetries && !self.syncSuccess {
                retryCount += 1
                attemptSync()
            }
        }
    }

    attemptSync()
}
```

### Q4: How to support multiple device switching?

```swift
// Save device list
BluetoothWatchDevice.saveToSandbox(device: device)

// Load all saved devices
BluetoothWatchDevice.loadAll()

// Switch to new device
func switchDevice(to newDevice: BluetoothWatchDevice) {
    // Disconnect current device
    XGZTBlueToothManager.shared.disconnect()

    // Connect to new device
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        XGZTBlueToothManager.shared.connectAndScan(
            to: newDevice.max!,
            deviceName: newDevice.deviceName!
        )
    }
}

// Delete device
BluetoothWatchDevice.deleteFromSandbox(mac: macAddress)
```

### Q5: How to optimize Bluetooth connection stability?

```swift
// 1. Set reasonable scan timeout
XGZTBlueToothManager.shared.scanTimeout = 15.0

// 2. Monitor app foreground/background transitions
NotificationCenter.default.addObserver(
    self,
    selector: #selector(appDidBecomeActive),
    name: UIApplication.didBecomeActiveNotification,
    object: nil
)

@objc func appDidBecomeActive() {
    // Check connection when app returns to foreground
    if !XGZTBlueToothManager.shared.isConnected {
        // Attempt to reconnect
        reconnectLastDevice()
    }
}

// 3. Implement heartbeat detection
Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
    if XGZTBlueToothManager.shared.isConnected {
        // Send heartbeat packet
        XGZTBlueToothManager.shared.handler.readBatteryLevel()
    }
}
```

---

## Version History

### v1.0.0 (2024-12-28)

**New Features**
- ✅ Initial release
- ✅ Complete Bluetooth device connection and management
- ✅ Health data sync (steps, sleep, heart rate, oxygen, blood pressure)
- ✅ Alarm and reminder functionality
- ✅ Message push support
- ✅ Delegation pattern for data storage
- ✅ Zero external dependencies

**Architecture Improvements**
- ✅ Removed RealmSwift dependency, using delegation pattern
- ✅ Provides Debug and Release versions
- ✅ Supports iOS device and simulator (XCFramework)

---

## Technical Support

For questions or suggestions, please contact technical support.

**Development Documentation**: See SDK source code comments
**Last Updated**: 2024-12-28
**SDK Version**: 1.0.0

---

© 2024 WatchProtocolSDK. All rights reserved.
