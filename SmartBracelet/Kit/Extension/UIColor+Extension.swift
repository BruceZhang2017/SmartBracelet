//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  UIColor+Extension.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/7/27.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit

extension UIColor {
    
    convenience init(hex: UInt32, alpha: CGFloat = 1.0) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255.0
        let green = CGFloat((hex >> 8) & 0xFF) / 255.0
        let blue = CGFloat(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    static let k3ACF95 = UIColor(hex: 0x3ACF95)
    static let k45DEB4 = UIColor(hex: 0x45DEB4)
    static let k64F2B4 = UIColor(hex: 0x64F2B4)
    static let kFF5E46 = UIColor(hex: 0xFF5E46)
    static let kDDDDDD = UIColor(hex: 0xDDDDDD)
    static let kAAAAAA = UIColor(hex: 0xAAAAAA)
    static let k333333 = UIColor(hex: 0x333333)
    static let k666666 = UIColor(hex: 0x666666)
    static let k999999 = UIColor(hex: 0x999999)
    static let kF5F5F5 = UIColor(hex: 0xF5F5F5)
    static let kEEEEEE = UIColor(hex: 0xEEEEEE)
    static let kFF3276 = UIColor(hex: 0xFF3276)
    static let kFFB642 = UIColor(hex: 0xFFB642)
    static let k88C9FA = UIColor(hex: 0x88C9FA)
    static let k0095F5 = UIColor(hex: 0x0095F5)
    static let k343434 = UIColor(hex: 0x343434)
    static let k9A9A9A = UIColor(hex: 0x9A9A9A)
    static let k08CCCC = UIColor(hex: 0x08CCCC)
    static let kDEDEDE = UIColor(hex: 0xDEDEDE)
    static let k373F4F = UIColor(hex: 0x373F4F)
    static let k14C8C6 = UIColor(hex: 0x14C8C6)
    static let kEA5959 = UIColor(hex: 0xEA5959)
    static let kFFA87E = UIColor(hex: 0xFFA87E)
    static let kCE96FF = UIColor(hex: 0xCE96FF)
    static let k7A61FF = UIColor(hex: 0x7A61FF)

    
    static let brand = UIColor(hex: 0x0C77F8)
    static let text_primary = UIColor(hex: 0x050A10)
    static let text_secondary = UIColor(hex: 0x49525E)
    static let text_third = UIColor(hex: 0x050A10, alpha: 0.48)
    static let fill = UIColor(hex: 0x0C77F8, alpha: 0.12)
    
    static func image(color: UIColor, viewSize: CGSize) -> UIImage {
        let rect: CGRect = CGRect(x: 0, y: 0, width: viewSize.width, height: viewSize.height)
        UIGraphicsBeginImageContext(rect.size)
        let context: CGContext = UIGraphicsGetCurrentContext()!
        context.setFillColor(color.cgColor)
        context.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsGetCurrentContext()
        return image!
    }
}
