//
//  RoundView.swift
//  SmartBracelet
//
//  Created by bruce on 2024/4/20.
//  Copyright © 2024 tjd. All rights reserved.
//

import Foundation

class RoundView: UIView {
    
    private let progressWidth: CGFloat = 20.0
    private let progressLayer = CAShapeLayer()
    private var progress: CGFloat = 0.0 // 进度值，范围从0.0到1.0
    private let trackLayer = CAShapeLayer()
    
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
        trackLayer.path = progressPath.cgPath
        trackLayer.strokeColor = UIColor.white.withAlphaComponent(0.5).cgColor
        trackLayer.fillColor = nil
        trackLayer.lineWidth = progressWidth
        trackLayer.lineCap = .round
        trackLayer.strokeEnd = 1
        if trackLayer.superlayer == nil {
            layer.addSublayer(trackLayer)
        }
        
        progressLayer.path = progressPath.cgPath
        progressLayer.strokeColor = UIColor.white.cgColor
        progressLayer.fillColor = nil
        progressLayer.lineWidth = progressWidth
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0.5
        
        if progressLayer.superlayer == nil {
            layer.addSublayer(progressLayer)
        }
        
        mLabel.attributedText = value
        mLabel.textAlignment = .center
        mLabel.textColor = UIColor.white
        if mLabel.superview == nil {
            addSubview(mLabel)
            mLabel.snp.makeConstraints { make in
                make.height.equalTo(40)
                make.centerX.equalToSuperview()
                make.top.equalTo(100)
            }
        }
    }
    
    func setProgress(_ newProgress: CGFloat) {
        let clampedProgress = max(0, min(newProgress, 1))
        let previousProgress = progress
        progress = clampedProgress
        progressLayer.strokeEnd = progress
        
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = previousProgress
        animation.toValue = clampedProgress
        animation.duration = 0.42
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        progressLayer.add(animation, forKey: "health.round.progress")
    }
    
    func refreshView(value: NSMutableAttributedString) {
        UIView.transition(with: mLabel, duration: 0.24, options: [.transitionCrossDissolve, .allowUserInteraction]) {
            self.mLabel.attributedText = value
        }
        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.fromValue = 0.985
        pulse.toValue = 1.02
        pulse.duration = 0.16
        pulse.autoreverses = true
        pulse.repeatCount = 1
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        mLabel.layer.add(pulse, forKey: "health.round.label")
    }
}
