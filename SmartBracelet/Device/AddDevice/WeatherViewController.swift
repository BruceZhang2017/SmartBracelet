//
//  WeatherViewController.swift
//  TJDWristbandSDKDemo
//
//  Created by apple on 2020/11/30.
//  Copyright © 2020 tjd. All rights reserved.
//

import UIKit
import TJDWristbandSDK
import Toaster

class WeatherViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    var pickerView = UIPickerView()
    var titleArray = [String]()
    var stepAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 35), NSAttributedString.Key.foregroundColor: UIColor.red]

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        // Do any additional setup after loading the view.
        for i in 0..<100 {
            titleArray.append(String.init(format: "%d", i - 50))
        }
        let pickerHeight: CGFloat = 400
        pickerView.frame = CGRect.init(x: 0, y: (UIScreen.main.bounds.height - pickerHeight)/2, width: UIScreen.main.bounds.width, height: pickerHeight)
        pickerView.delegate = self
        pickerView.dataSource = self
        self.view.addSubview(pickerView)
        pickerView.selectRow(50, inComponent: 0, animated: true)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: NSLocalizedString("发送", comment: ""), style: .plain, target: self, action: #selector(pressBtn(_:)))
    }
    
    @objc func pressBtn(_ sender: UIBarButtonItem) {
        let index = self.pickerView.selectedRow(inComponent: 0)
        let numberFormatter = NumberFormatter()
        let number = numberFormatter.number(from: self.titleArray[index])
        let value = number?.intValue ?? 0
        bleSelf.setWeather(temper: value, type: 1, max: value + 10, min: value - 10)
        Toast(text: "温度设置成功").show()
    }
    

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return titleArray.count
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        return NSMutableAttributedString.init(string: titleArray[row], attributes: stepAttributes)
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 53
    }

}
