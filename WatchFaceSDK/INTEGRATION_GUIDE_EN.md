# WatchFaceSDK Integration Guide (English)

## 📋 Table of Contents

- [Introduction](#introduction)
- [System Requirements](#system-requirements)
- [Quick Integration](#quick-integration)
- [Core Features](#core-features)
- [API Documentation](#api-documentation)
- [Usage Examples](#usage-examples)
- [FAQ](#faq)
- [Technical Support](#technical-support)

---

## Introduction

WatchFaceSDK is a powerful smartwatch face management framework that supports market watch face uploads and custom watch face creation.

### Key Features

- ✅ **Market Watch Face Upload** - Upload pre-made .bin format watch face files
- ✅ **Custom Watch Face** - Convert any image into a watch face
- ✅ **Smart Image Processing** - Automatic cropping, compression, and format conversion (PAR format)
- ✅ **Multiple Screen Support** - Auto-adapt to round and square screens
- ✅ **Real-time Progress Callbacks** - Complete progress feedback during transfer
- ✅ **Easy to Use** - Clear API design, integrate with just a few lines of code

### SDK Architecture

```
WatchFaceSDK
├── WatchFaceManager (Main Entry)
├── WatchFaceTransferEngine (Transfer Engine)
├── ImageProcessor (Image Processing)
└── Dependencies: WatchProtocolSDK + ABParTool
```

---

## System Requirements

| Item | Requirement |
|------|-------------|
| iOS Version | iOS 12.0 or later |
| Xcode | Xcode 12.0 or later |
| Swift | Swift 5.0 or later |
| Architecture | arm64 (Device) / arm64 + x86_64 (Simulator) |

---

## Quick Integration

### Step 1: Add Frameworks to Project

✅ **All frameworks are included in this release package!**

Drag the following 3 XCFramework files into your Xcode project (all located in WatchFaceSDK-Release directory):

```
1. WatchFaceSDK.xcframework        # Watch Face Management SDK
2. WatchProtocolSDK.xcframework    # Low-level Protocol SDK (Dependency)
3. ABParTool.xcframework           # PAR Image Processing Tool (Dependency)
```

**Note:** No need to download dependency frameworks separately. All required frameworks are included in this release package.

### Step 2: Configure Framework Embedding

1. Select project Target
2. Go to **General** > **Frameworks, Libraries, and Embedded Content**
3. Set all frameworks to **Embed & Sign**

![Framework Settings](https://via.placeholder.com/600x200/4A90E2/FFFFFF?text=Embed+%26+Sign)

### Step 3: Import Modules

Import in files where needed:

```swift
import WatchFaceSDK
import WatchProtocolSDK  // For device connection
```

### Step 4: Verify Installation

```swift
// Print SDK information
WatchFaceSDKConfig.printSDKInfo()

// Output:
// ==================================================
// WatchFaceSDK v1.0.0 (XGZT) - Build 2025-12-30
// ==================================================
```

---

## Core Features

### 1. Upload Market Watch Face

Market watch faces are pre-made .bin format watch face files.

```swift
do {
    let fileURL = Bundle.main.url(forResource: "watchface", withExtension: "bin")!

    try WatchFaceManager.shared.uploadMarketWatchFace(
        fileURL: fileURL,
        delegate: self
    )
} catch {
    print("Upload failed: \(error)")
}
```

### 2. Upload Custom Watch Face

Convert any image into a watch face.

```swift
do {
    guard let image = UIImage(named: "my_photo") else { return }

    try WatchFaceManager.shared.uploadCustomWatchFace(
        image: image,
        timePosition: .center,      // Time position: center
        color: .white,              // Time color: white
        delegate: self
    )
} catch {
    print("Upload failed: \(error)")
}
```

### 3. Transfer Control

```swift
// Pause transfer
WatchFaceManager.shared.pauseTransfer()

// Cancel transfer
WatchFaceManager.shared.cancelTransfer()

// Retry transfer
WatchFaceManager.shared.retryTransfer()
```

---

## API Documentation

### WatchFaceManager (Main Entry)

#### Singleton Access

```swift
let manager = WatchFaceManager.shared
```

#### Device Status Check

```swift
// Check if device is connected
func isDeviceConnected() -> Bool

// Get device screen information
func getCurrentDeviceScreenInfo() -> DeviceScreenInfo?
```

#### Upload Market Watch Face

```swift
/// Upload from file URL
func uploadMarketWatchFace(
    fileURL: URL,
    delegate: TransferDelegate?
) throws

/// Upload from data
func uploadMarketWatchFace(
    data: Data,
    delegate: TransferDelegate?
) throws
```

#### Upload Custom Watch Face

```swift
/// Upload from UIImage
func uploadCustomWatchFace(
    image: UIImage,
    timePosition: TimePosition,  // Time position
    color: DialColor,            // Time color
    delegate: TransferDelegate?
) throws

/// Upload from image name (Assets)
func uploadCustomWatchFace(
    imageName: String,
    timePosition: TimePosition,
    color: DialColor,
    delegate: TransferDelegate?
) throws

/// Upload from file URL
func uploadCustomWatchFace(
    fileURL: URL,
    timePosition: TimePosition,
    color: DialColor,
    delegate: TransferDelegate?
) throws
```

#### Image Validation

```swift
/// Validate if image meets device requirements
func validateImage(_ image: UIImage) -> (isValid: Bool, message: String)

/// Get recommended image size
func getRecommendedImageSize() -> CGSize?
```

---

## Data Types

### TimePosition

```swift
public enum TimePosition: Int {
    case none = 0           // None
    case topLeft = 1        // Top Left
    case bottomLeft = 2     // Bottom Left
    case topRight = 3       // Top Right
    case bottomRight = 4    // Bottom Right
    case center = 5         // Center
}
```

### DialColor

```swift
public enum DialColor: Int {
    case white = 0      // White
    case black = 1      // Black
    case yellow = 2     // Yellow
    case orange = 3     // Orange
    case pink = 4       // Pink
    case purple = 5     // Purple
    case blue = 6       // Blue
    case cyan = 7       // Cyan
    case green = 8      // Green
}
```

### TransferDelegate

```swift
public protocol TransferDelegate: AnyObject {
    /// Transfer started
    func transferDidStart()

    /// Progress updated
    func transferDidUpdateProgress(_ progress: TransferProgress)

    /// Transfer completed
    func transferDidComplete()

    /// Transfer failed
    func transferDidFail(error: Error)

    /// Transfer cancelled
    func transferDidCancel()
}
```

### TransferProgress

```swift
public struct TransferProgress {
    public let currentPacket: Int      // Current packet number
    public let totalPackets: Int       // Total packets
    public let bytesTransferred: Int   // Bytes transferred
    public let totalBytes: Int         // Total bytes
    public let percentage: Float       // Progress percentage (0.0 - 1.0)
    public let message: String         // Progress text (e.g., "50.00%")
}
```

---

## Usage Examples

### Complete Example: Upload Custom Watch Face

```swift
import UIKit
import WatchFaceSDK

class WatchFaceViewController: UIViewController {

    // MARK: - UI Elements
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var uploadButton: UIButton!

    // MARK: - Upload Watch Face
    @IBAction func uploadWatchFace(_ sender: UIButton) {
        // 1. Check device connection
        guard WatchFaceManager.shared.isDeviceConnected() else {
            showAlert(message: "Device not connected")
            return
        }

        // 2. Select image
        guard let image = UIImage(named: "watchface_background") else {
            showAlert(message: "Image not found")
            return
        }

        // 3. Validate image
        let validation = WatchFaceManager.shared.validateImage(image)
        guard validation.isValid else {
            showAlert(message: validation.message)
            return
        }

        // 4. Start upload
        do {
            try WatchFaceManager.shared.uploadCustomWatchFace(
                image: image,
                timePosition: .center,
                color: .white,
                delegate: self
            )

            uploadButton.isEnabled = false
            statusLabel.text = "Preparing upload..."

        } catch {
            showAlert(message: "Upload failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Cancel Upload
    @IBAction func cancelUpload(_ sender: UIButton) {
        WatchFaceManager.shared.cancelTransfer()
    }

    // MARK: - Helper Methods
    private func showAlert(message: String) {
        let alert = UIAlertController(
            title: "Notice",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - TransferDelegate
extension WatchFaceViewController: TransferDelegate {

    func transferDidStart() {
        DispatchQueue.main.async {
            self.statusLabel.text = "Transfer starting..."
            self.progressView.progress = 0.0
        }
    }

    func transferDidUpdateProgress(_ progress: TransferProgress) {
        DispatchQueue.main.async {
            self.progressView.progress = progress.percentage
            self.statusLabel.text = "Transferring: \(progress.message)"

            print("📊 Progress: \(progress.currentPacket)/\(progress.totalPackets) - \(progress.message)")
        }
    }

    func transferDidComplete() {
        DispatchQueue.main.async {
            self.statusLabel.text = "Upload successful!"
            self.progressView.progress = 1.0
            self.uploadButton.isEnabled = true

            self.showAlert(message: "Watch face uploaded successfully")
        }
    }

    func transferDidFail(error: Error) {
        DispatchQueue.main.async {
            self.statusLabel.text = "Upload failed"
            self.uploadButton.isEnabled = true

            self.showAlert(message: "Upload failed: \(error.localizedDescription)")
        }
    }

    func transferDidCancel() {
        DispatchQueue.main.async {
            self.statusLabel.text = "Cancelled"
            self.uploadButton.isEnabled = true

            self.showAlert(message: "Upload cancelled")
        }
    }
}
```

### Example: Get Device Information

```swift
if let screenInfo = WatchFaceManager.shared.getCurrentDeviceScreenInfo() {
    print("Device Screen Info:")
    print("  Width: \(screenInfo.width)")
    print("  Height: \(screenInfo.height)")
    print("  Shape: \(screenInfo.shape)")  // .round or .square

    if let recommendedSize = WatchFaceManager.shared.getRecommendedImageSize() {
        print("Recommended Image Size: \(recommendedSize)")
    }
} else {
    print("Device not connected or not supported")
}
```

### Example: Upload Market Watch Face

```swift
class MarketWatchFaceViewController: UIViewController, TransferDelegate {

    func uploadMarketWatchFace() {
        // Upload from local file
        guard let fileURL = Bundle.main.url(forResource: "market_dial_001", withExtension: "bin") else {
            print("File not found")
            return
        }

        do {
            try WatchFaceManager.shared.uploadMarketWatchFace(
                fileURL: fileURL,
                delegate: self
            )
            print("Starting market watch face upload...")
        } catch {
            print("Upload failed: \(error)")
        }
    }

    // MARK: - TransferDelegate
    func transferDidStart() {
        print("🚀 Transfer started")
    }

    func transferDidUpdateProgress(_ progress: TransferProgress) {
        print("📊 Progress: \(progress.message)")
    }

    func transferDidComplete() {
        print("✅ Transfer successful")
    }

    func transferDidFail(error: Error) {
        print("❌ Transfer failed: \(error)")
    }

    func transferDidCancel() {
        print("⏹ Transfer cancelled")
    }
}
```

---

## FAQ

### 1. Device Connection

**Q: How to connect the device?**

A: WatchFaceSDK itself does not handle device connection. You need to connect the device using WatchProtocolSDK first:

```swift
import WatchProtocolSDK

// Connect device
XGZTDeviceManager.shared.connectDevice(peripheral: peripheral) { success in
    if success {
        print("Device connected, can use WatchFaceSDK now")
    }
}
```

**Q: How to check if device supports watch face upload?**

A: Check if device screen information exists:

```swift
if WatchFaceManager.shared.getCurrentDeviceScreenInfo() != nil {
    print("Device supports watch face upload")
} else {
    print("Device not supported or not connected")
}
```

### 2. Image Processing

**Q: What image formats are supported?**

A: All standard iOS image formats (PNG, JPG, HEIC, etc.) are supported. SDK will automatically convert to PAR format required by the device.

**Q: What are the image size requirements?**

A:
- Minimum size: Should not be smaller than device screen size (e.g., 240x240, 240x280, etc.)
- Recommended size: 2x device screen size (e.g., 480x480)
- Maximum file size: Automatically compressed to within 120KB

```swift
// Get recommended size
if let size = WatchFaceManager.shared.getRecommendedImageSize() {
    print("Recommended image size: \(size)")
}
```

**Q: How are images processed for round screens?**

A: SDK automatically detects device screen shape and crops accordingly:
- Square screen: Center crop
- Round screen: Circular crop (preserves center area)

### 3. Transfer

**Q: How long does transfer take?**

A: Usually 10-30 seconds, depending on:
- File size (within 120KB)
- Bluetooth signal strength
- Device model

**Q: What to do if transfer fails?**

A: Common causes and solutions:

| Error | Cause | Solution |
|-------|-------|----------|
| `deviceNotConnected` | Device not connected | Ensure device is connected via WatchProtocolSDK |
| `deviceNotSupported` | Device not supported | Use a supported device model |
| `imageProcessFailed` | Image processing failed | Check image format and size |
| `transferFailed` | Transfer failed | Call `retryTransfer()` to retry |

**Q: Can I upload multiple watch faces simultaneously?**

A: No. SDK only supports one transfer task at a time. You need to wait for the current task to complete before starting a new one.

### 4. Error Handling

**Q: How to handle errors?**

A: Use do-catch to catch errors:

```swift
do {
    try WatchFaceManager.shared.uploadCustomWatchFace(
        image: image,
        timePosition: .center,
        color: .white,
        delegate: self
    )
} catch WatchFaceError.deviceNotConnected {
    print("Device not connected")
} catch WatchFaceError.imageProcessFailed {
    print("Image processing failed")
} catch {
    print("Other error: \(error)")
}
```

### 5. Performance Optimization

**Q: How to optimize upload speed?**

A:
1. Use smaller image sizes (recommended 2x device size)
2. Ensure good Bluetooth signal
3. Avoid other Bluetooth operations during upload

**Q: How to reduce memory usage?**

A:
1. Image processing automatically releases memory
2. Avoid loading multiple large images simultaneously
3. SDK automatically cleans cache after transfer completes

---

## Important Notes

### ⚠️ Important

1. **Device Connection**
   - Must connect device via WatchProtocolSDK before use
   - Check that `isDeviceConnected()` returns `true`

2. **Thread Safety**
   - TransferDelegate callbacks may execute on background threads
   - UI updates must switch to main thread:
   ```swift
   DispatchQueue.main.async {
       // Update UI
   }
   ```

3. **Image Requirements**
   - Recommended image size ≥ device screen size
   - Final file automatically compressed to within 120KB
   - Round screens automatically apply circular crop

4. **Transfer Control**
   - Only supports one transfer task at a time
   - Do not disconnect device during transfer
   - Can call `retryTransfer()` to retry on failure

5. **Error Handling**
   - Always use try-catch to handle possible errors
   - Implement complete TransferDelegate methods

---

## Debug Tips

### Enable Verbose Logging

```swift
// Enable verbose logging in AppDelegate
WatchFaceSDKConfig.configuration.enableVerboseLogging = true
```

### Print SDK Information

```swift
WatchFaceSDKConfig.printSDKInfo()
// Output:
// ==================================================
// WatchFaceSDK v1.0.0 (XGZT) - Build 2025-12-30
// ==================================================
```

### Monitor Transfer Progress

```swift
func transferDidUpdateProgress(_ progress: TransferProgress) {
    print("""
    📊 Transfer Progress:
       Current packet: \(progress.currentPacket)/\(progress.totalPackets)
       Transferred: \(progress.bytesTransferred)/\(progress.totalBytes) bytes
       Progress: \(progress.message)
    """)
}
```

---

## Technical Support

### 📚 Related Documentation

- `README.md` - Complete SDK usage manual
- `USAGE_EXAMPLES.md` - Detailed example code
- `WatchFaceSDK_ARCHITECTURE.md` - Architecture design documentation
- `INTEGRATION_GUIDE_CN.md` - Chinese integration guide

### 🔗 Related Links

- WatchProtocolSDK Documentation
- ABParTool Usage Guide

### 💬 Contact Us

For technical questions or support, please contact:

- Email: support@example.com
- Technical Support Team

---

**© 2025 Anker Innovations. All rights reserved.**

**WatchFaceSDK v1.0.0**
