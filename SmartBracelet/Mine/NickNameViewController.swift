//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  NickNameViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/9/6.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit
import Toaster
import ProgressHUD
import Alamofire

class NickNameViewController: BaseViewController {
    var rightButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var countLabel: UILabel!
    var type = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        rightButton = UIButton(type: .custom).then {
            $0.setTitleColor(.k64F2B4, for: .normal)
            $0.titleLabel?.font = UIFont.systemFont(ofSize: 15)
            $0.setTitle("mine_save".localized(), for: .normal)
            $0.addTarget(self, action: #selector(save), for: .touchUpInside)
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightButton)
        setupValue()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if type == 0 {
            let name = UserDefaults.standard.string(forKey: "NickName")
            if name?.count ?? 0 > 0 {
                textView.text = name
            } else {
                textView.text = bleSelf.userInfo.name
            }
        } else if type == 1 {
            textView.text = UserManager.sharedInstall.user?.username ?? ""
        }
        countLabel.text = "mine_insert_num_limit".localized().replacingOccurrences(of: "XX", with: "\(15 - textView.text.count)")
    }
    
    private func setupValue() {
        if type == 0 {
            title = "mine_nick".localized()
        } else if type == 1 {
            title = "姓名"
        }
    }

    @objc private func save() {
        let name = textView.text.trimmingCharacters(in: .whitespacesAndNewlines) 
        if name.count == 0 {
            Toast(text: "help_center_text_tip".localized()).show()
            return
        }
        if UserManager.sharedInstall.user?.token == nil {
            bleSelf.userInfo.name = name
            UserDefaults.standard.setValue(name, forKey: "NickName")
            UserDefaults.standard.synchronize()
            bleSelf.setUserinfoForWristband(bleSelf.userInfo)
            NotificationCenter.default.post(name: Notification.Name("UserInfo"), object: nil)
            navigationController?.popViewController(animated: true)
            return
        }
        uploadData(name: name)
        if type == 0 {
            UserManager.sharedInstall.user?.nickname = name
            UserManager.sharedInstall.saveUser()
        } else if type == 1 {
            UserManager.sharedInstall.user?.username = name
            UserManager.sharedInstall.saveUser()
        }
        NotificationCenter.default.post(name: Notification.Name("UserInfo"), object: nil)
        navigationController?.popViewController(animated: true)
    }
    
    private func uploadData(name: String) {
        //ProgressHUD.show()
        var parameters = ["id": "\(UserManager.sharedInstall.user?.id ?? 0)"]
        if type == 0 {
            parameters["nickname"] = name
        } else if type == 1 {
            parameters["username"] = name
        }
//        AF.request("\(UrlPrefix)api/User/userinfo.php", method: .post, parameters: parameters, encoder: URLEncodedFormParameterEncoder.default).response { (response) in
//            debugPrint("Response: \(response.debugDescription)")
//            //ProgressHUD.dismiss()
////            guard let data = response.value as? Data else {
////                return
////            }
////            let model = try? JSONDecoder().decode(BaseResponse.self, from: data)
////            if model == nil {
////                Toast(text: model?.message ?? "注册失败").show()
////                return
////            }
//            
//        }
    }
}

extension NickNameViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if textView.text.lengthOfBytes(using: .utf8) > 0 {
            
        } else {
            
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            // 删除安全
        if text == "" && range.length > 0 {
            return true
        }
        countLabel.text = "mine_insert_num_limit".localized().replacingOccurrences(of: "XX", with: "\(15 - textView.text.count)")
        if textView.text.count > 15 {
            return false
        }
        return true
    }
}
