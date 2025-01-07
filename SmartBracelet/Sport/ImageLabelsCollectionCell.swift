//
//  ImageLabelsCollectionCell.swift
//  LifeFit
//
//  Created by tjd on 2018/11/28.
//  Copyright © 2018年 tjd. All rights reserved.
//

import UIKit

class ImageLabelsCollectionCell: UICollectionViewCell {
    var iconImageView = UIImageView()
    var nameLabel = UILabel()
    var valueLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(valueLabel)
        valueLabel.snp.makeConstraints { (make) in
            make.width.height.lessThanOrEqualToSuperview()
            make.center.equalToSuperview()
        }
        valueLabel.textColor = UIColor.red
        valueLabel.font = UIFont.systemFont(ofSize: 22)
        valueLabel.numberOfLines = 0
        valueLabel.lineBreakMode = .byCharWrapping
        valueLabel.textAlignment = .center
        
        contentView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(valueLabel.snp.top).offset(-8)
        }
        
        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.width.height.lessThanOrEqualToSuperview()
            make.centerX.equalToSuperview()
            make.top.equalTo(valueLabel.snp.bottom).offset(5)
        }
        nameLabel.textColor = UIColor.red
        nameLabel.font = UIFont.systemFont(ofSize: 12)
        nameLabel.numberOfLines = 0
        nameLabel.lineBreakMode = .byCharWrapping
        nameLabel.textAlignment = .center
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
