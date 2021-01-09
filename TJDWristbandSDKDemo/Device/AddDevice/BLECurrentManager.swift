//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  BLECurrentManager.swift
//  TJDWristbandSDKDemo
//
//  Created by ANKER on 2020/11/1.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit
import CoreBluetooth

class BLECurrentManager: NSObject {
    static let sharedInstall = BLECurrentManager() // 单例
    var manager: CBCentralManager!
    var per: CBPeripheral!
    
    override init() {
        super.init()
        if #available(iOS 13.0, *) {
            manager = CBCentralManager(delegate: self, queue: DispatchQueue(label: "WristBand"), options: [CBConnectPeripheralOptionRequiresANCS: true])
        } else {
            manager = CBCentralManager(delegate: self, queue: DispatchQueue(label: "WristBand"))
        }
    }
    
    public func tryConnectedPer() {
        let cmdUUID = CBUUID(string: "")
        let perList = manager.retrieveConnectedPeripherals(withServices: [cmdUUID])
        if perList.count > 0 {
            per = perList[0]
        }
    }
}

extension BLECurrentManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
    }
    
    
}
