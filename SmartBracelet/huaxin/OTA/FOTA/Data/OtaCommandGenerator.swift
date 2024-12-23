//
//  OTACommand.swift
//  AB OTA Demo
//
//  Created by Bluetrum on 2020/12/25.
//

import Foundation

class OtaCommandGenerator {
    
    private var CMD_OTA_IDENTIFICATION: [UInt8] = [0xCC, 0xAA, 0x55, 0xEE, 0x12, 0x19, 0xE4]

    private var seqNum: UInt8 = 0
    
    public init() {
    }
    
    public func reset() {
        seqNum = 0
    }
    
    /* TLV format Command Data Generator */
    
    private func generateCmdGetInfoData(cmd: OtaGetInfoType, value: String) -> Data {
        let valueData = value.data(using: String.Encoding.utf8)!
        let bb = ByteBuffer(size: 2 + valueData.count)
        bb.put(cmd.rawValue)
        bb.put(UInt8(valueData.count))
        bb.put(valueData)
        return bb.array()
    }
    
    private func generateCmdGetInfoData(cmd: OtaGetInfoType, value: Data) -> Data {
        let bb = ByteBuffer(size: 2 + value.count)
        bb.put(cmd.rawValue)
        bb.put(UInt8(value.count))
        bb.put(value)
        return bb.array()
    }
    
    private func generateCmdGetInfoData<T: FixedWidthInteger>(cmd: OtaGetInfoType, value: T) -> Data {
        let bb = ByteBuffer(size: 2 + MemoryLayout<T>.size)
        bb.put(cmd.rawValue)
        bb.put(UInt8(MemoryLayout<T>.size))
        bb.put(value)
        return bb.array()
    }
    
    private func generateCmdGetInfoData(cmd: OtaGetInfoType) -> Data {
        let bb = ByteBuffer(size: 2)
        bb.put(cmd.rawValue)
        bb.put(UInt8(0))
        return bb.array()
    }
    
    /* Info Command Data */
    
    public func cmdDataGetInfoVersion() -> Data {
        return generateCmdGetInfoData(cmd: .CMD_GET_INFO_TYPE_VERSION)
    }
    
    public func cmdDataGetInfoUpdate(version: UInt16, hashData: Data?) -> Data {
        let bb = ByteBuffer(size: 6).order(.little)
        bb.put(version)
        
        if let data = hashData {
            bb.put(data[0...3])
        } else {
            bb.put(UInt32.max)
        }
        
        return generateCmdGetInfoData(cmd: .CMD_GET_INFO_TYPE_UPDATE, value: bb.array())
    }
    
    public func cmdDataGetInfoTWS() -> Data {
        return generateCmdGetInfoData(cmd: .CMD_GET_INFO_TYPE_CAPABILITIES)
    }
    
    public func cmdDataGetInfoStatus() -> Data {
        return generateCmdGetInfoData(cmd: .CMD_GET_INFO_TYPE_STATUS)
    }
    
    public func cmdDataGetInfoChannel() -> Data {
        return generateCmdGetInfoData(cmd: .CMD_GET_INFO_TYPE_CHANNEL)
    }
    
    /* Command with TLV format */
    
    public func cmdGetAllInfo() -> Data {
        var data = Data()
        data.append(OtaCommand.CMD_GET_INFO_TLV.rawValue)
        data.append(seqNum); seqNum &+= 1
        
        data.append(cmdDataGetInfoVersion())
        data.append(cmdDataGetInfoTWS())
        data.append(cmdDataGetInfoStatus())
        data.append(cmdDataGetInfoChannel())
        
        return data
    }
    
    /* Command */
    
    public func cmdOtaIdentification() -> Data {
        return Data(bytes: CMD_OTA_IDENTIFICATION, count: CMD_OTA_IDENTIFICATION.count)
    }
    
    public func cmdGetInfoVersion() -> Data {
        let bb = ByteBuffer(size: 3)
        bb.put(OtaCommand.CMD_GET_INFO.rawValue)
        bb.put(seqNum); seqNum &+= 1
        bb.put(OtaGetInfoType.CMD_GET_INFO_TYPE_VERSION.rawValue)
        return bb.array()
    }
    
    public func cmdGetInfoUpdate(version: UInt16, hashData: Data) -> Data {
        let bb = ByteBuffer(size: 9).order(.little)
        bb.put(OtaCommand.CMD_GET_INFO.rawValue)
        bb.put(seqNum); seqNum &+= 1
        bb.put(OtaGetInfoType.CMD_GET_INFO_TYPE_UPDATE.rawValue)
        bb.put(version)
        bb.put(hashData[0...3])
        return bb.array()
    }
    
    /* OTA Data */
    
//    public func cmdStartSend() throws -> Data {
//        guard let dataProvider = dataProvider else {
//            throw OTAError.noDataAvailable
//        }
//        
//        var data = Data()
//        
//        // Data must be taken in strict order
//        // startAddress/getTotalLengthToBeSent()/getStartData(:)
//        
//        data.append(OtaCommand.CMD_OTA_INFO.rawValue)
//        data.append(seqNum); seqNum &+= 1
//        
//        let startAddress = dataProvider.startAddress
//        data.append(startAddress.littleEndian.data)
//        
//        let totalLen = dataProvider.getTotalLengthToBeSent()
//        data.append(totalLen.littleEndian.data)
//        
//        let headerSize: UInt8 = UInt8(data.count)
//        data.append(dataProvider.getStartData(headerSize: headerSize))
//        
//        return data
//    }
    
    public func cmdStartSendHeader(startAddress: UInt32, totalLengthToBeSent: UInt32) -> Data {
        var data = Data()
        
        // Data must be taken in strict order
        // startAddress/getTotalLengthToBeSent()/getStartData(:)
        
        data.append(OtaCommand.CMD_OTA_INFO.rawValue)
        data.append(seqNum); seqNum &+= 1
        data.append(startAddress.littleEndian.data)
        data.append(totalLengthToBeSent.littleEndian.data)
        
//        let headerSize: UInt8 = UInt8(data.count)
//        data.append(dataProvider.getStartData(headerSize: headerSize))
        
        return data
    }
    
//    public func cmdSendData() throws -> Data {
//        guard let dataProvider = dataProvider else {
//            throw OTAError.noDataAvailable
//        }
//        
//        var data = Data()
//        
//        data.append(OtaCommand.CMD_SEND_DATA.rawValue)
//        data.append(seqNum); seqNum &+= 1
//        
//        let headerSize: UInt8 = UInt8(data.count)
//        data.append(dataProvider.getDataToBeSent(headerSize: headerSize))
//        
//        return data
//    }
    
    public func cmdSendDataHeader() -> Data {
        var data = Data()
        
        data.append(OtaCommand.CMD_SEND_DATA.rawValue)
        data.append(seqNum); seqNum &+= 1
        
//        let headerSize: UInt8 = UInt8(data.count)
//        data.append(dataProvider.getDataToBeSent(headerSize: headerSize))
        
        return data
    }
}
