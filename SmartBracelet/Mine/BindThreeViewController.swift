//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  BindThreeViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/10/7.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit

class BindThreeViewController: UIViewController {
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descLabel: UILabel!
    @IBOutlet weak var threeImageView: UIImageView!
    @IBOutlet weak var appImageView: UIImageView!
    var type = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appImageView.image = UIImage(named: "image_portrait")
        setupValue()
    }
    
    private func setupValue() {
        if type == 0 {
            titleLabel.text = "微信绑定"
            threeImageView.image = UIImage(named: "wechat_protrait")
        } else {
            titleLabel.text = "QQ绑定"
            threeImageView.image = UIImage(named: "qq_protrait")
        }
    }

    @IBAction func submit(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
