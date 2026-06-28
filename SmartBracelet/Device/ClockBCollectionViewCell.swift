//
// Copyright © 2015-2018 bruce Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  ClockBCollectionViewCell.swift
//  SmartBracelet
//
//  Created by bruce on 2020/9/5.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit

class ClockBCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var clockBGView: UIView!
    @IBOutlet weak var clockImageView: UIImageView!
    @IBOutlet weak var addImageView: UIImageView!
    @IBOutlet weak var width: NSLayoutConstraint!
    @IBOutlet weak var height: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        clockBGView.layer.cornerRadius = 18
        clockBGView.layer.cornerCurve = .continuous
        clockBGView.layer.borderWidth = 1
        clockBGView.layer.borderColor = UIColor.brand.withAlphaComponent(0.06).cgColor
        clockBGView.layer.masksToBounds = true
        
        layer.shadowColor = UIColor.brand.withAlphaComponent(0.05).cgColor
        layer.shadowOpacity = 1
        layer.shadowOffset = CGSize(width: 0, height: 6)
        layer.shadowRadius = 12
        
        clockImageView.contentMode = .scaleAspectFill
        clockImageView.layer.cornerRadius = 14
        clockImageView.layer.cornerCurve = .continuous
        clockImageView.layer.masksToBounds = true
        
        addImageView.contentMode = .scaleAspectFit
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 18).cgPath
    }
}
