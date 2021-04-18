//
//  HeartRateCollectionViewCell.swift
//  SmartBracelet
//
//  Created by anker on 2021/4/17.
//  Copyright © 2021 tjd. All rights reserved.
//

import UIKit

class HeartRateCollectionViewCell: UICollectionViewCell {
    var value: CGFloat = 0
    var lineImageView: UIImageView!
    var valueImageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        lineImageView = UIImageView().then {
            $0.backgroundColor = UIColor.hexStr(hexStr: "EEEEEE", alpha: 1)
            $0.layer.cornerRadius = 2
        }
        contentView.addSubview(lineImageView)
        lineImageView.snp.makeConstraints {
            $0.width.equalTo(4)
            $0.height.equalToSuperview()
            $0.center.equalToSuperview()
        }
        
        valueImageView = UIImageView().then {
            $0.backgroundColor = UIColor.hexStr(hexStr: "EB516B", alpha: 1)
            $0.layer.cornerRadius = 2
        }
        contentView.addSubview(valueImageView)
        valueImageView.snp.makeConstraints {
            $0.width.equalTo(4)
            $0.height.equalTo(0)
            $0.center.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func refreshUI() {
        valueImageView.snp.updateConstraints {
            $0.height.equalTo(50 * value / 100)
        }
    }
}
