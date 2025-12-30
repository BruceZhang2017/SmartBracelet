//
//  WatchFaceSDK.swift
//  WatchFaceSDK
//
//  Created by ANKER on 2025/12/30.
//

import Foundation

/// WatchFaceSDK 版本信息
public struct WatchFaceSDKInfo {
    public static let version = "1.0.0"
    public static let buildDate = "2025-12-30"
    public static let protocolType = "XGZT"

    public static var description: String {
        return "WatchFaceSDK v\(version) (\(protocolType)) - Build \(buildDate)"
    }
}

/// SDK 初始化配置
public struct WatchFaceSDKConfiguration {
    /// 是否启用详细日志
    public var enableVerboseLogging: Bool = false

    /// 最大文件大小限制（字节），默认 120KB
    public var maxFileSize: Int = 120 * 1024

    /// 传输超时时间（秒），默认 60 秒
    public var transferTimeout: TimeInterval = 60.0

    public init() {}
}

/// SDK 全局配置管理器
public class WatchFaceSDKConfig {

    /// 全局配置
    public static var configuration = WatchFaceSDKConfiguration()

    /// 打印SDK信息
    public static func printSDKInfo() {
        print("=" * 50)
        print(WatchFaceSDKInfo.description)
        print("=" * 50)
    }
}

/// 字符串重复操作符
private func * (left: String, right: Int) -> String {
    return String(repeating: left, count: right)
}
