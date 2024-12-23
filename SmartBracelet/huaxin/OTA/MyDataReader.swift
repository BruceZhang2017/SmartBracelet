//
//  MyDataReader.swift
//  AB_OTA Demo
//
//  Created by Bluetrum on 2024/5/13.
//

import Foundation
import CommonCrypto
import CryptoKit

/// 自定义[DataReader]。
/// Size和Hash可只获取一次，保存到变量，避免重复获取。以下仅做示例，所以每次均获取。
class MyDataReader: DataReader {
    
    private let filePath: String
    private var fileHandle: FileHandle?
    
    init(filePath: String) {
        self.filePath = filePath
    }
    
    public func open() throws {
        Logger.d(self, "open")
        fileHandle = FileHandle(forReadingAtPath: filePath)
    }
    
    public func getSize() throws -> Int {
        Logger.d(self, "getSize")
        guard let fileHandle else { return 0 }
        
        let offset = try fileHandle.fileOffset()
        try fileHandle.seek(to: 0)
        
        let fileSize = try fileHandle.seekToFileEnd()
        Logger.d(self, "fileSize: \(fileSize)")
        
        try fileHandle.seek(to: offset)
        
        return Int(fileSize)
    }
    
    public func getHash() throws -> Data {
        Logger.d(self, "getHash")
        guard let fileHandle else {
            return Data(repeating: 0xFF, count: 4)
        }
        
        // 分段计算MD5
        let STEP = 1024
        
        let offset = try fileHandle.fileOffset()
        try fileHandle.seek(to: 0)
        
        let hash = if #available(iOS 13.0, *) {
            try {
                var hasher = Insecure.MD5()
                while let chunkData = try fileHandle.read(count: STEP) {
                    hasher.update(data: chunkData)
                }
                let digest = hasher.finalize()
                let md5Data = Data(digest)
                return md5Data[0..<4]
            }()
        } else {
            try {
                var context = CC_MD5_CTX()
                CC_MD5_Init(&context)
                while let chunkData = try fileHandle.read(count: STEP) {
                    chunkData.withUnsafeBytes { bufferPointer in
                        if let baseAddress = bufferPointer.baseAddress {
                            CC_MD5_Update(&context, baseAddress, CC_LONG(bufferPointer.count))
                        }
                    }
                }
                var digest = Data(count: Int(CC_MD5_DIGEST_LENGTH))
                digest.withUnsafeMutableBytes { digestBuffer in
                    if let baseAddress = digestBuffer.baseAddress {
                        CC_MD5_Final(baseAddress, &context)
                    }
                }
                return digest[0..<4]
            }()
        }
        
        try fileHandle.seek(to: offset)
        
        return hash
    }
    
    public func read(srcPos: Int, length: Int) throws -> Data? {
        Logger.d(self, "read: srcPos=\(srcPos), length=\(length)")
        guard let fileHandle else { return nil }
        
        let offset = try fileHandle.fileOffset()
        try fileHandle.seek(to: UInt64(srcPos))
        let data = try fileHandle.read(count: length)
        try fileHandle.seek(to: offset)
        return data
    }
    
    public func close() throws {
        Logger.d(self, "close")
        
        if #available(iOS 13.0, *) {
            try fileHandle?.close()
        } else {
            fileHandle?.closeFile()
        }
    }
}

extension FileHandle {
    
    func fileOffset() throws -> UInt64 {
        return if #available(iOS 13.4, *) {
            try offset()
        } else {
            offsetInFile
        }
    }
    
    func seek(to offset: UInt64) throws {
        if #available(iOS 13.0, *) {
            try seek(toOffset: offset)
        } else {
            seek(toFileOffset: offset)
        }
    }
    
    @discardableResult
    public func seekToFileEnd() throws -> UInt64 {
        return if #available(iOS 13.4, *) {
            try seekToEnd()
        } else {
            seekToEndOfFile()
        }
    }
    
    func read(count: Int) throws -> Data? {
        return if #available(iOS 13.4, *) {
            try read(upToCount: count)
        } else {
            readData(ofLength: count)
        }
    }
}
