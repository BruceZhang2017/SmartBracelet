//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  LoginViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/9/14.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit
import CountryPickerView
import SnapKit
import Toaster
import ProgressHUD
import Alamofire

class LoginViewController: BaseViewController {
    @IBOutlet weak var tipLabel: UILabel!
    @IBOutlet weak var tipBLabel: UILabel!
    @IBOutlet weak var countryLabel: UILabel!
    @IBOutlet weak var countryButton: UIButton!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var pwdTextField: UITextField!
    @IBOutlet weak var showButton: UIButton! // 显示密码修改为获取短信验证码 20200110
    @IBOutlet weak var loginButton: UIButton!
    var countryPickerView: CountryPickerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        countryPickerView = CountryPickerView(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
        countryPickerView.isHidden = true
        view.addSubview(countryPickerView)
        countryPickerView.dataSource = self
        countryPickerView.delegate = self
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func selectCountry(_ sender: Any) {
        countryPickerView.showCountriesList(from: navigationController!) // 跳转至选择国家界面
    }
    
    /// 密码是否显示
    @IBAction func showOrHidePwd(_ sender: Any) {
        //showButton.isSelected = !showButton.isSelected
        //pwdTextField.isSecureTextEntry = !showButton.isSelected
        Toast(text: "验证码已通过短信/邮件的方式发送，请注意查收").show()
    }
    
    /// 用户登录操作
    @IBAction func loginAccount(_ sender: Any) {
        phoneTextField.resignFirstResponder() // 1.先隐藏键盘
        pwdTextField.resignFirstResponder()
        let phone = phoneTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "" // 2.验证输入内容
        if phone.count == 0 {
            Toast(text: "请输入手机号/邮箱").show()
            return
        }
        let pwd = pwdTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if pwd.count == 0 || pwd != "1234" {
            Toast(text: "请输入验证码'1234'").show()
            return
        }
        let model = UserModel()
        model.mobile = phone
        UserManager.sharedInstall.user = model
        UserManager.sharedInstall.saveUser()
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.pushToTab()
        
//        ProgressHUD.show()
//        let parameters = ["username": phone, "password": pwd, "country": "CN"]
//        AF.request("\(UrlPrefix)api/User/login.php", method: .get, parameters: parameters).response { (response) in
//            debugPrint("Response: \(response.debugDescription)")
//            ProgressHUD.dismiss()
//            guard let data = response.value as? Data else {
//                return
//            }
//            let model = try? JSONDecoder().decode(LoginResponse.self, from: data)
//            if model == nil {
//                Toast(text: model?.message ?? "登录失败").show()
//                return
//            }
//            if model?.err_code ?? 0 == 0 {
//                Toast(text: model?.message ?? "登录成功").show()
//                UserManager.sharedInstall.user = model?.data
//                UserManager.sharedInstall.saveUser()
//                let delegate = UIApplication.shared.delegate as! AppDelegate
//                delegate.pushToTab()
//            } else {
//                Toast(text: model?.message ?? "登录失败").show()
//            }
//
//        }
     }
    
    
    
    @IBAction func register(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "RegisterViewController") as? RegisterViewController
        navigationController?.pushViewController(vc!, animated: true)
    }
}

extension LoginViewController: CountryPickerViewDelegate {
    func countryPickerView(_ countryPickerView: CountryPickerView, didSelectCountry country: Country) {
        countryButton.setTitle(country.name, for: .normal)
    }
}

extension LoginViewController: CountryPickerViewDataSource {
    func preferredCountries(in countryPickerView: CountryPickerView) -> [Country] {
        return []
    }
    
    func sectionTitleForPreferredCountries(in countryPickerView: CountryPickerView) -> String? {
        return nil
    }
    
    func showOnlyPreferredSection(in countryPickerView: CountryPickerView) -> Bool {
        return false
    }
    
    func navigationTitle(in countryPickerView: CountryPickerView) -> String? {
        return "Select a Country"
    }
        
    func searchBarPosition(in countryPickerView: CountryPickerView) -> SearchBarPosition {
        return .tableViewHeader
    }
    
    func showPhoneCodeInList(in countryPickerView: CountryPickerView) -> Bool {
        return false
    }
    
    func showCountryCodeInList(in countryPickerView: CountryPickerView) -> Bool {
       return true
    }
}
