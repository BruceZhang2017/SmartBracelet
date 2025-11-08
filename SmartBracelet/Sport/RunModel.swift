//
//  RunModel.swift
//  LifeDog
//
//  Created by oce888 on 2017/7/27.
//  Copyright © 2017年 oce888. All rights reserved.
//

import UIKit
import JRDB

@objcMembers
class RunPoint: NSObject {
    var pathId = 0
    var latitude: Double = 0
    var longitude: Double = 0
    var speed: Double = 0
    var altitude: Double = 0
}

@objcMembers
class RunModel: NSObject {
    var timeStamp: Int = 0 {
        didSet {
            let date = timeStamp.dateFromSecond()
            dateStr = date.stringFromYmdHms()
        }
    }
    var type: Int = 0
    var dateStr: String = ""
    var duration: Int = 0
    var distance: Double = 0
    var pathCount = 0
    var cal: Double = 0
    var pointArray = [RunPoint]()
    
    override static func jr_oneToManyLinkedPropertyNames() -> [String : JRPersistent.Type]? {
        return ["pointArray": RunPoint.self]
    }
}



