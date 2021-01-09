//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  RegisterViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/9/14.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit
import Toaster
import ProgressHUD
import Alamofire

let UrlPrefix = "http://8.129.113.186/sinophy.com/"

class RegisterViewController: BaseViewController {
    @IBOutlet weak var tipLabel: UILabel!
    @IBOutlet weak var tipBLabel: UILabel!
    @IBOutlet weak var countryLabel: UILabel!
    @IBOutlet weak var countryButton: UIButton!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var pwdTextField: UITextField!
    @IBOutlet weak var showButton: UIButton!
    @IBOutlet weak var showBButton: UIButton!
    @IBOutlet weak var rePwdTextField: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "注册"
    }
    
    @IBAction func selectCountry(_ sender: Any) {
        
    }
    
    @IBAction func showOrHidePwd(_ sender: Any) {
        let btn = sender as! UIButton
        if btn == showButton {
            pwdTextField.isSecureTextEntry = !pwdTextField.isSecureTextEntry
            showButton.isSelected = !showButton.isSelected
        } else {
            rePwdTextField.isSecureTextEntry = !rePwdTextField.isSecureTextEntry
            showBButton.isSelected = !showBButton.isSelected
        }
    }
    
    @IBAction func registerAccount(_ sender: Any) {
        guard let username = phoneTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), username.count >= 8 else {
            Toast(text: "请输入有效的用户名/手机号/邮箱").show()
            return
        }
        guard let password = pwdTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), password.count >= 8 else {
            Toast(text: "密码不能为空，或长度不能小于8").show()
            return
        }
        guard let pwd = rePwdTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), password == pwd else {
            Toast(text: "二次密码不一致").show()
            return
        }
        ProgressHUD.show()
        let parameters = ["username": username, "password": password, "country": "CN"]
        AF.request("\(UrlPrefix)api/User/signup.php", method: .post, parameters: parameters, encoder: URLEncodedFormParameterEncoder.default).response { [weak self] (response) in
            debugPrint("Response: \(response.debugDescription)")
            ProgressHUD.dismiss()
            guard let data = response.value as? Data else {
                return
            }
            let model = try? JSONDecoder().decode(RegisterResponse.self, from: data)
            if model == nil {
                Toast(text: model?.message ?? "注册失败").show()
                return
            }
            if model?.err_code ?? 0 == 0 {
                Toast(text: model?.message ?? "注册成功").show()
                self?.navigationController?.popViewController(animated: true)
            } else {
                Toast(text: model?.message ?? "注册失败").show()
            }
            
        }
    }
    
    
}
