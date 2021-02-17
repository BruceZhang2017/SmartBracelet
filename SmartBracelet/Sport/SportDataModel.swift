//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  SportDataModel.swift
//  SmartBracelet
//
//  Created by ANKER on 2021/2/16.
//  Copyright © 2021 tjd. All rights reserved.
//
	

import UIKit
import RealmSwift

final class SportDataModel: Object {
    @objc dynamic var timeStamp = 0
    @objc dynamic var cal = 0
    @objc dynamic var avgSpeed: Float = 0
    @objc dynamic var maxSpeed: Float = 0
    @objc dynamic var distance: Float = 0
    @objc dynamic var duration: Float = 0
    @objc dynamic var locations: String = "" // 位置信息
}
