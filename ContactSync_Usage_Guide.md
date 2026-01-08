# WatchProtocolSDK - 联系人同步使用指南

## 问题诊断

您遇到的问题是因为**联系人同步是异步操作**，需要监听蓝牙设备的响应通知。直接调用 `setContactInfo` 不会立即生效，必须按照正确的流程进行。

---

## 前提条件：检查设备支持

**重要提示**：并非所有设备都支持联系人同步功能。在尝试同步联系人之前，**必须**检查连接的设备是否支持此功能。

### 检查设备类型

只有 **XGZT 协议设备**支持联系人同步。使用以下代码验证：

```swift
import WatchProtocolSDK

// 方法1：推荐（使用连接状态管理器）
if XGZTConnectionStateManager.shared.isXGZTDevice {
    // 设备支持联系人同步
    print("✅ 设备支持联系人同步")
} else {
    // 设备不支持联系人同步
    print("❌ 设备不支持联系人同步")
    return
}

// 方法2：旧版本（已弃用但仍可用）
if isXGZT {
    // 设备支持联系人同步
}
```

### 完整的预检查示例

```swift
func checkContactSyncSupport() -> Bool {
    // 1. 检查设备是否已连接
    guard XGZTConnectionStateManager.shared.isDeviceConnected else {
        print("⚠️ 没有连接的设备")
        return false
    }

    // 2. 检查设备是否支持联系人同步（仅限 XGZT）
    guard XGZTConnectionStateManager.shared.isXGZTDevice else {
        print("⚠️ 已连接的设备不支持联系人同步")
        print("ℹ️ 仅 XGZT 协议设备支持此功能")
        return false
    }

    print("✅ 设备支持联系人同步")
    return true
}

// 使用示例
if checkContactSyncSupport() {
    // 继续同步联系人
    startContactSync()
} else {
    // 向用户显示错误信息
    showAlert("该设备不支持联系人同步")
}
```

---

## 正确的使用流程

### 1. 同步前准备：清空设备联系人

在添加新联系人之前，**必须先调用** `getContactInfo()` 清空设备上的旧联系人数据：

```swift
// 第一步：清空设备联系人
XGZTCommand.getContactInfo()
```

### 2. 监听设备响应通知

联系人操作是**异步**的，需要监听通知来获取操作结果：

```swift
class YourViewController: UIViewController {

    private var syncedCount = 0
    private var contactsToSync: [(name: String, phone: String)] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // 注册通知监听
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
        // 确保在主线程更新UI
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if let result = notification.object as? String {
                if result == "0" {
                    // 操作成功
                    if self.syncedCount == -1 {
                        // getContactInfo 成功，开始添加联系人
                        self.syncedCount = 0
                        self.syncNextContact()
                    } else {
                        // setContactInfo 成功，继续下一个
                        self.syncedCount += 1
                        self.syncNextContact()
                    }
                } else {
                    // 操作失败
                    print("同步失败，错误代码：\(result)")
                }
            }
        }
    }
}
```

### 3. 完整的同步流程示例

```swift
class ContactSyncManager {

    private var contactsToSync: [(name: String, phone: String)] = []
    private var syncedCount = 0

    init() {
        // 注册通知
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

    /// 开始同步联系人
    /// - Parameter contacts: 要同步的联系人列表（最多8个）
    func startSync(contacts: [(name: String, phone: String)]) {
        // 首先检查设备支持
        guard XGZTConnectionStateManager.shared.isXGZTDevice else {
            print("⚠️ 设备不支持联系人同步")
            return
        }

        guard contacts.count <= 8 else {
            print("⚠️ 联系人数量超过限制（最多8个）")
            return
        }

        self.contactsToSync = contacts
        self.syncedCount = -1  // -1 表示还未开始同步

        // 第一步：清空设备联系人
        print("🔄 开始清空设备联系人...")
        XGZTCommand.getContactInfo()
    }

    @objc private func handleContactResponse(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if let result = notification.object as? String {
                if result == "0" {
                    // 操作成功
                    if self.syncedCount == -1 {
                        // getContactInfo 成功响应，开始添加联系人
                        print("✅ 设备联系人已清空，开始同步...")
                        self.syncedCount = 0
                        self.syncNextContact()
                    } else {
                        // setContactInfo 成功响应
                        print("✅ 联系人 \(self.syncedCount) 同步成功")
                        self.syncedCount += 1
                        self.syncNextContact()
                    }
                } else {
                    print("❌ 同步失败，错误代码：\(result)")
                }
            }
        }
    }

    private func syncNextContact() {
        // 检查是否所有联系人都已同步
        guard syncedCount < contactsToSync.count else {
            print("🎉 所有联系人同步完成！")
            return
        }

        let contact = contactsToSync[syncedCount]
        print("📤 正在同步联系人 \(syncedCount): \(contact.name) - \(contact.phone)")

        // 调用SDK方法
        XGZTCommand.setContactInfo(
            index: syncedCount,
            name: contact.name,
            phoneNumber: contact.phone
        )
    }
}
```

### 4. 使用示例

```swift
// 创建联系人管理器
let syncManager = ContactSyncManager()

// 准备要同步的联系人（最多8个）
let contacts = [
    (name: "张三", phone: "13800138000"),
    (name: "李四", phone: "13900139000"),
    (name: "王五", phone: "13700137000"),
    (name: "John", phone: "1234567890"),
    (name: "Alice", phone: "9876543210")
]

// 开始同步
syncManager.startSync(contacts: contacts)
```

---

## 关键要点

### ✅ 必须遵守的规则

1. **首先检查设备支持**：使用 `XGZTConnectionStateManager.shared.isXGZTDevice` 验证设备类型
2. **先清空再添加**：调用 `getContactInfo()` 清空设备联系人
3. **等待响应**：每次操作后必须等待设备响应（通过通知）
4. **顺序同步**：一次只能同步一个联系人，必须等待上一个成功后再同步下一个
5. **数量限制**：最多同步 **8个** 联系人
6. **监听通知**：通知名称为 `"SyncContactsViewController"`，返回 `"0"` 表示成功

### ❌ 常见错误

```swift
// ❌ 错误示例 1：不检查设备支持
XGZTCommand.setContactInfo(index: 0, name: "John", phoneNumber: "1234567890")
// 问题：非 XGZT 设备不支持联系人同步，命令会静默失败

// ❌ 错误示例 2：直接批量添加（不等待响应）
for i in 0..<5 {
    XGZTCommand.setContactInfo(index: i, name: "Contact \(i)", phoneNumber: "555-000\(i)")
}
// 问题：蓝牙设备无法处理并发请求，数据会丢失

// ❌ 错误示例 3：不先清空就添加
XGZTCommand.setContactInfo(index: 0, name: "John", phoneNumber: "1234567890")
// 问题：设备可能保留旧数据，导致数据混乱

// ❌ 错误示例 3：不监听通知
XGZTCommand.getContactInfo()
XGZTCommand.setContactInfo(index: 0, name: "John", phoneNumber: "1234567890")
// 问题：不知道操作是否成功，无法处理下一步
```

---

## 数据格式说明

### 电话号码处理

SDK 会自动过滤以下字符，只保留数字：
- 点号 `.`
- 横线 `-`
- 括号 `()` `（）`
- 空格

**示例**：
```swift
// 输入：(123) 456-7890
// SDK处理后：1234567890

XGZTCommand.setContactInfo(
    index: 0,
    name: "John",
    phoneNumber: "(123) 456-7890"  // SDK会自动清理
)
```

### 姓名长度限制

- 最大字节数：**30字节**（UTF-8编码）
- 中文字符通常占3个字节
- 超出部分会被自动截断

**示例**：
```swift
// ✅ 正常：约10个中文字符
XGZTCommand.setContactInfo(index: 0, name: "张三李四王五赵六", phoneNumber: "123")

// ⚠️ 超长：会被自动截断到30字节
XGZTCommand.setContactInfo(index: 0, name: "非常非常非常非常长的名字...", phoneNumber: "123")
```

---

## 调试建议

### 1. 添加日志

```swift
@objc private func handleContactResponse(_ notification: Notification) {
    if let result = notification.object as? String {
        print("📱 设备响应：\(result == "0" ? "成功" : "失败(\(result))")")
        print("📊 当前进度：\(syncedCount + 1)/\(contactsToSync.count)")
    }
}
```

### 2. 检查蓝牙连接

确保设备已连接：
```swift
if XGZTBlueToothManager.shared.isConnected {
    syncManager.startSync(contacts: contacts)
} else {
    print("⚠️ 设备未连接")
}
```

### 3. 处理超时

添加超时机制防止卡死：
```swift
private var syncTimer: Timer?

private func syncNextContact() {
    // 取消旧定时器
    syncTimer?.invalidate()

    // 设置5秒超时
    syncTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
        print("⚠️ 同步超时，请检查设备连接")
        self?.handleSyncTimeout()
    }

    // 发送命令
    XGZTCommand.setContactInfo(...)
}
```

---

## 完整的生产级示例

```swift
import Foundation
import WatchProtocolSDK

class ContactSyncService {

    static let shared = ContactSyncService()

    private var contactsToSync: [(name: String, phone: String)] = []
    private var syncedCount = 0
    private var isSyncing = false
    private var syncTimer: Timer?

    var onProgress: ((Int, Int) -> Void)?  // (当前, 总数)
    var onComplete: ((Bool, String) -> Void)?  // (成功, 消息)

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleContactResponse(_:)),
            name: Notification.Name("SyncContactsViewController"),
            object: nil
        )
    }

    func syncContacts(_ contacts: [(name: String, phone: String)]) {
        // 1. 检查设备支持
        guard XGZTConnectionStateManager.shared.isXGZTDevice else {
            onComplete?(false, "设备不支持联系人同步")
            return
        }

        guard !isSyncing else {
            onComplete?(false, "正在同步中，请稍候")
            return
        }

        guard contacts.count <= 8 else {
            onComplete?(false, "联系人数量不能超过8个")
            return
        }

        guard !contacts.isEmpty else {
            onComplete?(false, "联系人列表为空")
            return
        }

        isSyncing = true
        contactsToSync = contacts
        syncedCount = -1

        print("🔄 开始同步 \(contacts.count) 个联系人...")
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
                        // 清空成功，开始添加
                        print("✅ 设备已清空")
                        self.syncedCount = 0
                        self.syncNextContact()
                    } else {
                        // 添加成功
                        print("✅ 联系人 \(self.syncedCount + 1) 同步成功")
                        self.onProgress?(self.syncedCount + 1, self.contactsToSync.count)

                        self.syncedCount += 1
                        self.syncNextContact()
                    }
                } else {
                    self.handleError("同步失败，错误代码：\(result)")
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
            self?.handleError("同步超时，请检查设备连接")
        }
    }

    private func cancelTimeout() {
        syncTimer?.invalidate()
        syncTimer = nil
    }

    private func handleComplete() {
        isSyncing = false
        cancelTimeout()
        print("🎉 所有联系人同步完成")
        onComplete?(true, "同步成功")
    }

    private func handleError(_ message: String) {
        isSyncing = false
        cancelTimeout()
        print("❌ \(message)")
        onComplete?(false, message)
    }
}

// 使用示例
let service = ContactSyncService.shared

service.onProgress = { current, total in
    print("进度: \(current)/\(total)")
}

service.onComplete = { success, message in
    print(success ? "✅ \(message)" : "❌ \(message)")
}

let contacts = [
    (name: "张三", phone: "13800138000"),
    (name: "李四", phone: "13900139000")
]

service.syncContacts(contacts)
```

---

## 总结

联系人同步的核心是**异步响应机制**和**设备支持验证**。记住这个流程：

### 完整工作流

0. **预检查**：验证 `XGZTConnectionStateManager.shared.isXGZTDevice` 返回 `true`
1. **清空**：调用 `getContactInfo()` → 等待响应 "0"
2. **循环**：调用 `setContactInfo(index)` → 等待响应 "0" → index++
3. **完成**：所有联系人同步完成

如有疑问，请参考项目中的 `SyncContactsViewController.swift` 文件（第479-564行）查看完整实现。

---

## 快速参考

| 步骤 | 操作 | 等待响应 | 说明 |
|------|------|----------|------|
| 0 | 检查设备支持 | - | `XGZTConnectionStateManager.shared.isXGZTDevice` 必须为 `true` |
| 1 | `XGZTCommand.getContactInfo()` | 通知: `"0"` | 清空设备上所有联系人 |
| 2 | `XGZTCommand.setContactInfo(index: 0, ...)` | 通知: `"0"` | 第一个联系人 |
| 3 | `XGZTCommand.setContactInfo(index: 1, ...)` | 通知: `"0"` | 第二个联系人 |
| ... | 继续每个联系人 | 每次通知 | 最多 8 个联系人 |
| 完成 | 所有联系人同步完成 | - | 显示成功消息 |

**关键提醒**：
- ⚠️ 必须等待上一步成功响应（`"0"`）后才能进行下一步！
- ⚠️ 仅 XGZT 协议设备支持联系人同步功能！
- ⚠️ 通知名称：`"SyncContactsViewController"`
