//
//  DataReader.swift
//  AB_FOTA
//
//  Created by Bluetrum on 2024/5/13.
//

import Foundation

public protocol DataReader {
    
    /// 打开文件
    func open() throws
    
    /// 获取文件的总大小
    /// - Returns: 文件的总大小
    func getSize() throws -> Int
    
    /// 获取文件的MD5头4个字节
    /// - Returns: 文件的MD5头4个字节
    func getHash() throws -> Data
    
    /// 读取数据
    /// - Parameters:
    ///   - srcPos: 源偏移量
    ///   - length: 读取大小
    /// - Returns: 返回的数据，失败则为nil
    func read(srcPos: Int, length: Int) throws -> Data?
    
    /// 关闭文件
    func close() throws
}
