//
//  XGZTBlueToothManager.swift
//  
//
//  Created by anker on 2024/11/10.
//

import Foundation
import CoreBluetooth

// 自定义结构体来存储 CBPeripheral 和 MAC 地址
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
    var brands: [String: Int] = [:]
    var centralManager: CBCentralManager?
    private var peripheral: CBPeripheral?
    var characteristic: CBCharacteristic? // 普通通讯特征
    // In and Out, for Device
    public var dataInCharacteristic: CBCharacteristic?
    public var dataOutCharacteristic: CBCharacteristic?
    // 标记是否正在扫描
    var isScanning = false
    public var device: BluetoothWatchDevice?
    public var handler = XGZTBusinessHandler() // 逻辑处理
    public weak var delegate: BleManagerDelegate? // ble 管理代理
    public var isOTAing = false // 是否正在 OTA
    private var reconnectTimer: Timer? // 重连定时器
    private var autoDisconnect = false // 主动断开

    override init() {
        super.init()
    }

    func initCentral() {
        centralManager = CBCentralManager(delegate: self, queue:.global())
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
        reconnectToDevice()
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
    
    func disconnectDevice() {
        if let per = peripheral {
            autoDisconnect = true
            centralManager?.cancelPeripheralConnection(per)
        }
    }
    
    // 新增发起 BLE 回连功能
    public func reconnectToDevice() {
        if lastestDeviceMac.count == 0 {
            return 
        }
        if let peripheral = centralManager?.retrieveConnectedPeripherals(withServices: [CBUUID(string: "0000FF12-0000-1000-8000-00805F9B34FB")]).first {
            let peripheralInfo = PeripheralInfo(peripheral: peripheral, macAddress: lastestDeviceMac)
            discoveredPeripherals.append(peripheralInfo)
            centralManager?.connect(peripheral, options: nil)
        } else {
            print("No known peripheral found with the given identifier")
        }
    }
    
    // 先将 OTA 前检查设备是否准备好的指令放到这里
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
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        
        for p in discoveredPeripherals {
            if p.peripheral.identifier.uuidString == peripheral.identifier.uuidString {
                lastestDeviceMac = p.macAddress
                UserDefaults.standard.setValue(lastestDeviceMac, forKey: "LastestDeviceMac")
                UserDefaults.standard.synchronize()
                device = BluetoothWatchDevice()
                device?.deviceName = p.peripheral.name ?? ""
                device?.max = p.macAddress
                device?.brandID = brands[p.macAddress] ?? 0
                BluetoothWatchDevice.saveToSandbox(device: device!)
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
        if autoDisconnect {
            self.peripheral = nil
            device = nil
            handler.handleDisconnected()
            autoDisconnect = false 
            return
        }
        startReconnectTimer() // 设备断开连接时，启动重连定时器
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
                brands[macAddress] = Int(manufacturerData[12])
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
                // 保存特征或根据特征 UUID 进行不同操作
                print("Service UUID: \(service.uuid) characteristic UUID: \(characteristic.uuid.uuidString)")
                print("Service UUID: \(service.uuid) characteristic.properties: \(characteristicPropertiesToString(characteristic.properties))")
                print("Service UUID: \(service.uuid) characteristic.isNotifying: \(characteristic.isNotifying)")
                if OTAService.dataInUuid == characteristic.uuid || characteristic.uuid.uuidString == "0000FF14-0000-1000-8000-00805F9B34FB" {
                    Logger.n(self, "Data In characteristic found")
                    dataInCharacteristic = characteristic
                } else if OTAService.dataOutUuid == characteristic.uuid {
                    Logger.n(self, "Data Out characteristic found")
                    dataOutCharacteristic = characteristic
                } else if characteristic.uuid.uuidString == "FF13" || characteristic.uuid.uuidString == "0000FF13-0000-1000-8000-00805F9B34FB"  { // write
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
            print("<-[\(value.count)] \(value.hex)")
            if isOTAing { // 如果当前正在 OTA 中
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
        peripheral.writeValue(Data(command), for: characteristic, type:.withoutResponse)
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
    
    // 启动重连定时器
    private func startReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(disconnect), userInfo: nil, repeats: false)
        
        if let lastConnectedPeripheral = self.peripheral {
            centralManager?.connect(lastConnectedPeripheral, options: nil)
        }
    }
    
    // 重连操作
    @objc private func disconnect() {
        print("定时器被激活")
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        if let lastConnectedPeripheral = self.peripheral {
            centralManager?.cancelPeripheralConnection(lastConnectedPeripheral)
        }
        peripheral = nil
        device = nil
        handler.handleDisconnected()
    }
}

extension XGZTBlueToothManager: ABOtaSendDelegate {
    func sendData(_ data: Data) {
        guard let dataOutCharacteristic else { return }
        print("=> 0x\(data.hex)")
        peripheral?.writeValue(data, for: dataOutCharacteristic, type:.withoutResponse)
    }
}
