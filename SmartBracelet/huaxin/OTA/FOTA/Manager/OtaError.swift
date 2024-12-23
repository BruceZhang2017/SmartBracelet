//
//  OtaError.swift
//  AB OTA Demo
//
//  Created by Bluetrum on 2020/12/25.
//

import Foundation

/// 升级过程中的错误，`OtaManagerDelegate`代理方法`onError`中使用
public enum OTAError: Error {
    
    /// 设备拒绝升级
    case refusedByDevice
    /// 没有FOTA数据可用
    case noDataAvailable
    
    /// 设备报告错误，含错误代码
    case deviceReport(code: UInt8)
    
    /// 等待设备回复超时
    case timeoutWaitingResponse
    
    /// 升级中TWS断开
    case twsDisconnected
    
    /// DataReader错误
    case dataReaderError
}

extension OTAError: LocalizedError {
    
    /// 错误描述
    public var errorDescription: String? {
        switch self {
        case .refusedByDevice: return NSLocalizedString("Refused by device", comment: "")
        case .noDataAvailable: return NSLocalizedString("No OTA data available", comment: "")
        case .deviceReport(let code): return NSLocalizedString("Device report an error, code = \(code)", comment: "")
        case .timeoutWaitingResponse: return NSLocalizedString("Waiting response timeout", comment: "")
        case .twsDisconnected: return NSLocalizedString("TWS disconnected", comment: "")
        case .dataReaderError: return NSLocalizedString("DataReader error", comment: "")
        }
    }
    
}
