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
    var deletePeripheralInfo: PeripheralInfo? = nil
    var brands: [String: Int] = [:]
    var centralManager: CBCentralManager?
    private var peripheral: CBPeripheral?
    var characteristic: CBCharacteristic? // 普通通讯特征
    // In and Out, for Device
    public var dataInCharacteristic: CBCharacteristic?
    public var dataOutCharacteristic: CBCharacteristic?
    private var notifyCharacteristic: CBCharacteristic?
    // 标记是否正在扫描
    var isScanning = false
    public var device: BluetoothWatchDevice?
    public var handler = XGZTBusinessHandler() // 逻辑处理
    public weak var delegate: BleManagerDelegate? // ble 管理代理
    public var isOTAing = false // 是否正在 OTA
    public var isFromOTASuccess = false // 是否正在 OTA
    private var reconnectTimer: Timer? // 重连定时器
    private var scanTimer: Timer? // 搜索设备定时器
    private var autoDisconnect = false // 主动断开
    private var scanMacAddress = ""
    public var switchAutoDisconnect = false
    public var isReconnectingNow = false // 当前是否在回连中
    // 维护一个集合存储正在连接的外设
    var connectingPeripherals: Set<CBPeripheral> = []
    private var isCancelSystemBLE = false

    override init() {
        super.init()
    }
    
    // MARK: - 获取当前蓝牙状态
    public func isconnected() -> Bool {
        return peripheral?.state == .connected
    }
    
    public func isCurrentBleStateOFF() -> Bool {
        return centralManager?.state ?? .unknown == .poweredOff
    }

    func initCentral() {
        centralManager = CBCentralManager(delegate: self, queue:.global())
    }
    
    // 当发起连接时，添加外设到集合
    private func connect(to peripheral: CBPeripheral) {
        centralManager?.connect(peripheral, options: nil)
        connectingPeripherals.insert(peripheral)
    }

    // 清空所有连接操作
    public func cancelAllConnections() {
        // 取消未完成的连接请求
//        for peripheral in connectingPeripherals {
//            centralManager?.cancelPeripheralConnection(peripheral)
//        }
//        connectingPeripherals.removeAll()
        
        // 断开已连接的外设
        guard let connectedPeripherals = centralManager?.retrieveConnectedPeripherals(withServices: [CBUUID(string: "0000FF12-0000-1000-8000-00805F9B34FB")]) else {
            return
        }
        if connectedPeripherals.count > 0 {
            isCancelSystemBLE = true
        }
        for peripheral in connectedPeripherals {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
    }

    func startScanning(_ deleteCache: Bool = false) {
        isReconnectingNow = false
        if !isScanning {
            isScanning = true
            // 扫描选项
            let options: [String: Any] = [
                CBCentralManagerScanOptionAllowDuplicatesKey: false, // 不允许重复扫描
                CBCentralManagerScanOptionSolicitedServiceUUIDsKey: [] // 仅扫描指定服务的外设
            ]
            if deleteCache {
                discoveredPeripherals = []
            }
            startScanTimer(mac: "")
            centralManager?.scanForPeripherals(withServices: nil, options: options)
            XLogger.shared.log("开始扫描设备")
        }
        reconnectToDevice()
    }

    func stopScanning() {
        XLogger.shared.log("停止扫描")
        isScanning = false
        centralManager?.stopScan()
        BLEManager.shared.stopScan() // 停止扫描
    }

    func connectFunc(to device: CBPeripheral) {
        XLogger.shared.log("连接指定的蓝牙设备3")
        centralManager?.connect(device, options: nil)
    }
    
    func connectFunc(to macAddress: String) {
        for peripheralInfo in discoveredPeripherals {
            if peripheralInfo.macAddress == macAddress {
                let device = peripheralInfo.peripheral
                XLogger.shared.log("连接指定的mac地址\(macAddress)的蓝牙设备")
                centralManager?.connect(device, options: nil)
                break
            }
        }
    }
    
    func connectAndScan(to macAddress: String, deviceName: String) {
        startScanTimer(mac: macAddress)
        if let peripherals = centralManager?.retrieveConnectedPeripherals(withServices: [CBUUID(string: "0000FF12-0000-1000-8000-00805F9B34FB")]) {
            for peripheral in peripherals {
                if peripheral.name == deviceName {
                    if let dd = BluetoothWatchDevice.loadFromSandbox(deviceName: deviceName) {
                        if dd.max == macAddress {
                            let peripheralInfo = PeripheralInfo(peripheral: peripheral, macAddress: macAddress)
                            discoveredPeripherals.append(peripheralInfo)
                            XLogger.shared.log("连接指定的mac地址\(macAddress)的蓝牙设备4")
                            centralManager?.connect(peripheral, options: nil)
                            scanMacAddress = ""
                            return
                        }
                    }
                }
            }
        } else {
            XLogger.shared.log("No known peripheral found")
        }
        
        scanMacAddress = macAddress
        isReconnectingNow = false
        if isScanning {
            centralManager?.stopScan()
        }
        isScanning = true
        // 扫描选项
        let options: [String: Any] = [
            CBCentralManagerScanOptionAllowDuplicatesKey: false, // 不允许重复扫描
            CBCentralManagerScanOptionSolicitedServiceUUIDsKey: [] // 仅扫描指定服务的外设
        ]
        discoveredPeripherals = []
        startScanTimer(mac: "")
        centralManager?.scanForPeripherals(withServices: nil, options: options)
        XLogger.shared.log("开始扫描设备和连接准备")
    }
    
    
    func disconnectDevice() {
        if let per = peripheral {
            autoDisconnect = true
            centralManager?.cancelPeripheralConnection(per)
        }
    }
    
    // 新增发起 BLE 回连功能
    private func reconnectToDevice() {
        let mac = UserDefaults.standard.string(forKey: "deleteLastestDeviceMac") ?? ""
        if (lastestDeviceMac.count == 0 || device != nil) && mac.count == 0 {
            XLogger.shared.log("终止执行1: \(lastestDeviceMac) \(device != nil) \(mac)")
            return
        }
        if let peripherals = centralManager?.retrieveConnectedPeripherals(withServices: [CBUUID(string: "0000FF12-0000-1000-8000-00805F9B34FB")]) {
            if mac.count > 0 {
//                let peripheralInfo = PeripheralInfo(peripheral: peripheral, macAddress: mac)
//                discoveredPeripherals.append(peripheralInfo)
//                deletePeripheralInfo = peripheralInfo
//                NotificationCenter.default.post(name: Notification.Name.SearchDevice, object: "scan") // 搜索页面
                XLogger.shared.log("执行搜索功能，不应该存在，因为mac地址在变化")
            } else {
                if (lastestDeviceMac.count == 0 || device != nil){
                    XLogger.shared.log("终止执行2")
                    return
                }
                for peripheral in peripherals {
                    if lastestDeviceMac.count > 0, let d = BluetoothWatchDevice.loadFromSandbox(mac: lastestDeviceMac) {
                        XLogger.shared.log("设备名称：\(peripheral.name ?? "未知") 和 \(d.deviceName ?? "为空")")
                        if peripheral.name == d.deviceName ?? "e watch" {
                            let peripheralInfo = PeripheralInfo(peripheral: peripheral, macAddress: lastestDeviceMac)
                            discoveredPeripherals.append(peripheralInfo)
                            XLogger.shared.log("连接指定的mac地址\(lastestDeviceMac)的蓝牙设备5")
                            centralManager?.connect(peripheral, options: nil)
                        }
                    }
                }
            }
            
        } else {
            XLogger.shared.log("No known peripheral reconnectToDevice: \(lastestDeviceMac)")
            if (lastestDeviceMac.count == 0 || device != nil){
                return
            }
            connectFunc(to: lastestDeviceMac)
        }
    }
    
    // 先将 OTA 前检查设备是否准备好的指令放到这里
    public func isReadyOTA() {
        delegate?.onBleReady()
    }
    
    public func getDeviceName(mac: String) -> String {
        for peripheralInfo in discoveredPeripherals {
            if peripheralInfo.macAddress == mac {
                return peripheralInfo.peripheral.name ?? ""
            }
        }
        return ""
    }
    
    // 检查当前连接的设备
    public func checkConnectedDevicesIsEmpty() -> Bool {
        let connectedPeripherals = centralManager?.retrieveConnectedPeripherals(withServices: [CBUUID(string: "0000FF12-0000-1000-8000-00805F9B34FB")])
        if connectedPeripherals?.isEmpty == true {
            XLogger.shared.log("No BLE devices are connected.")
            return true
        }
        return false
    }

    // CBCentralManagerDelegate 方法
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            XLogger.shared.log("蓝牙已开启")
            // 扫描设备或执行其他操作
            NotificationCenter.default.post(name: Notification.Name("HealthVCLoading"), object: 0)
            NotificationCenter.default.post(name: Notification.Name("DevicesViewController"), object: "1")
            if lastestDeviceMac.count > 0 {
                scanMacAddress = lastestDeviceMac
            }
            startScanning()
        } else if central.state == .poweredOff {
            XLogger.shared.log("蓝牙已关闭")
            if device != nil {
                self.peripheral?.delegate = nil
                self.peripheral = nil
                device = nil
            }
            stopScanning()
            NotificationCenter.default.post(name: Notification.Name("HealthVCLoading"), object: 1)
            NotificationCenter.default.post(name: Notification.Name("DevicesViewController"), object: "1")
        } else if central.state == .unauthorized {
            stopScanning()
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        XLogger.shared.log("蓝牙设备连接成功")
        isCancelSystemBLE = false
        isReconnectingNow = false
        self.peripheral = peripheral
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        UserDefaults.standard.removeObject(forKey: "deleteLastestDeviceMac")
        deletePeripheralInfo = nil
        
        for p in discoveredPeripherals {
            if p.peripheral.identifier.uuidString == peripheral.identifier.uuidString {
                lastestDeviceMac = p.macAddress
                XLogger.shared.log("刷新最新的连接成功的设备：\(lastestDeviceMac)")
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
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        XLogger.shared.log("连接蓝牙设备失败: \(error?.localizedDescription ?? "未知错误")")
        connectFailMessage.append("[\(device?.max ?? "")]连接失败: \(error?.localizedDescription ?? "未知错误")")
        self.peripheral?.delegate = nil
        self.peripheral = nil
        handler.handleDisconnected()
        device = nil
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        var msg = "[\(lastestDeviceMac)]断开连接:"
        
        // 处理非空错误
        if let error = error {
            msg += "错误描述: \(error.localizedDescription)"
            XLogger.shared.log(msg)
            if let nserror = error as? NSError {
                msg += "错误域: \(nserror.domain) 错误码: \(nserror.code)"
                XLogger.shared.log(msg)
            } else {
                msg += "原始错误对象: \(error) 错误类型: \(type(of: error))"
                XLogger.shared.log(msg)
            }
        } else {
            msg += "断开原因: 主动断开连接（无错误）"
            XLogger.shared.log(msg)
        }
        connectFailMessage += msg
        NotificationCenter.default.post(name: Notification.Name("DevicesViewController"), object: "100")
        if autoDisconnect {
            XLogger.shared.log("蓝牙断开回调方法：autoDisconnect")
            self.peripheral?.delegate = nil
            self.peripheral = nil
            device = nil
            handler.handleDisconnected()
            autoDisconnect = false
            if isFromOTASuccess {
                if lastestDeviceMac.count > 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        [weak self] in
                        self?.connectAndScan(to: lastestDeviceMac, deviceName: peripheral.name ?? "e watch")
                    }
                }
                isFromOTASuccess = false
            }
            return
        }
        if switchAutoDisconnect {
            XLogger.shared.log("蓝牙断开回调方法：switchAutoDisconnect")
            self.peripheral?.delegate = nil
            self.peripheral = nil
            device = nil
            handler.handleDisconnected()
            switchAutoDisconnect = false
            NotificationCenter.default.post(name: Notification.Name("DevicesViewController"), object: "3000")
            return
        }
        if isCancelSystemBLE {
            isCancelSystemBLE = false
            XLogger.shared.log("蓝牙断开回调方法：isCancelSystemBLE")
            self.peripheral?.delegate = nil
            self.peripheral = nil
            device = nil
            handler.handleDisconnected()
            return
        }
        startReconnectTimer() // 设备断开连接时，启动重连定时器
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi: NSNumber) {
        // 检查 advertisementData 是否包含我们需要的数据
        if let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data,
           manufacturerData.count == 15,
           manufacturerData[1] == 0x01,
           manufacturerData[0] == 0x06 {
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
                XLogger.shared.log(peripheralInfo)
            }
            if scanMacAddress.count > 0 && macAddress.lowercased() == scanMacAddress.lowercased() {
                XLogger.shared.log("连接指定的mac地址\(scanMacAddress)的蓝牙设备6")
                if (peripheral.name?.count ?? 0) > 0 {
                    centralManager?.connect(peripheral, options: nil)
                    scanMacAddress = ""
                }
            }
        }
    }

    // CBPeripheralDelegate 方法
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)
                XLogger.shared.log("Service UUID: \(service.uuid)")
                XLogger.shared.log("Is Primary: \(service.isPrimary)")
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                // 保存特征或根据特征 UUID 进行不同操作
                XLogger.shared.log("Service UUID: \(service.uuid) characteristic UUID: \(characteristic.uuid.uuidString)")
                XLogger.shared.log("Service UUID: \(service.uuid) characteristic.properties: \(characteristicPropertiesToString(characteristic.properties))")
                XLogger.shared.log("Service UUID: \(service.uuid) characteristic.isNotifying: \(characteristic.isNotifying)")
                if OTAService.dataInUuid == characteristic.uuid || characteristic.uuid.uuidString == "0000FF14-0000-1000-8000-00805F9B34FB" {
                    Logger.n(self, "Data In characteristic found")
                    dataInCharacteristic = characteristic
                } else if OTAService.dataOutUuid == characteristic.uuid {
                    Logger.n(self, "Data Out characteristic found")
                    dataOutCharacteristic = characteristic
                } else if characteristic.uuid.uuidString == "FF13" || characteristic.uuid.uuidString == "0000FF13-0000-1000-8000-00805F9B34FB"  { // write
                    self.characteristic = characteristic
                    stopScanning()
                    handler.handleConnected()
                }
                if characteristic.properties.contains(.notify)  {
                    // 启用通知
                    notifyCharacteristic = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                    XLogger.shared.log("开启通知Service UUID: \(service.uuid) characteristic UUID: \(characteristic.uuid.uuidString)")
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            XLogger.shared.log("写入特征值失败: \(error.localizedDescription)")
        } else {
            XLogger.shared.log("写入特征值成功")
            // 这里可以选择读取特征值来获取响应数据
            peripheral.readValue(for: characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: (any Error)?) {
        if let error = error {
            XLogger.shared.log("Notification读取特征值失败: \(error.localizedDescription)")
        } else if let value = characteristic.value {
            XLogger.shared.log("【\(DateFormatter.logDateFormatter.string(from: Date()))】Notification接受到的数据<-[\(value.count)] \(value.hex)")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            XLogger.shared.log("读取特征值失败: \(error.localizedDescription)")
        } else if let value = characteristic.value {
            XLogger.shared.log("【\(DateFormatter.logDateFormatter.string(from: Date()))】接受到的数据<-[\(value.count)] \(value.hex)")
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
        XLogger.shared.log("【\(DateFormatter.logDateFormatter.string(from: Date()))】发送数据: \(hexString)")
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
        // 先清理旧定时器
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        
        // 确保在主线程创建定时器
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
//            self.reconnectTimer = Timer.scheduledTimer(timeInterval: 10.0,
//                                                       target: self,
//                                                       selector: #selector(disconnectAndStopTimer(_:)),
//                                                       userInfo: nil,
//                                                       repeats: false)
//            XLogger.shared.log("执行延时3秒断开检查") // 确保日志在主线程输出
            
            // 连接操作也需在主线程执行
            if !self.isFromOTASuccess {
                if let lastConnectedPeripheral = self.peripheral {
                    self.isReconnectingNow = true
                    NotificationCenter.default.post(name: Notification.Name("DevicesViewController"), object: "100")
                    XLogger.shared.log("连接指定的mac地址\(lastestDeviceMac)的蓝牙设备7")
                    self.centralManager?.connect(lastConnectedPeripheral, options: nil)
                }
            }
        }
    }
    
    private func startScanTimer(mac: String) {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) {
            [weak self] t in
            if let array = self?.discoveredPeripherals {
                if array.count == 0 && mac.count == 0 {
                    connectFailMessage += "[]搜素设备：未搜索到设备"
                    return
                }
                for peripheralInfo in  array {
                    if peripheralInfo.macAddress == mac {
                        return
                    }
                }
            }
            connectFailMessage += "[\(mac)]未搜索到手表：请检查手表BLE是否正常广播"
        }
    }
    
    @objc private func disconnectAndStopTimer(_ timer: Timer) {
        XLogger.shared.log("定时器被激活了")
        guard timer === reconnectTimer else {
            XLogger.shared.log("忽略无效的定时器回调")
            return
        }
        
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        
        // 安全断开连接
        if let lastConnectedPeripheral = self.peripheral {
            centralManager?.cancelPeripheralConnection(lastConnectedPeripheral)
        }
        
        // 重置对象并通知处理
        if let cha = notifyCharacteristic {
            self.peripheral?.setNotifyValue(false, for: cha)
        }
        peripheral = nil
        device = nil
        handler.handleDisconnected()
    }
}

extension XGZTBlueToothManager: ABOtaSendDelegate {
    func sendData(_ data: Data) {
        guard let dataOutCharacteristic else { return }
        XLogger.shared.log("=> 0x\(data.hex)")
        guard peripheral?.state == .connected else {
            XLogger.shared.log("Cannot send data: Peripheral not connected")
            return
        }
        peripheral?.writeValue(data, for: dataOutCharacteristic, type:.withoutResponse)
    }
}

extension DateFormatter {
    static let logDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS" // 例如："14:05:23.456"
        formatter.locale = Locale(identifier: "en_US_POSIX") // 确保格式一致
        return formatter
    }()
}
