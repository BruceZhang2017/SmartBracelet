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
        let nullLabel = UILabel().then {
            $0.textColor = UIColor.black
            $0.font = UIFont.systemFont(ofSize: 20)
            $0.text = "敬请期待..."
        }
        view.addSubview(nullLabel)
        nullLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        collectionView.dataSource = self
        collectionView.delegate = self
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
        cell.clockImageView.image = UIImage(named: "\(indexPath.row + 1)_240_240")
        cell.clockNameLabel.text = "ITIME-\(indexPath.row + 1)"
        cell.width.constant = (ScreenWidth - 60) / 2
        return cell
    }
    
}

extension MarketClockViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if bShowDetail {
            bShowDetail = false
            let storyboard = UIStoryboard(name: "Device", bundle: nil)
            let marketClockVC = storyboard.instantiateViewController(withIdentifier: "MarketClockViewController") as! MarketClockViewController
            parent?.navigationController?.pushViewController(marketClockVC, animated: true)
        }
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

