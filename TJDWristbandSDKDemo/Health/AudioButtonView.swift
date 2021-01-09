//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  AudioButtonView.swift
//  TJDWristbandSDKDemo
//
//  Created by ANKER on 2020/9/30.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit

/// 该类主要用于日历上选择日期/年份的按钮
class AudioButtonView: UIView {
    var label: UILabel!
    var unitLabel: UILabel!
    var imageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initializeUI()
        initializeLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initializeUI() {
        unitLabel = UILabel().then {
            $0.textColor = UIColor.k999999
            $0.font = UIFont.systemFont(ofSize: 11)
        }
        addSubview(unitLabel)
        label = UILabel().then {
            $0.textColor = UIColor.k333333
            $0.font = UIFont.systemFont(ofSize: 14)
        }
        addSubview(label)
        imageView = UIImageView().then {
            $0.image = UIImage(named: "sanjiaoxing")
        }
        addSubview(imageView)
    }
    
    func initializeLayout() {
        imageView.snp.makeConstraints {
            $0.width.height.equalTo(16)
            $0.centerY.equalToSuperview()
            $0.right.equalTo(-10)
        }
        unitLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.right.equalTo(imageView.snp.left).offset(-15)
        }
        label.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.right.equalTo(unitLabel.snp.left).offset(-2)
            $0.left.equalTo(20)
        }
    }
    
}
