//
//  ABOta.swift
//  AB_OTA Demo
//
//  Created by Bluetrum on 2023/3/1.
//

import Foundation

public protocol ABOtaSendDelegate: AnyObject {
    /// 发送数据
    func sendData(_ data: Data)
}

public enum OtaStatus {
    case OtaStatusReady
    case OtaStatusStart
    case OtaStatusUpdating(Int)
    case OtaStatusPause
    case OtaStatusContinue
    case OtaStatuSuccess
    case OtaStatusWaitFinish
    case OtaStatusFail(Int)
}

public protocol ABOtaEventListener: AnyObject {
    func onStatusChanged(_ status: OtaStatus)
    
    // FOTA会在准备环境时获取设备的一些信息，可根据需要进行取舍
    func onReceiveVersion(_ version: UInt16)
    func onReceiveTWSInfo(isTWS: Bool, isTWSConnected: Bool)
    func onReceiveChannel(_ isLeftChannel: Bool)
}

public class ABOta {
    
    // OTA Error
    public static let ERROR_CODE_DEVICE_REPORT: Int     = 0x1000
    public static let ERROR_CODE_DEVICE_REFUSED: Int    = 0x1001
    public static let ERROR_CODE_NO_OTA_DATA: Int       = 0x1002
    public static let ERROR_CODE_TIMEOUT: Int           = 0x1003
    public static let ERROR_CODE_TWS_DISCONNECTED: Int  = 0x1004
    public static let ERROR_CODE_DATA_READER_ERROR: Int = 0x1005
    // ERROR_CODE_DEVICE_REPORT
    // 设备报告的错误在OtaError中不一定能覆盖全，这里直接输出，范围是一个字节
    public static let ERROR_CODE_SAME_FIRMWARE: Int     = 1
    public static let ERROR_CODE_KEY_MISMATCH: Int      = 2
    public static let ERROR_CODE_CRC_ERROR: Int         = 11
    
    
    public weak var sendDelegate: ABOtaSendDelegate?
    public weak var eventListener: ABOtaEventListener?
    
    private var otaManager: ABOtaManager!
    
    public init() {
        self.otaManager = ABOtaManager(delegate: self)
        self.otaManager.initialize()
    }
    
    public func prepareToUpdate() {
        otaManager.prepareToUpdate()
    }
    
    public func setOtaData(_ data: Data) {
        otaManager.setOtaData(data)
    }
    
    public func setDataRead(_ dataReader: DataReader) {
        otaManager.setDataReader(dataReader)
    }
    
    public func setPacketSize(_ packetSize: UInt16) {
        otaManager.setPacketSize(packetSize)
    }
    
    public func isReady() -> Bool {
        return otaManager.isReadyToUpdate()
    }
    
    public func startOTA() {
        otaManager.startOTA()
    }
    
    public func isUpdating() -> Bool {
        return otaManager.isUpdating()
    }
}

extension ABOta {
    
    public func handleData(_ data: Data) {
        _ = otaManager.processData(data)
    }
    
    public func nextRun() {
        otaManager.nextRun()
    }
}

extension ABOta {
    
    private func handleTWSMessage() {
        eventListener?.onReceiveTWSInfo(isTWS: otaManager.isTwsDevice(),
                                   isTWSConnected: otaManager.isTWSConnected())
    }
}

extension ABOta: ABOtaManagerDelegate {
    
    public func sendOtaData(_ data: Data) throws {
        sendDelegate?.sendData(data)
    }
    
    public func onReady() {
        eventListener?.onStatusChanged(.OtaStatusReady)
    }
    
    public func onStart() {
        eventListener?.onStatusChanged(.OtaStatusStart)
    }
    
    public func onProgress(_ progress: Float) {
        eventListener?.onStatusChanged(.OtaStatusUpdating(Int(progress)))
    }
    
    public func onStop() {
        // Peripheral event, never happen here
    }
    
    public func onFinish() {
        if otaManager.isCompressedData {
            eventListener?.onStatusChanged(.OtaStatusWaitFinish)
        } else {
            eventListener?.onStatusChanged(.OtaStatuSuccess)
        }
    }
    
    public func onPause() {
        eventListener?.onStatusChanged(.OtaStatusPause)
    }
    
    public func onContinue() {
        eventListener?.onStatusChanged(.OtaStatusContinue)
    }
    
    public func onError(_ error: OTAError) {
        if case .deviceReport(let code) = error {
            // 设备报告的错误在OtaError中不一定能覆盖全，这里直接输出，范围是一个字节
            eventListener?.onStatusChanged(.OtaStatusFail(Int(code)))
        } else {
            eventListener?.onStatusChanged(.OtaStatusFail(error.errorCode))
        }
    }
    
    public func onTWSDisconnected() {
        eventListener?.onStatusChanged(.OtaStatusFail(ABOta.ERROR_CODE_TWS_DISCONNECTED))
    }
    
    public func onReceiveVersion(_ version: UInt16) {
        eventListener?.onReceiveVersion(version)
    }
    
    public func onReceiveIsTWS(_ isTWS: Bool) {
        handleTWSMessage()
    }
    
    public func onReceiveTWSConnected(_ connected: Bool) {
        handleTWSMessage()
    }
    
    public func onReceiveChannel(_ isLeftChannel: Bool) {
        eventListener?.onReceiveChannel(isLeftChannel)
    }
}

extension OTAError {
    
    var errorCode: Int {
        switch self {
        case .refusedByDevice:          return ABOta.ERROR_CODE_DEVICE_REFUSED
        case .noDataAvailable:          return ABOta.ERROR_CODE_NO_OTA_DATA
        case .timeoutWaitingResponse:   return ABOta.ERROR_CODE_TIMEOUT
        case .twsDisconnected:          return ABOta.ERROR_CODE_TWS_DISCONNECTED
        case .deviceReport(let code):   return Int(code)
        case .dataReaderError:          return ABOta.ERROR_CODE_DATA_READER_ERROR
        }
    }
}
