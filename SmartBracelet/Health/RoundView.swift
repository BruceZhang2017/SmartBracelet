//
//  RoundView.swift
//  SmartBracelet
//
//  Created by anker on 2024/4/20.
//  Copyright © 2024 tjd. All rights reserved.
//

import Foundation

class RoundView: UIView {
    
    private let progressWidth: CGFloat = 20.0
    private let progressLayer = CAShapeLayer()
    private var progress: CGFloat = 0.0 // 进度值，范围从0.0到1.0
    
    private let mLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
    }
    
    public func setupView(value: NSMutableAttributedString) {
        // 设置半圆形进度条
        let radius: CGFloat = 90
        let centerPoint = CGPoint(x: screenWidth / 2, y: 120)
        let startAngle = CGFloat.pi
        let endAngle = CGFloat.pi * 3
        
        let progressPath = UIBezierPath(arcCenter: centerPoint, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        let sLayer = CAShapeLayer()
        sLayer.path = progressPath.cgPath
        sLayer.strokeColor = UIColor.white.withAlphaComponent(0.5).cgColor
        sLayer.fillColor = nil
        sLayer.lineWidth = progressWidth
        sLayer.lineCap = .round
        sLayer.strokeEnd = 1
        layer.addSublayer(sLayer)
        
        progressLayer.path = progressPath.cgPath
        progressLayer.strokeColor = UIColor.white.cgColor
        progressLayer.fillColor = nil
        progressLayer.lineWidth = progressWidth
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0.5
        
        layer.addSublayer(progressLayer)
        
        mLabel.attributedText = value
        mLabel.textAlignment = .center
        mLabel.textColor = UIColor.white
        addSubview(mLabel)
        mLabel.snp.makeConstraints { make in
            make.height.equalTo(40)
            make.centerX.equalToSuperview()
            make.top.equalTo(100)
        }
    }
    
    func setProgress(_ newProgress: CGFloat) {
        progress = newProgress
        progressLayer.strokeEnd = progress
    }
    
    func refreshView(value: NSMutableAttributedString) {
        mLabel.attributedText = value
    }
}
