//
//  BluetoothTestViewController.swift
//  SmartBracelet
//
//  Created by anker on 2024/11/15.
//  Copyright © 2024 tjd. All rights reserved.
//

import UIKit
import CoreBluetooth

// 假设XGZTBlueToothManager在当前模块可访问
class BluetoothTestViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

    // UITextView用于展示交互内容
    let interactionTextView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.textColor = .white
        textView.backgroundColor = .black
        return textView
    }()

    // UITableView用于展示扫描到的设备和可测试的方法
    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tableView
    }()

    var centralManager: CBCentralManager?
    
    // 存储扫描到的蓝牙设备
    var discoveredPeripherals: [CBPeripheral] = []

    // 当前连接的蓝牙设备
    var connectedPeripheral: CBPeripheral?
    
    private var writeCharacteristic: CBCharacteristic?

    // 标记是否正在扫描
    var isScanning = false

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        
        centralManager = CBCentralManager(delegate: self, queue: .main)

    }

    func setupUI() {
        view.backgroundColor = .white

        // 添加UITextView到视图
        view.addSubview(interactionTextView)
        interactionTextView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            interactionTextView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            interactionTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            interactionTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            interactionTextView.heightAnchor.constraint(equalToConstant: 200)
        ])

        // 添加UITableView到视图
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: interactionTextView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        // 设置UITableView的代理和数据源
        tableView.delegate = self
        tableView.dataSource = self
    }

    func startScanning() {
        if !isScanning {
            isScanning = true
            // 扫描选项
            let options: [String: Any] = [
                CBCentralManagerScanOptionAllowDuplicatesKey: false, // 不允许重复扫描
                CBCentralManagerScanOptionSolicitedServiceUUIDsKey: [] // 仅扫描指定服务的外设
            ]
            centralManager?.scanForPeripherals(withServices: nil, options: options)
            print("开始扫描设备")
        }
    }

    func stopScanning() {
        if isScanning {
            isScanning = false
            centralManager?.stopScan()
            print("停止扫描设备")
        }
    }

    // CBCentralManagerDelegate方法

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            // 扫描设备或执行其他操作
            interactionTextView.text += "蓝牙已开启，开始扫描设备...\n"
            startScanning()
        } else if central.state == .poweredOff {
            interactionTextView.text += "蓝牙已关闭，请开启蓝牙后重试。\n"
            stopScanning()
        } else if central.state == .unauthorized {
            interactionTextView.text += "未授权访问蓝牙，请检查权限设置。\n"
            stopScanning()
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        peripheral.delegate = self
        interactionTextView.text += "已成功连接到蓝牙设备：\(peripheral.name ?? "未知设备")\n"
        centralManager?.stopScan()
        // 连接成功后，展示可测试的方法
        tableView.reloadData()
        peripheral.discoverServices(nil) // 连接成功后，开始发现服务
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        interactionTextView.text += "连接蓝牙设备失败：\(error?.localizedDescription ?? "未知错误")\n"
        connectedPeripheral = nil
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi: NSNumber) {
        if !discoveredPeripherals.contains(peripheral) && (peripheral.name?.contains("LE") ?? false) {
            discoveredPeripherals.append(peripheral)
            tableView.reloadData()
            // 打印所有信息
            let peripheralInfo = """
            发现蓝牙设备：
            名称：\(peripheral.name ?? "未知设备")
            设备ID：\(peripheral.identifier)
            RSSI：\(rssi)
            广告数据：\(advertisementData)
            """
            
            interactionTextView.text += "\(peripheralInfo)\n"
            print(peripheralInfo)
        }
    }

    // CBPeripheralDelegate方法

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)
                print("Service UUID: \(service.uuid)")
                print("Is Primary: \(service.isPrimary)")
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                // 保存特征或根据特征UUID进行不同操作
                print("Service UUID: \(service.uuid) characteristic UUID: \(characteristic.uuid.uuidString)")
                print("Service UUID: \(service.uuid) characteristic.properties: \(characteristicPropertiesToString(characteristic.properties))")
                print("Service UUID: \(service.uuid) characteristic.isNotifying: \(characteristic.isNotifying)")
                if characteristic.uuid.uuidString == "FF13" && characteristic.properties.contains(.write)  { // write
                    writeCharacteristic = characteristic
                    XGZTBlueToothManager.shared.characteristic = characteristic
                } else if characteristic.properties.contains(.notify)  {
                    // 启用通知
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let value = characteristic.value {
            let hexString = value.map { String(format: "%02x", $0) }.joined()
            interactionTextView.text += "已发送指令：\(hexString)\n"
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let value = characteristic.value {
            let hexString = value.map { String(format: "%02x", $0) }.joined()
            interactionTextView.text += "[\(characteristic.uuid.uuidString)]接收到指令内容：\(hexString)\n"
        } else if let error = error {
            interactionTextView.text += "[\(characteristic.uuid.uuidString)]读取特征值失败：\(error.localizedDescription)\n"
        }
        
        if characteristic.uuid.uuidString == "FF14" {
            if let value = characteristic.value {
                // 处理接收到的通知数据
                let hexString = value.map { String(format: "%02x", $0) }.joined()
                print("[\(characteristic.uuid.uuidString)]接收到指令内容: \(hexString)")
            }
        }
    }
    
    
    // 辅助函数：将 CBCharacteristicProperties 转换为字符串表示
    func characteristicPropertiesToString(_ properties: CBCharacteristicProperties) -> String {
        var propertiesArray: [String] = []
        
        if properties.contains(.broadcast) {
            propertiesArray.append("broadcast")
        }
        if properties.contains(.read) {
            propertiesArray.append("read")
        }
        if properties.contains(.writeWithoutResponse) {
            propertiesArray.append("writeWithoutResponse")
        }
        if properties.contains(.write) {
            propertiesArray.append("write")
        }
        if properties.contains(.notify) {
            propertiesArray.append("notify")
        }
        if properties.contains(.indicate) {
            propertiesArray.append("indicate")
        }
        if properties.contains(.authenticatedSignedWrites) {
            propertiesArray.append("authenticatedSignedWrites")
        }
        if properties.contains(.extendedProperties) {
            propertiesArray.append("extendedProperties")
        }
        if properties.contains(.notifyEncryptionRequired) {
            propertiesArray.append("notifyEncryptionRequired")
        }
        if properties.contains(.indicateEncryptionRequired) {
            propertiesArray.append("indicateEncryptionRequired")
        }
        
        return propertiesArray.joined(separator: ", ")
    }

}

extension BluetoothTestViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let connectedPeripheral = connectedPeripheral {
            // 连接成功后展示可测试的方法
            return XGZTCommand.methods.count
        } else {
            // 未连接时展示扫描到的设备
            return discoveredPeripherals.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        if let connectedPeripheral = connectedPeripheral {
            // 连接成功后展示可测试的方法名称
            let methodName = XGZTCommand.methods[indexPath.row]
            cell.textLabel?.text = methodName
        } else {
            // 未连接时展示扫描到的设备名称
            let peripheral = discoveredPeripherals[indexPath.row]
            cell.textLabel?.text = peripheral.name ?? "未知设备"
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let connectedPeripheral = connectedPeripheral {
            // 连接成功后执行点击的方法
            let method = XGZTCommand.methods[indexPath.row]
            switch method {
            case "syncTime":
                let timeZone = TimeZone.current.secondsFromGMT() / 3600
                let utc = Int(Date().timeIntervalSince1970)
                XGZTCommand.syncTime(timeZone: timeZone, utc: UInt32(utc))
            case "getBatteryLevel":
                XGZTCommand.getBatteryLevel()
            // 其他方法类似添加处理逻辑

            default:
                break
            }
        } else {
            // 未连接时尝试连接点击的设备
            let peripheral = discoveredPeripherals[indexPath.row]
            centralManager?.connect(peripheral)
        }
    }

}
