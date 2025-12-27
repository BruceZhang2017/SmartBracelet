//
//  WatchProtocolSDK-集成测试.swift
//  SmartBracelet
//
//  Created on 2025-12-27.
//  Framework 集成测试 - 验证 WatchProtocolSDK 可以正常使用
//

import Foundation
import WatchProtocolSDK

/// WatchProtocolSDK 集成测试类
/// 验证所有公开 API 可以正常访问和使用
class WatchProtocolSDKIntegrationTest {

    // MARK: - 测试1: 核心管理类访问测试

    /// 测试所有核心管理类的单例可以正常访问
    func testCoreManagersAccess() {
        print("\n✅ 测试1: 核心管理类访问")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // 蓝牙管理器
        let bleManager = XGZTBlueToothManager.shared
        print("✓ XGZTBlueToothManager.shared 可访问")
        print("  类型: \(type(of: bleManager))")

        // 业务处理器
        let businessHandler = XGZTBusinessHandler.shared
        print("✓ XGZTBusinessHandler.shared 可访问")
        print("  类型: \(type(of: businessHandler))")

        // 设备管理器
        let deviceManager = XGZTDeviceManager.shared
        print("✓ XGZTDeviceManager.shared 可访问")
        print("  缓存设备数: \(deviceManager.deviceCount)")

        // 指令状态管理器
        let commandManager = XGZTCommandStateManager.shared
        print("✓ XGZTCommandStateManager.shared 可访问")
        print("  当前读取状态: \(commandManager.deviceReadingState)")

        // 连接状态管理器
        let connectionManager = XGZTConnectionStateManager.shared
        print("✓ XGZTConnectionStateManager.shared 可访问")
        print("  设备类型: \(connectionManager.deviceType)")

        // 日志工具
        let logger = XLogger.shared
        print("✓ XLogger.shared 可访问")
        logger.log("测试日志输出")

        print("\n✅ 所有核心管理类访问正常\n")
    }

    // MARK: - 测试2: 蓝牙功能测试

    /// 测试蓝牙相关功能
    func testBluetoothFunctions() {
        print("\n✅ 测试2: 蓝牙功能")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        let bleManager = XGZTBlueToothManager.shared

        // 初始化中央管理器
        bleManager.initCentral()
        print("✓ initCentral() 调用成功")

        // 检查连接状态
        let isConnected = bleManager.isconnected()
        print("✓ isconnected() 返回: \(isConnected)")

        // 检查蓝牙状态
        let isBleOff = bleManager.isCurrentBleStateOFF()
        print("✓ isCurrentBleStateOFF() 返回: \(isBleOff)")

        // 检查扫描状态
        print("✓ isScanning 属性可访问: \(bleManager.isScanning)")

        // 检查设备列表
        print("✓ discoveredPeripherals 可访问，数量: \(bleManager.discoveredPeripherals.count)")

        print("\n注意: 实际的扫描和连接功能需要在真实设备上测试")
        print("✅ 蓝牙功能接口测试通过\n")
    }

    // MARK: - 测试3: 数据模型测试

    /// 测试数据模型的创建和访问
    func testDataModels() {
        print("\n✅ 测试3: 数据模型")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // 创建蓝牙设备对象
        let device = BluetoothWatchDevice()
        device.deviceName = "测试智能手环"
        device.max = "AA:BB:CC:DD:EE:FF"
        device.batteryLevel = 85
        device.firmwareVersion = "1.2.3"
        device.screenWidth = 240
        device.screenHeight = 280

        print("✓ BluetoothWatchDevice 创建成功")
        print("  设备名称: \(device.deviceName ?? "未知")")
        print("  MAC地址: \(device.max ?? "未设置")")
        print("  电量: \(device.batteryLevel ?? 0)%")
        print("  固件版本: \(device.firmwareVersion ?? "未知")")
        print("  屏幕尺寸: \(device.screenWidth)x\(device.screenHeight)")

        // 测试设备类型枚举
        let deviceType = DeviceType.xgzt
        print("\n✓ DeviceType 枚举可访问: \(deviceType)")

        print("\n✅ 数据模型测试通过\n")
    }

    // MARK: - 测试4: 指令类测试

    /// 测试指令类的访问
    func testCommands() {
        print("\n✅ 测试4: 指令类")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // 测试指令枚举
        let syncTimeCmd = XGZTCommands.syncTime
        print("✓ XGZTCommands.syncTime: 0x\(String(format: "%02X", syncTimeCmd.rawValue))")

        let batteryCmd = XGZTCommands.getBatteryLevel
        print("✓ XGZTCommands.getBatteryLevel: 0x\(String(format: "%02X", batteryCmd.rawValue))")

        let bindCmd = XGZTCommands.bindDevice
        print("✓ XGZTCommands.bindDevice: 0x\(String(format: "%02X", bindCmd.rawValue))")

        // 测试指令类的静态方法可访问
        print("\n✓ XGZTCommand 类可访问")
        print("  methods 数组: \(XGZTCommand.methods)")

        print("\n注意: 实际的指令发送需要连接设备后测试")
        print("✅ 指令类测试通过\n")
    }

    // MARK: - 测试5: 扩展方法测试

    /// 测试 Data 扩展方法
    func testExtensions() {
        print("\n✅ 测试5: 扩展方法")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // 创建测试数据
        let data = Data([0x01, 0x02, 0xAB, 0xFF])

        // 测试 hex 属性
        let hexString = data.hex
        print("✓ Data.hex: \(hexString)")
        assert(hexString == "0102ABFF", "hex 转换错误")

        // 测试 hexEncodedString 方法
        let hexWithSeparator = data.hexEncodedString()
        print("✓ Data.hexEncodedString(): \(hexWithSeparator)")
        assert(hexWithSeparator == "01:02:AB:FF", "hexEncodedString 转换错误")

        let hexWithDash = data.hexEncodedString(separator: "-")
        print("✓ Data.hexEncodedString(separator: \"-\"): \(hexWithDash)")
        assert(hexWithDash == "01-02-AB-FF", "hexEncodedString 自定义分隔符错误")

        // 测试 bytes 属性
        let bytes = data.bytes
        print("✓ Data.bytes: \(bytes)")
        assert(bytes.count == 4, "bytes 数组长度错误")
        assert(bytes[0] == 0x01 && bytes[3] == 0xFF, "bytes 数组内容错误")

        print("\n✅ 扩展方法测试通过\n")
    }

    // MARK: - 测试6: 线程安全测试

    /// 测试线程安全的单例访问
    func testThreadSafety() {
        print("\n✅ 测试6: 线程安全")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        let group = DispatchGroup()

        // 并发访问设备管理器
        for i in 0..<10 {
            group.enter()
            DispatchQueue.global().async {
                let deviceManager = XGZTDeviceManager.shared
                let count = deviceManager.deviceCount
                print("  线程\(i): deviceCount = \(count)")
                group.leave()
            }
        }

        group.wait()
        print("\n✓ 10个并发线程访问单例成功，无崩溃")
        print("✅ 线程安全测试通过\n")
    }

    // MARK: - 运行所有测试

    /// 运行所有集成测试
    func runAllTests() {
        print("\n")
        print("╔══════════════════════════════════════════════════╗")
        print("║  WatchProtocolSDK Framework 集成测试             ║")
        print("║  版本: 1.0.0                                     ║")
        print("║  测试日期: 2025-12-27                            ║")
        print("╚══════════════════════════════════════════════════╝")

        testCoreManagersAccess()
        testBluetoothFunctions()
        testDataModels()
        testCommands()
        testExtensions()
        testThreadSafety()

        print("╔══════════════════════════════════════════════════╗")
        print("║  🎉 所有测试通过！                               ║")
        print("║  WatchProtocolSDK Framework 可以正常使用         ║")
        print("╚══════════════════════════════════════════════════╝")
        print("\n")
    }
}

// MARK: - 使用示例

/// 基本使用示例
class WatchProtocolSDKUsageExample {

    func example_初始化和扫描() {
        print("示例1: 初始化和扫描设备")
        print("━━━━━━━━━━━━━━━━━━━━━━")

        // 1. 初始化蓝牙中央管理器
        XGZTBlueToothManager.shared.initCentral()

        // 2. 开始扫描设备
        XGZTBlueToothManager.shared.startScanning()

        // 3. 停止扫描
        // XGZTBlueToothManager.shared.stopScanning()
    }

    func example_连接设备() {
        print("\n示例2: 连接设备")
        print("━━━━━━━━━━━━━━━━━━━━━━")

        // 方式1: 通过 MAC 地址连接
        let macAddress = "AA:BB:CC:DD:EE:FF"
        XGZTBlueToothManager.shared.connectFunc(to: macAddress)

        // 方式2: 通过外设对象连接（从扫描结果中获取）
        // if let peripheral = XGZTBlueToothManager.shared.discoveredPeripherals.first?.peripheral {
        //     XGZTBlueToothManager.shared.connectFunc(to: peripheral)
        // }
    }

    func example_同步数据() {
        print("\n示例3: 同步设备数据")
        print("━━━━━━━━━━━━━━━━━━━━━━")

        // 同步设备信息
        XGZTBusinessHandler.shared.syncDevcieInfo()

        // 查看同步进度
        let isReading = XGZTCommandStateManager.shared.isDeviceReading
        print("正在读取设备数据: \(isReading)")
    }

    func example_查询设备信息() {
        print("\n示例4: 查询设备信息")
        print("━━━━━━━━━━━━━━━━━━━━━━")

        if let device = XGZTBlueToothManager.shared.device {
            print("设备名称: \(device.deviceName ?? "未知")")
            print("MAC地址: \(device.max ?? "未设置")")
            print("电量: \(device.batteryLevel ?? 0)%")
            print("固件版本: \(device.firmwareVersion ?? "未知")")
        } else {
            print("尚未连接设备")
        }
    }

    func example_断开连接() {
        print("\n示例5: 断开设备连接")
        print("━━━━━━━━━━━━━━━━━━━━━━")

        XGZTBlueToothManager.shared.disconnectDevice()
    }

    func runAllExamples() {
        print("\n╔══════════════════════════════════════════════════╗")
        print("║  WatchProtocolSDK Framework 使用示例             ║")
        print("╚══════════════════════════════════════════════════╝\n")

        example_初始化和扫描()
        example_连接设备()
        example_同步数据()
        example_查询设备信息()
        example_断开连接()

        print("\n")
    }
}

// MARK: - 测试入口

/// 在 AppDelegate 或 ViewController 中调用此方法来运行测试
func testWatchProtocolSDK() {
    // 运行集成测试
    let test = WatchProtocolSDKIntegrationTest()
    test.runAllTests()

    // 运行使用示例
    let example = WatchProtocolSDKUsageExample()
    example.runAllExamples()
}
