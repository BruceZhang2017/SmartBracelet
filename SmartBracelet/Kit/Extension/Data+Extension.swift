//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  Data+Extension.swift
//  SmartBracelet
//
//  Created by ANKER on 2021/1/19.
//  Copyright © 2021 tjd. All rights reserved.
//
	

import Foundation

extension Data {
    func hexEncodedStringNoBlank() -> String {
        return map { String(format: "%02hhx", $0) }.joined().uppercased()
    }
    
    func hexEncodedStringBlank() -> String {
        return map { String(format: "%02hhx ", $0) }.joined().uppercased()
    }
    
    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined(separator: ":").uppercased()
    }
}
