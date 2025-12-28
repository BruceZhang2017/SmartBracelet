//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  MineViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/8/17.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit
import Toaster
import DropDown
import WatchProtocolSDK

class MineViewController: BaseViewController {
    
    let tableView = UITableView(frame: .zero, style: .plain)
    let headerView = UIView()
    let profileImageView = UIImageView()
    let nicknameButton = UIButton()
    var bOnce = false
    let titles = ["mine_userinfo".localized(), "mine_help_center".localized(), "mine_about".localized()]
    let icons = [UIImage(named: "mine_account_info"), UIImage(named: "mine_help"), UIImage(named: "mine_account_about")]
    let dropDown = DropDown()
    var bHavenScanResult = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "mine".localized()
        
        if isXGZT {
            XGZTCommand.get12H24HTimeFormat()
            XGZTCommand.getDeviceUnitFormat()
        }
        
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
        
        // 设置 DropDown 数据源
        dropDown.dataSource = ["device_scan".localized(), "device_add".localized()]

        // 自定义下拉菜单样式
        dropDown.textFont = UIFont.systemFont(ofSize: 16)
        dropDown.textColor = .black
        dropDown.backgroundColor = .white
        dropDown.layer.cornerRadius = 16
        dropDown.clipsToBounds = true

        // 设置选中事件回调
        dropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            XLogger.shared.log("选中了第 \(index) 项: \(item)")
            self.bHavenScanResult = false
            // 您可以在这里处理选中后的操作，例如更新界面或发送请求
            if index == 1 {
                var count = DeviceManager.shared.devices.count
                count += cacheDevices.count
                let storyboard = UIStoryboard(name: "Device", bundle: nil)
                if count == 0 {
                    let vc = storyboard.instantiateViewController(withIdentifier: "DeviceSearchViewController") as? DeviceSearchViewController
                    vc?.title = "device_add".localized()
                    vc?.refreshBackButton()
                    vc?.hidesBottomBarWhenPushed = true
                    self.navigationController?.pushViewController(vc!, animated: true)
                } else {
                    let vc = storyboard.instantiateViewController(withIdentifier: "DeviceListViewController") as? DeviceListViewController
                    vc?.title = "device_change".localized()
                    vc?.refreshBackButton()
                    vc?.style = 1
                    vc?.hidesBottomBarWhenPushed = true
                    self.navigationController?.pushViewController(vc!, animated: true)
                }
            } else {
                /// 创建二维码扫描
                let vc = ScannerVC()
                vc.modalPresentationStyle = .fullScreen
                //设置标题、颜色、扫描样式（线条、网格）、提示文字
                vc.setupScanner("device_scan".localized(), .blue, .grid, "device_scan_add_device".localized()) {[weak self] (code) in
                    //扫描回调方法
                    XLogger.shared.log("扫描的结果是：\(code)")
                    if (self?.bHavenScanResult ?? false) {
                        XLogger.shared.log("扫描的结果重复了")
                        return
                    }
                    if code.count > 0 && code.contains("mac=") {
                        XLogger.shared.log("扫描的结果是旧设备")
                        self?.bHavenScanResult = true
                        if let mac = self?.extractMacValue(from: code) {
                            if bleSelf.bleModels.count > 0 {
                                for model in bleSelf.bleModels {
                                    let m = model.mac.replacingOccurrences(of: ":", with: "").lowercased()
                                    if m == mac.lowercased() {
                                        bleSelf.connectBleDevice(model: model)
                                        break
                                    }
                                }
                            } else {
                                BLEManager.shared.startScan()
                                Async.main(after: 1.5) {
                                    if bleSelf.bleModels.count > 0 {
                                        for model in bleSelf.bleModels {
                                            let m = model.mac.replacingOccurrences(of: ":", with: "").lowercased()
                                            if m == mac.lowercased() {
                                                bleSelf.connectBleDevice(model: model)
                                                break
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } else if code.count > 0 && code.contains("k=") {
                        XLogger.shared.log("扫描的结果是新设备")
                        self?.bHavenScanResult = true
                        // 手动解析k参数值（避免URLComponents旧系统兼容问题）
                        if let kParamStart = code.range(of: "k=")?.upperBound {
                            // 找到k参数的结束位置（&符号或字符串结尾）
                            let kParamEnd = code[kParamStart...].range(of: "&")?.lowerBound ?? code.endIndex
                            let kValueStr = String(code[kParamStart..<kParamEnd])
                            XLogger.shared.log("解析k参数的原始值：\(kValueStr)")
                            
                            // 按|分割字符串，获取所有部分
                            let components = kValueStr.components(separatedBy: "|")
                            
                            // 检查是否有足够的部分
                            guard components.count >= 2 else {
                                XLogger.shared.log("扫描的结果有错误1：参数k的值格式不正确，至少需要3个|分隔的部分，实际有\(components.count)个")
                                self?.dismiss(animated: true, completion: nil)
                                return
                            }
                            
                            // 提取各个部分并去除首尾空格
                            let macAddress = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                            let deviceName = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            XLogger.shared.log("解析到的mac地址是：\(macAddress)")
                            XLogger.shared.log("解析到的设备名称是：\(deviceName)")
                            
                            if XGZTBlueToothManager.shared.isCurrentBleStateOFF() {
                                Toast(text: "ble_off".localized()).show()
                                XLogger.shared.log("蓝牙没有开启")
                            } else {
                                // 可以根据需要使用所有解析出的参数
                                XGZTBlueToothManager.shared.connectAndScan(to: macAddress, deviceName: deviceName)
                            }
                        } else {
                            XLogger.shared.log("扫描的结果有错误2：未找到k参数")
                            self?.dismiss(animated: true, completion: nil)
                        }

                    } else {
                        XLogger.shared.log("扫描的结果是无设备")
                    }
                    //关闭扫描页面
                    self?.dismiss(animated: true, completion: nil)
                    
                }

                //Present到扫描页面
                self.navigationController?.present(vc, animated: true, completion: nil)
            }
            self.dropDown.clearSelection()
        }
        
    }
    
    func extractMacValue(from string: String) -> String? {
        let pattern = "mac="
        guard let range = string.range(of: pattern, options: .backwards) else {
            // 如果没有找到 "mac="，返回 nil
            return nil
        }
        // 截取 "mac=" 之后的字符串
        let macValue = string[range.upperBound...]
        return String(macValue)
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
        // 获取导航栏按钮的视图
        if let rightBarButton = self.navigationItem.rightBarButtonItem,
           let view = rightBarButton.value(forKey: "view") as? UIView {
            // 设置锚点视图
            dropDown.anchorView = view
            dropDown.bottomOffset = CGPoint(x: 0, y: view.bounds.height)
            dropDown.show()
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
            if !bleSelf.isConnected && XGZTBlueToothManager.shared.device == nil {
                Toast(text: "mine_unconnect".localized()).show()
                return
            }
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
