//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  UIColor+Extension.swift
//  TJDWristbandSDKDemo
//
//  Created by ANKER on 2020/7/27.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit

extension UIColor {
    static let k3ACF95 = UIColor.colorWithRGB(rgbValue: 0x3ACF95)
    static let k45DEB4 = UIColor.colorWithRGB(rgbValue: 0x45DEB4)
    static let k64F2B4 = UIColor.colorWithRGB(rgbValue: 0x64F2B4)
    static let kFF5E46 = UIColor.colorWithRGB(rgbValue: 0xFF5E46)
    static let kDDDDDD = UIColor.colorWithRGB(rgbValue: 0xDDDDDD)
    static let kAAAAAA = UIColor.colorWithRGB(rgbValue: 0xAAAAAA)
    static let k333333 = UIColor.colorWithRGB(rgbValue: 0x333333)
    static let k666666 = UIColor.colorWithRGB(rgbValue: 0x666666)
    static let k999999 = UIColor.colorWithRGB(rgbValue: 0x999999)
    static let kF5F5F5 = UIColor.colorWithRGB(rgbValue: 0xF5F5F5)
    static let kEEEEEE = UIColor.colorWithRGB(rgbValue: 0xEEEEEE)
    static let kFF3276 = UIColor.colorWithRGB(rgbValue: 0xFF3276)
    static let kFFB642 = UIColor.colorWithRGB(rgbValue: 0xFFB642)
    static let k88C9FA = UIColor.colorWithRGB(rgbValue: 0x88C9FA)
    static let k0095F5 = UIColor.colorWithRGB(rgbValue: 0x0095F5)
    static let k343434 = UIColor.colorWithRGB(rgbValue: 0x343434)
    static let k9A9A9A = UIColor.colorWithRGB(rgbValue: 0x9A9A9A)
    static let k08CCCC = UIColor.colorWithRGB(rgbValue: 0x08CCCC)
    static let kDEDEDE = UIColor.colorWithRGB(rgbValue: 0xDEDEDE)
    static let k373F4F = UIColor.colorWithRGB(rgbValue: 0x373F4F)
    static let k14C8C6 = UIColor.colorWithRGB(rgbValue: 0x14C8C6)
    static let kEA5959 = UIColor.colorWithRGB(rgbValue: 0xEA5959)
    static let kFFA87E = UIColor.colorWithRGB(rgbValue: 0xFFA87E)
    static let kCE96FF = UIColor.colorWithRGB(rgbValue: 0xCE96FF)
    static let k7A61FF = UIColor.colorWithRGB(rgbValue: 0x7A61FF)
    
    static func colorWithRGB(rgbValue: Int) -> UIColor {
        return UIColor(red: ((CGFloat)((rgbValue & 0xFF0000) >> 16)) / 255.0,
                       green: ((CGFloat)((rgbValue & 0xFF00) >> 8)) / 255.0,
                       blue: ((CGFloat)(rgbValue & 0xFF)) / 255.0,
                       alpha: 1.0)
    }
    
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
