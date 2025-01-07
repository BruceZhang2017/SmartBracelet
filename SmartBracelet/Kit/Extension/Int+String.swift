//
//  Int+DateStr.swift
//  LifeFit
//
//  Created by WuJunjie on 2018/11/18.
//  Copyright © 2018年 WuJunjie. All rights reserved.
//

import Foundation
import UIKit


extension Numeric {
    func hexString() -> String {
        return String.init(format: "%02x", self as! CVarArg)
    }
}

extension Int {
    func stringHmsFromSecond() -> String {
        let hour = self/3600
        let minute = self%3600/60
        let second = self%3600%60
        return String.init(format: "%02d:%02d:%02d", hour, minute, second)
    }
    
    func stringHmFromSecond() -> String {
        let hour = self/3600
        let minute = self%3600/60
        return String.init(format: "%02d:%02d", hour, minute)
    }
    
    func stringMsFromSecond() -> String {
        let minute = self/60
        let second = self%60
        return String.init(format: "%02d:%02d", minute, second)
    }
    
    func stringSpeedFromSecond() -> String {
        let minute = self/60
        let second = self%60
        return String.init(format: "%02d'%02d''", minute, second)
    }
    
    func dateFromSecond() -> Date {
        let date = Date.init(timeIntervalSince1970: TimeInterval(self))
        return date
    }
    
    func colorFromRGB() -> UIColor {
        let r = (self >> 16) & 0xff
        let g = (self >> 8) & 0xff
        let b = (self >> 0) & 0xff
        let temp = UIColor.init(red: CGFloat(r)/0xff, green: CGFloat(g)/0xff, blue: CGFloat(b)/0xff, alpha: 1)
        return temp
    }
    
    func colorFromRGBA() -> UIColor {
        let r = (self >> 24) & 0xff
        let g = (self >> 16) & 0xff
        let b = (self >> 8) & 0xff
        let a = (self >> 0) & 0xff
        let temp = UIColor.init(red: CGFloat(r)/0xff, green: CGFloat(g)/0xff, blue: CGFloat(b)/0xff, alpha: CGFloat(a)/0xff)
        return temp
    }
}
