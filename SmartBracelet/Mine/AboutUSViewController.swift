//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  AboutUSViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/8/17.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit

class AboutUSViewController: BaseViewController {
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var ownerLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "mine_about".localized()
        // Do any additional setup after loading the view.
        versionLabel.text = "v1.0.0  \("mine_version".localized())"
        ownerLabel.text = "＠ VPI6  \("mine_about_desc".localized())"
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
