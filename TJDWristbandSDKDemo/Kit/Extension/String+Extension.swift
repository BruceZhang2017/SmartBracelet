//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  String+Extension.swift
//  TJDWristbandSDKDemo
//
//  Created by ANKER on 2020/7/27.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import Foundation

extension String {
    static let kCellIdentifier = "Cell"
    static let kShowHealthDetail = "ShowHealthDetail"
    static let kSetTargetViewController = "SetTargetViewController"
    static let kSetTargetBViewController = "SetTargetBViewController"
    static let kSetTarget = "设定目标"
    
    /// Storyboard
    static let kSport = "Sport"
}

extension String {
    ///最少有一个大写和小写字母；最少有一个数字；最少八个字符
    func isPassWord() -> Bool {
        let regex = "^(?=.*\\d)(?=.*[a-z])(?=.*[A-Z])[a-zA-Z0-9]{8,}$"
        let allRegex : NSPredicate = NSPredicate(format: "SELF MATCHES %@", regex)
        if allRegex.evaluate(with: self) {
            return true
        }
        return false
    }
    
    func validateEmail() -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
        let emailTest: NSPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailTest.evaluate(with: self)
    }
}
