//
//  Double+String.swift
//  LifeFit
//
//  Created by WuJunjie on 2018/11/18.
//  Copyright © 2018年 WuJunjie. All rights reserved.
//

import Foundation

//1 mi = 1 km * 1.609344
let kDistanceConversion = 1/1.609344
// 1 ft = 1 cm * 30.48
// 1 ft = 1 inch * 12
let kHeightConversion = 1/30.48
// pound = 1 kg * 1/2.20462
let kWeightConversion = 2.20462
// 体重和距离求卡路里
let KCalConversion = 0.8214

extension Double {
    func stringCeil(_ floatCount:Int) -> String {
        let numFormatter = NumberFormatter()
//        numFormatter.locale = Locale.init(identifier: "zh_CN")
        numFormatter.minimumIntegerDigits = 1
        numFormatter.minimumFractionDigits = floatCount
        numFormatter.maximumFractionDigits = floatCount
        numFormatter.roundingMode = .ceiling
        return numFormatter.string(from: NSNumber.init(value: self))!
    }
    
    func stringFloor(_ floatCount:Int) -> String {
        let numFormatter = NumberFormatter()
//        numFormatter.locale = Locale.init(identifier: "zh_CN")
        numFormatter.minimumIntegerDigits = 1
        numFormatter.minimumFractionDigits = floatCount
        numFormatter.maximumFractionDigits = floatCount
        numFormatter.roundingMode = .floor
        return numFormatter.string(from: NSNumber.init(value: self))!
    }
    
    func stringRound(_ floatCount:Int) -> String {
        //左边一位是偶数舍弃，左边一位是奇数加一 halfEven
        // 四舍五入halfup
        let numFormatter = NumberFormatter()
        numFormatter.minimumIntegerDigits = 1
        numFormatter.minimumFractionDigits = floatCount
        numFormatter.maximumFractionDigits = floatCount
        numFormatter.roundingMode = .halfUp
        return numFormatter.string(from: NSNumber.init(value: self))!
    }
    
    func stringSystomRound(_ floatCount:Int) -> String {
        //左边一位是偶数舍弃，左边一位是奇数加一 halfEven
        let numFormatter = NumberFormatter()
//        numFormatter.locale = Locale.init(identifier: "zh_CN")
        numFormatter.minimumIntegerDigits = 1
        numFormatter.minimumFractionDigits = floatCount
        numFormatter.maximumFractionDigits = floatCount
        numFormatter.roundingMode = .halfEven
        return numFormatter.string(from: NSNumber.init(value: self))!
    }
    
    func kmToMi() -> Double {
        return self * kDistanceConversion
    }
    
    func miToKm() -> Double {
        return self / kDistanceConversion
    }
    
    func cmToFt() -> Double {
        return self * kHeightConversion
    }
    
    func ftToCm() -> Double {
        return self / kHeightConversion
    }
    
    func cmToInch() -> Double {
        return self * kHeightConversion * 12
    }
    
    func inchToCm() -> Double {
        return self / kHeightConversion / 12
    }
    
    func kgToPound() -> Double {
        return self * kWeightConversion
    }
    
    func poundToKg() -> Double {
        return self / kWeightConversion
    }
    
    /// 华氏温度转摄氏度
    /// - Returns: Double 摄氏度
    func tempratureFToC() -> Double {
        return (self - 32)/1.8
    }
    
    func tempratureCToF() -> Double {
        return self * 1.8 + 32
    }
    
    /// 绝对温度转摄氏度
    /// - Returns: Double 摄氏度
    func tempratureKToC() -> Double {
        return self - 273.15
    }
}
