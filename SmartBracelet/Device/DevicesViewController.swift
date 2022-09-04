//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  DevicesViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/8/28.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit
import TJDWristbandSDK

class DevicesViewController: BaseViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var dialManagmentLabel: UILabel!
    @IBOutlet weak var bottomLConstraint: NSLayoutConstraint!
    @IBOutlet weak var dialView: UIView!
    @IBOutlet weak var exchangeBarButtonItem: UIBarButtonItem!
    var deviceSettingView: UIView? // 设备设置的视图
    var deviceView: DevicesView!
    var clockArray: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        deviceView = DevicesView(frame: CGRect(x: 0, y: 5, width: ScreenWidth, height: 200))
        deviceView.delegate = self
        contentView.addSubview(deviceView)
        bleSelf.getSwitchForWristband()
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: Notification.Name("DevicesViewController"), object: nil)
        dialManagmentLabel.text = "dial_management".localized()
        initializeDeviceSettings()
        exchangeBarButtonItem.title = "switch_device".localized()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    private func refreshDevices() {
        let lastestDeviceMac = UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? "00:00:00:00:00:00"
        let clockDir = UserDefaults.standard.dictionary(forKey: "MyClock") ?? [:]
        let clockStr = clockDir[lastestDeviceMac] as? [String] ?? ["_&&_&&_", "_&&_&&_", "_&&_&&_"]
        if clockStr.count > 0 {
            clockArray = clockStr
        } else {
            clockArray.removeAll()
        }
        collectionView?.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        deviceView?.refreshData()
        refreshDevices()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // 设备设置
    private func initializeDeviceSettings() {
        deviceSettingView = UIView().then {
            $0.backgroundColor = UIColor.white
            
        }
        contentView.addSubview(deviceSettingView!)
        deviceSettingView?.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.top.equalTo(dialView.snp.bottom).offset(15)
        }
        let lblTitle = UILabel().then {
            $0.textColor = UIColor.black
            $0.font = UIFont.boldSystemFont(ofSize: 15)
            $0.text = "device_settings".localized()
        }
        deviceSettingView?.addSubview(lblTitle)
        lblTitle.snp.makeConstraints {
            $0.left.equalTo(15)
            $0.top.equalTo(10)
            $0.height.equalTo(20)
        }
        
        let storyboard = UIStoryboard(name: "Device", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "DeviceSettingsViewController") as! DeviceSettingsViewController
        addChild(vc)
        deviceSettingView?.addSubview(vc.view)
        vc.view.snp.makeConstraints {
            $0.left.equalTo(0)
            $0.top.equalTo(lblTitle.snp.bottom).offset(10)
            $0.right.equalTo(0)
            $0.height.equalTo(500)
            $0.bottom.equalToSuperview()
        }
        bottomLConstraint.constant = 460
    }
    
    @objc private func handleNotification(_ notification: Notification) {
        if let obj = notification.object as? String, obj.count > 0 {
            print("刷新设备列表数据")
            deviceView?.refreshData()
            refreshDevices()
            return
        }
        self.perform(#selector(pushToMobileSettings), with: nil, afterDelay: 0.3)
    }
    
    @objc private func pushToMobileSettings() {
        let url = URL(string: "App-Prefs:root=Bluetooth")
        if UIApplication.shared.canOpenURL(url!) {
            UIApplication.shared.open(url!, options: [:], completionHandler: nil)
        }
    }

    /// 表盘管理
    func pushToClockManage(index: Int) {
        if bleSelf.bleModel.screenWidth == 80 {
            let storyboard = UIStoryboard(name: "Device", bundle: nil)
            let myClockVC = storyboard.instantiateViewController(withIdentifier: "MyClockViewController") as! MyClockViewController
            myClockVC.index = index
            navigationController?.pushViewController(myClockVC, animated: true)
            return
        }
        
        let storyboard = UIStoryboard(name: "Device", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ClockManageViewController") as? ClockManageViewController
        vc?.index = index
        navigationController?.pushViewController(vc!, animated: true)
    }
    
    @IBAction private func showPop(_ sender: Any) {
        let pop = PopupViewController()
        pop.modalTransitionStyle = .crossDissolve
        pop.modalPresentationStyle = .overFullScreen
        pop.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        present(pop, animated: true, completion: nil)
        pop.titleLabel.text = "玩机技巧"
        pop.contentLabel.text =
        """
        左上键：短按时返回上一层菜单。 在时间界面时短按进行时间显示模式切换。
        　　  插卡口：打开机身左侧插卡口软塞，按箭头方向将SIM卡推进卡槽，固定住即可。
        　　  左下键：长按3秒，进行开关机操作;短按时返回对应的(时钟、电话、脉搏、计步器、GPS、设置)一级菜单或在各个一级菜单之间循环滑动。
        　　  SOS一键求救右上键：长按3秒后开始拨打服务中心电话。
        　　  充电&耳机接口：连接充电器或连接USB耳机
        　　  右下键：长按3秒后开始拨打设定的亲友号码。
        """
    }
    
    @IBAction func addDevice(_ sender: Any) {
        let count = DeviceManager.shared.devices.count
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
    
    private func deleteDevice(model: BLEModel?) {
        let alert = UIAlertController(title: "device_tip".localized(), message: "unbind_device_desc".localized(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "mine_cancel".localized(), style: .cancel, handler: { (action) in
            
        }))
        alert.addAction(UIAlertAction(title: "mine_confirm".localized(), style: .default, handler: { [weak self] (action) in
            let count = DeviceManager.shared.devices.count
            if count <= 1 {
                NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "delete", userInfo: ["mac": DeviceManager.shared.devices[0].mac])
                BLEManager.shared.unbind()
                UserDefaults.standard.removeObject(forKey: "LastestDeviceMac")
            } else {
                guard let mac = model?.mac else {
                    return
                }
                NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "delete", userInfo: ["mac": mac])
                let lastestDeviceMac = UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? ""
                if lastestDeviceMac == mac {
                    BLEManager.shared.unbind()
                    UserDefaults.standard.removeObject(forKey: "LastestDeviceMac")
                }
            }
            self?.deviceView?.refreshData()
        }))
        present(alert, animated: true) {
            
        }
    }
}

extension DevicesViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: .kCellIdentifier, for: indexPath) as! ClockBCollectionViewCell
        if indexPath.row < clockArray.count  {
            let item = clockArray[indexPath.item]
            let array = item.components(separatedBy: "&&")
            if array[0] == "_" {
                cell.clockImageView.image = UIImage(named: "jiahao")
                cell.clockNameLabel.text = "more_dial".localized()
            } else {
                cell.clockImageView.image = UIImage(named: "jiahao")
                if array[1].contains(".png"){
                    print("保存的图片路径：\(array[1])")
                    if array[1].contains("Documents") {
                        cell.clockImageView.image = UIImage(contentsOfFile: array[1])
                    } else {
                        if array[1].contains("http") {
                            cell.clockImageView.kf.setImage(with: URL(string: array[1]))
                        } else {
                            let fullPath = NSHomeDirectory().appending("/Documents/").appending(array[1])
                            cell.clockImageView.image = UIImage(contentsOfFile: fullPath)
                        }
                        
                    }
                    
                }
                
                cell.clockNameLabel.text = array[0]
            }
            
        } else {
            cell.clockImageView.image = UIImage(named: "jiahao")
            cell.clockNameLabel.text = "more_dial".localized()
        }
        return cell
    }
    
    
}

extension DevicesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        pushToClockManage(index: indexPath.row)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (ScreenWidth - 24) / 3, height: 170)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

extension DevicesViewController: DevicesViewDelegate {
    func callbackTap(model: BLEModel?, bConnected: Bool) {
        let count = DeviceManager.shared.devices.count
        if count == 0 {
            let storyboard = UIStoryboard(name: "Device", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "DeviceSearchViewController")
            vc.title = "device_add".localized()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
            return
        }
        deleteDevice(model: model)
        // 当设备已经连接后，并且连接成功后，则跳转至设备设置页面。删除该部分逻辑
    }
}

extension String {
    static let kDevice = "Device"
}
