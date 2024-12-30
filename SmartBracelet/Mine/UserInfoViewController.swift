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
        view.backgroundColor = UIColor.clear
        title = "mine_userinfo".localized()
        registerNotification()
        tableView.backgroundColor = UIColor.clear
        tableView.separatorStyle = .none
        tableView.separatorColor = UIColor.red
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
        cell.backgroundColor = UIColor.clear
        cell.lineImageView.backgroundColor = UIColor(hex: 0x000000, alpha: 0.06)
        if indexPath.row == 3 && isXGZT {
            cell.titleLabel.text = "age".localized()
        } else {
            cell.titleLabel.text = titles[indexPath.row]
        }
        cell.titleLabel.textColor = UIColor.text_primary
        cell.titleLabel.font = UIFont.body1()
        cell.iconImageView.isHidden = indexPath.row != 0
        cell.valueLabel.isHidden = indexPath.row == 0
        cell.valueLabel.text = values[indexPath.row]
        cell.valueLabel.textColor = UIColor.brand
        cell.valueLabel.font = UIFont.body1()
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
                cell.valueLabel.text = UserManager.sharedInstall.user?.nickname ?? ""
            }
        } else if indexPath.row == 2 {
            if UserManager.sharedInstall.user?.token == nil {
                if isXGZT {
                    cell.valueLabel.text = (XGZTBlueToothManager.shared.device?.sex ?? 0) == 0 ? "mine_male".localized() : "mine_female".localized()
                } else {
                    cell.valueLabel.text = bleSelf.userInfo.sex == 1 ? "mine_male".localized() : "mine_female".localized()
                }
            } else {
                cell.valueLabel.text = (UserManager.sharedInstall.user?.sex ?? 0 == 0) ? "mine_male".localized() : "mine_female".localized()
            }
            
        } else if indexPath.row == 3 {
            if UserManager.sharedInstall.user?.token == nil {
                if isXGZT {
                    cell.valueLabel.text = "\(XGZTBlueToothManager.shared.device?.age ?? 0)"
                } else {
                    let value = UserDefaults.standard.string(forKey: "Birthday")
                    if value?.count ?? 0 > 0 {
                        cell.valueLabel.text = value
                    } else {
                        cell.valueLabel.text = WUDate.dateFromTimeStamp(bleSelf.userInfo.birthday).stringFromYmd()
                    }
                }
            } else {
                cell.valueLabel.text = UserManager.sharedInstall.user?.birthday ?? ""
            }
        } else if indexPath.row == 4 {
            if UserManager.sharedInstall.user?.token == nil {
                if isXGZT {
                    cell.valueLabel.text = "\(XGZTBlueToothManager.shared.device?.height ?? 0)CM"
                } else {
                    cell.valueLabel.text = "\(bleSelf.userInfo.height)CM"
                }
            } else {
                cell.valueLabel.text = "\(UserManager.sharedInstall.user?.height ?? 0)CM"
            }
        } else if indexPath.row == 5 {
            if UserManager.sharedInstall.user?.token == nil {
                if isXGZT {
                    cell.valueLabel.text = "\(XGZTBlueToothManager.shared.device?.weight ?? 0)CM"
                } else {
                    cell.valueLabel.text = "\(bleSelf.userInfo.weight)KG"
                }
            } else {
                cell.valueLabel.text = "\(UserManager.sharedInstall.user?.weight ?? 0)KG"
            }
        } else if indexPath.row == 6 {
            if isXGZT {
                cell.valueLabel.text = XGZTBlueToothManager.shared.device?.timeUnit == 1 ? "24\("health_hour".localized())" : "12\("health_hour".localized())"
            } else {
                cell.valueLabel.text = bleSelf.userInfo.timeUnit == 0 ? "24\("health_hour".localized())" : "12\("health_hour".localized())"
            }
        } else if indexPath.row == 7 {
            if isXGZT {
                cell.valueLabel.text = XGZTBlueToothManager.shared.device?.baseUnit == 0 ? "cm,kg" : "ft-in,lb"
            } else {
                cell.valueLabel.text = bleSelf.userInfo.unit == 0 ? "cm,kg" : "ft-in,lb"
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.row == 0 ? 88 : 60
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
        } else if indexPath.row == 2 { // 性别
            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "SelectSexViewController") as! SelectSexViewController
            vc.delegate = self
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .overFullScreen
            if isXGZT {
                vc.sex = (XGZTBlueToothManager.shared.device?.sex ?? 0) == 0 ? "mine_male".localized() : "mine_female".localized()
            } else {
                vc.sex = (bleSelf.userInfo.sex) == 0 ? "mine_male".localized() : "mine_female".localized()
            }
            navigationController?.present(vc, animated: true, completion: nil)
        } else if indexPath.row == 3 { // 出生年月
            if isXGZT {
                let storyboard = UIStoryboard(name: .kMine, bundle: nil)
                itemVC = storyboard.instantiateViewController(withIdentifier: "SelectItemViewController") as? SelectItemViewController
                itemVC?.delegate = self
                itemVC?.modalTransitionStyle = .crossDissolve
                itemVC?.modalPresentationStyle = .overFullScreen
                itemVC?.index = (XGZTBlueToothManager.shared.device?.age ?? 0) - 1
                itemVC?.type = 2
                itemVC?.titles = (1...100).map { String($0) }
                itemVC?.titleStr = "age".localized()
                navigationController?.present(itemVC!, animated: false, completion: nil)
            } else {
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
            }
            
        } else if indexPath.row == 4 {
            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "InputHeightViewController") as! InputHeightViewController
            vc.delegate = self
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .overFullScreen
            vc.type = 0
            if isXGZT {
                vc.value = "\(XGZTBlueToothManager.shared.device?.height ?? 0)"
            } else {
                vc.value = "\(bleSelf.userInfo.height)"
            }
            navigationController?.present(vc, animated: true, completion: nil)
        } else if indexPath.row == 5 {
            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "InputHeightViewController") as! InputHeightViewController
            vc.delegate = self
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .overFullScreen
            vc.type = 1
            if isXGZT {
                vc.value = "\(XGZTBlueToothManager.shared.device?.weight ?? 0)"
            } else {
                vc.value = "\(bleSelf.userInfo.weight)"
            }
            navigationController?.present(vc, animated: true, completion: nil)

        } else if indexPath.row == 6 { // 时间制
            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
            itemVC = storyboard.instantiateViewController(withIdentifier: "SelectItemViewController") as? SelectItemViewController
            itemVC?.delegate = self
            itemVC?.modalTransitionStyle = .crossDissolve
            itemVC?.modalPresentationStyle = .overFullScreen
            itemVC?.index = 0
            itemVC?.type = 0
            itemVC?.titles = ["24", "12"]
            itemVC?.titleStr = "time_system".localized()
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
            itemVC?.titleStr = "unit".localized()
            navigationController?.present(itemVC!, animated: false, completion: nil)
        }
    }
}

extension UserInfoViewController {
    var titles: [String] {
        return ["mine_head_image".localized(), "mine_nick".localized(), "mine_sex".localized(), "mine_birthday".localized(), "mine_height".localized(), "mine_weight".localized(), "time_system".localized(), "unit".localized()]
    }
    
    var values: [String] {
        return ["", "未设置", "mine_male".localized(), "19XX-XX-XX", "168CM", "45KG", "24\("health_hour".localized())", "cm,kg"]
    }
}

extension UserInfoViewController: SelectSexVCDelegate {
    func callback(type: Int, value: String) {
        if type == 0 {
            if isXGZT {
                XGZTBlueToothManager.shared.device?.sex = value == "mine_male".localized() ? 0 : 1
            } else {
                UserManager.sharedInstall.user?.sex = value == "mine_male".localized() ? 0 : 1
            }
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
        if type == 0 {
            let sex = value == "mine_male".localized() ? 0 : 1
            if isXGZT {
                UserManager.sharedInstall.user?.sex = sex
                XGZTCommand.setPersonalInfo(sex: XGZTBlueToothManager.shared.device?.sex ?? 0, age: XGZTBlueToothManager.shared.device?.age ?? 0, height: XGZTBlueToothManager.shared.device?.height ?? 0, weight: XGZTBlueToothManager.shared.device?.weight ?? 0)
                return
            }
            if UserManager.sharedInstall.user?.token == nil {
                bleSelf.userInfo.sex = sex == 0 ? 1 : 0
                bleSelf.setUserinfoForWristband(bleSelf.userInfo)
            }
        } else if type == 1 {
            UserDefaults.standard.setValue(value, forKey: "Birthday")
            UserDefaults.standard.synchronize()
            if UserManager.sharedInstall.user?.token == nil {
                bleSelf.userInfo.birthday = Int(DateHelper().ymdToDate(value: value).timeIntervalSince1970)
                bleSelf.setUserinfoForWristband(bleSelf.userInfo)
            }
        }
    }
}

extension UserInfoViewController: InputHeightVCDelegate {
    func callback(type: Int, value: Int) {
        if type == 0 {
            if isXGZT {
                XGZTBlueToothManager.shared.device?.height = value
            } else {
                UserManager.sharedInstall.user?.height = value
                XGZTCommand.setPersonalInfo(sex: XGZTBlueToothManager.shared.device?.sex ?? 0, age: XGZTBlueToothManager.shared.device?.age ?? 0, height: XGZTBlueToothManager.shared.device?.height ?? 0, weight: XGZTBlueToothManager.shared.device?.weight ?? 0)
            }
            
        } else {
            if isXGZT {
                XGZTBlueToothManager.shared.device?.weight = value
            } else {
                UserManager.sharedInstall.user?.weight = value
                XGZTCommand.setPersonalInfo(sex: XGZTBlueToothManager.shared.device?.sex ?? 0, age: XGZTBlueToothManager.shared.device?.age ?? 0, height: XGZTBlueToothManager.shared.device?.height ?? 0, weight: XGZTBlueToothManager.shared.device?.weight ?? 0)
            }
        }
        if !isXGZT {
            UserManager.sharedInstall.saveUser()
            uploadData(type: type, value: value)
        }
        
        tableView.reloadData()
        
    }
}

extension UserInfoViewController {
    func uploadData(type: Int, value: Int) {
        if type == 0 {
            if UserManager.sharedInstall.user?.token == nil {
                bleSelf.userInfo.height = Double(value)
                bleSelf.setUserinfoForWristband(bleSelf.userInfo)
                return
            }
        } else if type == 1 {
            if UserManager.sharedInstall.user?.token == nil {
                bleSelf.userInfo.weight = Double(value)
                bleSelf.setUserinfoForWristband(bleSelf.userInfo)
                return
            }
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

    }
}

extension UserInfoViewController: SelectItemVCDelegate {
    func callback(type: Int, index: Int, value: String) {
        if type == 2 {
            if isXGZT {
                XGZTBlueToothManager.shared.device?.age = Int(value) ?? 0
                XGZTCommand.setPersonalInfo(sex: XGZTBlueToothManager.shared.device?.sex ?? 0, age: XGZTBlueToothManager.shared.device?.age ?? 0, height: XGZTBlueToothManager.shared.device?.height ?? 0, weight: XGZTBlueToothManager.shared.device?.weight ?? 0)
            }
            tableView.reloadData()
            return
        }
        if type == 1 {
            if isXGZT {
                XGZTBlueToothManager.shared.device?.baseUnit = index
                XGZTCommand.setDeviceUnitFormat(unitType: index)
            } else {
                bleSelf.userInfo.unit = index
                bleSelf.setZhiShiForWristband(bleSelf.userInfo)
            }
            tableView.reloadData()
            return
        }
        if isXGZT {
            XGZTBlueToothManager.shared.device?.timeUnit = index == 1 ? 0 : 1
            XGZTCommand.set12H24HTimeFormat(format: index == 1 ? 0 : 1)
        } else {
            bleSelf.userInfo.timeUnit = index
            bleSelf.setZhiShiForWristband(bleSelf.userInfo)
        }
        tableView.reloadData()
    }
}
