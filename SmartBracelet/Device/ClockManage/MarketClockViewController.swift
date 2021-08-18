//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  MarketClockViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/9/5.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit
import Toaster

class MarketClockViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    var rightButton: UIButton!
    var bShowDetail = false 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if bShowDetail == false {
            rightButton = UIButton(type: .custom).then {
                $0.initializeRightNavigationItem()
                $0.setTitle("管理", for: .normal)
                $0.setTitle("删除", for: .selected)
                $0.setTitle("完成", for: .disabled)
            }
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightButton)
        }
        collectionView.bounces = false
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension MarketClockViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: .kCellIdentifier, for: indexPath) as! ClockCCollectionViewCell
        let type = bleSelf.bleModel.screenType
        log.info("当前连接设备为：\(type == 1 ? "方形" : "圆形")")
        let w = bleSelf.bleModel.screenWidth
        let h = bleSelf.bleModel.screenHeight
        let imagename = "\(indexPath.row + 1)\(type == 1 ? "" : "_c")_\(w)_\(h)"
        cell.clockImageView.image = UIImage(named: imagename)
        cell.clockNameLabel.text = "\(bleSelf.bleModel.name)-\(indexPath.row + 1)"
        cell.width.constant = (ScreenWidth - 60) / 2
        cell.successButton.isHidden = true
        cell.loadingWidth.constant = 0
        let clockDir = UserDefaults.standard.dictionary(forKey: "LoadingClock") ?? [:]
        let loadingStr = clockDir[bleSelf.bleModel.mac] as? String ?? ""
        if loadingStr.count > 0 {
            let ClockArray = loadingStr.components(separatedBy: "&&&")
            if ClockArray.count > 0 {
                for item in ClockArray {
                    let array = item.components(separatedBy: "&&")
                    if imagename == array[1] {
                        cell.successButton.isHidden = false
                        cell.loadingWidth.constant = (ScreenWidth - 60) / 2
                    }
                }
            }
        }
        return cell
    }
    
}

extension MarketClockViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if !bleSelf.isConnected {
            Toast(text: "未连接手环").show()
            return
        }
        let vc = storyboard?.instantiateViewController(withIdentifier: "ClockUseViewController") as? ClockUseViewController
        vc?.index = indexPath.row + 1
        parent?.navigationController?.pushViewController(vc!, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (ScreenWidth - 60) / 2, height: ((ScreenWidth - 60) / 2) / 165 * 220)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

