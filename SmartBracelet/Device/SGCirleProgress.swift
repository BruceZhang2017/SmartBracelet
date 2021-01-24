//
// * Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// * The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.

//
//  SGCirleProgress.swift
//  SGCirleProgress
//
//  Created by SeanGao on 2018/1/9.
//  Copyright © 2018年 SeanGao. All rights reserved.
//

import UIKit

class SGCirleProgress: UIView {

    private var circle: SGCirle!
    private var percentLabel: UILabel!
    
    var progress: CGFloat = 0 {
        didSet {
            if progress > 100 { // 根据bugly获取到的bug修改，规避crash的情况
                return
            }
            circle.progress = progress / 100
            percentLabel.text = "\(String(format: "%.2f", progress))%"
        }
    }
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        initUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initUI() {
        let lineWidth: CGFloat = 6
        percentLabel = UILabel(frame: self.bounds)
        percentLabel.textColor = UIColor.black
        percentLabel.textAlignment = .center
        percentLabel.font = UIFont.systemFont(ofSize: 16)
        percentLabel.text = "0%"
        self.addSubview(percentLabel)
        
        circle = SGCirle(frame: self.bounds, lineWidth: lineWidth, singleColor: UIColor.k64F2B4)
        self.addSubview(circle)
    }
    
}
