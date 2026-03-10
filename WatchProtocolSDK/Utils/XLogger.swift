//
//  XLogger.swift
//  SmartBracelet
//
//  Created by bruce on 2025/5/7.
//  Copyright © 2025 tjd. All rights reserved.
//

import Foundation

public class XLogger {
    public static let shared = XLogger() // 单例模式，方便全局调用
    private let logFileURL: URL
    private var fileHandle: FileHandle?
    private let lock = NSLock()  // 线程安全锁
    
    private init() {
        let documentsDirectory = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        logFileURL = documentsDirectory.appendingPathComponent("log.txt")

        do {
            // 删除旧日志文件（如果存在）
            try FileManager.default.removeItem(at: logFileURL)
        } catch let error as NSError where error.code == NSFileNoSuchFileError {
            // 文件不存在，无需处理
        } catch {
            print("删除日志文件时发生错误: \(error)")
        }

        do {
            // 创建新空文件
            try "".write(to: logFileURL, atomically: false, encoding: .utf8)
            
            // 打开FileHandle并设置为追加模式
            fileHandle = try FileHandle(forWritingTo: logFileURL)
            fileHandle?.seekToEndOfFile()
        } catch {
            print("无法初始化日志文件: \(error)")
        }
    }
    
    public func log(_ message: String) {
        // 1. 输出到控制台
        print(message)
        
        // 2. 写入日志文件（线程安全）
        lock.lock()
        defer { lock.unlock() }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let logMessage = "[\(dateFormatter.string(from: Date()))] \(message)"
        guard let data = "\(logMessage)\n".data(using: .utf8) else { return }
        
        do {
            // 确保文件句柄存在
            guard let handle = fileHandle else {
                // 如果FileHandle失效，重新打开
                try data.write(to: logFileURL, options: .atomic)
                return
            }
            
            handle.write(data)
        } catch {
            print("写入日志文件失败: \(error)")
        }
    }
}
