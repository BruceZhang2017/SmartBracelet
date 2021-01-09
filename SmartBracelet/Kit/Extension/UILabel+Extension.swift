//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  UILabel+Extension.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/7/27.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit

extension UILabel {
    func setDifferentFontText(fonts: [UIFont],
                              colors: [UIColor],
                              text: String,
                              subLen: Int) {
        if fonts.count != 2 {
            return
        }
        if colors.count != 2 {
            return
        }
        let attrString = NSMutableAttributedString(string: text)
        attrString.addAttribute(.font, value: fonts[0], range: NSRange(location: 0, length: subLen))
        attrString.addAttribute(.font, value: fonts[1], range: NSRange(location: subLen, length: text.count - subLen))
        attrString.addAttribute(.foregroundColor, value: colors[0], range: NSRange(location: 0, length: subLen))
        attrString.addAttribute(.foregroundColor, value: colors[1], range: NSRange(location: subLen, length: text.count - subLen))
        attributedText = attrString
    }
}
