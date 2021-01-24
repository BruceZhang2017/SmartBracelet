//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  BLEModel.swift
//  SmartBracelet
//
//  Created by ANKER on 2021/1/19.
//  Copyright © 2021 tjd. All rights reserved.
//
	

import Foundation
import RealmSwift

final class BLEModel: Object {
    /// 增加是否绑定字段，方便开发者自行设置绑定，自行连接使用
    @objc dynamic var isBond: Bool = false

    /// 苹果系统里设备的唯一标识符
    @objc dynamic var uuidString: String = ""

    /// 设备名
    @objc dynamic var name: String = ""

    /// 广播名
    @objc dynamic var localName: String = ""

    /// 搜索的设备广播强度，可用来大致判断距离
    @objc dynamic var rssi: Int = 0

    /// 设备mac地址
    @objc dynamic var mac: String = ""

    /// 硬件版本
    @objc dynamic var hardwareVersion: String = ""

    /// 固件版本
    @objc dynamic var firmwareVersion: String = ""

    /// 厂商数据 ascii字符串，用于产商识别
    @objc dynamic var vendorNumberASCII: String = ""

    /// 厂商数据 16进制字符串，用于本公司固件升级服务器请求使用
    @objc dynamic var vendorNumberString: String = ""

    /// 内部型号
    @objc dynamic var internalNumber: String = ""

    /// ascii转出的string
    @objc dynamic var internalNumberString: String = ""
    
    @objc dynamic var imageName: String = "" // 设备图片
    
    override static func primaryKey() -> String? {
      return "mac"
    }

}
