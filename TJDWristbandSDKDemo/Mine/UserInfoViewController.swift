//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  UserInfoViewController.swift
//  TJDWristbandSDKDemo
//
//  Created by ANKER on 2020/8/17.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit
import Kingfisher
import Alamofire

class UserInfoViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "个人信息"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

}

extension UserInfoViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: .kCellIdentifier, for: indexPath) as! UserInfoTableViewCell
        cell.titleLabel.text = titles[indexPath.row]
        cell.iconImageView.isHidden = indexPath.row != 0
        cell.valueLabel.isHidden = indexPath.row == 0
        cell.valueLabel.text = values[indexPath.row]
        if indexPath.row == 0 {
            let fileName = "head\(UserManager.sharedInstall.user?.id ?? 0).jpg"
            let b = FileCache().fileIfExist(name: fileName)
            if b {
                let data = FileCache().readData(name: fileName)
                cell.iconImageView.image = UIImage(data: data)
            } else {
                let url = UserManager.sharedInstall.user?.headUrl ?? ""
                if url.count > 0 && url.hasPrefix("http") {
                    cell.iconImageView.kf.setImage(with: URL(string: url)!)
                } else {
                    cell.iconImageView.image = UIImage(named: "image_portrait")
                }
            }
        } else if indexPath.row == 1 {
            cell.valueLabel.text = UserManager.sharedInstall.user?.nickname ?? "未设置"
        } else if indexPath.row == 2 {
            cell.valueLabel.text = UserManager.sharedInstall.user?.username ?? ""
        } else if indexPath.row == 3 {
            cell.valueLabel.text = (UserManager.sharedInstall.user?.sex ?? 0 == 0) ? "男" : "女"
        } else if indexPath.row == 4 {
            cell.valueLabel.text = UserManager.sharedInstall.user?.birthday ?? ""
        } else if indexPath.row == 5 {
            cell.valueLabel.text = "\(UserManager.sharedInstall.user?.height ?? 0)CM"
        } else if indexPath.row == 6 {
            cell.valueLabel.text = "\(UserManager.sharedInstall.user?.weight ?? 0)KG"
        } else if indexPath.row == 7 {
            cell.valueLabel.text = UserManager.sharedInstall.user?.area ?? ""
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.row == 0 ? 78 : 48
    }
}

extension UserInfoViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 0 { // 头像
            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "ModifyHeadViewController")
            navigationController?.pushViewController(vc, animated: true)
        } else if indexPath.row == 1 { // 昵称
            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "NickNameViewController")
            navigationController?.pushViewController(vc, animated: true)
        } else if indexPath.row == 2 { // 姓名
            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "NickNameViewController") as! NickNameViewController
            vc.type = 1
            navigationController?.pushViewController(vc, animated: true)
        } else if indexPath.row == 3 { // 性别
            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "SelectSexViewController") as! SelectSexViewController
            vc.delegate = self
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .overFullScreen
            vc.sex = (UserManager.sharedInstall.user?.sex ?? 0) == 0 ? "男" : "女"
            navigationController?.present(vc, animated: true, completion: nil)
        } else if indexPath.row == 4 { // 出生年月
            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "SelectSexViewController") as! SelectSexViewController
            vc.delegate = self
            if let birth = UserManager.sharedInstall.user?.birthday, birth.count > 0 {
                vc.birth = birth.components(separatedBy: "-")
            }
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .overFullScreen
            vc.type = 1
            navigationController?.present(vc, animated: true, completion: nil)
        } else if indexPath.row == 5 {
            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "InputHeightViewController") as! InputHeightViewController
            vc.delegate = self
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .overFullScreen
            vc.type = 0
            vc.value = "\(UserManager.sharedInstall.user?.height ?? 0)"
            navigationController?.present(vc, animated: true, completion: nil)
        } else if indexPath.row == 6 {
            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "InputHeightViewController") as! InputHeightViewController
            vc.delegate = self
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .overFullScreen
            vc.type = 1
            vc.value = "\(UserManager.sharedInstall.user?.weight ?? 0)"
            navigationController?.present(vc, animated: true, completion: nil)
        } else {
            let vc = CitySelectorViewController()
            vc.delegate = self
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension UserInfoViewController {
    var titles: [String] {
        return ["头像", "昵称", "姓名", "性别", "出生年月", "身高", "体重", "地区"]
    }
    
    var values: [String] {
        return ["", "未设置", "张XX", "男", "19XX年XX月XX日", "168CM", "45KG", "当前位置"]
    }
}

extension UserInfoViewController: SelectSexVCDelegate {
    func callback(type: Int, value: String) {
        if type == 0 {
            UserManager.sharedInstall.user?.sex = value == "男" ? 0 : 1
        } else {
            UserManager.sharedInstall.user?.birthday = value
        }
        UserManager.sharedInstall.saveUser()
        tableView.reloadData()
        uploadData(type: type, value: value)
    }
}

extension UserInfoViewController {
    func uploadData(type: Int, value: String) {
        //ProgressHUD.show()
        var parameters = ["id": "\(UserManager.sharedInstall.user?.id ?? 0)"]
        if type == 0 {
            let sex = value == "男" ? 0 : 1
            parameters["sex"] = "\(sex)"
        } else if type == 1 {
            parameters["birthday"] = value
        }
        AF.request("\(UrlPrefix)api/User/userinfo.php", method: .post, parameters: parameters, encoder: URLEncodedFormParameterEncoder.default).response { (response) in
            debugPrint("Response: \(response.debugDescription)")
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
    }
}

extension UserInfoViewController: InputHeightVCDelegate {
    func callback(type: Int, value: Int) {
        if type == 0 {
            UserManager.sharedInstall.user?.height = value
        } else {
            UserManager.sharedInstall.user?.weight = value
        }
        UserManager.sharedInstall.saveUser()
        tableView.reloadData()
        uploadData(type: type, value: value)
    }
}

extension UserInfoViewController {
    func uploadData(type: Int, value: Int) {
        //ProgressHUD.show()
        var parameters = ["id": "\(UserManager.sharedInstall.user?.id ?? 0)"]
        if type == 0 {
            parameters["height"] = "\(value)"
        } else if type == 1 {
            parameters["weight"] = "\(value)"
        }
        AF.request("\(UrlPrefix)api/User/userinfo.php", method: .post, parameters: parameters, encoder: URLEncodedFormParameterEncoder.default).response { (response) in
            debugPrint("Response: \(response.debugDescription)")
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
    }
}

extension UserInfoViewController: CitySelectorVCDelegate {
    func callback(_ city: String) {
        UserManager.sharedInstall.user?.area = city
        UserManager.sharedInstall.saveUser()
        tableView.reloadData()
        uploadData(city: city)
    }
}

extension UserInfoViewController {
    func uploadData(city: String) {
        //ProgressHUD.show()
        var parameters = ["id": "\(UserManager.sharedInstall.user?.id ?? 0)"]
        parameters["area"] = city
        AF.request("\(UrlPrefix)api/User/userinfo.php", method: .post, parameters: parameters, encoder: URLEncodedFormParameterEncoder.default).response { (response) in
            debugPrint("Response: \(response.debugDescription)")
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
    }
}
