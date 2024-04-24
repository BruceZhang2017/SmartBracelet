//
//  UIColor+Extension.swift
//  SmartBracelet
//
//  Created by anker on 2024/4/7.
//  Copyright © 2024 tjd. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1.0) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255.0
        let green = CGFloat((hex >> 8) & 0xFF) / 255.0
        let blue = CGFloat(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    static let brand = UIColor(hex: 0x0C77F8)
}
