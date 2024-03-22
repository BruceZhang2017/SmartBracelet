//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  DeviceManager.swift
//  SmartBracelet
//
//  Created by ANKER on 2021/1/24.
//  Copyright © 2021 tjd. All rights reserved.
//
	

import Foundation

class DeviceManager: NSObject {
    static let shared = DeviceManager()
    public var devices: [BLEModel] = []
    public var deviceInfo: [String: DeviceModel] = [:]
    
    override init() {
        super.init()
        initializeDevices()
    }
    
    public func initializeDevices() {
        if Thread.current.isMainThread == true {
            devices = []
            if let models = try? BLEModel.er.all(), models.count > 0 {
                devices.append(contentsOf: models)
                print("数据库中的数据数量为: \(models.count)")
                return
            }
            print("数据库中的数据数量为: 0")
            return 
        }
        DispatchQueue.main.async {
            [weak self] in
            print("当前为主线程：\(Thread.current.isMainThread)")
            self?.devices = []
            if let models = try? BLEModel.er.all(), models.count > 0 {
                self?.devices.append(contentsOf: models)
                print("数据库中的数据数量为: \(models.count)")
                return
            }
            print("数据库中的数据数量为: 0")
        }
    }
}
