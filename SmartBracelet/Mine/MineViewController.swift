//
// Copyright © 2015-2018 bruce Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  MineViewController.swift
//  SmartBracelet
//
//  Created by bruce on 2020/8/17.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit
import Toaster

class MineViewController: BaseViewController {
    
    let tableView = UITableView(frame: .zero, style: .plain)
    let headerView = UIView()
    let profileImageView = UIImageView()
    let nicknameButton = UIButton()
    var bOnce = false
    let titles = ["mine_userinfo".localized(), "mine_help_center".localized(), "mine_about".localized()]
    let icons = [UIImage(named: "mine_account_info"), UIImage(named: "mine_help"), UIImage(named: "mine_account_about")]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "mine".localized()
        
        // 设置tableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
               
        // 设置headerView
        headerView.bounds = CGRect(x: 0, y: 0, width: view.frame.width, height: 170)
               
        // 计算profileImageView的位置和大小
        let profileImageSize: CGFloat = 94
        let profileImageViewX = (headerView.bounds.width - profileImageSize) / 2 // 水平居中
        let profileImageViewY: CGFloat = 15 // 顶部间隔
        profileImageView.frame = CGRect(x: profileImageViewX, y: profileImageViewY, width: profileImageSize, height: profileImageSize)
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
        profileImageView.clipsToBounds = true
        profileImageView.image = UIImage(named: "mine_header")
        headerView.addSubview(profileImageView)

        // 计算nicknameButton的位置和大小
        let nicknameButtonHeight: CGFloat = 30
        let nicknameButtonWidth: CGFloat = 200 // 或者可以使用sizeToFit()来根据内容调整宽度
        let nicknameButtonX = (headerView.bounds.width - nicknameButtonWidth) / 2 // 水平居中
        let nicknameButtonY = profileImageView.frame.maxY + 10 // 在profileImageView下方间隔10
        nicknameButton.frame = CGRect(x: nicknameButtonX, y: nicknameButtonY, width: nicknameButtonWidth, height: nicknameButtonHeight)
        nicknameButton.setTitle("person_info".localized(), for: .normal)
        nicknameButton.setTitleColor(.brand, for: .normal)
        nicknameButton.titleLabel?.font = UIFont.body1()
        headerView.addSubview(nicknameButton)
        headerView.backgroundColor = UIColor.clear
        view.addSubview(headerView)
        
        headerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 170),
            headerView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor)
        ])
        
        // 将headerView设置为tableView的header
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.white
        // 设置tableView的布局约束
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: headerView.safeAreaLayoutGuide.bottomAnchor),
            tableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor)
        ])
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let fileName = "head.jpg"
        let b = FileCache().fileIfExist(name: fileName)
        if b {
            let data = FileCache().readData(name: fileName)
            profileImageView.image = UIImage(data: data)
        } else {
            
        }
        let name = UserDefaults.standard.string(forKey: "NickName")
        if name?.count ?? 0 > 0 {
            nicknameButton.setTitle(name!, for: .normal)
        } else if bleSelf.userInfo.name.count > 0 {
            nicknameButton.setTitle(bleSelf.userInfo.name, for: .normal)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if bOnce {
           return
        }
        bOnce = true
        // 设置tableView的顶部两个角为圆角
        let path = UIBezierPath(roundedRect: tableView.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 20.0, height: 20.0))
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        tableView.layer.mask = maskLayer
    }
    
    private func logout() {
        let alert = UIAlertController(title: "device_tip".localized(), message: "agree_log_out".localized(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "mine_cancel".localized(), style: .cancel, handler: { (action) in
            
        }))
        alert.addAction(UIAlertAction(title: "mine_confirm".localized(), style: .default, handler: { (action) in
            let sb = UIStoryboard(name: "Mine", bundle: nil)
            let nav = sb.instantiateViewController(withIdentifier: "MNavigationController")
            UIApplication.shared.keyWindow?.rootViewController = nav
            UserManager.sharedInstall.deleteUser()
        }))
        present(alert, animated: true) {
            
        }
    }
    
    @IBAction func pushToAddDevice(_ sender: Any) {
        let count = DeviceManager.shared.devices.count + (bleSelf.bleModel.mac.count > 0 ? 1 : 0)
        let storyboard = UIStoryboard(name: "Device", bundle: nil)
        if count == 0 {
            let vc = storyboard.instantiateViewController(withIdentifier: "DeviceSearchViewController")
            vc.title = "device_add".localized()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        } else {
            let vc = storyboard.instantiateViewController(withIdentifier: "DeviceListViewController")
            vc.title = "device_change".localized()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func pushToGrade(_ sender: Any) {
        let sb = UIStoryboard(name: "Sport", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "GradeViewController")
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension MineViewController: UITableViewDelegate {
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 处理cell点击事件
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.row {
        case 0:
            // 跳转到个人信息页面
            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "UserInfoViewController")
            navigationController?.pushViewController(vc, animated: true)
            break
        case 1:
            // 跳转到帮助中心页面
            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "HelpCenterViewController")
            navigationController?.pushViewController(vc, animated: true)
            break
        case 2:
            // 跳转到关于页面
            let storyboard = UIStoryboard(name: .kMine, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "AboutUSViewController")
            navigationController?.pushViewController(vc, animated: true)
            break
        default:
            break
        }
    }
}

extension MineViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles.count
    }
        
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        // 设置cell
        cell.textLabel?.text = titles[indexPath.row]
        cell.textLabel?.font = UIFont.subtitle()
        cell.textLabel?.textColor = UIColor.text_primary
        cell.imageView?.image = icons[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
}

extension String {
    static let kMine = "Mine"
}
