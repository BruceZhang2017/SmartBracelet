# WatchFaceSDK v1.0.3 - Crash Hotfix

## 🐛 Bug Fix

**Issue**: SDK v1.0.2 crashes when calling `uploadCustomWatchFace`
- **Error**: `EXC_BAD_ACCESS (code=2)` in `UIImage.rawImageData` getter
- **Affected Method**: `WatchFaceManager.uploadCustomWatchFace()`

## 🔍 Root Cause

1. **Symbol Conflict**: WatchFaceSDK defined its own `UIImage.rawImageData` extension that conflicted with ABParTool's implementation
2. **Memory Safety Issue**: The Swift implementation used unsafe memory operations (`&rawData`) that caused access violations

## ✅ Solution

Removed the duplicate `UIImage.rawImageData` extension from WatchFaceSDK. Now uses ABParTool's stable Objective-C implementation directly.

## 📦 Changes

**File Modified**: `WatchFaceSDK/WatchFaceSDK/Extensions/ImageProcessor.swift`
- Removed lines 194-225 (duplicate `UIImage.rawImageData` extension)
- Added comment explaining the change

## 🚀 How to Use Fixed Version

### Option 1: Wait for Official Release (Recommended)
Wait for the rebuilt WatchFaceSDK.xcframework to be provided

### Option 2: Temporary Workaround
If you need an immediate fix, you can bypass the issue by:

```swift
// Instead of:
try WatchFaceManager.shared.uploadCustomWatchFace(
    image: image,
    timePosition: .center,
    color: .white,
    delegate: self
)

// Use the lower-level API directly:
import ABParTool

// 1. Process image manually
let targetSize = CGSize(width: 240, height: 280) // Use your device screen size
guard let cgImage = image.cgImage else { return }

// 2. Use ABParTool's rawImageData (from UIImage+RawImageData.h)
guard let rawData = image.rawImageData else {
    print("Failed to get raw image data")
    return
}

// 3. Convert to PAR
guard let parData = ParTool.par(
    fromRaw: rawData,
    width: Int32(targetSize.width),
    height: Int32(targetSize.height),
    runAlpha: false,
    useFilter: false,
    supportRotate: false
) else {
    print("Failed to convert to PAR")
    return
}

// 4. Upload using WatchProtocolSDK directly
// (This is a simplified example - full implementation requires more setup)
```

## 📋 Version Info

- **Version**: 1.0.3
- **Release Date**: 2026-01-14
- **Changes**: Fixed memory crash in uploadCustomWatchFace

## 🔄 Migration from v1.0.2

No code changes required. Simply replace the old xcframework with the new one.

---

**Critical Fix**: This resolves a crash that affects all users calling `uploadCustomWatchFace()`. Please update immediately.
