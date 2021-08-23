//
//  BLEDeviceNameHandler.swift
//  SmartBracelet
//
//  Created by anker on 2021/8/22.
//  Copyright © 2021 tjd. All rights reserved.
//

import Foundation

class BLEDeviceNameHandler {
    func handleName() -> Int { // 1.方型 2.圆形
        let name = bleSelf.bleModel.name
        if name.count > 0 {
            if name == "M3" {
                return 1
            }
            if name == "M4" {
                return 1
            }
            if name == "M5" {
                return 1
            }
            if name == "M6" {
                return 1
            }
            if name == "B28" {
                return 1
            }
            if name == "B33" {
                return 1
            }
            if name == "B35" {
                return 1
            }
            if name == "B37" {
                return 1
            }
            if name == "B38" {
                return 1
            }
            if name == "TB1" {
                return 1
            }
            if name == "TB1S" {
                return 1
            }
            if name == "TB1S-T" {
                return 1
            }
            if name == "TB3" {
                return 1
            }
            if name == "TB3S" {
                return 1
            }
            if name == "TB3S-T" {
                return 1
            }
            if name == "TB12" {
                return 2
            }
            if name == "TB15" {
                return 2
            }
            if name == "TB8B" {
                return 2
            }
            if name == "TB14B" {
                return 2
            }
            if name == "TB7B" {
                return 2
            }
            if name == "TB19B" {
                return 2
            }
            if name == "TB20B" {
                return 2
            }
        }
        
        
        return 0
    }
}
