# WatchFaceSDK v1.0.3 - Critical Hotfix Release

**Release Date**: January 14, 2026
**Release Type**: Critical Bug Fix
**Urgency**: 🔴 **IMMEDIATE UPDATE REQUIRED**

---

## ⚠️ Critical Issue Fixed

### Crash in uploadCustomWatchFace()

**Problem**:
- SDK v1.0.2 crashes with `EXC_BAD_ACCESS` when calling `uploadCustomWatchFace()`
- Crash occurs in `UIImage.rawImageData` getter
- Affects **ALL users** calling the custom watch face upload feature

**Impact**:
- 🔴 Critical: Complete feature failure
- 🔴 App crashes when uploading custom watch faces
- 🔴 Affects 100% of custom watch face uploads

**Resolution**:
- ✅ Fixed memory safety issue
- ✅ Removed symbol conflict
- ✅ Now stable and reliable

---

## 🔧 What Was Fixed

### Technical Details

1. **Removed Duplicate Implementation**
   - WatchFaceSDK previously defined its own `UIImage.rawImageData` extension
   - This conflicted with ABParTool.framework's implementation
   - Caused runtime symbol resolution issues

2. **Fixed Memory Safety Issue**
   - Previous implementation used unsafe Swift memory operations
   - Used `&rawData` pointer that could become invalid
   - Led to `EXC_BAD_ACCESS (code=2)` crashes

3. **Now Uses Stable Implementation**
   - Exclusively uses ABParTool's proven Objective-C implementation
   - Proper memory management
   - No symbol conflicts

### Changed File
- `WatchFaceSDK/WatchFaceSDK/Extensions/ImageProcessor.swift`
- Removed unsafe UIImage extension (lines 194-225)

---

## 📦 What's Included

### Framework
- ✅ **WatchFaceSDK.xcframework** (3.9 MB)
  - iOS Device (arm64)
  - iOS Simulator (arm64 + x86_64)
  - Includes embedded dependencies:
    - WatchProtocolSDK.framework
    - ABParTool.framework

### Documentation
- ✅ **VERSION.txt** - Version information
- ✅ **README.md** - Quick start guide
- ✅ **HOTFIX-v1.0.3-CRASH-FIX.md** - Hotfix summary
- ✅ **CRASH-FIX-ANALYSIS.md** - Detailed technical analysis
- ✅ **WatchFaceSDK-接入文档-中文.md** - Chinese integration guide
- ✅ **WatchFaceSDK-Integration-Guide-EN.md** - English integration guide
- ✅ **RELEASE-NOTES-v1.0.3.md** - This file

---

## 🚀 How to Update

### For Existing Users

**No code changes required!** This is a drop-in replacement.

1. **Remove Old Version**
   - Delete `WatchFaceSDK.xcframework` v1.0.2 from your project

2. **Add New Version**
   - Drag `WatchFaceSDK.xcframework` v1.0.3 into your project
   - Target → General → Frameworks, Libraries, and Embedded Content
   - Set Embed to "Embed & Sign"

3. **Clean Build**
   - Product → Clean Build Folder (⌘⇧K)
   - Rebuild your project

4. **Test**
   - Verify `uploadCustomWatchFace()` works without crashing
   - Test with various image sizes and formats

### Verification

Check your integrated version:
```swift
print(WatchFaceSDK.version) // Should show "1.0.3"
```

Or check VERSION.txt file in the xcframework.

---

## ✅ API Compatibility

| Feature | v1.0.2 | v1.0.3 | Notes |
|---------|---------|---------|-------|
| uploadCustomWatchFace() | ❌ Crashes | ✅ Works | **FIXED** |
| uploadMarketWatchFace() | ✅ Works | ✅ Works | No change |
| All other APIs | ✅ Works | ✅ Works | No change |

**100% API Compatible** - No code changes needed!

---

## 📊 Verified Architectures

```
✅ iOS Device (arm64)
✅ iOS Simulator (arm64)
✅ iOS Simulator (x86_64)
```

All architectures tested and verified.

---

## 🧪 Testing Checklist

Before releasing to your users:

- [ ] Framework integrated successfully
- [ ] Project builds without errors
- [ ] `uploadCustomWatchFace()` doesn't crash
- [ ] Custom watch face uploads successfully
- [ ] Transfer progress callbacks work
- [ ] Market watch face upload still works
- [ ] No new warnings or errors

---

## 📋 System Requirements

- **iOS**: 12.0+
- **Xcode**: 12.0+
- **Swift**: 5.0+
- **Dependencies**:
  - WatchProtocolSDK v1.0.2 (included)
  - ABParTool (included)

---

## 🔄 Version History

### v1.0.3 (2026-01-14) - **CURRENT**
- 🔧 **CRITICAL FIX**: Resolved EXC_BAD_ACCESS crash in uploadCustomWatchFace()
- 🔧 Removed duplicate UIImage.rawImageData extension
- 🔧 Eliminated symbol conflict with ABParTool
- 🔧 Fixed memory safety issue
- ✅ No API changes - drop-in replacement

### v1.0.2 (2026-01-11) - **DEPRECATED**
- ⚠️ **DO NOT USE**: Contains critical crash bug
- Enhanced transfer stability (other features)
- Improved image processing performance (other features)

### v1.0.1 (2026-01-05)
- Added custom watch face support
- Improved market watch face upload

### v1.0.0 (2025-12-30)
- Initial release

---

## 📞 Support

### Common Issues

**Q: Still seeing crashes after update?**
- Ensure you're using v1.0.3 (check VERSION.txt)
- Clean build folder (⌘⇧K)
- Delete derived data
- Restart Xcode

**Q: Upgrade from v1.0.2?**
- Yes, **immediately**! v1.0.2 has critical crash bug
- Drop-in replacement, no code changes needed

**Q: Compatible with WatchProtocolSDK v1.0.2?**
- Yes, fully compatible
- WatchProtocolSDK v1.0.2 is included

### Contact

For issues or questions:
- Check documentation in this package
- Review CRASH-FIX-ANALYSIS.md for technical details
- Contact technical support with:
  - SDK version (from VERSION.txt)
  - Crash logs if applicable
  - Xcode version
  - iOS version

---

## ⚠️ Important Notice

**This is a critical security and stability update.**

- v1.0.2 contains a severe memory access bug
- All users **must** upgrade to v1.0.3
- Failure to upgrade will result in app crashes
- Custom watch face feature is completely broken in v1.0.2

**Action Required**:
1. Stop using v1.0.2 immediately
2. Upgrade to v1.0.3
3. Test thoroughly before releasing to production
4. Notify your users if you shipped v1.0.2

---

## ✨ Features (Unchanged)

All features from v1.0.2 remain functional:

- ✅ Market watch face upload
- ✅ Custom watch face upload (**NOW FIXED**)
- ✅ Smart image processing (PAR conversion)
- ✅ Circle/Square screen adaptation
- ✅ Real-time transfer progress
- ✅ Automatic image compression
- ✅ Comprehensive error handling
- ✅ Thread-safe design

---

**Thank you for updating!**

If you encounter any issues with v1.0.3, please report them immediately.

---

**© 2025-2026 bruce. All Rights Reserved.**

**Release Compiled**: January 14, 2026
**Framework Size**: 3.9 MB
**Status**: ✅ Production Ready
