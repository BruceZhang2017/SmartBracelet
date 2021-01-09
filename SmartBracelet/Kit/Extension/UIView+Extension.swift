//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  UIView+Extension.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/7/27.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit
import SafariServices

extension UIView {
    
    func addGradientLayer(at rect: CGRect, colors: [UIColor]) {
        let gLayer = CAGradientLayer()
        gLayer.colors = colors.map({$0.cgColor})
        gLayer.frame = rect
        gLayer.startPoint = CGPoint(x: 0, y: 0)
        gLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.insertSublayer(gLayer, at: 0)
    }
    
    func addVGradientLayer(at rect: CGRect, colors: [UIColor]) {
        let gLayer = CAGradientLayer()
        gLayer.colors = colors.map({$0.cgColor})
        gLayer.frame = rect
        gLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.insertSublayer(gLayer, at: 0)
    }
    
    func addShadow(color: UIColor, offset: CGSize, opacity: Float) {
        layer.shadowColor = color.cgColor
        layer.shadowOffset = offset
        layer.shadowOpacity = opacity
    }
}

extension UIView {
    @IBInspectable var borderColor : UIColor? {
        set (newValue) {
            self.layer.borderColor = (newValue ?? UIColor.clear).cgColor
        }
        get { // 此处强解析是否会引起crash。是否存在为空的情况
            return UIColor(cgColor: self.layer.borderColor!)
        }
    }
}

extension UIViewController {
    func openURLWithSafari(url: String) {
        //URLCache.shared.removeAllCachedResponses()
        if url.count == 0 {
            return
        }
        if !url.hasPrefix("http://") && !url.hasPrefix("https://") {
            return
        }
        let url = URL(string: url) ?? URL(string: "https://www.baidu.com/")
        let safariVC = SFSafariViewController(url: url!)
        present(safariVC, animated: true)
    }
    
    func getTimes(date: Date) -> [Int] {
        var timers: [Int] = [] //  返回的数组
        let calendar: Calendar = Calendar(identifier: .gregorian)
        var comps: DateComponents = DateComponents()
        comps = calendar.dateComponents([.year,.month,.day, .weekday, .hour, .minute,.second], from: date)
        timers.append(comps.year! % 2000)  // 年 ，后2位数
        timers.append(comps.month!)            // 月
        timers.append(comps.day!)                // 日
        timers.append(comps.hour!)               // 小时
        timers.append(comps.minute!)            // 分钟
        timers.append(comps.second!)            // 秒
        timers.append(comps.weekday! - 1)      //星期
        return timers
    }
}

extension UIViewController {
    public func showLocationAlertView(title: String, message: String) {
        let alertView = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "确定", style: .default) { (action) in
            let url = URL(string: "App-Prefs:root=LOCATION_SERVICES")
            if UIApplication.shared.canOpenURL(url!) {
                UIApplication.shared.open(url!, options: [:], completionHandler: nil)
            }
        }
        alertView.addAction(ok)
        present(alertView, animated: true, completion: nil)
    }
}
