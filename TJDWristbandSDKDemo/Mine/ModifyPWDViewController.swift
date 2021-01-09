//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  ModifyPWDViewController.swift
//  TJDWristbandSDKDemo
//
//  Created by ANKER on 2020/10/7.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit

class ModifyPWDViewController: BaseViewController {
    @IBOutlet weak var oPWDTextField: UITextField!
    @IBOutlet weak var nPWDTextField: UITextField!
    @IBOutlet weak var rnPWDTextField: UITextField!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    @IBAction func showOrHidePWD(_ sender: Any) {
    }
    
    @IBAction func forgetPWD(_ sender: Any) {
    }
    
    @IBAction func submit(_ sender: Any) {
    }
    
    @IBAction func cancel(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    
}
