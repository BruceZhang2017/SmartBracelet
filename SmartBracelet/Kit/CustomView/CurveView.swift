//
//  CurveView.swift
//  SmartBracelet
//
//  Created by anker on 2021/6/26.
//  Copyright © 2021 tjd. All rights reserved.
//

import UIKit

class CurveView: UIView {
    var getupLayer: CALayer = CALayer()
    var lightSleepLayer: CALayer = CALayer()
    var deepSleepLayer: CALayer = CALayer()
    var lineImageView: UIImageView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        setupUI()
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        lineImageView = UIImageView().then {
            $0.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        }
        addSubview(lineImageView)
        getupLayer.backgroundColor = UIColor.color(hex: "EB517B").cgColor
        lightSleepLayer.backgroundColor = UIColor.color(hex: "EAB055").cgColor
        deepSleepLayer.backgroundColor = UIColor.color(hex: "5AC1C1").cgColor
        layer.addSublayer(getupLayer)
        layer.addSublayer(lightSleepLayer)
        layer.addSublayer(deepSleepLayer)
    }
    
    private func setupLayout() {
        lineImageView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(0.5)
            $0.bottom.equalToSuperview()
        }
        getupLayer.frame = CGRect(x: 242.0 / 6 - 5, y: 50, width: 10, height: 0)
        lightSleepLayer.frame = CGRect(x: 242.0 * 3 / 6 - 5, y: 50, width: 10, height: 0)
        deepSleepLayer.frame = CGRect(x: 242.0 * 5 / 6 - 5, y: 50, width: 10, height: 0)
        
    }
    
    public func refreshHeight(_ value: [CGFloat]) {
        if value.count != 3 {
            return
        }
        
        getupLayer.frame = CGRect(x: 242.0 / 6 - 5, y: 50 - value[0], width: 10, height: value[0])
        lightSleepLayer.frame = CGRect(x: 242.0 * 3 / 6 - 5, y: 50 - value[1], width: 10, height: value[1])
        deepSleepLayer.frame = CGRect(x: 242.0 * 5 / 6 - 5, y: 50 - value[2], width: 10, height: value[2])
        
    }

}
