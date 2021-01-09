//
// Copyright © 2015-2018 Anker Innovations Technology Limited All Rights Reserved.
// The program and materials is not free. Without our permission, any use, including but not limited to reproduction, retransmission, communication, display, mirror, download, modification, is expressly prohibited. Otherwise, it will be pursued for legal liability.
// 
//  SetTargetViewController.swift
//  SmartBracelet
//
//  Created by ANKER on 2020/7/29.
//  Copyright © 2020 tjd. All rights reserved.
//
	

import UIKit

class SetTargetViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var timeTextField: UITextField!
    @IBOutlet weak var unitLabel: UILabel!
    public var target: TargetModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = String.kSetTarget
        timeTextField.keyboardType = .numbersAndPunctuation
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard let value = timeTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return
        }
        let f = Float(value) ?? 0
        if f > 0 {
            target.distance = Int(f * 1000)
        }
    }

}

extension SetTargetViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: .kCellIdentifier, for: indexPath) as! SetTargetCollectionViewCell
        cell.timeLabel.text = distances[indexPath.row]
        cell.descLabel.text = descs[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return distances.count
    }
}

extension SetTargetViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        timeTextField.text = distances[indexPath.row]
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 5, bottom: 10, right: 5)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (ScreenWidth - 10) / 3, height: 82)
    }
}

extension SetTargetViewController {
    public var descs: [String] {
        return ["加油鸭", "爱你的路线", "一生一世", "超越半马", "超越全马", "超越自己"]
    }
    
    public var distances: [String] {
        return ["0.80", "5.20", "13.14", "21.25", "42.25", "--"]
    }
}
