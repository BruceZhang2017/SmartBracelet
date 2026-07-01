//
//  FanView.swift
//  SmartBracelet
//
//  Created by bruce on 2024/4/20.
//  Copyright © 2024 tjd. All rights reserved.
//

import UIKit

class FanView: UIView {
    
    private let progressWidth: CGFloat = 20.0
    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private var progress: CGFloat = 0.0
    
    private let topLabel = UILabel()
    private let bottomLabel = UILabel()
    private let metricsContainerView = UIView()
    
    private var metricValueLabels: [UILabel] = []
    private var metricItemViews: [UIView] = []
    private var separatorViews: [UIView] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateProgressPath()
    }
    
    public func setupView(titles: [String], values: [NSMutableAttributedString], title: String, value: NSMutableAttributedString) {
        topLabel.text = title
        bottomLabel.attributedText = value
        rebuildMetricViews(titles: titles, values: values)
        setNeedsLayout()
    }
    
    func setProgress(_ newProgress: CGFloat) {
        progress = max(0, min(newProgress, 1))
        progressLayer.strokeEnd = progress
    }
    
    func refreshValue(values: [NSMutableAttributedString], value: NSMutableAttributedString) {
        for (index, label) in metricValueLabels.enumerated() where index < values.count {
            label.attributedText = values[index]
        }
        bottomLabel.attributedText = value
    }
    
    private func setupViews() {
        backgroundColor = .clear
        
        trackLayer.strokeColor = UIColor.white.withAlphaComponent(0.5).cgColor
        trackLayer.fillColor = nil
        trackLayer.lineWidth = progressWidth
        trackLayer.lineCap = .round
        trackLayer.strokeEnd = 1
        layer.addSublayer(trackLayer)
        
        progressLayer.strokeColor = UIColor.white.cgColor
        progressLayer.fillColor = nil
        progressLayer.lineWidth = progressWidth
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0
        layer.addSublayer(progressLayer)
        
        topLabel.textAlignment = .center
        topLabel.textColor = .white
        topLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        topLabel.numberOfLines = 2
        topLabel.adjustsFontSizeToFitWidth = true
        topLabel.minimumScaleFactor = 0.8
        topLabel.lineBreakMode = .byWordWrapping
        addSubview(topLabel)
        
        bottomLabel.textAlignment = .center
        bottomLabel.textColor = .white
        bottomLabel.numberOfLines = 1
        bottomLabel.adjustsFontSizeToFitWidth = true
        bottomLabel.minimumScaleFactor = 0.7
        bottomLabel.lineBreakMode = .byTruncatingTail
        addSubview(bottomLabel)
        
        addSubview(metricsContainerView)
        
        topLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(70)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        
        bottomLabel.snp.makeConstraints { make in
            make.top.equalTo(topLabel.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(24)
        }
        
        metricsContainerView.snp.makeConstraints { make in
            make.top.equalTo(bottomLabel.snp.bottom).offset(36)
            make.leading.trailing.equalToSuperview()
            make.height.greaterThanOrEqualTo(52)
            make.bottom.lessThanOrEqualToSuperview().inset(12)
        }
    }
    
    private func rebuildMetricViews(titles: [String], values: [NSMutableAttributedString]) {
        metricItemViews.forEach { $0.removeFromSuperview() }
        separatorViews.forEach { $0.removeFromSuperview() }
        metricItemViews.removeAll()
        metricValueLabels.removeAll()
        separatorViews.removeAll()
        
        guard !titles.isEmpty else { return }
        
        var previousItemView: UIView?
        for index in 0..<titles.count {
            let itemView = UIView()
            let titleLabel = UILabel()
            let valueLabel = UILabel()
            
            titleLabel.text = titles[index]
            titleLabel.textAlignment = .center
            titleLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
            titleLabel.textColor = UIColor.white.withAlphaComponent(0.8)
            titleLabel.numberOfLines = 2
            titleLabel.adjustsFontSizeToFitWidth = true
            titleLabel.minimumScaleFactor = 0.75
            titleLabel.lineBreakMode = .byWordWrapping
            
            valueLabel.attributedText = index < values.count ? values[index] : nil
            valueLabel.textAlignment = .center
            valueLabel.textColor = .white
            valueLabel.numberOfLines = 1
            valueLabel.adjustsFontSizeToFitWidth = true
            valueLabel.minimumScaleFactor = 0.75
            valueLabel.lineBreakMode = .byTruncatingTail
            
            itemView.addSubview(titleLabel)
            itemView.addSubview(valueLabel)
            metricsContainerView.addSubview(itemView)
            
            titleLabel.snp.makeConstraints { make in
                make.top.equalToSuperview()
                make.leading.trailing.equalToSuperview().inset(8)
            }
            
            valueLabel.snp.makeConstraints { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(4)
                make.leading.trailing.equalToSuperview().inset(8)
                make.bottom.equalToSuperview()
            }
            
            itemView.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                if let previousItemView {
                    make.leading.equalTo(previousItemView.snp.trailing)
                    make.width.equalTo(previousItemView)
                } else {
                    make.leading.equalToSuperview()
                }
                
                if index == titles.count - 1 {
                    make.trailing.equalToSuperview()
                }
            }
            
            if let previousItemView {
                let separatorView = UIView()
                separatorView.backgroundColor = .white
                metricsContainerView.addSubview(separatorView)
                separatorView.snp.makeConstraints { make in
                    make.centerX.equalTo(itemView.snp.leading)
                    make.centerY.equalTo(itemView)
                    make.width.equalTo(1)
                    make.height.equalTo(18)
                }
                separatorViews.append(separatorView)
            }
            
            metricItemViews.append(itemView)
            metricValueLabels.append(valueLabel)
            previousItemView = itemView
        }
    }
    
    private func updateProgressPath() {
        guard bounds.width > 0, bounds.height > 0 else { return }
        
        let radius = min(bounds.width * 0.24, 90)
        let centerY = min(max(bounds.height * 0.34, 110), 130)
        let centerPoint = CGPoint(x: bounds.midX, y: centerY)
        let startAngle = CGFloat.pi * 3 / 4
        let endAngle = CGFloat.pi * 2 + CGFloat.pi / 4
        let progressPath = UIBezierPath(
            arcCenter: centerPoint,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )
        
        trackLayer.path = progressPath.cgPath
        progressLayer.path = progressPath.cgPath
    }
}
