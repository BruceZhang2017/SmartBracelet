//
//  OtaDataReader.swift
//  AB_FOTA
//
//  Created by Bluetrum on 2024/5/13.
//

import Foundation

final class OtaDataReader: DataReader {
    
    private let otaData: Data
    
    init(otaData: Data) {
        self.otaData = otaData
    }
    
    func open() throws {
        Logger.d(self, "open")
        // Do nothing
    }
    
    func getSize() throws -> Int {
        Logger.d(self, "getSize: \(otaData.count)")
        return otaData.count
    }
    
    func getHash() throws -> Data {
        Logger.d(self, "getHash")
        return otaData.md5()[0..<4]
    }
    
    func read(srcPos: Int, length: Int) throws -> Data? {
        Logger.d(self, "read: srcPos=\(srcPos), length=\(length)")
        return otaData[srcPos..<srcPos+length]
    }
    
    func close() throws {
        Logger.d(self, "close")
        // Do nothing
    }
}
