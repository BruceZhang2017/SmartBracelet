# WatchProtocolSDK - Contact Sync Usage Guide

## Problem Diagnosis

The issue you're experiencing is because **contact synchronization is an asynchronous operation** that requires listening to Bluetooth device response notifications. Directly calling `setContactInfo` won't take effect immediately - you must follow the correct workflow.

---

## Prerequisites: Check Device Support

**IMPORTANT**: Not all devices support contact synchronization. You **must** check if the connected device supports this feature before attempting to sync contacts.

### Check Device Type

Only **XGZT protocol devices** support contact synchronization. Use the following code to verify:

```swift
import WatchProtocolSDK

// Method 1: Recommended (using Connection State Manager)
if XGZTConnectionStateManager.shared.isXGZTDevice {
    // Device supports contact sync
    print("✅ Device supports contact synchronization")
} else {
    // Device does NOT support contact sync
    print("❌ Device does not support contact synchronization")
    return
}

// Method 2: Legacy (deprecated but still works)
if isXGZT {
    // Device supports contact sync
}
```

### Complete Pre-Check Example

```swift
func checkContactSyncSupport() -> Bool {
    // 1. Check if device is connected
    guard XGZTConnectionStateManager.shared.isDeviceConnected else {
        print("⚠️ No device connected")
        return false
    }

    // 2. Check if device supports contact sync (XGZT only)
    guard XGZTConnectionStateManager.shared.isXGZTDevice else {
        print("⚠️ Connected device does not support contact synchronization")
        print("ℹ️ Only XGZT protocol devices support this feature")
        return false
    }

    print("✅ Device supports contact synchronization")
    return true
}

// Usage
if checkContactSyncSupport() {
    // Proceed with contact sync
    startContactSync()
} else {
    // Show error message to user
    showAlert("Contact sync is not supported on this device")
}
```

---

## Correct Usage Workflow

### 1. Pre-Sync Preparation: Clear Device Contacts

Before adding new contacts, you **must first call** `getContactInfo()` to clear old contact data on the device:

```swift
// Step 1: Clear device contacts
XGZTCommand.getContactInfo()
```

### 2. Listen for Device Response Notifications

Contact operations are **asynchronous** - you need to listen for notifications to get operation results:

```swift
class YourViewController: UIViewController {

    private var syncedCount = 0
    private var contactsToSync: [(name: String, phone: String)] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Register notification observer
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleContactResponse(_:)),
            name: Notification.Name("SyncContactsViewController"),
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleContactResponse(_ notification: Notification) {
        // Ensure UI updates on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if let result = notification.object as? String {
                if result == "0" {
                    // Operation successful
                    if self.syncedCount == -1 {
                        // getContactInfo succeeded, start adding contacts
                        self.syncedCount = 0
                        self.syncNextContact()
                    } else {
                        // setContactInfo succeeded, continue to next
                        self.syncedCount += 1
                        self.syncNextContact()
                    }
                } else {
                    // Operation failed
                    print("Sync failed with error code: \(result)")
                }
            }
        }
    }
}
```

### 3. Complete Sync Flow Example

```swift
class ContactSyncManager {

    private var contactsToSync: [(name: String, phone: String)] = []
    private var syncedCount = 0

    init() {
        // Register notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleContactResponse(_:)),
            name: Notification.Name("SyncContactsViewController"),
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// Start syncing contacts
    /// - Parameter contacts: List of contacts to sync (max 8)
    func startSync(contacts: [(name: String, phone: String)]) {
        // Check device support first
        guard XGZTConnectionStateManager.shared.isXGZTDevice else {
            print("⚠️ Device does not support contact synchronization")
            return
        }

        guard contacts.count <= 8 else {
            print("⚠️ Contact count exceeds limit (max 8)")
            return
        }

        self.contactsToSync = contacts
        self.syncedCount = -1  // -1 indicates sync not started yet

        // Step 1: Clear device contacts
        print("🔄 Clearing device contacts...")
        XGZTCommand.getContactInfo()
    }

    @objc private func handleContactResponse(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if let result = notification.object as? String {
                if result == "0" {
                    // Operation successful
                    if self.syncedCount == -1 {
                        // getContactInfo successful, start adding contacts
                        print("✅ Device contacts cleared, starting sync...")
                        self.syncedCount = 0
                        self.syncNextContact()
                    } else {
                        // setContactInfo successful
                        print("✅ Contact \(self.syncedCount) synced successfully")
                        self.syncedCount += 1
                        self.syncNextContact()
                    }
                } else {
                    print("❌ Sync failed with error code: \(result)")
                }
            }
        }
    }

    private func syncNextContact() {
        // Check if all contacts have been synced
        guard syncedCount < contactsToSync.count else {
            print("🎉 All contacts synced successfully!")
            return
        }

        let contact = contactsToSync[syncedCount]
        print("📤 Syncing contact \(syncedCount): \(contact.name) - \(contact.phone)")

        // Call SDK method
        XGZTCommand.setContactInfo(
            index: syncedCount,
            name: contact.name,
            phoneNumber: contact.phone
        )
    }
}
```

### 4. Usage Example

```swift
// Create contact manager
let syncManager = ContactSyncManager()

// Prepare contacts to sync (max 8)
let contacts = [
    (name: "Zhang San", phone: "13800138000"),
    (name: "Li Si", phone: "13900139000"),
    (name: "Wang Wu", phone: "13700137000"),
    (name: "John", phone: "1234567890"),
    (name: "Alice", phone: "9876543210")
]

// Start sync
syncManager.startSync(contacts: contacts)
```

---

## Key Points

### ✅ Must Follow Rules

1. **Check Device Support First**: Verify device is XGZT type using `XGZTConnectionStateManager.shared.isXGZTDevice`
2. **Clear then Add**: Call `getContactInfo()` to clear device contacts first
3. **Wait for Response**: Must wait for device response (via notification) after each operation
4. **Sequential Sync**: Can only sync one contact at a time, must wait for previous to succeed
5. **Quantity Limit**: Maximum **8 contacts**
6. **Listen to Notifications**: Notification name is `"SyncContactsViewController"`, returns `"0"` for success

### ❌ Common Mistakes

```swift
// ❌ Wrong Example 1: Not checking device support
XGZTCommand.setContactInfo(index: 0, name: "John", phoneNumber: "1234567890")
// Problem: Non-XGZT devices don't support contact sync, command will fail silently

// ❌ Wrong Example 2: Batch adding without waiting for response
for i in 0..<5 {
    XGZTCommand.setContactInfo(index: i, name: "Contact \(i)", phoneNumber: "555-000\(i)")
}
// Problem: Bluetooth device cannot handle concurrent requests, data will be lost

// ❌ Wrong Example 3: Adding without clearing first
XGZTCommand.setContactInfo(index: 0, name: "John", phoneNumber: "1234567890")
// Problem: Device may retain old data, causing data corruption

// ❌ Wrong Example 4: Not listening to notifications
XGZTCommand.getContactInfo()
XGZTCommand.setContactInfo(index: 0, name: "John", phoneNumber: "1234567890")
// Problem: Cannot know if operation succeeded, unable to proceed
```

---

## Data Format Specifications

### Phone Number Processing

The SDK automatically filters the following characters, keeping only digits:
- Dots `.`
- Hyphens `-`
- Parentheses `()` `（）`
- Spaces

**Example**:
```swift
// Input: (123) 456-7890
// SDK processes to: 1234567890

XGZTCommand.setContactInfo(
    index: 0,
    name: "John",
    phoneNumber: "(123) 456-7890"  // SDK auto-cleans
)
```

### Name Length Limit

- Maximum bytes: **30 bytes** (UTF-8 encoding)
- Chinese characters typically take 3 bytes each
- Excess will be automatically truncated

**Example**:
```swift
// ✅ Normal: About 10 Chinese characters
XGZTCommand.setContactInfo(index: 0, name: "张三李四王五赵六", phoneNumber: "123")

// ⚠️ Too long: Will be auto-truncated to 30 bytes
XGZTCommand.setContactInfo(index: 0, name: "Very very very very long name...", phoneNumber: "123")
```

---

## Debugging Tips

### 1. Add Logging

```swift
@objc private func handleContactResponse(_ notification: Notification) {
    if let result = notification.object as? String {
        print("📱 Device response: \(result == "0" ? "Success" : "Failed(\(result))")")
        print("📊 Progress: \(syncedCount + 1)/\(contactsToSync.count)")
    }
}
```

### 2. Check Bluetooth Connection

Ensure device is connected:
```swift
if XGZTBlueToothManager.shared.isConnected {
    syncManager.startSync(contacts: contacts)
} else {
    print("⚠️ Device not connected")
}
```

### 3. Handle Timeout

Add timeout mechanism to prevent hanging:
```swift
private var syncTimer: Timer?

private func syncNextContact() {
    // Cancel old timer
    syncTimer?.invalidate()

    // Set 5 second timeout
    syncTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
        print("⚠️ Sync timeout, please check device connection")
        self?.handleSyncTimeout()
    }

    // Send command
    XGZTCommand.setContactInfo(...)
}
```

---

## Complete Production-Ready Example

```swift
import Foundation
import WatchProtocolSDK

class ContactSyncService {

    static let shared = ContactSyncService()

    private var contactsToSync: [(name: String, phone: String)] = []
    private var syncedCount = 0
    private var isSyncing = false
    private var syncTimer: Timer?

    var onProgress: ((Int, Int) -> Void)?  // (current, total)
    var onComplete: ((Bool, String) -> Void)?  // (success, message)

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleContactResponse(_:)),
            name: Notification.Name("SyncContactsViewController"),
            object: nil
        )
    }

    func syncContacts(_ contacts: [(name: String, phone: String)]) {
        // 1. Check device support
        guard XGZTConnectionStateManager.shared.isXGZTDevice else {
            onComplete?(false, "Device does not support contact synchronization")
            return
        }

        guard !isSyncing else {
            onComplete?(false, "Sync already in progress, please wait")
            return
        }

        guard contacts.count <= 8 else {
            onComplete?(false, "Contact count cannot exceed 8")
            return
        }

        guard !contacts.isEmpty else {
            onComplete?(false, "Contact list is empty")
            return
        }

        isSyncing = true
        contactsToSync = contacts
        syncedCount = -1

        print("🔄 Starting sync of \(contacts.count) contacts...")
        XGZTCommand.getContactInfo()
        startTimeout()
    }

    @objc private func handleContactResponse(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.isSyncing else { return }

            self.cancelTimeout()

            if let result = notification.object as? String {
                if result == "0" {
                    if self.syncedCount == -1 {
                        // Clear successful, start adding
                        print("✅ Device cleared")
                        self.syncedCount = 0
                        self.syncNextContact()
                    } else {
                        // Add successful
                        print("✅ Contact \(self.syncedCount + 1) synced successfully")
                        self.onProgress?(self.syncedCount + 1, self.contactsToSync.count)

                        self.syncedCount += 1
                        self.syncNextContact()
                    }
                } else {
                    self.handleError("Sync failed with error code: \(result)")
                }
            }
        }
    }

    private func syncNextContact() {
        guard syncedCount < contactsToSync.count else {
            handleComplete()
            return
        }

        let contact = contactsToSync[syncedCount]
        XGZTCommand.setContactInfo(
            index: syncedCount,
            name: contact.name,
            phoneNumber: contact.phone
        )
        startTimeout()
    }

    private func startTimeout() {
        cancelTimeout()
        syncTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            self?.handleError("Sync timeout, please check device connection")
        }
    }

    private func cancelTimeout() {
        syncTimer?.invalidate()
        syncTimer = nil
    }

    private func handleComplete() {
        isSyncing = false
        cancelTimeout()
        print("🎉 All contacts synced successfully")
        onComplete?(true, "Sync completed")
    }

    private func handleError(_ message: String) {
        isSyncing = false
        cancelTimeout()
        print("❌ \(message)")
        onComplete?(false, message)
    }
}

// Usage Example
let service = ContactSyncService.shared

service.onProgress = { current, total in
    print("Progress: \(current)/\(total)")
}

service.onComplete = { success, message in
    print(success ? "✅ \(message)" : "❌ \(message)")
}

let contacts = [
    (name: "John Doe", phone: "13800138000"),
    (name: "Jane Smith", phone: "13900139000")
]

service.syncContacts(contacts)
```

---

## Summary

The core of contact synchronization is the **asynchronous response mechanism** with **device support verification**. Remember this flow:

### Complete Workflow

0. **Pre-check**: Verify `XGZTConnectionStateManager.shared.isXGZTDevice` returns `true`
1. **Clear**: Call `getContactInfo()` → Wait for response "0"
2. **Loop**: Call `setContactInfo(index)` → Wait for response "0" → index++
3. **Complete**: All contacts synced

For questions, refer to the `SyncContactsViewController.swift` file in the project (lines 479-564) for complete implementation.

---

## Quick Reference

| Step | Action | Wait For | Notes |
|------|--------|----------|-------|
| 0 | Check device support | - | `XGZTConnectionStateManager.shared.isXGZTDevice` must be `true` |
| 1 | `XGZTCommand.getContactInfo()` | Notification: `"0"` | Clears all contacts on device |
| 2 | `XGZTCommand.setContactInfo(index: 0, ...)` | Notification: `"0"` | First contact |
| 3 | `XGZTCommand.setContactInfo(index: 1, ...)` | Notification: `"0"` | Second contact |
| ... | Continue for each contact | Each notification | Max 8 contacts |
| Done | All contacts synced | - | Show success message |

**Critical**:
- ⚠️ Never proceed to next step without receiving success notification (`"0"`)!
- ⚠️ Only XGZT protocol devices support contact synchronization!
- ⚠️ Notification name: `"SyncContactsViewController"`
