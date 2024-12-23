//
//  OtaDataProvider.swift
//  AB OTA Demo
//
//  Created by Bluetrum on 2020/12/24.
//

import Foundation

class OtaDataProvider {
    
    private let dataReader: DataReader
    private var dataSize: Int = 0
    public var isCompressedData: Bool = false
    
    public var blockSize: UInt32        = OtaConstants.UNDEFINED_BLOCK_SIZE
    public var packetSize: UInt16       = OtaConstants.DEFAULT_MTU_SIZE - 3

    private var blockOffset: UInt32     = 0
    private var fileOffset: UInt32      = 0
    
    public var startAddress: UInt32 {
        get {
            return self.fileOffset
        }
        set(address) {
            self.fileOffset = address
        }
    }
    
    public var progress: UInt32 { fileOffset * 100 / UInt32(getDataSize()) }

    
    public init(dataReader: DataReader) {
        self.dataReader = dataReader
    }
    
    public func open() throws {
        try dataReader.open()
        try dataSize = dataReader.getSize()
        try isCompressedData = checkIfCompressedData()
    }
    
    public func close() throws {
        self.fileOffset = 0
        self.blockOffset = 0
        self.packetSize = OtaConstants.DEFAULT_MTU_SIZE - 3
        self.blockSize = OtaConstants.UNDEFINED_BLOCK_SIZE
        try dataReader.close()
    }
    
    private func getDataSize() -> Int {
        return dataSize
    }
    
    public func getHash() throws -> Data {
        return try dataReader.getHash()
    }
    
    public func isBlockSendFinish() -> Bool {
        if blockSize == OtaConstants.UNDEFINED_BLOCK_SIZE {
            return isAllDataSent()
        } else {
            return (fileOffset - blockOffset == blockSize) || isAllDataSent()
        }
    }
    
    public func isAllDataSent() -> Bool {
        return fileOffset == getDataSize()
    }
    
    /* Command */
    
    public func getTotalLengthToBeSent() -> UInt32 {
        // data length
        var sendLen: UInt32
        
        // if no need to split
        if blockSize == OtaConstants.UNDEFINED_BLOCK_SIZE {
            sendLen = UInt32(getDataSize()) - fileOffset
        }
        // need splitting
        else {
            // left data length to be sent
            let leftLen = UInt32(getDataSize()) - fileOffset
            sendLen = min(leftLen, blockSize)
            blockOffset = fileOffset
        }
        
        return sendLen
    }
    
    public func getStartData(headerSize: UInt8) throws -> Data {
        let fileSize = UInt32(getDataSize())

        // Limit the length to send
        var dataLen = (blockSize == OtaConstants.UNDEFINED_BLOCK_SIZE) ? fileSize : blockSize
        dataLen = min(dataLen, UInt32(packetSize) - UInt32(headerSize))
        // Check if overlap file
        if fileOffset + dataLen > getDataSize() {
            dataLen = fileSize - fileOffset
        }
        
        guard let data = try dataReader.read(srcPos: Int(fileOffset), length: Int(dataLen)) else {
            // 因为长度都是经过计算的，如果读取返回-1，那说明读取失败，抛出异常
            throw OTAError.dataReaderError
        }
        
        fileOffset += UInt32(data.count)
        return data
    }
    
    public func getDataToBeSent(headerSize: UInt8) throws -> Data {
        let fileSize = UInt32(getDataSize())

        // Limit the length to send
        var dataLen = (blockSize == OtaConstants.UNDEFINED_BLOCK_SIZE) ? fileSize : blockSize
        dataLen = min(dataLen, UInt32(packetSize) - UInt32(headerSize))
        
        // Need splitting
        if blockSize != OtaConstants.UNDEFINED_BLOCK_SIZE {
            // Check if overlap block
            if (fileOffset - blockOffset) + dataLen > blockSize {
                dataLen = blockSize - (fileOffset - blockOffset)
            }
        }
        // Check if overlap file
        if fileOffset + dataLen > fileSize {
            dataLen = fileSize - fileOffset
        }
        
        guard let data = try dataReader.read(srcPos: Int(fileOffset), length: Int(dataLen)) else {
            // 因为长度都是经过计算的，如果读取返回-1，那说明读取失败，抛出异常
            throw OTAError.dataReaderError
        }
        
        fileOffset += UInt32(data.count)
        return data
    }
}

extension OtaDataProvider {
    
    func checkIfCompressedData() throws -> Bool {
        guard let header = try dataReader.read(srcPos: 0, length: 4) else {
            return false
        }
        return checkHeaderIfCompressedData(header)
    }
    
    func checkHeaderIfCompressedData(_ header: Data) -> Bool {
        return if (header.count >= 3) {
            // POT
            header.starts(with: "POT".data(using: .ascii)!)
        } else {
            false
        }
    }
}
