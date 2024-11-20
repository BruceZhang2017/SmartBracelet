//
//  XGZTBlueToothManager.swift
//  
//
//  Created by anker on 2024/11/10.
//

import Foundation
import CoreBluetooth

// 蓝牙协议操作类
class XGZTBlueToothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    static let shared = XGZTBlueToothManager()
    var centralManager: CBCentralManager?
    private var peripheral: CBPeripheral?
    var characteristic: CBCharacteristic?
    private var writeCompletion: (([UInt8]) -> Void)?

    override init() {
        super.init()
    }

    func initCentral() {
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }

    func scan(uuids: [String]? = nil) {
        var serviceUUIDs: [CBUUID] = []
        if let uuids = uuids {
            serviceUUIDs = uuids.map { CBUUID(string: $0) }
        }

        let options: [String: Any] = [
            CBCentralManagerScanOptionAllowDuplicatesKey: false,
            CBCentralManagerScanOptionSolicitedServiceUUIDsKey: serviceUUIDs
        ]

        centralManager?.scanForPeripherals(withServices: nil)
        print("开始扫描设备")
    }

    func connect(to device: CBPeripheral) {
        centralManager?.connect(device, options: nil)
    }

    // CBCentralManagerDelegate 方法
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            // 扫描设备或执行其他操作
        } else if central.state == .poweredOff {
            // 处理蓝牙关闭的情况
        } else if central.state == .unauthorized {
            // 处理未授权的情况
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.peripheral = peripheral
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("连接蓝牙设备失败: \(error?.localizedDescription ?? "未知错误")")
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi: NSNumber) {
        print("发现蓝牙设备: \(peripheral.name ?? "未知设备")，设备ID: \(peripheral.identifier)")
    }

    // CBPeripheralDelegate 方法
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                // 保存特征或根据特征 UUID 进行不同操作
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("写入特征值失败: \(error.localizedDescription)")
            writeCompletion?([])
        } else {
            print("写入特征值成功")
            // 这里可以选择读取特征值来获取响应数据
            peripheral.readValue(for: characteristic)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("读取特征值失败: \(error.localizedDescription)")
            writeCompletion?([])
        } else if let value = characteristic.value {
            let bytes = [UInt8](value)
            print("读取到特征值: \(bytes)")
            writeCompletion?(bytes)
        }
    }

    public func writeCharacteristic(command: [UInt8], completion: @escaping ([UInt8]) -> Void) {
        guard let peripheral = peripheral, let characteristic = characteristic else {
            completion([])
            return
        }

        writeCompletion = completion
        peripheral.writeValue(Data(command), for: characteristic, type: .withResponse)
    }
}
