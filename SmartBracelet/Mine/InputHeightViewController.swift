//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  InputHeightViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/10/8.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit
import Toaster

class InputHeightViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var unitLabel: UILabel!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var mTextField: UITextField!
    var type = 0
    var value = ""
    weak var delegate: InputHeightVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupValue()
        mTextField.keyboardType = .numberPad
        cancelButton.setTitle("mine_cancel".localized(), for: .normal)
        titleLabel.text = "mine_height".localized()
        okButton.setTitle("mine_confirm".localized(), for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mTextField.text = value
    }
    
    private func setupValue() {
        if type == 0 {
            titleLabel.text = "mine_height".localized()
            unitLabel.text = "CM"
            
        } else {
            titleLabel.text = "mine_weight".localized()
            unitLabel.text = "KG"
        }
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func submit(_ sender: Any) {
        guard let value = mTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), value.count > 0 else {
            Toast(text: "help_center_text_tip".localized()).show()
            return
        }
        delegate?.callback(type: type, value: Int(value) ?? 0)
        dismiss(animated: true, completion: nil)
    }
}

protocol InputHeightVCDelegate: NSObjectProtocol {
    func callback(type: Int, value: Int)
}
