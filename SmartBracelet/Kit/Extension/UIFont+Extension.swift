//
//  UIFont+Extension.swift
//  SmartBracelet
//
//  Created by bruce on 2024/4/7.
//  Copyright © 2024 tjd. All rights reserved.
//

import UIKit

extension UIFont {
    
    static func title() -> UIFont {
        return UIFont.systemFont(ofSize: 18, weight: .bold)
    }
    
    static func body() -> UIFont {
        return UIFont.systemFont(ofSize: 16, weight: .medium)
    }
    
    static func body1() -> UIFont {
        return UIFont.systemFont(ofSize: 14, weight: .medium)
    }
    
    static func body2() -> UIFont {
        return UIFont.systemFont(ofSize: 12, weight: .medium)
    }
    
    static func subtitle1() -> UIFont {
        return UIFont.systemFont(ofSize: 14, weight: .black)
    }
    
    static func subtitle() -> UIFont {
        return UIFont.systemFont(ofSize: 16, weight: .bold)
    }
    
    static func bigtitle() -> UIFont {
        return UIFont.systemFont(ofSize: 24, weight: .black)
    }
    
    static func bigbigtitle() -> UIFont {
        return UIFont.systemFont(ofSize: 250, weight: .black)
    }
}
