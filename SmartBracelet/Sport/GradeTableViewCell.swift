//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  GradeTableViewCell.swift
//  SmartBracelet
//
//  Created by ANKER on 2021/2/15.
//  Copyright © 2021 tjd. All rights reserved.
//
	

import UIKit

class GradeTableViewCell: UITableViewCell {
    @IBOutlet weak var GradeImageView: UIImageView!
    @IBOutlet weak var GradeLabel: UILabel!
    @IBOutlet weak var finishedLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
