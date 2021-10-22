//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  SetTargetCViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/11/8.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit

class SetTargetCViewController: BaseViewController {
    
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var startRunButton: UIButton!
    var selectedIndex = 0 // 当前被选择的项目
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = String.kSetTarget
        var goal = UserDefaults.standard.integer(forKey: "Goal") 
        if goal == 0 {
            goal = bleSelf.userInfo.stepGoal
        }
        let index = steps.firstIndex(of: goal) ?? 0
        if index >= 0 {
            selectedIndex = index
            pickerView.selectRow(index, inComponent: 0, animated: true)
        }
        startRunButton.setTitle("mine_confirm".localized(), for: .normal)
    }
    
    @IBAction func startRun(_ sender: Any) {
        bleSelf.userInfo.stepGoal = steps[selectedIndex]
        bleSelf.setUserinfoForWristband(bleSelf.userInfo)
        UserDefaults.standard.setValue(steps[selectedIndex], forKey: "Goal")
        UserDefaults.standard.synchronize()
        navigationController?.popViewController(animated: true)
    }

}

extension SetTargetCViewController: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return steps.count
    }
    
    
}

extension SetTargetCViewController: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return ScreenWidth
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 54
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var temView: UIView!
        if view != nil {
            temView = view
        } else {
            temView = UIView()
            let label = UILabel()
            label.tag = 1
            temView.addSubview(label)
            label.snp.makeConstraints {
                $0.center.equalToSuperview()
            }
        }
        let label = temView.viewWithTag(1) as! UILabel
        label.text = "\(steps[row])"
        return temView
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedIndex = row
    }
}

extension SetTargetCViewController {
    var steps: [Int] {
        return [1000,2000,3000,4000,5000,6000,8000,10000,12000,14000,16000,18000,20000]
    }
}

