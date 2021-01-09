//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  DevicesViewController.swift
//  TJDWristbandSDKDemo
//
//  Created by ANKER on 2020/8/28.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit

class DevicesViewController: BaseViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var contentView: UIView!
    var deviceView: DevicesView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        deviceView = DevicesView(frame: CGRect(x: 0, y: 5, width: ScreenWidth, height: 110))
        deviceView.delegate = self
        contentView.addSubview(deviceView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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

    @IBAction func pushToClockManage(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Device", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ClockManageViewController")
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension DevicesViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: .kCellIdentifier, for: indexPath) as! ClockBCollectionViewCell
        
        return cell
    }
    
    
}

extension DevicesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
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
    func callbackTap(index: Int) {
        let storyboard = UIStoryboard(name: "Device", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "DeviceSettingsViewController") as! DeviceSettingsViewController
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension String {
    static let kDevice = "Device"
}
