//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  MyClockViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/9/5.
//  Copyright © 2020 tjd. All rights reserved.
//

import UIKit
import Then

class MyClockViewController: UIViewController {
    @IBOutlet weak var collctionView: UICollectionView!
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
        collctionView.bounces = false 
    }

}

extension MyClockViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: .kCellIdentifier, for: indexPath) as! ClockCollectionViewCell
        cell.dialImageView.image = UIImage(named: "preview_watch\(indexPath.row + 1)")
        cell.opaqueView.isHidden = true
        cell.optionImageView.isHidden = true
        return cell
    }
    
}

extension MyClockViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let vc = storyboard?.instantiateViewController(withIdentifier: "ClockUseViewController") as? ClockUseViewController
        vc?.index = indexPath.row + 1
        parent?.navigationController?.pushViewController(vc!, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.row < 4 {
            return CGSize(width: (ScreenWidth - 60) / 2, height: (ScreenWidth - 60) / 2)
        } else {
            return CGSize(width: (ScreenWidth - 60) / 3, height: (ScreenWidth - 60) / 3)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}
