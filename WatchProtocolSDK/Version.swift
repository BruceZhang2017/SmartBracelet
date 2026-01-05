//
//  Version.swift
//  WatchProtocolSDK
//
//  Created on 2026/01/03.
//  Copyright © 2025 tjd. All rights reserved.
//

import Foundation

/// WatchProtocolSDK 版本信息
public struct WatchProtocolSDKVersion {
    /// SDK 版本号
    public static let version = "1.0.1"

    /// SDK 名称
    public static let name = "WatchProtocolSDK"

    /// 完整版本信息
    public static var fullVersion: String {
        return "\(name) v\(version)"
    }

    /// 构建日期
    public static let buildDate = "2026-01-03"
}
