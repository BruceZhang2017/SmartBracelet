//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  ClockBCollectionViewCell.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/9/5.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit

class ClockBCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var clockBGView: UIView!
    @IBOutlet weak var clockImageView: UIImageView!
    @IBOutlet weak var clockNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        clockBGView.layer.borderColor = UIColor.colorWithRGB(rgbValue: 0xDDDDDD).cgColor
        clockBGView.layer.borderWidth = 0.5
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
    }
}
