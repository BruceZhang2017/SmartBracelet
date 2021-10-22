//
//  CyclicCardCell.swift
//  CyclicCard
//
//  Created by Tony on 17/1/11.
//  Copyright © 2017年 Tony. All rights reserved.
//

import UIKit

class CyclicCardCell: UICollectionViewCell {
    
    var index = Int() // 下标
    var bConnected = false 
    let cardImgView = UIImageView()
    let cardNameLabel = UILabel()
    let btButton = UIButton(type: .custom)
    let batteryButton = UIButton(type: .custom)
    let addLabel = UILabel()
    let settingsImageView = UIImageView()
    
    override  init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(cardImgView)
        cardImgView.frame = CGRect(x: 4, y: 25, width: 60, height: 60)
        cardImgView.layer.cornerRadius = 30
        cardImgView.layer.borderColor = UIColor.kDDDDDD.cgColor
        cardImgView.layer.borderWidth = 0.5
        cardImgView.backgroundColor = UIColor.white
        
        let itemW = (ScreenWidth - 20 * 2) * 0.5
        self.addSubview(cardNameLabel)
        cardNameLabel.frame = CGRect(x: 76, y: 17, width: itemW - 80, height: 20)
        cardNameLabel.textColor = UIColor.k333333
        cardNameLabel.font = UIFont.systemFont(ofSize: 16)
        cardNameLabel.textAlignment = .left
        
        addSubview(btButton)
        btButton.setImage(UIImage(named: "content_blueteeth_link"), for: .normal)
        btButton.setTitle("mine_bluetooth_connect".localized(), for: .normal)
        btButton.titleLabel?.font = UIFont.systemFont(ofSize: 8)
        btButton.setTitleColor(.k999999, for: .normal)
        btButton.contentHorizontalAlignment = .left
        btButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 6)
        btButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 3, bottom: 0, right: -3)
        btButton.frame = CGRect(x: 76, y: 60, width: itemW - 80, height: 16)
        
        addSubview(batteryButton)
        batteryButton.setImage(UIImage(named: "conten_battery_full"), for: .normal)
        batteryButton.setTitle("\("mine_battery_level".localized())88%", for: .normal)
        batteryButton.titleLabel?.font = UIFont.systemFont(ofSize: 8)
        batteryButton.setTitleColor(.k999999, for: .normal)
        batteryButton.contentHorizontalAlignment = .left
        batteryButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 6)
        batteryButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 3, bottom: 0, right: -3)
        batteryButton.frame = CGRect(x: 76, y: 80, width: itemW - 80, height: 16)
        
        addSubview(settingsImageView)
        settingsImageView.image = UIImage(named: "shezhi")
        settingsImageView.snp.makeConstraints {
            $0.width.height.equalTo(20)
            $0.top.equalTo(10)
            $0.right.equalTo(-10)
        }
        
        addSubview(addLabel)
        addLabel.text = "add_device".localized()
        addLabel.textColor = .k333333
        addLabel.isHidden = true 
        addLabel.font = UIFont.systemFont(ofSize: 16)
        addLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
