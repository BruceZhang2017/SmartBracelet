//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  UIDevice+Extension.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/7/28.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit

let ScreenWidth = UIScreen.main.bounds.size.width
let ScreenHeight = UIScreen.main.bounds.size.height

extension UIDevice {
    // 判断手机是否IPONEX类型
    static func isSameToIphoneX() -> Bool {
        if #available(iOS 11.0, *) {
            if let window = UIApplication.shared.delegate?.window {
                if (window?.safeAreaInsets.bottom ?? 0) > 0 {
                    return true
                }
            }
        }
        return false
    }
}
