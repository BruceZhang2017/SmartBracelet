//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  DHeartRateModel.swift
//  SmartBracelet
//
//  Created by ANKER on 2021/2/18.
//  Copyright © 2021 tjd. All rights reserved.
//
	

import UIKit
import RealmSwift

final class DHeartRateModel: Object {
    /// 苹果系统里设备的唯一标识符
    @objc dynamic var uuidString: String = ""
    
    @objc dynamic var mac: String = ""
    
    @objc dynamic var heartRate: Int = 0
    
    @objc dynamic var timeStamp: Int = 0
    
    override static func primaryKey() -> String? {
      return "timeStamp"
    }
}
