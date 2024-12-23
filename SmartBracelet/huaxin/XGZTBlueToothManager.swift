//
//  XGZTBlueToothManager.swift
//  
//
//  Created by anker on 2024/11/10.
//

import Foundation
import CoreBluetooth

// 自定义结构体来存储CBPeripheral和MAC地址
struct PeripheralInfo {
    let peripheral: CBPeripheral
    let macAddress: String
}

extension PeripheralInfo: Equatable {
    static func == (lhs: PeripheralInfo, rhs: PeripheralInfo) -> Bool {
        return lhs.peripheral == rhs.peripheral && lhs.macAddress == rhs.macAddress
    }
}

protocol BleManagerDelegate: AnyObject {
    func onBleReady()
    func receiveData(_ data: Data)
    func sentData()
}

// 蓝牙协议操作类
class XGZTBlueToothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    static let shared = XGZTBlueToothManager()
    // 存储扫描到的蓝牙设备
    var discoveredPeripherals: [PeripheralInfo] = []
    var centralManager: CBCentralManager?
    private var peripheral: CBPeripheral?
    var characteristic: CBCharacteristic? // 普通通讯特征
    // In and Out, for Device
    public var dataInCharacteristic:  CBCharacteristic?
    public var dataOutCharacteristic: CBCharacteristic?
    // 标记是否正在扫描
    var isScanning = false
    public var device: BluetoothWatchDevice?
    public var handler = XGZTBusinessHandler() // 逻辑处理
    public weak var delegate: BleManagerDelegate? // ble管理代理
    public var isOTAing = false // 是否正在OTA

    override init() {
        super.init()
    }

    func initCentral() {
        centralManager = CBCentralManager(delegate: self, queue: .global())
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
        BLEManager.shared.stopScan() // 停止扫描
    }

    func connect(to device: CBPeripheral) {
        centralManager?.connect(device, options: nil)
    }
    
    func connect(to macAddress: String) {
        for peripheralInfo in discoveredPeripherals {
            if peripheralInfo.macAddress == macAddress {
                let device = peripheralInfo.peripheral
                centralManager?.connect(device, options: nil)
                break
            }
        }
        
    }
    
    // 先将OTA前检查设备是否准备好的指令放到这里
    public func isReadyOTA() {
        delegate?.onBleReady()
    }
    

    // CBCentralManagerDelegate 方法
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            // 扫描设备或执行其他操作
           startScanning()
        } else if central.state == .poweredOff {
            stopScanning()
        } else if central.state == .unauthorized {
            stopScanning()
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("蓝牙设备连接成功")
        self.peripheral = peripheral
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        
        for p in discoveredPeripherals {
            if p.peripheral.identifier.uuidString == peripheral.identifier.uuidString {
                lastestDeviceMac = p.macAddress
                device = BluetoothWatchDevice()
                device?.deviceName = p.peripheral.name ?? ""
                device?.max = p.macAddress
                device?.saveToSandbox(mac: lastestDeviceMac)
                
                var array = UserDefaults.standard.array(forKey: "max") as? [String]

                if array == nil {
                    array = [String]()
                }

                if let index = array?.firstIndex(of: lastestDeviceMac) {
                    print("Item already exists at index \(index)")
                } else {
                    array?.append(lastestDeviceMac)
                    UserDefaults.standard.set(array, forKey: "max")
                    UserDefaults.standard.synchronize()
                    print("Item added successfully")
                }
                
                break
            }
        }
        handler.handleConnected()
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("连接蓝牙设备失败: \(error?.localizedDescription ?? "未知错误")")
        self.peripheral = nil
        handler.handleDisconnected()
        device = nil 
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        print("蓝牙设备断开连接")
        self.peripheral = nil
        handler.handleDisconnected()
        device = nil
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi: NSNumber) {
        // 检查 advertisementData 是否包含我们需要的数据
            if let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data,
               manufacturerData.count == 15,
               manufacturerData[1] == 0x06 {
                let range = 5..<11 // Convert ClosedRange to Range by adding 1 to the upper bound
                let macAddress = manufacturerData.subdata(in: range).hexEncodedString()
                // 自研设备的处理逻辑
                let peripheralInfo = PeripheralInfo(peripheral: peripheral, macAddress: macAddress)
                if !discoveredPeripherals.contains(peripheralInfo) {
                    discoveredPeripherals.append(peripheralInfo)
                
                    // 打印所有信息
                    let peripheralInfo = """
                    发现蓝牙设备：
                    名称：\(peripheral.name ?? "未知设备")
                    设备ID：\(peripheral.identifier)
                    RSSI：\(rssi)
                    广告数据：\(advertisementData)
                    """
                    print(peripheralInfo)
                }
            }
    }

    // CBPeripheralDelegate 方法
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
                if OTAService.dataInUuid == characteristic.uuid || characteristic.uuid.uuidString == "0000FF14-0000-1000-8000-00805F9B34FB" {
                    Logger.n(self, "Data In characteristic found")
                    dataInCharacteristic = characteristic
                } else if OTAService.dataOutUuid == characteristic.uuid {
                    Logger.n(self, "Data Out characteristic found")
                    dataOutCharacteristic = characteristic
                }else if characteristic.uuid.uuidString == "FF13" || characteristic.uuid.uuidString == "0000FF13-0000-1000-8000-00805F9B34FB"  { // write
                    self.characteristic = characteristic
                }
                if characteristic.properties.contains(.notify)  {
                    // 启用通知
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("写入特征值失败: \(error.localizedDescription)")
        } else {
            print("写入特征值成功")
            // 这里可以选择读取特征值来获取响应数据
            peripheral.readValue(for: characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: (any Error)?) {
        
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("读取特征值失败: \(error.localizedDescription)")
        } else if let value = characteristic.value {
            print("<- 0x\(value.hex)")
            if isOTAing { // 如果当前正在OTA中
                DispatchQueue.main.async { [weak self] in
                    self?.delegate?.receiveData(value)
                }
                return
            }
            
            let bytes = [UInt8](value)
            XGZTCommand.handleResponse(response: bytes) // 处理设备端返回的指令内容
        }
    }

    public func writeCharacteristic(command: [UInt8]) {
        guard let peripheral = peripheral, let characteristic = characteristic else {
            return
        }
        // 将 [UInt8] 转换为 16 进制字符串
        let hexString = command.map { String(format: "%02X ", $0) }.joined()
        // 打印以 16 进制字符串形式表示的命令
        print("Writing characteristic with command (in hex): \(hexString)")
        peripheral.writeValue(Data(command), for: characteristic, type: .withoutResponse)
    }
    
    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        if isOTAing {
            delegate?.sentData()
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

extension XGZTBlueToothManager: ABOtaSendDelegate {
    func sendData(_ data: Data) {
        guard let dataOutCharacteristic else { return }
        print("=> 0x\(data.hex)")
        peripheral?.writeValue(data, for: dataOutCharacteristic, type: .withoutResponse)
    }
    
    
}
