//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  UIButton+Extension.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/7/29.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit

extension UIButton {
    /// UIButton图像文字同时存在时---图像相对于文字的位置
    ///
    /// - top: 图像在上
    /// - left: 图像在左
    /// - right: 图像在右
    /// - bottom: 图像在下
    enum SCButtonImageEdgeInsetsStyle {
        case top, left, right, bottom
    }
    
    
    /// 设置图片的位置，必须在设置image和title之后调用
    ///
    /// - Parameters:
    ///   - style: 图片相对文字的位置
    ///   - space: 两者间隔
    func setImagePosition(at style: UIButton.SCButtonImageEdgeInsetsStyle, space: CGFloat) {
        guard let imageV = imageView else { return }
        guard let titleL = titleLabel else { return }
        //使约束生效
        layoutIfNeeded()
        let btnWidth = bounds.width
        let btnHeight = bounds.height
        //获取图像的布局信息
        let imageWidth = imageV.frame.size.width
        let imageHeight = imageV.frame.size.height
        let imageRect = imageV.frame
        //获取文字的布局信息
        let labelWidth  = titleL.intrinsicContentSize.width
        let labelHeight = titleL.intrinsicContentSize.height
        let labelRect = titleL.frame
        
        var imageEdgeInsets = UIEdgeInsets.zero
        var labelEdgeInsets = UIEdgeInsets.zero
        //UIButton同时有图像和文字的正常状态---左图像右文字，间距为0
        switch style {
        case .left:
            //正常状态--只不过加了个间距
            imageEdgeInsets = UIEdgeInsets(top: 0, left: -space * 0.5, bottom: 0, right: space * 0.5)
            labelEdgeInsets = UIEdgeInsets(top: 0, left: space * 0.5, bottom: 0, right: -space * 0.5)
        case .right:
            //切换位置--左文字右图像
            //图像：UIEdgeInsets的left是相对于UIButton的左边移动了labelWidth + space * 0.5，right相对于label的左边移动了-labelWidth - space * 0.5
            imageEdgeInsets = UIEdgeInsets(top: 0, left: labelWidth + space * 0.5, bottom: 0, right: -labelWidth - space * 0.5)
            labelEdgeInsets = UIEdgeInsets(top: 0, left: -imageWidth - space * 0.5, bottom: 0, right: imageWidth + space * 0.5)
        case .top:
            //切换位置--上图像下文字
            /**图像和文字保持一定距离（space），整体垂直居中。
             */
            let totalHeight = imageRect.height + labelRect.height + space //整个内容高度
            var top = (btnHeight - totalHeight) / 2 - imageRect.minY
            var left = btnWidth / 2 - imageRect.minX - imageRect.width / 2
            var bottom = -((btnHeight - totalHeight) / 2 - imageRect.minY)
            var right = -(btnWidth / 2 - imageRect.minX - imageRect.width / 2)
            imageEdgeInsets = UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
            top = (btnHeight - totalHeight)/2 + imageRect.height + space - labelRect.minY
            left = (btnWidth / 2 - labelRect.minX - labelRect.width / 2) - (btnWidth - labelRect.width) / 2
            bottom = -((btnHeight - totalHeight) / 2 + imageRect.height + space - labelRect.minY)
            right = -(btnWidth / 2 - labelRect.minX - labelRect.width / 2) - (btnWidth - labelRect.width) / 2
            labelEdgeInsets = UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
        case .bottom:
            //切换位置--下图像上文字
            /**图像的中心位置向右移动了labelWidth * 0.5，向下移动了imageHeight * 0.5 + space * 0.5
             *文字的中心位置向左移动了imageWidth * 0.5，向上移动了labelHeight*0.5+space*0.5
             */
            imageEdgeInsets = UIEdgeInsets(top: imageHeight * 0.5 + space * 0.5, left: labelWidth * 0.5, bottom: -imageHeight * 0.5 - space * 0.5, right: -labelWidth * 0.5)
            labelEdgeInsets = UIEdgeInsets(top: -labelHeight * 0.5 - space * 0.5, left: -imageWidth * 0.5, bottom: labelHeight * 0.5 + space * 0.5, right: imageWidth * 0.5)
        }
        self.titleEdgeInsets = labelEdgeInsets
        self.imageEdgeInsets = imageEdgeInsets
    }
}

extension UIButton {
    func initializeRightNavigationItem() {
        titleLabel?.font = UIFont.systemFont(ofSize: 12)
        setTitleColor(.white, for: .normal)
        setTitleColor(.kAAAAAA, for: .disabled)
        setBackgroundImage(UIColor.image(color: .k64F2B4, viewSize: CGSize(width: 60, height: 24)), for: .normal)
        setBackgroundImage(UIColor.image(color: .kFF5E46, viewSize: CGSize(width: 60, height: 24)), for: .selected)
        setBackgroundImage(UIColor.image(color: .kDDDDDD, viewSize: CGSize(width: 60, height: 24)), for: .disabled)
        layer.cornerRadius = 2
    }
}

