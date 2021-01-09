//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  DeviceModel.swift
//  TJDWristbandSDKDemo
//
//  Created by ANKER on 2020/10/8.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit

class DeviceModel: NSObject {
    var userId = 0 // 用户ID
    var id = 0 // 设备 ID
    var alarms: [AlarmModel]?
    var type: String?
    var icon: String?
    var name: String?
    var mac: String?
    var version: String?
    var sn: String?
    var battery: Int = 0
    var btState: Int = 0
    var weixin: Bool = false
    var qq: Bool = false
    var linkedin: Bool = false
    var facebook: Bool = false
    var whatsapp: Bool = false
    var twitter: Bool = false 
    var callReminder: Bool = false // 来电提醒
    var upScreenLight: Bool = false // 抬手亮屏
    var sitReminder: Bool = false // 久坐提醒
}
