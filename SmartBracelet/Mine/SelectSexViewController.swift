//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  SelectSexViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/10/8.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit

class SelectSexViewController: UIViewController {
    @IBOutlet weak var chooseSexLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var mPickerView: UIPickerView!
    var type = 0
    var sex = ""
    var birth: [String] = ["1999", "1", "1"]
    weak var delegate: SelectSexVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        cancelButton.setTitle("mine_cancel".localized(), for: .normal)
        chooseSexLabel.text = "mine_select_sex".localized()
        okButton.setTitle("mine_confirm".localized(), for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if type == 0 && sex.count > 0 {
            mPickerView.selectRow(sex == "男" ? 0 : 1, inComponent: 0, animated: false)
        }
        if type == 1 {
            mPickerView.selectRow((Int(birth[0]) ?? 0) - 1920, inComponent: 0, animated: false)
            mPickerView.selectRow((Int(birth[1]) ?? 0) - 1, inComponent: 1, animated: false)
            mPickerView.selectRow((Int(birth[2]) ?? 0) - 1, inComponent: 2, animated: false)
        }
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func submit(_ sender: Any) {
        delegate?.callback(type: type, value: type == 0 ? sex : birth.joined(separator: "-"))
        dismiss(animated: true, completion: nil)
    }
}

extension SelectSexViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return type == 0 ? 1 : 3
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if type == 0 {
            return titles.count
        }
        if component == 0 {
            return 100
        } else if component == 1 {
            return 12
        } else {
            return 31
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if type == 0 {
            return titles[row]
        }
        if component == 0 {
            return "\(1920 + row)"
        } else if component == 1 {
            return "\(1 + row)"
        } else {
            return "\(1 + row)"
        }
    }
}

extension SelectSexViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if type == 0 {
            sex = titles[row]
            return
        }
        if component == 0 {
            birth[0] = "\(1920 + row)"
        } else if component == 1 {
            birth[1] = "\(1 + row)"
        } else {
            birth[2] = "\(1 + row)"
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 48
    }
}

extension SelectSexViewController {
    var titles: [String] {
        return ["mine_male".localized(), "mine_female".localized()]
    }
}

protocol SelectSexVCDelegate: NSObjectProtocol {
    func callback(type: Int, value: String)
}
