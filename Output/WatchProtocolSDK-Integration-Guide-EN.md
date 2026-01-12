# WatchProtocolSDK Integration Guide

## Version Information
- **SDK Version**: v1.0.2
- **Release Date**: 2026-01-10
- **Supported Platforms**: iOS 13.0+
- **Development Language**: Swift 5.0+

---

## Table of Contents
1. [SDK Overview](#sdk-overview)
2. [System Requirements](#system-requirements)
3. [SDK Integration](#sdk-integration)
4. [Quick Start](#quick-start)
5. [Core Features](#core-features)
6. [API Reference](#api-reference)
7. [Data Models](#data-models)
8. [Sample Code](#sample-code)
9. [FAQ](#faq)
10. [Changelog](#changelog)

---

## SDK Overview

WatchProtocolSDK is an iOS Bluetooth communication protocol SDK specifically designed for smart watch devices. It provides comprehensive features including device connection management, health data synchronization, and protocol command handling, helping developers quickly integrate smart watch device functionality into iOS applications.

### Key Features

- ✅ **Bluetooth Device Management**: Supports complete device lifecycle management including scanning, connecting, disconnecting, and reconnection
- ✅ **Health Data Synchronization**: Supports synchronization of multiple health data types including steps, sleep, heart rate, blood oxygen, and blood pressure
- ✅ **Protocol-based Storage**: Flexible data storage design based on protocols, adaptable to different storage solutions
- ✅ **Device Commands**: Supports rich commands such as time synchronization, language settings, alarm management, and sport modes
- ✅ **Thread Safety**: Core management classes designed with thread safety
- ✅ **Logging System**: Built-in comprehensive logging system for easy troubleshooting
- ✅ **Modular Architecture**: Clear module division, easy to maintain and extend

---

## System Requirements

| Item | Requirement |
|------|-------------|
| iOS Version | iOS 13.0 and above |
| Xcode Version | Xcode 12.0 and above |
| Swift Version | Swift 5.0 and above |
| Bluetooth | Supports Bluetooth 4.0 (BLE) |

### Dependencies

- `CoreBluetooth.framework` (System framework)
- `Foundation.framework` (System framework)
- `SwiftyJSON` (Third-party library, installed via CocoaPods)
- `CryptoSwift` (Third-party library, installed via CocoaPods)

---

## SDK Integration

### Method 1: Using XCFramework (Recommended)

1. Drag `WatchProtocolSDK.xcframework` into your project
2. Add the xcframework in Project Target -> General -> Frameworks, Libraries, and Embedded Content
3. Set Embed to "Embed & Sign"

### Method 2: Using CocoaPods

Add to your `Podfile`:

```ruby
# WatchProtocolSDK dependencies
pod 'SwiftyJSON'
pod 'CryptoSwift'

# Local podspec (if published to remote repository, use remote URL directly)
pod 'WatchProtocolSDK', :path => './WatchProtocolSDK.podspec'
```

Then execute:
```bash
pod install
```

### Project Configuration

1. **Add Bluetooth Permissions**
   Add the following permission descriptions to `Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Bluetooth is required to connect to smart watch devices</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>Bluetooth is required to communicate with smart watch devices</string>
```

2. **Import Framework**

```swift
import WatchProtocolSDK
```

---

## Quick Start

### 1. Initialize Bluetooth Manager

```swift
import WatchProtocolSDK

class YourViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize Bluetooth central manager
        XGZTBlueToothManager.shared.initCentral()

        // Set delegate
        XGZTBlueToothManager.shared.delegate = self
    }
}

// Implement Bluetooth manager delegate
extension YourViewController: BleManagerDelegate {

    // Bluetooth is ready
    func onBleReady() {
        print("Bluetooth is ready, can start scanning devices")
    }

    // Received data from device
    func receiveData(_ data: Data) {
        print("Received data: \(data.hexString)")
    }

    // Data sent successfully
    func sentData() {
        print("Data sent successfully")
    }
}
```

### 2. Scan and Connect to Device

```swift
// Start scanning for devices
func startScan() {
    XGZTBlueToothManager.shared.scanDevice { peripheral, macAddress in
        print("Found device: \(peripheral.name ?? "Unknown") - MAC: \(macAddress)")

        // Add device to list
        // ... Update UI to display device list
    }
}

// Connect to specific device
func connectDevice(macAddress: String) {
    XGZTBlueToothManager.shared.connectDevice(macAddress) { success in
        if success {
            print("Device connected successfully")
            // Start syncing data after successful connection
            self.syncDeviceData()
        } else {
            print("Device connection failed")
        }
    }
}

// Stop scanning
func stopScan() {
    XGZTBlueToothManager.shared.stopScan()
}

// Disconnect device
func disconnectDevice() {
    XGZTBlueToothManager.shared.disconnectBle()
}
```

### 3. Synchronize Health Data

```swift
// Implement data storage protocol
class MyHealthDataStorage: HealthDataStorageProtocol {

    func saveStepData(_ data: StepData) {
        print("Saving step data: \(data.step) steps, date: \(data.date)")
        // Implement your data storage logic (e.g., save to database)
    }

    func saveSleepData(_ data: SleepData) {
        print("Saving sleep data: deep \(data.deep) min, light \(data.light) min")
        // Implement your data storage logic
    }

    func saveHeartData(_ data: HeartData) {
        print("Saving heart rate data: \(data.heart) bpm")
        // Implement your data storage logic
    }

    func saveOxygenData(_ data: OxygenData) {
        print("Saving blood oxygen data: \(data.oxygen)%")
        // Implement your data storage logic
    }

    func saveBloodPressureData(_ data: BloodPressureData) {
        print("Saving blood pressure data: \(data.max)/\(data.min) mmHg")
        // Implement your data storage logic
    }
}

// Set data storage implementation
func setupDataStorage() {
    let storage = MyHealthDataStorage()
    XGZTBlueToothManager.shared.handler.dataStorage = storage
}

// Sync device data
func syncDeviceData() {
    // Get device info
    XGZTCommand.getDeviceInfo()

    // Sync historical data
    XGZTCommand.syncHistoryData()
}
```

### 4. Send Device Commands

```swift
// Sync time to device
func syncTime() {
    XGZTCommand.syncTime()
}

// Set device language
func setDeviceLanguage() {
    XGZTCommand.getDeviceLanguage()
}

// Find device (device vibrates or rings)
func findDevice() {
    XGZTCommand.findDevice()
}

// Set alarm
func setAlarm(hour: Int, minute: Int, isEnabled: Bool) {
    // Build alarm data and send
    // Refer to alarm-related methods in XGZTCommand for specific implementation
}
```

---

## Core Features

### 1. Bluetooth Device Management

#### XGZTBlueToothManager (Bluetooth Manager)

Responsible for core functions such as Bluetooth device scanning, connecting, disconnecting, and data transmission.

**Main Methods:**

- `initCentral()`: Initialize Bluetooth central manager
- `scanDevice(callback:)`: Scan nearby Bluetooth devices
- `connectDevice(_:completion:)`: Connect to device with specified MAC address
- `disconnectBle()`: Disconnect current device
- `stopScan()`: Stop scanning
- `isconnected()`: Check device connection status

#### XGZTDeviceManager (Device Manager)

Responsible for device cache management and connection failure diagnosis information management, with thread-safe design.

**Main Methods:**

- `addDevice(_:)`: Add device to cache
- `removeDevice(mac:)`: Remove specified device
- `findDevice(mac:)`: Find specified device
- `clearDeviceCache()`: Clear device cache
- `appendFailMessage(_:)`: Record connection failure information

### 2. Health Data Synchronization

SDK supports the following health data types:

| Data Type | Description | Data Model |
|-----------|-------------|------------|
| Steps | Daily step count statistics | `StepData` |
| Sleep | Deep sleep, light sleep, awake duration | `SleepData` |
| Heart Rate | Real-time heart rate data | `HeartData` |
| Blood Oxygen | Oxygen saturation | `OxygenData` |
| Blood Pressure | Systolic/Diastolic pressure | `BloodPressureData` |

**Data Storage Protocol:**

By implementing the `HealthDataStorageProtocol`, you can customize data storage methods (such as database, Core Data, files, etc.).

### 3. Device Command System

#### XGZTCommand (Command Manager)

Provides rich device commands, including:

- **Basic Commands**: Get device info, sync time, find device
- **Health Data**: Sync historical data, real-time measurement
- **Device Settings**: Language settings, vibration intensity, screen brightness
- **Sport Functions**: Sport mode switching, sport data synchronization
- **Alarm Management**: Add, delete, modify alarms

### 4. Connection State Management

#### XGZTConnectionStateManager (Connection State Manager)

Manages various states of Bluetooth connection:

- Device connection status
- Last connected device information
- Auto-reconnect flag
- OTA upgrade status

### 5. Command State Management

#### XGZTCommandStateManager (Command State Manager)

Manages device command execution states:

- Data reading status
- Time synchronization status
- Data synchronization progress

### 6. Logging System

#### XLogger (Logger Manager)

Provides comprehensive logging functionality with different log levels:

```swift
XLogger.shared.log("Normal log message")
XLogger.shared.logError("Error message")
XLogger.shared.logWarning("Warning message")
```

---

## API Reference

### XGZTBlueToothManager

```swift
/// Bluetooth manager singleton
public static let shared: XGZTBlueToothManager

/// Initialize Bluetooth central manager
public func initCentral()

/// Scan for devices
/// - Parameter callback: Device discovery callback (CBPeripheral, MAC address)
public func scanDevice(callback: @escaping (CBPeripheral, String) -> Void)

/// Connect to device
/// - Parameters:
///   - macAddress: Device MAC address
///   - completion: Connection result callback
public func connectDevice(_ macAddress: String,
                          completion: @escaping (Bool) -> Void)

/// Disconnect
public func disconnectBle()

/// Stop scanning
public func stopScan()

/// Check device connection status
/// - Returns: Whether connected
public func isconnected() -> Bool

/// Check if Bluetooth is off
/// - Returns: Whether Bluetooth is in off state
public func isCurrentBleStateOFF() -> Bool
```

### XGZTDeviceManager

```swift
/// Device manager singleton
public static let shared: XGZTDeviceManager

/// Device cache list (read-only)
public var cacheDevices: [BluetoothWatchDevice] { get }

/// Device count
public var deviceCount: Int { get }

/// Add device to cache
public func addDevice(_ device: BluetoothWatchDevice)

/// Remove device
public func removeDevice(mac: String)

/// Find device
public func findDevice(mac: String) -> BluetoothWatchDevice?

/// Get last device
public func lastDevice() -> BluetoothWatchDevice?

/// Clear device cache
public func clearDeviceCache()

/// Reload devices
public func reloadDevices()

/// Append connection failure message
public func appendFailMessage(_ message: String)

/// Get connection failure messages
public var connectFailMessage: String { get }

/// Clear failure messages
public func clearFailMessages()
```

### XGZTCommand

```swift
/// Get device information
public static func getDeviceInfo()

/// Sync time
public static func syncTime()

/// Find device
public static func findDevice()

/// Get device language
public static func getDeviceLanguage()

/// Sync historical data
public static func syncHistoryData()

/// Start real-time heart rate monitoring
public static func startHeartRateMonitoring()

/// Stop real-time heart rate monitoring
public static func stopHeartRateMonitoring()
```

### HealthDataStorageProtocol

```swift
/// Health data storage protocol
public protocol HealthDataStorageProtocol: AnyObject {

    /// Save step data
    func saveStepData(_ data: StepData)

    /// Save sleep data
    func saveSleepData(_ data: SleepData)

    /// Save heart rate data
    func saveHeartData(_ data: HeartData)

    /// Save blood oxygen data
    func saveOxygenData(_ data: OxygenData)

    /// Save blood pressure data
    func saveBloodPressureData(_ data: BloodPressureData)
}
```

---

## Data Models

### StepData (Step Data)

```swift
public struct StepData {
    public let date: String      // Date (format: yyyy-MM-dd)
    public let mac: String        // Device MAC address
    public let step: Int          // Step count
}
```

### SleepData (Sleep Data)

```swift
public struct SleepData {
    public let date: String      // Date
    public let mac: String        // Device MAC address
    public let awake: Int         // Awake duration (minutes)
    public let light: Int         // Light sleep duration (minutes)
    public let deep: Int          // Deep sleep duration (minutes)
}
```

### HeartData (Heart Rate Data)

```swift
public struct HeartData {
    public let mac: String        // Device MAC address
    public let time: Int          // Timestamp
    public let heart: Int         // Heart rate value (bpm)
}
```

### OxygenData (Blood Oxygen Data)

```swift
public struct OxygenData {
    public let mac: String        // Device MAC address
    public let time: Int          // Timestamp
    public let oxygen: Int        // Blood oxygen value (%)
}
```

### BloodPressureData (Blood Pressure Data)

```swift
public struct BloodPressureData {
    public let mac: String        // Device MAC address
    public let time: Int          // Timestamp
    public let max: Int           // Systolic pressure (mmHg)
    public let min: Int           // Diastolic pressure (mmHg)
}
```

---

## Sample Code

### Complete Device Connection Flow

```swift
import UIKit
import WatchProtocolSDK

class DeviceListViewController: UIViewController {

    private var discoveredDevices: [(peripheral: CBPeripheral, mac: String)] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBluetooth()
    }

    // MARK: - Initialize Bluetooth

    func setupBluetooth() {
        XGZTBlueToothManager.shared.initCentral()
        XGZTBlueToothManager.shared.delegate = self
    }

    // MARK: - Scan Devices

    @IBAction func startScanButtonTapped(_ sender: UIButton) {
        discoveredDevices.removeAll()

        XGZTBlueToothManager.shared.scanDevice { [weak self] peripheral, macAddress in
            guard let self = self else { return }

            // Check if already exists
            if !self.discoveredDevices.contains(where: { $0.mac == macAddress }) {
                self.discoveredDevices.append((peripheral, macAddress))

                DispatchQueue.main.async {
                    // Update UI (e.g., refresh TableView)
                    self.tableView.reloadData()
                }
            }
        }
    }

    // MARK: - Connect Device

    func connectDevice(at index: Int) {
        let device = discoveredDevices[index]

        // Stop scanning
        XGZTBlueToothManager.shared.stopScan()

        // Connect device
        XGZTBlueToothManager.shared.connectDevice(device.mac) { success in
            DispatchQueue.main.async {
                if success {
                    print("Device connected successfully")
                    self.onDeviceConnected(device.mac)
                } else {
                    print("Device connection failed")
                    self.showAlert(message: "Device connection failed, please try again")
                }
            }
        }
    }

    // MARK: - Post-Connection Operations

    func onDeviceConnected(_ macAddress: String) {
        // Save device info
        let device = BluetoothWatchDevice()
        device.max = macAddress
        device.deviceName = "My Smart Watch"
        XGZTDeviceManager.shared.addDevice(device)

        // Sync time
        XGZTCommand.syncTime()

        // Get device info
        XGZTCommand.getDeviceInfo()

        // Navigate to device detail
        // navigateToDeviceDetail()
    }

    // MARK: - Helper Methods

    func showAlert(message: String) {
        let alert = UIAlertController(title: "Notice",
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - BleManagerDelegate

extension DeviceListViewController: BleManagerDelegate {

    func onBleReady() {
        print("✅ Bluetooth is ready")
        // Can automatically start scanning
        // startScanButtonTapped(scanButton)
    }

    func receiveData(_ data: Data) {
        print("📥 Received data: \(data.hexString)")
    }

    func sentData() {
        print("📤 Data sent successfully")
    }
}
```

### Health Data Storage Example

```swift
import Foundation
import WatchProtocolSDK
import CoreData // or other database framework

class HealthDataStorageManager: HealthDataStorageProtocol {

    static let shared = HealthDataStorageManager()

    private init() {}

    // MARK: - HealthDataStorageProtocol

    func saveStepData(_ data: StepData) {
        // Example: Save to UserDefaults (production environment recommends using database)
        let key = "step_\(data.date)_\(data.mac)"
        UserDefaults.standard.set(data.step, forKey: key)

        // Or save to database
        // saveToDatabase(data)

        // Send notification to update UI
        NotificationCenter.default.post(
            name: .stepDataUpdated,
            object: data
        )
    }

    func saveSleepData(_ data: SleepData) {
        let sleepInfo: [String: Any] = [
            "date": data.date,
            "mac": data.mac,
            "deep": data.deep,
            "light": data.light,
            "awake": data.awake,
            "total": data.deep + data.light + data.awake
        ]

        let key = "sleep_\(data.date)_\(data.mac)"
        UserDefaults.standard.set(sleepInfo, forKey: key)

        NotificationCenter.default.post(
            name: .sleepDataUpdated,
            object: data
        )
    }

    func saveHeartData(_ data: HeartData) {
        // Heart rate data may update frequently, recommend batch saving
        var heartRateList = getHeartRateList(for: data.mac)
        heartRateList.append(data)

        // Keep only last 100 records
        if heartRateList.count > 100 {
            heartRateList.removeFirst()
        }

        // Save locally
        saveHeartRateList(heartRateList, for: data.mac)

        NotificationCenter.default.post(
            name: .heartRateUpdated,
            object: data
        )
    }

    func saveOxygenData(_ data: OxygenData) {
        let key = "oxygen_\(data.time)_\(data.mac)"
        UserDefaults.standard.set(data.oxygen, forKey: key)

        NotificationCenter.default.post(
            name: .oxygenDataUpdated,
            object: data
        )
    }

    func saveBloodPressureData(_ data: BloodPressureData) {
        let bpInfo: [String: Any] = [
            "time": data.time,
            "mac": data.mac,
            "systolic": data.max,  // Systolic
            "diastolic": data.min  // Diastolic
        ]

        let key = "bp_\(data.time)_\(data.mac)"
        UserDefaults.standard.set(bpInfo, forKey: key)

        NotificationCenter.default.post(
            name: .bloodPressureUpdated,
            object: data
        )
    }

    // MARK: - Helper Methods

    private func getHeartRateList(for mac: String) -> [HeartData] {
        // Read heart rate list from local storage
        // Simplified here, should use database in practice
        return []
    }

    private func saveHeartRateList(_ list: [HeartData], for mac: String) {
        // Save heart rate list to local storage
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let stepDataUpdated = Notification.Name("stepDataUpdated")
    static let sleepDataUpdated = Notification.Name("sleepDataUpdated")
    static let heartRateUpdated = Notification.Name("heartRateUpdated")
    static let oxygenDataUpdated = Notification.Name("oxygenDataUpdated")
    static let bloodPressureUpdated = Notification.Name("bloodPressureUpdated")
}
```

---

## FAQ

### 1. Bluetooth Permission Issues

**Problem**: App cannot access Bluetooth
**Solution**: Ensure you have correctly added Bluetooth permission description to `Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Bluetooth is required to connect to smart watch devices</string>
```

### 2. Device Connection Failure

**Problem**: Connection fails after calling `connectDevice`
**Possible Causes**:
- Device is out of range
- Device is already connected to another phone
- Bluetooth is not enabled
- Incorrect MAC address

**Solution**:
```swift
// Check Bluetooth status
if XGZTBlueToothManager.shared.isCurrentBleStateOFF() {
    print("Please turn on Bluetooth first")
    return
}

// View connection failure log
let failLog = XGZTDeviceManager.shared.connectFailMessage
print("Connection failure reason: \(failLog)")
```

### 3. Data Synchronization Failure

**Problem**: Unable to synchronize health data
**Solution**:
1. Ensure device is successfully connected
2. Ensure `HealthDataStorageProtocol` is implemented and set
3. Check if device supports this data type

```swift
// Confirm connection status
if !XGZTBlueToothManager.shared.isconnected() {
    print("Device not connected, cannot sync data")
    return
}

// Set data storage
XGZTBlueToothManager.shared.handler.dataStorage = HealthDataStorageManager.shared

// Sync data
XGZTCommand.syncHistoryData()
```

### 4. Memory Leak Issues

**Problem**: High memory usage after long-term use
**Solution**:
```swift
// Regularly clear device cache
XGZTDeviceManager.shared.clearDeviceCache()

// Clear connection failure logs
XGZTDeviceManager.shared.clearFailMessages()

// Disconnect Bluetooth when not needed
XGZTBlueToothManager.shared.disconnectBle()
```

### 5. Multiple Device Management

**Problem**: How to manage multiple smart watch devices
**Solution**:
```swift
// Get all cached devices
let devices = XGZTDeviceManager.shared.cacheDevices

// Find specific device
if let device = XGZTDeviceManager.shared.findDevice(mac: "AA:BB:CC:DD:EE:FF") {
    print("Found device: \(device.deviceName ?? "Unknown")")
}

// Switch connected device
func switchDevice(to mac: String) {
    // First disconnect current device
    XGZTBlueToothManager.shared.disconnectBle()

    // Connect to new device after disconnection completes
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        XGZTBlueToothManager.shared.connectDevice(mac) { success in
            print(success ? "Switch successful" : "Switch failed")
        }
    }
}
```

### 6. Log Debugging

**Problem**: How to view detailed runtime logs
**Solution**:
```swift
// Enable logging
XLogger.shared.enableLogging = true

// Set log level
XLogger.shared.logLevel = .debug

// View logs
XLogger.shared.log("This is a normal log")
XLogger.shared.logWarning("This is a warning")
XLogger.shared.logError("This is an error")

// Get log history
let logs = XLogger.shared.getRecentLogs()
```

---

## Changelog

### v1.0.2 (2026-01-10)

#### New Features
- ✨ Added `calculateCalorieAndDistance()` method: Automatically calculate calories and distance based on steps
- ✨ Added `getFormattedDistance()` method: Get formatted distance value in kilometers
- ✨ Added `getFormattedCalorie()` method: Get formatted calorie value in kilocalories

#### Enhancements
- 🚀 Enhanced `BluetoothWatchDevice` model with step-based health metrics calculation

### v1.0.1 (2026-01-03)

#### New Features
- ✨ Initial release of WatchProtocolSDK v1.0.1
- ✨ Complete Bluetooth device management functionality
- ✨ Support for steps, sleep, heart rate, blood oxygen, and blood pressure data synchronization
- ✨ Protocol-based data storage design, flexible adaptation to different storage solutions
- ✨ Thread-safe device management and state management
- ✨ Comprehensive logging system

#### Architecture Optimization
- 🏗️ Modular design with clear separation of responsibilities
- 🏗️ Protocol-oriented programming to reduce coupling
- 🏗️ Singleton pattern for convenient global access

#### Documentation
- 📖 Complete Chinese and English integration documentation
- 📖 Rich sample code
- 📖 Detailed API reference

---

## Technical Support

For questions or suggestions, please contact:

- **Email**: your.email@example.com
- **GitHub**: https://github.com/yourcompany/WatchProtocolSDK
- **Documentation**: https://docs.yourcompany.com/WatchProtocolSDK

---

## License

WatchProtocolSDK is licensed under the MIT License. See LICENSE file for details.

---

**© 2025-2026 Your Company. All Rights Reserved.**
