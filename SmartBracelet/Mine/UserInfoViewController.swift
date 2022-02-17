//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  UserInfoViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/8/17.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit
import Kingfisher
import Alamofire
import TJDWristbandSDK
import Toaster

class UserInfoViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    var itemVC: SelectItemViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "mine_userinfo".localized()
        registerNotification()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    deinit {
        unregisterNotification()
    }
    
    private func registerNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: Notification.Name("UserInfo"), object: nil)
    }
    
    private func unregisterNotification() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleNotification(_ notification: Notification) {
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
            let fileName = "head.jpg"
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
            if UserManager.sharedInstall.user?.token == nil {
                let name = UserDefaults.standard.string(forKey: "NickName")
                if name?.count ?? 0 > 0 {
                    cell.valueLabel.text = name
                } else {
                    cell.valueLabel.text = bleSelf.userInfo.name
                }
            } else {
                cell.valueLabel.text = UserManager.sharedInstall.user?.nickname ?? "未设置"
            }
            
//        } else if indexPath.row == 2 {
//            if UserManager.sharedInstall.user?.token == nil {
//                cell.valueLabel.text = bleSelf.userInfo.name
//            } else {
//                cell.valueLabel.text = UserManager.sharedInstall.user?.username ?? ""
//            }
            
        } else if indexPath.row == 2 {
            if UserManager.sharedInstall.user?.token == nil {
                cell.valueLabel.text = bleSelf.userInfo.sex == 1 ? "mine_male".localized() : "mine_female".localized()
            } else {
                cell.valueLabel.text = (UserManager.sharedInstall.user?.sex ?? 0 == 0) ? "mine_male".localized() : "mine_female".localized()
            }
            
        } else if indexPath.row == 3 {
            if UserManager.sharedInstall.user?.token == nil {
                let value = UserDefaults.standard.string(forKey: "Birthday")
                if value?.count ?? 0 > 0 {
                    cell.valueLabel.text = value
                } else {
                    cell.valueLabel.text = WUDate.dateFromTimeStamp(bleSelf.userInfo.birthday).stringFromYmd()
                }
                
            } else {
                cell.valueLabel.text = UserManager.sharedInstall.user?.birthday ?? ""
            }
        } else if indexPath.row == 4 {
            if UserManager.sharedInstall.user?.token == nil {
                cell.valueLabel.text = "\(bleSelf.userInfo.height)CM"
            } else {
                cell.valueLabel.text = "\(UserManager.sharedInstall.user?.height ?? 0)CM"
            }
        } else if indexPath.row == 5 {
            if UserManager.sharedInstall.user?.token == nil {
                cell.valueLabel.text = "\(bleSelf.userInfo.weight)KG"
            } else {
                cell.valueLabel.text = "\(UserManager.sharedInstall.user?.weight ?? 0)KG"
            }
//        } else if indexPath.row == 7 {
//            cell.valueLabel.text = UserManager.sharedInstall.user?.area ?? ""
        } else if indexPath.row == 6 {
            cell.valueLabel.text = bleSelf.userInfo.timeUnit == 0 ? "24小时" : "12小时"
        } else if indexPath.row == 7 {
            cell.valueLabel.text = bleSelf.userInfo.unit == 0 ? "cm,kg" : "ft-in,lb"
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
//            if UserManager.sharedInstall.user?.token == nil {
//                Toast(text: "服务器不可用").show()
//                return
//            }
            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "ModifyHeadViewController")
            navigationController?.pushViewController(vc, animated: true)
        } else if indexPath.row == 1 { // 昵称
            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "NickNameViewController")
            navigationController?.pushViewController(vc, animated: true)
//        } else if indexPath.row == 2 { // 姓名
//            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
//            let vc = storyboard.instantiateViewController(withIdentifier: "NickNameViewController") as! NickNameViewController
//            vc.type = 1
//            navigationController?.pushViewController(vc, animated: true)
        } else if indexPath.row == 2 { // 性别
            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "SelectSexViewController") as! SelectSexViewController
            vc.delegate = self
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .overFullScreen
            vc.sex = (bleSelf.userInfo.sex) == 0 ? "mine_male".localized() : "mine_female".localized()
            navigationController?.present(vc, animated: true, completion: nil)
        } else if indexPath.row == 3 { // 出生年月
            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "SelectSexViewController") as! SelectSexViewController
            vc.delegate = self
            var birth = ""
            let value = UserDefaults.standard.string(forKey: "Birthday") ?? ""
            if value.count > 0 {
                birth = value
            } else {
                birth = WUDate.dateFromTimeStamp(bleSelf.userInfo.birthday).stringFromYmd()
            }
            vc.birth = birth.components(separatedBy: "-")
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .overFullScreen
            vc.type = 1
            navigationController?.present(vc, animated: true, completion: nil)
        } else if indexPath.row == 4 {
            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "InputHeightViewController") as! InputHeightViewController
            vc.delegate = self
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .overFullScreen
            vc.type = 0
            vc.value = "\(bleSelf.userInfo.height)"
            navigationController?.present(vc, animated: true, completion: nil)
        } else if indexPath.row == 5 {
            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "InputHeightViewController") as! InputHeightViewController
            vc.delegate = self
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .overFullScreen
            vc.type = 1
            vc.value = "\(bleSelf.userInfo.weight)"
            navigationController?.present(vc, animated: true, completion: nil)
//        } else {
//            let vc = CitySelectorViewController()
//            vc.delegate = self
//            navigationController?.pushViewController(vc, animated: true)
        } else if indexPath.row == 6 { // 时间制
            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
            itemVC = storyboard.instantiateViewController(withIdentifier: "SelectItemViewController") as? SelectItemViewController
            itemVC?.delegate = self
            itemVC?.modalTransitionStyle = .crossDissolve
            itemVC?.modalPresentationStyle = .overFullScreen
            itemVC?.index = 0
            itemVC?.type = 0
            itemVC?.titles = ["24小时制", "12小时制"]
            itemVC?.titleStr = "时间制"
            navigationController?.present(itemVC!, animated: false, completion: nil)
        } else if indexPath.row == 7 { // 单位
            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
            itemVC = storyboard.instantiateViewController(withIdentifier: "SelectItemViewController") as? SelectItemViewController
            itemVC?.delegate = self
            itemVC?.modalTransitionStyle = .crossDissolve
            itemVC?.modalPresentationStyle = .overFullScreen
            itemVC?.index = 0
            itemVC?.type = 1
            itemVC?.titles = ["cm,kg" , "ft-in,lb"]
            itemVC?.titleStr = "单位"
            navigationController?.present(itemVC!, animated: false, completion: nil)
        }
    }
}

extension UserInfoViewController {
    var titles: [String] {
        return ["mine_head_image".localized(), "mine_nick".localized(), "mine_sex".localized(), "mine_birthday".localized(), "mine_height".localized(), "mine_weight".localized(), "时间制", "单位"]
    }
    
    var values: [String] {
        return ["", "未设置", "mine_male".localized(), "19XX年XX月XX日", "168CM", "45KG", "24小时", "cm,kg"]
    }
}

extension UserInfoViewController: SelectSexVCDelegate {
    func callback(type: Int, value: String) {
        if type == 0 {
            UserManager.sharedInstall.user?.sex = value == "mine_male".localized() ? 0 : 1
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
            let sex = value == "mine_male".localized() ? 0 : 1
            parameters["sex"] = "\(sex)"
            if UserManager.sharedInstall.user?.token == nil {
                bleSelf.userInfo.sex = sex == 0 ? 1 : 0
                bleSelf.setUserinfoForWristband(bleSelf.userInfo)
                return
            }
        } else if type == 1 {
            parameters["birthday"] = value
            UserDefaults.standard.setValue(value, forKey: "Birthday")
            UserDefaults.standard.synchronize()
            if UserManager.sharedInstall.user?.token == nil {
                bleSelf.userInfo.birthday = Int(DateHelper().ymdToDate(value: value).timeIntervalSince1970)
                bleSelf.setUserinfoForWristband(bleSelf.userInfo)
                return
            }
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
            if UserManager.sharedInstall.user?.token == nil {
                bleSelf.userInfo.height = Double(value)
                bleSelf.setUserinfoForWristband(bleSelf.userInfo)
                return
            }
        } else if type == 1 {
            parameters["weight"] = "\(value)"
            if UserManager.sharedInstall.user?.token == nil {
                bleSelf.userInfo.weight = Double(value)
                bleSelf.setUserinfoForWristband(bleSelf.userInfo)
                return
            }
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

extension UserInfoViewController: SelectItemVCDelegate {
    func callback(type: Int, index: Int, value: String) {
        if type == 1 {
            bleSelf.userInfo.unit = index
            bleSelf.setZhiShiForWristband(bleSelf.userInfo)
            tableView.reloadData()
            return
        }
        bleSelf.userInfo.timeUnit = index
        bleSelf.setZhiShiForWristband(bleSelf.userInfo)
        tableView.reloadData()
    }
}
