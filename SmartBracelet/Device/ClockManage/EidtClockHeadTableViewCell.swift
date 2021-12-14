//
//  EidtClockHeadTableViewCell.swift
//  SmartBracelet
//
//  Created by anker on 2021/12/12.
//  Copyright © 2021 tjd. All rights reserved.
//

import UIKit

class EidtClockHeadTableViewCell: UITableViewCell {
    @IBOutlet weak var clockView: UIView!
    @IBOutlet weak var dateTimeLabel: UILabel!
    @IBOutlet weak var dateTimeTopLabel: UILabel!
    @IBOutlet weak var dateTimeBottomLabel: UILabel!
    @IBOutlet weak var selectButton: UIButton!
    weak var delegate: EidtClockHeadTableViewCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction private func selectPhoto(_ sender: Any) {
        delegate?.handleSelectPhoto() // 让代理处理
    }

}

protocol EidtClockHeadTableViewCellDelegate: NSObjectProtocol {
    func handleSelectPhoto()
}
