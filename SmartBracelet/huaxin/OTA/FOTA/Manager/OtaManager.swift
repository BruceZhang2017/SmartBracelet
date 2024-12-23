//
//  OTAManager.swift
//  AB OTA Demo
//
//  Created by Bluetrum on 2020/12/25.
//

import Foundation
import CoreBluetooth

/// `OtaManager`代理，用于监听OTA事件。
public protocol OtaManagerDelegate: AnyObject {
    /// OTA已经准备就绪，可以开始升级
    func onReady()
    /// OTA已开始
    func onStart()
    /**
     OTA进度
     - Parameters:
        - progress: 进度，[0, 1.0]
     */
    func onProgress(_ progress: Float)
    /// OTA已停止
    func onStop()
    /// OTA已完成
    func onFinish()
    /// OTA已暂停
    func onPause()
    /// OTA已继续
    func onContinue()
    /**
     OTA遇到错误
     - Parameters:
        - error: 错误，`OTAError`
     */
    func onError(_ error: OTAError)
    
    // state & info
    /// TWS断开事件
    func onTWSDisconnected()
    /**
     接收到设备当前固件版本号
     - Parameters:
        - version: 固件版本号，具体定义参见固件端说明文档
     */
    func onReceiveVersion(_ version: UInt16)
    /**
     是否TWS
     - Parameters:
        - isTWS: 是否TWS
     */
    func onReceiveIsTWS(_ isTWS: Bool)
    /**
     TWS对耳是否已连接
     - Parameters:
        - connected: 是否已连接
     */
    func onReceiveTWSConnected(_ connected: Bool)
    /**
     声音左右通道，非TWS不用关注
     - Parameters:
        - isLeftChannel: true为左声道，false为右声道
     */
    func onReceiveChannel(_ isLeftChannel: Bool)
    
    // BLE status
    func onBleConnect()
    func onBleDiscoverServices()
    func onBleDidDiscoverServices()
    func onBleDisconverCharacteristics()
    func onBleDidDiscoverCharacteristic(_ characteristic: CBCharacteristic)
    func onBleSetNotify(_ characteristic: CBCharacteristic)
    func onBleDidSetNotify(_ characteristic: CBCharacteristic)
    func onBleNotPoweredOn(_ central: CBCentralManager)
    func onBleDidConnectPeripheral()
    func onBleDidDisconnectPeripheral()
    func onBleDidFailToConnectPeripheral()
}

/// 使BLE状态回调可选化，需要就覆盖实现
public extension OtaManagerDelegate {
    func onBleConnect() {}
    func onBleDiscoverServices() {}
    func onBleDidDiscoverServices() {}
    func onBleDisconverCharacteristics() {}
    func onBleDidDiscoverCharacteristic(_ characteristic: CBCharacteristic) {}
    func onBleSetNotify(_ characteristic: CBCharacteristic) {}
    func onBleDidSetNotify(_ characteristic: CBCharacteristic) {}
    func onBleNotPoweredOn(_ central: CBCentralManager) {}
    func onBleDidConnectPeripheral() {}
    func onBleDidDisconnectPeripheral() {}
    func onBleDidFailToConnectPeripheral() {}
}

/// 抽象类，不直接实例化，请使用`BleOtaManager`。
open class OtaManager: NSObject {
    
    /// 发送每一个数据块之后，等待固件回复的默认超时间隔
    public static let DEFAULT_TIMEOUT: TimeInterval = 10 // In second
    /// 固件默认版本
    public static let UNDEFINED_FIRMWARE_VERSION: UInt16 = 0xFFFF
    
    // MARK: - Properties
    
    /// 代理`OtaManagerDelegate`用以接收OTA状态
    open weak var delegate: OtaManagerDelegate?
    /// OTA文件的版本，默认是0xFFFF，即接受全部版本
    public var otaFirmwareVersion: UInt16 = UNDEFINED_FIRMWARE_VERSION
    
    var dataProvider: OtaDataProvider?
    var commandGenerator: OtaCommandGenerator
    public var deviceFirmwareVersion: UInt16?
    public var allowedUpdate: Bool = false
    
    private var blockSize = OtaConstants.DEFAULT_BLOCK_SIZE
    private var packetSize = OtaConstants.DEFAULT_PACKET_SIZE
    
    public var isCompressedData: Bool {
        return dataProvider?.isCompressedData ?? false
    }
    
    var isUpdatePause: Bool = false
    
    // TWS升级时使用，释放时不需要重置
    var isPrimaryUpdated: Bool = false
    var _isUpdating: Bool = false
    var _isTwsDevice: Bool?
    var _isTWSConnected: Bool?
    
    var disconnectedDueToDeviceError: Bool = false // 报错后断开不再调用onStop
    
    // Identification
    /**
     是否需要发送识别码，默认是发送。
     3月之后发的固件均需要使用识别码；更早的固件不需要发送，需要设为false，否则会报0x40错误。
     */
    private var needIdentification: Bool = true
    var sentIdentification: Bool = false
    let DELAY_AFTER_SEND_IDENTIFICATION: Int = 200 // ms
    
    private var timeoutTimer: Timer?

    // MARK: - Public API
    
    /// 构造器
    public override init() {
        commandGenerator = OtaCommandGenerator()
        super.init()
    }
    
    /// OTA Manager初始化，在进行OTA升级之前必须进行初始化。
    open func initialize() {
    }
    
    /**
     释放资源，包括断开蓝牙连接。
     通常在升级完成、遇到错误，或者超时的时候，会自动释放资源，但是如果需要中断升级，亦可手动调用。
     */
    open func deinitialize() {
        synced(self) {
            otaFirmwareVersion = OtaManager.UNDEFINED_FIRMWARE_VERSION
            deviceFirmwareVersion = nil
            allowedUpdate = false
            _isUpdating = false
            isUpdatePause = false
            sentIdentification = false
            cancelTimeout()
            commandGenerator.reset()
            
            if let dataProvider {
                do {
                    try dataProvider.close()
                } catch {
                    // 这里异常不影响结果
                }
            }
        }
    }
    
    open func getPacketSize() -> UInt16 { packetSize }
    
    open func getBlockSize() -> UInt32 { blockSize }
    
    /// 开始进行OTA升级，升级之前必须先判断`isReadyToUpdate()`。
    open func startOTA() {
        _isUpdating = true
        delegate?.onStart()
        // start from get version
        getOtaInfoVersion()
    }
    
    /**
     判断设备端是否已经就绪
     
     - Returns: 是否已就绪
     */
    open func isDeviceReady() -> Bool {
        Logger.i(self, "isDeviceReady: isTwsDevice = \(_isTwsDevice?.description ?? "?"), isTWSConnected = \(_isTWSConnected?.description ?? "?")")
        
        // Can't go through until we get response of getAllInfo
        guard let isTwsDevice = _isTwsDevice else {
            return false
        }
        
        if isTwsDevice {
            return _isTWSConnected ?? false
        } else {
            return true
        }
    }
    
    /**
     判断条件（设备和数据）是否已经全部就绪。
     
     - Returns: 是否已就绪
     */
    open func isReadyToUpdate() -> Bool {
        Logger.i(self, "isReadyToUpdate: DeviceReady = \(isDeviceReady()), DataReady = \(dataProvider != nil)")
        
        return isDeviceReady() && dataProvider != nil
    }
    
    /// 设置OTA数据。
    /// - Parameter otaData: OTA数据
    open func setOtaData(_ otaData: Data) {
        let dataReader = OtaDataReader(otaData: otaData)
        setDataReader(dataReader)
    }
    
    /// 配置DataReader
    /// - Parameter dataReader: OTA数据读取器
    open func setDataReader(_ dataReader: DataReader) {
        do {
            let dataProvider = OtaDataProvider(dataReader: dataReader)
            try dataProvider.open()
            self.dataProvider = dataProvider
            dataProvider.blockSize = getBlockSize()
            dataProvider.packetSize = getPacketSize()
            
            Logger.n(self, "OTA data is ready")
            checkIfReadyToUpdate()
        } catch {
            notifyOnError(.dataReaderError)
        }
    }
    
    /// 设备准备好之后，调用此方法
    public func prepareToUpdate() {
        if needIdentification {
            // 发送OTA识别信息
            sendOtaIdentification()
        } else {
            // 获取设备信息
            getAllInfo()
        }
    }
    
    /**
     是否正在进行升级
     - Returns: 是否正在升级
     */
    open func isUpdating() -> Bool { return _isUpdating }
    
    /**
     当前设备是否是TWS设备
     - Returns: 是否TWS设备
     */
    open func isTwsDevice() -> Bool {
        return _isTwsDevice != nil && _isTwsDevice!
    }
    
    /**
     TWS对耳是否已连接
     - Returns: TWS是否已连接
     */
    open func isTWSConnected() -> Bool {
        return _isTWSConnected != nil && _isTWSConnected!
    }
    
    open func send(_ data: Data) throws {
    }
    
    // MARK: - Notify
    
    open func notifyOnStop() {
        if !disconnectedDueToDeviceError {
            delegate?.onStop()
        }
        disconnectedDueToDeviceError = false
    }
    
    open func notifyOnError(_ error: OTAError) {
        disconnectedDueToDeviceError = true
        _isUpdating = false
        delegate?.onError(error)
        deinitialize()
    }
    
    // MARK: -
    
    open func canSendNow() -> Bool {
        guard allowedUpdate,
              let finished = dataProvider?.isBlockSendFinish(), !finished else {
            return false
        }
        return true
    }
    
    public func checkIfReadyToUpdate() {
        let ready = isReadyToUpdate()
        Logger.n(self, "checkIfReadyToUpdate: \(ready)")
        if ready {
            delegate?.onReady()
        }
    }
    
    public func notifyOnProgress(progress: UInt32) {
        delegate?.onProgress(Float(progress))
    }
    
    private func btSendData(_ data: Data) {
        do {
            try send(data)
        } catch {
            Logger.e(self, error)
        }
    }
    
    // MARK: - About Command
    
    public func getOtaInfoVersion() {
        let cmd = commandGenerator.cmdGetInfoVersion()
        btSendData(cmd)
        // 等待固件回复
        waitingForTimeout()
    }
    
    public func getOtaInfoUpdate(version: UInt16) {
        guard let dataProvider = dataProvider else {
            return
        }
        
        do {
            let hashData = try dataProvider.getHash()
            let cmd = commandGenerator.cmdGetInfoUpdate(version: version, hashData: hashData)
            btSendData(cmd)
            // 等待固件回复
            waitingForTimeout()
        } catch {
            notifyOnError(.dataReaderError)
        }
    }
    
    public func sendOtaIdentification() {
        let cmd = commandGenerator.cmdOtaIdentification()
        btSendData(cmd)
    }
    
    public func getAllInfo() {
        let cmd = commandGenerator.cmdGetAllInfo()
        btSendData(cmd)
        // 等待固件回复
        waitingForTimeout()
    }
    
    public func sendOtaStart() {
        guard let dataProvider else {
            return
        }
        
        let startAddress = dataProvider.startAddress
        let totalLengthToBeSent = dataProvider.getTotalLengthToBeSent()
        let header = commandGenerator.cmdStartSendHeader(startAddress: startAddress, totalLengthToBeSent: totalLengthToBeSent)
        let headerSize = header.count
        
        do {
            let data = try dataProvider.getStartData(headerSize: UInt8(headerSize))
            let cmd = header + data
            btSendData(cmd)
        } catch {
            notifyOnError(.dataReaderError)
        }
        
        // Report progress
        let progress = dataProvider.progress
        notifyOnProgress(progress: progress)
    }
    
    public func sendOtaData() {
        guard let dataProvider else {
            return
        }
        
        let header = commandGenerator.cmdSendDataHeader()
        let headerSize = header.count
        
        do {
            let data = try dataProvider.getDataToBeSent(headerSize: UInt8(headerSize))
            let cmd = header + data
            btSendData(cmd)
        } catch {
            notifyOnError(.dataReaderError)
        }
        
        
        // Report progress
        let progress = dataProvider.progress
        notifyOnProgress(progress: progress)
    }
    
    public func runDataSend() {
        if !needIdentification || sentIdentification {
            // Continue sending data
            if canSendNow() {
                sendOtaData()
            } else {
                if let isBlockSendFinish = dataProvider?.isBlockSendFinish(), isBlockSendFinish {
                    // 等待固件回复
                    waitingForTimeout()
                }
            }
        } else {
            // Delay, waiting for Firmware
            DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.microseconds(DELAY_AFTER_SEND_IDENTIFICATION)) {
                self.sentIdentification = true
                // Get info
                self.getAllInfo()
            }
        }
    }
    
    private func waitingForTimeout() {
        timeoutTimer?.invalidate()
        timeoutTimer = Timer.scheduledTimer(timeInterval: OtaManager.DEFAULT_TIMEOUT, target: self, selector: #selector(handleTimeout), userInfo: nil, repeats: false)
    }
    
    @objc
    private func handleTimeout() {
        // 有时候出现一种极限情况，如果判断可以发送，但是还没发送前
        // 来了暂停，还是会发送然后等超时，所以在这加一个发送后判断
        guard !isUpdatePause else { return }
        
        Logger.e(self, "Waiting for response timeout: \(_isUpdating)")
        
        synced(self) {
            if _isUpdating {
                notifyOnError(.timeoutWaitingResponse)
            }
        }
    }
    
    private func cancelTimeout() {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }
    
    // MARK: - Data Process
    
    public func processData(_ data: Data) -> Bool {
        guard data.count > 2 else {
            Logger.e(self, "Received data length is less than 3")
            return false
        }
        
        let bb = ByteBuffer.wrap(data)
        
        let cmdType = bb.get()
        let _ = bb.get() // seqNum, Not used for now
        
        if let otaCmd = OtaCommand(rawValue: cmdType) {
            switch otaCmd {
            case .CMD_NOTIFY_STATUS:
                let state = bb.get()
                processNotifyState(state)
                return true
            case .CMD_GET_INFO:
                cancelTimeout()
                let cmdSubType = bb.get()
                var extraData = Data(count: bb.remainning)
                bb.get(&extraData)
                processGetInfo(cmdSubType: cmdSubType, data: extraData)
                return true
            case .CMD_GET_INFO_TLV:
                cancelTimeout()
                var infoData = Data(count: bb.remainning)
                bb.get(&infoData)
                processGetInfoTLV(data: infoData)
                return true
                
            default: break
            }
        }
        
        return false
    }
    
    func processNotifyState(_ state: UInt8) {
        if let otaState = OtaState(rawValue: state) {
            switch otaState {
            case .STATE_OK:
                cancelTimeout()
                // If not in pause state, and not done yet, go on sending, until done
                if !isUpdatePause, let dataProvider = dataProvider, !dataProvider.isAllDataSent() {
                    sendOtaStart()
                }
                break
            case .STATE_DONE:
                cancelTimeout()
                _isUpdating = false
                // All done
                delegate?.onFinish()
                deinitialize()
                break
            case .STATE_PAUSE:
                cancelTimeout()
                allowedUpdate = false
                _isUpdating = false
                isUpdatePause = true
                delegate?.onPause()
                break
            case .STATE_CONTINUE:
                delegate?.onContinue()
                // Resume
                _isUpdating = true
                isUpdatePause = false
                getOtaInfoVersion()
                break
            case .STATE_TWS_DISCONNECTED:
                _isTWSConnected = false
                _isUpdating = false
                cancelTimeout()
                delegate?.onReceiveTWSConnected(_isTWSConnected!)
                notifyOnError(.twsDisconnected)
                break;
            }
        } else {
            _isUpdating = false
            Logger.e(self, "Device report state: \(state)")
            cancelTimeout()
            notifyOnError(.deviceReport(code: state))
        }
    }
    
    func processGetInfo(cmdSubType: UInt8, data: Data) {
        // Handle command
        processInfo(infoType: cmdSubType, infoData: data)
        
        // The operation after command handler
        if let otaInfoType = OtaGetInfoType(rawValue: cmdSubType) {
            switch otaInfoType {
            case .CMD_GET_INFO_TYPE_VERSION:
                getOtaInfoUpdate(version: otaFirmwareVersion)
                break
            case .CMD_GET_INFO_TYPE_UPDATE:
                if allowedUpdate {
                    // Send the first packet
                    sendOtaStart()
                } else {
                    cancelTimeout()
                    notifyOnError(.refusedByDevice)
                }
                break
            default:
                break
            }
        }
    }
    
    func processGetInfoTLV(data: Data) {
        var tlvInfoData = data
        
        while tlvInfoData.count > 2 {
            let bb = ByteBuffer.wrap(tlvInfoData)
            
            let infoType = bb.get()
            let infoLength = bb.get()
            var infoData = Data(count: Int(infoLength))
            bb.get(&infoData)
            processInfo(infoType: infoType, infoData: infoData)
            
            // Process remainning data
            if (bb.hasRemaining()) {
                var remainningData = Data(count: bb.remainning)
                bb.get(&remainningData)
                tlvInfoData = remainningData
                continue
            }
            break
        }
        
        checkIfReadyToUpdate()
    }
    
    private func processInfo(infoType: UInt8, infoData: Data) {
        Logger.d(self, "processInfo: \(infoType) -> \(infoData.hex)")
        
        if let otaInfoType = OtaGetInfoType(rawValue: infoType) {
            switch otaInfoType {
            case .CMD_GET_INFO_TYPE_VERSION:
                guard infoData.count == 2 else {
                    return
                }
                let bb = ByteBuffer.wrap(infoData).order(.little)
                let version: UInt16 = bb.get()
                deviceFirmwareVersion = version
                delegate?.onReceiveVersion(version)
                break
            case .CMD_GET_INFO_TYPE_UPDATE:
                guard infoData.count == 11 else {
                    return
                }
                let bb = ByteBuffer.wrap(infoData).order(.little)
                
                // Start address
                let startAddress: UInt32 = bb.get()
                dataProvider?.startAddress = startAddress
                // Block size
                let blockSize: UInt32 = bb.get()
                dataProvider?.blockSize = blockSize
                // Max packet size
                let packetSize: UInt16 = bb.get()
                dataProvider?.packetSize = packetSize
                
                // Check whether device allow update
                allowedUpdate = (bb.get() == DEVICE_ALLOW_UPDATE)
                break
            case .CMD_GET_INFO_TYPE_CAPABILITIES:
                guard infoData.count == 2 else {
                    return
                }
                let bb = ByteBuffer.wrap(infoData).order(.little)
                let devInfoCapabilities: UInt16 = bb.get()
                let isTwsDevice = devInfoCapabilities.isTwsDevice
                self._isTwsDevice = isTwsDevice
                delegate?.onReceiveIsTWS(isTwsDevice)
                break
            case .CMD_GET_INFO_TYPE_STATUS:
                guard infoData.count == 2 else {
                    return
                }
                let bb = ByteBuffer.wrap(infoData).order(.little)
                let deviceStatus: UInt16 = bb.get()
                let connected = deviceStatus.isTwsConnected
                _isTWSConnected = connected
                delegate?.onReceiveTWSConnected(connected)
                break
            case .CMD_GET_INFO_TYPE_CHANNEL:
                guard infoData.count == 1 else {
                    return
                }
                let channel = infoData[0]
                if channel.isLeftChannel {
                    delegate?.onReceiveChannel(true)
                } else {
                    delegate?.onReceiveChannel(false)
                }
                break
            }
        } else {
            Logger.e(self, "Unknown info type \(infoType)")
        }
    }
}
