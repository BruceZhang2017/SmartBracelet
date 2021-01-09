//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  BindEmailViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/10/7.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit
import Toaster
import Alamofire

class BindEmailViewController: BaseViewController {
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    var email = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailTextField.text = email
    }
    

    @IBAction func submit(_ sender: Any) {
        guard let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), email.count > 0 else {
            Toast(text: "请输入邮箱").show()
            return
        }
        if !email.validateEmail() {
            Toast(text: "邮箱输入有误").show()
            return
        }
        UserManager.sharedInstall.user?.email = email
        UserManager.sharedInstall.saveUser()
        //ProgressHUD.show()
        var parameters = ["id": "\(UserManager.sharedInstall.user?.id ?? 0)"]
        parameters["email"] = email
        AF.request("\(UrlPrefix)api/User/userinfo.php", method: .post, parameters: parameters, encoder: URLEncodedFormParameterEncoder.default).response { (response) in
            //debugPrint("Response: \(response.debugDescription)")
            //ProgressHUD.dismiss()
//            guard let data = response.value as? Data else {
//                return
//            }
//            let model = try? JSONDecoder().decode(BaseResponse.self, from: data)
//            if model == nil {
//                Toast(text: model?.message ?? "注册失败").show()
//                return
//            }
            
        }
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func cancel(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
}
