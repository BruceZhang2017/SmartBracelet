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
    var deviceView: DevicesView!
    var clockArray: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        deviceView = DevicesView(frame: CGRect(x: 0, y: 5, width: ScreenWidth, height: 200))
        deviceView.delegate = self
        contentView.addSubview(deviceView)
        bleSelf.getSwitchForWristband()
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: Notification.Name("DevicesViewController"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        deviceView?.refreshData()
        
        let clockDir = UserDefaults.standard.dictionary(forKey: "MyClock") ?? [:]
        let clockStr = clockDir[bleSelf.bleModel.mac] as? String ?? ""
        if clockStr.count > 0 {
            clockArray = clockStr.components(separatedBy: "&&&")
        }
        collectionView?.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleNotification(_ notification: Notification) {
        if let obj = notification.object as? String, obj.count > 0 {
            deviceView?.refreshData()
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
    @IBAction func pushToClockManage(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Device", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ClockManageViewController")
        navigationController?.pushViewController(vc, animated: true)
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
            vc.title = "添加设备"
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        } else {
            let vc = storyboard.instantiateViewController(withIdentifier: "DeviceListViewController")
            vc.title = "设备切换"
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    private func deleteDevice(index: Int) {
        let alert = UIAlertController(title: "提示", message: "您确定解除绑定该设备？如果确定，并请至手机“设置 -> 蓝牙”中删除该设备配对记录。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: { (action) in
            
        }))
        alert.addAction(UIAlertAction(title: "确定", style: .default, handler: { [weak self] (action) in
            let count = DeviceManager.shared.devices.count
            if count <= 1 {
                NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "delete", userInfo: ["mac": DeviceManager.shared.devices[0].mac])
                BLEManager.shared.unbind()
                UserDefaults.standard.removeObject(forKey: "LastestDeviceMac")
            } else {
                NotificationCenter.default.post(name: Notification.Name("HealthViewController"), object: "delete", userInfo: ["mac": DeviceManager.shared.devices[index].mac])
                let lastestDeviceMac = UserDefaults.standard.string(forKey: "LastestDeviceMac") ?? ""
                let mac = DeviceManager.shared.devices[index].mac
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
            let item = clockArray[indexPath.row]
            let array = item.components(separatedBy: "&&")
            cell.clockImageView.image = UIImage(named: array[1])
            cell.clockNameLabel.text = array[0]
        } else {
            cell.clockImageView.image = UIImage(named: "jiahao")
            cell.clockNameLabel.text = "更多表盘"
        }
        return cell
    }
    
    
}

extension DevicesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
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
    func callbackTap(index: Int, bConnected: Bool) {
        let count = DeviceManager.shared.devices.count
        if count == 0 {
            let storyboard = UIStoryboard(name: "Device", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "DeviceSearchViewController")
            vc.title = "添加设备"
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
            return
        }
        if !bConnected { // 如果是没有连接的设备
            deleteDevice(index: index)
            return
        }
        let storyboard = UIStoryboard(name: "Device", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "DeviceSettingsViewController") as! DeviceSettingsViewController
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension String {
    static let kDevice = "Device"
}
