//
// * Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// * The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.

//
//  SGCirle.swift
//  SGCirleProgress
//
//  Created by SeanGao on 2018/1/9.
//  Copyright © 2018年 SeanGao. All rights reserved.
//

import UIKit

class SGCirle: UIView {

    var lineWidth_: CGFloat!
    
    private var trackLayer: CAShapeLayer = CAShapeLayer()
    private var progressLayer: CAShapeLayer = CAShapeLayer()
    
    var progress: CGFloat = 0 {
        didSet {
            progressLayer.strokeEnd = progress
            progressLayer.removeAllAnimations()
        }
    }
    
    init(frame: CGRect, lineWidth: CGFloat, singleColor: UIColor? = nil, strokeColor: UIColor? = nil) {
        super.init(frame: frame)
        lineWidth_ = lineWidth
        self.buildLayout(singleColor: singleColor, strokeColor: strokeColor)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func buildLayout(singleColor: UIColor?, strokeColor: UIColor?) {
        let centerX:CGFloat = self.bounds.size.width / 2.0
        let centerY:CGFloat = self.bounds.size.height / 2.0
        let radius:CGFloat = (self.bounds.size.width - lineWidth_) / 2.0;
        
        let path:UIBezierPath = UIBezierPath(arcCenter: CGPoint(x: centerX, y: centerY), radius: radius, startAngle: CGFloat(-0.5 * Double.pi), endAngle: CGFloat(1.5 * Double.pi), clockwise: true)
        let backLayer:CAShapeLayer = CAShapeLayer()
        backLayer.frame = self.bounds
        backLayer.fillColor = UIColor.clear.cgColor
        backLayer.strokeColor = UIColor.lightGray.withAlphaComponent(0.3).cgColor
        backLayer.lineWidth = lineWidth_
        backLayer.path = path.cgPath
        backLayer.strokeEnd = 1
        self.layer.addSublayer(backLayer)
        
        progressLayer = CAShapeLayer()
        progressLayer.frame = self.bounds
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor  = singleColor == nil ? UIColor.blue.cgColor : singleColor!.cgColor
        progressLayer.lineCap = CAShapeLayerLineCap.round
        progressLayer.lineWidth = lineWidth_
        progressLayer.path = path.cgPath
        progressLayer.strokeEnd = 0
        layer.addSublayer(progressLayer)
    }
    
    public func setSingleColor(_ value: UIColor) {
        progressLayer.strokeColor = value.cgColor
    }
    
}
