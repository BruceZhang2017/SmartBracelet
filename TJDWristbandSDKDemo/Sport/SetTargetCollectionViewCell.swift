//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  SetTargetCollectionViewCell.swift
//  TJDWristbandSDKDemo
//
//  Created by ANKER on 2020/7/29.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit

class SetTargetCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var conView: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var descLabel: UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        conView.layer.borderColor = UIColor.k45DEB4.cgColor
    }
    
}
