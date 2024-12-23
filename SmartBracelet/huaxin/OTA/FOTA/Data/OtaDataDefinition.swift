//
//  OtaDataDefinition.swift
//  AB OTA Demo
//
//  Created by Bluetrum on 2020/12/29.
//

import Foundation

enum OtaCommand: UInt8 {
    case CMD_OTA_INFO       = 0xA0
    case CMD_SEND_DATA      = 0x20
    case CMD_GET_INFO       = 0x91
    case CMD_NOTIFY_STATUS  = 0x90
    case CMD_GET_INFO_TLV   = 0x92
}

enum OtaState: UInt8 {
    case STATE_OK               = 0x00
    case STATE_TWS_DISCONNECTED = 0x80
    case STATE_DONE             = 0xFF
    case STATE_PAUSE            = 0xFD
    case STATE_CONTINUE         = 0xFE
}

enum OtaGetInfoType: UInt8 {
    case CMD_GET_INFO_TYPE_VERSION      = 0x01
    case CMD_GET_INFO_TYPE_UPDATE       = 0x02
    case CMD_GET_INFO_TYPE_CAPABILITIES = 0x03
    case CMD_GET_INFO_TYPE_STATUS       = 0x04
    case CMD_GET_INFO_TYPE_CHANNEL      = 0x06
}

let DEVICE_ALLOW_UPDATE: UInt8 = 0x01

// MARK: - OTA Device Capabilities

enum OtaInfoCapabilities: UInt16 {
    case tws = 0x0001
}

extension UInt16 {
    
    var isTwsDevice: Bool {
        return (self & OtaInfoCapabilities.tws.rawValue) != 0
    }
    
}

// MARK: - OTA Device status

enum OtaDeviceStatus: UInt16 {
    case twsConnected = 0x0001
}

extension UInt16 {
    
    var isTwsConnected: Bool {
        return (self & OtaDeviceStatus.twsConnected.rawValue) != 0
    }
    
}

// MARK: - Channel

enum OtaInfoChannel: UInt8 {
    case left   = 0x01
    case right  = 0x00
}

extension UInt8 {
    
    var isLeftChannel: Bool {
        return (self & OtaInfoChannel.left.rawValue) != 0
    }
    
    var isRightChannel: Bool {
        return (self & OtaInfoChannel.right.rawValue) != 0
    }
    
}
