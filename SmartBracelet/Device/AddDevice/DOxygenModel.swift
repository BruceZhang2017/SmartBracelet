//
//  DOxygenModel.swift
//  SmartBracelet
//
//  Created by anker on 2021/6/19.
//  Copyright © 2021 tjd. All rights reserved.
//

import UIKit
import RealmSwift

class DOxygenModel: Object {
    /// 苹果系统里设备的唯一标识符
    @objc dynamic var uuidString: String = ""
    
    @objc dynamic var mac: String = ""
    
    @objc dynamic var oxygen: Int = 0
    
    @objc dynamic var timeStamp: Int = 0
    
    override static func primaryKey() -> String? {
      return "timeStamp"
    }
}
