//
// Copyright © 2015-2018 bruce Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  UIView+Extension.swift
//  SmartBracelet
//
//  Created by bruce on 2020/7/27.
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
    
    /// bg_base1 方法用于设置背景的渐变色
    /// - 使用了自定义的 UIColor 扩展来通过十六进制颜色值创建 UIColor 对象
    /// - 在当前视图的 bounds 范围内添加了一个垂直渐变层
    func bg_base1() {
        let topColor = UIColor(hex: 0x3990F9)
        let bottomColor = UIColor(hex: 0xFFFFFF)
        addVGradientLayer(at: self.bounds, colors: [topColor, bottomColor])
    }
    
    /// bg_base2 方法用于设置背景的渐变色
    /// - 使用了自定义的 UIColor 扩展来通过十六进制颜色值创建 UIColor 对象
    /// - 在当前视图的 bounds 范围内添加了一个垂直渐变层
    func bg_base2() {
        let topColor = UIColor(hex: 0xAED3FF)
        let bottomColor = UIColor(hex: 0xEFF5FC)
        addVGradientLayer(at: self.bounds, colors: [topColor, bottomColor])
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
        let ok = UIAlertAction(title: "mine_confirm".localized(), style: .default) { (action) in
            let url = URL(string: "App-Prefs:root=LOCATION_SERVICES")
            if UIApplication.shared.canOpenURL(url!) {
                UIApplication.shared.open(url!, options: [:], completionHandler: nil)
            }
        }
        alertView.addAction(ok)
        present(alertView, animated: true, completion: nil)
    }
}

extension UITextView: UITextViewDelegate {
    
    // Placeholder text
    @IBInspectable var placeholder: String? {
        get {
            var placeholderText: String?
            
            if let placeholderLabel = self.viewWithTag(100) as? UILabel {
                placeholderText = placeholderLabel.text
            }
            return placeholderText
        }
        set {
            if let placeholderLabel = self.viewWithTag(100) as! UILabel? {
                placeholderLabel.text = newValue
                placeholderLabel.sizeToFit()
            } else {
                self.addPlaceholder(newValue!)
            }
        }
    }
    
    // Add a placeholder to the UITextView
    func addPlaceholder(_ placeholderText: String) {
        let placeholderLabel = UILabel()
        placeholderLabel.text = placeholderText
        placeholderLabel.sizeToFit()
        placeholderLabel.font = self.font
        placeholderLabel.textColor = UIColor.text_third
        placeholderLabel.tag = 100
        
        placeholderLabel.isHidden = self.text.count > 0
        
        self.addSubview(placeholderLabel)
        self.delegate = self
        self.resizePlaceholder()
        self.sendSubviewToBack(placeholderLabel)
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        if let placeholderLabel = self.viewWithTag(100) as? UILabel {
            placeholderLabel.isHidden = self.text.count > 0
        }
    }
    
    private func resizePlaceholder() {
        if let placeholderLabel = self.viewWithTag(100) as? UILabel {
            let labelX = self.textContainer.lineFragmentPadding
            let labelY = self.textContainerInset.top - 2
            let labelWidth = self.frame.width - (labelX * 2)
            let labelHeight = placeholderLabel.frame.height
            
            placeholderLabel.frame = CGRect(x: labelX, y: labelY, width: labelWidth, height: labelHeight)
        }
    }
}
