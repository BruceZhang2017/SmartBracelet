//
//  SelectItemViewController.swift
//  SmartBracelet
//
//  Created by anker on 2021/12/13.
//  Copyright © 2021 tjd. All rights reserved.
//

import UIKit

class SelectItemViewController: UIViewController {
    @IBOutlet weak var chooseSexLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var mPickerView: UIPickerView!
    var item = "" // 当前选中项的内容
    var type = 0
    var index = 0 // 当前选中的index
    var titles: [String] = []
    weak var delegate: SelectItemVCDelegate?
    var titleStr: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        cancelButton.setTitle("mine_cancel".localized(), for: .normal)
        okButton.setTitle("mine_confirm".localized(), for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mPickerView.selectRow(index, inComponent: 0, animated: false)
        
        chooseSexLabel.text = titleStr
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func submit(_ sender: Any) {
        delegate?.callback(type: type, index: index, value: item)
        dismiss(animated: true, completion: nil)
    }
}

extension SelectItemViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return titles.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return titles[row]
    }
}

extension SelectItemViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        item = titles[row]
        index = row
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 48
    }
}

protocol SelectItemVCDelegate: NSObjectProtocol {
    func callback(type: Int, index: Int, value: String)
}

