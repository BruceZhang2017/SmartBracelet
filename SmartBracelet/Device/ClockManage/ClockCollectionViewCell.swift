//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  ClockCollectionViewCell.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/9/5.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit

class ClockCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var dialImageView: UIImageView!
    @IBOutlet weak var opaqueView: UIView!
    @IBOutlet weak var optionImageView: UIImageView!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
}
