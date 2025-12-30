//
//  DataExtensions.swift
//  WatchProtocolSDK
//
//  Created on 2025-12-27.
//  Copyright © 2025 huaxin. All rights reserved.
//

import Foundation

// MARK: - Data Extension for Hex Conversion
public extension Data {
    /// 将 Data 转换为十六进制字符串
    /// 例如: Data([0x01, 0x02, 0xFF]) -> "0102FF"
    var hex: String {
        return map { String(format: "%02X", $0) }.joined()
    }

    /// 将 Data 转换为十六进制字符串（带分隔符）
    /// 例如: Data([0x01, 0x02, 0xFF]) -> "01:02:FF"
    func hexEncodedString(separator: String = ":") -> String {
        return map { String(format: "%02X", $0) }.joined(separator: separator)
    }

    /// 将 Data 转换为字节数组
    var bytes: [UInt8] {
        return [UInt8](self)
    }
}
