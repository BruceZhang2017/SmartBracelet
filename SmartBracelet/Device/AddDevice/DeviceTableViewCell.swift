//
// Copyright © 2015-2018 bruce Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  DeviceTableViewCell.swift
//  SmartBracelet
//
//  Created by bruce on 2021/1/24.
//  Copyright © 2021 tjd. All rights reserved.
//
	

import UIKit

class DeviceTableViewCell: UITableViewCell {
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var deviceImageView: UIImageView!
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var bleConnectButton: UIButton!
    @IBOutlet weak var selectImageView: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!
    
    weak var delegate: DeviceTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func handleDeleteDevice(_ sender: Any) {
        delegate?.buttonTapped(cell: self)
    }
}

protocol DeviceTableViewCellDelegate: AnyObject {
    func buttonTapped(cell: DeviceTableViewCell)
}
