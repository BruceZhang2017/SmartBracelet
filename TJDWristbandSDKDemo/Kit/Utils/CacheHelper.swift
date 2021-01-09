//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  CacheHelper.swift
//  TJDWristbandSDKDemo
//
//  Created by ANKER on 2020/11/11.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import Foundation

class CacheHelper: NSObject {
    public func getCacheBool(name: String) -> Bool {
        return UserDefaults.standard.bool(forKey: name) 
    }
    
    public func setCacheBool(name: String, value: Bool) {
        UserDefaults.standard.set(value, forKey: name)
        UserDefaults.standard.synchronize()
    }
}
