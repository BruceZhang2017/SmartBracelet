//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  DAlarmModel.swift
//  SmartBracelet
//
//  Created by ANKER on 2021/2/19.
//  Copyright © 2021 tjd. All rights reserved.
//
	

import UIKit
import RealmSwift

final class DAlarmModel : Object {

    ///闹钟id 0...4 总共五组闹钟
    ///Alarm id 0...4 A total of five alarm clocks
    @objc dynamic var clockId: Int = 0

    ///闹钟开关状态
    ///Alarm switch status
    @objc dynamic var isOn: Bool = false

    /// 2的 0，1，2，3，4，5，6，分别代表天数 累计的和表示有哪几天, 0表示星期天
    /// 2 0,1,2,3,4,5,6, respectively, represent the number of days. The cumulative sum indicates which days, 0 means Sunday.
    @objc dynamic var weekday: Int = 0

    /// 闹钟触发的时间的小时值  0...23
    /// The hour value of the alarm trigger time 0...23
    @objc dynamic var hour: Int = 0

    /// 闹钟触发的时间的分钟值  0...59
    /// The minute value of the time the alarm is triggered 0...59
    @objc dynamic var minute: Int = 0
}
