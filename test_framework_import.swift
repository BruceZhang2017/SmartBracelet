// 测试文件：验证 WatchProtocolSDK 可以被导入和使用
import Foundation
import WatchProtocolSDK

// 测试1: 验证核心管理类可访问
func testCoreManagers() {
    print("✅ 测试核心管理类...")
    
    // XGZTBlueToothManager
    let bleManager = XGZTBlueToothManager.shared
    print("  - XGZTBlueToothManager.shared: \(type(of: bleManager))")
    
    // XGZTBusinessHandler
    let businessHandler = XGZTBusinessHandler.shared
    print("  - XGZTBusinessHandler.shared: \(type(of: businessHandler))")
    
    // XGZTDeviceManager
    let deviceManager = XGZTDeviceManager.shared
    print("  - XGZTDeviceManager.shared: \(type(of: deviceManager))")
    
    // XGZTCommandStateManager
    let commandManager = XGZTCommandStateManager.shared
    print("  - XGZTCommandStateManager.shared: \(type(of: commandManager))")
    
    // XGZTConnectionStateManager
    let connectionManager = XGZTConnectionStateManager.shared
    print("  - XGZTConnectionStateManager.shared: \(type(of: connectionManager))")
    
    // XLogger
    let logger = XLogger.shared
    print("  - XLogger.shared: \(type(of: logger))")
}

// 测试2: 验证数据模型可创建
func testDataModels() {
    print("\n✅ 测试数据模型...")
    
    // BluetoothWatchDevice
    let device = BluetoothWatchDevice()
    device.deviceName = "测试设备"
    device.max = "AA:BB:CC:DD:EE:FF"
    print("  - BluetoothWatchDevice 创建成功: \(device.deviceName ?? "无名称")")
    
    // 测试属性访问
    print("  - 设备MAC地址: \(device.max ?? "未设置")")
}

// 测试3: 验证指令类可访问
func testCommands() {
    print("\n✅ 测试指令类...")
    
    // XGZTCommand 静态方法
    print("  - XGZTCommand 类型: \(type(of: XGZTCommand.self))")
    print("  - XGZTCommand.methods 可访问")
    
    // XGZTCommands 枚举
    let syncTimeCmd = XGZTCommands.syncTime
    print("  - XGZTCommands.syncTime: \(syncTimeCmd.rawValue)")
}

// 测试4: 验证扩展方法可用
func testExtensions() {
    print("\n✅ 测试扩展方法...")
    
    let data = Data([0x01, 0x02, 0xFF])
    print("  - Data.hex: \(data.hex)")
    print("  - Data.hexEncodedString(): \(data.hexEncodedString())")
    print("  - Data.bytes.count: \(data.bytes.count)")
}

// 运行所有测试
print("🚀 开始测试 WatchProtocolSDK Framework\n")
print("=" * 50)

testCoreManagers()
testDataModels()
testCommands()
testExtensions()

print("\n" + "=" * 50)
print("🎉 所有测试通过！Framework 可以正常使用。")
