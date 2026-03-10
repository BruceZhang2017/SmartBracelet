//
//  FanView.swift
//  SmartBracelet
//
//  Created by bruce on 2024/4/20.
//  Copyright © 2024 tjd. All rights reserved.
//

import Foundation

class FanView: UIView {
    
    private let progressWidth: CGFloat = 20.0
    private let progressLayer = CAShapeLayer()
    private var progress: CGFloat = 0.0 // 进度值，范围从0.0到1.0
    
    private let topLabel = UILabel()
    private let bottomLabel = UILabel()
    
    private var subViews: [UIView] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
  
    }
    
    public func setupView(titles: [String], values: [NSMutableAttributedString], title: String, value: NSMutableAttributedString) {
        // 设置半圆形进度条
        let radius: CGFloat = 90
        let centerPoint = CGPoint(x: screenWidth / 2, y: 120)
        let startAngle = CGFloat.pi * 3 / 4
        let endAngle = CGFloat.pi * 2 + CGFloat.pi / 4
        
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
        
        // 设置中间的两个UILabel
        topLabel.text = title
        topLabel.textAlignment = .center
        topLabel.textColor = UIColor.white
        topLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        addSubview(topLabel)
        topLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(74)
        }
        
        bottomLabel.attributedText = value
        bottomLabel.textAlignment = .center
        bottomLabel.textColor = UIColor.white
        addSubview(bottomLabel)
        bottomLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(topLabel.snp.bottom).offset(4)
        }
        
        // 设置下方的3个子View
        let subViewWidth = screenWidth / CGFloat(titles.count)
        for i in 0..<titles.count {
            let subView = UIView()
            
            let subTopLabel = UILabel()
            subTopLabel.text = titles[i]
            subTopLabel.textAlignment = .center
            subTopLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            subTopLabel.textColor = UIColor.white.withAlphaComponent(0.8)
            
            let subBottomLabel = UILabel()
            subBottomLabel.tag = 99
            subBottomLabel.attributedText = values[i]
            subBottomLabel.textAlignment = .center
            subBottomLabel.textColor = UIColor.white
            
            subView.addSubview(subTopLabel)
            subTopLabel.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalToSuperview()
                make.height.equalTo(20)
            }
            subView.addSubview(subBottomLabel)
            subBottomLabel.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(subTopLabel.snp.bottom)
                make.height.equalTo(24)
            }
            addSubview(subView)
            subView.snp.makeConstraints { make in
                make.leading.equalTo(CGFloat(i) * subViewWidth)
                make.top.equalTo(bottomLabel.snp.bottom).offset(50)
                make.width.equalTo(subViewWidth)
                make.height.equalTo(52)
            }
            subViews.append(subView)
            
            // 如果不是最后一个子View，添加分隔的UIImageView
            if i < 2 {
                let separatorImageView = UIImageView()
                separatorImageView.backgroundColor = .white
                addSubview(separatorImageView)
                separatorImageView.snp.makeConstraints { make in
                    make.leading.equalTo(subViewWidth * CGFloat(i + 1))
                    make.centerY.equalTo(subView.snp.centerY)
                    make.height.equalTo(10)
                    make.width.equalTo(1)
                }
            }
        }
    }
    
    func setProgress(_ newProgress: CGFloat) {
        progress = newProgress
        progressLayer.strokeEnd = progress
    }
    
    func refreshValue(values: [NSMutableAttributedString], value: NSMutableAttributedString) {
        for (i,v) in subViews.enumerated() {
            if let label = v.viewWithTag(99) as? UILabel {
                label.attributedText = values[i]
            }
        }
        bottomLabel.attributedText = value
    }
}
