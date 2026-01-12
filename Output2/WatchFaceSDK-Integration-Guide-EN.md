# WatchFaceSDK Integration Guide (English)

## 📚 Table of Contents

1. [Overview](#overview)
2. [Requirements](#requirements)
3. [Integration](#integration)
4. [Core Features](#core-features)
5. [API Reference](#api-reference)
6. [Usage Examples](#usage-examples)
7. [Error Handling](#error-handling)
8. [Best Practices](#best-practices)
9. [FAQ](#faq)

---

## Overview

WatchFaceSDK is an iOS SDK for uploading watch faces to smart watches, supporting both market watch faces and custom watch faces.

### Key Features

- ✅ **Market Watch Face Upload**: Support for pre-designed watch face files
- ✅ **Custom Watch Faces**: Generate custom watch faces from images
- ✅ **Image Processing**: Automatic image format, size, and compression handling
- ✅ **Screen Adaptation**: Auto-adapt to circular and square screens
- ✅ **Progress Callbacks**: Real-time transfer progress updates
- ✅ **Error Handling**: Comprehensive error reporting and handling

### Architecture

WatchFaceSDK depends on WatchProtocolSDK for Bluetooth communication, using a protocol-based approach for watch face data transfer.

```
┌─────────────────────┐
│   Your App          │
├─────────────────────┤
│  WatchFaceSDK       │  ← Watch Face Layer
├─────────────────────┤
│  WatchProtocolSDK   │  ← Bluetooth Layer
├─────────────────────┤
│  CoreBluetooth      │  ← System Framework
└─────────────────────┘
```

---

## Requirements

- **iOS**: 12.0+
- **Xcode**: 12.0+
- **Swift**: 5.0+
- **Dependencies**: WatchProtocolSDK v1.0.2

---

## Integration

### Step 1: Add Framework

1. Drag `WatchFaceSDK.xcframework` into your Xcode project
2. Verify it's added in Target -> General -> Frameworks, Libraries, and Embedded Content
3. Set Embed to "Embed & Sign"

### Step 2: Configure Dependencies

Ensure WatchProtocolSDK and its dependencies are integrated. Add to `Podfile`:

```ruby
# WatchProtocolSDK dependencies
pod 'SwiftyJSON'
pod 'CryptoSwift'
```

Then run:
```bash
pod install
```

### Step 3: Configure Permissions

Add required permissions to `Info.plist`:

```xml
<!-- Bluetooth Permission -->
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Bluetooth is required to connect to smart watch devices</string>

<!-- Photo Library Permission (for custom watch faces) -->
<key>NSPhotoLibraryUsageDescription</key>
<string>Photo library access is needed to select watch face images</string>

<!-- Camera Permission (optional) -->
<key>NSCameraUsageDescription</key>
<string>Camera access is needed to capture watch face images</string>
```

### Step 4: Import Modules

```swift
import WatchFaceSDK
import WatchProtocolSDK
```

---

## Core Features

### 1. Watch Face Manager

`WatchFaceManager` is the core class of the SDK, using singleton pattern:

```swift
let manager = WatchFaceManager.shared
```

### 2. Upload Market Watch Face

Market watch faces are pre-designed watch face files, usually professionally created watch face packages.

```swift
func uploadMarketWatchFace(
    fileURL: URL,
    delegate: TransferDelegate?
) throws
```

**Parameters**:
- `fileURL`: Watch face file URL
- `delegate`: Transfer progress delegate

### 3. Upload Custom Watch Face

Custom watch faces are generated from images with customizable time position and color.

```swift
func uploadCustomWatchFace(
    image: UIImage,
    timePosition: TimePosition,
    color: UIColor,
    delegate: TransferDelegate?
) throws
```

**Parameters**:
- `image`: Watch face background image
- `timePosition`: Time display position (.top, .center, .bottom)
- `color`: Time display color
- `delegate`: Transfer progress delegate

### 4. Time Position Enum

```swift
public enum TimePosition {
    case top      // Top
    case center   // Center
    case bottom   // Bottom
}
```

---

## API Reference

### WatchFaceManager

#### Shared Instance
```swift
static let shared: WatchFaceManager
```

#### Upload Market Watch Face
```swift
func uploadMarketWatchFace(
    fileURL: URL,
    delegate: TransferDelegate?
) throws
```

**Throws**:
- `WatchFaceError.fileNotFound`: File not found
- `WatchFaceError.invalidFileFormat`: Invalid file format
- `WatchFaceError.fileSizeExceeded`: File size exceeded
- `WatchFaceError.deviceNotConnected`: Device not connected

#### Upload Custom Watch Face
```swift
func uploadCustomWatchFace(
    image: UIImage,
    timePosition: TimePosition = .center,
    color: UIColor = .white,
    delegate: TransferDelegate?
) throws
```

**Throws**:
- `WatchFaceError.invalidImage`: Invalid image
- `WatchFaceError.imageProcessingFailed`: Image processing failed
- `WatchFaceError.deviceNotConnected`: Device not connected

#### Cancel Transfer
```swift
func cancelTransfer()
```

### TransferDelegate

Transfer progress callback protocol:

```swift
protocol TransferDelegate: AnyObject {
    /// Transfer started
    func transferDidStart()

    /// Transfer progress updated
    /// - Parameter progress: Transfer progress object
    func transferDidUpdateProgress(_ progress: TransferProgress)

    /// Transfer completed
    func transferDidComplete()

    /// Transfer failed
    /// - Parameter error: Error information
    func transferDidFail(error: Error)
}
```

### TransferProgress

Transfer progress object:

```swift
public struct TransferProgress {
    public let currentPacket: Int      // Current packet number
    public let totalPackets: Int       // Total packets
    public let percentage: Double      // Progress percentage (0.0 - 1.0)
    public let speed: Double           // Transfer speed (bytes/s)
    public let remainingTime: TimeInterval  // Estimated remaining time (seconds)
}
```

---

## Usage Examples

### Example 1: Upload Market Watch Face

```swift
import UIKit
import WatchFaceSDK

class MarketWatchFaceViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        uploadMarketWatchFace()
    }

    func uploadMarketWatchFace() {
        // Get watch face file URL
        guard let fileURL = Bundle.main.url(
            forResource: "watchface_market_001",
            withExtension: "bin"
        ) else {
            print("❌ Watch face file not found")
            return
        }

        // Upload watch face
        do {
            try WatchFaceManager.shared.uploadMarketWatchFace(
                fileURL: fileURL,
                delegate: self
            )
        } catch {
            print("❌ Upload failed: \(error.localizedDescription)")
            showError(error)
        }
    }

    func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Upload Failed",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - TransferDelegate

extension MarketWatchFaceViewController: TransferDelegate {

    func transferDidStart() {
        DispatchQueue.main.async {
            print("🚀 Upload started")
            // Show loading indicator
        }
    }

    func transferDidUpdateProgress(_ progress: TransferProgress) {
        DispatchQueue.main.async {
            let percentage = Int(progress.percentage * 100)
            print("📊 Progress: \(percentage)%")
            print("⚡ Speed: \(progress.speed) bytes/s")
            print("⏱ Remaining: \(progress.remainingTime) seconds")
            // Update progress bar
        }
    }

    func transferDidComplete() {
        DispatchQueue.main.async {
            print("✅ Upload successful")
            // Hide loading indicator, show success message
        }
    }

    func transferDidFail(error: Error) {
        DispatchQueue.main.async {
            print("❌ Upload failed: \(error.localizedDescription)")
            self.showError(error)
        }
    }
}
```

### Example 2: Upload Custom Watch Face

```swift
import UIKit
import WatchFaceSDK

class CustomWatchFaceViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var statusLabel: UILabel!

    var selectedImage: UIImage?

    // MARK: - Actions

    @IBAction func selectImageTapped(_ sender: UIButton) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }

    @IBAction func uploadTapped(_ sender: UIButton) {
        uploadCustomWatchFace()
    }

    // MARK: - Upload

    func uploadCustomWatchFace() {
        guard let image = selectedImage else {
            showAlert("Please select an image first")
            return
        }

        do {
            try WatchFaceManager.shared.uploadCustomWatchFace(
                image: image,
                timePosition: .center,
                color: .white,
                delegate: self
            )
        } catch {
            print("❌ Upload failed: \(error)")
            showAlert(error.localizedDescription)
        }
    }

    func showAlert(_ message: String) {
        let alert = UIAlertController(
            title: "Notice",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate

extension CustomWatchFaceViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        if let image = info[.originalImage] as? UIImage {
            selectedImage = image
            imageView.image = image
        }
        picker.dismiss(animated: true)
    }
}

// MARK: - TransferDelegate

extension CustomWatchFaceViewController: TransferDelegate {

    func transferDidStart() {
        DispatchQueue.main.async {
            self.statusLabel.text = "Uploading..."
            self.progressView.progress = 0
        }
    }

    func transferDidUpdateProgress(_ progress: TransferProgress) {
        DispatchQueue.main.async {
            self.progressView.progress = Float(progress.percentage)
            let percentage = Int(progress.percentage * 100)
            self.statusLabel.text = "Uploading... \(percentage)%"
        }
    }

    func transferDidComplete() {
        DispatchQueue.main.async {
            self.statusLabel.text = "Upload successful!"
            self.progressView.progress = 1.0
            self.showAlert("Watch face uploaded successfully")
        }
    }

    func transferDidFail(error: Error) {
        DispatchQueue.main.async {
            self.statusLabel.text = "Upload failed"
            self.progressView.progress = 0
            self.showAlert("Upload failed: \(error.localizedDescription)")
        }
    }
}
```

### Example 3: Cancel Transfer

```swift
class WatchFaceViewController: UIViewController {

    @IBAction func cancelTapped(_ sender: UIButton) {
        WatchFaceManager.shared.cancelTransfer()
        print("Transfer cancelled")
    }
}
```

---

## Error Handling

### Error Types

```swift
public enum WatchFaceError: Error {
    case fileNotFound           // File not found
    case invalidFileFormat      // Invalid file format
    case fileSizeExceeded       // File size exceeded
    case invalidImage           // Invalid image
    case imageProcessingFailed  // Image processing failed
    case deviceNotConnected     // Device not connected
    case transferFailed         // Transfer failed
    case transferCancelled      // Transfer cancelled
}
```

### Error Handling Example

```swift
func handleWatchFaceError(_ error: Error) {
    if let watchFaceError = error as? WatchFaceError {
        switch watchFaceError {
        case .fileNotFound:
            print("Watch face file not found")
        case .invalidFileFormat:
            print("Invalid watch face file format")
        case .fileSizeExceeded:
            print("Watch face file too large")
        case .invalidImage:
            print("Invalid image")
        case .imageProcessingFailed:
            print("Image processing failed")
        case .deviceNotConnected:
            print("Device not connected, please connect first")
        case .transferFailed:
            print("Transfer failed, please retry")
        case .transferCancelled:
            print("Transfer cancelled")
        }
    } else {
        print("Unknown error: \(error.localizedDescription)")
    }
}
```

---

## Best Practices

### 1. Device Connection Check

Before uploading a watch face, ensure the device is connected:

```swift
import WatchProtocolSDK

func checkDeviceConnection() -> Bool {
    guard XGZTBlueToothManager.shared.isConnected else {
        print("Device not connected")
        return false
    }
    return true
}

func uploadWatchFace() {
    guard checkDeviceConnection() else {
        showAlert("Please connect device first")
        return
    }

    // Continue with upload...
}
```

### 2. Image Optimization

For custom watch faces, it's recommended to optimize images first:

```swift
extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

// Usage example
if let originalImage = UIImage(named: "watchface"),
   let resizedImage = originalImage.resized(to: CGSize(width: 240, height: 240)) {
    try WatchFaceManager.shared.uploadCustomWatchFace(
        image: resizedImage,
        timePosition: .center,
        color: .white,
        delegate: self
    )
}
```

### 3. Thread Safety

All UI updates should be performed on the main thread:

```swift
func transferDidUpdateProgress(_ progress: TransferProgress) {
    DispatchQueue.main.async {
        // Update UI
        self.progressView.progress = Float(progress.percentage)
    }
}
```

### 4. Memory Management

For large images, pay attention to memory release:

```swift
func processLargeImage() {
    autoreleasepool {
        if let image = UIImage(contentsOfFile: imagePath) {
            // Process image
            try? WatchFaceManager.shared.uploadCustomWatchFace(
                image: image,
                timePosition: .center,
                color: .white,
                delegate: self
            )
        }
    }
}
```

### 5. Retry Mechanism

```swift
class WatchFaceUploader {
    private var retryCount = 0
    private let maxRetries = 3

    func uploadWithRetry(image: UIImage) {
        do {
            try WatchFaceManager.shared.uploadCustomWatchFace(
                image: image,
                timePosition: .center,
                color: .white,
                delegate: self
            )
        } catch {
            if retryCount < maxRetries {
                retryCount += 1
                print("Upload failed, retry \(retryCount) of \(maxRetries)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.uploadWithRetry(image: image)
                }
            } else {
                print("Max retries reached, upload failed")
            }
        }
    }
}
```

---

## FAQ

### Q1: Upload failed with device not connected error?

**A**: Ensure device is connected via WatchProtocolSDK:

```swift
// Initialize Bluetooth
XGZTBlueToothManager.shared.initCentral()

// Scan for devices
XGZTBlueToothManager.shared.scanDevice { peripheral, macAddress in
    print("Device found: \(macAddress)")
}

// Connect device
XGZTBlueToothManager.shared.connectDevice(macAddress) { success in
    if success {
        print("Connected successfully")
        // Now you can upload watch face
    }
}
```

### Q2: Image processing failed?

**A**: Check image format and size:
- Supported formats: PNG, JPG
- Recommended size: equal to or larger than device screen size
- Image must not be nil or corrupted

### Q3: Slow transfer speed?

**A**: Possible reasons:
- Weak Bluetooth signal
- Large image file size
- Device performance limitations

Recommendations:
- Keep device within 5 meters
- Compress image size
- Avoid other Bluetooth operations during transfer

### Q4: How to customize time display?

**A**: Use `TimePosition` and color parameters:

```swift
// Time at top, red color
try WatchFaceManager.shared.uploadCustomWatchFace(
    image: image,
    timePosition: .top,
    color: .red,
    delegate: self
)

// Time at center, white color
try WatchFaceManager.shared.uploadCustomWatchFace(
    image: image,
    timePosition: .center,
    color: .white,
    delegate: self
)

// Time at bottom, blue color
try WatchFaceManager.shared.uploadCustomWatchFace(
    image: image,
    timePosition: .bottom,
    color: .blue,
    delegate: self
)
```

### Q5: How to handle multiple watch face uploads?

**A**: SDK doesn't support concurrent uploads, upload one by one:

```swift
class BatchUploader: TransferDelegate {
    private var watchFaces: [UIImage] = []
    private var currentIndex = 0

    func uploadAll(images: [UIImage]) {
        self.watchFaces = images
        self.currentIndex = 0
        uploadNext()
    }

    private func uploadNext() {
        guard currentIndex < watchFaces.count else {
            print("All watch faces uploaded")
            return
        }

        let image = watchFaces[currentIndex]
        try? WatchFaceManager.shared.uploadCustomWatchFace(
            image: image,
            timePosition: .center,
            color: .white,
            delegate: self
        )
    }

    func transferDidComplete() {
        currentIndex += 1
        uploadNext()
    }

    func transferDidFail(error: Error) {
        print("Watch face \(currentIndex + 1) upload failed")
        // Decide whether to continue or stop
        currentIndex += 1
        uploadNext()
    }
}
```

---

## Technical Support

For more questions, contact:
- Email: support@example.com
- GitHub: https://github.com/yourcompany/WatchFaceSDK

---

**© 2025-2026 Your Company. All Rights Reserved.**
