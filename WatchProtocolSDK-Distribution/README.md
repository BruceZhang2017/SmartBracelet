# WatchProtocolSDK Distribution Package

**Version**: 1.0.0
**Build Date**: 2024-12-28
**Supported Platforms**: iOS 12.0+

---

## 📦 Package Contents

```
WatchProtocolSDK-Distribution/
├── Debug/
│   └── WatchProtocolSDK.xcframework          # Debug version with debug symbols
├── Release/
│   └── WatchProtocolSDK.xcframework          # Release version (optimized)
├── 接入说明文档.md                             # Chinese integration guide
├── Integration Guide.md                      # English integration guide
└── README.md                                 # This file
```

---

## 🎯 Version Selection Guide

### Debug Version
**Location**: `Debug/WatchProtocolSDK.xcframework`

**When to Use**:
- During development and debugging
- When you need detailed crash logs and stack traces
- When using Xcode debugger with breakpoints

**Characteristics**:
- ✅ Contains debug symbols
- ✅ Better error messages and crash reports
- ✅ Larger file size (~1.9 MB per architecture)
- ❌ Not optimized for performance
- ❌ Contains extra debugging information

### Release Version
**Location**: `Release/WatchProtocolSDK.xcframework`

**When to Use**:
- For App Store submissions
- For TestFlight distributions
- For production builds

**Characteristics**:
- ✅ Fully optimized for performance
- ✅ Smaller file size (~0.6 MB per architecture)
- ✅ No debugging overhead
- ❌ Limited debugging capabilities
- ❌ Less detailed crash reports

**Recommendation**: Always use **Release** version for App Store submissions to ensure optimal performance and smaller app size.

---

## 📖 Documentation

### Quick Start

1. **Read the Integration Guide**
   - 中文: [接入说明文档.md](./接入说明文档.md)
   - English: [Integration Guide.md](./Integration%20Guide.md)

2. **Choose the Right Version**
   - Development → Use `Debug/WatchProtocolSDK.xcframework`
   - Production → Use `Release/WatchProtocolSDK.xcframework`

3. **Add to Your Project**
   - Drag the `.xcframework` file into your Xcode project
   - Set to "Embed & Sign" in **Frameworks, Libraries, and Embedded Content**

4. **Configure Permissions**
   - Add Bluetooth permission to `Info.plist`
   - See documentation for detailed steps

5. **Initialize the SDK**
   ```swift
   import WatchProtocolSDK

   // In AppDelegate
   XGZTBlueToothManager.shared.storageDelegate = DatabaseManager.shared
   ```

---

## 🏗 XCFramework Architecture

Both Debug and Release XCFrameworks contain:

### iOS Device (arm64)
- Real device support (iPhone, iPad)
- ARM64 architecture for Apple Silicon devices

### iOS Simulator (arm64 + x86_64)
- Apple Silicon Mac simulators (arm64)
- Intel Mac simulators (x86_64)
- Universal support for all development environments

**File Structure**:
```
WatchProtocolSDK.xcframework/
├── Info.plist
├── ios-arm64/                           # Real device
│   └── WatchProtocolSDK.framework/
│       ├── WatchProtocolSDK             # Binary
│       └── Info.plist
└── ios-arm64_x86_64-simulator/          # Simulator
    └── WatchProtocolSDK.framework/
        ├── WatchProtocolSDK             # Fat binary (arm64 + x86_64)
        └── Info.plist
```

---

## ✨ Key Features

### ✅ Zero Dependencies
- No external frameworks required
- Only uses system frameworks (Foundation, CoreBluetooth)
- No CocoaPods, SPM, or other package managers needed

### ✅ Production Ready
- Fully tested and stable
- Used in production apps
- Complete API documentation

### ✅ Developer Friendly
- Clean Swift API
- Delegation pattern for data storage
- Comprehensive error handling
- Detailed documentation with examples

---

## 🔧 System Requirements

| Requirement | Specification |
|-------------|---------------|
| Minimum iOS | iOS 12.0 |
| Xcode | 13.0+ |
| Swift | 5.0+ |
| Supported Architectures | arm64, x86_64 (simulator) |
| Dependencies | None (zero external dependencies) |

---

## 📝 Integration Checklist

- [ ] Choose Debug or Release version based on build type
- [ ] Add WatchProtocolSDK.xcframework to project
- [ ] Set framework to "Embed & Sign"
- [ ] Add Bluetooth permissions to Info.plist
- [ ] Implement `WatchDataStorageDelegate` protocol
- [ ] Set storage delegate in AppDelegate
- [ ] Import `WatchProtocolSDK` in required files
- [ ] Test Bluetooth connectivity
- [ ] Verify data synchronization

---

## 🚀 Quick Example

```swift
import WatchProtocolSDK

// 1. Implement storage delegate
class DatabaseManager: WatchDataStorageDelegate {
    static let shared = DatabaseManager()

    func saveStepData(_ data: StepData) {
        print("Steps: \(data.step)")
    }

    func saveSleepData(_ data: SleepData) {
        print("Sleep: \(data.deep) min deep, \(data.light) min light")
    }

    // Implement other delegate methods...
}

// 2. Initialize in AppDelegate
XGZTBlueToothManager.shared.storageDelegate = DatabaseManager.shared

// 3. Scan and connect
XGZTBlueToothManager.shared.startScan()
XGZTBlueToothManager.shared.delegate = self

// 4. Sync data after connection
XGZTBlueToothManager.shared.handler.syncStepData()
XGZTBlueToothManager.shared.handler.syncSleepData()
```

---

## 📚 Additional Resources

### Documentation Files
- **Chinese Guide**: `接入说明文档.md` - 完整的中文集成指南
- **English Guide**: `Integration Guide.md` - Complete English integration guide

### What's Covered
- ✅ Detailed integration steps
- ✅ API reference documentation
- ✅ Sample code and examples
- ✅ FAQ and troubleshooting
- ✅ Best practices

---

## 🆘 Support

### Before Asking for Help

1. Read the integration guide thoroughly
2. Check the FAQ section
3. Verify Bluetooth permissions are configured
4. Ensure you're using the correct version (Debug vs Release)
5. Check that storage delegate is properly set

### Common Issues

**Issue**: "Library not loaded: @rpath/WatchProtocolSDK.framework/WatchProtocolSDK"
**Solution**: Make sure framework is set to "Embed & Sign" in project settings

**Issue**: Data not syncing
**Solution**: Verify storage delegate is set and device is connected

**Issue**: Build fails on simulator
**Solution**: XCFramework supports all simulators. Clean and rebuild if needed.

---

## 📄 License

This SDK is proprietary software. See your license agreement for terms of use.

---

## 🔄 Version History

### v1.0.0 (2024-12-28)
- Initial release
- Complete Bluetooth device management
- Health data synchronization
- Alarm and reminder features
- Message push support
- Zero external dependencies
- XCFramework distribution

---

**Built with ❤️ for iOS developers**

For technical questions, please refer to the integration guides or contact support.
