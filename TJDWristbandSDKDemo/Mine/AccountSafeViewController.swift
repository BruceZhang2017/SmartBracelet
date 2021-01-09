//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  AccountSafeViewController.swift
//  TJDWristbandSDKDemo
//
//  Created by ANKER on 2020/10/7.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit

class AccountSafeViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
    }

}

extension AccountSafeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: .kCellIdentifier, for: indexPath) as! AccountSafeTableViewCell
        cell.titleLabel.text = titles[indexPath.row]
        cell.mSwitch.isHidden = indexPath.row != 5
        cell.valueLabel.isHidden = indexPath.row == 5
        cell.valueLabel.text = values[indexPath.row]
        cell.arrowImageView.isHidden = indexPath.row == 5
        cell.descLabel.isHidden = indexPath.row != 5
        cell.descLabel.text = indexPath.row == 5 ? "防止他人恶意登录，建议开启" : ""
        if indexPath.row == 0 {
            cell.valueLabel.text = UserManager.sharedInstall.user?.mobile ?? ""
        } else if indexPath.row == 1 {
            cell.valueLabel.text = UserManager.sharedInstall.user?.email ?? ""
        }
        return cell
    }
}

extension AccountSafeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 0 { // 绑定手机号
            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "BindPhoneNumViewController")
            navigationController?.pushViewController(vc, animated: true)
        } else if indexPath.row == 1 { // 绑定Email
            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "BindEmailViewController") as! BindEmailViewController
            vc.email = UserManager.sharedInstall.user?.email ?? ""
            navigationController?.pushViewController(vc, animated: true)
        } else if indexPath.row == 2 { // BindThreeViewController
            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "BindThreeViewController") as! BindThreeViewController
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .overFullScreen
            vc.type = 0
            navigationController?.present(vc, animated: true, completion: nil)  
        } else if indexPath.row == 3 { // QQ
            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "BindThreeViewController") as! BindThreeViewController
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .overFullScreen
            vc.type = 1
            navigationController?.present(vc, animated: true, completion: nil)
        } else if indexPath.row == 4 { // 密码修改
            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "ModifyPWDViewController")
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension AccountSafeViewController {
    var titles: [String] {
        return ["手机号", "邮件地址", "微信绑定", "QQ绑定", "密码修改", "账号保护"]
    }
    
    var values: [String] {
        return ["156XXXXXXXX", "未设置", "未绑定", "已绑定", "", ""]
    }
}
